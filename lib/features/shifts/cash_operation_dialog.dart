import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'shift_logic.dart';

IconData cashKindIcon(String k) => switch (k) {
  'pay_in' => Icons.add_card,
  'pay_out' => Icons.outbox,
  'expense' => Icons.shopping_bag_outlined,
  'collection' => Icons.account_balance,
  _ => Icons.payments_outlined,
};

Color cashKindColor(String k) => switch (k) {
  'pay_in' => AppColors.success,
  'expense' => AppColors.warning,
  'collection' => AppColors.info,
  _ => AppColors.danger,
};

String cashKindHint(String k, [AppLocalizations? l]) {
  final t = l ?? L.current;
  return switch (k) {
    'pay_in' => t.shiftKindPayInHint,
    'pay_out' => t.shiftKindPayOutHint,
    'expense' => t.shiftKindExpenseHint,
    'collection' => t.shiftKindCollectionHint,
    _ => '',
  };
}

/// Records a cash movement for [shiftId]. Returns true on success.
Future<bool> showCashOperationDialog(
  BuildContext context, {
  required String shiftId,
  required String kind,
  required int cashInDrawer,
}) async {
  final r = await showFormDialog<bool>(
    context,
    title: cashKindLabel(kind, context.l10n),
    width: 480,
    child: _CashOpForm(shiftId: shiftId, kind: kind, cashInDrawer: cashInDrawer),
  );
  return r == true;
}

class _CashOpForm extends ConsumerStatefulWidget {
  const _CashOpForm({required this.shiftId, required this.kind, required this.cashInDrawer});
  final String shiftId;
  final String kind;
  final int cashInDrawer;

  @override
  ConsumerState<_CashOpForm> createState() => _CashOpFormState();
}

class _CashOpFormState extends ConsumerState<_CashOpForm> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  int? _amount;
  String? _category;
  bool _busy = false;

  bool get _isExpense => widget.kind == 'expense';
  bool get _isOut => widget.kind != 'pay_in';

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_isExpense && _category == null) {
      showError(context, context.l10n.shiftPickExpenseCategory);
      return;
    }
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() => _busy = true);
    final reason = _reason.text.trim();
    final ok = await runGuarded(
      context,
      () => ref
          .read(shiftServiceProvider)
          .cashMovement(
            shiftId: widget.shiftId,
            kind: widget.kind,
            amount: _amount!,
            userId: session.user.id,
            reason: reason.isEmpty ? (_isExpense ? _category : null) : reason,
            expenseCategory: _isExpense ? _category : null,
          ),
      success: '${cashKindLabel(widget.kind, context.l10n)}: ${Money.format(_amount!)}',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final reasonRequired = widget.kind == 'pay_out' || (_isExpense && _category == otherExpenseCategory);
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.s),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    cashKindHint(widget.kind, l),
                    style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  ),
                  if (_isOut)
                    Padding(
                      padding: const EdgeInsets.only(top: Gap.xs),
                      child: Text(l.shiftCashInDrawerNow(Money.format(widget.cashInDrawer)), style: t.textTheme.bodySmall),
                    ),
                  const SizedBox(height: Gap.l),
                  MoneyField(
                    key: const ValueKey('cash_amount'),
                    label: l.commonAmount,
                    required: true,
                    allowZero: false,
                    autofocus: true,
                    onChanged: (v) => _amount = v,
                    onSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null) return l.shiftEnterAmount;
                      if (_isOut && v > widget.cashInDrawer) {
                        return l.shiftOnlyInDrawer(Money.format(widget.cashInDrawer));
                      }
                      return null;
                    },
                  ),
                  if (_isExpense) ...[
                    const SizedBox(height: Gap.l),
                    Text(l.shiftExpenseCategory, style: t.textTheme.labelLarge),
                    const SizedBox(height: Gap.s),
                    Wrap(
                      spacing: Gap.s,
                      runSpacing: Gap.s,
                      children: [
                        for (final c in expenseCategories)
                          ChoiceChip(
                            label: Text(expenseCategoryLabel(c, l)),
                            selected: _category == c,
                            onSelected: (_) => setState(() => _category = c),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: Gap.l),
                  TextFormField(
                    controller: _reason,
                    decoration: InputDecoration(
                      labelText: reasonRequired ? l.shiftReasonRequired : l.commonComment,
                      hintText: widget.kind == 'pay_out' ? l.shiftPayOutHint : null,
                    ),
                    validator: (v) => reasonRequired && (v == null || v.trim().isEmpty) ? l.shiftEnterReason : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.m, Gap.xl, Gap.l),
            child: OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: Gap.s,
              children: [
                TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(l.commonCancel)),
                FilledButton(
                  key: const ValueKey('cash_submit'),
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? l.shiftSaving : l.shiftPost),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
