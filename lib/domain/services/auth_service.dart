import 'package:drift/drift.dart';

import '../../l10n/l10n.dart';
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
    int salesPlan = 0,
    double commissionPercent = 0,
    String? actorId,
  }) async {
    final err = PinHasher.validate(pin);
    if (err != null) throw BusinessException(err);
    if (name.trim().isEmpty) throw BusinessException(L.current.commonEnterName);
    return db.transaction(() async {
      final all = await (db.select(db.users)..where((u) => u.deletedAt.isNull() & u.isActive.equals(true))).get();
      for (final u in all) {
        if (PinHasher.verify(pin, u.pinSalt, u.pinHash)) {
          throw BusinessException(L.current.errPinInUse);
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
            salesPlan: Value(salesPlan),
            commissionPercent: Value(commissionPercent),
          ));
      await db.markDirty('users', id);
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
        throw BusinessException(L.current.errPinInUse);
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
  /// user, so the PIN identifies the user. With several registers (D-025)
  /// two users can end up with one PIN (created / changed on two registers
  /// before they synced; salted hashes cannot be compared). Such a PIN is
  /// refused on every register instead of logging in whichever user comes
  /// first in this database (sales would be credited to different people
  /// depending on the till): someone else changes one of the PINs.
  Future<User> loginWithPin(String pin) async {
    final now = DateTime.now();
    if (await isThrottled()) {
      throw BusinessException(L.current.errTooManyAttempts('$lockMinutes'),
          code: 'throttle');
    }
    final users = await (db.select(db.users)
          ..where((u) => u.deletedAt.isNull() & u.isActive.equals(true)))
        .get();
    final matches = [
      for (final u in users)
        if (PinHasher.verify(pin, u.pinSalt, u.pinHash)) u,
    ];
    if (matches.length > 1) {
      await db.audit('auth.pin_conflict', details: matches.map((u) => u.name).join(', '));
      throw BusinessException(L.current.errPinAmbiguous, code: 'pin_conflict');
    }
    if (matches.isNotEmpty) {
      final u = matches.single;
      if (u.lockedUntil != null && u.lockedUntil!.isAfter(now)) {
        throw BusinessException(L.current.errAccountLockedTryLater);
      }
      // Bookkeeping only: a stat part for sync (`statColumns`, schema v7).
      await (db.update(db.users)..where((t) => t.id.equals(u.id))).write(UsersCompanion(
          lastLoginAt: Value(now),
          failedPinAttempts: const Value(0),
          lockedUntil: const Value(null)));
      await db.audit('auth.login', userId: u.id);
      return u;
    }
    // global throttle: count recent failures in audit
    await db.audit('auth.fail');
    final recent = await (db.select(db.auditLog)
          ..where((a) => a.action.equals('auth.fail') &
              a.at.isBiggerThanValue(now.subtract(const Duration(minutes: lockMinutes)))))
        .get();
    if (recent.length >= maxAttempts * 2) {
      throw BusinessException(L.current.errTooManyAttempts('$lockMinutes'),
          code: 'throttle');
    }
    throw BusinessException(L.current.errWrongPin, code: 'bad_pin');
  }

  /// Verifies a supervisor PIN for an approval (discount over limit, etc.)
  /// WITHOUT logging in: no lastLoginAt update, no 'auth.login'. Failures are
  /// audited as 'auth.approve_fail' and throttled separately from logins.
  Future<User> verifyApprover(String pin) async {
    final now = DateTime.now();
    final since = now.subtract(const Duration(minutes: lockMinutes));
    final fails = await (db.select(db.auditLog)
          ..where((a) => a.action.equals('auth.approve_fail') & a.at.isBiggerThanValue(since)))
        .get();
    if (fails.length >= maxAttempts) {
      throw BusinessException(L.current.errTooManyAttempts('$lockMinutes'),
          code: 'throttle');
    }
    final users = await (db.select(db.users)
          ..where((u) => u.deletedAt.isNull() & u.isActive.equals(true)))
        .get();
    for (final u in users) {
      if (PinHasher.verify(pin, u.pinSalt, u.pinHash)) {
        if (u.lockedUntil != null && u.lockedUntil!.isAfter(now)) {
          throw BusinessException(L.current.errAccountLocked);
        }
        return u;
      }
    }
    await db.audit('auth.approve_fail');
    throw BusinessException(L.current.errWrongPin, code: 'bad_pin');
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
