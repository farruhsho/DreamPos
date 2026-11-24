// Small dialogs used by the POS screen: quantity, price, discount, manager
// approval, opening a shift, seller choice and the parked receipts list.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/permissions.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../cart_controller.dart';
import '../parked_carts.dart';
import '../pos_providers.dart';

// ------------------------------------------------------------------ quantity

/// Asks for an exact quantity (weight for kg). Returns null when cancelled.
Future<double?> askQty(BuildContext context, {required String title, required String unit, double? initial}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _QtyDialog(title: title, unit: unit, initial: initial),
  );
}

/// Stateful so that the text controller is disposed with the dialog.
class _QtyDialog extends StatefulWidget {
  const _QtyDialog({required this.title, required this.unit, this.initial});
  final String title;
  final String unit;
  final double? initial;

  @override
  State<_QtyDialog> createState() => _QtyDialogState();
}

class _QtyDialogState extends State<_QtyDialog> {
  late final _ctl = TextEditingController(
      text: widget.initial == null ? '' : Qty.format(widget.initial!).replaceAll(' ', ''));
  final _key = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ctl.selection = TextSelection(baseOffset: 0, extentOffset: _ctl.text.length);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(context, Qty.round(QtyField.parse(_ctl.text)!));
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _key,
        child: SizedBox(
          width: 320,
          child: TextFormField(
            controller: _ctl,
            autofocus: true,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(
              labelText: Qty.isFractional(unit) ? l.posQtyWeight : l.commonQty,
              suffixText: Qty.unitLabel(unit, l),
              helperText: Qty.isFractional(unit) ? l.posQtyExample : null,
            ),
            validator: (v) => validateQty(QtyField.parse(v ?? ''), unit, l),
            onFieldSubmitted: (_) => _submit(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton(onPressed: _submit, child: Text(l.commonOk)),
      ],
    );
  }
}

// ------------------------------------------------------------------ price

Future<int?> askPrice(BuildContext context, CartLine line) {
  return showDialog<int>(context: context, builder: (_) => _PriceDialog(line: line));
}

class _PriceDialog extends StatefulWidget {
  const _PriceDialog({required this.line});
  final CartLine line;

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final _ctl = TextEditingController(text: Money.toInput(widget.line.unitPrice));
  final _key = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ctl.selection = TextSelection(baseOffset: 0, extentOffset: _ctl.text.length);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(context, Money.parse(_ctl.text));
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final t = Theme.of(context);
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.posSalePrice),
      content: Form(
        key: _key,
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.name, style: t.textTheme.titleSmall),
              const SizedBox(height: Gap.xs),
              Text(l.posListPrice(Money.format(line.basePrice)), style: t.textTheme.bodySmall),
              const SizedBox(height: Gap.m),
              MoneyField(
                label: l.posNewPrice,
                controller: _ctl,
                autofocus: true,
                required: true,
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (line.priceEdited)
          TextButton(
            onPressed: () => Navigator.pop(context, line.basePrice),
            child: Text(l.posRestoreListPrice),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton(onPressed: _submit, child: Text(l.commonApply)),
      ],
    );
  }
}

// ------------------------------------------------------------------ discount

class DiscountInput {
  const DiscountInput({this.amount = 0, this.percent = 0});
  final int amount;
  final double percent;
  bool get isZero => amount <= 0 && percent <= 0;
}

/// Manual discount entry, by percent or amount. [base] is the amount the
/// discount applies to (used to validate and show the result).
Future<DiscountInput?> askDiscount(
  BuildContext context, {
  required String title,
  required int base,
  required double limitPercent,
  int currentAmount = 0,
  double currentPercent = 0,
}) {
  return showDialog<DiscountInput>(
    context: context,
    builder: (_) => _DiscountDialog(
      title: title,
      base: base,
      limitPercent: limitPercent,
      currentAmount: currentAmount,
      currentPercent: currentPercent,
    ),
  );
}

class _DiscountDialog extends StatefulWidget {
  const _DiscountDialog({
    required this.title,
    required this.base,
    required this.limitPercent,
    required this.currentAmount,
    required this.currentPercent,
  });
  final String title;
  final int base;
  final double limitPercent;
  final int currentAmount;
  final double currentPercent;

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  late bool _percent = widget.currentAmount <= 0;
  late final _ctl = TextEditingController(
    text: widget.currentPercent > 0
        ? _fmtPct(widget.currentPercent)
        : widget.currentAmount > 0
        ? Money.toInput(widget.currentAmount)
        : '',
  );
  final _key = GlobalKey<FormState>();

  /// 10 → "10", 12.5 → "12,5" (Russian decimal comma, no trailing zeros).
  static String _fmtPct(double p) => p == p.roundToDouble()
      ? p.toStringAsFixed(0)
      : p.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceAll('.', ',');

  double? get _pctValue => QtyField.parse(_ctl.text.isEmpty ? '0' : _ctl.text);
  int? get _amountValue => _ctl.text.trim().isEmpty ? 0 : Money.parse(_ctl.text);

