// Pure logic of the receipts module: filters, statuses, return preview and
// void eligibility. Mirrors the rules of SaleService so the UI can show the
// exact numbers/answers before calling the service.
import 'package:flutter/material.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/theme.dart';

// ------------------------------------------------------------------ statuses

const saleStatuses = ['completed', 'partially_returned', 'returned', 'voided'];

String saleStatusLabel(String s) => switch (s) {
  'completed' => 'Проведён',
  'partially_returned' => 'Частичный возврат',
  'returned' => 'Возвращён',
  'voided' => 'Аннулирован',
  'held' => 'Отложен',
  _ => s,
};

Color saleStatusColor(String s) => switch (s) {
  'completed' => AppColors.success,
  'partially_returned' => AppColors.warning,
  'returned' => AppColors.info,
  'voided' => AppColors.danger,
  _ => Colors.grey,
};

IconData saleStatusIcon(String s) => switch (s) {
  'completed' => Icons.receipt_long,
  'partially_returned' => Icons.assignment_return_outlined,
  'returned' => Icons.assignment_return,
  'voided' => Icons.block,
  _ => Icons.receipt,
};

// ------------------------------------------------------------------ period

enum Period {
  today('Сегодня'),
  yesterday('Вчера'),
  week('7 дней'),
  month('Месяц'),
  all('Всё время'),
  custom('Период…');

  const Period(this.label);
  final String label;
}

/// Half-open interval [from, to). Null bounds mean "unbounded".
class DateSpan {
  const DateSpan(this.from, this.to);
  final DateTime? from;
  final DateTime? to;

  @override
  bool operator ==(Object other) => other is DateSpan && other.from == from && other.to == to;
  @override
  int get hashCode => Object.hash(from, to);
}

DateSpan periodSpan(Period p, DateTime now, {DateSpan? custom}) {
  final today = DateTime(now.year, now.month, now.day);
  return switch (p) {
    Period.today => DateSpan(today, today.add(const Duration(days: 1))),
    Period.yesterday => DateSpan(today.subtract(const Duration(days: 1)), today),
    Period.week => DateSpan(today.subtract(const Duration(days: 6)), today.add(const Duration(days: 1))),
    Period.month => DateSpan(_monthAgo(today), today.add(const Duration(days: 1))),
    Period.all => const DateSpan(null, null),
    Period.custom => custom ?? DateSpan(today, today.add(const Duration(days: 1))),
  };
}

/// Same day one month earlier, clamped to the shorter month
/// (31 March -> 28/29 February, not 3 March).
DateTime _monthAgo(DateTime today) {
  final y = today.month == 1 ? today.year - 1 : today.year;
  final m = today.month == 1 ? 12 : today.month - 1;
  final lastDay = DateTime(y, m + 1, 0).day;
  return DateTime(y, m, today.day > lastDay ? lastDay : today.day);
}

String periodTitle(Period p, DateSpan? custom) {
  if (p != Period.custom || custom?.from == null) return p.label;
  final from = custom!.from!;
  final to = custom.to!.subtract(const Duration(days: 1));
  String d(DateTime x) => '${x.day.toString().padLeft(2, '0')}.${x.month.toString().padLeft(2, '0')}';
  return from == to ? d(from) : '${d(from)} – ${d(to)}';
}

// ------------------------------------------------------------------ filters

class SalesFilter {
  const SalesFilter({
    this.period = Period.today,
    this.custom,
    this.status,
    this.method,
    this.cashierId,
    this.shiftId,
    this.query = '',
    this.limit = pageSize,
  });

  static const pageSize = 100;

  final Period period;
  final DateSpan? custom;
  final String? status;
  final String? method;
  final String? cashierId;

  /// Forced for users without "view all shifts".
  final String? shiftId;
  final String query;
  final int limit;

  DateSpan span(DateTime now) => periodSpan(period, now, custom: custom);

  SalesFilter copyWith({
    Period? period,
    DateSpan? custom,
    String? Function()? status,
    String? Function()? method,
    String? Function()? cashierId,
    String? Function()? shiftId,
    String? query,
    int? limit,
  }) => SalesFilter(
    period: period ?? this.period,
    custom: custom ?? this.custom,
    status: status == null ? this.status : status(),
    method: method == null ? this.method : method(),
    cashierId: cashierId == null ? this.cashierId : cashierId(),
    shiftId: shiftId == null ? this.shiftId : shiftId(),
    query: query ?? this.query,
    limit:
        limit ??
        (period == null &&
                custom == null &&
                status == null &&
                method == null &&
                cashierId == null &&
                shiftId == null &&
                (query == null || query == this.query)
            ? this.limit
            : pageSize),
  );

