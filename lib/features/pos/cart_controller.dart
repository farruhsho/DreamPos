// Cart state for the POS screen. Kept free of Flutter widgets so that it is
// easy to unit-test: all business rules about quantities, merging, discounts
// and parking serialisation live here.
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../domain/services/sale_service.dart';

/// Largest quantity a single line may hold (protects against typos like
/// scanning a barcode into the qty field).
const maxLineQty = 100000.0;

class CartLine {
  const CartLine({
    required this.key,
    required this.productId,
    required this.name,
    required this.unit,
    required this.basePrice,
    required this.unitPrice,
    required this.qty,
    this.categoryId,
    this.discountAmount = 0,
    this.discountPercent = 0,
    this.discountApprovedBy,
  });

  final String key;
  final String productId;
  final String name;
  final String unit;
  final String? categoryId;

  /// Catalogue price at the moment the product was added.
  final int basePrice;

  /// Price used for this sale (differs from [basePrice] only if edited).
  final int unitPrice;
  final double qty;

  /// Manual line discount: either a fixed amount (minor units) or a percent.
  final int discountAmount;
  final double discountPercent;

  /// User id of the manager who approved a discount over the cashier limit.
  final String? discountApprovedBy;

  bool get fractional => Qty.isFractional(unit);
  bool get priceEdited => unitPrice != basePrice;
  int get gross => (unitPrice * qty).round();
  bool get hasManualDiscount => discountAmount > 0 || discountPercent > 0;

  /// Manual discount in minor units (capped to the line amount).
  int get manualDiscount => discountPercent > 0
      ? min(gross, Money.percent(gross, discountPercent))
      : min(gross, discountAmount);

  CartLine copyWith({
    int? unitPrice,
    double? qty,
    int? discountAmount,
    double? discountPercent,
    Object? discountApprovedBy = _keep,
  }) =>
      CartLine(
        key: key,
        productId: productId,
        name: name,
        unit: unit,
        categoryId: categoryId,
        basePrice: basePrice,
        unitPrice: unitPrice ?? this.unitPrice,
        qty: qty ?? this.qty,
        discountAmount: discountAmount ?? this.discountAmount,
        discountPercent: discountPercent ?? this.discountPercent,
        discountApprovedBy: identical(discountApprovedBy, _keep)
            ? this.discountApprovedBy
            : discountApprovedBy as String?,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'productId': productId,
        'name': name,
        'unit': unit,
        'categoryId': categoryId,
        'basePrice': basePrice,
        'unitPrice': unitPrice,
        'qty': qty,
        'discountAmount': discountAmount,
        'discountPercent': discountPercent,
        'discountApprovedBy': discountApprovedBy,
      };

  static CartLine fromJson(Map<String, dynamic> j) => CartLine(
        key: j['key'] as String,
        productId: j['productId'] as String,
        name: j['name'] as String,
        unit: (j['unit'] as String?) ?? 'pcs',
        categoryId: j['categoryId'] as String?,
        basePrice: (j['basePrice'] as num).toInt(),
        unitPrice: (j['unitPrice'] as num).toInt(),
        qty: (j['qty'] as num).toDouble(),
        discountAmount: (j['discountAmount'] as num?)?.toInt() ?? 0,
        discountPercent: (j['discountPercent'] as num?)?.toDouble() ?? 0,
        discountApprovedBy: j['discountApprovedBy'] as String?,
      );
}

const _keep = Object();

class CartState {
  const CartState({
    this.lines = const [],
    this.selectedKey,
    this.customerId,
    this.customerName,
    this.promoCode,
    this.orderDiscountPercent = 0,
    this.orderDiscountAmount = 0,
    this.orderDiscountApprovedBy,
    this.sellerId,
    this.note,
    this.approverId,
  });

  final List<CartLine> lines;
  final String? selectedKey;
  final String? customerId;
  final String? customerName;
  final String? promoCode;
  final double orderDiscountPercent;
  final int orderDiscountAmount;
  final String? orderDiscountApprovedBy;
  final String? sellerId;
  final String? note;