  int get _discount {
    if (_percent) {
      final p = _pctValue ?? 0;
      return Money.percent(widget.base, p.clamp(0, 100).toDouble());
    }
    return _amountValue ?? 0;
  }

  double get _effectivePct => discountPercentOf(_discount, widget.base);

  String? _validate(String? v) {
    final l = context.l10n;
    if (_percent) {
      final p = QtyField.parse((v ?? '').isEmpty ? '0' : v!);
      if (p == null) return l.commonEnterNumber;
      if (p < 0) return l.commonCannotBeNegative;
      if (p > 100) return l.posNotMore100;
    } else {
      final a = (v ?? '').trim().isEmpty ? 0 : Money.parse(v!);
      if (a == null) return l.commonInvalidAmount;
      if (a < 0) return l.commonCannotBeNegative;
      if (a > widget.base) return l.posMoreThanAmount(Money.format(widget.base));
    }
    return null;
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(
      context,
      _percent
          ? DiscountInput(percent: (_pctValue ?? 0).toDouble())
          : DiscountInput(amount: _amountValue ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final over = !withinDiscountLimit(_effectivePct, widget.limitPercent);
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _key,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.posAmountValue(Money.format(widget.base)), style: t.textTheme.bodyMedium),
              const SizedBox(height: Gap.m),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(l.posPercentSeg)),
                  ButtonSegment(value: false, label: Text(l.commonAmount)),
                ],
                selected: {_percent},
                onSelectionChanged: (s) => setState(() {
                  _percent = s.first;
                  _ctl.clear();
                }),
              ),
              const SizedBox(height: Gap.m),
              TextFormField(
                controller: _ctl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))],
                decoration: InputDecoration(
                  labelText: _percent ? l.posDiscountPct : l.posDiscountAmount,
                  suffixText: _percent ? '%' : Money.currency.symbol,
                ),
                validator: _validate,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Gap.m),
              Text(
                l.posDiscountSummary(
                    Money.format(_discount), _fmtPct(_effectivePct), Money.format(widget.base - _discount)),
                style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: Gap.xs),
              Text(
                over
                    ? l.posOverLimit(_fmtPct(widget.limitPercent))
                    : l.posYourLimit(_fmtPct(widget.limitPercent)),
                style: t.textTheme.bodySmall?.copyWith(
                  color: over ? AppColors.warning : t.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.currentAmount > 0 || widget.currentPercent > 0)
          TextButton(
            onPressed: () => Navigator.pop(context, const DiscountInput()),
            child: Text(l.posRemoveDiscount),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton(onPressed: _submit, child: Text(l.commonApply)),
      ],
    );
  }
}

// ------------------------------------------------------------------ approval

/// Pure approval rule (unit-tested): may [approver] authorise a manual
/// discount of [percent] requested by [cashier]? Returns an error or null.
String? approvalError(User approver, User cashier, double percent, [AppLocalizations? l]) {
  final t = l ?? L.current;
  final role = Role.parse(approver.role);
  if (!role.can(Perm.applyDiscount)) {
    return t.posApproverNoPerm(approver.name);
  }
  if (approver.maxDiscountPercent <= cashier.maxDiscountPercent) {
    return t.posApproverLimitNotHigher(approver.name);
  }
  if (!withinDiscountLimit(percent, approver.maxDiscountPercent)) {
    return t.posApproverLimit(
        approver.name, approver.maxDiscountPercent.toStringAsFixed(0), percent.toStringAsFixed(1));
  }
  return null;
}

/// Asks a manager/owner PIN to approve a discount over the cashier's limit.
/// Does NOT change the current session. Returns the approver or null.
Future<User?> askManagerApproval(
  BuildContext context, {
  required User cashier,
  required double percent,
  required String what,
}) {
  return showDialog<User>(
    context: context,
    builder: (_) => _ApprovalDialog(cashier: cashier, percent: percent, what: what),
  );
}

class _ApprovalDialog extends ConsumerStatefulWidget {
  const _ApprovalDialog({required this.cashier, required this.percent, required this.what});
  final User cashier;
  final double percent;
  final String what;

  @override
  ConsumerState<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends ConsumerState<_ApprovalDialog> {
  String? _error;
  bool _busy = false;

  Future<void> _verify(String pin) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? err;
    final l = context.l10n;
    try {
      final u = await ref.read(authServiceProvider).verifyApprover(pin);
      err = u.id == widget.cashier.id
          ? l.posOtherPinNeeded
          : approvalError(u, widget.cashier, widget.percent, l);
      if (err == null) {
        if (mounted) Navigator.pop(context, u);
        return;
      }
    } catch (e) {
      err = errorText(e);
    }
    if (!mounted) return;
    setState(() {
      _error = err;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.posManagerApproval),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.posApprovalMessage(widget.what, widget.percent.toStringAsFixed(1),
                  widget.cashier.maxDiscountPercent.toStringAsFixed(0)),
              style: t.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gap.l),
            PinPad(onCompleted: _verify, error: _error, busy: _busy),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel))],
    );
  }
}

