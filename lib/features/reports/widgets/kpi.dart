import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import 'charts.dart';

/// KPI tile: label, big value, optional comparison with a previous value.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.current,
    this.previous,
    this.previousLabel,
    this.inverse = false,
    this.hint,
    this.onTap,
    this.tooltip,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final num? current;
  final num? previous;
  /// E.g. "вчера: 1 200 000 сум".
  final String? previousLabel;
  final bool inverse;
  final String? hint;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = color ?? t.colorScheme.primary;
    // no base to compare with (e.g. no returns yesterday): no badge
    final hasDelta = current != null && previous != null && previous != 0;
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.l),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: c),
                const SizedBox(width: Gap.s),
              ],
              // Two lines so labels like «Сумма заказа (по себестоимости)»
              // stay readable in narrow (phone) tiles.
              Expanded(
                child: Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              ),
            ]),
            const SizedBox(height: Gap.s),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (hasDelta || previousLabel != null || hint != null) ...[
              const SizedBox(height: 2),
              // badge inline with the comparison text, so it wraps under the
              // badge instead of forming a narrow column on phones
              Text.rich(
                TextSpan(children: [
                  if (hasDelta)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: Gap.xs),
                        child: DeltaBadge(current: current!, previous: previous!, inverse: inverse),
                      ),
                    ),
                  if (previousLabel != null || hint != null) TextSpan(text: previousLabel ?? hint),
                ]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
              ),
            ],
          ]),
        ),
      ),
    );
    return tooltip == null ? card : Tooltip(message: tooltip!, child: card);
  }
}

/// Lays children out in an even responsive grid (min tile width [minTile]).
/// Tiles in one row share the height of the tallest one; with [stretchLast]
/// an incomplete last row is widened to fill the line instead of leaving a gap.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTile = 200,
    this.spacing = Gap.m,
    this.maxColumns = 6,
    this.stretchLast = false,
  });
  final List<Widget> children;
  final double minTile;
  final double spacing;
  final int maxColumns;
  final bool stretchLast;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = math.max(
            1, math.min(maxColumns, ((c.maxWidth + spacing) / (minTile + spacing)).floor()));
        final rows = <List<Widget>>[
          for (var i = 0; i < children.length; i += cols)
            children.sublist(i, math.min(i + cols, children.length)),
        ];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) SizedBox(height: spacing),
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var i = 0; i < (stretchLast ? rows[r].length : cols); i++) ...[
                  if (i > 0) SizedBox(width: spacing),
                  Expanded(child: i < rows[r].length ? rows[r][i] : const SizedBox()),
                ],
              ]),
            ),
          ],
        ]);
      });
}

/// Two widgets side by side on wide screens, stacked on narrow ones.
class TwoPane extends StatelessWidget {
  const TwoPane({super.key, required this.left, required this.right, this.flexLeft = 1, this.flexRight = 1, this.breakpoint = 900});
  final Widget left;
  final Widget right;
  final int flexLeft;
  final int flexRight;
  final double breakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < breakpoint) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            left,
            const SizedBox(height: Gap.m),
            right,
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: flexLeft, child: left),
          const SizedBox(width: Gap.m),
          Expanded(flex: flexRight, child: right),
        ]);
      });
}
