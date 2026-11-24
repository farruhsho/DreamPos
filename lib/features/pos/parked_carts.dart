// Parked (held) receipts: kept in memory and mirrored to shared_preferences
// so that a crash or restart of the till never loses a customer's basket.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cart_controller.dart';

class ParkedCart {
  const ParkedCart({
    required this.id,
    required this.createdAt,
    required this.cart,
    this.note,
    this.cashierName,
  });

  final String id;
  final DateTime createdAt;
  final CartState cart;
  final String? note;
  final String? cashierName;

  int get grossTotal => cart.grossTotal;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'note': note,
        'cashierName': cashierName,
        'cart': cart.toJson(),
      };

  static ParkedCart fromJson(Map<String, dynamic> j) => ParkedCart(
        id: j['id'] as String,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        note: j['note'] as String?,
        cashierName: j['cashierName'] as String?,
        cart: CartState.fromJson(Map<String, dynamic>.from(j['cart'] as Map)),
      );
}

String encodeParked(List<ParkedCart> list) => jsonEncode([for (final p in list) p.toJson()]);

/// Tolerant decoder: corrupted entries are skipped instead of crashing the till.
List<ParkedCart> decodeParked(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final data = jsonDecode(raw);
    if (data is! List) return [];
    final out = <ParkedCart>[];
    for (final e in data) {
      try {
        out.add(ParkedCart.fromJson(Map<String, dynamic>.from(e as Map)));
      } catch (_) {
        // skip broken entry
      }
    }
    return out;
  } catch (_) {
    return [];
  }
}

class ParkedCartsController extends AsyncNotifier<List<ParkedCart>> {
  static const prefsKey = 'pos.parked_carts.v1';

  @override
  Future<List<ParkedCart>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return decodeParked(prefs.getString(prefsKey));
  }

  Future<void> _save(List<ParkedCart> list) async {
    state = AsyncData(list);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, encodeParked(list));
  }

  Future<List<ParkedCart>> _current() async => state.value ?? await future;

  Future<ParkedCart> park(CartState cart, {String? note, String? cashierName}) async {
    final p = ParkedCart(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      cart: cart.copyWith(selectedKey: null),
      note: (note ?? '').trim().isEmpty ? null : note!.trim(),
      cashierName: cashierName,
    );
    await _save([...await _current(), p]);
    return p;
  }

  /// Removes and returns the parked cart (null if it is already gone —
  /// e.g. restored on another window).
  Future<ParkedCart?> take(String id) async {
    final list = await _current();
    ParkedCart? found;
    for (final p in list) {
      if (p.id == id) found = p;
    }
    if (found == null) return null;
    await _save([for (final p in list) if (p.id != id) p]);
    return found;
  }

  Future<void> remove(String id) async => take(id);
}

final parkedCartsProvider =
    AsyncNotifierProvider<ParkedCartsController, List<ParkedCart>>(ParkedCartsController.new);
