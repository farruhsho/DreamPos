import 'package:drift/drift.dart';

import '../../core/db/database.dart';
import '../../core/permissions.dart';
import '../../core/security/pin.dart';
import '../errors.dart';

class AuthService {
  AuthService(this.db);
  final AppDatabase db;

  static const maxAttempts = 5;
  static const lockMinutes = 5;

  Future<bool> hasUsers() async {
    final c = await (db.selectOnly(db.users)..addColumns([db.users.id.count()])).getSingle();
    return (c.read(db.users.id.count()) ?? 0) > 0;
  }

  Future<User> createUser({
    required String name,
    required Role role,
    required String pin,
    String? phone,
    double maxDiscountPercent = 0,
    String? actorId,
  }) async {
    final err = PinHasher.validate(pin);
    if (err != null) throw BusinessException(err);
    if (name.trim().isEmpty) throw BusinessException('Введите имя');
    return db.transaction(() async {
      final all = await (db.select(db.users)..where((u) => u.deletedAt.isNull() & u.isActive.equals(true))).get();
      for (final u in all) {
        if (PinHasher.verify(pin, u.pinSalt, u.pinHash)) {
          throw BusinessException('Этот PIN уже используется другим сотрудником');
        }
      }
      final salt = PinHasher.newSalt();
      final id = newId();
      await db.into(db.users).insert(UsersCompanion.insert(
            id: id,
            name: name.trim(),
            phone: Value(phone),
            role: role.name,
            pinHash: PinHasher.hash(pin, salt),
            pinSalt: salt,
            maxDiscountPercent: Value(
                role == Role.owner || role == Role.admin ? 100 : maxDiscountPercent),
          ));
      await db.audit('user.create', userId: actorId, entity: 'user', entityId: id,
          details: '${role.name} $name');
      return (db.select(db.users)..where((u) => u.id.equals(id))).getSingle();
    });
  }

  Future<void> changePin(String userId, String newPin, {String? actorId}) async {
    final err = PinHasher.validate(newPin);
    if (err != null) throw BusinessException(err);
    final others = await (db.select(db.users)
          ..where((u) => u.id.isNotValue(userId) & u.deletedAt.isNull() & u.isActive.equals(true)))
        .get();
    for (final u in others) {
      if (PinHasher.verify(newPin, u.pinSalt, u.pinHash)) {
        throw BusinessException('Этот PIN уже используется другим сотрудником');
      }
    }
    final salt = PinHasher.newSalt();
    await (db.update(db.users)..where((u) => u.id.equals(userId))).write(UsersCompanion(
        pinSalt: Value(salt),
        pinHash: Value(PinHasher.hash(newPin, salt)),
        failedPinAttempts: const Value(0),
        lockedUntil: const Value(null),
        updatedAt: Value(DateTime.now())));
    await db.audit('user.pin_change', userId: actorId ?? userId, entity: 'user', entityId: userId);
  }

  /// PIN-only login (fast cashier switching). PINs are unique per active
  /// user, so the PIN identifies the user.
  Future<User> loginWithPin(String pin) async {
    final now = DateTime.now();
    if (await isThrottled()) {
      throw BusinessException('Слишком много неверных попыток. Подождите $lockMinutes минут',
          code: 'throttle');
    }
    final users = await (db.select(db.users)
          ..where((u) => u.deletedAt.isNull() & u.isActive.equals(true)))
        .get();
    for (final u in users) {
      if (PinHasher.verify(pin, u.pinSalt, u.pinHash)) {
        if (u.lockedUntil != null && u.lockedUntil!.isAfter(now)) {
          throw BusinessException('Учётная запись временно заблокирована. Попробуйте позже');
        }
        await (db.update(db.users)..where((t) => t.id.equals(u.id))).write(UsersCompanion(
            lastLoginAt: Value(now),
            failedPinAttempts: const Value(0),
            lockedUntil: const Value(null)));
        await db.audit('auth.login', userId: u.id);
        return u;
      }
    }
    // global throttle: count recent failures in audit
    await db.audit('auth.fail');
    final recent = await (db.select(db.auditLog)
          ..where((a) => a.action.equals('auth.fail') &
              a.at.isBiggerThanValue(now.subtract(const Duration(minutes: lockMinutes)))))
        .get();
    if (recent.length >= maxAttempts * 2) {
      throw BusinessException('Слишком много неверных попыток. Подождите $lockMinutes минут',
          code: 'throttle');
    }
    throw BusinessException('Неверный PIN', code: 'bad_pin');
  }

  Future<bool> isThrottled() async {
    final now = DateTime.now();
    final recent = await (db.select(db.auditLog)
          ..where((a) => a.action.equals('auth.fail') &
              a.at.isBiggerThanValue(now.subtract(const Duration(minutes: lockMinutes)))))
        .get();
    return recent.length >= maxAttempts * 2;
  }
}
