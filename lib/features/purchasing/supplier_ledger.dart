// «Взаиморасчёты» with a supplier: ledger with running balance, period
// filter, payment cancellation, manual corrections and the reconciliation
// act (акт сверки) as PDF / CSV.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../inventory/inventory_logic.dart' show goodsReceiptNumbersProvider;
import '../reports/widgets/report_table_view.dart' show showSavedDialog;
import 'purchasing_logic.dart';
import 'statement_pdf.dart';

/// Payment ids with a cancellation in flight (double-tap protection across
/// the ledger and the payments list).
final _cancelling = <String>{};

/// Asks for a mandatory reason and cancels [p]. The dialog stays open on a
/// service error and shows it. Returns true when the payment was cancelled.
Future<bool> cancelSupplierPaymentFlow(BuildContext context, WidgetRef ref, SupplierPayment p) async {
  if (_cancelling.contains(p.id)) return false;
  final canCash = ref.read(sessionProvider)?.can(Perm.cashInOut) ?? false;
  if (!supplierPaymentCancelAllowed(p, canCash: canCash)) {
    showError(context, noCashPermissionText);
    return false;
  }
  _cancelling.add(p.id);
  try {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => ReasonActionDialog(
        title: 'Отменить оплату ${Money.format(p.amount)}?',
        message:
            'Оплата от ${formatDateTime(p.createdAt)} (${paymentMethodLabels[p.method] ?? p.method}) '
            'останется в истории с отметкой «Отменена», долг поставщику увеличится на эту сумму.'
            '${p.method == 'cash' ? '\nНаличную оплату можно отменить только пока открыта её смена.' : ''}',
        label: 'Причина отмены *',
        ok: 'Отменить оплату',
        destructive: true,
        success: 'Оплата ${Money.format(p.amount)} отменена',
        action: (reason) => ref
            .read(purchasingRepoProvider)
            .cancelSupplierPayment(p.id, reason: reason, userId: ref.read(sessionProvider)?.user.id),
      ),
    );
    return r ?? false;
  } finally {
    _cancelling.remove(p.id);
  }
}

/// Confirmation dialog with a mandatory reason that runs [action] itself:
/// the button is disabled while it runs, errors are shown in the dialog.
class ReasonActionDialog extends StatefulWidget {
  const ReasonActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.label,
    required this.ok,
    required this.action,
    this.success,
    this.destructive = false,
  });
  final String title;
  final String message;
  final String label;
  final String ok;
  final String? success;
  final bool destructive;
  final Future<void> Function(String reason) action;

  @override
  State<ReasonActionDialog> createState() => _ReasonActionDialogState();
}

class _ReasonActionDialogState extends State<ReasonActionDialog> {
  final _key = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_key.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.action(_reason.text.trim());
      if (!mounted) return;
      if (widget.success != null) showSuccess(context, widget.success!);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorText(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _key,
        child: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.message),
                const SizedBox(height: Gap.m),
                TextFormField(
                  controller: _reason,
                  autofocus: true,
                  maxLength: 200,
                  decoration: InputDecoration(labelText: widget.label),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Укажите причину' : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Gap.s),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Назад')),
        FilledButton(
          style: widget.destructive ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.ok),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ adjust

/// Manual balance correction (owner/admin). Returns true when posted.
Future<bool> showSupplierAdjustDialog(BuildContext context, Supplier s) async {
  final r = await showFormDialog<bool>(context, title: 'Корректировка баланса', width: 480, child: _AdjustForm(s));
  return r ?? false;
}

class _AdjustForm extends ConsumerStatefulWidget {
  const _AdjustForm(this.s);
  final Supplier s;
  @override
  ConsumerState<_AdjustForm> createState() => _AdjustFormState();
}

