// Read-side providers of the POS screen (live drift streams + live quote).
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../domain/pricing.dart';
import 'cart_controller.dart';

/// Special category filter values.
const kFavorites = '__fav__';

typedef ProductFilter = ({String query, String? categoryId});

final posCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.categories)
        ..where((c) => c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.sortOrder), (c) => OrderingTerm.asc(c.name)]))
      .watch();
});

final posHasFavoritesProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.products)
        ..where((p) => p.deletedAt.isNull() & p.isActive.equals(true) & p.isFavorite.equals(true))
        ..limit(1))
      .watch()
      .map((l) => l.isNotEmpty);
});

/// Live product grid: filtered by text query and category / favorites.
final posProductsProvider =
    StreamProvider.family<List<Product>, ProductFilter>((ref, f) {
  final db = ref.watch(databaseProvider);
  final q = f.query.trim();
  final sel = db.select(db.products)
    ..where((p) => p.deletedAt.isNull() & p.isActive.equals(true));
  if (f.categoryId == kFavorites) {
    sel.where((p) => p.isFavorite.equals(true));
  } else if (f.categoryId != null) {
    sel.where((p) => p.categoryId.equals(f.categoryId!));
  }
  if (q.isNotEmpty) {
    final like = '%${q.replaceAll('%', '').replaceAll('_', '')}%';
    sel.where((p) =>
        p.name.like(like) | p.sku.like(like) | p.barcode.equals(q) | p.barcode.like('$q%'));
  }
  sel
    ..orderBy([
      (p) => OrderingTerm.desc(p.isFavorite),
      (p) => OrderingTerm.asc(p.name),
    ])
    ..limit(q.isEmpty ? 240 : 120);
  return sel.watch();
});

/// Live product rows for the products currently in the cart (stock warnings).
final cartProductsProvider = StreamProvider<Map<String, Product>>((ref) {
  final ids = ref.watch(cartProvider.select((c) => c.lines.map((l) => l.productId).toSet().join(',')));
  final db = ref.watch(databaseProvider);
  if (ids.isEmpty) return Stream.value(const {});
  final set = ids.split(',').toSet();
  return (db.select(db.products)..where((p) => p.id.isIn(set)))
      .watch()
      .map((l) => {for (final p in l) p.id: p});
});

/// Live attached customer (balances change after sales/payments).
final cartCustomerProvider = StreamProvider<Customer?>((ref) {
  final id = ref.watch(cartProvider.select((c) => c.customerId));
  if (id == null) return Stream.value(null);
  final db = ref.watch(databaseProvider);
  return (db.select(db.customers)..where((c) => c.id.equals(id))).watchSingleOrNull();
});

/// Active staff for the seller (consultant) selector.
final posActiveUsersProvider = StreamProvider<List<User>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.users)
        ..where((u) => u.deletedAt.isNull() & u.isActive.equals(true))
        ..orderBy([(u) => OrderingTerm.asc(u.name)]))
      .watch();
});

/// Live price quote of the cart — re-computed only when pricing inputs change.
/// Riverpod discards results of superseded computations, so a slow quote
/// never overwrites a newer one.
final cartQuoteProvider = FutureProvider<PricingResult?>((ref) async {
  ref.watch(cartProvider.select((c) => c.pricingSignature));
  final cart = ref.read(cartProvider);
  if (cart.isEmpty) return null;
  final svc = ref.watch(saleServiceProvider);
  return svc.quote(cart.toRequest(cashierId: ''));
});

/// Whether selling is possible: an open shift exists or shifts are not
/// required. While the shift stream is still loading we assume "yes" to
/// avoid flashing the banner; checkout validates the shift anyway.
final posCanSellProvider = Provider<bool>((ref) {
  final requireShift = ref.watch(settingProvider('require_shift')) != '0';
  if (!requireShift) return true;
  final shift = ref.watch(currentShiftProvider);
  if (shift.isLoading && !shift.hasValue) return true;
  return shift.value != null;
});
