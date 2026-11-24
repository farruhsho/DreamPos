import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/db/sql_functions.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';

AppDatabase memoryDb() => AppDatabase(NativeDatabase.memory(setup: registerSqlFunctions));

class Fixture {
  Fixture(this.db);
  final AppDatabase db;
  late User owner;
  late Shift shift;

  static Future<Fixture> create() async {
    final f = Fixture(memoryDb());
    f.owner = await AuthService(f.db).createUser(name: 'Owner', role: Role.owner, pin: '2580');
    f.shift = await ShiftService(f.db).open(userId: f.owner.id, openingCash: 10000);
    return f;
  }

  Future<Product> product(String name,
      {int price = 1000, int cost = 600, double stock = 10, String? categoryId, double vat = 0}) async {
    final id = newId();
    await db.into(db.products).insert(ProductsCompanion.insert(
          id: id,
          name: name,
          price: price,
          costPrice: Value(cost),
          stockQty: Value(stock),
          categoryId: Value(categoryId),
          vatPercent: Value(vat),
        ));
    return (db.select(db.products)..where((p) => p.id.equals(id))).getSingle();
  }

  Future<Customer> customer(String name, {double discount = 0, int debtLimit = 0, int bonus = 0}) async {
    final id = newId();
    await db.into(db.customers).insert(CustomersCompanion.insert(
          id: id,
          name: name,
          discountPercent: Value(discount),
          debtLimit: Value(debtLimit),
          bonusBalance: Value(bonus),
        ));
    return (db.select(db.customers)..where((c) => c.id.equals(id))).getSingle();
  }

  Future<Product> reload(Product p) =>
      (db.select(db.products)..where((t) => t.id.equals(p.id))).getSingle();
  Future<Customer> reloadC(Customer c) =>
      (db.select(db.customers)..where((t) => t.id.equals(c.id))).getSingle();
}
