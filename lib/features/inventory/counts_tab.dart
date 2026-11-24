import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/pickers.dart';
import '../../core/widgets/widgets.dart';
import 'inventory_logic.dart';
import 'inventory_pdf.dart';

Color countStatusColor(String s) => switch (s) {
      'draft' => AppColors.warning,
      'completed' => AppColors.success,
      _ => AppColors.danger,
    };

/// «Инвентаризация»: list of counts with a master-detail editor.
class CountsTab extends ConsumerStatefulWidget {
  const CountsTab({super.key});
  @override
  ConsumerState<CountsTab> createState() => _CountsTabState();
}

class _CountsTabState extends ConsumerState<CountsTab> {
  String? _selected;

  Future<void> _create(bool wide) async {
    final id = await showFormDialog<String>(context, title: 'Новая инвентаризация', width: 560, child: const _CreateCount());
    if (id == null || !mounted) return;
    _open(id, wide);
  }

  void _open(String id, bool wide) {
    if (wide) {
      setState(() => _selected = id);
    } else {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Инвентаризация')),
          body: Padding(padding: const EdgeInsets.all(Gap.m), child: CountEditor(countId: id)),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 1000;
      final list = _CountList(
        selected: wide ? _selected : null,
        onOpen: (id) => _open(id, wide),
        onCreate: () => _create(wide),
      );
      if (!wide) return list;
      return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(width: 340, child: list),
        const VerticalDivider(width: Gap.xl),
        Expanded(
          child: _selected == null
              ? const EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'Выберите инвентаризацию',
                  message: 'или создайте новую, чтобы сверить фактические остатки с учётными')
              : CountEditor(key: ValueKey(_selected), countId: _selected!),
        ),
      ]);
    });
  }
}

class _CountList extends ConsumerWidget {
  const _CountList({required this.selected, required this.onOpen, required this.onCreate});
  final String? selected;
  final ValueChanged<String> onOpen;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Новая инвентаризация')),
      const SizedBox(height: Gap.m),
      Expanded(
        child: AsyncView(
          value: ref.watch(inventoryCountsProvider),
          data: (list) => list.isEmpty
              ? const EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'Инвентаризаций ещё не было',
                  message: 'Регулярные пересчёты помогают вовремя находить недостачи')
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) {
                    final c = list[i];
                    return ListTile(
                      selected: c.id == selected,
                      title: Text('Инвентаризация №${c.number}'),
                      subtitle: Text([
                        formatDateTime(c.createdAt),
                        if (c.note != null) c.note!,
                      ].join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: StatusChip(countStatusLabels[c.status] ?? c.status, color: countStatusColor(c.status)),
                      onTap: () => onOpen(c.id),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

// ------------------------------------------------------------------ create

class _CreateCount extends ConsumerStatefulWidget {
  const _CreateCount();
  @override
  ConsumerState<_CreateCount> createState() => _CreateCountState();
}

class _CreateCountState extends ConsumerState<_CreateCount> {
  CountScope _scope = CountScope.all;
  String? _categoryId;
  final _products = <Product>[];
  final _note = TextEditingController();
  bool _busy = false;

  Future<void> _addProduct() async {
    final p = await pickProduct(context, title: 'Добавить товар в инвентаризацию');
    if (p != null && !_products.any((x) => x.id == p.id)) setState(() => _products.add(p));
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_scope == CountScope.category && _categoryId == null) {
      showError(context, 'Выберите категорию');
      return;
    }
    if (_scope == CountScope.selected && _products.isEmpty) {
      showError(context, 'Добавьте хотя бы один товар');
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await ref.read(inventoryRepoProvider).createCount(
            scope: _scope,
            categoryId: _categoryId,
            productIds: _products.map((p) => p.id).toList(),
            userId: ref.read(sessionProvider)?.user.id,
            note: _note.text,
          );
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(invCategoriesProvider).value ?? const <Category>[];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Gap.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SegmentedButton<CountScope>(
          segments: const [
            ButtonSegment(value: CountScope.all, label: Text('Все товары')),
            ButtonSegment(value: CountScope.category, label: Text('Категория')),
            ButtonSegment(value: CountScope.selected, label: Text('Выбранные')),
          ],
          selected: {_scope},
          onSelectionChanged: (s) => setState(() => _scope = s.first),
        ),
        const SizedBox(height: Gap.m),
        if (_scope == CountScope.category)
          DropdownButtonFormField<String>(
            initialValue: _categoryId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Категория *'),
            items: [for (final c in cats) DropdownMenuItem(value: c.id, child: Text(c.name))],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
        if (_scope == CountScope.selected) ...[
          for (final p in _products)
            ListTile(
              dense: true,
              title: Text(p.name),
              subtitle: Text('остаток ${Qty.format(p.stockQty, p.unit)}'),
              trailing: IconButton(
                  tooltip: 'Убрать',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _products.remove(p))),
            ),
          OutlinedButton.icon(onPressed: _addProduct, icon: const Icon(Icons.add), label: const Text('Добавить товар')),
        ],
        const SizedBox(height: Gap.m),
        TextField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'Комментарий (зона, ответственный…)'),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: Gap.m),
        Text(
          'Учётные остатки фиксируются в момент создания. Продажи во время пересчёта учитываются '
          'при проведении: расхождение считается от текущего остатка.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Gap.l),
        FilledButton(onPressed: _busy ? null : _submit, child: const Text('Создать')),
      ]),
    );
  }
}

