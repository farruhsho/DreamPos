// Background notification engine: scans the database for things that need
// attention (stock, overdue debts, birthdays, long shifts) and creates
// notifications idempotently. Runs offline on the device.
import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/widgets/widgets.dart' show formatDate, formatTime;
import '../reports/data/insights.dart' show loadOverdueDebtors;
import '../../l10n/l10n.dart';

/// Notification kinds produced by the engine (plus 'system' / 'task' from elsewhere).
abstract final class NotificationKind {
  static const lowStock = 'low_stock';
  static const outOfStock = 'out_of_stock';
  static const debtDue = 'debt_due';
  static const birthday = 'birthday';
  static const shift = 'shift';
  static const system = 'system';
  static const task = 'task';
}

/// Shift is considered "forgotten" after this many hours.
const longShiftHours = 16;

/// Max notifications of one kind created per run (protects against floods,
/// e.g. right after importing a catalogue with zero stock).
const maxPerKindPerRun = 100;

/// A read (or deleted) notification is not repeated for the same subject
/// within this window, so the owner isn't nagged every 10 minutes.
const renotifyAfter = Duration(hours: 24);

class NotificationCheckResult {
  const NotificationCheckResult({required this.created, required this.resolved, required this.unread});
  final int created;
  /// Unread notifications auto-marked read because the problem went away.
  final int resolved;
  final int unread;
}

class _Candidate {
  const _Candidate(this.kind, this.refType, this.refId, this.title, this.body);
  final String kind;
  final String refType;
  final String refId;
  final String title;
  final String body;
}

/// True when a person born on [birthday] celebrates on [day]
/// (29 February birthdays are celebrated on 28 February in common years).
bool isBirthdayOn(DateTime birthday, DateTime day) {
  if (birthday.month == day.month && birthday.day == day.day) return true;
  final leap = DateTime(day.year, 2, 29).month == 2;
  return !leap && birthday.month == 2 && birthday.day == 29 && day.month == 2 && day.day == 28;
}

/// Runs all checks; returns the number of unread notifications afterwards.
Future<int> runNotificationChecks(AppDatabase db, {DateTime? now}) async =>
    (await runNotificationChecksDetailed(db, now: now)).unread;

