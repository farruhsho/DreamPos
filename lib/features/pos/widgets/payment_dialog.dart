// Payment dialog: big total, cash with live change and quick tenders, split
// payments (card / transfer / bonus / debt / gift card). Calls checkout.
import 'dart:math';

import 'package:drift/drift.dart' hide Column;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/services/sale_service.dart';
import '../cart_controller.dart';
import '../tender.dart';

/// Pure payment math (unit-tested). Amounts in minor units.
class PaymentSplit {
  const PaymentSplit({
    required this.total,
    this.cash = 0,
    this.card = 0,
    this.transfer = 0,
    this.bonus = 0,
    this.debt = 0,
    this.gift = 0,
  });
  final int total;
  final int cash;
  final int card;
  final int transfer;
  final int bonus;
  final int debt;
  final int gift;

  int get nonCash => card + transfer + bonus + debt + gift;
  int get cashNeeded => max(0, total - nonCash);
  int get change => max(0, cash - cashNeeded);
  int get missing => max(0, cashNeeded - cash);
  bool get nonCashTooBig => nonCash > total;

  /// Error message to show, or null if the split can be submitted.
  String? get error {
    if (nonCashTooBig) {
      return 'Безналичная оплата больше суммы чека на ${Money.format(nonCash - total)}';
    }
    if (missing > 0) return 'Не хватает ${Money.format(missing)}';
    if (cashNeeded == 0 && cash > 0) return 'Наличные не нужны — чек уже оплачен';
    return null;
  }
}

class PaymentDialog extends ConsumerStatefulWidget {
  const PaymentDialog({
    super.key,
    required this.cart,
    required this.total,
    required this.cashierId,
    this.shiftId,
    this.customer,
  });

  final CartState cart;
  final int total;
  final String cashierId;
  final String? shiftId;
  final Customer? customer;

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  late final _cash = TextEditingController(text: Money.toInput(widget.total));
  final _card = TextEditingController();
  final _transfer = TextEditingController();
  final _transferRef = TextEditingController();
  final _bonus = TextEditingController();
  final _debt = TextEditingController();
  final _gift = TextEditingController();
  final _giftCode = TextEditingController();
  final _cashFocus = FocusNode();

  bool _cashTouched = false;
  bool _busy = false;
  String? _serverError;
  GiftCard? _giftCard;
  String? _giftError;
  bool _checkingGift = false;
  bool _showMore = false;

  @override
  void initState() {
    super.initState();
    _cash.selection = TextSelection(baseOffset: 0, extentOffset: _cash.text.length);
    for (final c in [_card, _transfer, _bonus, _debt, _gift]) {
      c.addListener(_onNonCashChanged);
    }
    _cash.addListener(() => setState(() => _serverError = null));
  }

  @override
  void dispose() {
    for (final c in [_cash, _card, _transfer, _transferRef, _bonus, _debt, _gift, _giftCode]) {
      c.dispose();
    }
    _cashFocus.dispose();
    super.dispose();
  }

  int _v(TextEditingController c) => c.text.trim().isEmpty ? 0 : (Money.parse(c.text) ?? 0);

  PaymentSplit get _split => PaymentSplit(
        total: widget.total,
        cash: _v(_cash),
        card: _v(_card),
        transfer: _v(_transfer),
        bonus: _v(_bonus),
        debt: _v(_debt),
        gift: _v(_gift),
      );

  void _onNonCashChanged() {
    // While the cashier has not typed a cash amount, keep cash = remainder.
    if (!_cashTouched) {
      final need = _split.cashNeeded;
      final t = need == 0 ? '' : Money.toInput(need);
      if (_cash.text != t) _cash.text = t;
    }
    setState(() => _serverError = null);
  }

  void _setCash(int v) {
    _cashTouched = true;
    _cash.text = Money.toInput(v);
    _cashFocus.requestFocus();
    _cash.selection = TextSelection(baseOffset: 0, extentOffset: _cash.text.length);
  }

