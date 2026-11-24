// Staff module logic: user management rules, time clock, motivation math,
// permission and audit labels. UI-free so it can be unit tested.
import 'package:drift/drift.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/security/pin.dart';
import '../../domain/errors.dart';
import '../../domain/services/auth_service.dart';
import '../../l10n/l10n.dart';

export '../../core/widgets/widgets.dart' show pluralRu;

// ------------------------------------------------------------ owner guard

/// Returns an error if changing [userId] to ([newRole], [newActive]) would
/// leave the store without an active owner.
String? lastOwnerGuard(List<User> users, {required String userId, required Role newRole, required bool newActive}) {
  final target = users.where((u) => u.id == userId).firstOrNull;
  if (target == null) return null;
  final wasOwner = target.role == Role.owner.name && target.isActive && target.deletedAt == null;
  final staysOwner = newRole == Role.owner && newActive;
  if (!wasOwner || staysOwner) return null;
  final others = users.where((u) => u.id != userId && u.role == Role.owner.name && u.isActive && u.deletedAt == null);
  if (others.isEmpty) {
    return L.current.staffErrLastOwner;
  }
  return null;
}

/// Whether [actor] may assign [role] / edit a user that currently has [targetRole].
bool canAssignRole(Role actor, Role role) => role != Role.owner || actor == Role.owner;
bool canEditUserWithRole(Role actor, Role targetRole) => targetRole != Role.owner || actor == Role.owner;

/// Input for create/update.
class UserInput {
  UserInput({
    required this.name,
    required this.role,
    this.phone,
    this.pin,
    this.maxDiscountPercent = 0,
    this.salesPlan = 0,
    this.commissionPercent = 0,
  });

  final String name;
  final Role role;
  final String? phone;

  /// New PIN (required on create, optional on update = reset).
  final String? pin;
  final double maxDiscountPercent;
  final int salesPlan;
  final double commissionPercent;

  String? validate({required bool creating}) {
    if (name.trim().isEmpty) return L.current.commonEnterName;
    if (name.trim().length > 120) return L.current.staffErrNameTooLong;
    if (creating && (pin == null || pin!.isEmpty)) return L.current.staffErrSetPin;
    if (pin != null && pin!.isNotEmpty) {
      final e = PinHasher.validate(pin!);
      if (e != null) return e;
    }
    if (maxDiscountPercent < 0 || maxDiscountPercent > 100) {
      return L.current.staffErrMaxDiscountRange;
    }
    if (commissionPercent < 0 || commissionPercent > 100) return L.current.staffErrCommissionRange;
    if (salesPlan < 0) return L.current.staffErrPlanNegative;
    final p = phone?.trim() ?? '';
    if (p.isNotEmpty && !RegExp(r'^\+?[0-9\s\-()]{5,20}$').hasMatch(p)) {
      return L.current.staffErrPhoneFormat;
    }
    return null;
  }
}

class StaffService {
  StaffService(this.db) : auth = AuthService(db);
  final AppDatabase db;
  final AuthService auth;

  Future<List<User>> _allUsers() => (db.select(db.users)..where((u) => u.deletedAt.isNull())).get();

  Future<User> _get(String id) => (db.select(db.users)..where((u) => u.id.equals(id))).getSingle();

