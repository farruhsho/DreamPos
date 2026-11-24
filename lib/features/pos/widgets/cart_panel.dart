// Right side of the till (or a full page on phones): customer, lines,
// totals with live pricing, promo code / order discount and the Pay button.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/permissions.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/pricing.dart';
import '../cart_controller.dart';
import '../parked_carts.dart';
import '../pos_actions.dart';
import '../pos_providers.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key, this.refocus, this.showHeader = true, this.onSold});
  final VoidCallback? refocus;
  final bool showHeader;
  final VoidCallback? onSold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = PosActions(context, ref, refocus: refocus, onSold: onSold);
    final cart = ref.watch(cartProvider);
    final quote = ref.watch(cartQuoteProvider);
    final t = Theme.of(context);

    return Material(
      color: t.cardTheme.color ?? t.colorScheme.surface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (showHeader) _CartHeader(actions: a),
        _CustomerBox(actions: a),
        const Divider(),
        Expanded(
          child: cart.isEmpty
              ? const EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Чек пуст',
                  message: 'Отсканируйте штрихкод или выберите товар в каталоге',
                )
              : _Lines(actions: a, cart: cart, quote: quote.value),
        ),
        const Divider(),
        _Totals(actions: a, cart: cart, quote: quote),
      ]),
    );
  }
}

// ------------------------------------------------------------------ header

class _CartHeader extends ConsumerWidget {
  const _CartHeader({required this.actions});
  final PosActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final parked = ref.watch(parkedCartsProvider).value?.length ?? 0;
    final users = ref.watch(posActiveUsersProvider).value ?? const <User>[];
    String? sellerName;
    for (final u in users) {
      if (u.id == cart.sellerId) sellerName = u.name;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.xs, Gap.xs),
      child: Row(children: [
        Text('Чек', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(width: Gap.s),
        if (cart.isNotEmpty) StatusChip('${cart.lines.length} поз.'),
        const Spacer(),
        Tooltip(
          message: 'Продавец-консультант (для мотивации)',
          child: TextButton.icon(
            onPressed: actions.chooseSeller,
            icon: const Icon(Icons.badge_outlined, size: 18),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(sellerName ?? 'Продавец', overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Отложенные чеки (F9)',
          onPressed: actions.showParked,
          icon: Badge(
            isLabelVisible: parked > 0,
            label: Text('$parked'),
            child: const Icon(Icons.inventory_outlined),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Действия с чеком',
          onSelected: (v) => switch (v) {
            'park' => actions.park(),
            'parked' => actions.showParked(),
            'seller' => actions.chooseSeller(),
            'clear' => actions.clearCart(),
            _ => null,
          },
          itemBuilder: (_) => [
            PopupMenuItem(
                value: 'park',
                enabled: cart.isNotEmpty,
                child: const ListTile(
                    leading: Icon(Icons.pause_circle_outline), title: Text('Отложить чек'), trailing: Text('F8'))),
            const PopupMenuItem(
                value: 'parked',
                child: ListTile(
                    leading: Icon(Icons.inventory_outlined), title: Text('Отложенные'), trailing: Text('F9'))),
            const PopupMenuItem(
                value: 'seller',
                child: ListTile(leading: Icon(Icons.badge_outlined), title: Text('Продавец'))),
            PopupMenuItem(
                value: 'clear',
                enabled: cart.isNotEmpty,
                child: const ListTile(
                    leading: Icon(Icons.delete_sweep_outlined, color: AppColors.danger),
                    title: Text('Очистить чек'))),
          ],
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ customer

class _CustomerBox extends ConsumerWidget {
  const _CustomerBox({required this.actions});
  final PosActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(cartProvider.select((c) => c.customerId));
    final t = Theme.of(context);
    if (id == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.s),
        child: OutlinedButton.icon(
          onPressed: actions.attachCustomer,
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Клиент (F4)'),
        ),
      );
    }
    final c = ref.watch(cartCustomerProvider).value;
    final loyalty = ref.watch(settingProvider('loyalty_enabled')) == '1';
    final name = c?.name ?? ref.watch(cartProvider.select((s) => s.customerName)) ?? '…';
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.xs, Gap.s),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: t.colorScheme.primaryContainer,
          child: Text(name.characters.first.toUpperCase()),
        ),
        const SizedBox(width: Gap.m),
        Expanded(
          child: InkWell(
            onTap: actions.attachCustomer,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              if (c != null)
                Wrap(spacing: Gap.s, children: [
                  if (c.discountPercent > 0)
                    Text('скидка ${c.discountPercent.toStringAsFixed(0)}%',
                        style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.primary)),
                  if (loyalty || c.bonusBalance > 0)
                    Text('бонусы ${Money.format(c.bonusBalance)}',
                        style: t.textTheme.bodySmall?.copyWith(color: AppColors.success)),
                  if (c.debtBalance > 0 || c.debtLimit > 0)
                    Text(
                        'долг ${Money.format(c.debtBalance)}'
                        '${c.debtLimit > 0 ? ' / лимит ${Money.format(c.debtLimit)}' : ''}',
                        style: t.textTheme.bodySmall?.copyWith(
                            color: c.debtBalance > 0 ? AppColors.danger : t.colorScheme.onSurfaceVariant)),
                ]),
            ]),
          ),
        ),
        IconButton(
          tooltip: 'Убрать клиента из чека',
          onPressed: actions.detachCustomer,
          icon: const Icon(Icons.person_remove_outlined),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ lines

class _Lines extends ConsumerWidget {
  const _Lines({required this.actions, required this.cart, required this.quote});
  final PosActions actions;
  final CartState cart;
  final PricingResult? quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(cartProductsProvider).value ?? const <String, Product>{};
    final session = ref.watch(sessionProvider);
    final canEditPrice = session?.can(Perm.editPrices) ?? false;
    // quote lines are keyed by index, valid only for the same line count
    final priced = quote != null && quote!.lines.length == cart.lines.length ? quote : null;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs),
      itemCount: cart.lines.length,
      separatorBuilder: (_, _) => const Divider(indent: Gap.l, endIndent: Gap.l),
      itemBuilder: (_, i) {
        final l = cart.lines[i];
        // a quote still computing for an older cart must not paint its
        // discounts onto a different line
        var pl = priced?.byKey('$i');
        if (pl != null &&
            (pl.line.productId != l.productId ||
                pl.line.unitPrice != l.unitPrice ||
                pl.line.qty != Qty.round(l.qty) ||
                pl.manualDiscount > l.manualDiscount)) {
          pl = null;
        }
        return CartLineTile(
          key: ValueKey(l.key),
          line: l,
          priced: pl,
          product: products[l.productId],
          selected: l.key == cart.selectedKey,
          canEditPrice: canEditPrice,
          actions: actions,
        );
      },
    );
  }
}