  /// Puts the whole remaining amount on a non-cash method.
  void _payAllBy(TextEditingController c, {int? cap}) {
    final others = _split.nonCash - _v(c);
    var amount = max(0, widget.total - others);
    if (cap != null) amount = min(amount, cap);
    _cashTouched = false;
    c.text = amount == 0 ? '' : Money.toInput(amount);
    _onNonCashChanged();
  }

  // ---- loyalty / debt limits
  bool get _loyaltyEnabled => ref.read(settingProvider('loyalty_enabled')) == '1';
  double get _maxRedeemPct =>
      double.tryParse(ref.read(settingProvider('loyalty_max_redeem_percent')) ?? '') ?? 100;
  int get _maxBonus {
    final c = widget.customer;
    if (c == null) return 0;
    return min(c.bonusBalance, Money.percent(widget.total, _maxRedeemPct));
  }

  int? get _debtAvailable {
    final c = widget.customer;
    if (c == null) return 0;
    if (c.debtLimit <= 0) return null; // no limit configured
    return max(0, c.debtLimit - c.debtBalance);
  }

  String? _validateExtras() {
    final s = _split;
    if (s.bonus > 0 && s.bonus > _maxBonus) {
      return 'Бонусами можно оплатить не более ${Money.format(_maxBonus)}';
    }
    final avail = _debtAvailable;
    if (s.debt > 0 && avail != null && s.debt > avail) {
      return 'Превышен кредитный лимит: доступно ${Money.format(avail)}';
    }
    if (s.gift > 0) {
      if (_giftCard == null) return 'Проверьте код сертификата';
      if (s.gift > _giftCard!.balance) {
        return 'На сертификате только ${Money.format(_giftCard!.balance)}';
      }
    }
    return null;
  }

  Future<void> _checkGift() async {
    final code = normalizeGiftCode(_giftCode.text);
    if (code.isEmpty) {
      setState(() => _giftError = 'Введите код сертификата');
      return;
    }
    setState(() {
      _checkingGift = true;
      _giftError = null;
      _giftCard = null;
    });
    try {
      final db = ref.read(databaseProvider);
      final card = await (db.select(db.giftCards)
            ..where((g) => g.code.equals(code) & g.deletedAt.isNull()))
          .getSingleOrNull();
      String? err;
      if (card == null) {
        err = 'Сертификат не найден';
      } else if (card.status != 'active') {
        err = 'Сертификат не активен (${card.status == 'used' ? 'использован' : card.status})';
      } else if (card.expiresAt != null && DateTime.now().isAfter(card.expiresAt!)) {
        err = 'Срок действия истёк ${formatDate(card.expiresAt!)}';
      } else if (card.balance <= 0) {
        err = 'На сертификате нет средств';
      }
      if (!mounted) return;
      setState(() {
        _giftError = err;
        _giftCard = err == null ? card : null;
      });
      if (err == null) _payAllBy(_gift, cap: card!.balance);
    } catch (e) {
      if (mounted) setState(() => _giftError = errorText(e));
    } finally {
      if (mounted) setState(() => _checkingGift = false);
    }
  }

