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
import '../../../l10n/l10n.dart';
import '../../../domain/services/sale_service.dart';
import '../cart_controller.dart';
import '../pos_providers.dart';
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
  String? get error => errorIn(L.current);

  String? errorIn(AppLocalizations l) {
    if (nonCashTooBig) {
      return l.posNonCashOver(Money.format(nonCash - total));
    }
    if (missing > 0) return l.posMissing(Money.format(missing));
    if (cashNeeded == 0 && cash > 0) return l.posCashNotNeeded;
    return null;
  }
}

/// Width of the "Всё" / "Проверить" buttons, so every method field lines up
/// (narrower on phones, where every pixel of the field counts).
double _trailingWidth(BuildContext context) => context.isCompact ? 84 : 96;
const _kTrailingPadding = EdgeInsets.symmetric(horizontal: 4);

class PaymentDialog extends ConsumerStatefulWidget {
  const PaymentDialog({
    super.key,
    required this.cart,
    required this.total,
    required this.cashierId,
    this.shiftId,
    this.registerId,
    this.customer,
    this.cashTotal,
  });

  final CartState cart;
  /// Total for any payment that includes non-cash methods (no rounding).
  final int total;
  final String cashierId;
  final String? shiftId;
  /// Register bound to this device (Settings > Кассы), if any.
  final String? registerId;
  final Customer? customer;
  /// Total when the whole receipt is paid in cash: rounded down by the
  /// `cash_rounding` setting (D-015). Null = quote it when the dialog opens.
  final int? cashTotal;

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  late final _cash = TextEditingController(text: Money.toInput(widget.cashTotal ?? widget.total));
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
  int? _quotedCashTotal;
  int _debtDays = 14;
  late DateTime _debtDue = _dueIn(14);

  static const debtDueChoices = [7, 14, 30];

