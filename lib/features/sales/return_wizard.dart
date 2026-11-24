// Return wizard: pick items/qty, see the exact refund, choose refund method,
// restock toggle, reason. Calls SaleService.returnItems.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/services/sale_service.dart';
import '../../l10n/l10n.dart';
import 'sales_logic.dart';
import 'sales_queries.dart';

/// Opens the wizard (dialog on wide screens, full-screen page on phones).
/// Returns the created [Return] or null if cancelled.
Future<Return?> showReturnWizard(BuildContext context, SaleDetail detail) {
  final title = context.l10n.salesReturnWizardTitle('${detail.sale.number}');
  if (context.isCompact) {
    return Navigator.of(context).push<Return>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ReturnWizard(detail: detail),
        ),
      ),
    );
  }
  return showFormDialog<Return>(
    context,
    title: title,
    width: 780,
    child: ReturnWizard(detail: detail),
  );
}

class ReturnWizard extends ConsumerStatefulWidget {
  const ReturnWizard({super.key, required this.detail, this.now});
  final SaleDetail detail;

  /// For tests.
  final DateTime? now;

  @override
  ConsumerState<ReturnWizard> createState() => _ReturnWizardState();
}

class _ReturnWizardState extends ConsumerState<ReturnWizard> {
  late final List<SaleItem> _items = widget.detail.items.where((i) => availableToReturn(i) > 1e-9).toList();
  late final Map<String, TextEditingController> _ctl = {
    for (final i in _items)
      i.id: TextEditingController(text: _items.length == 1 ? Qty.format(availableToReturn(i)) : '0'),
  };
  late String _method = defaultRefundMethod(widget.detail.payments, hasCustomer: widget.detail.customer != null);
  bool _restock = true;
  final _reason = TextEditingController();
  bool _busy = false;
  bool _triedSubmit = false;

  @override
  void dispose() {
    for (final c in _ctl.values) {
      c.dispose();
    }
    _reason.dispose();
    super.dispose();
  }

  double? _parse(String s) => QtyField.parse(s.isEmpty ? '0' : s);

  /// Validation message for a line or null.
  String? _lineError(SaleItem it) {
    final q = _parse(_ctl[it.id]!.text);
    final l = context.l10n;
    if (q == null || q < 0) return l.commonEnterNumber;
    final avail = availableToReturn(it);
    if (q > avail + 1e-9) return l.salesNotMore(Qty.format(avail));
    if (!Qty.isFractional(widget.detail.unitOf(it)) && q != q.roundToDouble()) return l.salesIntegerOnly;
    return null;
  }

  Map<String, double> get _selection => {
    for (final it in _items)
      if (_lineError(it) == null && (_parse(_ctl[it.id]!.text) ?? 0) > 0) it.id: Qty.round(_parse(_ctl[it.id]!.text)!),
  };

  void _setQty(SaleItem it, double q) {
    final avail = availableToReturn(it);
    final v = q.clamp(0, avail).toDouble();
    setState(() => _ctl[it.id]!.text = Qty.format(v));
  }

  void _all() {
    for (final it in _items) {
      _ctl[it.id]!.text = Qty.format(availableToReturn(it));
    }
    setState(() {});
  }

