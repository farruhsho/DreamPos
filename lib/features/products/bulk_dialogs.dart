import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'product_logic.dart';
import 'product_widgets.dart';
import 'products_repo.dart';

/// Moves the selected products to another category. Returns true if applied.
Future<bool> showBulkCategoryDialog(BuildContext context, WidgetRef ref, Set<String> ids) async {
  final cats = ref.read(productCategoriesProvider).value ?? const <Category>[];
  final l = context.l10n;
  String? target;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setS) => AlertDialog(
        title: Text(l.prodBulkCategoryTitle('${ids.length}')),
        content: SizedBox(
          width: 400,
          child: DropdownButtonFormField<String?>(
            initialValue: target,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.prodNewCategory),
            items: [
              DropdownMenuItem(value: null, child: Text(l.prodNoCategory)),
              for (final cat in cats)
                DropdownMenuItem(
                  value: cat.id,
                  child: Row(children: [
                    CategoryDot(color: cat.color),
                    const SizedBox(width: Gap.s),
                    Flexible(child: Text(cat.name, overflow: TextOverflow.ellipsis)),
                  ]),
                ),
            ],
            onChanged: (v) => setS(() => target = v),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.commonApply)),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return false;
  return runGuarded(
    context,
    () => ref
        .read(productsRepoProvider)
        .setCategory(ids, target, userId: ref.read(sessionProvider)?.user.id),
    success: l.prodBulkCategoryDone('${ids.length}'),
  );
}

/// Bulk retail price change by percent with rounding, preview and confirm.
Future<bool> showBulkPriceDialog(BuildContext context, Set<String> ids) async {
  final r = await showFormDialog<bool>(context,
      title: context.l10n.prodBulkPriceTitle, width: 720, child: _BulkPriceDialog(ids: ids));
  return r ?? false;
}

class _BulkPriceDialog extends ConsumerStatefulWidget {
  const _BulkPriceDialog({required this.ids});
  final Set<String> ids;

  @override
  ConsumerState<_BulkPriceDialog> createState() => _BulkPriceDialogState();
}

class _BulkPriceDialogState extends ConsumerState<_BulkPriceDialog> {
  final _pct = TextEditingController();
  late final Future<List<Product>> _products = ref.read(productsRepoProvider).byIds(widget.ids);
  late int _step = Money.currency.decimals == 0 ? 100 : 1;
  RoundMode _mode = RoundMode.nearest;
  bool _busy = false;

  @override
  void dispose() {
    _pct.dispose();
    super.dispose();
  }

  double? get _percent {
    final v = parseDecimal(_pct.text);
    if (v == null || v <= -100 || v > 1000) return null;
    return v;
  }

