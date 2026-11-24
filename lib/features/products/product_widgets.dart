import 'package:flutter/material.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'product_logic.dart';

/// Colored dot of a category (grey outline when there is none).
class CategoryDot extends StatelessWidget {
  const CategoryDot({super.key, this.color, this.size = 10});
  final int? color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color == null ? Colors.transparent : Color(color!),
          shape: BoxShape.circle,
          border: color == null
              ? Border.all(color: Theme.of(context).colorScheme.outline, width: 1.2)
              : null,
        ),
      );
}

enum StockLevel { untracked, ok, low, out, negative }

StockLevel stockLevel(Product p) {
  if (!p.trackStock) return StockLevel.untracked;
  if (p.stockQty < 0) return StockLevel.negative;
  if (p.stockQty == 0) return StockLevel.out;
  if (p.minStock > 0 && p.stockQty <= p.minStock) return StockLevel.low;
  return StockLevel.ok;
}

/// Stock with unit; red when out/negative, amber when low.
class StockBadge extends StatelessWidget {
  const StockBadge(this.product, {super.key, this.dense = false});
  final Product product;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final lvl = stockLevel(p);
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    final (Color? color, String tip) = switch (lvl) {
      StockLevel.untracked => (null, l.prodStockUntracked),
      StockLevel.ok => (null, l.prodStockIn),
      StockLevel.low => (AppColors.warning, l.prodStockLowTip(Qty.format(p.minStock, p.unit, l))),
      StockLevel.out => (AppColors.danger, l.prodStockOut),
      StockLevel.negative => (AppColors.danger, l.prodStockNegativeTip),
    };
    final text = lvl == StockLevel.untracked ? '—' : Qty.format(p.stockQty, p.unit, l);
    final child = color == null
        ? Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: lvl == StockLevel.untracked ? scheme.onSurfaceVariant : null))
        : Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: dense ? 2 : 3),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(text,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          );
    return Tooltip(message: tip, child: child);
  }
}

/// One catalog row. Table-like on wide widths, two-line on phones.
class ProductRow extends StatelessWidget {
  const ProductRow({
    super.key,
    required this.product,
    required this.category,
    required this.showCost,
    required this.selected,
    required this.selectionMode,
    required this.checked,
    required this.onTap,
    required this.onLongPress,
    required this.onCheck,
  });

  final Product product;
  final Category? category;
  final bool showCost;
  final bool selected;
  final bool selectionMode;
  final bool checked;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onCheck;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final p = product;
    final muted = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    final l = context.l10n;
    final codes = [
      if (p.barcode != null) p.barcode!,
      if (p.sku != null) l.prodSkuShort(p.sku!),
      category?.name ?? l.prodNoCategory,
    ].join(' · ');
    final margin = marginPercent(p.price, p.costPrice);
    final marginColor = margin == null
        ? null
        : margin < 0
            ? AppColors.danger
            : margin < 10
                ? AppColors.warning
                : AppColors.success;

