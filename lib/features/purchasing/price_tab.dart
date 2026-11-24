import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'purchasing_logic.dart';
import '../../l10n/l10n.dart';

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
    final l = context.l10n;
    final products = ref.watch(purProductMapProvider).value ?? const {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Gap.m,
          runSpacing: Gap.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: SearchField(hint: l.commonProduct, onChanged: (v) => setState(() => _q = v)),
            ),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 30, label: Text(l.purDaysShort('30'))),
                ButtonSegment(value: 90, label: Text(l.purDaysShort('90'))),
                ButtonSegment(value: 180, label: Text(l.purDaysShort('180'))),
                ButtonSegment(value: 365, label: Text(l.commonYear)),
              ],
              selected: {_days},
              onSelectionChanged: (v) => setState(() => _days = v.first),
            ),
            FilterChip(
              label: Text(l.purPriceRiseFilter),
              selected: _spikesOnly,
              onSelected: (v) => setState(() => _spikesOnly = v),
            ),
          ],
        ),
        const SizedBox(height: Gap.m),
        Expanded(
          child: AsyncView(
            value: ref.watch(purReceiptMovementsProvider(_days)),
            data: (moves) {
              final hist = buildPriceHistory(moves);
              final q = _q.toLowerCase();
              final entries =
                  hist.entries.where((e) {
                    final last = e.value.last;
                    if (_spikesOnly && !last.isSpike) return false;
                    final name = products[e.key]?.name ?? '';
                    return q.isEmpty || name.toLowerCase().contains(q);
                  }).toList()..sort((a, b) {
                    // Spikes first, then by largest last change.
                    final ca = a.value.last.changePercent ?? -1e9;
                    final cb = b.value.last.changePercent ?? -1e9;
                    return cb.compareTo(ca);
                  });
              final spikes = hist.values.where((v) => v.last.isSpike).length;
              if (hist.isEmpty) {
                return EmptyState(
                  icon: Icons.price_change_outlined,
                  title: l.purPricesEmpty,
                  message: l.purPricesEmptyMessage,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.purPricesSummary('${hist.length}', '$spikes'),
                    style: t.textTheme.bodySmall?.copyWith(color: spikes > 0 ? AppColors.danger : null),
                  ),
                  const SizedBox(height: Gap.s),
                  Expanded(
                    child: entries.isEmpty
                        ? EmptyState(icon: Icons.search_off, title: l.purNoProductsForFilter)
                        : ListView.separated(
                            itemCount: entries.length,
                            separatorBuilder: (_, _) => const Divider(),
                            itemBuilder: (_, i) =>
                                _ProductHistory(product: products[entries[i].key], points: entries[i].value),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductHistory extends StatelessWidget {
  const _ProductHistory({required this.product, required this.points});
  final Product? product;
  final List<PricePoint> points;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final last = points.last;
    final ch = last.changePercent;
    final color = ch == null || ch == 0
        ? null
        : (ch > 0 ? (last.isSpike ? AppColors.danger : AppColors.warning) : AppColors.success);
    return ExpansionTile(
      title: Row(
        children: [
          Flexible(child: Text(product?.name ?? l.purDeletedProduct, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (last.isSpike) ...[const SizedBox(width: Gap.s), StatusChip(l.purPriceRiseChip, color: AppColors.danger)],
        ],
      ),
      subtitle: Text(
        l.purLastReceipt(formatDate(last.at), '${points.length}') +
            (product != null ? l.purRetailSuffix(Money.format(product!.price)) : ''),
        style: t.textTheme.bodySmall,
      ),
      // Custom trailing keeps an expand chevron so the row reads as expandable.
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Money.format(last.unitCost), style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (ch != null)
                Text(
                  ch == 0 ? l.purNoChange : _pct(ch),
                  style: t.textTheme.bodySmall?.copyWith(
                    color: color ?? t.colorScheme.onSurfaceVariant,
                    fontWeight: ch == 0 ? null : FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(width: Gap.s),
          Icon(Icons.expand_more, color: t.colorScheme.onSurfaceVariant),
        ],
      ),
      children: [
        for (final p in points.reversed)
          ListTile(
            dense: true,
            title: Text(Money.format(p.unitCost)),
            subtitle: Text('${formatDateTime(p.at)} · ${Qty.format(p.qty, product?.unit)}'),
            trailing: p.changePercent == null
                ? null
                : Text(
                    _pct(p.changePercent!),
                    style: TextStyle(
                      color: p.isSpike
                          ? AppColors.danger
                          : p.changePercent! < 0
                          ? AppColors.success
                          : null,
                      fontWeight: p.isSpike ? FontWeight.w700 : null,
                    ),
                  ),
          ),
      ],
    );
  }
}
