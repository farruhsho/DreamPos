import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../errors.dart';
import '../pricing.dart';
import 'stock_service.dart';

const paymentMethods = ['cash', 'card', 'transfer', 'bonus', 'debt', 'gift_card'];

String paymentMethodLabel(String m) => switch (m) {
      'cash' => 'Наличные',
      'card' => 'Карта',
      'transfer' => 'Перевод',
      'bonus' => 'Бонусы',
      'debt' => 'В долг',
      'gift_card' => 'Сертификат',
      _ => m,
    };

/// Gift card codes are stored uppercase without separators.
String normalizeGiftCode(String raw) =>
    raw.toUpperCase().replaceAll(RegExp(r'[\s\-_]'), '');

class CheckoutLine {
  CheckoutLine({
    required this.productId,
    required this.qty,
    required this.unitPrice,
    this.manualDiscount = 0,
  });
  final String productId;
  final double qty;
  /// Price used at the till (may be edited by users with editPrices).
  final int unitPrice;
  final int manualDiscount;
}

class PaymentInput {
  PaymentInput(this.method, this.amount, {this.reference});
  final String method;
  /// For cash this is the TENDERED amount (change is computed).
  final int amount;
  final String? reference;
}

class CheckoutRequest {
  CheckoutRequest({
    required this.lines,
    required this.payments,
    required this.cashierId,
    this.shiftId,
    this.registerId,
    this.sellerId,
    this.customerId,
    this.promoCode,
    this.manualOrderDiscountPercent = 0,
    this.manualOrderDiscountAmount = 0,
    this.note,
    this.debtDueDate,
    this.now,
    this.discountApprovedBy,
  });

  final List<CheckoutLine> lines;
  final List<PaymentInput> payments;
  final String cashierId;
  final String? shiftId;
  final String? registerId;
  final String? sellerId;
  final String? customerId;
  final String? promoCode;
  final double manualOrderDiscountPercent;
  final int manualOrderDiscountAmount;
  final String? note;
  final DateTime? debtDueDate;
  final DateTime? now;
  /// User id of a manager who approved manual discounts above the cashier's
  /// limit (verified by PIN in the UI). The service re-checks the limit.
  final String? discountApprovedBy;
}

class CheckoutResult {
  CheckoutResult(this.sale, this.changeDue);
  final Sale sale;
  final int changeDue;
}

class ReturnLineInput {
  ReturnLineInput(this.saleItemId, this.qty);
  final String saleItemId;
  final double qty;
}

/// Loyalty program settings (settings table):
///  loyalty_enabled=1, loyalty_earn_percent=2, loyalty_max_redeem_percent=50
class LoyaltyConfig {
  LoyaltyConfig({this.enabled = false, this.earnPercent = 0, this.maxRedeemPercent = 0});
  final bool enabled;
  final double earnPercent;
  final double maxRedeemPercent;

  static Future<LoyaltyConfig> load(AppDatabase db) async => LoyaltyConfig(
        enabled: await db.getSetting('loyalty_enabled') == '1',
        earnPercent: double.tryParse(await db.getSetting('loyalty_earn_percent') ?? '') ?? 0,
        maxRedeemPercent:
            double.tryParse(await db.getSetting('loyalty_max_redeem_percent') ?? '') ?? 100,
      );
}

class SaleService {
  SaleService(this.db) : stock = StockService(db);
  final AppDatabase db;
  final StockService stock;

  Future<List<PromoRule>> activePromotions([DateTime? at]) async {
    final now = at ?? DateTime.now();
    final rows = await (db.select(db.promotions)
          ..where((p) => p.isActive.equals(true) & p.deletedAt.isNull()))
        .get();
    return [
      for (final p in rows)
        if ((p.startsAt == null || !now.isBefore(p.startsAt!)) &&
            (p.endsAt == null || now.isBefore(p.endsAt!)))
          PromoRule(
            id: p.id,
            name: p.name,
            type: p.type,
            value: p.value,
            targetId: p.targetId,
            code: p.code,
            minOrderTotal: p.minOrderTotal,
            buyQty: p.buyQty,
            getQty: p.getQty,
          )
    ];
  }

