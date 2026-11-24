// User intents of the POS screen. Kept in one place so that the wide layout,
// the narrow cart page and the keyboard shortcuts all behave identically.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/widgets/pickers.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/services/sale_service.dart';
import 'cart_controller.dart';
import 'parked_carts.dart';
import 'pos_providers.dart';
import 'widgets/payment_dialog.dart';
import 'widgets/pos_dialogs.dart';
import 'widgets/sale_success_dialog.dart';

/// Whether selling is currently possible (open shift or shift not required).
bool posCanSell(WidgetRef ref) => ref.read(posCanSellProvider);

/// Outcome of Enter in the scanner field.
enum ScanOutcome { added, notFound, failed, cancelled }

class PosActions {
  PosActions(this.context, this.ref, {this.refocus, this.onSold});
  final BuildContext context;
  final WidgetRef ref;
  final VoidCallback? refocus;

  /// Called after a completed sale (the phone cart page closes itself).
  final VoidCallback? onSold;

  /// One payment flow at a time for the whole till: a double F12 / double
  /// tap must never open two payment dialogs for the same basket.
  static bool _paying = false;
  static bool get paying => _paying;

  CartController get _cart => ref.read(cartProvider.notifier);
  CartState get _state => ref.read(cartProvider);
  Session? get _session => ref.read(sessionProvider);
  AppDatabase get _db => ref.read(databaseProvider);

  void _done() => refocus?.call();

  void _err(Object e) {
    if (context.mounted) showError(context, e);
  }

  // ------------------------------------------------------------ adding

  /// Adds a product; weighted goods ask for weight unless [qty] is given.
  Future<bool> addProduct(Product p, {double? qty}) async =>
      await _add(p, qty: qty) == ScanOutcome.added;

  Future<ScanOutcome> _add(Product p, {double? qty}) async {
    if (!p.isActive || p.deletedAt != null) {
      _err('Товар «${p.name}» снят с продажи');
      return ScanOutcome.failed;
    }
    var q = qty;
    if (q == null && Qty.isFractional(p.unit)) {
      q = await askQty(context, title: p.name, unit: p.unit);
      if (q == null) {
        _done();
        return ScanOutcome.cancelled;
      }
    }
    final err = _cart.addProduct(p, qty: q ?? 1);
    if (err != null) {
      _err(err);
      return ScanOutcome.failed;
    }
    _done();
    return ScanOutcome.added;
  }

  /// Handles Enter in the search field (scanner or keyboard).
  Future<ScanOutcome> submitSearch(String text) async {
    final raw = text.trim();
    if (raw.isEmpty) return ScanOutcome.cancelled;
    final input = parseScanInput(raw);
    if (input == null) {
      _err('Неверный множитель. Пример: 3*4780000000011');
      return ScanOutcome.failed;
    }
    final byCode = await findByCode(_db, input.code);
    if (!context.mounted) return ScanOutcome.cancelled;
    if (byCode != null) {
      return _add(byCode, qty: input.hasMultiplier ? input.qty : null);
    }
    if (!looksLikeBarcode(input.code)) {
      final found = await searchProducts(_db, input.code, limit: 2);
      if (!context.mounted) return ScanOutcome.cancelled;
      if (found.length == 1) {
        return _add(found.first, qty: input.hasMultiplier ? input.qty : null);
      }
      if (found.length > 1) {
        _err('Найдено несколько товаров — выберите нужный в списке');
        return ScanOutcome.failed;
      }
    }
    _err('Товар «${input.code}» не найден');
    return ScanOutcome.notFound;
  }

  // ------------------------------------------------------------ lines

  Future<void> editQty(CartLine line) async {
    final q = await askQty(context, title: line.name, unit: line.unit, initial: line.qty);
    if (q != null) {
      final err = _cart.setQty(line.key, q);
      if (err != null) _err(err);
    }
    _done();
  }

  Future<void> editPrice(CartLine line) async {
    final s = _session;
    if (s == null || !s.can(Perm.editPrices)) {
      _err('Нет права изменять цены');
      return;
    }
    final price = await askPrice(context, line);
    if (price != null && price != line.unitPrice) {
      final err = _cart.setPrice(line.key, price);
      if (err != null) {
        _err(err);
      } else {
        await _db.audit('pos.price_edit',
            userId: s.user.id,
            entity: 'product',
            entityId: line.productId,
            details: '${line.name}: ${line.unitPrice} -> $price (прайс ${line.basePrice})');
      }
    }
    _done();
  }