  void _none() {
    for (final it in _items) {
      _ctl[it.id]!.text = '0';
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (_busy) return; // Enter / Ctrl+Enter / double click while confirming or saving
    setState(() => _triedSubmit = true);
    final d = widget.detail;
    final l = context.l10n;
    final sel = _selection;
    final hasErrors = _items.any((i) => _lineError(i) != null);
    if (hasErrors) return showError(context, l.salesCheckQty);
    if (sel.isEmpty) return showError(context, l.salesSelectItems);
    if (_reason.text.trim().isEmpty) return showError(context, l.salesEnterReason);
    final shift = ref.read(currentShiftProvider).value;
    if (_method == 'cash' && shift == null) {
      return showError(context, l.salesOpenShiftForCash);
    }
    final total = previewRefund(_items, sel);
    setState(() => _busy = true);
    final ok = await confirm(
      context,
      title: l.salesConfirmReturnTitle,
      message: l.salesConfirmReturnMessage(
        paymentMethodLabel(_method, l),
        Money.format(total),
        '${sel.length}',
        _restock ? l.salesRestockYes : l.salesRestockNo,
      ),
      ok: l.salesDoReturn,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _busy = false);
      return;
    }
    try {
      final session = ref.read(sessionProvider)!;
      final ret = await ref
          .read(saleServiceProvider)
          .returnItems(
            saleId: d.sale.id,
            lines: [for (final e in sel.entries) ReturnLineInput(e.key, e.value)],
            refundMethod: _method,
            userId: session.user.id,
            shiftId: shift?.id,
            reason: _reason.text.trim(),
            restock: _restock,
          );
      if (mounted) Navigator.of(context).pop(ret);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final t = Theme.of(context);
    final l = context.l10n;
    final now = widget.now ?? DateTime.now();
    final expired = returnPeriodExpired(d.sale, ref.watch(settingProvider('return_days')), now);
    final shift = ref.watch(currentShiftProvider).value;
    final sel = _selection;
    final total = previewRefund(_items, sel);
    final fully = d.items.every((i) => (availableToReturn(i) - (sel[i.id] ?? 0)).abs() < 1e-9);
    final claw = d.customer == null ? 0 : previewBonusClawback(d.sale, total, fully: fully);
    final options = refundMethodOptions(hasCustomer: d.customer != null);
    final cashBlocked = _method == 'cash' && shift == null;

    if (_items.isEmpty) {
      return EmptyState(icon: Icons.done_all, title: l.salesAllReturned);
    }

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.l),
      shrinkWrap: true,
      children: [
        if (expired != null)
          InfoBanner(
            color: AppColors.danger,
            icon: Icons.event_busy,
            text: l.salesReturnExpiredBanner(expired, formatDate(d.sale.createdAt)),
          ),
        Row(
          children: [
            Expanded(child: Text(l.salesWhatToReturn, style: t.textTheme.titleSmall)),
            Expanded(
              flex: 2,
              child: Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton(onPressed: _none, child: Text(l.commonReset)),
                  TextButton(onPressed: _all, child: Text(l.salesReturnAll)),
                ],
              ),
            ),
          ],
        ),
        for (final it in _items) _line(it),
        const Divider(height: Gap.xl),
        Text(l.salesHowToRefund, style: t.textTheme.titleSmall),
        const SizedBox(height: Gap.s),
        Wrap(
          spacing: Gap.s,
          runSpacing: Gap.s,
          children: [
            for (final m in options)
              ChoiceChip(
                label: Text(paymentMethodLabel(m, l)),
                selected: _method == m,
                onSelected: (_) => setState(() => _method = m),
              ),
          ],
        ),
        const SizedBox(height: Gap.xs),
        Text(
          cashBlocked
              ? l.salesNoShiftNoCash
              : _method == 'debt' && d.customer != null && total > d.customer!.debtBalance
              ? l.salesDebtExcess(
                  Money.format(d.customer!.debtBalance),
                  Money.format(total - d.customer!.debtBalance),
                )
              : refundMethodHint(_method, l),
          style: t.textTheme.bodySmall?.copyWith(
            color: cashBlocked ? AppColors.danger : t.colorScheme.onSurfaceVariant,
          ),
        ),
        if (d.payments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Gap.xs),
            child: Text(
              l.salesPaidList(
                d.payments.map((p) => '${paymentMethodLabel(p.method, l)} ${Money.format(p.amount)}').join(', '),
              ),
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
          ),
        const Divider(height: Gap.xl),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _restock,
          onChanged: (v) => setState(() => _restock = v),
          title: Text(l.salesRestockTitle),
          subtitle: Text(
            _restock
                ? l.salesRestockOn
                : l.salesRestockOff,
          ),
        ),
        const SizedBox(height: Gap.s),
        Text(l.commonReason, style: t.textTheme.titleSmall),
        const SizedBox(height: Gap.s),
        Wrap(
          spacing: Gap.s,
          runSpacing: Gap.s,
          children: [
            for (final (i, r) in quickReturnReasons(l).indexed)
              ActionChip(
                label: Text(r),
                onPressed: () => setState(() {
                  _reason.text = i == quickReasonOther ? '' : r;
                  if (i == quickReasonDefect) _restock = false;
                }),
              ),
          ],
        ),
        const SizedBox(height: Gap.s),
        TextField(
          controller: _reason,
          decoration: InputDecoration(
            labelText: l.salesReasonLabel,
            errorText: _triedSubmit && _reason.text.trim().isEmpty ? l.salesReasonRequired : null,
          ),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _busy || expired != null ? null : _submit(),
        ),
        if (claw > 0)
          Padding(
            padding: const EdgeInsets.only(top: Gap.m),
            child: InfoBanner(
              color: AppColors.info,
              icon: Icons.stars_outlined,
              text: l.salesBonusClawback(Money.format(claw)),
            ),
          ),
      ],
    );

    final footer = Container(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.m, Gap.xl, Gap.l),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.salesToRefund, style: t.textTheme.bodySmall),
                // Scales down instead of wrapping next to a long button label (uz/ky).
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Money.format(total),
                    key: const Key('return-total'),
                    style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _busy || expired != null || sel.isEmpty || cashBlocked ? null : _submit,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.assignment_return),
            label: Text(l.salesDoReturn),
          ),
        ],
      ),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop(),
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (!_busy && expired == null) _submit();
        },
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(child: body),
          footer,
        ],
      ),
    );
  }

  Widget _line(SaleItem it) {
    final t = Theme.of(context);
    final l = context.l10n;
    final unit = widget.detail.unitOf(it);
    final avail = availableToReturn(it);
    final err = _lineError(it);
    final q = err == null ? (_parse(_ctl[it.id]!.text) ?? 0) : 0.0;
    final refund = err == null ? previewLineRefund(it, q) : 0;
    const step = 1.0;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(it.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(
          [
            l.salesBought(Qty.format(it.qty, unit, l)),
            if (it.returnedQty > 0) l.salesReturnedQty(Qty.format(it.returnedQty, unit, l)),
            l.salesPaidAmount(Money.format(it.total)),
          ].join(' · '),
          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
        ),
      ],
    );
    final stepper = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l.salesLess,
          onPressed: q <= 0 ? null : () => _setQty(it, q - step),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 84,
          child: TextField(
            key: Key('qty-${it.id}'),
            controller: _ctl[it.id],
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(errorText: err, errorMaxLines: 2, helperText: l.salesOfQty(Qty.format(avail))),
            onChanged: (_) => setState(() {}),
          ),
        ),
        IconButton(
          tooltip: l.salesMore,
          onPressed: q >= avail - 1e-9 ? null : () => _setQty(it, q + step),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
    final amount = SizedBox(
      width: 110,
      child: Text(
        refund > 0 ? Money.format(refund) : '—',
        textAlign: TextAlign.right,
        style: TextStyle(fontWeight: FontWeight.w600, color: refund > 0 ? AppColors.success : null),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs),
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                Row(children: [stepper, const Spacer(), amount]),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              stepper,
              amount,
            ],
          );
        },
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.color, required this.icon, required this.text});
  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: Gap.m),
    padding: const EdgeInsets.all(Gap.m),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: Gap.m),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
