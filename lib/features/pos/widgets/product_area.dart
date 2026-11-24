// Left side of the till: scanner/search field, category chips, product tiles.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../pos_providers.dart';

class PosSearchBar extends StatelessWidget {
  const PosSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    this.error,
    this.busy = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final String? error;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('pos-search'),
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      textInputAction: TextInputAction.done,
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(
        hintText: context.isCompact ? context.l10n.posSearchHintShort : context.l10n.posSearchHint,
        prefixIcon: busy
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
            : const Icon(Icons.qr_code_scanner),
        errorText: error,
        suffixIcon: ListenableBuilder(
          listenable: controller,
          builder: (_, _) => controller.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(tooltip: context.l10n.posClearEsc, icon: const Icon(Icons.close), onPressed: onClear),
        ),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key, required this.selected, required this.onSelected});
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(posCategoriesProvider).value ?? const <Category>[];
    final hasFav = ref.watch(posHasFavoritesProvider).value ?? false;
    final chips = <Widget>[
      ChoiceChip(
        label: Text(context.l10n.commonAll),
        selected: selected == null,
        onSelected: (_) => onSelected(null),
      ),
      if (hasFav)
        ChoiceChip(
          avatar: const Icon(Icons.star, size: 18, color: AppColors.warning),
          label: Text(context.l10n.posFavorites),
          selected: selected == kFavorites,
          onSelected: (_) => onSelected(kFavorites),
        ),
      for (final c in cats)
        ChoiceChip(
          avatar: CircleAvatar(backgroundColor: Color(c.color), radius: 6),
          label: Text(c.name),
          selected: selected == c.id,
          onSelected: (_) => onSelected(selected == c.id ? null : c.id),
        ),
    ];
    // The row scrolls sideways; a soft fade at the right edge tells the
    // cashier there are more categories (a hard cut looked like a bug). The
    // end padding lets the last chip scroll fully out of the fade.
    return SizedBox(
      height: 40,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => LinearGradient(
          colors: const [Colors.black, Colors.black, Colors.transparent],
          stops: [0, r.width <= 32 ? 0 : 1 - 32 / r.width, 1],
        ).createShader(r),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 32),
          itemCount: chips.length,
          separatorBuilder: (_, _) => const SizedBox(width: Gap.s),
          itemBuilder: (_, i) => chips[i],
        ),
      ),
    );
  }
}

class ProductGrid extends ConsumerWidget {
  const ProductGrid({super.key, required this.filter, required this.onTap});
  final ProductFilter filter;
  final ValueChanged<Product> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(posProductsProvider(filter));
    return AsyncView(
      value: products,
      onRetry: () => ref.invalidate(posProductsProvider(filter)),
      data: (list) {
        if (list.isEmpty) {
          if (filter.query.isNotEmpty) {
            return EmptyState(
              icon: Icons.search_off,
              title: context.l10n.commonNothingFound,
              message: context.l10n.posNoResults(filter.query),
            );
          }
          if (filter.categoryId != null) {
            return EmptyState(icon: Icons.category_outlined, title: context.l10n.posCategoryEmpty);
          }
          return EmptyState(
            icon: Icons.inventory_2_outlined,
            title: context.l10n.posCatalogEmpty,
            message: context.l10n.posCatalogEmptyHint,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.only(bottom: Gap.l),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 190,
            mainAxisExtent: 118,
            crossAxisSpacing: Gap.s,
            mainAxisSpacing: Gap.s,
          ),
          itemCount: list.length,
          itemBuilder: (_, i) => ProductTile(product: list[i], onTap: () => onTap(list[i])),
        );
      },
    );
  }
}

/// Stock badge color: red when out of stock, amber when at/below minimum.
Color? stockColor(Product p) {
  if (!p.trackStock) return null;
  if (p.stockQty <= 0) return AppColors.danger;
  if (p.minStock > 0 && p.stockQty <= p.minStock) return AppColors.warning;
  return AppColors.success;
}

class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final p = product;
    final sc = stockColor(p);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // keep keyboard focus on the scanner field
        canRequestFocus: false,
        child: Padding(
          padding: const EdgeInsets.all(Gap.m),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.2)),
              ),
              if (p.isFavorite) const Icon(Icons.star, size: 16, color: AppColors.warning),
            ]),
            const Spacer(),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Money.format(p.price) +
                        (p.unit == 'pcs' ? '' : ' / ${Qty.unitLabel(p.unit)}'),
                    style: t.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800, color: t.colorScheme.primary),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: Gap.xs),
            if (sc != null)
              StatusChip(Qty.format(p.stockQty, p.unit), color: sc)
            else
              Text(context.l10n.posNoStockTracking,
                  style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
