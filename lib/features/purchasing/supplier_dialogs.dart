import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'purchasing_logic.dart';
import '../../l10n/l10n.dart';

/// Create/edit supplier. Returns the supplier id or null.
Future<String?> showSupplierForm(BuildContext context, {Supplier? supplier}) => showFormDialog<String>(
  context,
  title: supplier == null ? context.l10n.purNewSupplier : context.l10n.commonSupplier,
  width: 560,
  child: _SupplierForm(supplier),
);

class _SupplierForm extends ConsumerStatefulWidget {
  const _SupplierForm(this.s);
  final Supplier? s;
  @override
  ConsumerState<_SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends ConsumerState<_SupplierForm> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.s?.name);
  late final _phone = TextEditingController(text: widget.s?.phone);
  late final _contact = TextEditingController(text: widget.s?.contactPerson);
  late final _tax = TextEditingController(text: widget.s?.taxId);
  late final _address = TextEditingController(text: widget.s?.address);
  late final _note = TextEditingController(text: widget.s?.note);
  bool _busy = false;

  Future<void> _save() async {
    if (_busy || !_key.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final id = await ref
          .read(purchasingRepoProvider)
          .saveSupplier(
            SupplierInput(
              name: _name.text,
              phone: _phone.text,
              contactPerson: _contact.text,
              taxId: _tax.text,
              address: _address.text,
              note: _note.text,
            ),
            id: widget.s?.id,
            userId: ref.read(sessionProvider)?.user.id,
          );
      if (!mounted) return;
      showSuccess(context, widget.s == null ? context.l10n.purSupplierAdded : context.l10n.purChangesSaved);
      Navigator.pop(context, id);
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget f(
      TextEditingController c,
      String label, {
      bool autofocus = false,
      TextInputType? kb,
      String? Function(String?)? v,
      int lines = 1,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: Gap.m),
      child: TextFormField(
        controller: c,
        autofocus: autofocus,
        keyboardType: kb,
        maxLines: lines,
        decoration: InputDecoration(labelText: label),
        validator: v,
        textInputAction: lines > 1 ? TextInputAction.newline : TextInputAction.next,
        onFieldSubmitted: lines > 1 ? null : (_) => _save(),
      ),
    );
    return Form(
      key: _key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            f(
              _name,
              l.purNameRequiredLabel,
              autofocus: true,
              v: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return l.purEnterSupplierName;
                if (t.length > 160) return l.purMax160Chars;
                return null;
              },
            ),
            f(
              _phone,
              l.commonPhone,
              kb: TextInputType.phone,
              v: (v) {
                final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if ((v ?? '').trim().isNotEmpty && d.length < 7) return l.purCheckPhone;
                return null;
              },
            ),
            f(_contact, l.purContactPerson),
            f(
              _tax,
              l.purTaxId,
              v: (v) {
                final t = (v ?? '').trim();
                if (t.isNotEmpty && !RegExp(r'^\d{9,14}$').hasMatch(t)) return l.purTaxIdInvalid;
                return null;
              },
            ),
            f(_address, l.commonAddress),
            f(_note, l.commonNote, lines: 3),
            FilledButton(onPressed: _busy ? null : _save, child: Text(l.commonSave)),
          ],
        ),
      ),
    );
  }
}

/// Supplier payment dialog. Returns true when a payment was recorded.
Future<bool> showSupplierPaymentDialog(BuildContext context, Supplier s, {PurchaseOrder? order, int? suggested}) async {
  final r = await showFormDialog<bool>(
    context,
    title: context.l10n.purPaymentTitle,
    width: 480,
    child: _PaymentForm(s, order: order, suggested: suggested),
  );
  return r ?? false;
}

class _PaymentForm extends ConsumerStatefulWidget {
  const _PaymentForm(this.s, {this.order, this.suggested});
  final Supplier s;
  final PurchaseOrder? order;
  final int? suggested;
  @override
  ConsumerState<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<_PaymentForm> {
  final _key = GlobalKey<FormState>();
  late int? _amount = widget.suggested ?? (widget.s.balance > 0 ? widget.s.balance : null);
  String _method = 'transfer';
  final _note = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    if (_busy || !_key.currentState!.validate()) return;
    final l = context.l10n;
    final amount = _amount!;
    final shift = ref.read(currentShiftProvider).value;
    if (_method == 'cash' && shift == null) {
      showError(context, l.purCashNeedsShift);
      return;
    }
    final live = ref.read(purSupplierProvider(widget.s.id)).value ?? widget.s;
    var overpay = false;
    if (amount > live.balance) {
      overpay = await confirm(
        context,
        title: l.purOverpayTitle,
        message: l.purOverpayMessage(
          Money.format(live.balance),
          Money.format(amount),
          Money.format(amount - (live.balance > 0 ? live.balance : 0)),
        ),
        ok: l.purPayWithAdvance,
      );
      if (!overpay || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(purchasingRepoProvider)
          .paySupplier(
            supplierId: widget.s.id,
            amount: amount,
            method: _method,
            shiftId: shift?.id,
            orderId: widget.order?.id,
            userId: ref.read(sessionProvider)?.user.id,
            note: _note.text,
            allowOverpay: overpay,
          );
      if (!mounted) return;
      showSuccess(context, l.purPaymentDone(Money.format(amount)));
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
    final l = context.l10n;
    final live = ref.watch(purSupplierProvider(widget.s.id)).value ?? widget.s;
    final shift = ref.watch(currentShiftProvider).value;
    final canCash = ref.watch(sessionProvider)?.can(Perm.cashInOut) ?? false;
    return Form(
      key: _key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(live.name, style: t.textTheme.titleMedium),
            if (widget.order != null) Text(l.purOrderNumber('${widget.order!.number}')),
            Text(
              live.balance >= 0
                  ? l.purOurDebtValue(Money.format(live.balance))
                  : l.purAdvanceValue(Money.format(-live.balance)),
              style: TextStyle(
                color: live.balance > 0 ? AppColors.danger : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Gap.l),
            MoneyField(
              label: l.purAmountRequired,
              initial: _amount,
              required: true,
              allowZero: false,
              autofocus: true,
              onChanged: (v) => _amount = v,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Gap.m),
            Text(l.commonPaymentMethod, style: t.textTheme.labelLarge),
            const SizedBox(height: Gap.s),
            Wrap(
              spacing: Gap.s,
              runSpacing: Gap.xs,
              children: [
                for (final e in paymentMethodLabelsOf(l).entries)
                  Tooltip(
                    message: e.key == 'cash' && !canCash ? l.purNoCashOutPermission : '',
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _method == e.key,
                      onSelected: e.key != 'cash' || canCash ? (_) => setState(() => _method = e.key) : null,
                    ),
                  ),
              ],
            ),
            if (_method == 'cash')
              Padding(
                padding: const EdgeInsets.only(top: Gap.s),
                child: Text(
                  shift == null
                      ? l.purShiftClosedNoCash
                      : l.purCashOutFromShift('${shift.number}'),
                  style: t.textTheme.bodySmall?.copyWith(color: shift == null ? AppColors.danger : null),
                ),
              ),
            const SizedBox(height: Gap.m),
            TextField(
              controller: _note,
              decoration: InputDecoration(labelText: l.purPaymentCommentLabel),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Gap.l),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.payments_outlined),
              label: Text(l.purPay),
            ),
          ],
        ),
      ),
    );
  }
}
