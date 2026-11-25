import '../../core/doc_number.dart';
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
import 'stock_tab.dart' show InvChipBar;
import '../../l10n/l10n.dart';

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
    final id = await showFormDialog<String>(
      context,
      title: context.l10n.invNewCount,
      width: 560,
      child: const _CreateCount(),
    );
    if (id == null || !mounted) return;
    _open(id, wide);
  }

  void _open(String id, bool wide) {
    if (wide) {
      setState(() => _selected = id);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(context.l10n.invCount)),
            body: Padding(
              padding: const EdgeInsets.all(Gap.m),
              child: CountEditor(countId: id),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1000;
        final list = _CountList(
          selected: wide ? _selected : null,
          onOpen: (id) => _open(id, wide),
          onCreate: () => _create(wide),
        );
        if (!wide) return list;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 340, child: list),
            const VerticalDivider(width: Gap.xl),
            Expanded(
              child: _selected == null
                  ? EmptyState(
                      icon: Icons.fact_check_outlined,
                      title: context.l10n.invSelectCount,
                      message: context.l10n.invSelectCountMessage,
                    )
                  : CountEditor(key: ValueKey(_selected), countId: _selected!),
            ),
          ],
        );
      },
    );
  }
}

class _CountList extends ConsumerWidget {
  const _CountList({required this.selected, required this.onOpen, required this.onCreate});
  final String? selected;
  final ValueChanged<String> onOpen;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full width in the narrow master pane / on phones; natural width when
        // the list spans a tablet screen, so the button isn't a 900px bar.
        LayoutBuilder(
          builder: (context, c) {
            final btn = FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(l.invNewCount),
            );
            return c.maxWidth > 560 ? Align(alignment: Alignment.centerLeft, child: btn) : btn;
          },
        ),
        const SizedBox(height: Gap.m),
        Expanded(
          child: AsyncView(
            value: ref.watch(inventoryCountsProvider),
            data: (list) => list.isEmpty
                ? EmptyState(
                    icon: Icons.fact_check_outlined,
                    title: l.invNoCountsYet,
                    message: l.invNoCountsMessage,
                  )
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (_, i) {
                      final c = list[i];
                      return ListTile(
                        selected: c.id == selected,
                        title: Text(l.invCountTitle(docNo(c.number, c.deviceCode))),
                        subtitle: Text(
                          [formatDateTime(c.createdAt), if (c.note != null) c.note!].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: StatusChip(
                          countStatusLabelsOf(l)[c.status] ?? c.status,
                          color: countStatusColor(c.status),
                        ),
                        onTap: () => onOpen(c.id),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
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
    final p = await pickProduct(context, title: context.l10n.invAddToCount);
    if (p != null && !_products.any((x) => x.id == p.id)) setState(() => _products.add(p));
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_scope == CountScope.category && _categoryId == null) {
      showError(context, context.l10n.invSelectCategory);
      return;
    }
    if (_scope == CountScope.selected && _products.isEmpty) {
      showError(context, context.l10n.invAddAtLeastOneProduct);
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await ref
          .read(inventoryRepoProvider)
          .createCount(
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
    final l = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<CountScope>(
            // On phones the check icon squeezed «Все товары» into three lines.
            showSelectedIcon: !context.isCompact,
            segments: [
              ButtonSegment(value: CountScope.all, label: Text(context.isCompact ? l.commonAll : l.invAllProducts)),
              ButtonSegment(value: CountScope.category, label: Text(l.commonCategory)),
              ButtonSegment(value: CountScope.selected, label: Text(l.invSelected)),
            ],
            selected: {_scope},
            onSelectionChanged: (s) => setState(() => _scope = s.first),
          ),
          const SizedBox(height: Gap.m),
          if (_scope == CountScope.category)
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.invCategoryRequired),
              items: [for (final c in cats) DropdownMenuItem(value: c.id, child: Text(c.name))],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
          if (_scope == CountScope.selected) ...[
            for (final p in _products)
              ListTile(
                dense: true,
                title: Text(p.name),
                subtitle: Text(l.invStockAfter(Qty.format(p.stockQty, p.unit))),
                trailing: IconButton(
                  tooltip: l.invRemove,
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _products.remove(p)),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _addProduct,
              icon: const Icon(Icons.add),
              label: Text(l.invAddProduct),
            ),
          ],
          const SizedBox(height: Gap.m),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.commonComment, hintText: l.invCountNoteHint),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Gap.m),
          Text(
            l.invCountCreateInfo,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Gap.l),
          FilledButton(onPressed: _busy ? null : _submit, child: Text(l.commonCreate)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ editor

enum _LineFilter { all, uncounted, diff }

final _countMovesProvider = StreamProvider.family<Map<String, double>, String>((ref, countId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.stockMovements)..where((m) => m.refType.equals('count') & m.refId.equals(countId))).watch().map(
    (l) => {for (final m in l) m.productId: m.qty},
  );
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

  TextEditingController _controller(InventoryCountItem it) =>
      _ctl.putIfAbsent(it.id, () => TextEditingController(text: it.countedQty == null ? '' : _fmt(it.countedQty!)));

  String _fmt(double q) => Qty.format(q);

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
    final l = context.l10n;
    final db = ref.read(databaseProvider);
    final items = await (db.select(
      db.inventoryCountItems,
    )..where((i) => i.countId.equals(widget.countId) & i.deletedAt.isNull())).get();
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
        showError(context, l.invProductNotFound(c));
        return;
      }
      p = found;
      it = byProduct[found.id];
      if (it == null) {
        final add = await confirm(
          context,
          title: l.invNotInSheetTitle,
          message: l.invNotInSheetMessage(found.name, Qty.unitLabel(found.unit, l)),
          ok: l.commonAdd,
        );
        if (!add || !mounted) return;
        await runGuarded(
          context,
          () => _repo.addCountItem(widget.countId, found, counted: 1),
          success: l.invAddedOne(found.name),
        );
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
        ..showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1200),
            content: Text('${p?.name ?? l.commonProduct}: ${Qty.format(next, unit)}'),
          ),
        );
    }
  }

  Future<void> _complete(InventoryCount count) async {
    await _scanQueue;
    await _flush();
    final lines = await _repo.loadLines(widget.countId);
    if (!mounted) return;
    final l = context.l10n;
    final s = CountSummary.of(lines);
    if (s.counted == 0) {
      showError(context, l.invNoCountedQty);
      return;
    }
    final canCost = ref.read(sessionProvider)?.can(Perm.viewCost) ?? false;
    final ok = await confirm(
      context,
      title: l.invCompleteTitle(docNo(count.number, count.deviceCode)),
      message: [
        l.invCompleteCounted('${s.counted}', '${s.lines}'),
        if (s.uncounted > 0) l.invCompleteUncounted('${s.uncounted}'),
        canCost
            ? l.invCompleteSurplusSum('${s.surplusLines}', Money.format(s.surplusValue))
            : l.invCompleteSurplus('${s.surplusLines}'),
        canCost
            ? l.invCompleteShortageSum('${s.shortageLines}', Money.format(s.shortageValue))
            : l.invCompleteShortage('${s.shortageLines}'),
        if (canCost) l.invCompleteNet(Money.format(s.netValue)),
        if (s.changedSinceStart > 0) '\n${l.invCompleteChanged('${s.changedSinceStart}')}',
        '\n${l.invCompleteFinal}',
      ].join('\n'),
      ok: l.invPost,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    await runGuarded(
      context,
      () => _repo.completeCount(widget.countId, userId: ref.read(sessionProvider)?.user.id),
      success: l.invCountCompletedToast(docNo(count.number, count.deviceCode)),
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _cancel(InventoryCount count) async {
    final l = context.l10n;
    final ok = await confirm(
      context,
      title: l.invCancelCountTitle(docNo(count.number, count.deviceCode)),
      message: l.invCancelCountMessage,
      ok: l.invCancelCount,
      destructive: true,
    );
    if (!ok || !mounted) return;
    _pending.clear();
    await runGuarded(
      context,
      () => _repo.cancelCount(widget.countId, userId: ref.read(sessionProvider)?.user.id),
      success: l.invCountCancelledToast,
    );
  }

  Future<void> _print(InventoryCount count) async {
    await _flush();
    if (!mounted) return;
    await runGuarded(
      context,
      () => printCountSheet(ref.read(databaseProvider), _repo, count, showExpected: count.status != 'draft'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countV = ref.watch(inventoryCountProvider(widget.countId));
    final itemsV = ref.watch(inventoryCountItemsProvider(widget.countId));
    final products = ref.watch(invProductMapProvider).value;
    final canCost = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    final l = context.l10n;
    return AsyncView(
      value: countV,
      data: (count) {
        if (count == null) return EmptyState(icon: Icons.search_off, title: l.invCountNotFound);
        return AsyncView(
          value: itemsV,
          data: (items) {
            if (products == null) return const LoadingView();
            final draft = count.status == 'draft';
            final posted = count.status == 'completed'
                ? ref.watch(_countMovesProvider(count.id)).value ?? const {}
                : const <String, double>{};
            // Merge pending (unsaved) values so totals update while typing.
            final lines = [
              for (final it in items)
                CountLine(
                  _pending.containsKey(it.id) ? it.copyWith(countedQty: Value(_pending[it.id])) : it,
                  products[it.productId],
                ),
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(count, s, canCost, draft),
                if (draft && s.changedSinceStart > 0)
                  Container(
                    margin: const EdgeInsets.only(top: Gap.s),
                    padding: const EdgeInsets.all(Gap.m),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.warning),
                        const SizedBox(width: Gap.s),
                        Expanded(
                          child: Text(l.invChangedWarning('${s.changedSinceStart}')),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: Gap.m),
                LayoutBuilder(
                  builder: (context, c) {
                    final fieldW = c.maxWidth < 640 ? c.maxWidth : 300.0;
                    return Wrap(
                      spacing: Gap.m,
                      runSpacing: Gap.s,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (draft)
                          SizedBox(
                            width: fieldW,
                            child: TextField(
                              controller: _scan,
                              focusNode: _scanFocus,
                              autofocus: true,
                              decoration: InputDecoration(
                                labelText: l.invScanPlusOne,
                                prefixIcon: const Icon(Icons.qr_code_scanner),
                              ),
                              onSubmitted: _onScan,
                            ),
                          ),
                        SizedBox(
                          width: fieldW,
                          child: SearchField(hint: l.invSearchInSheet, onChanged: (v) => setState(() => _q = v)),
                        ),
                        InvChipBar(
                          children: [
                            for (final (f, label) in [
                              (_LineFilter.all, l.invFilterAllCount('${s.lines}')),
                              if (draft) (_LineFilter.uncounted, l.invFilterUncounted('${s.uncounted}')),
                              (_LineFilter.diff, l.invDiscrepancies),
                            ])
                              ChoiceChip(
                                label: Text(label),
                                selected: _filter == f,
                                onSelected: (_) => setState(() => _filter = f),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: Gap.s),
                if (shown.isNotEmpty) _columnsHeader(draft),
                Expanded(
                  child: shown.isEmpty
                      ? EmptyState(icon: Icons.checklist, title: l.invNoLinesForFilter)
                      : ListView.separated(
                          itemCount: shown.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (_, i) => _lineRow(shown[i], draft, canCost, posted),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _header(InventoryCount count, CountSummary s, bool canCost, bool draft) {
    final t = Theme.of(context);
    final l = context.l10n;
    final users = ref.watch(invUserNamesProvider).value ?? const {};
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(child: Text(l.invCountTitle(docNo(count.number, count.deviceCode)), style: t.textTheme.titleLarge)),
            const SizedBox(width: Gap.s),
            StatusChip(countStatusLabelsOf(l)[count.status] ?? count.status, color: countStatusColor(count.status)),
          ],
        ),
        Text(
          [
            l.invCreatedAt(formatDateTime(count.createdAt)),
            if (users[count.userId] != null) users[count.userId]!,
            if (count.completedAt != null) l.invCompletedAt(formatDateTime(count.completedAt!)),
            if (count.note != null) count.note!,
          ].join(' · '),
          style: t.textTheme.bodySmall,
        ),
        const SizedBox(height: Gap.s),
        Wrap(
          spacing: Gap.s,
          runSpacing: Gap.xs,
          children: [
            StatusChip(l.invCountedChip('${s.counted}', '${s.lines}'), color: AppColors.info),
            if (draft) ...[
              StatusChip(
                '${l.invSurplusChip('${s.surplusLines}')}${canCost ? ' · ${Money.format(s.surplusValue)}' : ''}',
                color: AppColors.success,
              ),
              StatusChip(
                '${l.invShortageChip('${s.shortageLines}')}${canCost ? ' · ${Money.format(s.shortageValue)}' : ''}',
                color: AppColors.danger,
              ),
            ],
            if (_pending.isNotEmpty) StatusChip(l.invSaving, color: AppColors.warning),
          ],
        ),
      ],
    );
    Future<void> save() async {
      await _flush();
      if (mounted) showSuccess(context, l.invDraftSaved);
    }

    final complete = FilledButton.icon(
      onPressed: _busy ? null : () => _complete(count),
      icon: const Icon(Icons.task_alt),
      label: Text(l.invPost),
    );
    final actions = Wrap(
      spacing: Gap.s,
      runSpacing: Gap.s,
      children: [
        OutlinedButton.icon(
          onPressed: () => _print(count),
          icon: const Icon(Icons.print_outlined),
          label: Text(l.invBlank),
        ),
        if (draft) ...[
          OutlinedButton(
            onPressed: _busy ? null : () => _cancel(count),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l.invCancelShort),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : save,
            icon: const Icon(Icons.save_outlined),
            label: Text(l.commonSave),
          ),
          complete,
        ],
      ],
    );
    // Phones: one compact toolbar row (icon buttons + primary action) so the
    // count sheet keeps most of the screen.
    final compactActions = Row(
      children: [
        IconButton.outlined(tooltip: l.invBlank, onPressed: () => _print(count), icon: const Icon(Icons.print_outlined)),
        if (draft) ...[
          IconButton.outlined(
            tooltip: l.commonSave,
            onPressed: _busy ? null : save,
            icon: const Icon(Icons.save_outlined),
          ),
          IconButton.outlined(
            tooltip: l.invCancelShort,
            color: AppColors.danger,
            onPressed: _busy ? null : () => _cancel(count),
            icon: const Icon(Icons.block),
          ),
          const SizedBox(width: Gap.s),
          Expanded(child: complete),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: Gap.s),
              c.maxWidth < 480 ? compactActions : actions,
            ],
          );
        }
        // Actions keep their natural width so «Провести» stays on the same
        // line as the rest instead of wrapping under them.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: Gap.m),
            actions,
          ],
        );
      },
    );
  }

  // Narrower qty/diff columns on phones leave room for product names.
  double get _factW => context.isCompact ? 96 : 110;
  double get _diffW => context.isCompact ? 80 : 110;

  Widget _columnsHeader(bool draft) {
    final t = Theme.of(context);
    final st = t.textTheme.labelMedium?.copyWith(color: t.colorScheme.onSurfaceVariant);
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: Gap.xs),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(context.isCompact ? l.commonProduct : l.invProductBookStock, style: st)),
          const SizedBox(width: Gap.s),
          SizedBox(
            width: draft ? _factW : 90,
            child: Text(l.invFact, textAlign: TextAlign.right, style: st),
          ),
          const SizedBox(width: Gap.s),
          SizedBox(
            width: _diffW,
            child: Text(l.invDiff, textAlign: TextAlign.right, style: st),
          ),
        ],
      ),
    );
  }

  Widget _lineRow(CountLine l, bool draft, bool canCost, Map<String, double> posted) {
    final t = Theme.of(context);
    final tr = context.l10n;
    final it = l.item;
    final diff = draft ? l.diff : posted[it.productId];
    final diffColor = diff == null || diff == 0 ? null : (diff > 0 ? AppColors.success : AppColors.danger);
    final sub = [
      // Quantities first: on phones the barcode is what gets ellipsized.
      tr.invBookShort(Qty.format(it.expectedQty, l.unit)),
      if (draft && l.stockChanged) tr.invNowShort(Qty.format(l.currentQty, l.unit)),
      if (l.product?.barcode != null) l.product!.barcode!,
    ].join(' · ');
    final diffText = diff == null
        ? Text('—', style: t.textTheme.bodySmall)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${diff > 0 ? '+' : ''}${Qty.format(diff)}',
                style: TextStyle(fontWeight: FontWeight.w700, color: diffColor),
              ),
              if (canCost && diff != 0)
                Text(
                  Money.format(lineValue(diff, l.unitCost)),
                  style: t.textTheme.bodySmall?.copyWith(color: diffColor),
                ),
            ],
          );
    final field = draft
        ? SizedBox(
            width: _factW,
            child: TextField(
              controller: _controller(it),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: context.isCompact ? null : tr.invFactHint,
                suffixText: Qty.unitLabel(l.unit),
                errorText: _invalid(it, l.unit),
              ),
              onChanged: (v) => _onEdit(it, v, l.unit),
              onSubmitted: (_) => _flush(),
            ),
          )
        : SizedBox(
            width: 90,
            child: Text(
              it.countedQty == null ? tr.invNotCounted : Qty.format(it.countedQty!, l.unit),
              textAlign: TextAlign.right,
            ),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs, horizontal: Gap.s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.bodySmall?.copyWith(
                    color: draft && l.stockChanged ? AppColors.warning : t.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.s),
          field,
          const SizedBox(width: Gap.s),
          SizedBox(
            width: _diffW,
            // Scale long amounts down instead of wrapping «сум» onto a new line.
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: diffText),
            ),
          ),
        ],
      ),
    );
  }

  String? _invalid(InventoryCountItem it, String unit) {
    final text = _ctl[it.id]?.text.trim() ?? '';
    if (text.isEmpty) return null;
    final q = QtyField.parse(text);
    if (q == null) return context.l10n.invNumberQ;
    return validateQty(q, unit, allowZero: true) == null ? null : context.l10n.invInvalidShort;
  }
}
