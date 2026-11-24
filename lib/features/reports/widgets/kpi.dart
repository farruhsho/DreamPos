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
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.l),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: c),
                const SizedBox(width: Gap.s),
              ],
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              ),
              if (current != null && previous != null)
                DeltaBadge(current: current!, previous: previous!, inverse: inverse),
            ]),
            const SizedBox(height: Gap.s),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (previousLabel != null || hint != null) ...[
              const SizedBox(height: 2),
              Text(previousLabel ?? hint!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ],
          ]),
        ),
      ),
    );
    return tooltip == null ? card : Tooltip(message: tooltip!, child: card);
  }
}

/// Lays children out in an even responsive grid (min tile width [minTile]).
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTile = 200,
    this.spacing = Gap.m,
    this.maxColumns = 6,
  });
  final List<Widget> children;
  final double minTile;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = math.max(1, math.min(maxColumns, ((c.maxWidth + spacing) / (minTile + spacing)).floor()));
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(spacing: spacing, runSpacing: spacing, children: [
          for (final ch in children) SizedBox(width: w, child: ch),
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