    Widget title = Row(children: [
      Flexible(
        child: Text(p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: p.isActive ? null : t.colorScheme.onSurfaceVariant,
                decoration: p.isActive ? null : TextDecoration.lineThrough)),
      ),
      if (p.isFavorite) ...[
        const SizedBox(width: Gap.xs),
        const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
      ],
      if (!p.isActive) ...[
        const SizedBox(width: Gap.xs),
        StatusChip(l.prodArchive, color: t.colorScheme.outline),
      ],
    ]);

    final leading = selectionMode
        ? Checkbox(
            value: checked,
            onChanged: (v) => onCheck(v ?? false),
            // Keep the row height unchanged when selection mode toggles.
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CategoryDot(color: category?.color, size: 12),
          );

    return Material(
      color: selected ? t.colorScheme.primaryContainer.withValues(alpha: 0.45) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 680;
          if (!wide) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.s),
              child: Row(children: [
                SizedBox(width: 40, child: Center(child: leading)),
                const SizedBox(width: Gap.s),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    title,
                    const SizedBox(height: 2),
                    Text(codes, style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                const SizedBox(width: Gap.s),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(Money.format(p.price), style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  StockBadge(p, dense: true),
                ]),
              ]),
            );
          }
          final cols = _TableCols.of(c.maxWidth);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.s + 2),
            child: Row(children: [
              SizedBox(width: 40, child: Center(child: leading)),
              const SizedBox(width: Gap.s),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  title,
                  const SizedBox(height: 2),
                  Text(codes, style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              SizedBox(
                width: cols.price,
                child: Text(Money.format(p.price),
                    textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              if (showCost) ...[
                SizedBox(
                    width: cols.cost,
                    child: Text(Money.format(p.costPrice), textAlign: TextAlign.right, style: muted)),
                SizedBox(
                  width: cols.margin,
                  child: Text(formatPercent(margin),
                      textAlign: TextAlign.right,
                      style: TextStyle(color: marginColor, fontWeight: FontWeight.w500)),
                ),
              ],
              SizedBox(width: cols.stock, child: Align(alignment: Alignment.centerRight, child: StockBadge(p))),
            ]),
          );
        }),
      ),
    );
  }
}

/// Numeric column widths of the wide table. On very wide panes (full-width
/// list on a desktop) the columns grow, so the numbers are not crammed to the
/// right edge with a large empty gap after the product name.
class _TableCols {
  const _TableCols(this.price, this.cost, this.margin, this.stock);
  final double price, cost, margin, stock;

  static _TableCols of(double width) =>
      width >= 1200 ? const _TableCols(170, 160, 110, 140) : const _TableCols(120, 110, 70, 110);
}

/// Header of the wide table layout.
class ProductTableHeader extends StatelessWidget {
  const ProductTableHeader({super.key, required this.showCost, this.leading});
  final bool showCost;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final s = t.textTheme.labelMedium?.copyWith(color: t.colorScheme.onSurfaceVariant);
    final l = context.l10n;
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 680) return const SizedBox.shrink();
      final cols = _TableCols.of(c.maxWidth);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.s),
        child: Row(children: [
          SizedBox(width: 40, child: Center(child: leading)),
          const SizedBox(width: Gap.s),
          Expanded(child: Text(l.commonProduct, style: s)),
          SizedBox(width: cols.price, child: Text(l.commonPrice, textAlign: TextAlign.right, style: s)),
          if (showCost) ...[
            SizedBox(
                width: cols.cost,
                child: Text(l.prodCostShort,
                    textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: s)),
            SizedBox(
                width: cols.margin,
                child: Text(l.prodMargin,
                    textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: s)),
          ],
          SizedBox(
              width: cols.stock,
              child: Text(l.commonStock,
                  textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: s)),
        ]),
      );
    });
  }
}

/// Lays children in a row on wide forms, stacked on narrow.
class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.children, this.breakpoint = 520});
  final List<Widget> children;
  final double breakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < breakpoint) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: Gap.m),
              children[i],
            ],
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: Gap.m),
            Expanded(child: children[i]),
          ],
        ]);
      });
}

/// Section header inside forms/detail views.
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.title, required this.children, this.icon, this.trailing});
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.l),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: t.colorScheme.primary),
            const SizedBox(width: Gap.s),
          ],
          Expanded(
            child: Text(title,
                style: t.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700, color: t.colorScheme.primary)),
          ),
          ?trailing,
        ]),
        const SizedBox(height: Gap.m),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: Gap.m),
          children[i],
        ],
      ]),
    );
  }
}

/// Read-only field that looks like a disabled input (used when the user has
/// no permission to change a value).
class ReadOnlyField extends StatelessWidget {
  const ReadOnlyField({super.key, required this.label, required this.value, this.helper});
  final String label;
  final String value;
  final String? helper;

  @override
  Widget build(BuildContext context) => InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 2,
          enabled: false,
          suffixIcon: const Icon(Icons.lock_outline, size: 18),
        ),
        child: Text(value),
      );
}