class CartLineTile extends ConsumerWidget {
  const CartLineTile({
    super.key,
    required this.line,
    required this.priced,
    required this.product,
    required this.selected,
    required this.canEditPrice,
    required this.actions,
  });

  final CartLine line;
  final PricedLine? priced;
  final Product? product;
  final bool selected;
  final bool canEditPrice;
  final PosActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final ctl = ref.read(cartProvider.notifier);
    final l = line;
    final total = priced?.total ?? (l.gross - l.manualDiscount);
    final discount = priced?.discount ?? l.manualDiscount;
    final p = product;
    final short = p != null &&
        p.trackStock &&
        !p.allowNegativeStock &&
        l.qty > p.stockQty + 1e-9;

    final notes = <Widget>[
      if (priced != null && priced!.autoDiscount > 0)
        Text('${priced!.autoReason ?? 'Акция'}: −${Money.format(priced!.autoDiscount)}',
            style: t.textTheme.bodySmall?.copyWith(color: AppColors.success)),
      if (l.hasManualDiscount)
        Text(
            'Ручная скидка${l.discountPercent > 0 ? ' ${l.discountPercent.toStringAsFixed(l.discountPercent % 1 == 0 ? 0 : 1)}%' : ''}: '
            '−${Money.format(l.manualDiscount)}${l.discountApprovedBy != null ? ' (подтв.)' : ''}',
            style: t.textTheme.bodySmall?.copyWith(color: AppColors.info)),
      if (priced != null && priced!.orderDiscount > 0)
        Text('Скидка на чек: −${Money.format(priced!.orderDiscount)}',
            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
      if (short)
        Text('На складе только ${Qty.format(p.stockQty, p.unit)}',
            style: t.textTheme.bodySmall
                ?.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600)),
    ];

    return Material(
      color: selected ? t.colorScheme.primaryContainer.withValues(alpha: 0.35) : Colors.transparent,
      child: InkWell(
        canRequestFocus: false,
        onTap: () => ctl.select(l.key),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.xs, Gap.s),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(l.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(Money.format(total),
                    style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                if (discount > 0)
                  Text(Money.format(l.gross),
                      style: t.textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: t.colorScheme.onSurfaceVariant)),
              ]),
              const SizedBox(width: Gap.xs),
            ]),
            const SizedBox(height: Gap.xs),
            Row(children: [
              _StepButton(
                icon: Icons.remove,
                tooltip: 'Меньше (−)',
                onPressed: l.qty > 1 ? () => ctl.changeQty(l.key, -1) : null,
              ),
              InkWell(
                canRequestFocus: false,
                borderRadius: BorderRadius.circular(8),
                onTap: () => actions.editQty(l),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 56),
                  padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: t.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(Qty.format(l.qty, l.unit),
                      key: Key('qty-${l.productId}'),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                tooltip: 'Больше (+)',
                onPressed: () => ctl.changeQty(l.key, 1),
              ),
              const SizedBox(width: Gap.s),
              Flexible(
                child: Tooltip(
                  message: canEditPrice ? 'Изменить цену' : 'Нет права изменять цены',
                  child: InkWell(
                    canRequestFocus: false,
                    onTap: canEditPrice ? () => actions.editPrice(l) : null,
                    child: Text(
                      '× ${Money.format(l.unitPrice)}${l.priceEdited ? ' *' : ''}',
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.bodyMedium?.copyWith(
                        color: l.priceEdited ? AppColors.warning : t.colorScheme.onSurfaceVariant,
                        decoration: canEditPrice ? TextDecoration.underline : null,
                        decorationStyle: TextDecorationStyle.dotted,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Скидка на позицию',
                visualDensity: VisualDensity.compact,
                onPressed: () => actions.lineDiscount(l),
                icon: Icon(Icons.percent,
                    size: 20, color: l.hasManualDiscount ? AppColors.info : null),
              ),
              IconButton(
                tooltip: 'Удалить позицию (Del)',
                visualDensity: VisualDensity.compact,
                onPressed: () => actions.removeLine(l),
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ]),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 2),
              ...notes,
            ],
          ]),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ExcludeFocus(
        child: IconButton.filledTonal(
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
        ),
      );
}

