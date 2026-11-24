import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import 'staff_logic.dart';

final staffServiceProvider = Provider((ref) => StaffService(ref.watch(databaseProvider)));
final timeClockProvider = Provider((ref) => TimeClock(ref.watch(databaseProvider)));

/// All non-deleted staff: active first, then by name.
final staffUsersProvider = StreamProvider<List<User>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.users)
        ..where((u) => u.deletedAt.isNull())
        ..orderBy([(u) => OrderingTerm.desc(u.isActive), (u) => OrderingTerm.asc(u.name)]))
      .watch();
});

/// Time range [from, to).
typedef Period = ({DateTime from, DateTime to});

Period todayPeriod([DateTime? now]) {
  final n = now ?? DateTime.now();
  final d = DateTime(n.year, n.month, n.day);
  return (from: d, to: DateTime(d.year, d.month, d.day + 1));
}

/// Work sessions overlapping [period] (open sessions always included).
final workSessionsProvider = StreamProvider.autoDispose.family<List<WorkSession>, Period>((ref, p) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.workSessions)
        ..where(
          (w) =>
              w.deletedAt.isNull() &
              w.startedAt.isSmallerThanValue(p.to) &
              (w.endedAt.isNull() | w.endedAt.isBiggerThanValue(p.from)),
        )
        ..orderBy([(w) => OrderingTerm.desc(w.startedAt)]))
      .watch();
});

/// Open (clocked-in) session of the current session user.
final myOpenWorkSessionProvider = StreamProvider<WorkSession?>((ref) {
  final db = ref.watch(databaseProvider);
  final uid = ref.watch(sessionProvider)?.user.id;
  if (uid == null) return Stream.value(null);
  return (db.select(db.workSessions)
        ..where((w) => w.userId.equals(uid) & w.endedAt.isNull() & w.deletedAt.isNull())
        ..orderBy([(w) => OrderingTerm.desc(w.startedAt)])
        ..limit(1))
      .watchSingleOrNull();
});

/// Motivation for a month (any day inside it), live on sales/returns changes.
final motivationProvider = StreamProvider.autoDispose.family<List<MotivationRow>, DateTime>((ref, month) {
  final db = ref.watch(databaseProvider);
  final (from, to) = monthRange(month);
  return db
      .customSelect('SELECT 1', readsFrom: {db.sales, db.returns, db.users})
      .watch()
      .asyncMap((_) => computeMotivation(db, from, to));
});

/// Audit journal filter.
class AuditFilter {
  const AuditFilter({this.userId, this.group, required this.from, required this.to});
  final String? userId;
  final String? group; // action prefix like 'cash.'
  final DateTime from;
  final DateTime to;

  @override
  bool operator ==(Object other) =>
      other is AuditFilter &&
      other.userId == userId &&
      other.group == group &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(userId, group, from, to);
}

const auditLimit = 500;

final auditProvider = StreamProvider.autoDispose.family<List<AuditEntry>, AuditFilter>((ref, f) {
  final db = ref.watch(databaseProvider);
  final q = db.select(db.auditLog)
    ..where((a) => a.at.isBiggerOrEqualValue(f.from) & a.at.isSmallerThanValue(f.to));
  if (f.userId != null) q.where((a) => a.userId.equals(f.userId!));
  if (f.group != null) q.where((a) => a.action.like('${f.group}%'));
  q
    ..orderBy([(a) => OrderingTerm.desc(a.seq)])
    ..limit(auditLimit);
  return q.watch();
});
