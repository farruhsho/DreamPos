import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'price_labels.dart';
import 'product_editor.dart';
import 'product_logic.dart';
import 'product_widgets.dart';
import 'products_repo.dart';

// ----------------------------------------------------------- shared actions

/// Archives / unarchives products (asks before archiving).
/// Returns true when the change was applied.
Future<bool> archiveProductsAction(BuildContext context, WidgetRef ref, Set<String> ids, bool active) async {
  if (!active) {
    final ok = await confirm(context,
        title: ids.length == 1 ? 'Архивировать товар?' : 'Архивировать товары (${ids.length})?',
        message: 'Архивные товары не продаются и не видны на кассе. История продаж сохраняется. '
            'Вернуть можно в любой момент (фильтр «Архив»).',
        ok: 'В архив');
    if (!ok || !context.mounted) return false;
  }
  return runGuarded(
    context,
    () => ref.read(productsRepoProvider).setActive(ids, active, userId: ref.read(sessionProvider)?.user.id),
    success: active ? 'Товары возвращены в продажу' : 'Перемещено в архив',
  );
}

/// Deletes a product without history; otherwise offers to archive it.
/// Returns true only when the product was actually deleted.
Future<bool> deleteProductAction(BuildContext context, WidgetRef ref, Product p) async {
  final repo = ref.read(productsRepoProvider);
  final userId = ref.read(sessionProvider)?.user.id;
  final history = await repo.hasHistory(p.id);
  if (!context.mounted) return false;
  if (history) {
    if (!p.isActive) {
      showError(context, 'По товару есть операции — удалить нельзя, он уже в архиве');
      return false;
    }
    final ok = await confirm(context,
        title: 'Удалить нельзя',
        message: 'По товару «${p.name}» есть продажи или движения по складу — для отчётов он '
            'должен остаться в базе. Переместить его в архив?',
        ok: 'В архив');
    if (!ok || !context.mounted) return false;
    await runGuarded(context, () => repo.setActive({p.id}, false, userId: userId),
        success: 'Товар перемещён в архив');
    return false;
  }
  final ok = await confirm(context,
      title: 'Удалить «${p.name}»?',
      message: 'Товар без операций будет удалён из каталога.',
      ok: 'Удалить',
      destructive: true);
  if (!ok || !context.mounted) return false;
  return runGuarded(context, () => repo.deleteProduct(p.id, userId: userId), success: 'Товар удалён');
}

// -------------------------------------------------------------------- views

/// Full-screen detail (phones).
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Товар')),
        body: ProductDetailView(productId: productId, onDeleted: () => Navigator.of(context).maybePop()),
      );
}

