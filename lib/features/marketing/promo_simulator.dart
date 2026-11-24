import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/pickers.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/pricing.dart';

Future<void> showPromoSimulator(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  if (size.width < 700) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Проверка акций на чеке')),
          body: const PromoSimulator(),
        ),
      ),
    );
  }
  return showFormDialog<void>(context, title: 'Проверка акций на чеке', width: 860, child: const PromoSimulator());
}

class _SimLine {
  _SimLine(this.product, double qty) : qty = TextEditingController(text: Qty.format(qty));
  final Product product;
  final TextEditingController qty;
  final key = UniqueKey().toString();
  double get value => double.tryParse(qty.text.replaceAll(',', '.')) ?? 0;
}

/// Runs the real PricingEngine with currently active promotions on a sample
/// cart, so the owner sees which discount wins (D-008: no stacking per line).
class PromoSimulator extends ConsumerStatefulWidget {
  const PromoSimulator({super.key});
  @override
  ConsumerState<PromoSimulator> createState() => _PromoSimulatorState();
}

class _PromoSimulatorState extends ConsumerState<PromoSimulator> {
  final _lines = <_SimLine>[];
  final _customerPct = TextEditingController();
  final _code = TextEditingController();
  List<PromoRule>? _rules;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    try {
      final r = await ref.read(saleServiceProvider).activePromotions();
      if (mounted) setState(() => _rules = r);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.qty.dispose();
    }
    _customerPct.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final p = await pickProduct(context, title: 'Добавить товар в тестовый чек');
    if (p == null) return;
    setState(() {
      final existing = _lines.where((l) => l.product.id == p.id).firstOrNull;
      if (existing != null) {
        existing.qty.text = Qty.format(existing.value + 1);
      } else {
        _lines.add(_SimLine(p, 1));
      }
    });
  }

  /// Customer discount as typed; null when invalid (not a number or > 100).
  double? get _customerPercent {
    final t = _customerPct.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return 0;
    final v = double.tryParse(t);
    if (v == null || v < 0 || v > 100) return null;
    return v;
  }

  void _removeLine(_SimLine l) {
    setState(() => _lines.remove(l));
    // The TextField still holds the controller until this frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) => l.qty.dispose());
  }

  PricingResult? _compute() {
    final rules = _rules;
    if (rules == null || _lines.isEmpty) return null;
    return PricingEngine.price(
      lines: [
        for (final l in _lines)
          if (l.value > 0)
            PricingLine(
              key: l.key,
              productId: l.product.id,
              categoryId: l.product.categoryId,
              qty: l.value,
              unitPrice: l.product.price,
              vatPercent: l.product.vatPercent,
            ),
      ],
      promotions: rules,
      customerDiscountPercent: _customerPercent ?? 0,
      promoCode: _code.text.trim().isEmpty ? null : _code.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    if (_loadError != null) return ErrorView(error: _loadError!, onRetry: _loadRules);
    if (_rules == null) return const SizedBox(height: 200, child: LoadingView());
    final res = _compute();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Добавьте товары и посмотрите, какие скидки применит касса. Действует активных акций: ${_rules!.length}. '
            'Скидки на позицию не суммируются — берётся лучшая из акции на товар/категорию, «N+M» '
            'и персональной скидки клиента. Из скидок на чек (акция на чек, промокод) применяется одна, самая выгодная.',
            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: Gap.m),
          LayoutBuilder(
            builder: (context, box) {
              final addBtn = FilledButton.tonalIcon(
                autofocus: true,
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('Добавить товар'),
              );
              final pct = TextField(
                controller: _customerPct,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: InputDecoration(
                  labelText: 'Скидка клиента',
                  suffixText: '%',
                  errorText: _customerPercent == null ? 'От 0 до 100' : null,
                ),
                onChanged: (_) => setState(() {}),
              );
              final code = TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Промокод'),
                onChanged: (_) => setState(() {}),
              );
              // Phones: full-width button, both inputs share one row instead of
              // two half-empty 200px fields stacked under each other.
              if (box.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    addBtn,
                    const SizedBox(height: Gap.m),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: pct),
                        const SizedBox(width: Gap.s),
                        Expanded(child: code),
                      ],
                    ),
                  ],
                );
              }
              return Wrap(
                spacing: Gap.m,
                runSpacing: Gap.m,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  addBtn,
                  SizedBox(width: 200, child: pct),
                  SizedBox(width: 200, child: code),
                ],
              );
            },
          ),
          const SizedBox(height: Gap.l),
          if (_lines.isEmpty)
            const EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Тестовый чек пуст',
              message: 'Добавьте один или несколько товаров',
            )
          else ...[
            Card(
              child: Column(
                children: [
                  for (final l in _lines) ...[_lineRow(t, l, res?.byKey(l.key)), if (l != _lines.last) const Divider()],
                ],
              ),
            ),
            if (res != null) ...[const SizedBox(height: Gap.m), _summary(t, res)],
          ],
        ],
      ),
    );
  }

  Widget _lineRow(ThemeData t, _SimLine l, PricedLine? pl) {
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text('${Money.format(l.product.price)} за ${Qty.unitLabel(l.product.unit)}', style: t.textTheme.bodySmall),
        if (pl != null && pl.autoDiscount > 0)
          Text(
            '−${Money.format(pl.autoDiscount)} · ${pl.autoReason ?? ''}',
            style: const TextStyle(color: AppColors.success, fontSize: 12),
          ),
        if (pl != null && pl.orderDiscount > 0)
          Text(
            '−${Money.format(pl.orderDiscount)} · доля скидки на чек',
            style: const TextStyle(color: AppColors.info, fontSize: 12),
          ),
        if (l.value <= 0)
          const Text('Укажите количество больше нуля', style: TextStyle(color: AppColors.danger, fontSize: 12)),
      ],
    );
    final qty = SizedBox(
      width: 96,
      child: TextField(
        controller: l.qty,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        decoration: InputDecoration(labelText: 'Кол-во', suffixText: Qty.unitLabel(l.product.unit)),
        onChanged: (_) => setState(() {}),
      ),
    );
    final total = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (pl != null && pl.discount > 0)
          Text(
            Money.format(pl.line.gross),
            style: t.textTheme.bodySmall?.copyWith(decoration: TextDecoration.lineThrough),
          ),
        Text(Money.format(pl?.total ?? 0), style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
    final remove = IconButton(tooltip: 'Убрать', icon: const Icon(Icons.close), onPressed: () => _removeLine(l));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.s),
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth >= 520) {
            return Row(
              children: [
                Expanded(child: info),
                qty,
                const SizedBox(width: Gap.m),
                SizedBox(width: 120, child: total),
                remove,
              ],
            );
          }
          // Phones: product info on top, quantity and total below.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: info),
                  remove,
                ],
              ),
              const SizedBox(height: Gap.xs),
              Row(children: [qty, const Spacer(), total]),
            ],
          );
        },
      ),
    );
  }

  Widget _summary(ThemeData t, PricingResult res) {
    Widget row(String l, String v, {bool strong = false, Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(l, style: strong ? t.textTheme.titleMedium : null)),
          Text(
            v,
            style: (strong ? t.textTheme.titleMedium : t.textTheme.bodyMedium)?.copyWith(
              fontWeight: strong ? FontWeight.w700 : null,
              color: color,
            ),
          ),
        ],
      ),
    );
    final code = res.promoCodeValid;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row('Сумма без скидок', Money.format(res.subtotal)),
            row('Скидка', '−${Money.format(res.discountTotal)}', color: AppColors.success),
            const Divider(),
            row('К оплате', Money.format(res.total), strong: true),
            const SizedBox(height: Gap.m),
            if (code != null)
              Text(
                code ? 'Промокод принят' : 'Промокод не найден, не активен или сумма чека меньше минимальной',
                style: TextStyle(color: code ? AppColors.success : AppColors.danger),
              ),
            const SizedBox(height: Gap.xs),
            Text('Применённые скидки:', style: t.textTheme.labelLarge),
            if (res.appliedPromotions.isEmpty)
              Text('нет', style: t.textTheme.bodySmall)
            else
              Wrap(
                spacing: Gap.xs,
                runSpacing: Gap.xs,
                children: [for (final a in res.appliedPromotions) StatusChip(a, color: AppColors.success)],
              ),
          ],
        ),
      ),
    );
  }
}
