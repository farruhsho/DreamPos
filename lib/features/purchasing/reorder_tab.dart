import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'purchasing_logic.dart';

const _noSupplier = '';
const reorderTargetDaysKey = 'reorder_target_days';

class _Row {
  _Row(this.s) : qty = TextEditingController(text: Qty.format(s.suggestedQty));
  final ReorderSuggestion s;
  final TextEditingController qty;
  bool selected = true;
  double get q => QtyField.parse(qty.text) ?? 0;
}

/// «Автозаказ»: what to buy, based on sales velocity and minimum stock.
class ReorderTab extends ConsumerStatefulWidget {
  const ReorderTab({super.key});
  @override
  ConsumerState<ReorderTab> createState() => _ReorderTabState();
}

class _ReorderTabState extends ConsumerState<ReorderTab> {
  late final _days = TextEditingController();
  int _target = 14;
  List<_Row>? _rows;
  Object? _error;
  bool _busy = false;
  final _assign = <String, String>{}; // group(no supplier) -> chosen supplier

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final saved = int.tryParse(await ref.read(databaseProvider).getSetting(reorderTargetDaysKey) ?? '');
    _target = saved != null && saved > 0 ? saved : 14;
    _days.text = '$_target';
    await _load();
  }

  @override
  void dispose() {
    _days.dispose();
    for (final r in _rows ?? const <_Row>[]) {
      r.qty.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final old = _rows;
    setState(() {
      _error = null;
      _rows = null;
    });
    // Old rows are off screen now; release their controllers after the frame.
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final r in old) {
          r.qty.dispose();
        }
      });
    }
    try {
      final list = await ref.read(purchasingRepoProvider).reorderSuggestions(targetDays: _target);
      if (!mounted) return;
      setState(() => _rows = [for (final s in list) _Row(s)]);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _applyDays() async {
    if (_rows == null && _error == null) return; // already loading
    final d = int.tryParse(_days.text.trim());
    if (d == null || d < 1 || d > 365) {
      showError(context, 'Укажите запас от 1 до 365 дней');
      return;
    }
    _target = d;
    await ref.read(databaseProvider).setSetting(reorderTargetDaysKey, '$d');
    await _load();
  }

  Future<void> _createOrders(Map<String, List<_Row>> groups, Map<String, String> names) async {
    final payload = <String, List<PoLineInput>>{};
    var skipped = 0;
    for (final e in groups.entries) {
      final sel = e.value.where((r) => r.selected && r.q > 0).toList();
      if (sel.isEmpty) continue;
      final sid = e.key == _noSupplier ? _assign[_noSupplier] : e.key;
      if (sid == null || !names.containsKey(sid)) {
        skipped += sel.length;
        continue;
      }
      for (final r in sel) {
        if (!Qty.isFractional(r.s.product.unit) && r.q != r.q.roundToDouble()) {
          showError(context, '«${r.s.product.name}»: только целое количество');
          return;
        }
      }
      final lines = payload.putIfAbsent(sid, () => []);
      for (final r in sel) {
        final ex = lines.firstWhereOrNull((l) => l.productId == r.s.product.id);
        if (ex == null) lines.add(PoLineInput(productId: r.s.product.id, qty: r.q, unitCost: r.s.product.costPrice));
      }
    }
    if (payload.isEmpty) {
      showError(
        context,
        skipped > 0 ? 'Выберите поставщика для товаров без поставщика' : 'Не выбрано ни одной позиции',
      );
      return;
    }
    final ok = await confirm(
      context,
      title: 'Создать заказы?',
      message:
          'Будет создано черновиков: ${payload.length}\n'
          '${payload.entries.map((e) => '• ${names[e.key]}: ${e.value.length} поз.').join('\n')}'
          '${skipped > 0 ? '\n\n$skipped поз. без поставщика пропущены' : ''}',
      ok: 'Создать',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final done = await runGuarded(
      context,
      () => ref
          .read(purchasingRepoProvider)
          .createOrdersFromSuggestions(payload, userId: ref.read(sessionProvider)?.user.id),
      success: 'Создано черновиков заказов: ${payload.length}. Проверьте их во вкладке «Заказы»',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (done) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final suppliers = ref.watch(purSuppliersProvider).value ?? const <Supplier>[];
    final names = {for (final s in suppliers) s.id: s.name};
    final canCost = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    final toolbar = Wrap(
      spacing: Gap.m,
      runSpacing: Gap.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 200,
          child: TextField(
            controller: _days,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Запас на, дней', suffixText: 'дн.'),
            onSubmitted: (_) => _applyDays(),
          ),
        ),
        OutlinedButton.icon(onPressed: _applyDays, icon: const Icon(Icons.refresh), label: const Text('Пересчитать')),
        Text(
          'Средний расход считается по продажам за 30 дней; учтены остатки, минимум и уже заказанное.',
          style: t.textTheme.bodySmall,
        ),
      ],
    );

    Widget body;
    if (_error != null) {
      body = ErrorView(error: _error!, onRetry: _load);
    } else if (_rows == null) {
      body = const LoadingView();
    } else if (_rows!.isEmpty) {
      body = const EmptyState(
        icon: Icons.thumb_up_alt_outlined,
        title: 'Заказывать нечего',
        message: 'Запасов хватает на выбранный период. Задайте минимальные остатки в карточках товаров.',
      );
    } else {
      final groups = groupBy<_Row, String>(_rows!, (r) {
        final sid = r.s.product.supplierId;
        return sid != null && names.containsKey(sid) ? sid : _noSupplier;
      });
      final keys = groups.keys.toList()
        ..sort(
          (a, b) => a == _noSupplier
              ? 1
              : b == _noSupplier
              ? -1
              : (names[a] ?? '').compareTo(names[b] ?? ''),
        );
      final selectedCount = _rows!.where((r) => r.selected && r.q > 0).length;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ListView(children: [for (final k in keys) _group(k, groups[k]!, suppliers, names, canCost)])),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(top: Gap.s),
            child: Row(
              children: [
                Expanded(child: Text('Выбрано позиций: $selectedCount', style: t.textTheme.titleSmall)),
                FilledButton.icon(
                  onPressed: _busy || selectedCount == 0 ? null : () => _createOrders(groups, names),
                  icon: const Icon(Icons.playlist_add_check),
                  label: const Text('Создать заказы'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top inset keeps the floating field label inside the tab's clip.
        Padding(
          padding: const EdgeInsets.only(top: Gap.s),
          child: toolbar,
        ),
        const SizedBox(height: Gap.m),
        Expanded(child: body),
      ],
    );
  }

  Widget _group(String key, List<_Row> rows, List<Supplier> suppliers, Map<String, String> names, bool canCost) {
    final t = Theme.of(context);
    final total = rows.where((r) => r.selected).fold<int>(0, (s, r) => s + (r.q * r.s.product.costPrice).round());
    final allSel = rows.every((r) => r.selected);
    return Card(
      margin: const EdgeInsets.only(bottom: Gap.m),
      child: Padding(
        padding: const EdgeInsets.all(Gap.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Checkbox(
                  value: allSel,
                  onChanged: (v) => setState(() {
                    for (final r in rows) {
                      r.selected = v ?? false;
                    }
                  }),
                ),
                Expanded(
                  child: Text(
                    key == _noSupplier ? 'Без поставщика' : names[key] ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.titleMedium,
                  ),
                ),
                if (canCost) Text('≈ ${Money.format(total)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            if (key == _noSupplier)
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.s, 0, Gap.s, Gap.s),
                child: DropdownButtonFormField<String>(
                  key: ValueKey('assign${suppliers.length}'),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Заказать у поставщика',
                    helperText: 'У этих товаров поставщик не указан в карточке',
                  ),
                  initialValue: names.containsKey(_assign[_noSupplier]) ? _assign[_noSupplier] : null,
                  items: [
                    for (final s in suppliers)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => v == null ? _assign.remove(_noSupplier) : _assign[_noSupplier] = v),
                ),
              ),
            const Divider(),
            for (final r in rows) _row(r, canCost),
          ],
        ),
      ),
    );
  }

  Widget _row(_Row r, bool canCost) {
    final t = Theme.of(context);
    final p = r.s.product;
    final cover = r.s.daysOfCover;
    final urgent = p.stockQty <= 0 || (cover != null && cover < 3);
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(child: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis)),
            if (urgent) ...[const SizedBox(width: Gap.s), const StatusChip('Срочно', color: AppColors.danger)],
          ],
        ),
        Text(
          [
            'остаток ${Qty.format(p.stockQty, p.unit)}',
            if (p.minStock > 0) 'мин. ${Qty.format(p.minStock)}',
            'продаж/день ${r.s.avgDaily.toStringAsFixed(r.s.avgDaily >= 10 ? 0 : 2).replaceAll('.', ',')}',
            cover == null
                ? 'продаж не было'
                : 'хватит на ${cover.toStringAsFixed(cover >= 10 ? 0 : 1).replaceAll('.', ',')} дн.',
            if (r.s.onOrder > 0) 'уже в заказах ${Qty.format(r.s.onOrder)}',
          ].join(' · '),
          style: t.textTheme.bodySmall?.copyWith(color: urgent ? AppColors.danger : t.colorScheme.onSurfaceVariant),
        ),
      ],
    );
    final qty = SizedBox(
      width: 110,
      child: TextField(
        controller: r.qty,
        enabled: r.selected,
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          suffixText: Qty.unitLabel(p.unit),
          errorText: r.selected && _qtyError(r) != null ? _qtyError(r) : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
    final cost = canCost
        ? SizedBox(width: 110, child: Text(Money.format((r.q * p.costPrice).round()), textAlign: TextAlign.right))
        : null;
    final check = Checkbox(value: r.selected, onChanged: (v) => setState(() => r.selected = v ?? false));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs),
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth >= 560) {
            return Row(
              children: [
                check,
                Expanded(child: info),
                const SizedBox(width: Gap.s),
                qty,
                ?cost,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              check,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    info,
                    const SizedBox(height: Gap.xs),
                    Row(children: [qty, const Spacer(), ?cost]),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String? _qtyError(_Row r) {
    final q = QtyField.parse(r.qty.text);
    if (q == null || q <= 0) return 'больше 0';
    if (!Qty.isFractional(r.s.product.unit) && q != q.roundToDouble()) return 'целое';
    return null;
  }
}