// ------------------------------------------------------------------ editor

enum _LineFilter { all, uncounted, diff }

final _countMovesProvider = StreamProvider.family<Map<String, double>, String>((ref, countId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.stockMovements)..where((m) => m.refType.equals('count') & m.refId.equals(countId)))
      .watch()
      .map((l) => {for (final m in l) m.productId: m.qty});
});

class CountEditor extends ConsumerStatefulWidget {
  const CountEditor({super.key, required this.countId});
  final String countId;
  @override
  ConsumerState<CountEditor> createState() => _CountEditorState();
}

class _CountEditorState extends ConsumerState<CountEditor> {
  final _ctl = <String, TextEditingController>{};
  final _pending = <String, double?>{};
  final _scan = TextEditingController();
  final _scanFocus = FocusNode();
  Timer? _save;
  String _q = '';
  _LineFilter _filter = _LineFilter.all;
  bool _busy = false;

  late final InventoryRepo _repo;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(inventoryRepoProvider);
  }

  @override
  void dispose() {
    _save?.cancel();
    if (_pending.isNotEmpty) {
      // Best-effort flush when leaving the editor.
      final p = Map.of(_pending);
      _repo.saveCounted(widget.countId, p).catchError((_) {});
    }
    for (final c in _ctl.values) {
      c.dispose();
    }
    _scan.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  TextEditingController _controller(InventoryCountItem it) => _ctl.putIfAbsent(
      it.id, () => TextEditingController(text: it.countedQty == null ? '' : _fmt(it.countedQty!)));

  String _fmt(double q) => Qty.format(q).replaceAll(',', '.');

  void _onEdit(InventoryCountItem it, String v, String unit) {
    final t = v.trim();
    final q = QtyField.parse(t);
    if (t.isEmpty) {
      _pending[it.id] = null;
    } else if (validateQty(q, unit, allowZero: true) == null) {
      _pending[it.id] = q;
    } else {
      _pending.remove(it.id); // invalid input is never saved
    }
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 700), _flush);
    setState(() {});
  }

  Future<void> _flush() async {
    _save?.cancel();
    if (_pending.isEmpty) return;
    final p = Map.of(_pending);
    _pending.clear();
    try {
      await _repo.saveCounted(widget.countId, p);
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() {});
  }

  /// Scans are processed strictly one after another: a hardware scanner can
  /// fire several codes before the drift stream delivers the previous write,
  /// and each +1 must build on the value actually stored.
  Future<void> _scanQueue = Future.value();

  void _onScan(String code) {
    final c = code.trim();
    _scan.clear();
    _scanFocus.requestFocus();
    if (c.isEmpty) return;
    _scanQueue = _scanQueue.then((_) => _scanOne(c)).catchError((Object e) {
      if (mounted) showError(context, e);
    });
  }

  Future<void> _scanOne(String c) async {
    if (!mounted) return;
    final db = ref.read(databaseProvider);
    final items = await (db.select(db.inventoryCountItems)
          ..where((i) => i.countId.equals(widget.countId) & i.deletedAt.isNull()))
        .get();
    final byProduct = {for (final i in items) i.productId: i};
    final products = ref.read(invProductMapProvider).value ?? const <String, Product>{};
    InventoryCountItem? it = items
        .where((i) => products[i.productId]?.barcode == c || products[i.productId]?.sku == c)
        .firstOrNull;
    Product? p = it == null ? null : products[it.productId];
    if (it == null) {
      final found = await findByCode(db, c);
      if (!mounted) return;
      if (found == null) {
        showError(context, 'Товар «$c» не найден');
        return;
      }
      p = found;
      it = byProduct[found.id];
      if (it == null) {
        final add = await confirm(context,
            title: 'Товара нет в ведомости',
            message: '«${found.name}» не входит в эту инвентаризацию. '
                'Добавить и засчитать 1 ${Qty.unitLabel(found.unit)}?',
            ok: 'Добавить');
        if (!add || !mounted) return;
        await runGuarded(context, () => _repo.addCountItem(widget.countId, found, counted: 1),
            success: '«${found.name}» добавлен: 1');
        if (mounted) _scanFocus.requestFocus();
        return;
      }
    }
    final item = it;
    final unit = p?.unit ?? 'pcs';
    // Unsaved typing wins over the stored value; otherwise use the DB value.
    final next = Qty.round((_pending.containsKey(item.id) ? _pending[item.id] : item.countedQty) ?? 0) + 1;
    _controller(item).text = _fmt(next);
    _pending[item.id] = next;
    await _flush();
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            duration: const Duration(milliseconds: 1200),
            content: Text('${p?.name ?? 'Товар'}: ${Qty.format(next, unit)}')));
    }
  }

  Future<void> _complete(InventoryCount count) async {
    await _scanQueue;
    await _flush();
    final lines = await _repo.loadLines(widget.countId);
    if (!mounted) return;
    final s = CountSummary.of(lines);
    if (s.counted == 0) {
      showError(context, 'Не введено ни одного фактического количества');
      return;
    }
    final canCost = ref.read(sessionProvider)?.can(Perm.viewCost) ?? false;
    String money(int v) => canCost ? ' на ${Money.format(v)}' : '';
    final ok = await confirm(
      context,
      title: 'Провести инвентаризацию №${count.number}?',
      message: [
        'Посчитано позиций: ${s.counted} из ${s.lines}.',
        if (s.uncounted > 0) 'Не посчитано: ${s.uncounted} — их остатки не изменятся.',
        'Излишки: ${s.surplusLines} поз.${money(s.surplusValue)}',
        'Недостача: ${s.shortageLines} поз.${money(s.shortageValue)}',
        if (canCost) 'Итог: ${Money.format(s.netValue)}',
        if (s.changedSinceStart > 0)
          '\nПо ${s.changedSinceStart} поз. остаток изменился после создания ведомости (продажи, приходы). '
              'Расхождения рассчитаны от ТЕКУЩЕГО остатка.',
        '\nОстатки будут приведены к фактическим. Действие необратимо.',
      ].join('\n'),
      ok: 'Провести',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    await runGuarded(context, () => _repo.completeCount(widget.countId, userId: ref.read(sessionProvider)?.user.id),
        success: 'Инвентаризация №${count.number} проведена');
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _cancel(InventoryCount count) async {
    final ok = await confirm(context,
        title: 'Отменить инвентаризацию №${count.number}?',
        message: 'Введённые данные сохранятся в истории, остатки не изменятся.',
        ok: 'Отменить инвентаризацию',
        destructive: true);
    if (!ok || !mounted) return;
    _pending.clear();
    await runGuarded(context, () => _repo.cancelCount(widget.countId, userId: ref.read(sessionProvider)?.user.id),
        success: 'Инвентаризация отменена');
  }

  Future<void> _print(InventoryCount count) async {
    await _flush();
    if (!mounted) return;
    await runGuarded(context,
        () => printCountSheet(ref.read(databaseProvider), _repo, count, showExpected: count.status != 'draft'));
  }

  @override
  Widget build(BuildContext context) {
    final countV = ref.watch(inventoryCountProvider(widget.countId));
    final itemsV = ref.watch(inventoryCountItemsProvider(widget.countId));
    final products = ref.watch(invProductMapProvider).value;
    final canCost = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    return AsyncView(
      value: countV,
      data: (count) {
        if (count == null) return const EmptyState(icon: Icons.search_off, title: 'Инвентаризация не найдена');
        return AsyncView(
          value: itemsV,
          data: (items) {
            if (products == null) return const LoadingView();
            final draft = count.status == 'draft';
            final posted = count.status == 'completed' ? ref.watch(_countMovesProvider(count.id)).value ?? const {} : const <String, double>{};
            // Merge pending (unsaved) values so totals update while typing.
            final lines = [
              for (final it in items)
                CountLine(_pending.containsKey(it.id) ? it.copyWith(countedQty: Value(_pending[it.id])) : it,
                    products[it.productId]),
            ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            final s = CountSummary.of(lines);
            final shown = lines.where((l) {
              if (_q.isNotEmpty && !(l.product != null && matchesQuery(l.product!, _q))) return false;
              return switch (_filter) {
                _LineFilter.all => true,
                _LineFilter.uncounted => l.item.countedQty == null,
                _LineFilter.diff => draft ? (l.diff != null && l.diff != 0) : (posted[l.item.productId] ?? 0) != 0,
              };
            }).toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _header(count, s, canCost, draft),
              if (draft && s.changedSinceStart > 0)
                Container(
                  margin: const EdgeInsets.only(top: Gap.s),
                  padding: const EdgeInsets.all(Gap.m),
                  decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: AppColors.warning),
                    const SizedBox(width: Gap.s),
                    Expanded(
                      child: Text(
                          'По ${s.changedSinceStart} поз. учётный остаток изменился после создания ведомости '
                          '(продажи/приходы). Расхождение считается от текущего остатка.'),
                    ),
                  ]),
                ),
              const SizedBox(height: Gap.m),
              LayoutBuilder(builder: (context, c) {
                final fieldW = c.maxWidth < 640 ? c.maxWidth : 300.0;
                return Wrap(spacing: Gap.m, runSpacing: Gap.s, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  if (draft)
                    SizedBox(
                      width: fieldW,
                      child: TextField(
                        controller: _scan,
                        focusNode: _scanFocus,
                        autofocus: true,
                        decoration: const InputDecoration(
                            labelText: 'Скан: +1 к факту', prefixIcon: Icon(Icons.qr_code_scanner)),
                        onSubmitted: _onScan,
                      ),
                    ),
                  SizedBox(
                      width: fieldW,
                      child: SearchField(hint: 'Поиск в ведомости', onChanged: (v) => setState(() => _q = v))),
                  Wrap(spacing: Gap.s, runSpacing: Gap.xs, children: [
                    for (final (f, label) in [
                      (_LineFilter.all, 'Все (${s.lines})'),
                      if (draft) (_LineFilter.uncounted, 'Не посчитано (${s.uncounted})'),
                      (_LineFilter.diff, 'Расхождения'),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                  ]),
                ]);
              }),
              const SizedBox(height: Gap.s),
              Expanded(
                child: shown.isEmpty
                    ? const EmptyState(icon: Icons.checklist, title: 'Нет строк по фильтру')
                    : ListView.separated(
                        itemCount: shown.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (_, i) => _lineRow(shown[i], draft, canCost, posted),
                      ),
              ),
            ]);
          },
        );
      },
    );
  }

  Widget _header(InventoryCount count, CountSummary s, bool canCost, bool draft) {
    final t = Theme.of(context);
    final users = ref.watch(invUserNamesProvider).value ?? const {};
    final title = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Flexible(child: Text('Инвентаризация №${count.number}', style: t.textTheme.titleLarge)),
        const SizedBox(width: Gap.s),
        StatusChip(countStatusLabels[count.status] ?? count.status, color: countStatusColor(count.status)),
      ]),
      Text(
          [
            'создана ${formatDateTime(count.createdAt)}',
            if (users[count.userId] != null) users[count.userId]!,
            if (count.completedAt != null) 'проведена ${formatDateTime(count.completedAt!)}',
            if (count.note != null) count.note!,
          ].join(' · '),
          style: t.textTheme.bodySmall),
      const SizedBox(height: Gap.s),
      Wrap(spacing: Gap.s, runSpacing: Gap.xs, children: [
        StatusChip('Посчитано ${s.counted}/${s.lines}', color: AppColors.info),
        if (draft) ...[
          StatusChip('Излишки ${s.surplusLines}${canCost ? ' · ${Money.format(s.surplusValue)}' : ''}',
              color: AppColors.success),
          StatusChip('Недостача ${s.shortageLines}${canCost ? ' · ${Money.format(s.shortageValue)}' : ''}',
              color: AppColors.danger),
        ],
        if (_pending.isNotEmpty) const StatusChip('Сохранение…', color: AppColors.warning),
      ]),
    ]);
    final actions = Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
      OutlinedButton.icon(onPressed: () => _print(count), icon: const Icon(Icons.print_outlined), label: const Text('Бланк')),
      if (draft) ...[
        OutlinedButton(
            onPressed: _busy ? null : () => _cancel(count),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Отменить')),
        OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    await _flush();
                    if (mounted) showSuccess(context, 'Черновик сохранён');
                  },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Сохранить')),
        FilledButton.icon(
            onPressed: _busy ? null : () => _complete(count),
            icon: const Icon(Icons.task_alt),
            label: const Text('Провести')),
      ],
    ]);
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 760) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: Gap.s), actions]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: title),
        const SizedBox(width: Gap.m),
        Flexible(child: Align(alignment: Alignment.topRight, child: actions)),
      ]);
    });
  }

  Widget _lineRow(CountLine l, bool draft, bool canCost, Map<String, double> posted) {
    final t = Theme.of(context);
    final it = l.item;
    final diff = draft ? l.diff : posted[it.productId];
    final diffColor = diff == null || diff == 0 ? null : (diff > 0 ? AppColors.success : AppColors.danger);
    final sub = [
      if (l.product?.barcode != null) l.product!.barcode!,
      'учёт ${Qty.format(it.expectedQty, l.unit)}',
      if (draft && l.stockChanged) 'сейчас ${Qty.format(l.currentQty, l.unit)}',
    ].join(' · ');
    final diffText = diff == null
        ? Text('—', style: t.textTheme.bodySmall)
        : Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
            Text('${diff > 0 ? '+' : ''}${Qty.format(diff)}',
                style: TextStyle(fontWeight: FontWeight.w700, color: diffColor)),
            if (canCost && diff != 0)
              Text(Money.format(lineValue(diff, l.unitCost)), style: t.textTheme.bodySmall?.copyWith(color: diffColor)),
          ]);
    final field = draft
        ? SizedBox(
            width: 110,
            child: TextField(
              controller: _controller(it),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'факт',
                suffixText: Qty.unitLabel(l.unit),
                errorText: _invalid(it, l.unit),
              ),
              onChanged: (v) => _onEdit(it, v, l.unit),
              onSubmitted: (_) => _flush(),
            ),
          )
        : SizedBox(
            width: 90,
            child: Text(it.countedQty == null ? 'не считали' : Qty.format(it.countedQty!, l.unit),
                textAlign: TextAlign.right),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs, horizontal: Gap.s),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.bodySmall?.copyWith(
                    color: draft && l.stockChanged ? AppColors.warning : t.colorScheme.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(width: Gap.s),
        field,
        const SizedBox(width: Gap.s),
        SizedBox(width: 96, child: Align(alignment: Alignment.centerRight, child: diffText)),
      ]),
    );
  }

  String? _invalid(InventoryCountItem it, String unit) {
    final text = _ctl[it.id]?.text.trim() ?? '';
    if (text.isEmpty) return null;
    final q = QtyField.parse(text);
    if (q == null) return 'число?';
    return validateQty(q, unit, allowZero: true) == null ? null : 'неверно';
  }
}
