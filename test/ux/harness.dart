// Shared UX screenshot harness.
//
//   final h = await UxHarness.start(tester);          // demo store, owner logged in
//   await h.go('/products');
//   await h.shot('products_list');                     // -> <dir>/<size>_products_list.png
//   await tester.tap(find.text('Добавить')); await h.settle();
//   await h.shot('products_editor');
//   await h.finish();
//
// Output dir: env SCREENSHOTS_DIR (default build/screens). Size: h.setSize(...).
// Overflow/render errors are collected into <name>.errors.txt next to the PNG
// and returned by shot(), so a test can assert there are none.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dreampos/app/app.dart';
import 'package:dreampos/app/router.dart';
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/db/demo_seed.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Screenshot tests run only with env SCREENSHOTS=1.
final bool screenshotsEnabled = Platform.environment['SCREENSHOTS'] == '1';

const uxSizes = {
  'desktop': Size(1440, 900),
  'tablet': Size(1024, 768),
  'phone': Size(390, 844),
};

bool _fontsLoaded = false;

Future<void> loadUxFonts() async {
  if (_fontsLoaded) return;
  Future<void> load(String family, List<String> files) async {
    final l = FontLoader(family);
    for (final f in files) {
      final bytes = File(f).readAsBytesSync();
      l.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await l.load();
  }

  await load('Roboto', ['assets/fonts/Roboto-Regular.ttf', 'assets/fonts/Roboto-Bold.ttf']);
  await load('RobotoMono', ['assets/fonts/RobotoMono-Regular.ttf', 'assets/fonts/RobotoMono-Bold.ttf']);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? r'C:\dev\flutter';
  await load('MaterialIcons',
      ['$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf']);
  _fontsLoaded = true;
}

class UxHarness {
  UxHarness._(this.tester, this.db, this.container, this.owner, this.dir);

  final WidgetTester tester;
  final AppDatabase db;
  final ProviderContainer container;
  final User owner;
  final Directory dir;
  final _key = GlobalKey();
  String sizeName = 'desktop';

  static Future<UxHarness> start(WidgetTester tester, {String size = 'desktop'}) async {
    await tester.runAsync(loadUxFonts);
    final db = memoryDb();
    final owner = (await tester.runAsync(() => seedDemoStore(db)))!;
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    final dir = Directory(Platform.environment['SCREENSHOTS_DIR'] ?? 'build/screens')
      ..createSync(recursive: true);
    final h = UxHarness._(tester, db, container, owner, dir);
    h.setSize(size);
    container.read(sessionProvider.notifier).login(owner);
    await tester.pumpWidget(RepaintBoundary(
      key: h._key,
      child: UncontrolledProviderScope(container: container, child: const DreamPosApp()),
    ));
    await h.settle();
    return h;
  }

  void setSize(String name) {
    sizeName = name;
    tester.view.physicalSize = uxSizes[name]!;
    tester.view.devicePixelRatio = 1;
  }

  /// Lets DB futures/streams complete and frames render (no pumpAndSettle:
  /// spinners would never settle).
  Future<void> settle([int rounds = 6]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> go(String route) async {
    container.read(routerProvider).go(route);
    await settle(8);
  }

  /// Saves `<dir>/<size>_<name>.png`; returns collected render errors.
  Future<List<String>> shot(String name) async {
    final file = '${dir.path}/${sizeName}_$name.png';
    await tester.runAsync(() async {
      final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 1);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File(file).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    final errors = <String>[];
    Object? e;
    while ((e = tester.takeException()) != null) {
      errors.add(e.toString());
    }
    final errFile = File('$file.errors.txt');
    if (errors.isNotEmpty) {
      errFile.writeAsStringSync(errors.join('\n\n'));
    } else if (errFile.existsSync()) {
      errFile.deleteSync();
    }
    return errors;
  }

  Future<void> finish() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump(const Duration(seconds: 2));
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

/// Demo store: settings, catalogue, customers, promotions, an open shift and
/// 14 days of sales with a debt sale and a return. Returns the owner.
Future<User> seedDemoStore(AppDatabase db) async {
  for (final e in {
    'setup_done': '1',
    'store_name': 'Магазин «Ташкент Маркет»',
    'store_address': 'г. Ташкент, ул. Навои, 12',
    'store_phone': '+998 71 200 00 00',
    'currency_code': 'UZS',
    'currency_symbol': 'сум',
    'currency_decimals': '0',
    'require_shift': '1',
    'return_days': '14',
    'loyalty_enabled': '1',
    'loyalty_earn_percent': '2',
    'loyalty_max_redeem_percent': '50',
    'receipt_footer': 'Спасибо за покупку!',
    'demo_mode': '1',
  }.entries) {
    await db.setSetting(e.key, e.value);
  }
  final owner = await AuthService(db).createUser(name: 'Фаррух', role: Role.owner, pin: '2580');
  await DemoSeeder(db).seed(ownerId: owner.id);
  final shift = await ShiftService(db).open(userId: owner.id, openingCash: 500000);
  await _seedSales(db, owner.id, shift.id);
  return owner;
}

Future<void> _seedSales(AppDatabase db, String userId, String shiftId) async {
  final svc = SaleService(db);
  final products = await db.select(db.products).get();
  final customers = await db.select(db.customers).get();
  final now = DateTime.now();
  var n = 0;
  for (var day = 13; day >= 0; day--) {
    final count = 3 + (day * 7 % 5);
    for (var i = 0; i < count; i++) {
      n++;
      final p1 = products[(n * 3) % products.length];
      final p2 = products[(n * 7 + 1) % products.length];
      final at = DateTime(now.year, now.month, now.day - day, 9 + (n % 11), (n * 13) % 60);
      final lines = [
        CheckoutLine(productId: p1.id, qty: p1.unit == 'kg' ? 0.5 : (1 + n % 3).toDouble(), unitPrice: p1.price),
        if (n % 2 == 0) CheckoutLine(productId: p2.id, qty: 1, unitPrice: p2.price),
      ];
      final cust = n % 4 == 0 ? customers[n % customers.length] : null;
      final quote = await svc.quote(
          CheckoutRequest(lines: lines, payments: [], cashierId: userId, customerId: cust?.id, now: at));
      try {
        await svc.checkout(CheckoutRequest(
          lines: lines,
          payments: [PaymentInput(n % 3 == 0 ? 'card' : 'cash', quote.total + (n % 3 == 0 ? 0 : 1000))],
          cashierId: userId,
          shiftId: shiftId,
          customerId: cust?.id,
          now: at,
        ));
      } catch (_) {/* stock-outs in demo data are fine */}
    }
  }
  final debtor = customers.firstWhere((c) => c.debtLimit > 0);
  final big = products.firstWhere((p) => p.price > 100000);
  await svc.checkout(CheckoutRequest(
    lines: [CheckoutLine(productId: big.id, qty: 1, unitPrice: big.price)],
    payments: [PaymentInput('debt', big.price)],
    cashierId: userId,
    shiftId: shiftId,
    customerId: debtor.id,
  ));
  final other = await (db.select(db.sales)..limit(1)).getSingle();
  final oItem = (await (db.select(db.saleItems)..where((i) => i.saleId.equals(other.id))).get()).first;
  await svc.returnItems(
      saleId: other.id,
      lines: [ReturnLineInput(oItem.id, 1)],
      refundMethod: 'cash',
      userId: userId,
      shiftId: shiftId,
      reason: 'Брак');
}
