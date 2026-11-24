// «Продажа сертификата» (D-023): the single dialog for selling a gift card.
// Owned by marketing; the POS action («Продать сертификат») imports it, and
// Маркетинг > Сертификаты > «Выпустить» uses the same flow.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/printing/gift_receipt.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/pickers.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/errors.dart';
import '../../l10n/l10n.dart';
import '../pos/pos_providers.dart' show resolveDeviceRegisterId;
import 'gift_cards_tab.dart' show printGiftCard;
import 'gift_sales_logic.dart';
import 'marketing_repo.dart';

/// Setting: quick nominals in major units, comma separated ("50000,100000").
const giftQuickNominalsKey = 'gift_quick_nominals';
const _defaultQuickNominalsMajor = [50000, 100000, 200000, 500000];

/// Quick nominal buttons (minor units) from the setting, or the defaults.
List<int> giftQuickNominals(String? setting) {
  final parsed = (setting ?? '')
      .split(RegExp(r'[,;]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .map(Money.parse)
      .whereType<int>()
      .where((v) => v > 0)
      .toSet()
      .toList();
  if (parsed.isNotEmpty) return parsed;
  return [for (final m in _defaultQuickNominalsMajor) Money.parse('$m')!];
}

/// Payment mode of the dialog: one method or a split.
Map<String, String> _modes(AppLocalizations l) => {
  'cash': l.payCash,
  'card': l.payCard,
  'transfer': l.payTransfer,
  'mixed': l.mktPayMixed,
};

/// Whether [e] is the domain error «code already exists» (in any UI language).
bool _isCodeExistsError(Object e) {
  if (e is! BusinessException) return false;
  final text = e.toString();
  return L.current.errGiftCodeExists('\u0000').split('\u0000').every((part) => text.contains(part));
}

/// Context of the flow in progress; a flow whose screen was disposed (e.g.
/// logout) no longer blocks new ones.
BuildContext? _flowContext;

/// Full flow: permission + shift check, the sale dialog, then the success
/// dialog (number, code, «Печать», «Готово»). Returns the result or null.
/// One flow at a time (a double tap must not open two dialogs).
Future<GiftSaleResult?> sellGiftCard(BuildContext context, WidgetRef ref) async {
  if (_flowContext?.mounted ?? false) return null;
  final s = ref.read(sessionProvider);
  if (s == null || !s.can(Perm.sell)) {
    showError(context, context.l10n.mktNoSellRight);
    return null;
  }
  if (ref.read(currentShiftProvider).value == null) {
    showError(context, context.l10n.errOpenShiftToSellGift);
    return null;
  }
  final Object started = _flowContext = context;
  try {
    final res = await showGiftSaleDialog(context);
    if (res != null && context.mounted) await showGiftSaleSuccess(context, res);
    return res;
  } finally {
    if (identical(_flowContext, started)) _flowContext = null;
  }
}

/// The «Продажа сертификата» form dialog. Not dismissible while selling.
Future<GiftSaleResult?> showGiftSaleDialog(BuildContext context) => showDialog<GiftSaleResult>(
  context: context,
  barrierDismissible: false,
  builder: (c) => Dialog(
    insetPadding: const EdgeInsets.all(Gap.l),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.sizeOf(c).height * 0.92),
      child: const GiftSaleForm(),
    ),
  ),
);

class GiftSaleForm extends ConsumerStatefulWidget {
  const GiftSaleForm({super.key});
  @override
  ConsumerState<GiftSaleForm> createState() => _GiftSaleFormState();
}

