// New warranty claim: by receipt number (pick the sold item) or manually
// (product + customer), serial number and problem description.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/pickers.dart';
import '../../core/widgets/widgets.dart';
import 'warranty_logic.dart';
import 'warranty_repository.dart';

Future<WarrantyClaim?> showNewClaim(BuildContext context, {String? receipt}) {
  if (context.isCompact) {
    return Navigator.of(context).push<WarrantyClaim>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Новая гарантийная заявка')),
          body: NewClaimForm(initialReceipt: receipt),
        ),
      ),
    );
  }
  return showFormDialog<WarrantyClaim>(
    context,
    title: 'Новая гарантийная заявка',
    width: 680,
    child: NewClaimForm(initialReceipt: receipt),
  );
}

class NewClaimForm extends ConsumerStatefulWidget {
  const NewClaimForm({super.key, this.initialReceipt});
  final String? initialReceipt;

  @override
  ConsumerState<NewClaimForm> createState() => _NewClaimFormState();
}

class _NewClaimFormState extends ConsumerState<NewClaimForm> {
  int _mode = 0; // 0 = by receipt, 1 = manual
  late final _receipt = TextEditingController(text: widget.initialReceipt ?? '');
  final _serial = TextEditingController();
  final _problem = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  SaleLookup? _sale;
  String? _lookupError;
  bool _looking = false;
  SaleItem? _item;
  Product? _product;
  Customer? _customer;
  bool _busy = false;
  bool _triedSubmit = false;

  @override
  void initState() {
    super.initState();
    if ((widget.initialReceipt ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookup());
    }
  }

  @override
  void dispose() {
    _receipt.dispose();
    _serial.dispose();
    _problem.dispose();
    super.dispose();
  }

  int _lookupSeq = 0;

  Future<void> _lookup() async {
    final n = int.tryParse(_receipt.text.trim().replaceAll('№', ''));
    if (n == null) {
      setState(() => _lookupError = 'Введите номер чека цифрами');
      return;
    }
    final seq = ++_lookupSeq; // only the latest lookup may update the form
    setState(() {
      _looking = true;
      _lookupError = null;
    });
    try {
      final r = await ref.read(warrantyRepositoryProvider).findSale(n);
      if (!mounted || seq != _lookupSeq) return;
      final selectable = r == null ? const <SaleItem>[] : r.items.where((i) => _itemBlock(r, i) == null).toList();
      setState(() {
        _looking = false;
        _sale = r;
        _lookupError = r == null ? 'Чек №$n не найден' : null;
        _item = selectable.length == 1 ? selectable.first : null;
        _customer = r?.customer ?? _customer;
      });
    } catch (e) {
      if (mounted && seq == _lookupSeq) {
        setState(() => _looking = false);
        showError(context, e);
      }
    }
  }

  /// Why an item of the found receipt cannot be taken on warranty.
  String? _itemBlock(SaleLookup s, SaleItem it) {
    if (s.sale.status == 'voided') return 'чек аннулирован';
    if (it.returnedQty >= it.qty - 1e-9) return 'товар возвращён';
    return null;
  }

  DateTime? get _until => _mode == 0 ? _item?.warrantyUntil : null;

  /// Expired / missing warranty and duplicate open claim need a confirmation.
  Future<bool> _confirmWarnings() async {
    if (_mode != 0) return true;
    final state = warrantyState(_until, DateTime.now());
    if (state != WarrantyState.active) {
      final ok = await confirm(
        context,
        title: state == WarrantyState.expired ? 'Гарантия истекла' : 'Гарантия не установлена',
        message: 'Заявку можно принять как платный ремонт или на экспертизу. Принять?',
        ok: 'Принять',
      );
      if (!ok || !mounted) return false;
    }
    final dup = await ref.read(warrantyRepositoryProvider).openClaimFor(_item!.id);
    if (dup != null && mounted) {
      return confirm(
        context,
        title: 'Уже есть открытая заявка',
        message:
            'По этому товару из чека уже принята заявка №${dup.number} '
            '(${warrantyStatusLabel(dup.status).toLowerCase()}). Создать ещё одну?',
        ok: 'Создать',
      );
    }
    return mounted;
  }

