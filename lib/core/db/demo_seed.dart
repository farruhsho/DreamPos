import 'package:drift/drift.dart';

import '../../core/permissions.dart';
import '../../domain/services/auth_service.dart';
import '../money.dart';
import 'database.dart';

/// Demo data, only on explicit opt-in during setup (setting demo_mode=1).
/// Prices are given in major units and converted with the selected currency.
class DemoSeeder {
  DemoSeeder(this.db);
  final AppDatabase db;

  int _m(num major) => (major * Money.currency.factor).round();

  Future<void> seed({required String ownerId}) async {
    await db.transaction(() async {
      final cats = <String, String>{};
      final catDefs = {
        'Напитки': 0xFF0EA5E9,
        'Молочные продукты': 0xFF22C55E,
        'Бакалея': 0xFFF59E0B,
        'Сладости': 0xFFEC4899,
        'Бытовая химия': 0xFF8B5CF6,
        'Электроника': 0xFF64748B,
      };
      var order = 0;
      for (final e in catDefs.entries) {
        final id = newId();
        cats[e.key] = id;
        await db.into(db.categories).insert(CategoriesCompanion.insert(
            id: id, name: e.key, color: Value(e.value), sortOrder: Value(order++)));
      }
      final supplierId = newId();
      await db.into(db.suppliers).insert(SuppliersCompanion.insert(
          id: supplierId, name: 'ООО «Оптовик»', phone: const Value('+998 90 000 00 00'),
          contactPerson: const Value('Рустам')));

      // name, category, price, cost, unit, stock, barcode, warrantyMonths
      final products = [
        ['Вода минеральная 1.5л', 'Напитки', 5000, 3200, 'pcs', 120, '4780000000011', 0],
        ['Кола 1л', 'Напитки', 11000, 8000, 'pcs', 60, '4780000000028', 0],
        ['Сок яблочный 1л', 'Напитки', 14000, 10000, 'pcs', 40, '4780000000035', 0],
        ['Чай чёрный 100г', 'Напитки', 18000, 12500, 'pcs', 35, '4780000000042', 0],
        ['Кофе растворимый 95г', 'Напитки', 42000, 31000, 'pcs', 18, '4780000000059', 0],
        ['Молоко 2.5% 1л', 'Молочные продукты', 12000, 9000, 'pcs', 50, '4780000000066', 0],
        ['Кефир 1л', 'Молочные продукты', 11000, 8200, 'pcs', 30, '4780000000073', 0],
        ['Сыр российский', 'Молочные продукты', 95000, 72000, 'kg', 8.5, '2000000000015', 0],
        ['Масло сливочное 200г', 'Молочные продукты', 28000, 21000, 'pcs', 4, '4780000000080', 0],
        ['Рис девзира', 'Бакалея', 26000, 19000, 'kg', 75, '2000000000022', 0],
        ['Сахар', 'Бакалея', 13000, 10500, 'kg', 100, '2000000000039', 0],
        ['Мука в/с 2кг', 'Бакалея', 17000, 13000, 'pcs', 25, '4780000000097', 0],
        ['Масло подсолнечное 1л', 'Бакалея', 21000, 16500, 'pcs', 3, '4780000000103', 0],
        ['Макароны 400г', 'Бакалея', 8000, 5600, 'pcs', 45, '4780000000110', 0],
        ['Шоколад молочный 90г', 'Сладости', 15000, 10000, 'pcs', 60, '4780000000127', 0],
        ['Печенье овсяное 300г', 'Сладости', 12000, 8000, 'pcs', 22, '4780000000134', 0],
        ['Конфеты ассорти', 'Сладости', 68000, 48000, 'kg', 6, '2000000000046', 0],
        ['Стиральный порошок 3кг', 'Бытовая химия', 65000, 49000, 'pcs', 12, '4780000000141', 0],
        ['Средство для посуды 500мл', 'Бытовая химия', 16000, 11000, 'pcs', 2, '4780000000158', 0],
        ['Наушники беспроводные', 'Электроника', 250000, 170000, 'pcs', 7, '4780000000165', 12],
        ['Зарядное устройство USB-C', 'Электроника', 85000, 52000, 'pcs', 15, '4780000000172', 6],
        ['Power bank 10000 mAh', 'Электроника', 190000, 130000, 'pcs', 5, '4780000000189', 12],
      ];
      final ids = <String>[];
      for (final p in products) {
        final id = newId();
        ids.add(id);
        await db.into(db.products).insert(ProductsCompanion.insert(
              id: id,
              name: p[0] as String,
              categoryId: Value(cats[p[1]]),
              price: _m(p[2] as int),
              costPrice: Value(_m(p[3] as int)),
              unit: Value(p[4] as String),
              stockQty: Value((p[5] as num).toDouble()),
              minStock: const Value(5),
              barcode: Value(_ean13(p[6] as String)),
              warrantyMonths: Value(p[7] as int),
              supplierId: Value(supplierId),
              isFavorite: Value(ids.length <= 6),
            ));
        await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
              id: newId(),
              productId: id,
              type: 'receipt',
              qty: (p[5] as num).toDouble(),
              qtyAfter: (p[5] as num).toDouble(),
              unitCost: Value(_m(p[3] as int)),
              refType: const Value('manual'),
              reason: const Value('Начальные остатки (демо)'),
              userId: Value(ownerId),
            ));
      }

      final customers = [
        ['Алишер Каримов', '+998 90 123 45 67', 5.0, 0],
        ['Дилноза Юсупова', '+998 91 234 56 78', 0.0, _m(500000)],
        ['Фарход Рахимов', '+998 93 345 67 89', 3.0, _m(1000000)],
        ['Мадина Азизова', '+998 94 456 78 90', 0.0, 0],
      ];
      var card = 1000;
      for (final c in customers) {
        await db.into(db.customers).insert(CustomersCompanion.insert(
              id: newId(),
              name: c[0] as String,
              phone: Value(c[1] as String),
              discountPercent: Value(c[2] as double),
              debtLimit: Value(c[3] as int),
              cardNumber: Value('DP${card++}'),
            ));
      }

      await db.into(db.promotions).insert(PromotionsCompanion.insert(
          id: newId(), name: 'Сладкая неделя −10%', type: 'percent_category', value: 10,
          targetId: Value(cats['Сладости'])));
      await db.into(db.promotions).insert(PromotionsCompanion.insert(
          id: newId(), name: 'Вода 2+1', type: 'buy_x_get_y', value: 0,
          targetId: Value(ids[0]), buyQty: const Value(2), getQty: const Value(1)));
      await db.into(db.promotions).insert(PromotionsCompanion.insert(
          id: newId(), name: 'Промокод WELCOME −5%', type: 'promo_code', value: 5,
          code: const Value('WELCOME')));

      await db.into(db.registers).insert(RegistersCompanion.insert(id: newId(), name: 'Касса 1'));
    });
    final auth = AuthService(db);
    await auth.createUser(name: 'Кассир Нигора', role: Role.cashier, pin: '1357', maxDiscountPercent: 5);
    await auth.createUser(name: 'Менеджер Тимур', role: Role.manager, pin: '2468', maxDiscountPercent: 20);
    await db.setSetting('loyalty_enabled', '1');
  }
}

/// Replaces the 13th digit with the correct EAN-13 check digit.
String _ean13(String code) {
  final d = code.substring(0, 12);
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    sum += int.parse(d[i]) * (i.isEven ? 1 : 3);
  }
  return '$d${(10 - sum % 10) % 10}';
}
