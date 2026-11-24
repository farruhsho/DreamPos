// «Взаиморасчёты» on the supplier page, cancelled payments, corrections and
// receipt documents on the purchase order page.
import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/domain/services/receipt_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/domain/services/supplier_service.dart';
import 'package:dreampos/features/purchasing/orders_tab.dart';
import 'package:dreampos/features/purchasing/purchasing_logic.dart';
import 'package:dreampos/features/purchasing/purchasing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

class _LoggedIn extends SessionNotifier {
  _LoggedIn(this.u);
  final User u;
  @override
  Session? build() => Session(u);
}

Future<void> _settle(WidgetTester tester, [int rounds = 10]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _Seed {
  _Seed(this.f, this.supplierId, this.receiptId, this.transferId, this.cashId);
  final Fixture f;
  final String supplierId;
  final String receiptId;
  final String transferId;
  final String cashId;
  AppDatabase get db => f.db;
}

/// Supplier «Молочный завод»: receipt №1 (10 × 9 000 = 90 000), transfer
/// payment 30 000 and a cash payment 5 000 from the open shift.
Future<_Seed> _seed() async {
  final f = await Fixture.create();
  final repo = PurchasingRepo(f.db, StockService(f.db));
  final sid = await repo.saveSupplier(const SupplierInput(name: 'Молочный завод', phone: '+998901234567'));
  final milk = await f.product('Молоко 1л', price: 12000, cost: 9000, stock: 0);
  final doc = await ReceiptService(f.db, StockService(f.db), SupplierLedgerService(f.db)).post(
    lines: [ReceiptLineInput(productId: milk.id, qty: 10, unitCost: 9000)],
    supplierId: sid,
    supplierInvoice: 'НК-77',
    userId: f.owner.id,
  );
  final transfer = await repo.paySupplier(
    supplierId: sid,
    amount: 30000,
    method: 'transfer',
    note: 'п/п 5',
    userId: f.owner.id,
  );
  final cash = await repo.paySupplier(
    supplierId: sid,
    amount: 5000,
    method: 'cash',
    shiftId: f.shift.id,
    userId: f.owner.id,
  );
  return _Seed(f, sid, doc.id, transfer, cash);
}

Future<void> _pump(WidgetTester tester, _Seed s, Size size, {User? user}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(s.db),
        sessionProvider.overrideWith(() => _LoggedIn(user ?? s.f.owner)),
      ],
      child: const MaterialApp(home: PurchasingScreen()),
    ),
  );
  await _settle(tester);
  await tester.tap(find.text('Молочный завод'));
  await _settle(tester);
}

Future<void> _dispose(WidgetTester tester, _Seed s) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 100));
  await s.db.close();
}

Future<int> _balance(WidgetTester tester, _Seed s) async =>
    (await tester.runAsync(() => s.db.select(s.db.suppliers).getSingle()))!.balance;

