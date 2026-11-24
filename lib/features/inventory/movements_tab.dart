import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/pickers.dart';
import '../../core/widgets/widgets.dart';
import 'inventory_logic.dart';
import 'receipt_document.dart';
import 'stock_dialogs.dart';
import 'stock_tab.dart' show InvChipBar;

/// Filter for the stock movement journal.
class MovementQuery {
  const MovementQuery({this.type, this.productId, this.from, this.to});
  final String? type;
  final String? productId;
  final DateTime? from;
  final DateTime? to; // exclusive

  @override
  bool operator ==(Object other) =>
      other is MovementQuery &&
      other.type == type &&
      other.productId == productId &&
      other.from == from &&
      other.to == to;
  @override
  int get hashCode => Object.hash(type, productId, from, to);
}

const movementsLimit = 500;

final movementsProvider = StreamProvider.family<List<StockMovement>, MovementQuery>((ref, q) {
  final db = ref.watch(databaseProvider);
  final sel = db.select(db.stockMovements)..where((m) => m.deletedAt.isNull());
  if (q.type != null) sel.where((m) => m.type.equals(q.type!));
  if (q.productId != null) sel.where((m) => m.productId.equals(q.productId!));
  if (q.from != null) sel.where((m) => m.createdAt.isBiggerOrEqualValue(q.from!));
  if (q.to != null) sel.where((m) => m.createdAt.isSmallerThanValue(q.to!));
  sel
    ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
    ..limit(movementsLimit);
  return sel.watch();
});

enum _Period {
  today('Сегодня'),
  week('7 дней'),
  month('30 дней'),
  all('Всё время'),
  custom('Период…');

  const _Period(this.label);
  final String label;
}

/// «Движения»: stock movement journal.
class MovementsTab extends ConsumerStatefulWidget {
  const MovementsTab({super.key});
  @override
  ConsumerState<MovementsTab> createState() => _MovementsTabState();
}

class _MovementsTabState extends ConsumerState<MovementsTab> {
  String? _type;
  Product? _product;
  _Period _period = _Period.week;
  DateTimeRange? _range;

  MovementQuery get _query {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final (from, to) = switch (_period) {
      _Period.today => (today, null),
      _Period.week => (today.subtract(const Duration(days: 6)), null),
      _Period.month => (today.subtract(const Duration(days: 29)), null),
      _Period.all => (null, null),
      _Period.custom => (_range?.start, _range?.end.add(const Duration(days: 1))),
    };
    return MovementQuery(type: _type, productId: _product?.id, from: from, to: to);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _range,
      helpText: 'Период движений',
    );
    if (r != null) {
      setState(() {
        _range = r;
        _period = _Period.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final products = ref.watch(invProductMapProvider).value ?? const {};
    final users = ref.watch(invUserNamesProvider).value ?? const {};
    final receiptNumbers = ref.watch(goodsReceiptNumbersProvider).value ?? const <String, int>{};
    final q = _query;
    final typeField = DropdownButtonFormField<String?>(
      initialValue: _type,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Тип'),
      items: [
        const DropdownMenuItem(value: null, child: Text('Все типы')),
        for (final e in movementTypeLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: (v) => setState(() => _type = v),
    );
    final productChip = InputChip(
      avatar: const Icon(Icons.inventory_2_outlined, size: 18),
      label: Text(_product?.name ?? 'Все товары', overflow: TextOverflow.ellipsis),
      onPressed: () async {
        final p = await pickProduct(context, title: 'Фильтр по товару');
        if (p != null) setState(() => _product = p);
      },
      onDeleted: _product == null ? null : () => setState(() => _product = null),
      deleteButtonTooltipMessage: 'Сбросить',
    );
    final periods = [
      for (final p in _Period.values)
        ChoiceChip(
          label: Text(
            p == _Period.custom && _range != null && _period == _Period.custom
                ? '${formatDate(_range!.start)} – ${formatDate(_range!.end)}'
                : p.label,
          ),
          selected: _period == p,
          onSelected: (_) => p == _Period.custom ? _pickRange() : setState(() => _period = p),
        ),
    ];
    // Phones: type + product on one line, periods as one scrolling chip row.
    final filters = context.isCompact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: typeField),
                  const SizedBox(width: Gap.s),
                  Flexible(child: productChip),
                ],
              ),
              const SizedBox(height: Gap.s),
              InvChipBar(children: periods),
            ],
          )
        : Wrap(
            spacing: Gap.s,
            runSpacing: Gap.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(width: 220, child: typeField),
              productChip,
              ...periods,
            ],
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top inset keeps the floating «Тип» label inside the tab's clip.
        Padding(
          padding: const EdgeInsets.only(top: Gap.s),
          child: filters,
        ),
        const SizedBox(height: Gap.m),
        Expanded(
          child: AsyncView(
            value: ref.watch(movementsProvider(q)),
            onRetry: () => ref.invalidate(movementsProvider(q)),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.swap_vert,
                  title: 'Движений нет',
                  message: 'Измените фильтры или период',
                );
              }
              var inQty = 0.0, outQty = 0.0;
              for (final m in list) {
                if (m.qty > 0) {
                  inQty += m.qty;
                } else {
                  outQty += m.qty;
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    [
                      'Записей: ${list.length}${list.length >= movementsLimit ? ' (показаны последние $movementsLimit — уточните фильтр)' : ''}',
                      if (_product != null) 'приход +${Qty.format(inQty)} · расход ${Qty.format(outQty)}',
                    ].join(' · '),
                    style: t.textTheme.bodySmall,
                  ),
                  const SizedBox(height: Gap.s),
                  Expanded(
                    child: Card(
                      child: ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, i) {
                          final m = list[i];
                          final p = products[m.productId];
                          final reference = movementReference(m, receiptNumbers);
                          return MovementTile(
                            m: m,
                            unit: p?.unit ?? 'pcs',
                            productName: p?.name ?? 'Удалённый товар',
                            userName: users[m.userId],
                            reference: reference,
                            onTap: reference == null ? null : () => showReceiptDocument(context, m.refId!),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_product != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.s),
            child: Text(
              'Текущий остаток «${_product!.name}»: '
              '${Qty.format(products[_product!.id]?.stockQty ?? _product!.stockQty, _product!.unit)}',
              style: t.textTheme.titleSmall?.copyWith(color: AppColors.info),
            ),
          ),
      ],
    );
  }
}