  /// Manager who approved the manual discounts of this cart above the
  /// cashier's limit (verified by PIN). Sent to checkout as
  /// `discountApprovedBy`; the service re-checks the cumulative limit.
  final String? approverId;

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;
  int get grossTotal => lines.fold(0, (s, l) => s + l.gross);
  bool get hasOrderDiscount => orderDiscountPercent > 0 || orderDiscountAmount > 0;
  bool get hasManualDiscounts => hasOrderDiscount || lines.any((l) => l.hasManualDiscount);

  /// The same cart without any manual discounts (to measure their share).
  CartState withoutManualDiscounts() => copyWith(
        lines: [
          for (final l in lines) l.copyWith(discountAmount: 0, discountPercent: 0, discountApprovedBy: null)
        ],
        orderDiscountPercent: 0,
        orderDiscountAmount: 0,
        orderDiscountApprovedBy: null,
        approverId: null,
      );

  /// Pure: the cart with a line discount applied (no validation).
  CartState withLineDiscount(String key, {int amount = 0, double percent = 0, String? approvedBy}) {
    final next = copyWith(lines: [
      for (final l in lines)
        l.key == key
            ? l.copyWith(
                discountAmount: percent > 0 ? 0 : amount,
                discountPercent: percent,
                discountApprovedBy: approvedBy)
            : l,
    ]);
    return next._dropStaleApprover();
  }

  /// Pure: the cart with an order discount applied (no validation).
  CartState withOrderDiscount({int amount = 0, double percent = 0, String? approvedBy}) => copyWith(
        orderDiscountPercent: percent,
        orderDiscountAmount: percent > 0 ? 0 : amount,
        orderDiscountApprovedBy: approvedBy,
      )._dropStaleApprover();

  CartState _dropStaleApprover() =>
      !hasManualDiscounts && approverId != null ? copyWith(approverId: null) : this;

  /// Refreshes catalogue data of the lines (after restoring a parked cart):
  /// price of lines whose price was NOT edited by hand follows the current
  /// catalogue price. Lines whose product vanished are kept (checkout will
  /// report them). Returns the new state and the number of re-priced lines.
  (CartState, int) withCatalogPrices(Map<String, Product> products) {
    var changed = 0;
    final out = <CartLine>[];
    for (final l in lines) {
      final p = products[l.productId];
      if (p == null || l.priceEdited || p.price == l.basePrice) {
        out.add(l);
        continue;
      }
      changed++;
      out.add(CartLine(
        key: l.key,
        productId: l.productId,
        name: p.name,
        unit: l.unit,
        categoryId: p.categoryId,
        basePrice: p.price,
        unitPrice: p.price,
        qty: l.qty,
        discountAmount: min(l.discountAmount, (p.price * l.qty).round()),
        discountPercent: l.discountPercent,
        discountApprovedBy: l.discountApprovedBy,
      ));
    }
    return (copyWith(lines: out), changed);
  }

  /// Number of units for display (pcs counted as units, weighted as 1 line).
  double get unitCount => lines.fold(0.0, (s, l) => s + (l.fractional ? 1 : l.qty));

  CartLine? get selected {
    for (final l in lines) {
      if (l.key == selectedKey) return l;
    }
    return null;
  }

  CartLine? line(String key) {
    for (final l in lines) {
      if (l.key == key) return l;
    }
    return null;
  }

  /// Everything that influences pricing. Used to re-quote only when needed.
  String get pricingSignature => [
        for (final l in lines)
          '${l.productId}|${l.qty}|${l.unitPrice}|${l.manualDiscount}',
        'c=$customerId',
        'p=${promoCode ?? ''}',
        'od=$orderDiscountPercent/$orderDiscountAmount',
      ].join(';');