  /// Prices a cart exactly the way checkout will.
  Future<PricingResult> quote(CheckoutRequest r, {Map<String, Product>? productCache}) async {
    final products = productCache ?? await _loadProducts(r.lines.map((l) => l.productId));
    final promos = await activePromotions(r.now);
    final customerPct = await _customerPct(r.customerId);
    return _price(r, products, promos, customerPct);
  }

  Future<double> _customerPct(String? customerId) async {
    if (customerId == null) return 0;
    final c = await (db.select(db.customers)..where((t) => t.id.equals(customerId)))
        .getSingleOrNull();
    return c?.discountPercent ?? 0;
  }

  PricingResult _price(CheckoutRequest r, Map<String, Product> products, List<PromoRule> promos,
      double customerPct, {bool includeManual = true}) {
    return PricingEngine.price(
      lines: [
        for (var i = 0; i < r.lines.length; i++)
          PricingLine(
            key: '$i',
            productId: r.lines[i].productId,
            categoryId: products[r.lines[i].productId]?.categoryId,
            qty: r.lines[i].qty,
            unitPrice: r.lines[i].unitPrice,
            vatPercent: products[r.lines[i].productId]?.vatPercent ?? 0,
            manualDiscount: includeManual ? r.lines[i].manualDiscount : 0,
          ),
      ],
      promotions: promos,
      customerDiscountPercent: customerPct,
      promoCode: r.promoCode,
      manualOrderDiscountPercent: includeManual ? r.manualOrderDiscountPercent : 0,
      manualOrderDiscountAmount: includeManual ? r.manualOrderDiscountAmount : 0,
    );
  }

  Future<Map<String, Product>> _loadProducts(Iterable<String> ids) async {
    final list = await (db.select(db.products)..where((p) => p.id.isIn(ids.toSet())))
        .get();
    return {for (final p in list) p.id: p};
  }