  Future<User> create(UserInput i, {required User actor}) async {
    final err = i.validate(creating: true);
    if (err != null) throw BusinessException(err);
    if (!canAssignRole(Role.parse(actor.role), i.role)) {
      throw BusinessException(L.current.staffErrOwnerRoleOnlyOwner);
    }
    // One transaction: the user never exists without plan/commission/limits.
    return db.transaction(() async {
      final u = await auth.createUser(
        name: i.name.trim(),
        role: i.role,
        pin: i.pin!,
        phone: _clean(i.phone),
        maxDiscountPercent: i.maxDiscountPercent,
        actorId: actor.id,
      );
      await (db.update(db.users)..where((t) => t.id.equals(u.id))).write(
        UsersCompanion(
          maxDiscountPercent: Value(i.maxDiscountPercent),
          salesPlan: Value(i.salesPlan),
          commissionPercent: Value(i.commissionPercent),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await db.markDirty('users', u.id);
      return _get(u.id);
    });
  }

  Future<User> update(String userId, UserInput i, {required User actor}) async {
    final err = i.validate(creating: false);
    if (err != null) throw BusinessException(err);
    final actorRole = Role.parse(actor.role);
    final before = await _get(userId);
    final beforeRole = Role.parse(before.role);
    if (!canEditUserWithRole(actorRole, beforeRole)) {
      throw BusinessException(L.current.staffErrOwnerEditOnlyOwner);
    }
    if (i.role != beforeRole && !canAssignRole(actorRole, i.role)) {
      throw BusinessException(L.current.staffErrOwnerRoleOnlyOwner);
    }
    final guard = lastOwnerGuard(await _allUsers(), userId: userId, newRole: i.role, newActive: before.isActive);
    if (guard != null) throw BusinessException(guard);
    // PIN reset and field changes are applied atomically: a rejected PIN
    // (already in use) leaves the user untouched.
    await db.transaction(() async {
      if (i.pin != null && i.pin!.isNotEmpty) {
        await auth.changePin(userId, i.pin!, actorId: actor.id);
      }
      await (db.update(db.users)..where((t) => t.id.equals(userId))).write(
        UsersCompanion(
          name: Value(i.name.trim()),
          phone: Value(_clean(i.phone)),
          role: Value(i.role.name),
          maxDiscountPercent: Value(i.maxDiscountPercent),
          salesPlan: Value(i.salesPlan),
          commissionPercent: Value(i.commissionPercent),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await db.markDirty('users', userId);
      final changes = <String>[
        if (before.name != i.name.trim()) 'имя: ${before.name} → ${i.name.trim()}', // l10n-ignore
        if ((before.phone ?? '') != (_clean(i.phone) ?? '')) 'телефон', // l10n-ignore
        if (before.maxDiscountPercent != i.maxDiscountPercent)
          'скидка: ${before.maxDiscountPercent}% → ${i.maxDiscountPercent}%', // l10n-ignore
        if (before.salesPlan != i.salesPlan) 'план: ${Money.format(before.salesPlan)} → ${Money.format(i.salesPlan)}', // l10n-ignore
        if (before.commissionPercent != i.commissionPercent)
          'комиссия: ${before.commissionPercent}% → ${i.commissionPercent}%', // l10n-ignore
      ];
      if (beforeRole != i.role) {
        await db.audit(
          'user.role',
          userId: actor.id,
          entity: 'user',
          entityId: userId,
          details: '${beforeRole.labelIn(L.of('ru'))} → ${i.role.labelIn(L.of('ru'))}',
        );
      }
      if (changes.isNotEmpty) {
        await db.audit('user.update', userId: actor.id, entity: 'user', entityId: userId, details: changes.join('; '));
      }
    });
    return _get(userId);
  }

  /// Soft (de)activation. Deactivation also ends the user's open work session.
  Future<void> setActive(String userId, bool active, {required User actor, String? newPin}) async {
    final user = await _get(userId);
    if (user.isActive == active) return;
    if (!active && userId == actor.id) {
      throw BusinessException(L.current.staffErrCannotDeactivateSelf);
    }
    if (!canEditUserWithRole(Role.parse(actor.role), Role.parse(user.role))) {
      throw BusinessException(L.current.staffErrOwnerEditOnlyOwner);
    }
    final all = await _allUsers();
    if (!active) {
      final guard = lastOwnerGuard(all, userId: userId, newRole: Role.parse(user.role), newActive: false);
      if (guard != null) throw BusinessException(guard);
    } else {
      // Another active user may have received the same PIN while this one
      // was inactive; salted hashes cannot be compared, so a new PIN is
      // required (uniqueness is enforced by AuthService.changePin).
      if (newPin == null || newPin.isEmpty) {
        throw BusinessException(L.current.staffErrActivateNeedsPin);
      }
    }
    final now = DateTime.now();
    await db.transaction(() async {
      if (active) await auth.changePin(userId, newPin!, actorId: actor.id);
      await (db.update(
        db.users,
      )..where((t) => t.id.equals(userId))).write(UsersCompanion(isActive: Value(active), updatedAt: Value(now)));
      await db.markDirty('users', userId);
      if (!active) {
        final open = await (db.select(
          db.workSessions,
        )..where((w) => w.userId.equals(userId) & w.endedAt.isNull() & w.deletedAt.isNull())).get();
        for (final w in open) {
          await (db.update(
            db.workSessions,
          )..where((t) => t.id.equals(w.id))).write(WorkSessionsCompanion(endedAt: Value(now), updatedAt: Value(now)));
          await db.markDirty('work_sessions', w.id);
        }
      }
      await db.audit(
        active ? 'user.activate' : 'user.deactivate',
        userId: actor.id,
        entity: 'user',
        entityId: userId,
        details: user.name,
      );
    });
  }

  static String? _clean(String? s) {
    final t = s?.trim() ?? '';
    return t.isEmpty ? null : t;
  }
}

// ------------------------------------------------------------ time clock

class WorkSpan {
  WorkSpan(this.start, this.end);
  final DateTime start;
  final DateTime end;
  Duration get duration => end.difference(start);
}

/// Duration of [s] that falls inside [from, to). Open sessions count up to [now].
Duration overlap(WorkSession s, DateTime from, DateTime to, {DateTime? now}) {
  final end = s.endedAt ?? now ?? DateTime.now();
  final a = s.startedAt.isAfter(from) ? s.startedAt : from;
  final b = end.isBefore(to) ? end : to;
  return b.isAfter(a) ? b.difference(a) : Duration.zero;
}

/// "1 ч 05 мин" in [loc] (default: the UI language).
String formatDuration(Duration d, [AppLocalizations? loc]) {
  final l = loc ?? L.current;
  final h = d.inHours, m = d.inMinutes % 60;
  if (h == 0) return l.staffDurationMin('$m');
  return l.staffDurationHm('$h', m.toString().padLeft(2, '0'));
}

class TimeClock {
  TimeClock(this.db);
  final AppDatabase db;

  Future<WorkSession?> openSession(String userId) =>
      (db.select(db.workSessions)
            ..where((w) => w.userId.equals(userId) & w.endedAt.isNull() & w.deletedAt.isNull())
            ..orderBy([(w) => OrderingTerm.desc(w.startedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<WorkSession> clockIn(String userId, {DateTime? at}) async {
    return db.transaction(() async {
      final open = await openSession(userId);
      if (open != null) {
        throw BusinessException(L.current.staffErrAlreadyClockedIn(_hm(open.startedAt)));
      }
      final id = newId();
      final t = at ?? DateTime.now();
      await db.into(db.workSessions).insert(WorkSessionsCompanion.insert(id: id, userId: userId, startedAt: t));
      await db.markDirty('work_sessions', id);
      await db.audit('time.clock_in', userId: userId, entity: 'work_session', entityId: id);
      return (db.select(db.workSessions)..where((w) => w.id.equals(id))).getSingle();
    });
  }

  Future<WorkSession> clockOut(String userId, {DateTime? at}) async {
    return db.transaction(() async {
      final open = await openSession(userId);
      if (open == null) throw BusinessException(L.current.staffErrClockInFirst);
      final t = at ?? DateTime.now();
      if (!t.isAfter(open.startedAt)) {
        throw BusinessException(L.current.staffErrEndBeforeStart);
      }
      await (db.update(db.workSessions)..where((w) => w.id.equals(open.id))).write(
        WorkSessionsCompanion(endedAt: Value(t), updatedAt: Value(DateTime.now())),
      );
      await db.markDirty('work_sessions', open.id);
      await db.audit(
        'time.clock_out',
        userId: userId,
        entity: 'work_session',
        entityId: open.id,
        details: formatDuration(t.difference(open.startedAt), L.of('ru')),
      );
      return (db.select(db.workSessions)..where((w) => w.id.equals(open.id))).getSingle();
    });
  }

  /// Manager adds ([id] == null) or edits a session.
  Future<void> save({
    String? id,
    required String userId,
    required DateTime start,
    DateTime? end,
    String? note,
    required String actorId,
    DateTime? now,
  }) async {
    final n = now ?? DateTime.now();
    if (start.isAfter(n)) throw BusinessException(L.current.staffErrStartInFuture);
    if (end != null) {
      if (!end.isAfter(start)) {
        throw BusinessException(L.current.staffErrEndBeforeStart);
      }
      if (end.isAfter(n)) throw BusinessException(L.current.staffErrEndInFuture);
      if (end.difference(start) > const Duration(hours: 24)) {
        throw BusinessException(L.current.staffErrTooLong);
      }
    }
    await db.transaction(() async {
      final others = await (db.select(
        db.workSessions,
      )..where((w) => w.userId.equals(userId) & w.deletedAt.isNull())).get();
      for (final o in others.where((o) => o.id != id)) {
        final oEnd = o.endedAt ?? n;
        final myEnd = end ?? n;
        if (start.isBefore(oEnd) && myEnd.isAfter(o.startedAt)) {
          throw BusinessException(
            L.current.staffErrOverlap(_dt(o.startedAt), o.endedAt == null ? L.current.staffNow : _dt(o.endedAt!)),
          );
        }
        if (end == null && o.endedAt == null) {
          throw BusinessException(L.current.staffErrOpenExists);
        }
      }
      final cleanNote = (note ?? '').trim().isEmpty ? null : note!.trim();
      if (id == null) {
        final nid = newId();
        await db
            .into(db.workSessions)
            .insert(
              WorkSessionsCompanion.insert(
                id: nid,
                userId: userId,
                startedAt: start,
                endedAt: Value(end),
                note: Value(cleanNote),
              ),
            );
        await db.markDirty('work_sessions', nid);
        await db.audit(
          'time.add',
          userId: actorId,
          entity: 'work_session',
          entityId: nid,
          details: '${_dt(start)} — ${end == null ? '…' : _dt(end)}',
        );
      } else {
        final before = await (db.select(db.workSessions)..where((w) => w.id.equals(id))).getSingle();
        await (db.update(db.workSessions)..where((w) => w.id.equals(id))).write(
          WorkSessionsCompanion(
            startedAt: Value(start),
            endedAt: Value(end),
            note: Value(cleanNote),
            updatedAt: Value(DateTime.now()),
          ),
        );
        await db.markDirty('work_sessions', id);
        await db.audit(
          'time.edit',
          userId: actorId,
          entity: 'work_session',
          entityId: id,
          details:
              'было ${_dt(before.startedAt)} — ' // l10n-ignore
              '${before.endedAt == null ? '…' : _dt(before.endedAt!)}; '
              'стало ${_dt(start)} — ${end == null ? '…' : _dt(end)}', // l10n-ignore
        );
      }
    });
  }

  Future<void> delete(String id, {required String actorId}) async {
    final now = DateTime.now();
    await db.transaction(() async {
      final before = await (db.select(db.workSessions)..where((w) => w.id.equals(id))).getSingle();
      await (db.update(
        db.workSessions,
      )..where((w) => w.id.equals(id))).write(WorkSessionsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await db.markDirty('work_sessions', id, op: 'delete');
      await db.audit(
        'time.delete',
        userId: actorId,
        entity: 'work_session',
        entityId: id,
        details: '${_dt(before.startedAt)} — ${before.endedAt == null ? '…' : _dt(before.endedAt!)}',
      );
    });
  }

  static String _hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  static String _dt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} ${_hm(d)}';
}

/// Default start/end for a manually added session: today 09:00–18:00, but
/// never in the future (end is clamped to [now], start to an hour before).
({DateTime start, DateTime end}) defaultManualSession(DateTime now) {
  final day = DateTime(now.year, now.month, now.day);
  var end = DateTime(day.year, day.month, day.day, 18);
  if (end.isAfter(now)) end = DateTime(now.year, now.month, now.day, now.hour, now.minute);
  var start = DateTime(day.year, day.month, day.day, 9);
  if (!start.isBefore(end)) start = end.subtract(const Duration(hours: 1));
  return (start: start, end: end);
}

// ------------------------------------------------------------ motivation

class MotivationRow {
  MotivationRow({required this.user, required this.grossRevenue, required this.refunds, required this.receipts});

  final User user;
  final int grossRevenue;
  final int refunds;
  final int receipts;

  int get netRevenue => grossRevenue - refunds;
  int get plan => user.salesPlan;
  double? get completion => plan <= 0 ? null : netRevenue / plan;

  /// Commission on net revenue; never negative (no claw-back below zero).
  int get commission {
    if (netRevenue <= 0) return 0;
    return Money.percent(netRevenue, user.commissionPercent);
  }

  int get averageCheck => receipts == 0 ? 0 : grossRevenue ~/ receipts;
}

/// Month boundaries [start, nextMonthStart).
(DateTime, DateTime) monthRange(DateTime month) =>
    (DateTime(month.year, month.month), DateTime(month.year, month.month + 1));

/// Sales credited to the seller (fallback: cashier) within [from, to),
/// excluding voided/parked receipts, minus refunds made within the period on
/// that seller's sales.
Future<List<MotivationRow>> computeMotivation(AppDatabase db, DateTime from, DateTime to) async {
  final sales = await db
      .customSelect(
        'SELECT COALESCE(seller_id, cashier_id) AS uid, COUNT(*) AS cnt, '
        'COALESCE(SUM(total), 0) AS revenue FROM sales '
        "WHERE status NOT IN ('voided', 'held') AND deleted_at IS NULL "
        'AND created_at >= ? AND created_at < ? GROUP BY uid',
        variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
        readsFrom: {db.sales},
      )
      .get();
  final refunds = await db
      .customSelect(
        'SELECT COALESCE(s.seller_id, s.cashier_id) AS uid, COALESCE(SUM(r.total), 0) AS refunded '
        'FROM returns r JOIN sales s ON s.id = r.sale_id '
        "WHERE s.status != 'voided' AND r.deleted_at IS NULL "
        'AND r.created_at >= ? AND r.created_at < ? GROUP BY uid',
        variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
        readsFrom: {db.returns, db.sales},
      )
      .get();
  final users = await (db.select(db.users)..where((u) => u.deletedAt.isNull())).get();
  final rev = <String, (int, int)>{};
  for (final r in sales) {
    final uid = r.readNullable<String>('uid');
    if (uid == null) continue;
    rev[uid] = (r.read<int>('revenue'), r.read<int>('cnt'));
  }
  final ref = <String, int>{};
  for (final r in refunds) {
    final uid = r.readNullable<String>('uid');
    if (uid == null) continue;
    ref[uid] = r.read<int>('refunded');
  }
  final rows = <MotivationRow>[];
  for (final u in users) {
    final has = rev.containsKey(u.id) || ref.containsKey(u.id);
    final sells = Role.parse(u.role).can(Perm.sell);
    if (!has && !(u.isActive && sells)) continue;
    rows.add(
      MotivationRow(user: u, grossRevenue: rev[u.id]?.$1 ?? 0, receipts: rev[u.id]?.$2 ?? 0, refunds: ref[u.id] ?? 0),
    );
  }
  rows.sort((a, b) {
    final c = b.netRevenue.compareTo(a.netRevenue);
    return c != 0 ? c : a.user.name.compareTo(b.user.name);
  });
  return rows;
}

// ------------------------------------------------------------ labels

String permLabel(Perm p, [AppLocalizations? loc]) {
  final l = loc ?? L.current;
  return switch (p) {
    Perm.sell => l.staffPermSell,
    Perm.applyDiscount => l.staffPermApplyDiscount,
    Perm.voidSale => l.staffPermVoidSale,
    Perm.refund => l.staffPermRefund,
    Perm.openCloseShift => l.staffPermOpenCloseShift,
    Perm.cashInOut => l.staffPermCashInOut,
    Perm.viewProducts => l.staffPermViewProducts,
    Perm.editProducts => l.staffPermEditProducts,
    Perm.editPrices => l.staffPermEditPrices,
    Perm.viewCost => l.staffPermViewCost,
    Perm.stockOps => l.staffPermStockOps,
    Perm.purchasing => l.staffPermPurchasing,
    Perm.viewCustomers => l.staffPermViewCustomers,
    Perm.editCustomers => l.staffPermEditCustomers,
    Perm.manageDebts => l.staffPermManageDebts,
    Perm.managePromotions => l.staffPermManagePromotions,
    Perm.viewReports => l.staffPermViewReports,
    Perm.viewAllShifts => l.staffPermViewAllShifts,
    Perm.manageStaff => l.staffPermManageStaff,
    Perm.manageSettings => l.staffPermManageSettings,
    Perm.viewAudit => l.staffPermViewAudit,
  };
}

Map<String, String> _auditLabels(AppLocalizations l) => {
  'auth.login': l.staffAuditAuthLogin,
  'auth.fail': l.staffAuditAuthFail,
  'auth.logout': l.staffAuditAuthLogout,
  'sale.discount': l.staffAuditSaleDiscount,
  'sale.return': l.staffAuditSaleReturn,
  'sale.void': l.staffAuditSaleVoid,
  'sale.create': l.staffAuditSaleCreate,
  'shift.open': l.staffAuditShiftOpen,
  'shift.close': l.staffAuditShiftClose,
  'cash.pay_in': l.staffAuditCashPayIn,
  'cash.pay_out': l.staffAuditCashPayOut,
  'cash.expense': l.staffAuditCashExpense,
  'cash.collection': l.staffAuditCashCollection,
  'stock.receive': l.staffAuditStockReceive,
  'stock.writeoff': l.staffAuditStockWriteoff,
  'stock.adjust': l.staffAuditStockAdjust,
  'stock.set': l.staffAuditStockSet,
  'user.create': l.staffAuditUserCreate,
  'user.update': l.staffAuditUserUpdate,
  'user.role': l.staffAuditUserRole,
  'user.pin_change': l.staffAuditUserPinChange,
  'user.activate': l.staffAuditUserActivate,
  'user.deactivate': l.staffAuditUserDeactivate,
  'product.price': l.staffAuditProductPrice,
  'debt.payment': l.staffAuditDebtPayment,
  'bonus.adjust': l.staffAuditBonusAdjust,
  'inventory.complete': l.staffAuditInventoryComplete,
  'discount.override': l.staffAuditDiscountOverride,
  'discount.approve': l.staffAuditDiscountApprove,
  'auth.approve_fail': l.staffAuditAuthApproveFail,
  'backup.auto': l.staffAuditBackupAuto,
  'time.clock_in': l.staffAuditTimeClockIn,
  'time.clock_out': l.staffAuditTimeClockOut,
  'time.add': l.staffAuditTimeAdd,
  'time.edit': l.staffAuditTimeEdit,
  'time.delete': l.staffAuditTimeDelete,
  'stock.receipt': l.staffAuditStockReceipt,
  'product.create': l.staffAuditProductCreate,
  'product.update': l.staffAuditProductUpdate,
  'product.delete': l.staffAuditProductDelete,
  'product.cost': l.staffAuditProductCost,
  'product.import': l.staffAuditProductImport,
  'product.bulk_price': l.staffAuditProductBulkPrice,
  'product.bulk_category': l.staffAuditProductBulkCategory,
  'category.delete': l.staffAuditCategoryDelete,
  'customer.create': l.staffAuditCustomerCreate,
  'customer.delete': l.staffAuditCustomerDelete,
  'customer.terms': l.staffAuditCustomerTerms,
  'supplier.payment': l.staffAuditSupplierPayment,
  'supplier.delete': l.staffAuditSupplierDelete,
  'po.ordered': l.staffAuditPoOrdered,
  'po.receive': l.staffAuditPoReceive,
  'promotion.create': l.staffAuditPromotionCreate,
  'promotion.update': l.staffAuditPromotionUpdate,
  'promotion.delete': l.staffAuditPromotionDelete,
  'gift_card.issue': l.staffAuditGiftCardIssue,
  'warranty.create': l.staffAuditWarrantyCreate,
  'warranty.status': l.staffAuditWarrantyStatus,
  'inventory.create': l.staffAuditInventoryCreate,
  'inventory.cancel': l.staffAuditInventoryCancel,
  'pos.price_edit': l.staffAuditPosPriceEdit,
  'pos.cart_clear': l.staffAuditPosCartClear,
  'settings.change': l.staffAuditSettingsChange,
  'register.delete': l.staffAuditRegisterDelete,
  'register.bind_device': l.staffAuditRegisterBindDevice,
  'data.export': l.staffAuditDataExport,
  'backup.create': l.staffAuditBackupCreate,
  'backup.delete': l.staffAuditBackupDelete,
  'backup.restore_scheduled': l.staffAuditBackupRestoreScheduled,
  'backup.restore_cancelled': l.staffAuditBackupRestoreCancelled,
  'backup.restore_applied': l.staffAuditBackupRestoreApplied,
};

/// Action groups for the journal filter (prefix -> label).
Map<String, String> auditGroupsOf(AppLocalizations l) => {
  'auth.': l.staffGroupAuth,
  'sale.': l.staffGroupSale,
  'shift.': l.staffGroupShift,
  'cash.': l.staffGroupCash,
  'stock.': l.staffGroupStock,
  'inventory.': l.staffGroupInventory,
  'user.': l.staffGroupUser,
  'time.': l.staffGroupTime,
  'product.': l.staffGroupProduct,
  'debt.': l.staffGroupDebt,
  'bonus.': l.staffGroupBonus,
  'discount.': l.staffGroupDiscount,
  'pos.': l.staffGroupPos,
  'customer.': l.staffGroupCustomer,
  'supplier.': l.staffGroupSupplier,
  'po.': l.staffGroupPo,
  'promotion.': l.staffGroupPromotion,
  'settings.': l.staffGroupSettings,
  'backup.': l.staffGroupBackup,
};

/// [auditGroupsOf] in the current UI language.
Map<String, String> get auditGroups => auditGroupsOf(L.current);

String auditLabel(String action, [AppLocalizations? loc]) {
  final l = loc ?? L.current;
  final label = _auditLabels(l)[action];
  if (label != null) return label;
  for (final e in auditGroupsOf(l).entries) {
    if (action.startsWith(e.key)) return '${e.value}: ${action.substring(e.key.length)}';
  }
  return action;
}
/// Sensitive actions highlighted in the journal.
bool auditIsWarning(String action) => const {
  'auth.fail',
  'sale.void',
  'discount.override',
  'discount.approve',
  'auth.approve_fail',
  'user.role',
  'user.deactivate',
  'time.edit',
  'time.delete',
  'stock.adjust',
  'stock.writeoff',
  'pos.price_edit',
  'product.bulk_price',
  'backup.restore_applied',
}.contains(action);

// ------------------------------------------------------------ audit details

const _detailKeys = {'discount', 'total', 'opening', 'expected', 'counted', 'manual', 'method', 'promos'};

Map<String, String> _detailLabels(AppLocalizations l) => {
  'discount': l.staffDetailDiscount,
  'total': l.staffDetailTotal,
  'opening': l.staffDetailOpening,
  'expected': l.staffDetailExpected,
  'counted': l.staffDetailCounted,
  'manual': l.staffDetailManual,
  'method': l.staffDetailMethod,
};

const _moneyKeys = {'discount', 'total', 'opening', 'expected', 'counted'};

Map<String, String> _methodLabels(AppLocalizations l) => {
  'cash': l.staffMethodCash,
  'card': l.staffMethodCard,
  'debt': l.staffMethodDebt,
  'bonus': l.staffMethodBonus,
  'transfer': l.staffMethodTransfer,
  'gift_card': l.staffMethodGiftCard,
};

/// Turns the raw machine details of an audit entry ("discount=2850;
/// promos=…", "return #3 total=18000 method=cash; Брак") into readable
/// text in the UI language ("скидка 2 850 сум · акции: …"). Unknown text is kept as is.
String auditDetailsText(String action, String? details, [AppLocalizations? loc]) {
  final l = loc ?? L.current;
  final labels = _detailLabels(l);
  final methods = _methodLabels(l);
  final raw = (details ?? '').trim();
  if (raw.isEmpty) return '';
  final amountFirst = action.startsWith('cash.') || action == 'debt.payment';
  final parts = <String>[];
  for (final (i, part) in raw.split(';').indexed) {
    final p = part.trim();
    if (p.isEmpty) continue;
    final words = <String>[];
    final tokens = p.split(' ');
    for (var j = 0; j < tokens.length; j++) {
      final tok = tokens[j];
      final eq = tok.indexOf('=');
      if (eq > 0 && _detailKeys.contains(tok.substring(0, eq))) {
        final key = tok.substring(0, eq);
        // The value of "promos=" may contain spaces: take the rest.
        final value = key == 'promos'
            ? [tok.substring(eq + 1), ...tokens.skip(j + 1)].join(' ')
            : tok.substring(eq + 1);
        final shown = switch (key) {
          _ when _moneyKeys.contains(key) && int.tryParse(value) != null => Money.format(int.parse(value)),
          'method' => methods[value] ?? value,
          _ => value,
        };
        if (shown.isNotEmpty) words.add(key == 'promos' ? l.staffDetailPromos(shown) : '${labels[key]} $shown');
        if (key == 'promos') break;
      } else if (tok == 'return' && j + 1 < tokens.length && tokens[j + 1].startsWith('#')) {
        words.add(l.staffDetailReturnNo(tokens[++j].substring(1)));
      } else if (i == 0 && j == 0 && amountFirst && int.tryParse(tok) != null) {
        words.add(Money.format(int.parse(tok)));
      } else if (action == 'debt.payment' && methods.containsKey(tok)) {
        words.add(methods[tok]!);
      } else if (action == 'user.create' && i == 0 && j == 0 && Role.values.any((r) => r.name == tok)) {
        words.add(Role.values.byName(tok).labelIn(l));
      } else {
        words.add(tok);
      }
    }
    if (words.isNotEmpty) parts.add(words.join(' '));
  }
  return parts.join(' · ');
}