  CartState copyWith({
    List<CartLine>? lines,
    Object? selectedKey = _keep,
    Object? customerId = _keep,
    Object? customerName = _keep,
    Object? promoCode = _keep,
    double? orderDiscountPercent,
    int? orderDiscountAmount,
    Object? orderDiscountApprovedBy = _keep,
    Object? sellerId = _keep,
    Object? note = _keep,
    Object? approverId = _keep,
  }) =>
      CartState(
        lines: lines ?? this.lines,
        selectedKey: identical(selectedKey, _keep) ? this.selectedKey : selectedKey as String?,
        customerId: identical(customerId, _keep) ? this.customerId : customerId as String?,
        customerName:
            identical(customerName, _keep) ? this.customerName : customerName as String?,
        promoCode: identical(promoCode, _keep) ? this.promoCode : promoCode as String?,
        orderDiscountPercent: orderDiscountPercent ?? this.orderDiscountPercent,
        orderDiscountAmount: orderDiscountAmount ?? this.orderDiscountAmount,
        orderDiscountApprovedBy: identical(orderDiscountApprovedBy, _keep)
            ? this.orderDiscountApprovedBy
            : orderDiscountApprovedBy as String?,
        sellerId: identical(sellerId, _keep) ? this.sellerId : sellerId as String?,
        note: identical(note, _keep) ? this.note : note as String?,
        approverId: identical(approverId, _keep) ? this.approverId : approverId as String?,
      );

  /// Builds the service request (lines in cart order — quote keys are '$i').
  CheckoutRequest toRequest({
    required String cashierId,
    String? shiftId,
    List<PaymentInput> payments = const [],
    DateTime? debtDueDate,
  }) =>
      CheckoutRequest(
        lines: [
          for (final l in lines)
            CheckoutLine(
              productId: l.productId,
              qty: Qty.round(l.qty),
              unitPrice: l.unitPrice,
              manualDiscount: l.manualDiscount,
            ),
        ],
        payments: payments,
        cashierId: cashierId,
        shiftId: shiftId,
        sellerId: sellerId,
        customerId: customerId,
        promoCode: (promoCode ?? '').trim().isEmpty ? null : promoCode!.trim(),
        manualOrderDiscountPercent: orderDiscountPercent,
        manualOrderDiscountAmount: orderDiscountAmount,
        note: (note ?? '').trim().isEmpty ? null : note!.trim(),
        debtDueDate: debtDueDate,
        discountApprovedBy: hasManualDiscounts ? approverId : null,
      );

  Map<String, dynamic> toJson() => {
        'lines': [for (final l in lines) l.toJson()],
        'customerId': customerId,
        'customerName': customerName,
        'promoCode': promoCode,
        'orderDiscountPercent': orderDiscountPercent,
        'orderDiscountAmount': orderDiscountAmount,
        'orderDiscountApprovedBy': orderDiscountApprovedBy,
        'sellerId': sellerId,
        'note': note,
        'approverId': approverId,
      };

  static CartState fromJson(Map<String, dynamic> j) => CartState(
        lines: [
          for (final l in (j['lines'] as List? ?? const []))
            CartLine.fromJson(Map<String, dynamic>.from(l as Map)),
        ],
        customerId: j['customerId'] as String?,
        customerName: j['customerName'] as String?,
        promoCode: j['promoCode'] as String?,
        orderDiscountPercent: (j['orderDiscountPercent'] as num?)?.toDouble() ?? 0,
        orderDiscountAmount: (j['orderDiscountAmount'] as num?)?.toInt() ?? 0,
        orderDiscountApprovedBy: j['orderDiscountApprovedBy'] as String?,
        sellerId: j['sellerId'] as String?,
        note: j['note'] as String?,
        approverId: j['approverId'] as String?,
      );
}

// ------------------------------------------------------------------ rules

/// Validates a quantity for a unit. Returns an error message or null.
String? validateQty(double? qty, String unit) {
  if (qty == null || qty.isNaN || qty.isInfinite) return 'Введите число';
  if (qty <= 0) return 'Количество должно быть больше нуля';
  if (qty > maxLineQty) return 'Слишком большое количество';
  if (!Qty.isFractional(unit) && qty != qty.roundToDouble()) {
    return 'Для «${Qty.unitLabel(unit)}» только целое количество';
  }
  if (Qty.round(qty) <= 0) return 'Слишком маленькое количество';
  return null;
}