  /// The single entry point that records a sale. Everything happens in one
  /// transaction: either the whole sale is stored or nothing is.
  Future<CheckoutResult> checkout(CheckoutRequest r) async {
    if (r.lines.isEmpty) throw BusinessException('Чек пуст');
    for (final l in r.lines) {
      if (l.qty <= 0 || l.qty.isNaN) {
        throw BusinessException('Количество должно быть больше нуля');
      }
      if (l.unitPrice < 0) throw BusinessException('Цена не может быть отрицательной');
    }
    for (final p in r.payments) {
      if (p.amount < 0) throw BusinessException('Сумма оплаты не может быть отрицательной');
      if (!paymentMethods.contains(p.method)) {
        throw BusinessException('Неизвестный способ оплаты: ${p.method}');
      }
    }
    final now = r.now ?? DateTime.now();

    return db.transaction(() async {
      // --- shift
      final requireShift = (await db.getSetting('require_shift')) != '0';
      if (requireShift) {
        if (r.shiftId == null) throw BusinessException('Откройте смену, чтобы продавать');
        final shift = await (db.select(db.shifts)..where((s) => s.id.equals(r.shiftId!)))
            .getSingleOrNull();
        if (shift == null || shift.status != 'open') {
          throw BusinessException('Смена закрыта. Откройте новую смену');
        }
      }

      final products = await _loadProducts(r.lines.map((l) => l.productId));
      for (final l in r.lines) {
        final p = products[l.productId];
        if (p == null || p.deletedAt != null) {
          throw BusinessException('Товар не найден или удалён');
        }
      }
      final promos = await activePromotions(r.now);
      final customerPct = await _customerPct(r.customerId);
      final priced = _price(r, products, promos, customerPct);
      if (r.promoCode != null && r.promoCode!.trim().isNotEmpty && priced.promoCodeValid != true) {
        throw BusinessException('Промокод недействителен');
      }
      final total = priced.total;

      // --- manual discount limit (defense in depth; UI also checks).
      // Manual part = total discount with manual inputs − without them.
      final automatic = _price(r, products, promos, customerPct, includeManual: false);
      final manualTotal = priced.discountTotal - automatic.discountTotal;
      if (manualTotal > 0 && priced.subtotal > 0) {
        final pct = manualTotal * 100 / priced.subtotal;
        Future<double> limitOf(String id) async =>
            (await (db.select(db.users)..where((u) => u.id.equals(id))).getSingleOrNull())
                ?.maxDiscountPercent ??
            0;
        var limit = await limitOf(r.cashierId);
        if (r.discountApprovedBy != null) {
          final a = await limitOf(r.discountApprovedBy!);
          if (a > limit) limit = a;
        }
        if (pct > limit + 0.01) {
          throw BusinessException(
              'Ручная скидка ${pct.toStringAsFixed(1)}% превышает допустимую (${limit.toStringAsFixed(0)}%). Нужно подтверждение менеджера',
              code: 'discount_limit');
        }
        if (r.discountApprovedBy != null) {
          await db.audit('discount.override',
              userId: r.discountApprovedBy, entity: 'cashier', entityId: r.cashierId,
              details: 'manual=${pct.toStringAsFixed(1)}%');
        }
      }

      // --- customer
      Customer? customer;
      if (r.customerId != null) {
        customer = await (db.select(db.customers)..where((c) => c.id.equals(r.customerId!)))
            .getSingleOrNull();
        if (customer == null) throw BusinessException('Клиент не найден');
      }

      // --- payments validation
      final byMethod = <String, int>{};
      for (final p in r.payments) {
        if (p.amount == 0) continue;
        byMethod[p.method] = (byMethod[p.method] ?? 0) + p.amount;
      }
      final nonCash = byMethod.entries
          .where((e) => e.key != 'cash')
          .fold(0, (s, e) => s + e.value);
      final cashTendered = byMethod['cash'] ?? 0;
      if (nonCash > total) {
        throw BusinessException('Безналичная оплата превышает сумму чека');
      }
      final cashNeeded = total - nonCash;
      if (cashTendered < cashNeeded) {
        throw BusinessException(
            'Недостаточно оплаты: не хватает ${Money.format(cashNeeded - cashTendered)}');
      }
      final change = cashTendered - cashNeeded;
      final cashApplied = cashNeeded;

      final loyalty = await LoyaltyConfig.load(db);
      final bonusPay = byMethod['bonus'] ?? 0;
      if (bonusPay > 0) {
        if (customer == null) throw BusinessException('Для оплаты бонусами выберите клиента');
        if (!loyalty.enabled) throw BusinessException('Бонусная программа выключена');
        if (bonusPay > customer.bonusBalance) {
          throw BusinessException('Недостаточно бонусов: доступно ${Money.format(customer.bonusBalance)}');
        }
        final maxRedeem = Money.percent(total, loyalty.maxRedeemPercent);
        if (bonusPay > maxRedeem) {
          throw BusinessException('Бонусами можно оплатить не более ${Money.format(maxRedeem)}');
        }
      }
      final debtPay = byMethod['debt'] ?? 0;
      if (debtPay > 0) {
        if (customer == null) throw BusinessException('Для продажи в долг выберите клиента');
        if (customer.debtLimit > 0 && customer.debtBalance + debtPay > customer.debtLimit) {
          throw BusinessException(
              'Превышен кредитный лимит клиента (${Money.format(customer.debtLimit)}). '
              'Текущий долг: ${Money.format(customer.debtBalance)}');
        }
        if (customer.debtLimit == 0 && (await db.getSetting('debt_requires_limit')) == '1') {
          throw BusinessException('Клиенту не открыт кредит');
        }
      }
      final giftPays = r.payments.where((p) => p.method == 'gift_card' && p.amount > 0).toList();
      final giftCardsUsed = <GiftCard, int>{};
      for (final gp in giftPays) {
        final code = normalizeGiftCode(gp.reference ?? '');
        final card = await (db.select(db.giftCards)
              ..where((g) => g.code.equals(code) & g.deletedAt.isNull()))
            .getSingleOrNull();
        if (card == null) throw BusinessException('Сертификат $code не найден');
        if (card.status != 'active') throw BusinessException('Сертификат $code не активен');
        if (card.expiresAt != null && now.isAfter(card.expiresAt!)) {
          throw BusinessException('Срок действия сертификата $code истёк');
        }
        if (card.balance < gp.amount) {
          throw BusinessException('На сертификате $code только ${Money.format(card.balance)}');
        }
        giftCardsUsed[card] = gp.amount;
      }

      // --- create sale
      final saleId = newId();
      final number = await db.nextNumber('sale');
      final costTotal = r.lines.fold<int>(
          0, (s, l) => s + (products[l.productId]!.costPrice * l.qty).round());
      final bonusBase = total - bonusPay;
      final bonusEarned = (customer != null && loyalty.enabled && loyalty.earnPercent > 0)
          ? Money.percent(max(0, bonusBase), loyalty.earnPercent)
          : 0;

      await db.into(db.sales).insert(SalesCompanion.insert(
            id: saleId,
            number: number,
            shiftId: Value(r.shiftId),
            registerId: Value(r.registerId),
            cashierId: Value(r.cashierId),
            sellerId: Value(r.sellerId ?? r.cashierId),
            customerId: Value(r.customerId),
            status: 'completed',
            subtotal: priced.subtotal,
            discountTotal: Value(priced.discountTotal),
            total: total,
            costTotal: Value(costTotal),
            vatTotal: Value(priced.vatTotal),
            paidTotal: Value(total),
            changeDue: Value(change),
            bonusEarned: Value(bonusEarned),
            promoCode: Value(r.promoCode?.trim().isEmpty ?? true ? null : r.promoCode!.trim()),
            note: Value(r.note),
            createdAt: Value(now),
            updatedAt: Value(now),
          ));

      for (var i = 0; i < r.lines.length; i++) {
        final l = r.lines[i];
        final p = products[l.productId]!;
        final pl = priced.byKey('$i')!;
        await db.into(db.saleItems).insert(SaleItemsCompanion.insert(
              id: newId(),
              saleId: saleId,
              productId: p.id,
              productName: p.name,
              qty: Qty.round(l.qty),
              unitPrice: l.unitPrice,
              unitCost: Value(p.costPrice),
              discount: Value(pl.discount),
              total: pl.total,
              vatPercent: Value(p.vatPercent),
              warrantyUntil: Value(p.warrantyMonths > 0
                  ? DateTime(now.year, now.month + p.warrantyMonths, now.day)
                  : null),
              createdAt: Value(now),
              updatedAt: Value(now),
            ));
      }
      // aggregate qty per product for the stock check
      final qtyByProduct = <String, double>{};
      for (final l in r.lines) {
        qtyByProduct[l.productId] = (qtyByProduct[l.productId] ?? 0) + l.qty;
      }
      for (final e in qtyByProduct.entries) {
        await stock.move(
          productId: e.key,
          delta: -e.value,
          type: 'sale',
          refType: 'sale',
          refId: saleId,
          userId: r.cashierId,
          enforce: true,
        );
      }

      // payments: store APPLIED amounts (cash minus change)
      Future<void> addPayment(String method, int amount, [String? ref]) =>
          db.into(db.salePayments).insert(SalePaymentsCompanion.insert(
                id: newId(),
                saleId: saleId,
                method: method,
                amount: amount,
                reference: Value(ref),
                createdAt: Value(now),
                updatedAt: Value(now),
              ));
      if (cashApplied > 0) await addPayment('cash', cashApplied);
      for (final m in ['card', 'transfer', 'bonus', 'debt']) {
        if ((byMethod[m] ?? 0) > 0) await addPayment(m, byMethod[m]!);
      }
      for (final e in giftCardsUsed.entries) {
        await addPayment('gift_card', e.value, e.key.code);
        final newBal = e.key.balance - e.value;
        await (db.update(db.giftCards)..where((g) => g.id.equals(e.key.id))).write(
            GiftCardsCompanion(
                balance: Value(newBal),
                status: Value(newBal == 0 ? 'used' : 'active'),
                updatedAt: Value(now)));
      }

      // customer: stats, debt, bonus
      if (customer != null) {
        var debt = customer.debtBalance;
        var bonus = customer.bonusBalance;
        Future<void> ledger(String kind, int amount, int after, {DateTime? due}) =>
            db.into(db.customerLedger).insert(CustomerLedgerCompanion.insert(
                  id: newId(),
                  customerId: customer!.id,
                  kind: kind,
                  amount: amount,
                  balanceAfter: after,
                  refType: const Value('sale'),
                  refId: Value(saleId),
                  userId: Value(r.cashierId),
                  shiftId: Value(r.shiftId),
                  dueDate: Value(due),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ));
        if (debtPay > 0) {
          debt += debtPay;
          await ledger('debt_sale', debtPay, debt, due: r.debtDueDate);
        }
        if (bonusPay > 0) {
          bonus -= bonusPay;
          await ledger('bonus_spend', -bonusPay, bonus);
        }
        if (bonusEarned > 0) {
          bonus += bonusEarned;
          await ledger('bonus_earn', bonusEarned, bonus);
        }
        await (db.update(db.customers)..where((c) => c.id.equals(customer!.id))).write(
            CustomersCompanion(
                debtBalance: Value(debt),
                bonusBalance: Value(bonus),
                totalSpent: Value(customer.totalSpent + total),
                visits: Value(customer.visits + 1),
                lastVisitAt: Value(now),
                updatedAt: Value(now)));
        await db.markDirty('customers', customer.id);
      }

      if (priced.discountTotal > 0) {
        await db.audit('sale.discount',
            userId: r.cashierId,
            entity: 'sale',
            entityId: saleId,
            details: 'discount=${priced.discountTotal}; promos=${priced.appliedPromotions.join(", ")}');
      }
      await db.markDirty('sales', saleId);
      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();
      return CheckoutResult(sale, change);
    });
  }

