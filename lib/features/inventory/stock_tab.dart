import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'inventory_logic.dart';
import 'stock_dialogs.dart';

/// Filter chips: a wrapping group on wide screens, a single horizontally
/// scrolling row on phones so filters don't eat the list's vertical space.
class InvChipBar extends StatelessWidget {
  const InvChipBar({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!context.isCompact) return Wrap(spacing: Gap.s, runSpacing: Gap.s, children: children);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: Gap.s), children[i]],
        ],
      ),
    );
  }
}

/// «Остатки»: stock overview with valuation, filters and quick actions.
class StockTab extends ConsumerStatefulWidget {
  const StockTab({super.key});
  @override
  ConsumerState<StockTab> createState() => _StockTabState();
}

class _StockTabState extends ConsumerState<StockTab> {
  String _q = '';
  StockFilter _filter = StockFilter.all;
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final canCost = session?.can(Perm.viewCost) ?? false;
    final cats = ref.watch(invCategoriesProvider).value ?? const <Category>[];
    final catNames = {for (final c in cats) c.id: c.name};
    return AsyncView(
      value: ref.watch(invProductsProvider),
      onRetry: () => ref.invalidate(invProductsProvider),
      data: (all) {
        final tracked = all.where((p) => p.trackStock).toList();
        final inCat = _categoryId == null ? tracked : tracked.where((p) => p.categoryId == _categoryId).toList();
        final val = StockValuation.of(inCat);
        final shown = inCat.where((p) => matchesStockFilter(p, _filter) && matchesQuery(p, _q)).toList();
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _summary(val, canCost)),
            SliverToBoxAdapter(child: _filters(cats, val)),
            if (tracked.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Товаров пока нет',
                  message: 'Добавьте товары в разделе «Товары», затем оформите приход.',
                ),
              )
            else if (shown.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.search_off,
                  title: 'Ничего не найдено',
                  message: 'Измените фильтры или запрос',
                ),
              )
            else ...[
              SliverToBoxAdapter(child: _header(canCost)),
              SliverList.separated(
                itemCount: shown.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, i) =>
                    _StockRow(p: shown[i], category: catNames[shown[i].categoryId], canCost: canCost),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: Gap.xl)),
          ],
        );
      },
    );
  }

  Widget _header(bool canCost) {
    final t = Theme.of(context);
    final st = t.textTheme.labelMedium?.copyWith(color: t.colorScheme.onSurfaceVariant);
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 820) return const SizedBox.shrink();
        Widget col(String s, double w) => SizedBox(
          width: w,
          child: Text(s, textAlign: TextAlign.right, style: st),
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(Gap.s, Gap.xs, Gap.s, Gap.xs),
          child: Row(
            children: [
              Expanded(child: Text('Товар', style: st)),
              if (canCost) col('Себестоимость', 130),
              col('Цена', 130),
              if (canCost) col('Сумма запаса', 150),
              col('Остаток', 120),
              const SizedBox(width: 48),
            ],
          ),
        );
      },
    );
  }

  Widget _summary(StockValuation v, bool canCost) {
    final cards = <Widget>[
      StatCard(label: 'Позиций на учёте', value: '${v.positions}', icon: Icons.inventory_2_outlined),
      if (canCost)
        StatCard(
          label: 'Запас по себестоимости',
          value: Money.format(v.costValue),
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.info,
        ),
      StatCard(
        label: 'Запас в розничных ценах',
        value: Money.format(v.retailValue),
        icon: Icons.sell_outlined,
        color: AppColors.success,
        hint: canCost ? 'Потенц. наценка ${Money.format(v.potentialMargin)}' : null,
      ),
      StatCard(
        label: 'Мало / нет / минус',
        value: '${v.lowCount} / ${v.outCount} / ${v.negativeCount}',
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        onTap: () => setState(
          () => _filter = v.negativeCount > 0
              ? StockFilter.negative
              : v.lowCount > 0
              ? StockFilter.low
              : StockFilter.out,
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        // Phones get a dense 2-column grid of compact tiles instead of four
        // full-width cards that push the list below the fold.
        if (c.maxWidth < 560) {
          return _CompactSummary(cards: cards.cast<StatCard>());
        }
        final cols = c.maxWidth >= 1100 ? cards.length : 2;
        final rows = <List<Widget>>[
          for (var i = 0; i < cards.length; i += cols) cards.sublist(i, (i + cols).clamp(0, cards.length)),
        ];
        // Equal-height cards per row (one card has an extra hint line).
        return Column(
          children: [
            for (final (i, row) in rows.indexed) ...[
              if (i > 0) const SizedBox(height: Gap.m),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (j, card) in row.indexed) ...[
                      if (j > 0) const SizedBox(width: Gap.m),
                      Expanded(child: card),
                    ],
                    for (var k = row.length; k < cols; k++) ...[
                      const SizedBox(width: Gap.m),
                      const Expanded(child: SizedBox()),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _filters(List<Category> cats, StockValuation v) {
    int count(StockFilter f) => switch (f) {
      StockFilter.all => v.positions,
      StockFilter.low => v.lowCount,
      StockFilter.out => v.outCount,
      StockFilter.negative => v.negativeCount,
    };
    final catField = DropdownButtonFormField<String?>(
      key: ValueKey('cat$_categoryId${cats.length}'),
      initialValue: cats.any((c) => c.id == _categoryId) ? _categoryId : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Категория'),
      items: [
        const DropdownMenuItem(value: null, child: Text('Все категории')),
        for (final c in cats)
          DropdownMenuItem(
            value: c.id,
            child: Text(c.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => setState(() => _categoryId = v),
    );
    final search = SearchField(hint: 'Название, артикул, штрихкод', onChanged: (v) => setState(() => _q = v));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth < 600) {
                return Column(
                  children: [
                    search,
                    const SizedBox(height: Gap.s),
                    catField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: Gap.m),
                  Expanded(flex: 2, child: catField),
                ],
              );
            },
          ),
          const SizedBox(height: Gap.s),
          InvChipBar(
            children: [
              for (final f in StockFilter.values)
                FilterChip(
                  label: Text('${f.label} (${count(f)})'),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockRow extends ConsumerWidget {
  const _StockRow({required this.p, required this.category, required this.canCost});
  final Product p;
  final String? category;
  final bool canCost;

  Color? _qtyColor() {
    if (isNegative(p) || isOut(p)) return AppColors.danger;
    if (isLow(p)) return AppColors.warning;
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final qtyColor = _qtyColor();
    final status = isNegative(p)
        ? const StatusChip('Минус', color: AppColors.danger)
        : isOut(p)
        ? const StatusChip('Нет', color: AppColors.danger)
        : isLow(p)
        ? const StatusChip('Мало', color: AppColors.warning)
        : null;
    final menu = PopupMenuButton<String>(
      tooltip: 'Действия',
      onSelected: (a) {
        switch (a) {
          case 'in':
            showQuickReceiptDialog(context, p);
          case 'off':
            showWriteOffDialog(context, p);
          case 'adj':
            showAdjustDialog(context, ref, p);
          case 'hist':
            showProductHistoryDialog(context, p);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'in',
          child: ListTile(leading: Icon(Icons.add_box_outlined), title: Text('Приход')),
        ),
        PopupMenuItem(
          value: 'off',
          child: ListTile(leading: Icon(Icons.delete_sweep_outlined), title: Text('Списание')),
        ),
        PopupMenuItem(
          value: 'adj',
          child: ListTile(leading: Icon(Icons.tune), title: Text('Корректировка')),
        ),
        PopupMenuItem(
          value: 'hist',
          child: ListTile(leading: Icon(Icons.history), title: Text('Движения')),
        ),
      ],
    );
    final sub = [
      ?category,
      if (p.sku != null) 'арт. ${p.sku}',
      if (p.barcode != null) p.barcode!,
      if (p.minStock > 0) 'мин. ${Qty.format(p.minStock)}',
      if (!p.isActive) 'не активен',
    ].join(' · ');
    final qty = Text(
      Qty.format(p.stockQty, p.unit),
      style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: qtyColor),
    );
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 820;
        return InkWell(
          onTap: () => showProductHistoryDialog(context, p),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: Gap.s),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.name,
                              maxLines: wide ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.textTheme.bodyLarge,
                            ),
                          ),
                          if (status != null) ...[const SizedBox(width: Gap.s), status],
                        ],
                      ),
                      if (sub.isNotEmpty)
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                if (wide) ...[
                  if (canCost)
                    SizedBox(
                      width: 130,
                      child: Text(
                        Money.format(p.costPrice),
                        textAlign: TextAlign.right,
                        style: TextStyle(color: t.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  SizedBox(width: 130, child: Text(Money.format(p.price), textAlign: TextAlign.right)),
                  if (canCost)
                    SizedBox(
                      width: 150,
                      child: Text(
                        Money.format(p.stockQty > 0 ? lineValue(p.stockQty, p.costPrice) : 0),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
                wide
                    ? SizedBox(
                        width: 120,
                        child: Align(alignment: Alignment.centerRight, child: qty),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(left: Gap.s),
                        child: qty,
                      ),
                menu,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Phone summary: 2×2 grid of compact tiles built from the same StatCards.
class _CompactSummary extends StatelessWidget {
  const _CompactSummary({required this.cards});
  final List<StatCard> cards;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget tile(StatCard s) => Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: s.onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (s.icon != null) ...[
                    Icon(s.icon, size: 18, color: s.color ?? t.colorScheme.primary),
                    const SizedBox(width: Gap.xs),
                  ],
                  Expanded(
                    child: Text(
                      s.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(s.value, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
    return Column(
      children: [
        for (var i = 0; i < cards.length; i += 2) ...[
          if (i > 0) const SizedBox(height: Gap.s),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(cards[i])),
                const SizedBox(width: Gap.s),
                Expanded(child: i + 1 < cards.length ? tile(cards[i + 1]) : const SizedBox()),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
