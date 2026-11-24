import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../money.dart';
import '../providers.dart';
import '../theme.dart';
import 'widgets.dart';

/// Search products by name / SKU / barcode (prefix + contains), active only.
Future<List<Product>> searchProducts(AppDatabase db, String query, {int limit = 50}) {
  final q = query.trim();
  final sel = db.select(db.products)
    ..where((p) => p.deletedAt.isNull() & p.isActive.equals(true));
  if (q.isNotEmpty) {
    final like = '%${q.replaceAll('%', '').replaceAll('_', '')}%';
    sel.where((p) =>
        p.name.like(like) | p.sku.equals(q) | p.barcode.equals(q) | p.sku.like(like));
  }
  sel
    ..orderBy([(p) => OrderingTerm.asc(p.name)])
    ..limit(limit);
  return sel.get();
}

/// Exact barcode/SKU lookup (scanner input).
Future<Product?> findByCode(AppDatabase db, String code) async {
  final c = code.trim();
  if (c.isEmpty) return null;
  final list = await (db.select(db.products)
        ..where((p) => p.deletedAt.isNull() & (p.barcode.equals(c) | p.sku.equals(c)))
        ..limit(1))
      .get();
  return list.isEmpty ? null : list.first;
}

/// Modal product picker. Returns the chosen product or null.
Future<Product?> pickProduct(BuildContext context, {String title = 'Выбор товара'}) {
  return showFormDialog<Product>(context, title: title, width: 640, child: const _ProductPicker());
}

class _ProductPicker extends ConsumerStatefulWidget {
  const _ProductPicker();
  @override
  ConsumerState<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends ConsumerState<_ProductPicker> {
  String _q = '';
  Future<List<Product>>? _f;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _f = searchProducts(ref.read(databaseProvider), _q);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.l),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SearchField(
          autofocus: true,
          hint: 'Название, артикул или штрихкод',
          onChanged: (v) => setState(() {
            _q = v;
            _load();
          }),
          onSubmitted: (v) async {
            final p = await findByCode(ref.read(databaseProvider), v);
            if (p != null && context.mounted) Navigator.pop(context, p);
          },
        ),
        const SizedBox(height: Gap.s),
        SizedBox(
          height: 420,
          child: FutureBuilder<List<Product>>(
            future: _f,
            builder: (context, s) {
              if (s.hasError) return ErrorView(error: s.error!);
              if (!s.hasData) return const LoadingView();
              final list = s.data!;
              if (list.isEmpty) {
                return const EmptyState(icon: Icons.search_off, title: 'Ничего не найдено');
              }
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, i) {
                  final p = list[i];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text([
                      if (p.barcode != null) p.barcode!,
                      if (p.sku != null) 'арт. ${p.sku}',
                      'остаток ${Qty.format(p.stockQty, p.unit)}',
                    ].join(' · ')),
                    trailing: Text(Money.format(p.price),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// Search customers by name / phone / card.
Future<List<Customer>> searchCustomers(AppDatabase db, String query, {int limit = 50}) {
  final q = query.trim();
  final sel = db.select(db.customers)..where((c) => c.deletedAt.isNull());
  if (q.isNotEmpty) {
    final like = '%${q.replaceAll('%', '')}%';
    final digits = q.replaceAll(RegExp(r'\D'), '');
    sel.where((c) =>
        c.name.like(like) |
        c.cardNumber.equals(q) |
        c.phone.like(like) |
        (digits.length >= 3 ? c.phone.like('%$digits%') : const Constant(false)));
  }
  sel
    ..orderBy([(c) => OrderingTerm.desc(c.lastVisitAt), (c) => OrderingTerm.asc(c.name)])
    ..limit(limit);
  return sel.get();
}

/// Modal customer picker with quick "new customer" creation.
Future<Customer?> pickCustomer(BuildContext context) =>
    showFormDialog<Customer>(context, title: 'Клиент', width: 600, child: const _CustomerPicker());

class _CustomerPicker extends ConsumerStatefulWidget {
  const _CustomerPicker();
  @override
  ConsumerState<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends ConsumerState<_CustomerPicker> {
  String _q = '';
  late Future<List<Customer>> _f = searchCustomers(ref.read(databaseProvider), '');

  Future<void> _create() async {
    final db = ref.read(databaseProvider);
    final name = TextEditingController(text: RegExp(r'\d').hasMatch(_q) ? '' : _q);
    final phone = TextEditingController(text: RegExp(r'\d').hasMatch(_q) ? _q : '');
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Новый клиент'),
        content: Form(
          key: key,
          child: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Имя *'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Введите имя' : null),
              const SizedBox(height: Gap.m),
              TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Телефон')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
          FilledButton(
              onPressed: () {
                if (key.currentState!.validate()) Navigator.pop(c, true);
              },
              child: const Text('Создать')),
        ],
      ),
    );
    if (ok != true) return;
    final id = newId();
    await db.into(db.customers).insert(CustomersCompanion.insert(
        id: id,
        name: name.text.trim(),
        phone: Value(phone.text.trim().isEmpty ? null : phone.text.trim())));
    await db.markDirty('customers', id);
    final c = await (db.select(db.customers)..where((t) => t.id.equals(id))).getSingle();
    if (mounted) Navigator.pop(context, c);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.l),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: SearchField(
              autofocus: true,
              hint: 'Имя, телефон или номер карты',
              onChanged: (v) => setState(() {
                _q = v;
                _f = searchCustomers(ref.read(databaseProvider), v);
              }),
            ),
          ),
          const SizedBox(width: Gap.s),
          FilledButton.tonalIcon(
              onPressed: _create, icon: const Icon(Icons.person_add_alt), label: const Text('Новый')),
        ]),
        const SizedBox(height: Gap.s),
        SizedBox(
          height: 400,
          child: FutureBuilder<List<Customer>>(
            future: _f,
            builder: (context, s) {
              if (s.hasError) return ErrorView(error: s.error!);
              if (!s.hasData) return const LoadingView();
              if (s.data!.isEmpty) {
                return EmptyState(
                  icon: Icons.person_search,
                  title: 'Клиент не найден',
                  action: FilledButton(onPressed: _create, child: const Text('Создать клиента')),
                );
              }
              return ListView.separated(
                itemCount: s.data!.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, i) {
                  final c = s.data![i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(c.name.characters.first.toUpperCase())),
                    title: Text(c.name),
                    subtitle: Text([
                      if (c.phone != null) c.phone!,
                      if (c.cardNumber != null) 'карта ${c.cardNumber}',
                      if (c.discountPercent > 0) 'скидка ${c.discountPercent.toStringAsFixed(0)}%',
                    ].join(' · ')),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (c.debtBalance > 0)
                          Text('долг ${Money.format(c.debtBalance)}',
                              style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                        if (c.bonusBalance > 0)
                          Text('бонусы ${Money.format(c.bonusBalance)}',
                              style: const TextStyle(color: AppColors.success, fontSize: 12)),
                      ],
                    ),
                    onTap: () => Navigator.pop(context, c),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