/// Percent that [discount] makes of [base] (0 when base is 0).
double discountPercentOf(int discount, int base) =>
    base <= 0 ? (discount > 0 ? 100 : 0) : discount * 100 / base;

/// Share (in % of the cart subtotal) of all MANUAL discounts in [cart],
/// measured exactly like `SaleService.checkout` does (priced with and
/// without manual inputs). Used to decide whether a manager must approve.
Future<double> cartManualDiscountPercent(SaleService svc, CartState cart) async {
  if (cart.isEmpty || !cart.hasManualDiscounts) return 0;
  final withManual = await svc.quote(cart.toRequest(cashierId: ''));
  final without = await svc.quote(cart.withoutManualDiscounts().toRequest(cashierId: ''));
  final manual = withManual.discountTotal - without.discountTotal;
  if (manual <= 0 || withManual.subtotal <= 0) return 0;
  return manual * 100 / withManual.subtotal;
}

/// Whether a manual discount of [percent] fits into a user's limit.
bool withinDiscountLimit(double percent, double limitPercent) =>
    percent <= limitPercent + 1e-6;

/// Result of parsing what the cashier/scanner typed into the search field.
class ScanInput {
  const ScanInput(this.code, this.qty, {this.hasMultiplier = false});
  final String code;
  final double qty;
  final bool hasMultiplier;

  @override
  String toString() => 'ScanInput($code x $qty)';
}

final _multiplierRe = RegExp(r'^(\d+(?:[.,]\d+)?)\s*[*xXхХ×]\s*(\S+)$');

/// Parses "4780000000011", "3*4780000000011" or "0,5*2000001".
/// Returns null for empty input or an invalid multiplier ("0*123").
ScanInput? parseScanInput(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final m = _multiplierRe.firstMatch(s);
  if (m != null) {
    final q = double.tryParse(m.group(1)!.replaceAll(',', '.'));
    if (q == null || q <= 0) return null;
    return ScanInput(m.group(2)!, q, hasMultiplier: true);
  }
  return ScanInput(s, 1);
}

/// Scanner input is usually only digits (EAN/UPC/internal codes).
bool looksLikeBarcode(String s) => RegExp(r'^\d{4,}$').hasMatch(s.trim());

// ------------------------------------------------------------------ controller

class CartController extends Notifier<CartState> {
  var _seq = 0;

  @override
  CartState build() => const CartState();

  String _newKey() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  /// Adds [qty] of [p]; merges with an existing line of the same product.
  /// Returns an error message (and leaves the cart unchanged) when invalid.
  String? addProduct(Product p, {double qty = 1}) {
    final err = validateQty(qty, p.unit);
    if (err != null) return err;
    final idx = state.lines.indexWhere((l) => l.productId == p.id);
    if (idx >= 0) {
      final l = state.lines[idx];
      final newQty = Qty.round(l.qty + qty);
      if (newQty > maxLineQty) return 'Слишком большое количество';
      final lines = [...state.lines]..[idx] = l.copyWith(qty: newQty);
      state = state.copyWith(lines: lines, selectedKey: l.key);
      return null;
    }
    final line = CartLine(
      key: _newKey(),
      productId: p.id,
      name: p.name,
      unit: p.unit,
      categoryId: p.categoryId,
      basePrice: p.price,
      unitPrice: p.price,
      qty: Qty.round(qty),
    );
    state = state.copyWith(lines: [...state.lines, line], selectedKey: line.key);
    return null;
  }

  void _replace(String key, CartLine Function(CartLine) f) {
    state = state.copyWith(lines: [
      for (final l in state.lines) l.key == key ? f(l) : l,
    ]);
  }