class _GiftSaleFormState extends ConsumerState<GiftSaleForm> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _amount = TextEditingController();
  final _tendered = TextEditingController();
  final _cardPart = TextEditingController();
  final _transferPart = TextEditingController();
  final _reference = TextEditingController();
  DateTime? _expires = () {
    final n = DateTime.now();
    return DateTime(n.year + 1, n.month, n.day);
  }();
  Customer? _customer;
  String _mode = 'cash';
  bool _busy = false;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _regen();
  }

  @override
  void dispose() {
    for (final c in [_code, _amount, _tendered, _cardPart, _transferPart, _reference]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _regen() async {
    try {
      final c = await ref.read(marketingRepoProvider).generateUniqueGiftCode();
      if (mounted) {
        setState(() {
          _code.text = c;
          _codeError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _codeError = errorText(e));
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _expires ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      helpText: context.l10n.mktValidUntilInclusive,
    );
    if (d != null) setState(() => _expires = d);
  }

  // ------------------------------------------------------------ figures

  int get _nominal => Money.parse(_amount.text) ?? 0;
  int _parsed(TextEditingController c) => Money.parse(c.text) ?? 0;
  int get _card => switch (_mode) {
    'card' => _nominal,
    'mixed' => _parsed(_cardPart),
    _ => 0,
  };
  int get _transfer => switch (_mode) {
    'transfer' => _nominal,
    'mixed' => _parsed(_transferPart),
    _ => 0,
  };
  int get _cash => switch (_mode) {
    'cash' => _nominal,
    'mixed' => _nominal - _card - _transfer,
    _ => 0,
  };
  bool get _takesCash => _cash > 0 && (_mode == 'cash' || _mode == 'mixed');
  int? get _cashTendered => _takesCash && _tendered.text.trim().isNotEmpty ? Money.parse(_tendered.text) : null;
  int get _change {
    final t = _cashTendered;
    return t == null || t < _cash ? 0 : t - _cash;
  }

  /// Why the payment part is not valid yet (shown under the payment block).
  String? get _payError {
    if (_nominal <= 0) return null;
    final l = L.current;
    if (_mode == 'mixed') {
      if (_cash < 0) return l.mktPayExceeds(Money.format(-_cash));
      if (_card + _transfer == 0) return l.mktPayEnterCardTransfer;
    }
    final t = _cashTendered;
    if (t != null && t < _cash) return l.mktPayTenderedShort(Money.format(_cash));
    return null;
  }

  List<GiftSalePaymentInput> get _payments {
    final ref = _reference.text.trim().isEmpty ? null : _reference.text.trim();
    return [
      if (_cash > 0) GiftSalePaymentInput('cash', _cash),
      if (_card > 0) GiftSalePaymentInput('card', _card, reference: _mode == 'card' ? ref : null),
      if (_transfer > 0) GiftSalePaymentInput('transfer', _transfer, reference: _mode == 'transfer' ? ref : null),
    ];
  }

  void _setNominal(int v) {
    _amount.text = Money.groupInput(Money.toInput(v));
    setState(() {});
  }

  // ------------------------------------------------------------ submit

  Future<void> _submit() async {
    // Busy flag before the first await: a double Enter / double tap must not
    // sell the certificate (and take the money) twice.
    if (_busy || !_form.currentState!.validate()) return;
    final payErr = _payError;
    if (payErr != null) {
      showError(context, payErr);
      return;
    }
    final session = ref.read(sessionProvider);
    final shift = ref.read(currentShiftProvider).value;
    if (session == null) return;
    setState(() => _busy = true);
    try {
      final db = ref.read(databaseProvider);
      if (await ref.read(marketingRepoProvider).isGiftCodeTaken(_code.text)) {
        if (mounted) {
          setState(() {
            _codeError = context.l10n.mktCodeExists;
            _busy = false;
          });
        }
        return;
      }
      final registerId = await resolveDeviceRegisterId(db);
      final res = await ref
          .read(giftCardServiceProvider)
          .sell(
            GiftCardSaleRequest(
              code: _code.text,
              amount: _nominal,
              payments: _payments,
              cashierId: session.user.id,
              shiftId: shift?.id,
              registerId: registerId,
              customerId: _customer?.id,
              expiresAt: _expires == null ? null : DateTime(_expires!.year, _expires!.month, _expires!.day, 23, 59, 59),
              cashTendered: _cashTendered,
            ),
          );
      if (mounted) Navigator.pop(context, res);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (_isCodeExistsError(e)) {
          _codeError = context.l10n.mktCodeExists;
        }
      });
      showError(context, e);
    }
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final shift = ref.watch(currentShiftProvider).value;
    final nominals = giftQuickNominals(ref.watch(settingProvider(giftQuickNominalsKey)));
    final payErr = _payError;
    final muted = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);

    Widget picker({
      required String label,
      required IconData icon,
      required String value,
      required VoidCallback onTap,
      VoidCallback? onClear,
      String? clearTooltip,
    }) => InkWell(
      onTap: _busy ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: onClear == null
              ? null
              : IconButton(tooltip: clearTooltip, icon: const Icon(Icons.close), onPressed: onClear),
        ),
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );

    final expiry = picker(
      label: l.mktValidUntilLabel,
      icon: Icons.event,
      value: _expires == null ? l.mktNoExpiryCap : formatDate(_expires!),
      onTap: _pickExpiry,
      onClear: _expires == null ? null : () => setState(() => _expires = null),
      clearTooltip: l.mktNoExpiryCap,
    );
    final customer = picker(
      label: l.mktBuyerOptional,
      icon: Icons.person_outline,
      value: _customer?.name ?? l.mktNotSelected,
      onTap: () async {
        final c = await pickCustomer(context);
        if (c != null && mounted) setState(() => _customer = c);
      },
      onClear: _customer == null ? null : () => setState(() => _customer = null),
      clearTooltip: l.mktRemoveBuyer,
    );

    return PopScope(
      canPop: !_busy,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.l, Gap.s, 0),
              child: Row(
                children: [
                  Expanded(child: Text(l.mktGiftSaleTitle, style: t.textTheme.titleLarge)),
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: l.commonClose,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.l),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final twoCol = box.maxWidth >= 440;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          shift == null
                              ? l.mktShiftClosedNote
                              : l.mktShiftAdvanceNote('${shift.number}'),
                          style: shift == null ? const TextStyle(color: AppColors.danger, fontSize: 12) : muted,
                        ),
                        const SizedBox(height: Gap.m),
                        MoneyField(
                          key: const Key('gift-sale-amount'),
                          label: l.mktFaceValueRequired,
                          controller: _amount,
                          autofocus: true,
                          required: true,
                          allowZero: false,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: Gap.s),
                        Wrap(
                          spacing: Gap.xs,
                          runSpacing: Gap.xs,
                          children: [
                            for (final v in nominals)
                              ChoiceChip(
                                label: Text(Money.format(v)),
                                selected: _nominal == v,
                                onSelected: _busy ? null : (_) => _setNominal(v),
                              ),
                          ],
                        ),
                        const SizedBox(height: Gap.m),
                        TextFormField(
                          key: const Key('gift-sale-code'),
                          controller: _code,
                          enabled: !_busy,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontFamily: AppFonts.mono,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                            TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
                          ],
                          decoration: InputDecoration(
                            labelText: l.mktGiftCodeRequired,
                            errorText: _codeError,
                            helperText: l.mktGiftCodeHelper,
                            helperMaxLines: 2,
                            prefixIcon: const Icon(Icons.qr_code_scanner),
                            suffixIcon: IconButton(
                              tooltip: l.mktGenerate,
                              icon: const Icon(Icons.refresh),
                              onPressed: _busy ? null : _regen,
                            ),
                          ),
                          validator: (v) {
                            final c = normalizeGiftCode(v ?? '');
                            if (c.length < 6) return l.mktMin6Chars;
                            if (c.length > 32) return l.mktMax32Chars;
                            return null;
                          },
                          onChanged: (_) {
                            if (_codeError != null) setState(() => _codeError = null);
                          },
                        ),
                        const SizedBox(height: Gap.m),
                        if (twoCol)
                          Row(
                            children: [
                              Expanded(child: expiry),
                              const SizedBox(width: Gap.m),
                              Expanded(child: customer),
                            ],
                          )
                        else ...[
                          expiry,
                          const SizedBox(height: Gap.m),
                          customer,
                        ],
                        const SizedBox(height: Gap.l),
                        Text(l.commonPayment, style: t.textTheme.labelLarge),
                        const SizedBox(height: Gap.s),
                        Wrap(
                          spacing: Gap.xs,
                          runSpacing: Gap.xs,
                          children: [
                            for (final e in _modes(l).entries)
                              ChoiceChip(
                                label: Text(e.value),
                                selected: _mode == e.key,
                                onSelected: _busy ? null : (_) => setState(() => _mode = e.key),
                              ),
                          ],
                        ),
                        const SizedBox(height: Gap.m),
                        ..._paymentFields(twoCol),
                        const SizedBox(height: Gap.m),
                        _Summary(
                          nominal: _nominal,
                          cash: _mode == 'mixed' ? _cash : null,
                          change: _change,
                          error: payErr,
                        ),
                        const SizedBox(height: Gap.l),
                        FilledButton.icon(
                          key: const Key('gift-sale-submit'),
                          onPressed: _busy || shift == null ? null : _submit,
                          icon: _busy
                              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check),
                          label: Text(l.mktSellGift),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _paymentFields(bool twoCol) {
    final l = context.l10n;
    final tendered = MoneyField(
      key: const Key('gift-sale-tendered'),
      label: l.mktTenderedCash,
      controller: _tendered,
      enabled: !_busy,
      helper: l.mktTenderedHelper,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _submit(),
    );
    final reference = TextField(
      controller: _reference,
      enabled: !_busy,
      decoration: InputDecoration(
        labelText: _mode == 'card' ? l.mktSlipNumber : l.mktTransferNumber,
      ),
    );
    switch (_mode) {
      case 'cash':
        return [tendered];
      case 'card':
      case 'transfer':
        return [reference];
    }
    final card = MoneyField(
      key: const Key('gift-sale-card'),
      label: l.payCard,
      controller: _cardPart,
      enabled: !_busy,
      onChanged: (_) => setState(() {}),
    );
    final transfer = MoneyField(
      key: const Key('gift-sale-transfer'),
      label: l.payTransfer,
      controller: _transferPart,
      enabled: !_busy,
      onChanged: (_) => setState(() {}),
    );
    return [
      if (twoCol)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: card),
            const SizedBox(width: Gap.m),
            Expanded(child: transfer),
          ],
        )
      else ...[
        card,
        const SizedBox(height: Gap.m),
        transfer,
      ],
      if (_takesCash) ...[const SizedBox(height: Gap.m), tendered],
    ];
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.nominal, required this.cash, required this.change, required this.error});
  final int nominal;

  /// Cash part in split mode (null = not split).
  final int? cash;
  final int change;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    Widget line(String label, String value, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
    final big = t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    return Container(
      padding: const EdgeInsets.all(Gap.m),
      decoration: BoxDecoration(
        color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line(l.mktSimToPay, Money.format(nominal), style: big),
          if (cash != null && cash! > 0) line(l.mktInCash, Money.format(cash!)),
          if (change > 0) line(l.commonChange, Money.format(change), style: big?.copyWith(color: AppColors.warning)),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: Gap.xs),
              child: Text(
                error!,
                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ success

Future<void> showGiftSaleSuccess(BuildContext context, GiftSaleResult result) => showDialog<void>(
  context: context,
  builder: (_) => GiftSaleSuccessDialog(result: result),
);

/// After a sale: number, code (large), nominal, change; «Печать» (slip),
/// «Бланк» (the A6 certificate), «Готово».
class GiftSaleSuccessDialog extends ConsumerStatefulWidget {
  const GiftSaleSuccessDialog({super.key, required this.result});
  final GiftSaleResult result;

  @override
  ConsumerState<GiftSaleSuccessDialog> createState() => _GiftSaleSuccessDialogState();
}

class _GiftSaleSuccessDialogState extends ConsumerState<GiftSaleSuccessDialog> {
  bool _printing = false;

  Future<void> _run(Future<void> Function() job) async {
    if (_printing) return;
    setState(() => _printing = true);
    try {
      await job();
    } catch (e) {
      if (mounted) showError(context, context.l10n.mktPrintFailed(errorText(e)));
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final r = widget.result;
    final g = r.giftCard;
    return AlertDialog(
      icon: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
      title: Text(l.mktGiftSold),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.coreGiftSlipTitle('${r.number}'), style: t.textTheme.titleMedium),
              const SizedBox(height: Gap.m),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: SelectableText(
                  groupGiftCode(g.code),
                  key: const Key('gift-success-code'),
                  style: t.textTheme.headlineSmall?.copyWith(
                    fontFamily: AppFonts.mono,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: Gap.xs),
              Text(
                '${Money.format(g.initialAmount)} · '
                '${g.expiresAt == null ? l.coreGiftNoExpiry : l.mktUntil(formatDate(g.expiresAt!))}',
                style: t.textTheme.bodyMedium,
              ),
              if (r.changeDue > 0) ...[
                const SizedBox(height: Gap.l),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Gap.m),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(l.commonChange, style: t.textTheme.titleMedium),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Money.format(r.changeDue),
                          style: t.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _printing
              ? null
              : () => _run(() => printGiftCard(g, store: ref.read(settingProvider('store_name')) ?? 'DreamPOS')),
          icon: const Icon(Icons.card_giftcard),
          label: Text(l.mktBlank),
        ),
        OutlinedButton.icon(
          key: const Key('gift-success-print'),
          onPressed: _printing ? null : () => _run(() => printGiftReceipt(ref.read(databaseProvider), r.saleId)),
          icon: const Icon(Icons.print_outlined),
          label: Text(l.commonPrint),
        ),
        FilledButton(autofocus: true, onPressed: () => Navigator.pop(context), child: Text(l.commonDone)),
      ],
    );
  }
}
