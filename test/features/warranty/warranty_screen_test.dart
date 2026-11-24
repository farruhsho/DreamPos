import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/features/warranty/warranty_repository.dart';
import 'package:dreampos/features/warranty/warranty_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

class _LoggedIn extends SessionNotifier {
  _LoggedIn(this.user);
  final User user;
  @override
  Session? build() => Session(user);
}

void main() {
  late Fixture f;
  setUp(() async => f = await Fixture.create());

  Future<void> pump(WidgetTester tester, Size size) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(f.db), sessionProvider.overrideWith(() => _LoggedIn(f.owner))],
        child: const MaterialApp(home: WarrantyScreen()),
      ),
    );
    await settle(tester);
  }

  Future<void> cleanup(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await settle(tester, rounds: 2);
    await tester.runAsync(f.db.close);
  }

  testWidgets('empty state offers creating a claim', (tester) async {
    await pump(tester, const Size(1400, 900));
    expect(find.text('Заявок пока нет'), findsOneWidget);
    expect(find.text('Новая заявка'), findsWidgets);
    await cleanup(tester);
  });

  testWidgets('list -> detail -> move to repair', (tester) async {
    await tester.runAsync(() async {
      final p = await f.product('Пылесос');
      await WarrantyRepository(
        f.db,
      ).createClaim(productId: p.id, serialNumber: 'SN-77', problem: 'Не включается', userId: f.owner.id);
    });
    await pump(tester, const Size(1400, 900));
    expect(find.textContaining('№1 · Пылесос'), findsOneWidget);

    await tester.tap(find.textContaining('№1 · Пылесос'));
    await settle(tester);
    expect(find.text('Заявка №1'), findsOneWidget);
    expect(find.text('SN-77'), findsOneWidget);

    await tester.tap(find.text('Передать в ремонт'));
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).last, 'СЦ, 7 дней');
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await settle(tester);

    final claim = await tester.runAsync(() => f.db.select(f.db.warrantyClaims).getSingle());
    expect(claim!.status, 'in_repair');
    expect(find.text('В ремонте'), findsWidgets);
    await cleanup(tester);
  });

  testWidgets('new claim by receipt number: lookup, item auto-picked, saved', (tester) async {
    late Sale sale;
    await tester.runAsync(() async {
      final p = await f.product('Смартфон', price: 300000, stock: 2);
      await (f.db.update(
        f.db.products,
      )..where((t) => t.id.equals(p.id))).write(const ProductsCompanion(warrantyMonths: Value(12)));
      sale = (await SaleService(f.db).checkout(
        CheckoutRequest(
          lines: [CheckoutLine(productId: p.id, qty: 1, unitPrice: 300000)],
          payments: [PaymentInput('card', 300000)],
          cashierId: f.owner.id,
          shiftId: f.shift.id,
        ),
      )).sale;
    });
    await pump(tester, const Size(1400, 900));
    await tester.tap(find.text('Новая заявка').first);
    await settle(tester);
    await tester.enterText(find.byKey(const Key('claim-receipt')), '${sale.number}');
    await tester.tap(find.text('Найти'));
    await settle(tester);
    expect(find.textContaining('На гарантии до'), findsOneWidget, reason: 'single item auto-selected');
    await tester.enterText(find.byKey(const Key('claim-problem')), 'Не заряжается');
    await tester.tap(find.text('Принять заявку'));
    await settle(tester);
    // offer to print the act
    expect(find.text('Заявка №1 принята'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await settle(tester);

    final claim = await tester.runAsync(() => f.db.select(f.db.warrantyClaims).getSingle());
    expect(claim!.saleItemId, isNotNull);
    expect(claim.problem, 'Не заряжается');
    expect(find.text('Заявка №1'), findsOneWidget, reason: 'new claim opened in the detail pane');
    await cleanup(tester);
  });

  testWidgets('narrow layout opens new claim form', (tester) async {
    await pump(tester, const Size(360, 740));
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    expect(find.text('Новая гарантийная заявка'), findsOneWidget);
    await tester.tap(find.text('Принять заявку'));
    await settle(tester);
    expect(find.text('Опишите неисправность'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });

  testWidgets('360px phone: claim detail with a refund decision renders without overflow', (tester) async {
    await tester.runAsync(() async {
      final p = await f.product('Стиральная машина с длинным названием модели');
      final repo = WarrantyRepository(f.db);
      final c = await repo.createClaim(
        productId: p.id,
        serialNumber: 'WM-2026-000123',
        problem: 'Течёт',
        userId: f.owner.id,
      );
      await repo.changeStatus(claimId: c.id, to: 'refunded', userId: f.owner.id, note: 'Дефект подтверждён');
    });
    await pump(tester, const Size(360, 740));
    await tester.tap(find.textContaining('№1 ·'));
    await settle(tester);
    expect(find.text('Заявка №1'), findsOneWidget);
    expect(find.text('К чеку'), findsOneWidget, reason: 'refund decision points to the sales module');
    expect(find.text('Выдать клиенту'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });
}

/// Lets drift streams (real async) deliver, then rebuilds.
Future<void> settle(WidgetTester tester, {int rounds = 6}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}