  /// Partial or full return. Refund amount per line is proportional to the
  /// line's paid total; the last unit returned takes the rounding remainder.
  Future<Return> returnItems({
    required String saleId,
    required List<ReturnLineInput> lines,
    required String refundMethod,
    required String userId,
    String? shiftId,
    String? reason,
    bool restock = true,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final wanted = lines.where((l) => l.qty > 0).toList();
    if (wanted.isEmpty) throw BusinessException('Выберите товары для возврата');
    return db.transaction(() async {
      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId)))
          .getSingleOrNull();
      if (sale == null) throw BusinessException('Чек не найден');
      if (sale.status == 'voided' || sale.status == 'returned') {
        throw BusinessException('По этому чеку уже оформлен полный возврат');
      }
      final days = int.tryParse(await db.getSetting('return_days') ?? '') ?? 14;
      if (days > 0 && at.difference(sale.createdAt).inDays > days) {
        throw BusinessException('Срок возврата ($days дн.) истёк');
      }
      final items = await (db.select(db.saleItems)..where((i) => i.saleId.equals(saleId))).get();
      final byId = {for (final i in items) i.id: i};

      final returnId = newId();
      var total = 0;
      final rows = <ReturnItemsCompanion>[];
      for (final l in wanted) {
        final it = byId[l.saleItemId];
        if (it == null) throw BusinessException('Позиция не из этого чека');
        final available = Qty.round(it.qty - it.returnedQty);
        if (l.qty > available + 1e-9) {
          throw BusinessException('«${it.productName}»: можно вернуть не более ${Qty.format(available)}');
        }
        final isLast = (available - l.qty).abs() < 1e-9;
        final alreadyRefunded = (it.total * it.returnedQty / it.qty).round();
        final amount = isLast ? it.total - alreadyRefunded : (it.total * l.qty / it.qty).round();
        total += amount;
        rows.add(ReturnItemsCompanion.insert(
          id: newId(),
          returnId: returnId,
          saleItemId: it.id,
          productId: it.productId,
          qty: l.qty,
          amount: amount,
          createdAt: Value(at),
          updatedAt: Value(at),
        ));
        await (db.update(db.saleItems)..where((t) => t.id.equals(it.id))).write(
            SaleItemsCompanion(returnedQty: Value(Qty.round(it.returnedQty + l.qty)), updatedAt: Value(at)));
        if (restock) {
          await stock.move(
            productId: it.productId,
            delta: l.qty,
            type: 'return',
            refType: 'return',
            refId: returnId,
            userId: userId,
            unitCost: it.unitCost,
            reason: reason,
          );
        }
      }

      // validate refund method against what was paid
      final payments = await (db.select(db.salePayments)..where((p) => p.saleId.equals(saleId))).get();
      final paidBy = <String, int>{};
      for (final p in payments) {
        paidBy[p.method] = (paidBy[p.method] ?? 0) + p.amount;
      }
      Customer? customer;
      if (sale.customerId != null) {
        customer = await (db.select(db.customers)..where((c) => c.id.equals(sale.customerId!)))
            .getSingleOrNull();
      }
      if (refundMethod == 'debt' || refundMethod == 'bonus') {
        if (customer == null) throw BusinessException('В чеке нет клиента');
      }
      if (refundMethod == 'cash' || refundMethod == 'card' || refundMethod == 'transfer') {
        // money back out of the till requires an open shift
        if (refundMethod == 'cash' && shiftId == null) {
          throw BusinessException('Для возврата наличными откройте смену');
        }
      }

      final number = await db.nextNumber('return');
      await db.into(db.returns).insert(ReturnsCompanion.insert(
            id: returnId,
            number: number,
            saleId: saleId,
            shiftId: Value(shiftId),
            userId: Value(userId),
            total: total,
            refundMethod: refundMethod,
            reason: Value(reason),
            restock: Value(restock),
            createdAt: Value(at),
            updatedAt: Value(at),
          ));
      for (final row in rows) {
        await db.into(db.returnItems).insert(row);
      }

      // sale status
      final refunded = sale.refundedTotal + total;
      final itemsAfter = await (db.select(db.saleItems)..where((i) => i.saleId.equals(saleId))).get();
      final fully = itemsAfter.every((i) => (i.qty - i.returnedQty).abs() < 1e-9);
      await (db.update(db.sales)..where((s) => s.id.equals(saleId))).write(SalesCompanion(
          refundedTotal: Value(refunded),
          status: Value(fully ? 'returned' : 'partially_returned'),
          updatedAt: Value(at)));

      // customer effects
      if (customer != null) {
        var debt = customer.debtBalance;
        var bonus = customer.bonusBalance;
        Future<void> ledger(String kind, int amount, int after) =>
            db.into(db.customerLedger).insert(CustomerLedgerCompanion.insert(
                  id: newId(),
                  customerId: customer!.id,
                  kind: kind,
                  amount: amount,
                  balanceAfter: after,
                  refType: const Value('return'),
                  refId: Value(returnId),
                  userId: Value(userId),
                  shiftId: Value(shiftId),
                  createdAt: Value(at),
                  updatedAt: Value(at),
                ));
        if (refundMethod == 'debt') {
          debt -= total;
          await ledger('debt_adjust', -total, debt);
        } else if (refundMethod == 'bonus') {
          bonus += total;
          await ledger('bonus_adjust', total, bonus);
        }
        // claw back bonus earned proportionally
        if (sale.bonusEarned > 0 && sale.total > 0) {
          final claw = fully
              ? sale.bonusEarned - (sale.bonusEarned * sale.refundedTotal / sale.total).round()
              : (sale.bonusEarned * total / sale.total).round();
          final c = min(claw, max(0, bonus));
          if (c > 0) {
            bonus -= c;
            await ledger('bonus_adjust', -c, bonus);
          }
        }
        await (db.update(db.customers)..where((c) => c.id.equals(customer!.id))).write(
            CustomersCompanion(
                debtBalance: Value(debt),
                bonusBalance: Value(bonus),
                totalSpent: Value(max(0, customer.totalSpent - total)),
                updatedAt: Value(at)));
      }

      await db.audit('sale.return',
          userId: userId, entity: 'sale', entityId: saleId,
          details: 'return #$number total=$total method=$refundMethod; $reason');
      await db.markDirty('returns', returnId);
      return (db.select(db.returns)..where((r) => r.id.equals(returnId))).getSingle();
    });
  }

  /// Cancels a whole sale (e.g. cashier mistake) by returning everything
  /// with the original payment split. Only allowed in the same open shift.
  Future<void> voidSale(String saleId,
      {required String userId, required String reason, String? shiftId}) async {
    if (reason.trim().isEmpty) throw BusinessException('Укажите причину аннулирования');
    await db.transaction(() async {
      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();
      if (sale.status != 'completed') {
        throw BusinessException('Аннулировать можно только чек без возвратов');
      }
      if (sale.shiftId != null && sale.shiftId != shiftId) {
        throw BusinessException('Чек из другой смены — оформите возврат');
      }
      final items = await (db.select(db.saleItems)..where((i) => i.saleId.equals(saleId))).get();
      final payments = await (db.select(db.salePayments)..where((p) => p.saleId.equals(saleId))).get();
      for (final it in items) {
        await stock.move(
            productId: it.productId,
            delta: it.qty,
            type: 'return',
            refType: 'void',
            refId: saleId,
            userId: userId,
            reason: reason);
        await (db.update(db.saleItems)..where((t) => t.id.equals(it.id)))
            .write(SaleItemsCompanion(returnedQty: Value(it.qty)));
      }
      if (sale.customerId != null) {
        final c = await (db.select(db.customers)..where((t) => t.id.equals(sale.customerId!))).getSingle();
        var debt = c.debtBalance;
        var bonus = c.bonusBalance;
        for (final p in payments) {
          if (p.method == 'debt') debt -= p.amount;
          if (p.method == 'bonus') bonus += p.amount;
        }
        bonus = max(0, bonus - sale.bonusEarned);
        await db.into(db.customerLedger).insert(CustomerLedgerCompanion.insert(
              id: newId(),
              customerId: c.id,
              kind: 'debt_adjust',
              amount: debt - c.debtBalance,
              balanceAfter: debt,
              refType: const Value('void'),
              refId: Value(saleId),
              userId: Value(userId),
              note: Value('Аннулирование чека №${sale.number}'),
            ));
        await (db.update(db.customers)..where((t) => t.id.equals(c.id))).write(CustomersCompanion(
            debtBalance: Value(debt),
            bonusBalance: Value(bonus),
            totalSpent: Value(max(0, c.totalSpent - sale.total)),
            visits: Value(max(0, c.visits - 1))));
      }
      for (final p in payments.where((p) => p.method == 'gift_card' && p.reference != null)) {
        final g = await (db.select(db.giftCards)..where((t) => t.code.equals(p.reference!))).getSingleOrNull();
        if (g != null) {
          await (db.update(db.giftCards)..where((t) => t.id.equals(g.id)))
              .write(GiftCardsCompanion(balance: Value(g.balance + p.amount), status: const Value('active')));
        }
      }
      await (db.update(db.sales)..where((s) => s.id.equals(saleId))).write(SalesCompanion(
          status: const Value('voided'),
          voidReason: Value(reason),
          refundedTotal: Value(sale.total),
          updatedAt: Value(DateTime.now())));
      await db.audit('sale.void', userId: userId, entity: 'sale', entityId: saleId, details: reason);
    });
  }
}
