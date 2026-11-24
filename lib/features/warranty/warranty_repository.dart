// Data access and actions for warranty claims. WarrantyClaims is a service
// register (not money/stock), so it is written here directly with
// updatedAt + markDirty + audit. Stock effects go through StockService.
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../domain/errors.dart';
import '../../domain/services/stock_service.dart';
import '../../l10n/l10n.dart';
import 'warranty_logic.dart';

class ClaimRow {
  ClaimRow({
    required this.claim,
    this.productName,
    this.customerName,
    this.customerPhone,
    this.saleId,
    this.saleNumber,
    this.saleDate,
    this.warrantyUntil,
    this.userName,
  });
  final WarrantyClaim claim;
  final String? productName;
  final String? customerName;
  final String? customerPhone;
  final String? saleId;
  final int? saleNumber;
  final DateTime? saleDate;
  final DateTime? warrantyUntil;
  final String? userName;
}

class ClaimsFilter {
  const ClaimsFilter({this.group = ClaimGroup.all, this.query = '', this.limit = pageSize});
  static const pageSize = 100;
  final ClaimGroup group;
  final String query;
  final int limit;

  ClaimsFilter copyWith({ClaimGroup? group, String? query, int? limit}) =>
      ClaimsFilter(group: group ?? this.group, query: query ?? this.query, limit: limit ?? pageSize);

  @override
  bool operator ==(Object other) =>
      other is ClaimsFilter && other.group == group && other.query == query && other.limit == limit;
  @override
  int get hashCode => Object.hash(group, query, limit);
}

List<String> _likeVariants(String q) {
  final t = q.trim().replaceAll('%', '').replaceAll('_', '');
  if (t.isEmpty) return const [];
  final lower = t.toLowerCase();
  final cap = lower[0].toUpperCase() + lower.substring(1);
  return {t, lower, cap, t.toUpperCase()}.map((v) => '%$v%').toList();
}

const _claimSelect = '''
SELECT w.*, COALESCE(p.name, si.product_name) AS x_product, c.name AS x_customer, c.phone AS x_phone,
  s.id AS x_sale_id, s.number AS x_sale_number, s.created_at AS x_sale_date,
  si.warranty_until AS x_until, u.name AS x_user
FROM warranty_claims w
LEFT JOIN products p ON p.id = w.product_id
LEFT JOIN customers c ON c.id = w.customer_id
LEFT JOIN sale_items si ON si.id = w.sale_item_id
LEFT JOIN sales s ON s.id = si.sale_id
LEFT JOIN users u ON u.id = w.user_id
''';

ClaimRow _mapRow(AppDatabase db, QueryRow r) => ClaimRow(
  claim: db.warrantyClaims.map(r.data),
  productName: r.readNullable<String>('x_product'),
  customerName: r.readNullable<String>('x_customer'),
  customerPhone: r.readNullable<String>('x_phone'),
  saleId: r.readNullable<String>('x_sale_id'),
  saleNumber: r.readNullable<int>('x_sale_number'),
  saleDate: r.readNullable<DateTime>('x_sale_date'),
  warrantyUntil: r.readNullable<DateTime>('x_until'),
  userName: r.readNullable<String>('x_user'),
);

Set<ResultSetImplementation> _claimTables(AppDatabase db) => {
  db.warrantyClaims,
  db.products,
  db.customers,
  db.saleItems,
  db.sales,
  db.users,
};

