import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../l10n/l10n.dart';

/// PIN hashing: PBKDF-like iterated SHA-256 with per-user salt.
/// PINs are short, so this mainly protects against casual DB inspection;
/// online brute force is limited by lockout in AuthService.
class PinHasher {
  PinHasher._();

  static const iterations = 20000;

  static String newSalt() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  static String hash(String pin, String salt) {
    var bytes = utf8.encode('$salt:$pin');
    var digest = sha256.convert(bytes);
    for (var i = 0; i < iterations; i++) {
      digest = sha256.convert([...digest.bytes, ...bytes]);
    }
    return digest.toString();
  }

  static bool verify(String pin, String salt, String expectedHash) {
    final h = hash(pin, salt);
    if (h.length != expectedHash.length) return false;
    var diff = 0;
    for (var i = 0; i < h.length; i++) {
      diff |= h.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return diff == 0;
  }

  static String? validate(String pin) {
    if (!RegExp(r'^\d{4,8}$').hasMatch(pin)) return L.current.corePinFormat;
    if (RegExp(r'^(\d)\1+$').hasMatch(pin)) return L.current.corePinTooSimple;
    if ('0123456789'.contains(pin) || '9876543210'.contains(pin)) {
      return L.current.corePinTooSimple;
    }
    return null;
  }
}
