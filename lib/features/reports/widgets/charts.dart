// Lightweight charts drawn with plain widgets (no chart package): bar chart
// with tooltips, horizontal share bars, and a weekday × hour heatmap.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class BarDatum {
  const BarDatum({required this.label, required this.value, this.tooltip, this.highlight = false});
  final String label;
  final int value;
  final String? tooltip;
  final bool highlight;
}

/// Vertical bar chart. Bars are proportional to the max value; negatives are
/// drawn as a small red stub. Labels are thinned to avoid overlap.
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    super.key,
    required this.data,
    this.height = 180,
    this.formatAxis,
    this.color,
    this.onTap,
  });

  final List<BarDatum> data;
  final double height;
  final String Function(int)? formatAxis;
  final Color? color;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final base = color ?? t.colorScheme.primary;
    final maxV = data.fold<int>(0, (m, d) => math.max(m, d.value));
    final labelStyle = t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    return LayoutBuilder(builder: (context, c) {
      final n = math.max(1, data.length);
      final slot = c.maxWidth / n;
      final every = math.max(1, (44 / slot).ceil());
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (formatAxis != null)
          Text(maxV > 0 ? formatAxis!(maxV) : '', style: labelStyle, maxLines: 1),
        const SizedBox(height: Gap.xs),
        SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.colorScheme.outlineVariant)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < data.length; i++)
                Expanded(
                  child: Tooltip(
                    message: data[i].tooltip ?? '${data[i].label}: ${data[i].value}',
                    waitDuration: const Duration(milliseconds: 150),
                    child: InkWell(
                      onTap: onTap == null ? null : () => onTap!(i),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: slot > 14 ? 2 : 0.5),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            constraints: const BoxConstraints(maxWidth: 56),
                            duration: const Duration(milliseconds: 250),
                            height: data[i].value < 0
                                ? 3
                                : maxV == 0
                                    ? 0
                                    : math.max(data[i].value > 0 ? 2.0 : 0.0,
                                        height * data[i].value / maxV),
                            decoration: BoxDecoration(
                              color: data[i].value < 0
                                  ? AppColors.danger
                                  : data[i].highlight
                                      ? base
                                      : base.withValues(alpha: 0.55),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: Gap.xs),
        Row(children: [
          for (var i = 0; i < data.length; i++)
            Expanded(
              child: Text(
                // thinned from the end so the latest bar (today) is always labelled
                (data.length - 1 - i) % every == 0 ? data[i].label : '',
                style: labelStyle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.clip,
                softWrap: false,
              ),
            ),
        ]),
      ]);
    });
  }
}

class ShareItem {
  const ShareItem(this.label, this.value, {this.trailing, this.color, this.onTap});
  final String label;
  final int value;
  final String? trailing;
  final Color? color;
  final VoidCallback? onTap;
}

/// Horizontal bars showing each item's share of the largest/total value.
class ShareBars extends StatelessWidget {
  const ShareBars({super.key, required this.items, this.relativeToMax = false});
  final List<ShareItem> items;
  /// When true bars are relative to the largest value (rankings);
  /// otherwise relative to the total (splits).
  final bool relativeToMax;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final total = items.fold<int>(0, (s, i) => s + math.max(0, i.value));
    final maxV = items.fold<int>(0, (m, i) => math.max(m, i.value));
    final denom = relativeToMax ? maxV : total;
    return Column(children: [
      for (final it in items)
        InkWell(
          onTap: it.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(
                    child: Text(it.label,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodyMedium)),
                const SizedBox(width: Gap.s),
                Text(it.trailing ?? '${it.value}',
                    style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: denom <= 0 ? 0 : (math.max(0, it.value) / denom).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: t.colorScheme.surfaceContainerHighest,
                  color: it.color ?? t.colorScheme.primary,
                ),
              ),
            ]),
          ),
        ),
    ]);
  }
}

const weekdayShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

/// Weekday × hour heatmap. [values] is indexed [weekday-1][hour].
class HourHeatmap extends StatelessWidget {
  const HourHeatmap({super.key, required this.values, required this.tooltip});
  final List<List<int>> values;
  final String Function(int weekday, int hour, int value) tooltip;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final maxV = values.expand((r) => r).fold<int>(0, math.max);
    // Only show hours that ever had sales (plus neighbours), to keep it compact.
    var first = 24, last = -1;
    for (final row in values) {
      for (var h = 0; h < 24; h++) {
        if (row[h] > 0) {
          first = math.min(first, h);
          last = math.max(last, h);
        }
      }
    }
    if (last < 0) {
      first = 8;
      last = 21;
    }
    final hours = [for (var h = first; h <= last; h++) h];
    final labelStyle = t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    return LayoutBuilder(builder: (context, c) {
      const labelW = 28.0;
      // fills the card width on desktop instead of a small block at the left
      final cell = ((c.maxWidth - labelW) / hours.length).clamp(16.0, 160.0);
      final cellH = cell >= 60 ? 28.0 : 22.0;
      final grid = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const SizedBox(width: labelW),
          for (final h in hours)
            SizedBox(
                width: cell,
                child: Text('$h', style: labelStyle, textAlign: TextAlign.center)),
        ]),
        for (var wd = 0; wd < 7; wd++)
          Row(children: [
            SizedBox(
                width: labelW,
                height: cellH + 2,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(weekdayShort[wd], style: labelStyle))),
            for (final h in hours)
              Tooltip(
                message: tooltip(wd + 1, h, values[wd][h]),
                waitDuration: const Duration(milliseconds: 150),
                child: Container(
                  width: cell - 2,
                  height: cellH,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: values[wd][h] == 0 || maxV == 0
                        ? t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                        : t.colorScheme.primary
                            .withValues(alpha: 0.15 + 0.85 * values[wd][h] / maxV),
                  ),
                ),
              ),
          ]),
      ]);
      return SingleChildScrollView(scrollDirection: Axis.horizontal, child: grid);
    });
  }
}

/// Small "+12% / −5%" delta badge.
class DeltaBadge extends StatelessWidget {
  const DeltaBadge({super.key, required this.current, required this.previous, this.inverse = false});
  final num current;
  final num previous;
  /// For metrics where growth is bad (returns).
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    if (previous == 0) {
      return Text(current == 0 ? '—' : 'новое',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant));
    }
    final pct = (current - previous) * 100 / previous.abs();
    final up = pct >= 0;
    final good = inverse ? !up : up;
    final color = pct.abs() < 0.5
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : good
            ? AppColors.success
            : AppColors.danger;
    final s = pct.abs() >= 1000 ? '>999' : pct.abs().toStringAsFixed(pct.abs() >= 10 ? 0 : 1);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: color),
      Text('${s.replaceAll('.', ',')}%',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ]);
  }
}

/// Payment method colors, shared by the dashboard and the payments report.
Color? paymentMethodColor(String method) => switch (method) {
      'cash' => AppColors.success,
      'card' => AppColors.info,
      'transfer' => AppColors.brand,
      'debt' => AppColors.warning,
      _ => null,
    };