class _AdjustFormState extends ConsumerState<_AdjustForm> {
  final _key = GlobalKey<FormState>();
  final _reason = TextEditingController();
  int _sign = 1;
  int? _amount;
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_key.currentState!.validate()) return;
    setState(() => _busy = true);
    final delta = _sign * _amount!;
    try {
      await ref
          .read(purchasingRepoProvider)
          .adjustSupplierBalance(
            widget.s.id,
            delta,
            reason: _reason.text.trim(),
            userId: ref.read(sessionProvider)?.user.id,
          );
      if (!mounted) return;
      showSuccess(context, 'Корректировка ${delta > 0 ? '+' : '−'}${Money.format(delta.abs())} проведена');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final live = ref.watch(purSupplierProvider(widget.s.id)).value ?? widget.s;
    final after = live.balance + _sign * (_amount ?? 0);
    String bal(int b) => b >= 0 ? 'наш долг ${Money.format(b)}' : 'аванс ${Money.format(-b)}';
    return Form(
      key: _key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(live.name, style: t.textTheme.titleMedium),
            Text('Сейчас: ${bal(live.balance)}', style: t.textTheme.bodyMedium),
            const SizedBox(height: Gap.l),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 1, icon: Icon(Icons.add), label: Text('Увеличить долг')),
                ButtonSegment(value: -1, icon: Icon(Icons.remove), label: Text('Уменьшить долг')),
              ],
              selected: {_sign},
              onSelectionChanged: (v) => setState(() => _sign = v.first),
            ),
            const SizedBox(height: Gap.m),
            MoneyField(
              label: 'Сумма *',
              required: true,
              allowZero: false,
              autofocus: true,
              onChanged: (v) => setState(() => _amount = v),
            ),
            const SizedBox(height: Gap.m),
            TextFormField(
              controller: _reason,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Причина *', hintText: 'Например: по акту сверки от …'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Укажите причину корректировки' : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Gap.s),
            Text(
              'После корректировки: ${bal(after)}',
              style: TextStyle(fontWeight: FontWeight.w600, color: after > 0 ? AppColors.danger : AppColors.success),
            ),
            const SizedBox(height: Gap.l),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.tune),
              label: const Text('Провести корректировку'),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ ledger view

/// «Взаиморасчёты» tab of the supplier page.
class SupplierLedgerView extends ConsumerStatefulWidget {
  const SupplierLedgerView({super.key, required this.supplierId});
  final String supplierId;
  @override
  ConsumerState<SupplierLedgerView> createState() => _SupplierLedgerViewState();
}