  /// Sets the exact quantity. Returns an error message when invalid.
  String? setQty(String key, double qty) {
    final l = state.line(key);
    if (l == null) return 'Позиция не найдена';
    final err = validateQty(qty, l.unit);
    if (err != null) return err;
    _replace(key, (l) => l.copyWith(qty: Qty.round(qty)));
    return null;
  }

  /// +/- one unit. Never goes to zero (removal is an explicit action).
  bool changeQty(String key, int delta) {
    final l = state.line(key);
    if (l == null) return false;
    final next = Qty.round(l.qty + delta);
    if (next <= 0 || next > maxLineQty) return false;
    _replace(key, (l) => l.copyWith(qty: next));
    return true;
  }

  void remove(String key) {
    final idx = state.lines.indexWhere((l) => l.key == key);
    if (idx < 0) return;
    final lines = [...state.lines]..removeAt(idx);
    String? sel = state.selectedKey;
    if (sel == key) {
      sel = lines.isEmpty ? null : lines[min(idx, lines.length - 1)].key;
    }
    // an order discount by amount must not exceed the remaining cart
    final gross = lines.fold<int>(0, (s, l) => s + l.gross);
    var next = state.copyWith(lines: lines, selectedKey: sel);
    if (lines.isEmpty) {
      next = next.withOrderDiscount();
    } else if (next.orderDiscountAmount > gross) {
      next = next.copyWith(orderDiscountAmount: gross);
    }
    state = next._dropStaleApprover();
  }

  void select(String? key) => state = state.copyWith(selectedKey: key);

  void selectNext(int delta) {
    if (state.lines.isEmpty) return;
    final idx = state.lines.indexWhere((l) => l.key == state.selectedKey);
    final next = idx < 0
        ? (delta > 0 ? 0 : state.lines.length - 1)
        : (idx + delta).clamp(0, state.lines.length - 1);
    state = state.copyWith(selectedKey: state.lines[next].key);
  }

  String? setPrice(String key, int price) {
    if (price < 0) return 'Цена не может быть отрицательной';
    if (state.line(key) == null) return 'Позиция не найдена';
    _replace(key, (l) => l.copyWith(unitPrice: price));
    return null;
  }

  /// Sets a manual line discount (amount OR percent). Zero removes it.
  /// Limits/approval are checked by the caller (UI) before calling this.
  String? setLineDiscount(String key,
      {int amount = 0, double percent = 0, String? approvedBy}) {
    final l = state.line(key);
    if (l == null) return 'Позиция не найдена';
    if (amount < 0 || percent < 0) return 'Скидка не может быть отрицательной';
    if (percent > 100) return 'Скидка не может превышать 100%';
    if (amount > l.gross) return 'Скидка больше суммы позиции';
    state = state.withLineDiscount(key, amount: amount, percent: percent, approvedBy: approvedBy);
    return null;
  }

  String? setOrderDiscount({int amount = 0, double percent = 0, String? approvedBy}) {
    if (amount < 0 || percent < 0) return 'Скидка не может быть отрицательной';
    if (percent > 100) return 'Скидка не может превышать 100%';
    if (amount > state.grossTotal) return 'Скидка больше суммы чека';
    state = state.withOrderDiscount(amount: amount, percent: percent, approvedBy: approvedBy);
    return null;
  }

  /// Records the manager who approved the cart's manual discounts.
  void setApprover(String? userId) => state = state.copyWith(approverId: userId);

  void setCustomer(Customer? c) =>
      state = state.copyWith(customerId: c?.id, customerName: c?.name);

  void setPromoCode(String? code) {
    final c = (code ?? '').trim().toUpperCase();
    state = state.copyWith(promoCode: c.isEmpty ? null : c);
  }

  void setSeller(String? userId) => state = state.copyWith(sellerId: userId);
  void setNote(String? note) => state = state.copyWith(note: note);

  void clear() => state = const CartState();

  void restore(CartState s) =>
      state = s.copyWith(selectedKey: s.lines.isEmpty ? null : s.lines.last.key);
}

final cartProvider = NotifierProvider<CartController, CartState>(CartController.new);
