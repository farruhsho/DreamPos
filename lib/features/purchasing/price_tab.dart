import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'purchasing_logic.dart';

final _receiptsProvider = StreamProvider.family<List<StockMovement>, int>((ref, days) {
  final db = ref.watch(databaseProvider);
  final since = DateTime.now().subtract(Duration(days: days));
  return (db.select(db.stockMovements)
        ..where((m) => m.type.equals('receipt') & m.createdAt.isBiggerOrEqualValue(since)))
      .watch();
});

String _pct(double v) => '${v > 0 ? '+' : ''}${v.toStringAsFixed(1).replaceAll('.', ',')}%';

/// «Контроль закупочных цен»: purchase cost history per product.
class PriceControlTab extends ConsumerStatefulWidget {
  const PriceControlTab({super.key});
  @override
  ConsumerState<PriceControlTab> createState() => _PriceControlTabState();
}

class _PriceControlTabState extends ConsumerState<PriceControlTab> {
  String _q = '';
  bool _spikesOnly = false;
  int _days = 180;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final products = ref.watch(purProductMapProvider).value ?? const {};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: Gap.m, runSpacing: Gap.s, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(width: 320, child: SearchField(hint: 'Товар', onChanged: (v) => setState(() => _q = v))),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 30, label: Text('30 дн.')),
            ButtonSegment(value: 90, label: Text('90 дн.')),
            ButtonSegment(value: 180, label: Text('180 дн.')),
            ButtonSegment(value: 365, label: Text('Год')),
          ],
          selected: {_days},
          onSelectionChanged: (v) => setState(() => _days = v.first),
        ),
        FilterChip(
          label: const Text('Рост цены > 10%'),
          selected: _spikesOnly,
          onSelected: (v) => setState(() => _spikesOnly = v),
        ),
      ]),
      const SizedBox(height: Gap.m),
      Expanded(
        child: AsyncView(
          value: ref.watch(_receiptsProvider(_days)),
          data: (moves) {
            final hist = buildPriceHistory(moves);
            final q = _q.toLowerCase();
            final entries = hist.entries.where((e) {
              final last = e.value.last;
              if (_spikesOnly && !last.isSpike) return false;
              final name = products[e.key]?.name ?? '';
              return q.isEmpty || name.toLowerCase().contains(q);
            }).toList()
              ..sort((a, b) {
                // Spikes first, then by largest last change.
                final ca = a.value.last.changePercent ?? -1e9;
                final cb = b.value.last.changePercent ?? -1e9;
                return cb.compareTo(ca);
              });
            final spikes = hist.values.where((v) => v.last.isSpike).length;
            if (hist.isEmpty) {
              return const EmptyState(
                  icon: Icons.price_change_outlined,
                  title: 'Приходов за период нет',
                  message: 'История закупочных цен строится по приходам товара');
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Товаров с приходами: ${hist.length} · подорожали более чем на 10%: $spikes',
                  style: t.textTheme.bodySmall?.copyWith(color: spikes > 0 ? AppColors.danger : null)),
              const SizedBox(height: Gap.s),
              Expanded(
                child: entries.isEmpty
                    ? const EmptyState(icon: Icons.search_off, title: 'Нет товаров по фильтру')
                    : ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (_, i) => _ProductHistory(
                            product: products[entries[i].key], points: entries[i].value),
                      ),
              ),
            ]);
          },
        ),
      ),
    ]);
  }
}

class _ProductHistory extends StatelessWidget {
  const _ProductHistory({required this.product, required this.points});
  final Product? product;
  final List<PricePoint> points;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final last = points.last;
    final ch = last.changePercent;
    final color = ch == null || ch == 0 ? null : (ch > 0 ? (last.isSpike ? AppColors.danger : AppColors.warning) : AppColors.success);
    return ExpansionTile(
      title: Row(children: [
        Flexible(child: Text(product?.name ?? 'Удалённый товар', maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (last.isSpike) ...[const SizedBox(width: Gap.s), const StatusChip('Рост > 10%', color: AppColors.danger)],
      ]),
      subtitle: Text(
          'последний приход ${formatDate(last.at)} · приходов ${points.length}'
          '${product != null ? ' · розница ${Money.format(product!.price)}' : ''}',
          style: t.textTheme.bodySmall),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(Money.format(last.unitCost), style: const TextStyle(fontWeight: FontWeight.w700)),
        if (ch != null) Text(_pct(ch), style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ]),
      children: [
        for (final p in points.reversed)
          ListTile(
            dense: true,
            title: Text(Money.format(p.unitCost)),
            subtitle: Text('${formatDateTime(p.at)} · ${Qty.format(p.qty, product?.unit)}'),
            trailing: p.changePercent == null
                ? null
                : Text(_pct(p.changePercent!),
                    style: TextStyle(
                        color: p.isSpike
                            ? AppColors.danger
                            : p.changePercent! < 0
                                ? AppColors.success
                                : null,
                        fontWeight: p.isSpike ? FontWeight.w700 : null)),
          ),
      ],
    );
  }
}