  /// Decides whether the manual discounts of [next] (the cart as it would
  /// be after the change) are allowed for the session user. Both the single
  /// discount ([requestPercent] of its own base) and the cumulative manual
  /// share of the whole cart (as `SaleService.checkout` measures it) must fit
  /// the user's limit; otherwise a manager/owner PIN is asked.
  /// Returns (ok, approverId) — approverId is null when no approval needed.
  Future<(bool, String?)> _authorize(CartState next, double requestPercent, String what) async {
    final s = _session;
    if (s == null) return (false, null);
    double cumulative;
    try {
      cumulative = await cartManualDiscountPercent(ref.read(saleServiceProvider), next);
    } catch (e) {
      _err(e);
      return (false, null);
    }
    final need = requestPercent > cumulative ? requestPercent : cumulative;
    if (need <= 0 || withinDiscountLimit(need, s.user.maxDiscountPercent)) return (true, null);

    // an approval already given for this cart may still cover it
    final existing = next.approverId;
    if (existing != null) {
      final u = await (_db.select(_db.users)..where((t) => t.id.equals(existing)))
          .getSingleOrNull();
      if (u != null && u.isActive && u.deletedAt == null && approvalError(u, s.user, need) == null) {
        return (true, u.id);
      }
    }
    if (!context.mounted) return (false, null);
    final approver =
        await askManagerApproval(context, cashier: s.user, percent: need, what: what);
    if (approver == null) return (false, null);
    await _db.audit('discount.approve',
        userId: approver.id,
        entity: 'user',
        entityId: s.user.id,
        details: '$what; ${need.toStringAsFixed(2)}%; кассир ${s.user.name}; '
            'подтвердил ${approver.name}');
    return (true, approver.id);
  }

  Future<void> lineDiscount(CartLine line) async {
    final s = _session;
    if (s == null) return;
    final res = await askDiscount(
      context,
      title: 'Скидка на позицию',
      base: line.gross,
      limitPercent: s.user.maxDiscountPercent,
      currentAmount: line.discountAmount,
      currentPercent: line.discountPercent,
    );
    if (res == null || !context.mounted) return _done();
    final pct = res.percent > 0 ? res.percent : discountPercentOf(res.amount, line.gross);
    final next = _state.withLineDiscount(line.key, amount: res.amount, percent: res.percent);
    final (ok, approver) = await _authorize(next, pct, 'Скидка на «${line.name}»');
    if (!ok) return _done();
    final err = _cart.setLineDiscount(line.key,
        amount: res.amount, percent: res.percent, approvedBy: approver);
    if (err != null) {
      _err(err);
    } else if (approver != null) {
      _cart.setApprover(approver);
    }
    _done();
  }

  Future<void> orderDiscount() async {
    final s = _session;
    if (s == null) return;
    final st = _state;
    if (st.isEmpty) return _err('Чек пуст');
    // base: amount after line discounts (before order-level discounts)
    final quote = ref.read(cartQuoteProvider).value;
    final base = quote == null
        ? st.grossTotal
        : quote.lines.fold<int>(
            0, (a, l) => a + l.line.gross - l.autoDiscount - l.manualDiscount);
    final res = await askDiscount(
      context,
      title: 'Скидка на чек',
      base: base,
      limitPercent: s.user.maxDiscountPercent,
      currentAmount: st.orderDiscountAmount,
      currentPercent: st.orderDiscountPercent,
    );
    if (res == null || !context.mounted) return _done();
    final pct = res.percent > 0 ? res.percent : discountPercentOf(res.amount, base);
    final next = _state.withOrderDiscount(amount: res.amount, percent: res.percent);
    final (ok, approver) = await _authorize(next, pct, 'Скидка на чек');
    if (!ok) return _done();
    final err =
        _cart.setOrderDiscount(amount: res.amount, percent: res.percent, approvedBy: approver);
    if (err != null) {
      _err(err);
    } else if (approver != null) {
      _cart.setApprover(approver);
    }
    _done();
  }

  void removeLine(CartLine line) {
    _cart.remove(line.key);
    _done();
  }

  // ------------------------------------------------------------ cart level

  Future<void> attachCustomer() async {
    final c = await pickCustomer(context);
    if (c != null) _cart.setCustomer(c);
    _done();
  }

  void detachCustomer() {
    _cart.setCustomer(null);
    _done();
  }

  Future<void> enterPromo() async {
    final code = await promptText(context,
        title: 'Промокод', label: 'Код', initial: _state.promoCode, required: false);
    if (code != null) _cart.setPromoCode(code);
    _done();
  }

  Future<void> chooseSeller() async {
    final id = await pickSeller(context, current: _state.sellerId);
    if (id != null) _cart.setSeller(id.isEmpty ? null : id);
    _done();
  }