Stream<List<ClaimRow>> watchClaims(AppDatabase db, ClaimsFilter f) {
  final parts = <String>['w.deleted_at IS NULL'];
  final vars = <Variable>[];
  final st = f.group.statuses;
  if (st != null) {
    parts.add('w.status IN (${List.filled(st.length, '?').join(', ')})');
    vars.addAll(st.map(Variable.withString));
  }
  final q = f.query.trim();
  if (q.isNotEmpty) {
    final or = <String>[];
    final n = int.tryParse(q.replaceAll('№', '').replaceAll('#', '').trim());
    if (n != null) {
      or.addAll(['w.number = ?', 's.number = ?']);
      vars.addAll([Variable.withInt(n), Variable.withInt(n)]);
    }
    for (final like in _likeVariants(q)) {
      or.addAll(['p.name LIKE ?', 'si.product_name LIKE ?', 'c.name LIKE ?', 'w.serial_number LIKE ?']);
      vars.addAll(List.filled(4, Variable.withString(like)));
    }
    final digits = q.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 3) {
      or.add('c.phone LIKE ?');
      vars.add(Variable.withString('%$digits%'));
    }
    parts.add('(${or.join(' OR ')})');
  }
  return db
      .customSelect(
        '$_claimSelect WHERE ${parts.join(' AND ')} ORDER BY w.created_at DESC, w.number DESC LIMIT ?',
        variables: [...vars, Variable.withInt(f.limit)],
        readsFrom: _claimTables(db),
      )
      .watch()
      .map((rows) => [for (final r in rows) _mapRow(db, r)]);
}

Stream<ClaimRow?> watchClaim(AppDatabase db, String id) => db
    .customSelect('$_claimSelect WHERE w.id = ?', variables: [Variable.withString(id)], readsFrom: _claimTables(db))
    .watch()
    .map((rows) => rows.isEmpty ? null : _mapRow(db, rows.first));

/// Status history from the audit log: (entry, user name).
Stream<List<(AuditEntry, String?)>> watchClaimHistory(AppDatabase db, String id) => db
    .customSelect(
      '''SELECT a.*, u.name AS x_user FROM audit_log a LEFT JOIN users u ON u.id = a.user_id
         WHERE a.entity = 'warranty_claim' AND a.entity_id = ? ORDER BY a.seq''',
      variables: [Variable.withString(id)],
      readsFrom: {db.auditLog, db.users},
    )
    .watch()
    .map((rows) => [for (final r in rows) (db.auditLog.map(r.data), r.readNullable<String>('x_user'))]);

final claimsProvider = StreamProvider.autoDispose.family<List<ClaimRow>, ClaimsFilter>(
  (ref, f) => watchClaims(ref.watch(databaseProvider), f),
);
final claimProvider = StreamProvider.autoDispose.family<ClaimRow?, String>(
  (ref, id) => watchClaim(ref.watch(databaseProvider), id),
);
final claimHistoryProvider = StreamProvider.autoDispose.family<List<(AuditEntry, String?)>, String>(
  (ref, id) => watchClaimHistory(ref.watch(databaseProvider), id),
);

/// A sale found by receipt number for the "new claim" form.
class SaleLookup {
  SaleLookup(this.sale, this.items, this.customer);
  final Sale sale;
  final List<SaleItem> items;
  final Customer? customer;
}

class WarrantyRepository {
  WarrantyRepository(this.db);
  final AppDatabase db;

  Future<SaleLookup?> findSale(int number) async {
    final sales =
        await (db.select(db.sales)
              ..where((s) => s.number.equals(number) & s.deletedAt.isNull())
              ..limit(1))
            .get();
    if (sales.isEmpty) return null;
    final s = sales.first;
    final items = await (db.select(db.saleItems)..where((i) => i.saleId.equals(s.id))).get();
    final customer = s.customerId == null
        ? null
        : await (db.select(db.customers)..where((c) => c.id.equals(s.customerId!))).getSingleOrNull();
    return SaleLookup(s, items, customer);
  }

  /// An open (received / in repair) claim for the same sold item, if any.
  Future<WarrantyClaim?> openClaimFor(String saleItemId) async {
    final list =
        await (db.select(db.warrantyClaims)
              ..where((w) => w.saleItemId.equals(saleItemId) & w.deletedAt.isNull() & w.status.isIn(WStatus.open))
              ..limit(1))
            .get();
    return list.isEmpty ? null : list.first;
  }