Future<NotificationCheckResult> runNotificationChecksDetailed(AppDatabase db, {DateTime? now}) async {
  final at = now ?? DateTime.now();
  // Title/body are stored in the DB, written in the UI language of the run.
  final l = L.current;
  final candidates = <_Candidate>[];

  // ---- stock: low (0 < stock ≤ min) and out (stock ≤ 0, ever stocked or min set)
  final stockRows = await db.customSelect(
    'SELECT p.id AS id, p.name AS name, p.unit AS unit, p.stock_qty AS stock, p.min_stock AS min '
    'FROM products p '
    'WHERE p.deleted_at IS NULL AND p.is_active = 1 AND p.track_stock = 1 '
    'AND ((p.stock_qty > 0 AND p.stock_qty <= p.min_stock) '
    '  OR (p.stock_qty <= 0 AND (p.min_stock > 0 OR EXISTS '
    '      (SELECT 1 FROM stock_movements m WHERE m.product_id = p.id)))) '
    'ORDER BY p.stock_qty <= 0 DESC, p.name',
  ).get();
  final lowIds = <String>{}, outIds = <String>{};
  for (final r in stockRows) {
    final id = r.data['id'] as String;
    final name = r.data['name'] as String;
    final unit = r.data['unit'] as String? ?? 'pcs';
    final stock = (r.data['stock'] as num).toDouble();
    final min = (r.data['min'] as num).toDouble();
    if (stock <= 0) {
      outIds.add(id);
      candidates.add(_Candidate(NotificationKind.outOfStock, 'product', id, l.notifOutOfStockTitle(name),
          l.notifOutOfStockBody(Qty.format(stock, unit, l))));
    } else {
      lowIds.add(id);
      candidates.add(_Candidate(NotificationKind.lowStock, 'product', id, l.notifLowStockTitle(name),
          l.notifLowStockBody(Qty.format(stock, unit, l), Qty.format(min, unit, l))));
    }
  }

  // ---- overdue debts
  final overdue = await loadOverdueDebtors(db, now: at);
  final debtIds = <String>{};
  for (final d in overdue) {
    debtIds.add(d.customerId);
    candidates.add(_Candidate(NotificationKind.debtDue, 'customer', d.customerId,
        l.notifDebtTitle(d.name),
        d.debt > d.overdue
            ? l.notifDebtBodyPartial(Money.format(d.overdue), Money.format(d.debt), formatDate(d.oldestDue))
            : l.notifDebtBody(Money.format(d.overdue), formatDate(d.oldestDue))));
  }

  // ---- birthdays today
  final customers = await (db.selectOnly(db.customers)
        ..addColumns([db.customers.id, db.customers.name, db.customers.birthday])
        ..where(db.customers.deletedAt.isNull() & db.customers.birthday.isNotNull()))
      .get();
  final birthdayIds = <String>{};
  for (final r in customers) {
    final b = r.read(db.customers.birthday)!;
    if (isBirthdayOn(b, at)) {
      final age = at.year - b.year;
      final id = r.read(db.customers.id)!;
      birthdayIds.add(id);
      candidates.add(_Candidate(NotificationKind.birthday, 'customer', id,
          l.notifBirthdayTitle('${r.read(db.customers.name)}'),
          age > 0 && age < 120 ? l.notifBirthdayBodyAge('$age') : l.notifBirthdayBody));
    }
  }

  // ---- shifts open too long
  final longShifts = await (db.select(db.shifts)
        ..where((s) =>
            s.status.equals('open') &
            s.deletedAt.isNull() &
            s.openedAt.isSmallerThanValue(at.subtract(const Duration(hours: longShiftHours)))))
      .get();
  final shiftIds = <String>{};
  for (final s in longShifts) {
    shiftIds.add(s.id);
    final h = at.difference(s.openedAt).inHours;
    candidates.add(_Candidate(NotificationKind.shift, 'shift', s.id,
        l.notifShiftTitle('${s.number}', '$h'),
        l.notifShiftBody(formatDate(s.openedAt), formatTime(s.openedAt))));
  }

  return db.transaction(() async {
    // Existing subjects that block a new notification: unread ones, or any
    // created within the re-notify window (read/deleted too).
    final blocking = await db.customSelect(
      'SELECT kind, ref_id FROM notifications WHERE ref_id IS NOT NULL AND '
      '((is_read = 0 AND deleted_at IS NULL) OR created_at >= ?1)',
      variables: [Variable.withDateTime(at.subtract(renotifyAfter))],
      readsFrom: {db.notifications},
    ).get();
    final blocked = {for (final r in blocking) '${r.data['kind']}|${r.data['ref_id']}'};

    var created = 0;
    final perKind = <String, int>{};
    for (final c in candidates) {
      final key = '${c.kind}|${c.refId}';
      if (blocked.contains(key)) continue;
      final n = perKind[c.kind] ?? 0;
      if (n >= maxPerKindPerRun) continue;
      perKind[c.kind] = n + 1;
      blocked.add(key);
      final id = newId();
      await db.into(db.notifications).insert(NotificationsCompanion.insert(
            id: id,
            kind: c.kind,
            title: c.title,
            body: Value(c.body),
            refType: Value(c.refType),
            refId: Value(c.refId),
            createdAt: Value(at),
            updatedAt: Value(at),
          ));
      await db.markDirty('notifications', id);
      created++;
    }

    // Auto-resolve: unread alerts whose problem is gone are marked read.
    final unresolved = await (db.select(db.notifications)
          ..where((n) =>
              n.isRead.equals(false) &
              n.deletedAt.isNull() &
              n.kind.isIn(const [
                NotificationKind.lowStock,
                NotificationKind.outOfStock,
                NotificationKind.debtDue,
                NotificationKind.shift,
                NotificationKind.birthday,
              ])))
        .get();
    var resolved = 0;
    for (final n in unresolved) {
      final still = switch (n.kind) {
        NotificationKind.lowStock => lowIds.contains(n.refId),
        NotificationKind.outOfStock => outIds.contains(n.refId),
        NotificationKind.debtDue => debtIds.contains(n.refId),
        NotificationKind.shift => shiftIds.contains(n.refId),
        // a birthday greeting is only relevant on the day itself; leaving it
        // unread would also block next year's reminder
        NotificationKind.birthday => birthdayIds.contains(n.refId),
        _ => true,
      };
      if (still) continue;
      await (db.update(db.notifications)..where((t) => t.id.equals(n.id)))
          .write(NotificationsCompanion(isRead: const Value(true), updatedAt: Value(at)));
      await db.markDirty('notifications', n.id);
      resolved++;
    }

    final unread = await db.customSelect(
      'SELECT COUNT(*) AS n FROM notifications WHERE is_read = 0 AND deleted_at IS NULL',
      readsFrom: {db.notifications},
    ).getSingle();
    return NotificationCheckResult(
        created: created, resolved: resolved, unread: (unread.data['n'] as num).toInt());
  });
}

/// Activates the background engine: runs once immediately and then every
/// 10 minutes while watched. The app shell activates it with a single
/// `ref.watch(notificationEngineProvider)`.
final notificationEngineProvider = Provider<void>((ref) {
  final db = ref.watch(databaseProvider);
  var running = false;
  var disposed = false;
  Future<void> run() async {
    if (running || disposed) return;
    running = true;
    try {
      await runNotificationChecks(db);
    } catch (e, st) {
      debugPrint('Notification checks failed: $e\n$st');
    } finally {
      running = false;
    }
  }

  final timer = Timer.periodic(const Duration(minutes: 10), (_) => run());
  ref.onDispose(() {
    disposed = true;
    timer.cancel();
  });
  unawaited(run());
});