  Future<void> _submit() async {
    if (_busy) return; // Ctrl+Enter / double click while a dialog or save is pending
    setState(() => _triedSubmit = true);
    if (!_formKey.currentState!.validate()) return;
    if (_mode == 0 && _item == null) return showError(context, 'Найдите чек и выберите товар из него');
    if (_mode == 1 && _product == null) return showError(context, 'Выберите товар');
    setState(() => _busy = true);
    try {
      if (!await _confirmWarnings() || !mounted) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final claim = await ref
          .read(warrantyRepositoryProvider)
          .createClaim(
            saleItemId: _mode == 0 ? _item!.id : null,
            productId: _mode == 0 ? _item!.productId : _product!.id,
            customerId: _customer?.id,
            serialNumber: _serial.text,
            problem: _problem.text,
            userId: ref.read(sessionProvider)!.user.id,
          );
      if (mounted) Navigator.of(context).pop(claim);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final muted = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop(),
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (!_busy) _submit();
        },
      },
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.l),
                children: [
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, icon: Icon(Icons.receipt_long_outlined), label: Text('По чеку')),
                      ButtonSegment(value: 1, icon: Icon(Icons.edit_note), label: Text('Без чека')),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() => _mode = s.first),
                  ),
                  const SizedBox(height: Gap.l),
                  if (_mode == 0) ..._receiptSection(t, muted) else ..._manualSection(),
                  const SizedBox(height: Gap.m),
                  _customerTile(muted),
                  const SizedBox(height: Gap.m),
                  TextFormField(
                    controller: _serial,
                    decoration: const InputDecoration(
                      labelText: 'Серийный номер / IMEI',
                      prefixIcon: Icon(Icons.qr_code_2),
                    ),
                  ),
                  const SizedBox(height: Gap.m),
                  TextFormField(
                    key: const Key('claim-problem'),
                    controller: _problem,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Описание неисправности *',
                      hintText: 'Что не работает, когда проявилось, внешний вид, комплектность',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v ?? '').trim().length < 3 ? 'Опишите неисправность' : null,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.l),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: Gap.s,
                overflowSpacing: Gap.s,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Отмена')),
                  FilledButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: const Text('Принять заявку'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _receiptSection(ThemeData t, TextStyle? muted) {
    final s = _sale;
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              key: const Key('claim-receipt'),
              controller: _receipt,
              autofocus: _receipt.text.isEmpty,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Номер чека',
                prefixIcon: const Icon(Icons.receipt_long_outlined),
                errorText: _lookupError,
              ),
              onSubmitted: (_) => _lookup(),
            ),
          ),
          const SizedBox(width: Gap.s),
          FilledButton.tonal(
            onPressed: _looking ? null : _lookup,
            child: _looking
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Найти'),
          ),
        ],
      ),
      if (s != null) ...[
        const SizedBox(height: Gap.m),
        Text(
          'Чек №${s.sale.number} от ${formatDateTime(s.sale.createdAt)} — выберите товар',
          style: t.textTheme.titleSmall,
        ),
        const SizedBox(height: Gap.xs),
        if (s.sale.status == 'voided')
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.xs),
            child: Text(
              'Чек аннулирован — принять товар по нему нельзя. Используйте режим «Без чека».',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        for (final it in s.items) _itemTile(s, it, muted),
        if (_item != null) ...[const SizedBox(height: Gap.s), _warrantyBanner(_item!.warrantyUntil)],
      ],
    ];
  }

  Widget _itemTile(SaleLookup s, SaleItem it, TextStyle? muted) {
    final sel = _item?.id == it.id;
    final block = _itemBlock(s, it);
    final st = warrantyState(it.warrantyUntil, DateTime.now());
    final (label, color) = switch (st) {
      WarrantyState.none => ('без гарантии', Colors.grey),
      WarrantyState.active => ('гарантия до ${formatDate(it.warrantyUntil!)}', AppColors.success),
      WarrantyState.expired => ('гарантия истекла ${formatDate(it.warrantyUntil!)}', AppColors.danger),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: Gap.xs),
      color: sel ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5) : null,
      child: ListTile(
        enabled: block == null,
        onTap: () => setState(() => _item = it),
        leading: Icon(
          sel ? Icons.check_circle : Icons.circle_outlined,
          color: sel ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(it.productName),
        // chip in the subtitle (not trailing) so long dates fit on 360px phones
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${Qty.format(it.qty)} × ${Money.format(it.unitPrice)}', style: muted),
            const SizedBox(height: Gap.xs),
            Wrap(
              spacing: Gap.xs,
              runSpacing: Gap.xs,
              children: [
                StatusChip(label, color: color),
                if (block != null) StatusChip(block, color: AppColors.danger),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _warrantyBanner(DateTime? until) {
    final st = warrantyState(until, DateTime.now());
    final (color, icon, text) = switch (st) {
      WarrantyState.active => (AppColors.success, Icons.verified_user, 'На гарантии до ${formatDate(until!)}'),
      WarrantyState.expired => (
        AppColors.danger,
        Icons.gpp_bad_outlined,
        'Гарантия истекла ${formatDate(until!)}. Заявку можно принять как платный ремонт.',
      ),
      WarrantyState.none => (AppColors.warning, Icons.info_outline, 'На этот товар гарантия не установлена'),
    };
    return Container(
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

  List<Widget> _manualSection() {
    final missing = _triedSubmit && _product == null;
    final err = Theme.of(context).colorScheme.error;
    return [
      Card(
        shape: missing
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: err),
              )
            : null,
        child: ListTile(
          leading: Icon(Icons.inventory_2_outlined, color: missing ? err : null),
          title: Text(_product?.name ?? 'Выберите товар *', style: missing ? TextStyle(color: err) : null),
          subtitle: _product == null
              ? Text(
                  missing ? 'Обязательно для заявки без чека' : 'Для товара без чека или проданного вне системы',
                  style: missing ? TextStyle(color: err) : null,
                )
              : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final p = await pickProduct(context);
            if (p != null) setState(() => _product = p);
          },
        ),
      ),
    ];
  }

  Widget _customerTile(TextStyle? muted) => Card(
    child: ListTile(
      leading: const Icon(Icons.person_outline),
      title: Text(_customer?.name ?? 'Клиент (необязательно)'),
      subtitle: Text(_customer?.phone ?? 'Нужен для связи о готовности', style: muted),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_customer != null)
            IconButton(
              tooltip: 'Убрать клиента',
              onPressed: () => setState(() => _customer = null),
              icon: const Icon(Icons.close),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () async {
        final c = await pickCustomer(context);
        if (c != null) setState(() => _customer = c);
      },
    ),
  );
}