void main() {
  testWidgets('desktop: ledger rows, balances and payment cancel with mandatory reason', (tester) async {
    final s = (await tester.runAsync(_seed))!;
    await _pump(tester, s, const Size(1440, 900));

    // Default tab is «Взаиморасчёты» with labelled operations.
    expect(find.text('Приход №1'), findsOneWidget);
    expect(find.text('Оплата (Перечисление)'), findsOneWidget);
    expect(find.text('Оплата (Наличные)'), findsOneWidget);
    expect(find.text('Сальдо на начало периода'), findsOneWidget);
    expect(find.text('Сальдо на конец периода'), findsOneWidget);
    expect(find.text('Приход (+)'), findsWidgets);
    expect(find.text('Расход (−)'), findsWidgets);
    // 90 000 − 30 000 − 5 000 = 55 000 closing.
    expect(find.textContaining(Money.format(55000)), findsWidgets);
    expect(find.text('Корректировка'), findsOneWidget, reason: 'owner has manageSettings');
    expect(find.text('Акт сверки'), findsOneWidget);
    expect(find.byTooltip('Отменить оплату'), findsNWidgets(2));

    // Cancel the transfer: the reason is mandatory.
    await tester.tap(find.byTooltip('Отменить оплату').first);
    await _settle(tester);
    expect(find.textContaining('Отменить оплату ${Money.format(30000)}'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Отменить оплату'));
    await _settle(tester);
    expect(find.text('Укажите причину'), findsOneWidget);
    expect(await _balance(tester, s), 55000, reason: 'nothing cancelled without a reason');

    await tester.enterText(find.widgetWithText(TextFormField, 'Причина отмены *'), 'Ошибка в сумме');
    // Double tap: the second tap is ignored while the first one runs.
    await tester.tap(find.widgetWithText(FilledButton, 'Отменить оплату'));
    await tester.tap(find.widgetWithText(FilledButton, 'Отменить оплату'), warnIfMissed: false);
    await _settle(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(await _balance(tester, s), 85000);
    final cancels = await tester.runAsync(
      () => (s.db.select(s.db.supplierLedger)..where((l) => l.kind.equals('payment_cancel'))).get(),
    );
    expect(cancels, hasLength(1), reason: 'double tap must not cancel twice');
    final p = await tester.runAsync(
      () => (s.db.select(s.db.supplierPayments)..where((x) => x.id.equals(s.transferId))).getSingle(),
    );
    expect(p!.cancelledAt, isNotNull);
    expect(p.cancelReason, 'Ошибка в сумме');

    // Ledger: the cancelled payment is marked, its cancel row shows the reason,
    // and it can no longer be cancelled.
    expect(find.text('Отмена оплаты'), findsOneWidget);
    expect(find.text('Ошибка в сумме'), findsOneWidget);
    expect(find.text('Отменена'), findsOneWidget);
    expect(find.byTooltip('Отменить оплату'), findsOneWidget);

    // Payments tab: struck through with «Отменена» and the reason.
    await tester.tap(find.text('Оплаты'));
    await _settle(tester);
    expect(find.text('Отменена'), findsOneWidget);
    expect(find.textContaining('Ошибка в сумме'), findsOneWidget);
    final struck = tester.widget<Text>(find.text(Money.format(30000)).first);
    expect(struck.style?.decoration, TextDecoration.lineThrough);
    expect(tester.takeException(), isNull);
    await _dispose(tester, s);
  });

  testWidgets('cash payment of a closed shift: service error is shown in the dialog', (tester) async {
    final s = (await tester.runAsync(() async {
      final s = await _seed();
      await ShiftService(s.db).close(shiftId: s.f.shift.id, userId: s.f.owner.id, countedCash: 5000);
      return s;
    }))!;
    await _pump(tester, s, const Size(1440, 900));
    // Rows are chronological: the cash payment is the last cancellable one.
    await tester.tap(find.byTooltip('Отменить оплату').last);
    await _settle(tester);
    expect(find.textContaining('только пока открыта её смена'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Причина отмены *'), 'Возврат');
    await tester.tap(find.widgetWithText(FilledButton, 'Отменить оплату'));
    await _settle(tester);
    expect(find.text('Смена оплаты закрыта — отмена невозможна'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget, reason: 'dialog stays open on error');
    expect(await _balance(tester, s), 55000);
    await tester.tap(find.text('Назад'));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    await _dispose(tester, s);
  });

  testWidgets('correction: sign choice + mandatory reason; hidden without manageSettings', (tester) async {
    final s = (await tester.runAsync(_seed))!;
    await _pump(tester, s, const Size(1440, 900));
    await tester.tap(find.text('Корректировка'));
    await _settle(tester);
    expect(find.text('Корректировка баланса'), findsOneWidget);
    await tester.tap(find.text('Уменьшить долг'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Сумма *'), '7000');
    await _settle(tester);
    expect(find.text('После корректировки: наш долг ${Money.format(48000)}'), findsOneWidget);
    await tester.tap(find.text('Провести корректировку'));
    await _settle(tester);
    expect(find.text('Укажите причину корректировки'), findsOneWidget);
    expect(await _balance(tester, s), 55000);
    await tester.enterText(find.widgetWithText(TextFormField, 'Причина *'), 'Скидка по акту');
    await tester.tap(find.text('Провести корректировку'));
    await _settle(tester);
    expect(await _balance(tester, s), 48000);
    expect(find.text('Корректировка баланса'), findsNothing);
    expect(find.text('Скидка по акту'), findsOneWidget, reason: 'reason shown in the ledger');
    await _dispose(tester, s);
  });

  testWidgets('manager (no manageSettings) does not see «Корректировка»', (tester) async {
    late User manager;
    final s = (await tester.runAsync(() async {
      final s = await _seed();
      manager = await AuthService(s.db).createUser(name: 'Менеджер', role: Role.manager, pin: '1357');
      return s;
    }))!;
    await _pump(tester, s, const Size(1440, 900), user: manager);
    expect(find.text('Приход №1'), findsOneWidget);
    expect(find.text('Корректировка'), findsNothing);
    expect(find.text('Акт сверки'), findsOneWidget);
    await _dispose(tester, s);
  });

  testWidgets('period filter: opening balance for the period and «Операций за период нет»', (tester) async {
    final s = (await tester.runAsync(() async {
      final s = await _seed();
      // Move the receipt row two months back: it becomes the opening balance.
      final old = DateTime.now().subtract(const Duration(days: 70));
      await (s.db.update(
        s.db.supplierLedger,
      )..where((l) => l.kind.equals('receipt'))).write(SupplierLedgerCompanion(createdAt: Value(old)));
      return s;
    }))!;
    await _pump(tester, s, const Size(1440, 900));
    expect(find.text('Приход №1'), findsOneWidget);
    await tester.tap(find.text('Этот месяц'));
    await _settle(tester);
    expect(find.text('Приход №1'), findsNothing);
    // Opening 90 000 (card + row), closing 55 000.
    expect(find.text(Money.format(90000)), findsNWidgets(2));
    expect(find.text('Оплата (Перечисление)'), findsOneWidget);
    await tester.tap(find.text('Прошлый месяц'));
    await _settle(tester);
    // Only the receipt could be there (or before it): no rows in any case.
    expect(find.text('Оплата (Перечисление)'), findsNothing);
    expect(tester.takeException(), isNull);
    await _dispose(tester, s);
  });

  testWidgets('empty ledger shows an empty state', (tester) async {
    final f = (await tester.runAsync(() async {
      final f = await Fixture.create();
      await PurchasingRepo(f.db, StockService(f.db)).saveSupplier(const SupplierInput(name: 'Молочный завод'));
      return f;
    }))!;
    final s = _Seed(f, '', '', '', '');
    await _pump(tester, s, const Size(1440, 900));
    expect(find.text('Взаиморасчётов ещё не было'), findsOneWidget);
    await _dispose(tester, s);
  });

  for (final size in const [Size(390, 844), Size(1024, 768)]) {
    testWidgets('ledger renders without overflow at ${size.width.toInt()}', (tester) async {
      final s = (await tester.runAsync(_seed))!;
      await _pump(tester, s, size);
      expect(find.text('Приход №1'), findsOneWidget);
      expect(find.text('Взаиморасчёты'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Оплаты'));
      await tester.pump();
      await tester.tap(find.text('Оплаты'));
      await _settle(tester);
      expect(find.textContaining('п/п 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _dispose(tester, s);
    });
  }

  testWidgets('PO detail lists its receipt documents; reversed ones excluded from received value', (tester) async {
    late String orderId;
    late String receiptId;
    final f = (await tester.runAsync(() async {
      final f = await Fixture.create();
      final repo = PurchasingRepo(f.db, StockService(f.db));
      final sid = await repo.saveSupplier(const SupplierInput(name: 'Молочный завод'));
      final milk = await f.product('Молоко 1л', price: 12000, cost: 9000, stock: 0);
      orderId = await repo.saveDraftOrder(
        supplierId: sid,
        lines: [PoLineInput(productId: milk.id, qty: 20, unitCost: 9000)],
      );
      await repo.markOrdered(orderId);
      final item = await f.db.select(f.db.purchaseOrderItems).getSingle();
      final r = await repo.receiveOrderDoc(orderId, [
        ReceiveLineInput(itemId: item.id, qty: 5),
      ], supplierInvoice: 'НК-1');
      receiptId = r.receipt.id;
      await repo.receiveOrder(orderId, [ReceiveLineInput(itemId: item.id, qty: 3)]);
      return f;
    }))!;
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(f.db), sessionProvider.overrideWith(() => _LoggedIn(f.owner))],
        child: MaterialApp(
          home: Scaffold(body: OrderDetail(orderId: orderId)),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('Приходы по заказу'), findsOneWidget);
    expect(find.text('Приход №1'), findsOneWidget);
    expect(find.text('Приход №2'), findsOneWidget);
    expect(find.text('Проведён'), findsNWidgets(2));
    expect(find.textContaining('накл. НК-1'), findsOneWidget);
    expect(find.text('Получено на сумму ${Money.format(72000)}'), findsOneWidget);

    await tester.runAsync(
      () => ReceiptService(f.db, StockService(f.db), SupplierLedgerService(f.db)).reverse(receiptId, reason: 'Брак'),
    );
    await _settle(tester);
    expect(find.text('Сторнирован'), findsOneWidget);
    expect(find.text('Получено на сумму ${Money.format(27000)}'), findsOneWidget);

    // Tapping a document opens it (does not throw).
    await tester.tap(find.text('Приход №2'));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    await f.db.close();
  });
}
