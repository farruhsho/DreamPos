import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'purchasing_logic.dart';

/// Create/edit supplier. Returns the supplier id or null.
Future<String?> showSupplierForm(BuildContext context, {Supplier? supplier}) => showFormDialog<String>(context,
    title: supplier == null ? 'Новый поставщик' : 'Поставщик', width: 560, child: _SupplierForm(supplier));

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
      final id = await ref.read(purchasingRepoProvider).saveSupplier(
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
      showSuccess(context, widget.s == null ? 'Поставщик добавлен' : 'Изменения сохранены');
      Navigator.pop(context, id);
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget f(TextEditingController c, String label,
            {bool autofocus = false, TextInputType? kb, String? Function(String?)? v, int lines = 1}) =>
        Padding(
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          f(_name, 'Название *', autofocus: true, v: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return 'Введите название поставщика';
            if (t.length > 160) return 'Не длиннее 160 символов';
            return null;
          }),
          f(_phone, 'Телефон', kb: TextInputType.phone, v: (v) {
            final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
            if ((v ?? '').trim().isNotEmpty && d.length < 7) return 'Проверьте номер телефона';
            return null;
          }),
          f(_contact, 'Контактное лицо'),
          f(_tax, 'ИНН', v: (v) {
            final t = (v ?? '').trim();
            if (t.isNotEmpty && !RegExp(r'^\d{9,14}$').hasMatch(t)) return 'ИНН — от 9 до 14 цифр';
            return null;
          }),
          f(_address, 'Адрес'),
          f(_note, 'Примечание', lines: 3),
          FilledButton(onPressed: _busy ? null : _save, child: const Text('Сохранить')),
        ]),
      ),
    );
  }
}

/// Supplier payment dialog. Returns true when a payment was recorded.
Future<bool> showSupplierPaymentDialog(BuildContext context, Supplier s, {PurchaseOrder? order, int? suggested}) async {
  final r = await showFormDialog<bool>(context,
      title: 'Оплата поставщику', width: 480, child: _PaymentForm(s, order: order, suggested: suggested));
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
    final amount = _amount!;
    final shift = ref.read(currentShiftProvider).value;
    if (_method == 'cash' && shift == null) {
      showError(context, 'Оплата наличными из кассы требует открытой смены. Откройте смену или выберите другой способ.');
      return;
    }
    final live = ref.read(purSupplierProvider(widget.s.id)).value ?? widget.s;
    var overpay = false;
    if (amount > live.balance) {
      overpay = await confirm(context,
          title: 'Сумма больше долга',
          message: 'Долг поставщику: ${Money.format(live.balance)}.\n'
              'После оплаты ${Money.format(amount)} образуется аванс ${Money.format(amount - (live.balance > 0 ? live.balance : 0))}. Продолжить?',
          ok: 'Оплатить с авансом');
      if (!overpay || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(purchasingRepoProvider).paySupplier(
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
      showSuccess(context, 'Оплата ${Money.format(amount)} проведена');
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
    final shift = ref.watch(currentShiftProvider).value;
    final canCash = ref.watch(sessionProvider)?.can(Perm.cashInOut) ?? false;
    return Form(
      key: _key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(live.name, style: t.textTheme.titleMedium),
          if (widget.order != null) Text('Заказ №${widget.order!.number}'),
          Text(
            live.balance >= 0 ? 'Наш долг: ${Money.format(live.balance)}' : 'Аванс у поставщика: ${Money.format(-live.balance)}',
            style: TextStyle(color: live.balance > 0 ? AppColors.danger : AppColors.success, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Gap.l),
          MoneyField(
            label: 'Сумма *',
            initial: _amount,
            required: true,
            allowZero: false,
            autofocus: true,
            onChanged: (v) => _amount = v,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Gap.m),
          Text('Способ оплаты', style: t.textTheme.labelLarge),
          const SizedBox(height: Gap.s),
          Wrap(spacing: Gap.s, runSpacing: Gap.xs, children: [
            for (final e in paymentMethodLabels.entries)
              Tooltip(
                message: e.key == 'cash' && !canCash ? 'Нет права на выдачу наличных из кассы' : '',
                child: ChoiceChip(
                  label: Text(e.value),
                  selected: _method == e.key,
                  onSelected: e.key != 'cash' || canCash ? (_) => setState(() => _method = e.key) : null,
                ),
              ),
          ]),
          if (_method == 'cash')
            Padding(
              padding: const EdgeInsets.only(top: Gap.s),
              child: Text(
                shift == null
                    ? 'Смена закрыта — наличные из кассы выдать нельзя'
                    : 'Будет учтено как выплата из кассы смены №${shift.number}',
                style: t.textTheme.bodySmall?.copyWith(color: shift == null ? AppColors.danger : null),
              ),
            ),
          const SizedBox(height: Gap.m),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Комментарий (№ платёжки…)'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Gap.l),
          FilledButton.icon(
              onPressed: _busy ? null : _submit, icon: const Icon(Icons.payments_outlined), label: const Text('Оплатить')),
        ]),
      ),
    );
  }
}
