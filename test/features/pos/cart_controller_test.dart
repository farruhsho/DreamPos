import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/features/pos/cart_controller.dart';
import 'package:dreampos/features/pos/parked_carts.dart';
import 'package:dreampos/features/pos/tender.dart';
import 'package:dreampos/features/pos/widgets/payment_dialog.dart';
import 'package:dreampos/features/pos/widgets/pos_dialogs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers.dart';

Product _p(String id, {int price = 1000, String unit = 'pcs', String? cat}) => Product(
      id: id,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      name: 'Товар $id',
      unit: unit,
      price: price,
      costPrice: 0,
      vatPercent: 0,
      trackStock: true,
      allowNegativeStock: false,
      stockQty: 10,
      minStock: 0,
      warrantyMonths: 0,
      isActive: true,
      isFavorite: false,
      categoryId: cat,
    );

void main() {
  late ProviderContainer c;
  CartController ctl() => c.read(cartProvider.notifier);
  CartState st() => c.read(cartProvider);

  setUp(() => c = ProviderContainer());
  tearDown(() => c.dispose());

  group('adding and merging', () {
    test('adds a new line and selects it', () {
      expect(ctl().addProduct(_p('a')), isNull);
      expect(st().lines, hasLength(1));
      expect(st().lines.single.qty, 1);
      expect(st().selectedKey, st().lines.single.key);
    });

    test('same product merges into one line', () {
      ctl().addProduct(_p('a'));
      ctl().addProduct(_p('b'));
      ctl().addProduct(_p('a'), qty: 2);
      expect(st().lines, hasLength(2));
      expect(st().lines.first.qty, 3);
      expect(st().selected!.productId, 'a');
      expect(st().grossTotal, 4000);
    });

    test('fractional qty only for kg/l/m', () {
      expect(ctl().addProduct(_p('w', unit: 'kg', price: 20000), qty: 0.75), isNull);
      expect(st().lines.single.gross, 15000);
      expect(ctl().addProduct(_p('a'), qty: 1.5), contains('целое'));
      expect(st().lines, hasLength(1));
    });

    test('rejects zero / negative / huge qty', () {
      expect(ctl().addProduct(_p('a'), qty: 0), isNotNull);
      expect(ctl().addProduct(_p('a'), qty: -1), isNotNull);
      expect(ctl().addProduct(_p('a'), qty: maxLineQty + 1), isNotNull);
      expect(st().isEmpty, isTrue);
    });
  });

  group('quantities', () {
    test('stepper +/- never goes to zero', () {
      ctl().addProduct(_p('a'));
      final k = st().lines.single.key;
      expect(ctl().changeQty(k, 1), isTrue);
      expect(st().lines.single.qty, 2);
      expect(ctl().changeQty(k, -1), isTrue);
      expect(ctl().changeQty(k, -1), isFalse);
      expect(st().lines.single.qty, 1);
    });

    test('exact qty with validation', () {
      ctl().addProduct(_p('w', unit: 'kg'), qty: 1);
      final k = st().lines.single.key;
      expect(ctl().setQty(k, 2.345), isNull);
      expect(st().lines.single.qty, 2.345);
      expect(ctl().setQty(k, 0), isNotNull);
      expect(st().lines.single.qty, 2.345);
    });

    test('remove selects the neighbour', () {
      ctl().addProduct(_p('a'));
      ctl().addProduct(_p('b'));
      ctl().addProduct(_p('c'));
      final keys = st().lines.map((l) => l.key).toList();
      ctl().select(keys[1]);
      ctl().remove(keys[1]);
      expect(st().lines.map((l) => l.productId), ['a', 'c']);
      expect(st().selectedKey, keys[2]);
      ctl().remove(keys[0]);
      ctl().remove(keys[2]);
      expect(st().isEmpty, isTrue);
      expect(st().selectedKey, isNull);
    });

    test('selectNext walks lines', () {
      ctl().addProduct(_p('a'));
      ctl().addProduct(_p('b'));
      ctl().selectNext(-1);
      expect(st().selected!.productId, 'a');
      ctl().selectNext(-1);
      expect(st().selected!.productId, 'a');
      ctl().selectNext(1);
      expect(st().selected!.productId, 'b');
    });
  });

  group('discounts and prices', () {
    test('line discount by percent and amount, capped', () {
      ctl().addProduct(_p('a', price: 10000), qty: 2);
      final k = st().lines.single.key;
      expect(ctl().setLineDiscount(k, percent: 10), isNull);
      expect(st().lines.single.manualDiscount, 2000);
      expect(ctl().setLineDiscount(k, amount: 500), isNull);
      expect(st().lines.single.manualDiscount, 500);
      expect(st().lines.single.discountPercent, 0);
      expect(ctl().setLineDiscount(k, amount: 50000), isNotNull);
      expect(ctl().setLineDiscount(k, percent: 150), isNotNull);
      expect(ctl().setLineDiscount(k), isNull);
      expect(st().lines.single.hasManualDiscount, isFalse);
    });

    test('order discount validation', () {
      ctl().addProduct(_p('a', price: 10000));
      expect(ctl().setOrderDiscount(percent: 5), isNull);
      expect(st().orderDiscountPercent, 5);
      expect(ctl().setOrderDiscount(amount: 20000), isNotNull);
      expect(ctl().setOrderDiscount(amount: 1000, approvedBy: 'm'), isNull);
      expect(st().orderDiscountAmount, 1000);
      expect(st().orderDiscountPercent, 0);
      expect(st().orderDiscountApprovedBy, 'm');
    });

    test('discount limit helpers', () {
      expect(discountPercentOf(500, 10000), 5);
      expect(withinDiscountLimit(5, 5), isTrue);
      expect(withinDiscountLimit(5.01, 5), isFalse);
      expect(withinDiscountLimit(0, 0), isTrue);
    });

    test('price edit', () {
      ctl().addProduct(_p('a', price: 10000));
      final k = st().lines.single.key;
      expect(ctl().setPrice(k, -1), isNotNull);
      expect(ctl().setPrice(k, 9000), isNull);
      expect(st().lines.single.priceEdited, isTrue);
      expect(st().grossTotal, 9000);
    });

    test('toRequest maps lines in order with manual discounts', () {
      ctl().addProduct(_p('a', price: 10000));
      ctl().addProduct(_p('b', price: 5000), qty: 2);
      ctl().setLineDiscount(st().lines.first.key, percent: 10);
      ctl().setPromoCode(' spring ');
      final r = st().toRequest(cashierId: 'u1', shiftId: 's1');
      expect(r.lines.map((l) => l.productId), ['a', 'b']);
      expect(r.lines.first.manualDiscount, 1000);
      expect(r.lines.last.qty, 2);
      expect(r.promoCode, 'SPRING');
      expect(r.shiftId, 's1');
    });
  });

  group('scanner input', () {
    test('plain code', () {
      final s = parseScanInput(' 4780000000011 ')!;
      expect(s.code, '4780000000011');
      expect(s.qty, 1);
      expect(s.hasMultiplier, isFalse);
    });

    test('multiplier prefix', () {
      final s = parseScanInput('3*4780000000011')!;
      expect(s.code, '4780000000011');
      expect(s.qty, 3);
      expect(s.hasMultiplier, isTrue);
      expect(parseScanInput('0,5*2000001')!.qty, 0.5);
      expect(parseScanInput('2 x 123456')!.qty, 2);
    });

    test('invalid input', () {
      expect(parseScanInput(''), isNull);
      expect(parseScanInput('0*123456'), isNull);
      expect(parseScanInput('молоко')!.code, 'молоко');
      expect(looksLikeBarcode('4780000000011'), isTrue);
      expect(looksLikeBarcode('молоко'), isFalse);
    });
  });

  group('payment math', () {
    test('quick tenders round up to banknotes', () {
      const uzs = CurrencyConfig(code: 'UZS', decimals: 0);
      expect(quickTenders(37500, uzs), [38000, 40000, 50000, 100000]);
      expect(quickTenders(0, uzs), isEmpty);
      const tjs = CurrencyConfig(code: 'TJS', decimals: 2);
      expect(quickTenders(1250, tjs).first, 1300);
    });

    test('split: change, missing, overpay', () {
      expect(const PaymentSplit(total: 10000, cash: 15000).change, 5000);
      expect(const PaymentSplit(total: 10000, cash: 15000).error, isNull);
      expect(const PaymentSplit(total: 10000, cash: 5000).error, contains('Не хватает'));
      expect(const PaymentSplit(total: 10000, card: 4000, cash: 6000).error, isNull);
      expect(const PaymentSplit(total: 10000, card: 12000).error, isNotNull);
      expect(const PaymentSplit(total: 10000, card: 10000, cash: 100).error, isNotNull);
      expect(const PaymentSplit(total: 10000, card: 10000).error, isNull);
    });
  });

  group('approval and repricing (audit fixes)', () {
    test('approver travels to checkout request and JSON, dropped with discounts', () {
      ctl().addProduct(_p('a', price: 10000), qty: 2);
      final key = st().lines.single.key;
      ctl().setLineDiscount(key, percent: 30, approvedBy: 'mgr');
      ctl().setApprover('mgr');
      expect(st().toRequest(cashierId: 'c').discountApprovedBy, 'mgr');
      expect(CartState.fromJson(st().toJson()).approverId, 'mgr');

      // removing the only manual discount forgets the approval
      ctl().setLineDiscount(key);
      expect(st().hasManualDiscounts, isFalse);
      expect(st().approverId, isNull);
      expect(st().toRequest(cashierId: 'c').discountApprovedBy, isNull);
    });

    test('clear() forgets everything including approval', () {
      ctl().addProduct(_p('a'));
      ctl().setOrderDiscount(percent: 50);
      ctl().setApprover('mgr');
      ctl().clear();
      expect(st().approverId, isNull);
      expect(st().hasOrderDiscount, isFalse);
    });

    test('withoutManualDiscounts keeps lines, strips manual parts', () {
      ctl().addProduct(_p('a', price: 10000));
      ctl().setLineDiscount(st().lines.single.key, amount: 500);
      ctl().setOrderDiscount(percent: 5);
      final plain = st().withoutManualDiscounts();
      expect(plain.lines.single.manualDiscount, 0);
      expect(plain.hasManualDiscounts, isFalse);
      expect(plain.lines.single.qty, 1);
      // pure: the cart itself is unchanged
      expect(st().lines.single.manualDiscount, 500);
    });

    test('removing lines caps an order discount amount to what is left', () {
      ctl().addProduct(_p('a', price: 10000));
      ctl().addProduct(_p('b', price: 1000));
      ctl().setOrderDiscount(amount: 5000);
      ctl().remove(st().lines.first.key);
      expect(st().orderDiscountAmount, 1000);
      ctl().remove(st().lines.single.key);
      expect(st().hasOrderDiscount, isFalse);
    });

    test('restored parked cart follows catalogue price unless edited by hand', () {
      ctl().addProduct(_p('a', price: 1000));
      ctl().addProduct(_p('b', price: 2000));
      ctl().setPrice(st().lines.last.key, 1500); // manual price stays
      final (fresh, n) = st().withCatalogPrices({
        'a': _p('a', price: 1200),
        'b': _p('b', price: 2500),
      });
      expect(n, 1);
      expect(fresh.lines.first.unitPrice, 1200);
      expect(fresh.lines.first.basePrice, 1200);
      expect(fresh.lines.last.unitPrice, 1500);
      // product gone from catalogue: line kept unchanged
      final (same, n2) = st().withCatalogPrices(const {});
      expect(n2, 0);
      expect(same.lines.first.unitPrice, 1000);
    });
  });

  group('manager approval rule', () {
    test('approver needs permission and higher limit', () async {
      final db = memoryDb();
      addTearDown(db.close);
      final auth = AuthService(db);
      final cashier = await auth.createUser(
          name: 'Кассир', role: Role.cashier, pin: '1357', maxDiscountPercent: 5);
      final manager = await auth.createUser(
          name: 'Менеджер', role: Role.manager, pin: '2468', maxDiscountPercent: 20);
      final owner = await auth.createUser(name: 'Владелец', role: Role.owner, pin: '3691');
      final cashier2 = await auth.createUser(
          name: 'Кассир 2', role: Role.cashier, pin: '4826', maxDiscountPercent: 50);
      expect(approvalError(manager, cashier, 15), isNull);
      expect(approvalError(manager, cashier, 25), isNotNull);
      expect(approvalError(owner, cashier, 90), isNull);
      expect(approvalError(cashier2, cashier, 10), contains('нет права'));
    });
  });

  group('parked carts', () {
    test('json round trip keeps everything', () {
      ctl().addProduct(_p('a', price: 10000), qty: 2);
      ctl().addProduct(_p('w', unit: 'kg', price: 3000), qty: 0.5);
      ctl().setLineDiscount(st().lines.first.key, percent: 10, approvedBy: 'm');
      ctl().setOrderDiscount(amount: 100);
      ctl().setPromoCode('X1');
      final p = ParkedCart(id: '1', createdAt: DateTime(2026, 1, 2), cart: st(), note: 'Иван');
      final back = decodeParked(encodeParked([p])).single;
      expect(back.note, 'Иван');
      expect(back.cart.lines, hasLength(2));
      expect(back.cart.lines.last.qty, 0.5);
      expect(back.cart.lines.first.discountApprovedBy, 'm');
      expect(back.cart.pricingSignature, st().pricingSignature);
    });

    test('broken storage does not crash', () {
      expect(decodeParked('not json'), isEmpty);
      expect(decodeParked('[{"id":1}]'), isEmpty);
      expect(decodeParked(null), isEmpty);
    });

    test('park / take persist to shared_preferences', () async {
      SharedPreferences.setMockInitialValues({});
      ctl().addProduct(_p('a'));
      final n = c.read(parkedCartsProvider.notifier);
      await c.read(parkedCartsProvider.future);
      final parked = await n.park(st(), note: 'Покупатель в синем');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ParkedCartsController.prefsKey), contains('Покупатель в синем'));

      // a fresh container (= app restart) sees the parked cart
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      final list = await c2.read(parkedCartsProvider.future);
      expect(list.single.id, parked.id);

      final taken = await n.take(parked.id);
      expect(taken!.cart.lines.single.productId, 'a');
      expect(await n.take(parked.id), isNull);
      expect(decodeParked(prefs.getString(ParkedCartsController.prefsKey)), isEmpty);
    });
  });
}
