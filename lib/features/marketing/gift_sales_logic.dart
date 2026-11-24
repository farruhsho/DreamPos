// Read side of gift card sale documents (D-023) for the marketing / POS UI.
// Writes go through GiftCardService (giftCardServiceProvider).
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../domain/services/gift_card_service.dart';

export '../../domain/services/gift_card_service.dart'
    show
        GiftCardService,
        GiftCardSaleRequest,
        GiftSalePaymentInput,
        GiftSaleResult,
        GiftSaleStatus,
        GiftSalesByMethod,
        giftSaleMethods,
        giftSalesByMethod;

const giftSaleStatusLabels = {GiftSaleStatus.completed: 'Проведена', GiftSaleStatus.voided: 'Аннулирована'};

/// List filter. [from] inclusive, [to] exclusive (both by createdAt);
/// [status] null = all; [giftCardId] limits to one card's documents.
class GiftSalesFilter {
  const GiftSalesFilter({this.from, this.to, this.status, this.giftCardId});
  final DateTime? from;
  final DateTime? to;
  final String? status;
  final String? giftCardId;

  @override
  bool operator ==(Object other) =>
      other is GiftSalesFilter &&
      other.from == from &&
      other.to == to &&
      other.status == status &&
      other.giftCardId == giftCardId;

  @override
  int get hashCode => Object.hash(from, to, status, giftCardId);
}

/// A row of the «Продажи сертификатов» list.
class GiftSaleRow {
  const GiftSaleRow({
    required this.sale,
    required this.code,
    required this.payments,
    this.cashierName,
    this.customerName,
  });
  final GiftCardSale sale;
  final String code;
  final List<GiftCardSalePayment> payments;
  final String? cashierName;
  final String? customerName;
}

Future<List<GiftSaleRow>> loadGiftSales(AppDatabase db, GiftSalesFilter f) async {
  final q = db.select(db.giftCardSales).join([
    innerJoin(db.giftCards, db.giftCards.id.equalsExp(db.giftCardSales.giftCardId)),
    leftOuterJoin(db.users, db.users.id.equalsExp(db.giftCardSales.cashierId)),
    leftOuterJoin(db.customers, db.customers.id.equalsExp(db.giftCardSales.customerId)),
  ]);
  final s = db.giftCardSales;
  q.where(s.deletedAt.isNull());
  if (f.from != null) q.where(s.createdAt.isBiggerOrEqualValue(f.from!));
  if (f.to != null) q.where(s.createdAt.isSmallerThanValue(f.to!));
  if (f.status != null) q.where(s.status.equals(f.status!));
  if (f.giftCardId != null) q.where(s.giftCardId.equals(f.giftCardId!));
  q.orderBy([OrderingTerm.desc(s.createdAt), OrderingTerm.desc(s.number)]);
  final rows = await q.get();
  final ids = [for (final r in rows) r.readTable(s).id];
  final pays = <String, List<GiftCardSalePayment>>{};
  if (ids.isNotEmpty) {
    for (final p in await (db.select(
      db.giftCardSalePayments,
    )..where((p) => p.saleId.isIn(ids) & p.deletedAt.isNull())).get()) {
      (pays[p.saleId] ??= []).add(p);
    }
  }
  return [
    for (final r in rows)
      GiftSaleRow(
        sale: r.readTable(s),
        code: r.readTable(db.giftCards).code,
        payments: pays[r.readTable(s).id] ?? const [],
        cashierName: r.readTableOrNull(db.users)?.name,
        customerName: r.readTableOrNull(db.customers)?.name,
      ),
  ];
}

/// Gift card sale documents, newest first, live.
final giftSalesProvider = StreamProvider.autoDispose.family<List<GiftSaleRow>, GiftSalesFilter>((ref, f) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect(
        'SELECT 1',
        readsFrom: {db.giftCardSales, db.giftCardSalePayments, db.giftCards, db.users, db.customers},
      )
      .watch()
      .asyncMap((_) => loadGiftSales(db, f));
});

/// One sale document by id.
final giftSaleProvider = StreamProvider.autoDispose.family<GiftCardSale?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.giftCardSales)..where((s) => s.id.equals(id))).watchSingleOrNull();
});

/// Payments of a sale document.
final giftSalePaymentsProvider = StreamProvider.autoDispose.family<List<GiftCardSalePayment>, String>((ref, saleId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.giftCardSalePayments)
        ..where((p) => p.saleId.equals(saleId) & p.deletedAt.isNull())
        ..orderBy([(p) => OrderingTerm.asc(p.createdAt)]))
      .watch();
});

/// The sale document of a card (null for cards issued before v4).
final giftSaleByCardProvider = StreamProvider.autoDispose.family<GiftCardSale?, String>((ref, giftCardId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.giftCardSales)
        ..where((s) => s.giftCardId.equals(giftCardId) & s.deletedAt.isNull())
        ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
        ..limit(1))
      .watchSingleOrNull();
});

/// Why the sale cannot be voided (tooltip), or null when it can. Does not
/// check the shift or permissions — the UI does.
final giftSaleVoidBlockReasonProvider = StreamProvider.autoDispose.family<String?, String>((ref, saleId) {
  final db = ref.watch(databaseProvider);
  final svc = ref.watch(giftCardServiceProvider);
  return db
      .customSelect('SELECT 1', readsFrom: {db.giftCardSales, db.giftCards, db.salePayments})
      .watch()
      .asyncMap((_) => svc.voidBlockReason(saleId));
});

/// Gift card advances for a period (payments report).
final giftSalesByMethodProvider = StreamProvider.autoDispose.family<GiftSalesByMethod, ({DateTime from, DateTime to})>((
  ref,
  p,
) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect('SELECT 1', readsFrom: {db.giftCardSales, db.giftCardSalePayments})
      .watch()
      .asyncMap((_) => giftSalesByMethod(db, p.from, p.to));
});

/// The sale document of a card with payments and names (null for cards
/// issued before v4), live. For the card detail.
final giftSaleRowByCardProvider = StreamProvider.autoDispose.family<GiftSaleRow?, String>((ref, giftCardId) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect(
        'SELECT 1',
        readsFrom: {db.giftCardSales, db.giftCardSalePayments, db.giftCards, db.users, db.customers},
      )
      .watch()
      .asyncMap((_) async {
        final rows = await loadGiftSales(db, GiftSalesFilter(giftCardId: giftCardId));
        return rows.isEmpty ? null : rows.first;
      });
});

/// One gift card by id, live (status / balance change after a void).
final giftCardByIdProvider = StreamProvider.autoDispose.family<GiftCard?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.giftCards)..where((g) => g.id.equals(id))).watchSingleOrNull();
});
