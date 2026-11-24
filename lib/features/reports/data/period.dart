import '../../../core/widgets/widgets.dart' show formatDate;
import '../../../l10n/l10n.dart';

/// Report period presets shown in the period picker.
enum PeriodPreset {
  today,
  yesterday,
  week,
  month,
  lastMonth,
  quarter,
  year,
  custom;

  String labelIn(AppLocalizations l) => switch (this) {
        PeriodPreset.today => l.commonToday,
        PeriodPreset.yesterday => l.commonYesterday,
        PeriodPreset.week => l.commonWeek,
        PeriodPreset.month => l.commonMonth,
        PeriodPreset.lastMonth => l.repPeriodLastMonth,
        PeriodPreset.quarter => l.repPeriodQuarter,
        PeriodPreset.year => l.commonYear,
        PeriodPreset.custom => l.repPeriodCustom,
      };

  String get label => labelIn(L.current);
}

/// Half-open time interval `[start, end)` in local time.
class ReportPeriod {
  const ReportPeriod(this.start, this.end, {this.preset = PeriodPreset.custom});

  final DateTime start;
  final DateTime end;
  final PeriodPreset preset;

  /// Builds a preset relative to [now].
  /// "Неделя"/"Месяц"/"Квартал"/"Год" are calendar-to-date periods
  /// (Monday, 1st of month, quarter start, Jan 1st) — what shop owners expect.
  factory ReportPeriod.preset(PeriodPreset p, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final tomorrow = DateTime(n.year, n.month, n.day + 1);
    switch (p) {
      case PeriodPreset.today:
      case PeriodPreset.custom:
        return ReportPeriod(today, tomorrow, preset: p);
      case PeriodPreset.yesterday:
        return ReportPeriod(DateTime(n.year, n.month, n.day - 1), today, preset: p);
      case PeriodPreset.week:
        return ReportPeriod(DateTime(n.year, n.month, n.day - (n.weekday - 1)), tomorrow,
            preset: p);
      case PeriodPreset.month:
        return ReportPeriod(DateTime(n.year, n.month, 1), tomorrow, preset: p);
      case PeriodPreset.lastMonth:
        return ReportPeriod(DateTime(n.year, n.month - 1, 1), DateTime(n.year, n.month, 1),
            preset: p);
      case PeriodPreset.quarter:
        final qStart = ((n.month - 1) ~/ 3) * 3 + 1;
        return ReportPeriod(DateTime(n.year, qStart, 1), tomorrow, preset: p);
      case PeriodPreset.year:
        return ReportPeriod(DateTime(n.year, 1, 1), tomorrow, preset: p);
    }
  }

  /// Custom inclusive day range (from date picker) -> `[first 00:00, last+1 00:00)`.
  factory ReportPeriod.days(DateTime first, DateTime last) => ReportPeriod(
        DateTime(first.year, first.month, first.day),
        DateTime(last.year, last.month, last.day + 1),
      );

  /// Number of calendar days covered (at least 1).
  int get dayCount {
    var d = 0;
    var c = start;
    while (c.isBefore(end)) {
      d++;
      c = DateTime(c.year, c.month, c.day + 1);
    }
    return d < 1 ? 1 : d;
  }

  /// Every calendar day in the period (for zero-filled charts).
  List<DateTime> get days {
    final out = <DateTime>[];
    var c = DateTime(start.year, start.month, start.day);
    while (c.isBefore(end)) {
      out.add(c);
      c = DateTime(c.year, c.month, c.day + 1);
    }
    return out;
  }

  /// The same-length period immediately before this one (for comparisons).
  ReportPeriod get previous {
    final len = dayCount;
    return ReportPeriod(DateTime(start.year, start.month, start.day - len), start);
  }

  /// Dates only, e.g. `01.11.2026 – 24.11.2026` (one date for a single day).
  String get rangeLabel {
    final last = end.subtract(const Duration(seconds: 1));
    return formatDate(start) == formatDate(last)
        ? formatDate(start)
        : '${formatDate(start)} – ${formatDate(last)}';
  }

  String labelIn(AppLocalizations l) =>
      preset == PeriodPreset.custom ? rangeLabel : '${preset.labelIn(l)} · $rangeLabel';

  String get label => labelIn(L.current);

  @override
  bool operator ==(Object other) =>
      other is ReportPeriod && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// SQL day key `YYYY-MM-DD` matching `date(x + utcOffset, 'unixepoch')`.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