  Future<WarrantyClaim> createClaim({
    String? saleItemId,
    String? productId,
    String? customerId,
    String? serialNumber,
    required String problem,
    required String userId,
  }) async {
    if (problem.trim().isEmpty) throw BusinessException(L.current.warrantyDescribeProblem);
    if (saleItemId == null && productId == null) throw BusinessException(L.current.warrantySelectProduct);
    var pid = productId;
    if (saleItemId != null) {
      final si = await (db.select(db.saleItems)..where((i) => i.id.equals(saleItemId))).getSingleOrNull();
      if (si == null) throw BusinessException(L.current.warrantyReceiptLineNotFound);
      pid ??= si.productId;
    }
    final serial = serialNumber?.trim();
    return db.transaction(() async {
      final id = newId();
      final number = await db.nextNumber('warranty');
      final now = DateTime.now();
      await db
          .into(db.warrantyClaims)
          .insert(
            WarrantyClaimsCompanion.insert(
              id: id,
              number: number,
              saleItemId: Value(saleItemId),
              productId: Value(pid),
              customerId: Value(customerId),
              serialNumber: Value(serial == null || serial.isEmpty ? null : serial),
              problem: problem.trim(),
              userId: Value(userId),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await db.markDirty('warranty_claims', id);
      await db.audit(
        'warranty.create',
        userId: userId,
        entity: 'warranty_claim',
        entityId: id,
        details: '№$number; ${problem.trim()}', // l10n-ignore: audit details are stored in the DB
      );
      return (db.select(db.warrantyClaims)..where((w) => w.id.equals(id))).getSingle();
    });
  }

  /// Moves a claim along the workflow. When [writeOff] is set (replacement),
  /// one unit of the product is written off via [stock] in the same
  /// transaction — if that fails (no stock), the status is not changed.
  Future<void> changeStatus({
    required String claimId,
    required String to,
    required String userId,
    String? note,
    bool writeOff = false,
    StockService? stock,
  }) async {
    final c = await (db.select(db.warrantyClaims)..where((w) => w.id.equals(claimId))).getSingleOrNull();
    final l = L.current;
    if (c == null) throw BusinessException(l.warrantyClaimNotFound);
    if (!canTransition(c.status, to)) {
      throw BusinessException(l.warrantyCannotTransition(warrantyStatusLabel(c.status, l), warrantyStatusLabel(to, l)));
    }
    final text = note?.trim() ?? '';
    if (resolutionRequired(to) && text.isEmpty) throw BusinessException(l.warrantyEnterClaimResolution);
    if (writeOff) {
      if (to != WStatus.replaced) throw BusinessException(l.warrantyWriteOffOnlyReplace);
      if (c.productId == null) throw BusinessException(l.warrantyNoProductInClaim);
      if (stock == null) throw BusinessException(l.warrantyStockUnavailable);
    }
    await db.transaction(() async {
      // re-check inside the transaction (another terminal may have moved it)
      final fresh = await (db.select(db.warrantyClaims)..where((w) => w.id.equals(claimId))).getSingle();
      if (fresh.status != c.status) throw BusinessException(l.warrantyChangedByOther);
      if (writeOff) {
        // nested transaction (savepoint): rolled back together with the status.
        // The movement reason is stored in the DB and stays Russian (spec «Not translated»).
        await stock!.writeOff(
          productId: c.productId!,
          qty: 1,
          reason: 'Гарантийная замена', // l10n-ignore: stored movement reason
          userId: userId,
        );
      }
      await (db.update(db.warrantyClaims)..where((w) => w.id.equals(claimId))).write(
        WarrantyClaimsCompanion(
          status: Value(to),
          // Only the decision is the "resolution"; notes on other steps
          // (in repair, handed back) live in the audit history and must not
          // overwrite the decision text.
          resolution: resolutionRequired(to) ? Value(text) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await db.markDirty('warranty_claims', claimId);
      await db.audit(
        'warranty.status',
        userId: userId,
        entity: 'warranty_claim',
        entityId: claimId,
        // audit details are stored in the DB (not translated)
        details: '${c.status}→$to${writeOff ? '; списана 1 ед.' : ''}${text.isEmpty ? '' : '; $text'}', // l10n-ignore
      );
    });
  }
}

final warrantyRepositoryProvider = Provider((ref) => WarrantyRepository(ref.watch(databaseProvider)));