  static DateTime _dueIn(int days) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day + days);
  }

  @override
  void initState() {
    super.initState();
    _cash.selection = TextSelection(baseOffset: 0, extentOffset: _cash.text.length);
    for (final c in [_card, _transfer, _bonus, _debt, _gift]) {
      c.addListener(_onNonCashChanged);
    }
    _cash.addListener(() => setState(() => _serverError = null));
    if (widget.cashTotal == null) _loadCashTotal();
  }

  /// Quotes the cash-only total (cash rounding) when the caller did not.
  Future<void> _loadCashTotal() async {
    try {
      final q = await ref.read(saleServiceProvider).quote(widget.cart.toRequest(
          cashierId: widget.cashierId,
          applyCashRounding: true,
          payments: [PaymentInput('cash', widget.total)]));
      if (!mounted || q.total == widget.total) return;
      setState(() => _quotedCashTotal = q.total);
      // keep the prefilled cash in step with the (rounded) amount due
      if (!_cashTouched && _nonCash == 0) _cash.text = Money.toInput(q.total);
    } catch (_) {
      // no rounding preview: checkout still rounds consistently
    }
  }

  /// Amount due when everything is paid in cash (rounded down).
  int get _cashTotal => widget.cashTotal ?? _quotedCashTotal ?? widget.total;

  int get _nonCash => _v(_card) + _v(_transfer) + _v(_bonus) + _v(_debt) + _v(_gift);

  /// Rounding applies only while the receipt is paid in cash alone.
  bool get _cashOnly => _nonCash == 0;

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
        total: _cashOnly ? _cashTotal : widget.total,
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

  void _setDebtDays(int days) => setState(() {
        _debtDays = days;
        _debtDue = _dueIn(days);
      });

  Future<void> _pickDebtDue() async {
    final today = _dueIn(0);
    final picked = await showDatePicker(
      context: context,
      initialDate: _debtDue,
      firstDate: today.add(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: 730)),
      helpText: context.l10n.posDebtDue,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _debtDue = DateTime(picked.year, picked.month, picked.day);
      final days = _debtDue.difference(today).inDays;
      _debtDays = debtDueChoices.contains(days) ? days : 0;
    });
  }

  /// Due date of the debt part: quick chips (+7/14/30 days) and a calendar.
  Widget _debtDueRow(ThemeData t) => Padding(
        key: const Key('pay-debt-due'),
        padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, 0, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.l10n.posDebtDue, style: t.textTheme.labelLarge),
          const SizedBox(height: Gap.xs),
          Wrap(
            spacing: Gap.s,
            runSpacing: Gap.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final d in debtDueChoices)
                ChoiceChip(
                  label: Text(context.l10n.posDays('$d')),
                  selected: _debtDays == d,
                  onSelected: (_) => _setDebtDays(d),
                ),
              ActionChip(
                key: const Key('pay-debt-date'),
                tooltip: context.l10n.posPickDate,
                avatar: const Icon(Icons.event, size: 18),
                label: Text(context.l10n.posUntil(formatDate(_debtDue))),
                onPressed: _pickDebtDue,
              ),
            ],
          ),
        ]),
      );

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
    final l = context.l10n;
    if (s.bonus > 0 && s.bonus > _maxBonus) {
      return l.posBonusMax(Money.format(_maxBonus));
    }
    final avail = _debtAvailable;
    if (s.debt > 0 && avail != null && s.debt > avail) {
      return l.posCreditExceeded(Money.format(avail));
    }
    if (s.gift > 0) {
      if (_giftCard == null) return l.posCheckGiftCode;
      if (s.gift > _giftCard!.balance) {
        return l.posGiftOnly(Money.format(_giftCard!.balance));
      }
    }
    return null;
  }

  Future<void> _checkGift() async {
    final code = normalizeGiftCode(_giftCode.text);
    final l = context.l10n;
    if (code.isEmpty) {
      setState(() => _giftError = l.posEnterGiftCode);
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
        err = l.posGiftNotFound;
      } else if (card.status != 'active') {
        err = l.posGiftInactive(card.status == 'used' ? l.posGiftUsed : card.status);
      } else if (card.expiresAt != null && DateTime.now().isAfter(card.expiresAt!)) {
        err = l.posGiftExpired(formatDate(card.expiresAt!));
      } else if (card.balance <= 0) {
        err = l.posGiftEmpty;
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
    final err = s.errorIn(context.l10n) ?? _validateExtras();
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
            registerId: widget.registerId,
            payments: payments,
            applyCashRounding: s.nonCash == 0,
            debtDueDate: s.debt > 0 ? _debtDue : null,
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
    final l = context.l10n;
    final extrasError = _validateExtras();
    final canConfirm = s.errorIn(l) == null && extrasError == null && !_busy;
    final tenders =
        quickTenders(s.cashNeeded, Money.currency, notes: ref.watch(posBanknotesProvider));
    final rounding = hasNonCash ? 0 : widget.total - _cashTotal;
    // no keyboard hints on phones
    final compact = context.isCompact;

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
                MoneyField(label: label, controller: c, onSubmitted: (_) => _confirm()),
                // own Text instead of the field's helper: it wraps on phones
                // instead of being cut off with an ellipsis
                if (helper != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Gap.l, Gap.xs, 0, 0),
                    child: Text(helper,
                        style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                  ),
                ?extra,
              ]),
            ),
            const SizedBox(width: Gap.s),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(
                width: _trailingWidth(context),
                child: TextButton(
                  style: TextButton.styleFrom(padding: _kTrailingPadding),
                  onPressed: () => _payAllBy(c, cap: cap),
                  child: Text(l.posAll),
                ),
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
                  Text(l.posToPay, style: t.textTheme.titleSmall),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(Money.format(s.total),
                        key: const Key('pay-total'),
                        style: t.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800, color: t.colorScheme.onPrimaryContainer)),
                  ),
                  if (rounding > 0)
                    Text(l.posRounding(Money.format(rounding)),
                        key: const Key('pay-rounding'),
                        style: t.textTheme.bodyMedium?.copyWith(
                            color: t.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600)),
                  if (customer != null)
                    Text(l.posCustomerValue(customer.name), style: t.textTheme.bodySmall),
                ]),
              ),
              IconButton(
                tooltip: l.posCloseEsc,
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
                    labelText: l.posCashReceived,
                    helperText: hasNonCash ? l.posCashNeeded(Money.format(s.cashNeeded)) : null,
                    helperMaxLines: 2,
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
                // Quick tenders: the chip matching the typed cash is shown as
                // selected (a permanent check mark on "Без сдачи" read as
                // "selected" even when another amount was typed). Amounts go
                // without the currency: the field already shows it, and short
                // chips fit in one row on desktop and two on phones.
                Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
                  ChoiceChip(
                    key: const Key('pay-exact'),
                    label: Text(l.posNoChange),
                    selected: s.cashNeeded > 0 && s.cash == s.cashNeeded,
                    onSelected: (_) => _setCash(s.cashNeeded),
                  ),
                  for (final v in tenders)
                    ChoiceChip(
                      label: Text(Money.format(v, withSymbol: false)),
                      selected: s.cash == v,
                      onSelected: (_) => _setCash(v),
                    ),
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
                      label: Text(l.posByCard),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        _payAllBy(_transfer);
                        setState(() => _showMore = true);
                        _cashFocus.requestFocus();
                      },
                      icon: const Icon(Icons.qr_code_2),
                      label: Text(l.posByTransfer),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showMore = true),
                      icon: const Icon(Icons.call_split),
                      label: Text(l.posMixed),
                    ),
                  ])
                else ...[
                  methodRow(icon: Icons.credit_card, label: l.payCard, c: _card),
                  methodRow(
                    icon: Icons.qr_code_2,
                    label: l.payTransfer,
                    c: _transfer,
                    extra: _v(_transfer) > 0
                        ? Padding(
                            padding: const EdgeInsets.only(top: Gap.s),
                            child: TextField(
                              controller: _transferRef,
                              decoration: InputDecoration(labelText: l.posTransferRef),
                            ),
                          )
                        : null,
                  ),
                  if (loyalty)
                    methodRow(
                      icon: Icons.stars_outlined,
                      label: l.payBonus,
                      c: _bonus,
                      cap: _maxBonus,
                      helper:
                          l.posBonusHelper(Money.format(customer.bonusBalance), Money.format(_maxBonus)),
                    ),
                  if (customer != null)
                    methodRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: l.payDebt,
                      c: _debt,
                      cap: _debtAvailable,
                      helper: _debtAvailable == null
                          ? l.posDebtNoLimit(Money.format(customer.debtBalance))
                          : l.posDebtHelper(Money.format(customer.debtBalance), Money.format(customer.debtLimit),
                              Money.format(_debtAvailable!)),
                      extra: s.debt > 0 ? _debtDueRow(t) : null,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: Gap.m),
                      child: Text(
                          compact
                              ? l.posSelectCustomerForDebt
                              : l.posSelectCustomerForDebtF4,
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
                            labelText: l.posGiftCode,
                            errorText: _giftError,
                            helperText: _giftCard == null
                                ? null
                                : l.posGiftBalance(Money.format(_giftCard!.balance)) +
                                    (_giftCard!.expiresAt == null
                                        ? ''
                                        : ' · ${l.posUntil(formatDate(_giftCard!.expiresAt!))}'),
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
                        child: SizedBox(
                          width: _trailingWidth(context),
                          child: TextButton(
                            style: TextButton.styleFrom(padding: _kTrailingPadding),
                            onPressed: _checkingGift ? null : _checkGift,
                            child: FittedBox(child: Text(l.posCheck)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  if (_giftCard != null)
                    methodRow(
                        icon: Icons.redeem,
                        label: l.posPayByGift,
                        c: _gift,
                        cap: _giftCard!.balance),
                ],
              ]),
            ),
          ),
          // ---- footer (divider: the methods above scroll under it)
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.m, Gap.xl, Gap.l),
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
                  label: Text(_busy ? l.posProcessing : (compact ? l.posConfirmPay : l.posConfirmPayEnter),
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
    final l = context.l10n;
    final missing = split.missing > 0 || split.nonCashTooBig;
    final color = missing ? AppColors.danger : AppColors.success;
    final label = split.nonCashTooBig
        ? l.posNonCashOverpay
        : missing
            ? l.posMissingLabel
            : l.commonChange;
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