class _SupplierLedgerViewState extends ConsumerState<SupplierLedgerView> {
  LedgerPeriod _period = LedgerPeriod.all;
  DateTimeRange? _range;
  bool _exporting = false;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _range,
      helpText: 'Период взаиморасчётов',
    );
    if (r != null && mounted) {
      setState(() {
        _range = r;
        _period = LedgerPeriod.custom;
      });
    }
  }

  Future<void> _export(String action, StatementData d) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      switch (action) {
        case 'print':
          await runGuarded(context, () => printStatement(d));
        case 'share':
          await runGuarded(context, () => shareStatement(d));
        case 'csv':
          String? path;
          final ok = await runGuarded(context, () async => path = await saveStatementCsv(d));
          if (ok && mounted && path != null) await showSavedDialog(context, path!);
        case 'copy':
          await runGuarded(
            context,
            () => Clipboard.setData(ClipboardData(text: d.toCsv())),
            success: 'Акт сверки скопирован — вставьте в Excel',
          );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.supplierId;
    final supplier = ref.watch(purSupplierProvider(id)).value;
    final numbers = ref.watch(goodsReceiptNumbersProvider).value ?? const <String, int>{};
    final payments = <String, SupplierPayment>{
      for (final p in ref.watch(purSupplierPaymentsProvider(id)).value ?? const <SupplierPayment>[]) p.id: p,
    };
    final canAdjust = ref.watch(sessionProvider)?.can(Perm.manageSettings) ?? false;
    final canCash = ref.watch(sessionProvider)?.can(Perm.cashInOut) ?? false;
    String op(SupplierLedgerEntry e) => supplierLedgerOperation(e, receiptNumbers: numbers, payments: payments);
    return AsyncView(
      value: ref.watch(purSupplierLedgerProvider(id)),
      onRetry: () => ref.invalidate(purSupplierLedgerProvider(id)),
      data: (entries) {
        final range = ledgerPeriodRange(_period, first: _range?.start, last: _range?.end);
        final st = SupplierStatement.of(entries, from: range.from, to: range.to);
        final data = supplier == null
            ? null
            : StatementData(
                supplier: supplier,
                statement: st,
                from: range.from,
                to: range.to,
                operation: op,
                settings: ref.watch(settingsProvider).value ?? const {},
              );
        final header = <Widget>[
          _PeriodBar(
            period: _period,
            range: _range,
            onSelect: (p) => p == LedgerPeriod.custom ? _pickRange() : setState(() => _period = p),
          ),
          const SizedBox(height: Gap.s),
          Wrap(
            spacing: Gap.s,
            runSpacing: Gap.s,
            children: [
              if (canAdjust && supplier != null)
                OutlinedButton.icon(
                  onPressed: () => showSupplierAdjustDialog(context, supplier),
                  icon: const Icon(Icons.tune),
                  label: const Text('Корректировка'),
                ),
              MenuAnchor(
                builder: (context, ctl, _) => OutlinedButton.icon(
                  onPressed: data == null || _exporting ? null : () => ctl.isOpen ? ctl.close() : ctl.open(),
                  icon: _exporting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.fact_check_outlined),
                  label: const Text('Акт сверки'),
                ),
                menuChildren: [
                  for (final (action, icon, text) in const [
                    ('print', Icons.print_outlined, 'Печать / PDF'),
                    ('share', Icons.share_outlined, 'Отправить PDF'),
                    ('csv', Icons.table_view_outlined, 'Сохранить CSV (Excel)'),
                    ('copy', Icons.copy, 'Копировать CSV'),
                  ])
                    MenuItemButton(
                      leadingIcon: Icon(icon),
                      onPressed: data == null ? null : () => _export(action, data),
                      child: Text(text),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Gap.s),
          _Totals(st: st),
          const SizedBox(height: Gap.s),
        ];
        if (entries.isEmpty || (st.rows.isEmpty && st.opening == 0)) {
          return ListView(
            children: [
              ...header,
              EmptyState(
                icon: Icons.account_balance_outlined,
                title: entries.isEmpty ? 'Взаиморасчётов ещё не было' : 'Операций за период нет',
                message: entries.isEmpty
                    ? 'Здесь появятся приходы, оплаты и корректировки с текущим балансом'
                    : 'Выберите другой период',
              ),
            ],
          );
        }
        return LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 640;
            // header + [column titles] + opening + rows + closing
            final lead = header.length + (wide ? 1 : 0);
            final count = lead + st.rows.length + 2;
            return ListView.builder(
              itemCount: count,
              itemBuilder: (context, i) {
                if (i < header.length) return header[i];
                if (wide && i == header.length) return const _ColumnTitles();
                final k = i - lead;
                if (k == 0) {
                  return _BalanceRow(label: 'Сальдо на начало периода', balance: st.opening, wide: wide);
                }
                if (k == st.rows.length + 1) {
                  return _BalanceRow(label: 'Сальдо на конец периода', balance: st.closing, wide: wide);
                }
                final e = st.rows[k - 1];
                final pay = e.kind == SupplierLedgerKind.payment && e.refId != null ? payments[e.refId] : null;
                final c = cancellablePayment(e, payments);
                final cancellable = c != null && supplierPaymentCancelAllowed(c, canCash: canCash) ? c : null;
                return _LedgerRow(
                  e: e,
                  operation: op(e),
                  wide: wide,
                  cancelled: pay?.cancelledAt != null,
                  onCancel: cancellable == null ? null : () => cancelSupplierPaymentFlow(context, ref, cancellable),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PeriodBar extends StatelessWidget {
  const _PeriodBar({required this.period, required this.range, required this.onSelect});
  final LedgerPeriod period;
  final DateTimeRange? range;
  final ValueChanged<LedgerPeriod> onSelect;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final p in LedgerPeriod.values)
        ChoiceChip(
          label: Text(
            p == LedgerPeriod.custom && period == LedgerPeriod.custom && range != null
                ? '${formatDate(range!.start)} – ${formatDate(range!.end)}'
                : p.label,
          ),
          selected: period == p,
          onSelected: (_) => onSelect(p),
        ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[if (i > 0) const SizedBox(width: Gap.s), chips[i]],
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.st});
  final SupplierStatement st;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget cell(String label, String value, {Color? color}) => Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
      ),
    );
    final cells = [
      cell('Сальдо на начало', _signed(st.opening)),
      cell('Приход (+)', Money.format(st.increase), color: st.increase > 0 ? AppColors.danger : null),
      cell('Расход (−)', Money.format(st.decrease), color: st.decrease > 0 ? AppColors.success : null),
      cell('Сальдо на конец', _signed(st.closing), color: st.closing > 0 ? AppColors.danger : AppColors.success),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth >= 640 ? 4 : 2;
        final w = (c.maxWidth - Gap.s * (perRow - 1)) / perRow;
        return Wrap(
          spacing: Gap.s,
          runSpacing: Gap.s,
          children: [for (final x in cells) SizedBox(width: w, child: x)],
        );
      },
    );
  }
}

/// Balance with a hint of direction: «аванс» for negative balances.
String _signed(int b) => b < 0 ? '${Money.format(-b)} аванс' : Money.format(b);

const _wDate = 120.0;
const _wMoney = 120.0;
const _wBalance = 140.0;
const _wAction = 40.0;

class _ColumnTitles extends StatelessWidget {
  const _ColumnTitles();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final s = t.textTheme.labelMedium?.copyWith(color: t.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600);
    Widget r(String x, double w) => SizedBox(
      width: w,
      child: Text(x, style: s, textAlign: TextAlign.right),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: Gap.xs),
      child: Row(
        children: [
          SizedBox(
            width: _wDate,
            child: Text('Дата', style: s),
          ),
          Expanded(child: Text('Операция', style: s)),
          r('Приход (+)', _wMoney),
          r('Расход (−)', _wMoney),
          r('Баланс', _wBalance),
          const SizedBox(width: _wAction),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.label, required this.balance, required this.wide});
  final String label;
  final int balance;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final style = t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    return Container(
      color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: Gap.s),
      child: Row(
        children: [
          if (wide) const SizedBox(width: _wDate),
          Expanded(child: Text(label, style: style)),
          Text(_signed(balance), style: style, textAlign: TextAlign.right),
          if (wide) const SizedBox(width: _wAction),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.e,
    required this.operation,
    required this.wide,
    required this.cancelled,
    this.onCancel,
  });
  final SupplierLedgerEntry e;
  final String operation;
  final bool wide;
  final bool cancelled;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final muted = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    final inc = e.amount > 0 ? Money.format(e.amount) : '';
    final dec = e.amount < 0 ? Money.format(-e.amount) : '';
    // Receipt rows carry «Приход №N» as their note: do not repeat it.
    final note = e.note == null || e.note == operation ? null : e.note;
    final upColor = cancelled ? t.colorScheme.onSurfaceVariant : AppColors.danger;
    final downColor = cancelled ? t.colorScheme.onSurfaceVariant : AppColors.success;
    final title = Wrap(
      spacing: Gap.s,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(operation, style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        if (cancelled) const StatusChip('Отменена', color: AppColors.danger),
      ],
    );
    final action = onCancel == null
        ? const SizedBox(width: _wAction)
        : SizedBox(
            width: _wAction,
            child: IconButton(
              tooltip: 'Отменить оплату',
              visualDensity: VisualDensity.compact,
              onPressed: onCancel,
              icon: const Icon(Icons.undo, color: AppColors.danger),
            ),
          );
    final Widget body;
    if (wide) {
      Widget money(String v, double w, {Color? c, bool bold = false}) => SizedBox(
        width: w,
        child: Text(
          v,
          textAlign: TextAlign.right,
          style: t.textTheme.bodyMedium?.copyWith(color: c, fontWeight: bold ? FontWeight.w700 : null),
        ),
      );
      body = Row(
        children: [
          SizedBox(
            width: _wDate,
            child: Text(formatDateTime(e.createdAt), style: muted),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                if (note != null) Text(note, style: muted, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          money(inc, _wMoney, c: upColor),
          money(dec, _wMoney, c: downColor),
          money(_signed(e.balanceAfter), _wBalance, bold: true),
          action,
        ],
      );
    } else {
      final amount = e.amount > 0 ? '+$inc' : '−$dec';
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                Text(
                  [formatDateTime(e.createdAt), ?note].join(' · '),
                  style: muted,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.s),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: t.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: e.amount > 0 ? upColor : downColor,
                ),
              ),
              Text('баланс ${_signed(e.balanceAfter)}', style: muted),
            ],
          ),
          if (onCancel != null) action,
        ],
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.dividerColor.withValues(alpha: 0.4))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: Gap.s),
        child: body,
      ),
    );
  }
}