class ProductDetailView extends ConsumerWidget {
  const ProductDetailView({super.key, required this.productId, this.onDeleted, this.onClose});
  final String productId;
  final VoidCallback? onDeleted;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();
    final async = ref.watch(productByIdProvider(productId));
    return AsyncView<Product?>(
      value: async,
      onRetry: () => ref.invalidate(productByIdProvider(productId)),
      data: (p) {
        if (p == null || p.deletedAt != null) {
          return const EmptyState(icon: Icons.inventory_2_outlined, title: 'Товар не найден или удалён');
        }
        return _Detail(product: p, session: session, onDeleted: onDeleted, onClose: onClose);
      },
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.product, required this.session, this.onDeleted, this.onClose});
  final Product product;
  final Session session;
  final VoidCallback? onDeleted;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = product;
    final t = Theme.of(context);
    final canEdit = session.can(Perm.editProducts);
    final canCost = session.can(Perm.viewCost);
    final cats = ref.watch(productCategoriesProvider).value ?? const <Category>[];
    final cat = cats.where((c) => c.id == p.categoryId).firstOrNull;
    final suppliers = ref.watch(productSuppliersProvider).value ?? const <Supplier>[];
    final supplier = suppliers.where((s) => s.id == p.supplierId).firstOrNull;
    final stats = ref.watch(productStatsProvider(p.id));
    final moves = ref.watch(productMovementsProvider(p.id));
    final muted = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);

    final actions = <Widget>[
      if (canEdit)
        FilledButton.icon(
          onPressed: () => openProductEditor(context, product: p),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Изменить'),
        ),
      OutlinedButton.icon(
        onPressed: () => showPriceLabelsDialog(context, {p.id}),
        icon: const Icon(Icons.local_offer_outlined),
        label: const Text('Ценник'),
      ),
      if (canEdit)
        MenuAnchor(
          builder: (context, ctl, _) => IconButton(
            tooltip: 'Ещё',
            onPressed: () => ctl.isOpen ? ctl.close() : ctl.open(),
            icon: const Icon(Icons.more_vert),
          ),
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.copy_all_outlined),
              onPressed: () => openProductEditor(context, copyOf: p),
              child: const Text('Дублировать'),
            ),
            MenuItemButton(
              leadingIcon: Icon(p.isFavorite ? Icons.star_outline : Icons.star),
              onPressed: () => runGuarded(
                  context, () => ref.read(productsRepoProvider).setFavorite(p.id, !p.isFavorite),
                  success: p.isFavorite ? 'Убрано из избранного' : 'Добавлено в избранное'),
              child: Text(p.isFavorite ? 'Убрать из избранного' : 'В избранное'),
            ),
            MenuItemButton(
              leadingIcon: Icon(p.isActive ? Icons.archive_outlined : Icons.unarchive_outlined),
              onPressed: () => archiveProductsAction(context, ref, {p.id}, !p.isActive),
              child: Text(p.isActive ? 'В архив' : 'Вернуть из архива'),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () async {
                final done = await deleteProductAction(context, ref, p);
                if (done) onDeleted?.call();
              },
              child: const Text('Удалить', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
    ];

    String? fmtQty(double q) => Qty.format(q, p.unit);
    final margin = marginPercent(p.price, p.costPrice);

    return ListView(padding: const EdgeInsets.all(Gap.l), children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: Gap.xs),
            Wrap(spacing: Gap.s, runSpacing: Gap.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                CategoryDot(color: cat?.color),
                const SizedBox(width: Gap.xs),
                Text(cat?.name ?? 'Без категории', style: muted),
              ]),
              if (!p.isActive) StatusChip('Архив', color: t.colorScheme.outline),
              if (p.isFavorite) const StatusChip('Избранное', color: AppColors.warning),
              if (!p.trackStock) StatusChip('Без учёта остатка', color: t.colorScheme.outline),
            ]),
          ]),
        ),
        if (onClose != null)
          IconButton(onPressed: onClose, icon: const Icon(Icons.close), tooltip: 'Закрыть'),
      ]),
      const SizedBox(height: Gap.m),
      Wrap(spacing: Gap.s, runSpacing: Gap.s, crossAxisAlignment: WrapCrossAlignment.center, children: actions),
      const SizedBox(height: Gap.l),
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 560 ? 3 : 2;
        final w = (c.maxWidth - Gap.s * (cols - 1)) / cols;
        // Narrow cards: the icon tile would eat the label ("Продано за …").
        final showIcons = w >= 230;
        final s = stats.value;
        // Every card carries a hint line so cards in a row have equal height.
        String? daysAgo(DateTime? d) {
          if (d == null) return 'приходов не было';
          final days = DateTime.now().difference(d).inDays;
          return days <= 0 ? 'сегодня' : '$days дн. назад';
        }

        final cards = <Widget>[
          StatCard(
            label: 'Цена',
            value: Money.format(p.price),
            hint: p.wholesalePrice != null
                ? 'опт. ${Money.format(p.wholesalePrice!)}'
                : 'за 1 ${Qty.unitLabel(p.unit)}',
            icon: showIcons ? Icons.sell_outlined : null,
          ),
          if (canCost)
            StatCard(
              label: 'Себестоимость',
              value: Money.format(p.costPrice),
              hint: 'маржа ${formatPercent(margin)}',
              icon: showIcons ? Icons.account_balance_wallet_outlined : null,
              color: margin != null && margin < 0 ? AppColors.danger : AppColors.info,
            ),
          StatCard(
            label: 'Остаток',
            value: p.trackStock ? fmtQty(p.stockQty)! : '—',
            hint: !p.trackStock
                ? 'без учёта'
                : p.minStock > 0
                    ? 'мин. ${fmtQty(p.minStock)}'
                    : 'минимум не задан',
            icon: showIcons ? Icons.warehouse_outlined : null,
            color: switch (stockLevel(p)) {
              StockLevel.out || StockLevel.negative => AppColors.danger,
              StockLevel.low => AppColors.warning,
              _ => AppColors.success,
            },
          ),
          StatCard(
            label: 'Продано',
            value: s == null ? '…' : fmtQty(s.soldQty)!,
            hint: s == null ? 'за 30 дней' : 'за 30 дней · чеков: ${s.receipts}',
            icon: showIcons ? Icons.shopping_bag_outlined : null,
          ),
          StatCard(
            label: 'Выручка',
            value: s == null ? '…' : Money.format(s.revenue),
            hint: 'за 30 дней',
            icon: showIcons ? Icons.payments_outlined : null,
            color: AppColors.success,
          ),
          StatCard(
            label: 'Последний приход',
            value: s == null ? '…' : (s.lastReceiptAt == null ? '—' : formatDate(s.lastReceiptAt!)),
            hint: s == null ? ' ' : daysAgo(s.lastReceiptAt),
            icon: showIcons ? Icons.local_shipping_outlined : null,
            color: AppColors.info,
          ),
        ];
        return Wrap(
          spacing: Gap.s,
          runSpacing: Gap.s,
          children: [for (final card in cards) SizedBox(width: w, child: card)],
        );
      }),
      const SizedBox(height: Gap.l),
      SectionCard(
        title: 'Характеристики',
        child: Column(children: [
          _kv('Штрихкод', p.barcode ?? '—', selectable: true),
          _kv('Артикул', p.sku ?? '—', selectable: true),
          _kv('Ед. изм.', Qty.unitLabel(p.unit)),
          if (p.wholesalePrice != null) _kv('Оптовая цена', Money.format(p.wholesalePrice!)),
          _kv('НДС', p.vatPercent == 0 ? 'без НДС' : formatPercent(p.vatPercent)),
          if (p.trackStock) _kv('Продажа в минус', p.allowNegativeStock ? 'разрешена' : 'запрещена'),
          _kv('Гарантия', p.warrantyMonths == 0 ? 'нет' : '${p.warrantyMonths} мес.'),
          _kv('Поставщик', supplier?.name ?? '—'),
          _kv('Изменён', formatDateTime(p.updatedAt)),
          if (p.description != null) ...[
            const SizedBox(height: Gap.s),
            Align(alignment: Alignment.centerLeft, child: Text(p.description!)),
          ],
        ]),
      ),
      const SizedBox(height: Gap.l),
      SectionCard(
        title: 'Движение товара',
        trailing: Text('последние 50', style: muted),
        child: AsyncView<List<StockMovement>>(
          value: moves,
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: Gap.l),
                child: Text('Движений пока не было. Приход оформляется в разделе «Склад» или «Закупки».',
                    style: muted, textAlign: TextAlign.center),
              );
            }
            return Column(children: [
              for (final m in list)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    SizedBox(
                      width: 92,
                      child: Text(formatDateTime(m.createdAt), style: muted),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(movementTypeLabel(m.type), style: const TextStyle(fontWeight: FontWeight.w500)),
                        if (m.reason != null && m.reason!.isNotEmpty)
                          Text(m.reason!, style: muted, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(
                        '${m.qty > 0 ? '+' : ''}${fmtQty(m.qty)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: m.qty >= 0 ? AppColors.success : AppColors.danger,
                        ),
                      ),
                      Text('ост. ${fmtQty(m.qtyAfter)}', style: muted),
                    ]),
                  ]),
                ),
            ]);
          },
        ),
      ),
    ]);
  }

  Widget _kv(String k, String v, {bool selectable = false}) => Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 140,
              child: Text(k, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(child: selectable ? SelectableText(v) : Text(v)),
        ]),
      ));
}
