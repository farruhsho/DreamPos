// Multi-device harness for the sync engine tests: several in-memory
// databases with the real domain services, connected through FakeSyncServer.
import 'package:drift/drift.dart';
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/core/sync/sync_tables.dart';
import 'package:dreampos/core/sync/transport.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/domain/services/customer_service.dart';
import 'package:dreampos/domain/services/gift_card_service.dart';
import 'package:dreampos/domain/services/receipt_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/domain/services/supplier_service.dart';

import '../../helpers.dart';
import '../../support/fake_sync_server.dart';

const testEmail = 'owner@example.test';
const testPassword = 'test-password';
const testEndpoint = SyncEndpoint(url: 'https://fake.example.test', anonKey: 'anon-test-key');

class SyncDevice {
  SyncDevice(this.name, this.db, this.server, {int pushBatchSize = 200, int pullBatchSize = 500})
      : sync = SyncService(db,
            transportFactory: (_) => server.client(), pushBatchSize: pushBatchSize, pullBatchSize: pullBatchSize),
        stock = StockService(db),
        sales = SaleService(db),
        shifts = ShiftService(db),
        customers = CustomerService(db),
        gifts = GiftCardService(db),
        ledger = SupplierLedgerService(db) {
    receipts = ReceiptService(db, stock, ledger);
  }

  final String name;
  final AppDatabase db;
  final FakeSyncServer server;
  final SyncService sync;
  final StockService stock;
  final SaleService sales;
  final ShiftService shifts;
  final CustomerService customers;
  final GiftCardService gifts;
  final SupplierLedgerService ledger;
  late final ReceiptService receipts;

  late String userId;
  Shift? shift;

  static SyncDevice create(FakeSyncServer server, String name, {int pushBatchSize = 200, int pullBatchSize = 500}) {
    // Several independent in-memory databases on purpose.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    return SyncDevice(name, memoryDb(), server, pushBatchSize: pushBatchSize, pullBatchSize: pullBatchSize);
  }

  Future<void> signIn() => sync.signIn(endpoint: testEndpoint, email: testEmail, password: testPassword);

  /// Owner user (first device only).
  Future<void> createOwner() async {
    userId = (await AuthService(db).createUser(name: 'Владелец', role: Role.owner, pin: '2580')).id;
  }

  /// Uses the (synced) owner and opens this register's own shift.
  Future<Shift> openShift({int openingCash = 10000}) async {
    final u = await (db.select(db.users)..limit(1)).getSingle();
    userId = u.id;
    return shift = await shifts.open(userId: userId, openingCash: openingCash, registerId: 'reg-$name');
  }

  Future<SyncReport> syncNow() => sync.syncNow();

  Future<Product> product(String name, {int price = 1000, double qty = 20, String? barcode}) async {
    final id = newId();
    await db.into(db.products).insert(ProductsCompanion.insert(
          id: id,
          name: name,
          price: price,
          costPrice: const Value(600),
          barcode: Value(barcode),
        ));
    if (qty > 0) await stock.receive(productId: id, qty: qty, unitCost: 600, userId: userId);
    return productById(id);
  }

  Future<Product> productById(String id) => (db.select(db.products)..where((p) => p.id.equals(id))).getSingle();
  Future<Customer> customerById(String id) => (db.select(db.customers)..where((p) => p.id.equals(id))).getSingle();
  Future<GiftCard> giftById(String id) => (db.select(db.giftCards)..where((p) => p.id.equals(id))).getSingle();
  Future<Supplier> supplierById(String id) => (db.select(db.suppliers)..where((p) => p.id.equals(id))).getSingle();

  Future<Customer> customer(String name, {String? card, int debtLimit = 1000000}) async {
    final id = newId();
    await db.into(db.customers).insert(CustomersCompanion.insert(
          id: id,
          name: name,
          cardNumber: Value(card),
          debtLimit: Value(debtLimit),
        ));
    return customerById(id);
  }

  Future<Supplier> supplier(String name) async {
    final id = newId();
    await db.into(db.suppliers).insert(SuppliersCompanion.insert(id: id, name: name));
    return supplierById(id);
  }

  Future<CheckoutResult> sell(String productId, double qty, {int price = 1000, List<PaymentInput>? pays, String? customerId}) =>
      sales.checkout(CheckoutRequest(
        lines: [CheckoutLine(productId: productId, qty: qty, unitPrice: price)],
        payments: pays ?? [PaymentInput('cash', (qty * price).round())],
        cashierId: userId,
        shiftId: shift!.id,
        customerId: customerId,
      ));

  Future<void> close() async {
    sync.dispose();
    await db.close();
  }
}

/// Server with one account; device A creates a `test` store from its data
/// (owner user created first), the others join empty and pull. Every device
/// has its own open shift afterwards.
Future<List<SyncDevice>> cluster(int n, {FakeSyncServer? server, String storeName = 'Магазин'}) async {
  final s = server ?? (FakeSyncServer()..addUser(testEmail, testPassword));
  final devices = [for (var i = 0; i < n; i++) SyncDevice.create(s, String.fromCharCode(65 + i))];
  final a = devices.first;
  await a.createOwner();
  await a.signIn();
  final info = await a.sync.createStoreAndUpload(name: storeName, environment: StoreEnvironment.test);
  for (final d in devices.skip(1)) {
    await d.signIn();
    await d.sync.joinStore(info.id);
  }
  for (final d in devices) {
    await d.openShift();
  }
  await syncAll(devices);
  return devices;
}

/// Two rounds of push+pull on every device: after it everybody has
/// everything (round 1 pushes, round 2 pulls what others pushed later).
Future<void> syncAll(List<SyncDevice> devices) async {
  for (var round = 0; round < 2; round++) {
    for (final d in devices) {
      await d.syncNow();
    }
  }
}

/// Full dump of the synced data: every synced table (all columns, by id) and
/// the synced settings. Local tables are excluded by construction.
Future<Map<String, List<Map<String, Object?>>>> dump(AppDatabase db) async {
  final out = <String, List<Map<String, Object?>>>{};
  for (final t in syncedTables) {
    out[t] = [for (final r in await db.customSelect('SELECT * FROM $t ORDER BY id').get()) r.data];
  }
  out['settings'] = [
    for (final r in await db.customSelect('SELECT key, value FROM settings ORDER BY key').get())
      if (!isLocalSettingKey(r.read<String>('key'))) r.data,
  ];
  return out;
}

/// Human-readable first difference between two dumps (null when equal).
String? dumpDiff(Map<String, List<Map<String, Object?>>> a, Map<String, List<Map<String, Object?>>> b) {
  for (final t in {...a.keys, ...b.keys}) {
    final ra = a[t] ?? const [], rb = b[t] ?? const [];
    final ia = {for (final r in ra) '${r['id'] ?? r['key']}': r};
    final ib = {for (final r in rb) '${r['id'] ?? r['key']}': r};
    for (final id in {...ia.keys, ...ib.keys}) {
      final x = ia[id], y = ib[id];
      if (x == null || y == null) return '$t/$id only on ${x == null ? 'second' : 'first'}';
      for (final c in {...x.keys, ...y.keys}) {
        if (x[c] != y[c]) return '$t/$id.$c: ${x[c]} != ${y[c]}';
      }
    }
  }
  return null;
}