// ------------------------------------------------------------------ shift

/// Opens a shift. Returns true when opened.
Future<bool> showOpenShiftDialog(BuildContext context) async {
  final r = await showDialog<bool>(context: context, builder: (_) => const _OpenShiftDialog());
  return r ?? false;
}

class _OpenShiftDialog extends ConsumerStatefulWidget {
  const _OpenShiftDialog();
  @override
  ConsumerState<_OpenShiftDialog> createState() => _OpenShiftDialogState();
}

class _OpenShiftDialogState extends ConsumerState<_OpenShiftDialog> {
  final _key = GlobalKey<FormState>();
  int _cash = 0;
  bool _busy = false;

  Future<void> _submit() async {
    if (_busy || !_key.currentState!.validate()) return;
    final s = ref.read(sessionProvider);
    if (s == null) return;
    setState(() => _busy = true);
    try {
      final db = ref.read(databaseProvider);
      final registerId = await resolveDeviceRegisterId(db);
      await ref
          .read(shiftServiceProvider)
          .open(userId: s.user.id, openingCash: _cash, registerId: registerId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.posOpenShift),
      content: Form(
        key: _key,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.posOpenShiftHint),
              const SizedBox(height: Gap.l),
              MoneyField(
                label: l.posOpeningCash,
                initial: 0,
                autofocus: true,
                helper: l.posOpeningCashHelper,
                onChanged: (v) => _cash = v ?? 0,
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
        FilledButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.lock_open),
          label: Text(l.posOpenShift),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ seller

/// Returns '' to reset to "the cashier", a user id, or null when cancelled.
Future<String?> pickSeller(BuildContext context, {String? current}) {
  return showFormDialog<String>(
    context,
    title: context.l10n.posSellerConsultant,
    width: 420,
    child: Consumer(
      builder: (context, ref, _) {
        final users = ref.watch(posActiveUsersProvider);
        return SizedBox(
          height: 380,
          child: AsyncView(
            value: users,
            data: (list) => ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(context.l10n.posCashierDefault),
                  selected: current == null,
                  onTap: () => Navigator.pop(context, ''),
                ),
                const Divider(),
                for (final u in list)
                  ListTile(
                    leading: CircleAvatar(child: Text(u.name.characters.first.toUpperCase())),
                    title: Text(u.name),
                    subtitle: Text(Role.parse(u.role).labelIn(context.l10n)),
                    selected: u.id == current,
                    trailing: u.id == current ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(context, u.id),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// ------------------------------------------------------------------ parked

/// Shows parked receipts. Returns the chosen one (already removed from the
/// list) or null.
Future<ParkedCart?> showParkedList(BuildContext context) {
  return showFormDialog<ParkedCart>(
    context,
    title: context.l10n.posParkedReceipts,
    width: 560,
    child: const _ParkedList(),
  );
}

class _ParkedList extends ConsumerWidget {
  const _ParkedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parked = ref.watch(parkedCartsProvider);
    final t = Theme.of(context);
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.s, Gap.l),
      child: AsyncView(
        value: parked,
        data: (list) {
          if (list.isEmpty) {
            return SizedBox(
              height: 260,
              child: EmptyState(
                icon: Icons.pause_circle_outline,
                title: l.posNoParked,
                message: l.posNoParkedHint,
              ),
            );
          }
          final sorted = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.s, Gap.xs, Gap.s, Gap.s),
                child: Text(
                  l.posParkedTapHint,
                  style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = sorted[i];
                    final n = p.cart.lines.length;
                    final names = p.cart.lines.map((l) => l.name).take(3).join(', ');
                    final more = n > 3 ? ' ${l.posAndMore('${n - 3}')}' : '';
                    return ListTile(
                      autofocus: i == 0,
                      contentPadding: const EdgeInsets.only(left: Gap.s),
                      // phones: the room is better spent on the name and total
                      leading: context.isCompact ? null : const CircleAvatar(child: Icon(Icons.receipt_long)),
                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              p.note ?? p.cart.customerName ?? l.posReceiptFrom(formatTime(p.createdAt)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: Gap.s),
                          Text(
                            Money.format(p.grossTotal),
                            style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        [
                          [
                            formatDateTime(p.createdAt),
                            l.posPositions('$n'),
                            if (p.cashierName != null) p.cashierName!,
                          ].join(' · '),
                          '$names$more',
                        ].join('\n'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: l.posDeleteParked,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await confirm(
                            context,
                            title: l.posDeleteParkedQ,
                            message: l.posDeleteParkedMessage,
                            ok: l.commonDelete,
                            destructive: true,
                          );
                          if (ok) await ref.read(parkedCartsProvider.notifier).remove(p.id);
                        },
                      ),
                      onTap: () async {
                        final taken = await ref.read(parkedCartsProvider.notifier).take(p.id);
                        if (context.mounted) Navigator.pop(context, taken);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