  Future<void> _confirm() async {
    if (_busy) return;
    final s = _split;
    final err = s.error ?? _validateExtras();
    if (err != null) {
      setState(() => _serverError = err);
      return;
    }
    setState(() {
      _busy = true;
      _serverError = null;
    });
    final payments = <PaymentInput>[
      if (s.cash > 0) PaymentInput('cash', s.cash),
      if (s.card > 0) PaymentInput('card', s.card),
      if (s.transfer > 0)
        PaymentInput('transfer', s.transfer,
            reference: _transferRef.text.trim().isEmpty ? null : _transferRef.text.trim()),
      if (s.bonus > 0) PaymentInput('bonus', s.bonus),
      if (s.debt > 0) PaymentInput('debt', s.debt),
      if (s.gift > 0) PaymentInput('gift_card', s.gift, reference: _giftCard?.code),
    ];
    try {
      final res = await ref.read(saleServiceProvider).checkout(widget.cart.toRequest(
            cashierId: widget.cashierId,
            shiftId: widget.shiftId,
            payments: payments,
          ));
      if (mounted) Navigator.pop(context, res);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _serverError = errorText(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final s = _split;
    final customer = widget.customer;
    final loyalty = customer != null && _loyaltyEnabled && customer.bonusBalance > 0;
    final hasNonCash = s.nonCash > 0;
    final extrasError = _validateExtras();
    final canConfirm = s.error == null && extrasError == null && !_busy;
    final tenders = quickTenders(s.cashNeeded, Money.currency);

    Widget methodRow({
      required IconData icon,
      required String label,
      required TextEditingController c,
      String? helper,
      int? cap,
      Widget? extra,
    }) =>
        Padding(
          padding: const EdgeInsets.only(top: Gap.m),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, right: Gap.s),
              child: Icon(icon, color: t.colorScheme.primary),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                MoneyField(label: label, controller: c, helper: helper, onSubmitted: (_) => _confirm()),
                ?extra,
              ]),
            ),
            const SizedBox(width: Gap.s),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton(
                onPressed: () => _payAllBy(c, cap: cap),
                child: const Text('Всё'),
              ),
            ),
          ]),
        );

    return PopScope(
      // never close while checkout runs: the sale could be recorded while the
      // cart stays filled, inviting a second (duplicate) sale.
      canPop: !_busy,
      child: Focus(
      // Enter confirms even when no text field has focus (e.g. after the
      // "Картой" button was used). Fields and buttons keep their own Enter.
      onKeyEvent: (node, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        if (e.logicalKey != LogicalKeyboardKey.enter &&
            e.logicalKey != LogicalKeyboardKey.numpadEnter) {
          return KeyEventResult.ignored;
        }
        final f = FocusManager.instance.primaryFocus;
        if (f == null || f == node || f is FocusScopeNode) {
          if (canConfirm) _confirm();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Dialog(
      insetPadding: const EdgeInsets.all(Gap.l),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.sizeOf(context).height * 0.95),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ---- header with the big total
          Container(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.l, Gap.s, Gap.l),
            decoration: BoxDecoration(
              color: t.colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('К оплате', style: t.textTheme.titleSmall),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(Money.format(widget.total),
                        key: const Key('pay-total'),
                        style: t.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800, color: t.colorScheme.onPrimaryContainer)),
                  ),
                  if (customer != null)
                    Text('Клиент: ${customer.name}', style: t.textTheme.bodySmall),
                ]),
              ),
              IconButton(
                tooltip: 'Закрыть (Esc)',
                onPressed: _busy ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.m, Gap.xl, Gap.m),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // ---- cash
                TextFormField(
                  key: const Key('pay-cash'),
                  controller: _cash,
                  focusNode: _cashFocus,
                  autofocus: true,
                  style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))],
                  decoration: InputDecoration(
                    labelText: hasNonCash
                        ? 'Наличными получено (нужно ${Money.format(s.cashNeeded)})'
                        : 'Наличными получено',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    suffixText: Money.currency.symbol,
                  ),
                  onChanged: (_) {
                    _cashTouched = true;
                    setState(() {});
                  },
                  onFieldSubmitted: (_) => _confirm(),
                ),
                const SizedBox(height: Gap.s),
                Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
                  ActionChip(
                    avatar: const Icon(Icons.check, size: 18),
                    label: const Text('Без сдачи'),
                    onPressed: () => _setCash(s.cashNeeded),
                  ),
                  for (final v in tenders)
                    ActionChip(label: Text(Money.format(v)), onPressed: () => _setCash(v)),
                ]),
                const SizedBox(height: Gap.m),
                // ---- change / missing
                _ChangeBox(split: s),
                const SizedBox(height: Gap.s),
                // ---- other methods
                if (!_showMore && !hasNonCash)
                  Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
                    FilledButton.tonalIcon(
                      onPressed: () {
                        _payAllBy(_card);
                        setState(() => _showMore = true);
                        _cashFocus.requestFocus();
                      },
                      icon: const Icon(Icons.credit_card),
                      label: const Text('Картой'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        _payAllBy(_transfer);
                        setState(() => _showMore = true);
                        _cashFocus.requestFocus();
                      },
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Переводом'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showMore = true),
                      icon: const Icon(Icons.call_split),
                      label: const Text('Смешанная оплата'),
                    ),
                  ])
                else ...[
                  methodRow(icon: Icons.credit_card, label: 'Карта', c: _card),
                  methodRow(
                    icon: Icons.qr_code_2,
                    label: 'Перевод',
                    c: _transfer,
                    extra: _v(_transfer) > 0
                        ? Padding(
                            padding: const EdgeInsets.only(top: Gap.s),
                            child: TextField(
                              controller: _transferRef,
                              decoration: const InputDecoration(
                                  labelText: '№ операции / комментарий (необязательно)'),
                            ),
                          )
                        : null,
                  ),
                  if (loyalty)
                    methodRow(
                      icon: Icons.stars_outlined,
                      label: 'Бонусы',
                      c: _bonus,
                      cap: _maxBonus,
                      helper:
                          'Баланс ${Money.format(customer.bonusBalance)} · можно списать до ${Money.format(_maxBonus)}',
                    ),
                  if (customer != null)
                    methodRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'В долг',
                      c: _debt,
                      cap: _debtAvailable,
                      helper: _debtAvailable == null
                          ? 'Долг ${Money.format(customer.debtBalance)} · лимит не задан'
                          : 'Долг ${Money.format(customer.debtBalance)} из ${Money.format(customer.debtLimit)} · '
                              'доступно ${Money.format(_debtAvailable!)}',
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: Gap.m),
                      child: Text('Для оплаты в долг или бонусами выберите клиента (F4)',
                          style: t.textTheme.bodySmall
                              ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                    ),
                  // ---- gift card
                  Padding(
                    padding: const EdgeInsets.only(top: Gap.m),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, right: Gap.s),
                        child: Icon(Icons.card_giftcard, color: t.colorScheme.primary),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _giftCode,
                          decoration: InputDecoration(
                            labelText: 'Код сертификата',
                            errorText: _giftError,
                            helperText: _giftCard == null
                                ? null
                                : 'Баланс ${Money.format(_giftCard!.balance)}'
                                    '${_giftCard!.expiresAt == null ? '' : ' · до ${formatDate(_giftCard!.expiresAt!)}'}',
                          ),
                          onChanged: (_) {
                            if (_giftCard != null || _giftError != null) {
                              setState(() {
                                _giftCard = null;
                                _giftError = null;
                                _gift.clear();
                              });
                            }
                          },
                          onSubmitted: (_) => _checkGift(),
                        ),
                      ),
                      const SizedBox(width: Gap.s),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: TextButton(
                          onPressed: _checkingGift ? null : _checkGift,
                          child: const Text('Проверить'),
                        ),
                      ),
                    ]),
                  ),
                  if (_giftCard != null)
                    methodRow(
                        icon: Icons.redeem,
                        label: 'Оплата сертификатом',
                        c: _gift,
                        cap: _giftCard!.balance),
                ],
              ]),
            ),
          ),
          // ---- footer
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.l),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if ((_serverError ?? extrasError) != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.s),
                  child: Text(_serverError ?? extrasError!,
                      key: const Key('pay-error'),
                      style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                ),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  key: const Key('pay-confirm'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                  onPressed: canConfirm ? _confirm : null,
                  icon: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_busy ? 'Проводим…' : 'Провести оплату (Enter)',
                      style: const TextStyle(fontSize: 17)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    ),
    ),
    );
  }
}

class _ChangeBox extends StatelessWidget {
  const _ChangeBox({required this.split});
  final PaymentSplit split;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final missing = split.missing > 0 || split.nonCashTooBig;
    final color = missing ? AppColors.danger : AppColors.success;
    final label = split.nonCashTooBig
        ? 'Переплата безналом'
        : missing
            ? 'Не хватает'
            : 'Сдача';
    final value = split.nonCashTooBig
        ? split.nonCash - split.total
        : missing
            ? split.missing
            : split.change;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.m),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Text(label, style: t.textTheme.titleMedium?.copyWith(color: color)),
        const Spacer(),
        Text(Money.format(value),
            key: const Key('pay-change'),
            style: t.textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