  Future<void> _apply(List<Product> products) async {
    if (_busy) return; // Enter pressed twice
    final pct = _percent;
    final l = context.l10n;
    if (pct == null || pct == 0) {
      showError(context, l.prodBulkPctError);
      return;
    }
    final map = {
      for (final p in products) p.id: applyPercentChange(p.price, pct, step: _step, mode: _mode),
    };
    final changed = products.where((p) => map[p.id] != p.price).length;
    if (changed == 0) {
      showError(context, l.prodBulkNoChange);
      return;
    }
    _busy = true;
    final ok = await confirm(context,
        title: l.prodBulkPriceConfirmQ('$changed'),
        message: l.prodBulkPriceConfirmMessage,
        ok: l.prodChangePrices);
    if (!mounted) return;
    if (!ok) {
      setState(() => _busy = false);
      return;
    }
    setState(() {});
    final sign = pct > 0 ? '+' : '';
    final success = await runGuarded(
      context,
      () => ref.read(productsRepoProvider).applyPrices(map,
          userId: ref.read(sessionProvider)?.user.id,
          // Audit note is stored in the DB: stays Russian.
          note: 'массово $sign${formatPercent(pct)}, ' // l10n-ignore
              '${roundingStepLabel(_step, Money.currency, L.of('ru')).toLowerCase()}'),
      success: l.prodBulkPriceDone('$changed'),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final canCost = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    final l = context.l10n;
    final steps = roundingStepsMinor(Money.currency);
    if (!steps.contains(_step)) _step = steps.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.l),
      child: FutureBuilder<List<Product>>(
        future: _products,
        builder: (context, s) {
          if (s.hasError) return ErrorView(error: s.error!);
          if (!s.hasData) return const SizedBox(height: 200, child: LoadingView());
          final products = s.data!;
          final pct = _percent;
          final preview = [
            for (final p in products)
              (p, pct == null ? p.price : applyPercentChange(p.price, pct, step: _step, mode: _mode)),
          ];
          final changed = preview.where((e) => e.$2 != e.$1.price).length;
          final belowCost = preview.where((e) => e.$1.costPrice > 0 && e.$2 < e.$1.costPrice).length;
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            FieldRow(children: [
              TextFormField(
                controller: _pct,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-−]'))],
                decoration: InputDecoration(
                  labelText: l.prodChangePct,
                  hintText: l.prodChangePctHint,
                  helperText: l.prodChangePctHelper,
                  errorText: _pct.text.isNotEmpty && pct == null ? l.prodChangePctRange : null,
                ),
                onChanged: (v) {
                  if (v.contains('−')) _pct.text = v.replaceAll('−', '-');
                  setState(() {});
                },
                onFieldSubmitted: (_) => _apply(products),
              ),
              DropdownButtonFormField<int>(
                initialValue: _step,
                decoration: InputDecoration(labelText: l.prodRounding),
                items: [
                  for (final st in steps)
                    DropdownMenuItem(value: st, child: Text(roundingStepLabel(st, Money.currency, l))),
                ],
                onChanged: (v) => setState(() => _step = v ?? 1),
              ),
            ]),
            const SizedBox(height: Gap.m),
            if (_step > 1)
              SegmentedButton<RoundMode>(
                segments: [for (final m in RoundMode.values) ButtonSegment(value: m, label: Text(m.labelIn(l)))],
                selected: {_mode},
                onSelectionChanged: (v) => setState(() => _mode = v.first),
              ),
            const SizedBox(height: Gap.m),
            Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
              StatusChip(l.prodSelectedCount('${products.length}')),
              StatusChip(l.prodWillChange('$changed'), color: AppColors.info),
              if (canCost && belowCost > 0)
                StatusChip(l.prodBelowCostCount('$belowCost'), color: AppColors.danger),
            ]),
            const SizedBox(height: Gap.s),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 340),
                decoration: BoxDecoration(
                  border: Border.all(color: t.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: preview.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) {
                    final (p, np) = preview[i];
                    final diff = np != p.price;
                    final below = canCost && p.costPrice > 0 && np < p.costPrice;
                    return ListTile(
                      dense: true,
                      title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: canCost
                          ? Text(
                              l.prodCostMarginLine(
                                  Money.format(p.costPrice), formatPercent(marginPercent(np, p.costPrice))),
                              style: below ? const TextStyle(color: AppColors.danger) : null)
                          : null,
                      trailing: Text.rich(TextSpan(children: [
                        TextSpan(
                            text: Money.format(p.price),
                            style: TextStyle(
                                color: t.colorScheme.onSurfaceVariant,
                                decoration: diff ? TextDecoration.lineThrough : null)),
                        if (diff) ...[
                          const TextSpan(text: '  →  '),
                          TextSpan(text: Money.format(np), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ])),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: Gap.l),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
              const SizedBox(width: Gap.s),
              FilledButton.icon(
                onPressed: _busy || pct == null || changed == 0 ? null : () => _apply(products),
                icon: const Icon(Icons.price_change_outlined),
                label: Text(changed == 0 ? l.commonApply : l.prodApplyTo('$changed')),
              ),
            ]),
          ]);
        },
      ),
    );
  }
}
