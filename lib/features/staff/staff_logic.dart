// Staff module logic: user management rules, time clock, motivation math,
// permission and audit labels. UI-free so it can be unit tested.
import 'package:drift/drift.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/security/pin.dart';
import '../../domain/errors.dart';
import '../../domain/services/auth_service.dart';

// ------------------------------------------------------------ owner guard

/// Returns an error if changing [userId] to ([newRole], [newActive]) would
/// leave the store without an active owner.
String? lastOwnerGuard(
  List<User> users, {
  required String userId,
  required Role newRole,
  required bool newActive,
}) {
  final target = users.where((u) => u.id == userId).firstOrNull;
  if (target == null) return null;
  final wasOwner = target.role == Role.owner.name && target.isActive && target.deletedAt == null;
  final staysOwner = newRole == Role.owner && newActive;
  if (!wasOwner || staysOwner) return null;
  final others = users.where(
    (u) => u.id != userId && u.role == Role.owner.name && u.isActive && u.deletedAt == null,
  );
  if (others.isEmpty) {
    return 'Это единственный активный владелец. Сначала назначьте другого владельца';
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
    if (name.trim().isEmpty) return 'Введите имя';
    if (name.trim().length > 120) return 'Имя слишком длинное';
    if (creating && (pin == null || pin!.isEmpty)) return 'Задайте PIN';
    if (pin != null && pin!.isNotEmpty) {
      final e = PinHasher.validate(pin!);
      if (e != null) return e;
    }
    if (maxDiscountPercent < 0 || maxDiscountPercent > 100) {
      return 'Макс. скидка — от 0 до 100%';
    }
    if (commissionPercent < 0 || commissionPercent > 100) return 'Комиссия — от 0 до 100%';
    if (salesPlan < 0) return 'План не может быть отрицательным';
    final p = phone?.trim() ?? '';
    if (p.isNotEmpty && !RegExp(r'^\+?[0-9\s\-()]{5,20}$').hasMatch(p)) {
      return 'Неверный формат телефона';
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
      throw BusinessException('Назначить роль «Владелец» может только владелец');
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
      throw BusinessException('Изменять данные владельца может только владелец');
    }
    if (i.role != beforeRole && !canAssignRole(actorRole, i.role)) {
      throw BusinessException('Назначить роль «Владелец» может только владелец');
    }
    final guard = lastOwnerGuard(
      await _allUsers(),
      userId: userId,
      newRole: i.role,
      newActive: before.isActive,
    );
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
        if (before.name != i.name.trim()) 'имя: ${before.name} → ${i.name.trim()}',
        if ((before.phone ?? '') != (_clean(i.phone) ?? '')) 'телефон',
        if (before.maxDiscountPercent != i.maxDiscountPercent)
          'скидка: ${before.maxDiscountPercent}% → ${i.maxDiscountPercent}%',
        if (before.salesPlan != i.salesPlan)
          'план: ${Money.format(before.salesPlan)} → ${Money.format(i.salesPlan)}',
        if (before.commissionPercent != i.commissionPercent)
          'комиссия: ${before.commissionPercent}% → ${i.commissionPercent}%',
      ];
      if (beforeRole != i.role) {
        await db.audit(
          'user.role',
          userId: actor.id,
          entity: 'user',
          entityId: userId,
          details: '${beforeRole.label} → ${i.role.label}',
        );
      }
      if (changes.isNotEmpty) {
        await db.audit(
          'user.update',
          userId: actor.id,
          entity: 'user',
          entityId: userId,
          details: changes.join('; '),
        );
      }
    });
    return _get(userId);
  }

  /// Soft (de)activation. Deactivation also ends the user's open work session.
  Future<void> setActive(String userId, bool active, {required User actor, String? newPin}) async {
    final user = await _get(userId);
    if (user.isActive == active) return;
    if (!active && userId == actor.id) {
      throw BusinessException('Нельзя деактивировать собственную учётную запись');
    }
    if (!canEditUserWithRole(Role.parse(actor.role), Role.parse(user.role))) {
      throw BusinessException('Изменять данные владельца может только владелец');
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
        throw BusinessException('Для активации задайте сотруднику новый PIN');
      }
    }
    final now = DateTime.now();
    await db.transaction(() async {
      if (active) await auth.changePin(userId, newPin!, actorId: actor.id);
      await (db.update(db.users)..where((t) => t.id.equals(userId))).write(
        UsersCompanion(isActive: Value(active), updatedAt: Value(now)),
      );
      await db.markDirty('users', userId);
      if (!active) {
        final open = await (db.select(
          db.workSessions,
        )..where((w) => w.userId.equals(userId) & w.endedAt.isNull() & w.deletedAt.isNull())).get();
        for (final w in open) {
          await (db.update(db.workSessions)..where((t) => t.id.equals(w.id))).write(
            WorkSessionsCompanion(endedAt: Value(now), updatedAt: Value(now)),
          );
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

String formatDuration(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60;
  if (h == 0) return '$m мин';
  return '$h ч ${m.toString().padLeft(2, '0')} мин';
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
        throw BusinessException('Приход уже отмечен в ${_hm(open.startedAt)}');
      }
      final id = newId();
      final t = at ?? DateTime.now();
      await db
          .into(db.workSessions)
          .insert(WorkSessionsCompanion.insert(id: id, userId: userId, startedAt: t));
      await db.markDirty('work_sessions', id);
      await db.audit('time.clock_in', userId: userId, entity: 'work_session', entityId: id);
      return (db.select(db.workSessions)..where((w) => w.id.equals(id))).getSingle();
    });
  }

  Future<WorkSession> clockOut(String userId, {DateTime? at}) async {
    return db.transaction(() async {
      final open = await openSession(userId);
      if (open == null) throw BusinessException('Сначала отметьте приход');
      final t = at ?? DateTime.now();
      if (!t.isAfter(open.startedAt)) {
        throw BusinessException('Время ухода должно быть позже времени прихода');
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
        details: formatDuration(t.difference(open.startedAt)),
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
    if (start.isAfter(n)) throw BusinessException('Время прихода не может быть в будущем');
    if (end != null) {
      if (!end.isAfter(start)) {
        throw BusinessException('Время ухода должно быть позже времени прихода');
      }
      if (end.isAfter(n)) throw BusinessException('Время ухода не может быть в будущем');
      if (end.difference(start) > const Duration(hours: 24)) {
        throw BusinessException('Смена не может длиться больше 24 часов');
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
            'Пересекается с другой записью '
            '(${_dt(o.startedAt)} — ${o.endedAt == null ? 'сейчас' : _dt(o.endedAt!)})',
          );
        }
        if (end == null && o.endedAt == null) {
          throw BusinessException('У сотрудника уже есть незавершённая запись');
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
              'было ${_dt(before.startedAt)} — '
              '${before.endedAt == null ? '…' : _dt(before.endedAt!)}; '
              'стало ${_dt(start)} — ${end == null ? '…' : _dt(end)}',
        );
      }
    });
  }

  Future<void> delete(String id, {required String actorId}) async {
    final now = DateTime.now();
    await db.transaction(() async {
      final before = await (db.select(db.workSessions)..where((w) => w.id.equals(id))).getSingle();
      await (db.update(db.workSessions)..where((w) => w.id.equals(id))).write(
        WorkSessionsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
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

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
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
  MotivationRow({
    required this.user,
    required this.grossRevenue,
    required this.refunds,
    required this.receipts,
  });

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
      MotivationRow(
        user: u,
        grossRevenue: rev[u.id]?.$1 ?? 0,
        receipts: rev[u.id]?.$2 ?? 0,
        refunds: ref[u.id] ?? 0,
      ),
    );
  }
  rows.sort((a, b) {
    final c = b.netRevenue.compareTo(a.netRevenue);
    return c != 0 ? c : a.user.name.compareTo(b.user.name);
  });
  return rows;
}

// ------------------------------------------------------------ labels

String permLabel(Perm p) => switch (p) {
  Perm.sell => 'Продажа (касса)',
  Perm.applyDiscount => 'Ручные скидки',
  Perm.voidSale => 'Аннулирование чеков',
  Perm.refund => 'Возвраты',
  Perm.openCloseShift => 'Открытие/закрытие смены',
  Perm.cashInOut => 'Внесения и выплаты',
  Perm.viewProducts => 'Просмотр товаров',
  Perm.editProducts => 'Редактирование товаров',
  Perm.editPrices => 'Изменение цен',
  Perm.viewCost => 'Себестоимость и прибыль',
  Perm.stockOps => 'Складские операции',
  Perm.purchasing => 'Закупки',
  Perm.viewCustomers => 'Просмотр клиентов',
  Perm.editCustomers => 'Редактирование клиентов',
  Perm.manageDebts => 'Долги клиентов',
  Perm.managePromotions => 'Акции и маркетинг',
  Perm.viewReports => 'Отчёты',
  Perm.viewAllShifts => 'Все смены',
  Perm.manageStaff => 'Управление сотрудниками',
  Perm.manageSettings => 'Настройки',
  Perm.viewAudit => 'Журнал действий',
};

const _auditLabels = <String, String>{
  'auth.login': 'Вход в систему',
  'auth.fail': 'Неверный PIN',
  'auth.logout': 'Выход из системы',
  'sale.discount': 'Скидка в чеке',
  'sale.return': 'Возврат',
  'sale.void': 'Аннулирование чека',
  'sale.create': 'Продажа',
  'shift.open': 'Открытие смены',
  'shift.close': 'Закрытие смены',
  'cash.pay_in': 'Внесение в кассу',
  'cash.pay_out': 'Выплата из кассы',
  'cash.expense': 'Расход из кассы',
  'cash.collection': 'Инкассация',
  'stock.receive': 'Приход товара',
  'stock.writeoff': 'Списание товара',
  'stock.adjust': 'Корректировка остатка',
  'stock.set': 'Установка остатка',
  'user.create': 'Создан сотрудник',
  'user.update': 'Изменены данные сотрудника',
  'user.role': 'Изменена роль сотрудника',
  'user.pin_change': 'Смена PIN',
  'user.activate': 'Сотрудник активирован',
  'user.deactivate': 'Сотрудник деактивирован',
  'product.price': 'Изменение цены',
  'debt.payment': 'Погашение долга',
  'bonus.adjust': 'Корректировка бонусов',
  'inventory.complete': 'Инвентаризация проведена',
  'discount.override': 'Скидка сверх лимита',
  'discount.approve': 'Скидка подтверждена менеджером',
  'auth.approve_fail': 'Неверный PIN подтверждения',
  'backup.auto': 'Автоматическая резервная копия',
  'time.clock_in': 'Приход на работу',
  'time.clock_out': 'Уход с работы',
  'time.add': 'Добавлена запись рабочего времени',
  'time.edit': 'Изменена запись рабочего времени',
  'time.delete': 'Удалена запись рабочего времени',
  'stock.receipt': 'Приход товара',
  'product.create': 'Создан товар',
  'product.update': 'Изменён товар',
  'product.delete': 'Удалён товар',
  'product.cost': 'Изменение себестоимости',
  'product.import': 'Импорт товаров',
  'product.bulk_price': 'Массовое изменение цен',
  'product.bulk_category': 'Массовая смена категории',
  'category.delete': 'Удалена категория',
  'customer.create': 'Создан клиент',
  'customer.delete': 'Удалён клиент',
  'customer.terms': 'Изменены условия клиента',
  'supplier.payment': 'Оплата поставщику',
  'supplier.delete': 'Удалён поставщик',
  'po.ordered': 'Заказ поставщику отправлен',
  'po.receive': 'Приёмка заказа поставщика',
  'promotion.create': 'Создана акция',
  'promotion.update': 'Изменена акция',
  'promotion.delete': 'Удалена акция',
  'gift_card.issue': 'Выпущен подарочный сертификат',
  'warranty.create': 'Гарантийное обращение',
  'warranty.status': 'Статус гарантийного обращения',
  'inventory.create': 'Начата инвентаризация',
  'inventory.cancel': 'Инвентаризация отменена',
  'pos.price_edit': 'Изменение цены в чеке',
  'pos.cart_clear': 'Очистка чека',
  'settings.change': 'Изменены настройки',
  'register.delete': 'Удалена касса',
  'register.bind_device': 'Привязка устройства к кассе',
  'data.export': 'Экспорт данных',
  'backup.create': 'Создана резервная копия',
  'backup.delete': 'Удалена резервная копия',
  'backup.restore_scheduled': 'Запланировано восстановление',
  'backup.restore_cancelled': 'Восстановление отменено',
  'backup.restore_applied': 'Данные восстановлены из копии',
};

const auditGroups = <String, String>{
  'auth.': 'Вход',
  'sale.': 'Продажи',
  'shift.': 'Смены',
  'cash.': 'Касса',
  'stock.': 'Склад',
  'inventory.': 'Инвентаризация',
  'user.': 'Сотрудники',
  'time.': 'Рабочее время',
  'product.': 'Товары',
  'debt.': 'Долги',
  'bonus.': 'Бонусы',
  'discount.': 'Скидки',
  'pos.': 'Касса (чек)',
  'customer.': 'Клиенты',
  'supplier.': 'Поставщики',
  'po.': 'Закупки',
  'promotion.': 'Акции',
  'settings.': 'Настройки',
  'backup.': 'Резервные копии',
};

String auditLabel(String action) {
  final l = _auditLabels[action];
  if (l != null) return l;
  for (final e in auditGroups.entries) {
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