// ------------------------------------------------------------------ totals

class _Totals extends ConsumerWidget {
  const _Totals({required this.actions, required this.cart, required this.quote});
  final PosActions actions;
  final CartState cart;
  final AsyncValue<PricingResult?> quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final q = quote.value;
    final canSell = ref.watch(posCanSellProvider);
    final subtotal = q?.subtotal ?? cart.grossTotal;
    final discount = q?.discountTotal ?? 0;
    final total = q?.total ?? cart.grossTotal;
    final vat = q?.vatTotal ?? 0;

    Widget row(String label, String value, {Color? color, String? hint}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: t.textTheme.bodyMedium?.copyWith(color: color)),
                if (hint != null)
                  Text(hint,
                      style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              ]),
            ),
            Text(value, style: t.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ]),
        );

    final promoValid = q?.promoCodeValid;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.l),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ---- adjustments
        Wrap(spacing: Gap.s, runSpacing: Gap.xs, children: [
          if (cart.promoCode == null)
            ActionChip(
              avatar: const Icon(Icons.confirmation_number_outlined, size: 18),
              label: const Text('Промокод'),
              onPressed: cart.isEmpty ? null : actions.enterPromo,
            )
          else
            InputChip(
              avatar: Icon(
                promoValid == true
                    ? Icons.check_circle
                    : promoValid == false
                        ? Icons.error
                        : Icons.hourglass_empty,
                size: 18,
                color: promoValid == true
                    ? AppColors.success
                    : promoValid == false
                        ? AppColors.danger
                        : null,
              ),
              label: Text(promoValid == false
                  ? '${cart.promoCode} — недействителен'
                  : cart.promoCode!),
              onPressed: actions.enterPromo,
              onDeleted: () => ref.read(cartProvider.notifier).setPromoCode(null),
              deleteButtonTooltipMessage: 'Убрать промокод',
            ),
          if (!cart.hasOrderDiscount)
            ActionChip(
              avatar: const Icon(Icons.percent, size: 18),
              label: const Text('Скидка на чек'),
              onPressed: cart.isEmpty ? null : actions.orderDiscount,
            )
          else
            InputChip(
              avatar: const Icon(Icons.percent, size: 18, color: AppColors.info),
              label: Text(cart.orderDiscountPercent > 0
                  ? 'Скидка на чек ${cart.orderDiscountPercent.toStringAsFixed(cart.orderDiscountPercent % 1 == 0 ? 0 : 1)}%'
                  : 'Скидка на чек ${Money.format(cart.orderDiscountAmount)}'),
              onPressed: actions.orderDiscount,
              onDeleted: () => ref.read(cartProvider.notifier).setOrderDiscount(),
              deleteButtonTooltipMessage: 'Убрать скидку',
            ),
        ]),
        const SizedBox(height: Gap.s),
        row('Подытог', Money.format(subtotal)),
        if (discount > 0)
          row('Скидка', '−${Money.format(discount)}',
              color: AppColors.success,
              hint: (q?.appliedPromotions.isNotEmpty ?? false) ? q!.appliedPromotions.join(', ') : null),
        if (vat > 0) row('в т.ч. НДС', Money.format(vat)),
        const SizedBox(height: Gap.xs),
        Row(children: [
          Text('Итого', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          if (quote.isLoading)
            const Padding(
              padding: EdgeInsets.only(left: Gap.s),
              child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          const Spacer(),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(Money.format(total),
                  key: const Key('cart-total'),
                  style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
        if (quote.hasError)
          Text('Не удалось рассчитать скидки: ${errorText(quote.error!)}',
              style: t.textTheme.bodySmall?.copyWith(color: AppColors.danger)),
        const SizedBox(height: Gap.m),
        Tooltip(
          message: !canSell
              ? 'Откройте смену, чтобы продавать'
              : cart.isEmpty
                  ? 'Добавьте товары в чек'
                  : 'Оплата (F12 или Ctrl+Enter)',
          child: SizedBox(
            height: 60,
            child: FilledButton.icon(
              key: const Key('pos-pay'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: cart.isEmpty || !canSell ? null : actions.pay,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Оплатить  ·  F12', style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
      ]),
    );
  }
}