  Future<void> clearCart() async {
    if (_state.isEmpty) return;
    final ok = await confirm(context,
        title: 'Очистить чек?',
        message: 'Все ${_state.lines.length} поз. будут удалены из чека.',
        ok: 'Очистить',
        destructive: true);
    if (ok) {
      _cart.clear();
      final s = _session;
      if (s != null) await _db.audit('pos.cart_clear', userId: s.user.id);
    }
    _done();
  }

  // ------------------------------------------------------------ parking

  Future<void> park() async {
    if (_state.isEmpty) {
      _err('Нечего откладывать — чек пуст');
      return;
    }
    final note = await promptText(context,
        title: 'Отложить чек', label: 'Комментарий (имя покупателя и т.п.)', required: false);
    if (note == null) return _done();
    try {
      await ref
          .read(parkedCartsProvider.notifier)
          .park(_state, note: note, cashierName: _session?.user.name);
      _cart.clear();
      if (context.mounted) showSuccess(context, 'Чек отложен (F9 — список отложенных)');
    } catch (e) {
      _err(e);
    }
    _done();
  }

  Future<void> showParked() async {
    final p = await showParkedList(context);
    if (p == null) return _done();
    if (_state.isNotEmpty) {
      // never lose the current basket: park it in exchange
      await ref
          .read(parkedCartsProvider.notifier)
          .park(_state, note: 'Автоматически отложен', cashierName: _session?.user.name);
    }
    var cart = p.cart;
    var repriced = 0;
    try {
      // catalogue prices may have changed while the receipt was parked
      final ids = cart.lines.map((l) => l.productId).toSet();
      final rows = await (_db.select(_db.products)..where((t) => t.id.isIn(ids))).get();
      (cart, repriced) = cart.withCatalogPrices({for (final r in rows) r.id: r});
    } catch (_) {
      // never lose the basket because of a lookup problem: restore as parked
    }
    _cart.restore(cart);
    if (context.mounted) {
      showSuccess(
          context,
          repriced > 0
              ? 'Чек восстановлен. Цены обновлены по прайсу: $repriced поз.'
              : 'Чек восстановлен');
    }
    _done();
  }

  // ------------------------------------------------------------ shift & pay

  Future<void> openShift() async {
    final s = _session;
    if (s == null || !s.can(Perm.openCloseShift)) {
      _err('Нет права открывать смену — обратитесь к менеджеру');
      return;
    }
    final ok = await showOpenShiftDialog(context);
    if (ok && context.mounted) showSuccess(context, 'Смена открыта. Можно продавать');
    _done();
  }

  Future<void> pay() async {
    if (_paying) return;
    _paying = true;
    try {
      await _pay();
    } finally {
      _paying = false;
    }
  }

  Future<void> _pay() async {
    final s = _session;
    var st = _state;
    if (s == null) return;
    if (st.isEmpty) {
      _err('Чек пуст — добавьте товары');
      return;
    }
    if (!s.can(Perm.sell)) {
      _err('Нет права продавать');
      return;
    }
    if (!posCanSell(ref)) {
      _err('Смена не открыта. Откройте смену, чтобы продавать');
      return;
    }
    final shift = ref.read(currentShiftProvider).value;
    try {
      // fresh quote — exactly what checkout will charge
      final quote = await ref.read(saleServiceProvider).quote(st.toRequest(cashierId: s.user.id));
      if (st.promoCode != null && quote.promoCodeValid != true) {
        _err('Промокод «${st.promoCode}» недействителен — удалите или исправьте его');
        return;
      }
      // The share of manual discounts may have grown after qty changes or
      // removed lines: re-check the cumulative limit now (manager PIN if
      // needed) instead of failing inside the payment dialog.
      if (st.hasManualDiscounts) {
        final (ok, approver) = await _authorize(st, 0, 'Ручные скидки в чеке');
        if (!ok) {
          _err('Ручные скидки превышают ваш лимит — нужно подтверждение менеджера '
              'или уменьшите скидку');
          return;
        }
        if (approver != null && approver != st.approverId) {
          _cart.setApprover(approver);
          st = _state;
        }
      }
      final customer = st.customerId == null
          ? null
          : await (_db.select(_db.customers)..where((c) => c.id.equals(st.customerId!)))
              .getSingleOrNull();
      if (!context.mounted) return;
      final res = await showDialog<CheckoutResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PaymentDialog(
          cart: st,
          total: quote.total,
          cashierId: s.user.id,
          shiftId: shift?.id,
          customer: customer,
        ),
      );
      if (res == null) return _done();
      _cart.clear();
      if (context.mounted) await showSaleSuccess(context, res);
      onSold?.call();
    } catch (e) {
      _err(e);
    }
    _done();
  }
}
