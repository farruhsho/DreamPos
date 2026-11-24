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
import '../../l10n/l10n.dart';

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
  today,
  week,
  month,
  all,
  custom;

  String labelIn(AppLocalizations l) => switch (this) {
    _Period.today => l.commonToday,
    _Period.week => l.invDays7,
    _Period.month => l.invDays30,
    _Period.all => l.invAllTime,
    _Period.custom => l.invPeriodCustom,
  };
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
      helpText: context.l10n.invMovementsPeriod,
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
    final l = context.l10n;
    final products = ref.watch(invProductMapProvider).value ?? const {};
    final users = ref.watch(invUserNamesProvider).value ?? const {};
    final receiptNumbers = ref.watch(goodsReceiptNumbersProvider).value ?? const <String, int>{};
    final q = _query;
    final typeField = DropdownButtonFormField<String?>(
      initialValue: _type,
      isExpanded: true,
      decoration: InputDecoration(labelText: l.invType),
      items: [
        DropdownMenuItem(value: null, child: Text(l.invAllTypes)),
        for (final e in movementTypeLabelsOf(l).entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: (v) => setState(() => _type = v),
    );
    final productChip = InputChip(
      avatar: const Icon(Icons.inventory_2_outlined, size: 18),
      label: Text(_product?.name ?? l.invAllProducts, overflow: TextOverflow.ellipsis),
      onPressed: () async {
        final p = await pickProduct(context, title: l.invFilterByProduct);
        if (p != null) setState(() => _product = p);
      },
      onDeleted: _product == null ? null : () => setState(() => _product = null),
      deleteButtonTooltipMessage: l.commonReset,
    );
    final periods = [
      for (final p in _Period.values)
        ChoiceChip(
          label: Text(
            p == _Period.custom && _range != null && _period == _Period.custom
                ? '${formatDate(_range!.start)} – ${formatDate(_range!.end)}'
                : p.labelIn(l),
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
                return EmptyState(
                  icon: Icons.swap_vert,
                  title: l.invNoMovements,
                  message: l.invChangeFiltersOrPeriod,
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
                      list.length >= movementsLimit
                          ? l.invRecordsLimited('${list.length}', '$movementsLimit')
                          : l.invRecords('${list.length}'),
                      if (_product != null) l.invInOut(Qty.format(inQty), Qty.format(outQty)),
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
                            productName: p?.name ?? l.invDeletedProduct,
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
              l.invCurrentStockOf(
                _product!.name,
                Qty.format(products[_product!.id]?.stockQty ?? _product!.stockQty, _product!.unit),
              ),
              style: t.textTheme.titleSmall?.copyWith(color: AppColors.info),
            ),
          ),
      ],
    );
  }
}