  /// True when any filter besides the period is set.
  bool get hasFilters => query.isNotEmpty || status != null || method != null || cashierId != null;

  @override
  bool operator ==(Object other) =>
      other is SalesFilter &&
      other.period == period &&
      other.custom == custom &&
      other.status == status &&
      other.method == method &&
      other.cashierId == cashierId &&
      other.shiftId == shiftId &&
      other.query == query &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(period, custom, status, method, cashierId, shiftId, query, limit);
}

/// LIKE patterns for a user query. SQLite LIKE folds case only for ASCII, so
/// for Cyrillic we try the text as typed, lower-cased and capitalised.
List<String> likeVariants(String q) {
  final t = q.trim().replaceAll('%', '').replaceAll('_', '');
  if (t.isEmpty) return const [];
  final lower = t.toLowerCase();
  final cap = lower[0].toUpperCase() + lower.substring(1);
  return {t, lower, cap, t.toUpperCase()}.map((v) => '%$v%').toList();
}

// ------------------------------------------------------------------ returns

/// Refund for returning [qty] of [item] — exactly the rule SaleService uses
/// (D-009): proportional to the paid line total; the last unit returned
/// takes the rounding remainder.
int previewLineRefund(SaleItem item, double qty) {
  if (qty <= 0 || item.qty <= 0) return 0;
  final available = Qty.round(item.qty - item.returnedQty);
  final isLast = (available - qty).abs() < 1e-9;
  final alreadyRefunded = (item.total * item.returnedQty / item.qty).round();
  return isLast ? item.total - alreadyRefunded : (item.total * qty / item.qty).round();
}

double availableToReturn(SaleItem item) => Qty.round(item.qty - item.returnedQty);

/// Total refund for a selection {saleItemId: qty}.
int previewRefund(Iterable<SaleItem> items, Map<String, double> qty) {
  var total = 0;
  for (final it in items) {
    total += previewLineRefund(it, qty[it.id] ?? 0);
  }
  return total;
}

/// Bonus clawback the service will apply (informational).
int previewBonusClawback(Sale sale, int refundTotal, {required bool fully}) {
  if (sale.bonusEarned <= 0 || sale.total <= 0) return 0;
  return fully
      ? sale.bonusEarned - (sale.bonusEarned * sale.refundedTotal / sale.total).round()
      : (sale.bonusEarned * refundTotal / sale.total).round();
}

/// Refund methods offered in the wizard.
List<String> refundMethodOptions({required bool hasCustomer}) => [
  'cash',
  'card',
  'transfer',
  if (hasCustomer) 'debt',
  if (hasCustomer) 'bonus',
];

/// The method that paid the largest part of the sale (if refundable),
/// otherwise cash.
String defaultRefundMethod(List<SalePayment> payments, {required bool hasCustomer}) {
  final by = <String, int>{};
  for (final p in payments) {
    by[p.method] = (by[p.method] ?? 0) + p.amount;
  }
  final options = refundMethodOptions(hasCustomer: hasCustomer);
  final sorted = by.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  for (final e in sorted) {
    if (options.contains(e.key)) return e.key;
  }
  return 'cash';
}

String refundMethodHint(String m) => switch (m) {
  'cash' => 'Выдать деньги из кассы',
  'card' => 'Вернуть на карту через терминал',
  'transfer' => 'Вернуть переводом',
  'debt' => 'Уменьшить долг клиента',
  'bonus' => 'Начислить на бонусный счёт клиента',
  _ => '',
};

/// Null if the return period is still open, otherwise a user message.
/// Mirrors SaleService.returnItems (`return_days`, default 14, 0 = no limit).
String? returnPeriodExpired(Sale sale, String? returnDaysSetting, DateTime now) {
  final days = int.tryParse(returnDaysSetting ?? '') ?? 14;
  if (days > 0 && now.difference(sale.createdAt).inDays > days) {
    return 'Срок возврата ($days дн.) истёк';
  }
  return null;
}

bool canReturnStatus(String status) => status == 'completed' || status == 'partially_returned';

/// Null if the sale can be voided now, otherwise the reason why not.
/// Mirrors SaleService.voidSale.
String? voidBlockReason(Sale sale, Shift? currentShift) {
  if (sale.status == 'voided') return 'Чек уже аннулирован';
  if (sale.status != 'completed') return 'Аннулировать можно только чек без возвратов';
  if (sale.shiftId != null) {
    if (currentShift == null || currentShift.status != 'open') {
      return 'Смена чека закрыта — оформите возврат';
    }
    if (currentShift.id != sale.shiftId) return 'Чек из другой смены — оформите возврат';
  }
  return null;
}

const quickReturnReasons = ['Брак', 'Не подошёл', 'Ошибка кассира', 'Другое'];
