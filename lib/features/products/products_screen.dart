import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'bulk_dialogs.dart';
import 'categories_dialog.dart';
import 'import_export.dart';
import 'price_labels.dart';
import 'product_detail.dart';
import 'product_editor.dart';
import 'product_logic.dart';
import 'product_widgets.dart';
import 'products_repo.dart';

const _pageSize = 100;

/// Products catalog: search/filter/sort a live list (paged in SQL), product
/// detail (master-detail on wide screens), editor, categories, bulk actions,
/// CSV import/export and price labels.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  ProductQuery _q = const ProductQuery(limit: _pageSize);
  final _searchCtl = TextEditingController();
  final _searchFocus = FocusNode();
  final Set<String> _checked = {};
  bool _selectionMode = false;
  String? _openId;
  List<Product>? _last;
  int _requestedLimit = _pageSize;

  @override
  void dispose() {
    _searchCtl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _setQuery(ProductQuery q) => setState(() {
        _q = q.copyWith(limit: _pageSize);
        _requestedLimit = _pageSize;
      });

  void _loadMore() {
    if (_requestedLimit > _q.limit) return;
    _requestedLimit = _q.limit + _pageSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _q = _q.copyWith(limit: _requestedLimit));
    });
  }

  void _resetFilters() {
    _searchCtl.clear();
    _setQuery(const ProductQuery());
  }

  Future<void> _create({String? barcode}) async {
    final cat = _q.categoryId == noCategoryId ? null : _q.categoryId;
    final id = await openProductEditor(context, categoryId: cat, barcode: barcode);
    if (id != null && mounted && context.isWide) setState(() => _openId = id);
  }

  void _open(Product p) {
    if (_selectionMode) {
      _toggle(p.id, !_checked.contains(p.id));
      return;
    }
    if (context.isWide) {
      setState(() => _openId = p.id);
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailPage(productId: p.id)));
    }
  }

  void _toggle(String id, bool on) => setState(() {
        on ? _checked.add(id) : _checked.remove(id);
        if (_checked.isEmpty) _selectionMode = false;
      });

  void _exitSelection() => setState(() {
        _checked.clear();
        _selectionMode = false;
      });

  /// Scanner-friendly: Enter in the search box with an exact barcode/SKU
  /// opens the product, or offers to create one with that barcode.
  Future<void> _onSearchSubmitted(String v) async {
    final code = v.trim();
    if (code.isEmpty) return;
    final repo = ref.read(productsRepoProvider);
    final p = await repo.findByCode(code);
    if (!mounted) return;
    if (p != null) {
      _open(p);
      return;
    }
    final canEdit = ref.read(sessionProvider)?.can(Perm.editProducts) ?? false;
    final looksLikeBarcode = RegExp(r'^\d{8,14}$').hasMatch(code);
    if (canEdit && looksLikeBarcode) {
      final ok = await confirm(context,
          title: 'Товар не найден',
          message: 'Штрихкода $code нет в каталоге. Создать новый товар с этим штрихкодом?',
          ok: 'Создать');
      if (ok && mounted) await _create(barcode: code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();
    ref.watch(settingsProvider); // keeps Money.currency in sync
    final canEdit = session.can(Perm.editProducts);
    final canPrices = session.can(Perm.editPrices);
    final canCost = session.can(Perm.viewCost);
    final wide = context.isWide;
    final compact = context.isCompact;

    final listAsync = ref.watch(productListProvider(_q));
    if (listAsync.hasValue) _last = listAsync.value;
    final count = ref.watch(productCountProvider(_q.unlimited)).value;
    final cats = ref.watch(productCategoriesProvider).value ?? const <Category>[];
    final catById = {for (final c in cats) c.id: c};

    final menu = PopupMenuButton<String>(
      tooltip: 'Ещё',
      icon: const Icon(Icons.more_vert),
      onSelected: (v) {
        switch (v) {
          case 'categories':
            showCategoriesManager(context);
          case 'import':
            showImportDialog(context);
          case 'export':
            exportProductsCsv(context, ref, _q);
        }
      },
      itemBuilder: (_) => [
        if (compact)
          const PopupMenuItem(
              value: 'categories',
              child: ListTile(leading: Icon(Icons.category_outlined), title: Text('Категории'))),
        if (canEdit)
          const PopupMenuItem(
              value: 'import',
              child: ListTile(leading: Icon(Icons.upload_file_outlined), title: Text('Импорт из CSV'))),
        PopupMenuItem(
            value: 'export',
            child: ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Экспорт в CSV'),
                subtitle: Text(_q.isFiltered ? 'по текущему фильтру' : 'весь каталог'))),
      ],
    );

    final actions = <Widget>[
      if (!compact)
        TextButton.icon(
          onPressed: () => showCategoriesManager(context),
          icon: const Icon(Icons.category_outlined),
          label: const Text('Категории'),
        ),
      menu,
      if (canEdit && !compact) ...[
        const SizedBox(width: Gap.s),
        Tooltip(
          message: 'Ctrl+N',
          child: FilledButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.add),
            label: const Text('Новый товар'),
          ),
        ),
      ],
    ];

    final listPane = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _filterBar(cats, compact),
      _summaryBar(count, canEdit, canPrices),
      const Divider(),
      ProductTableHeader(
        showCost: canCost,
        leading: _selectionMode
            ? Checkbox(
                tristate: true,
                value: _checked.isEmpty
                    ? false
                    : (_last != null && _last!.every((p) => _checked.contains(p.id)) ? true : null),
                onChanged: (_) => setState(() {
                  final all = _last ?? const <Product>[];
                  if (all.every((p) => _checked.contains(p.id))) {
                    _checked.clear();
                    _selectionMode = false;
                  } else {
                    _checked.addAll(all.map((p) => p.id));
                  }
                }),
              )
            : null,
      ),
      Expanded(child: _list(listAsync, catById, canCost, canEdit)),
    ]);

    Widget body = listPane;
    if (wide && _openId != null) {
      final detailW = (context.width * 0.36).clamp(380.0, 560.0);
      body = Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: listPane),
        const VerticalDivider(width: 1),
        SizedBox(
          width: detailW,
          child: ProductDetailView(
            key: ValueKey(_openId),
            productId: _openId!,
            onClose: () => setState(() => _openId = null),
            onDeleted: () => setState(() => _openId = null),
          ),
        ),
      ]);
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          if (canEdit) _create();
        },
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () => _searchFocus.requestFocus(),
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_selectionMode) {
            _exitSelection();
          } else if (_openId != null) {
            setState(() => _openId = null);
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: PageScaffold(
          title: 'Товары',
          padding: EdgeInsets.zero,
          actions: actions,
          fab: canEdit && compact
              ? FloatingActionButton(
                  onPressed: _create, tooltip: 'Новый товар', child: const Icon(Icons.add))
              : null,
          body: body,
        ),
      ),
    );
  }

  // ------------------------------------------------------------- filter bar

  Widget _filterBar(List<Category> cats, bool compact) {
    final cat = _q.categoryId == null
        ? null
        : _q.categoryId == noCategoryId
            ? 'Без категории'
            : cats.where((c) => c.id == _q.categoryId).firstOrNull?.name;
    final search = SearchField(
      controller: _searchCtl,
      focusNode: _searchFocus,
      hint: 'Название, артикул или штрихкод (Ctrl+F)',
      onChanged: (v) => _setQuery(_q.copyWith(search: v)),
      onSubmitted: _onSearchSubmitted,
    );
    final chips = <Widget>[
      _MenuChip<String?>(
        icon: Icons.category_outlined,
        label: cat ?? 'Все категории',
        active: _q.categoryId != null,
        items: [
          const _MenuItem(null, 'Все категории'),
          const _MenuItem(noCategoryId, 'Без категории', leading: CategoryDot()),
          for (final c in cats) _MenuItem(c.id, c.name, leading: CategoryDot(color: c.color)),
        ],
        onSelected: (v) => _setQuery(_q.copyWith(categoryId: () => v)),
      ),
      _MenuChip<StockFilter>(
        icon: Icons.warehouse_outlined,
        label: _q.stock.label,
        active: _q.stock != StockFilter.all,
        items: [for (final s in StockFilter.values) _MenuItem(s, s.label)],
        onSelected: (v) => _setQuery(_q.copyWith(stock: v)),
      ),
      _MenuChip<ActiveFilter>(
        icon: Icons.inventory_outlined,
        label: _q.active.label,
        active: _q.active != ActiveFilter.active,
        items: [for (final a in ActiveFilter.values) _MenuItem(a, a.label)],
        onSelected: (v) => _setQuery(_q.copyWith(active: v)),
      ),
      FilterChip(
        avatar: Icon(_q.favoritesOnly ? Icons.star : Icons.star_outline, size: 18),
        label: const Text('Избранные'),
        selected: _q.favoritesOnly,
        showCheckmark: false,
        onSelected: (v) => _setQuery(_q.copyWith(favoritesOnly: v)),
      ),
      _MenuChip<ProductSort>(
        icon: _q.descending ? Icons.arrow_downward : Icons.arrow_upward,
        label: _q.sort.label,
        active: _q.sort != ProductSort.name || _q.descending,
        items: [for (final s in ProductSort.values) _MenuItem(s, s.label)],
        onSelected: (v) => _setQuery(
            v == _q.sort ? _q.copyWith(descending: !_q.descending) : _q.copyWith(sort: v, descending: false)),
        tooltip: 'Сортировка (повторный выбор — обратный порядок)',
      ),
      if (_q.isFiltered)
        TextButton.icon(
          onPressed: _resetFilters,
          icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
          label: const Text('Сбросить'),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.l, Gap.s),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        search,
        const SizedBox(height: Gap.s),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final c in chips) ...[c, const SizedBox(width: Gap.s)],
          ]),
        ),
      ]),
    );
  }

  // ------------------------------------------------------------ summary bar

  Widget _summaryBar(int? count, bool canEdit, bool canPrices) {
    final t = Theme.of(context);
    if (!_selectionMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.s, Gap.xs),
        child: Row(children: [
          Expanded(
            child: Text(count == null ? 'Загрузка…' : 'Товаров: $count',
                style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _selectionMode = true),
            icon: const Icon(Icons.checklist, size: 18),
            label: const Text('Выбрать'),
          ),
        ]),
      );
    }
    final ids = Set<String>.of(_checked);
    final none = ids.isEmpty;
    final buttons = <(IconData, String, VoidCallback?, String?)>[
      (Icons.category_outlined, 'Категория', !canEdit || none ? null : () => _afterBulk(showBulkCategoryDialog(context, ref, ids)),
          canEdit ? null : 'Нет права редактировать товары'),
      (Icons.price_change_outlined, 'Цены, %', !canPrices || none ? null : () => _afterBulk(showBulkPriceDialog(context, ids)),
          canPrices ? null : 'Нет права менять цены'),
      (Icons.local_offer_outlined, 'Ценники', none ? null : () => showPriceLabelsDialog(context, ids), null),
      (Icons.archive_outlined, 'В архив', !canEdit || none ? null : () => _bulkActive(ids, false),
          canEdit ? null : 'Нет права редактировать товары'),
      (Icons.unarchive_outlined, 'Вернуть', !canEdit || none ? null : () => _bulkActive(ids, true),
          canEdit ? null : 'Нет права редактировать товары'),
      (Icons.download_outlined, 'Экспорт', none ? null : () => exportProductsCsv(context, ref, _q, ids: ids), null),
    ];
    return Container(
      color: t.colorScheme.primaryContainer.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: Gap.xs),
      child: Row(children: [
        IconButton(tooltip: 'Отменить выбор (Esc)', onPressed: _exitSelection, icon: const Icon(Icons.close)),
        Text('Выбрано: ${ids.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: Gap.s),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            if (c.maxWidth < 560) {
              return Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<int>(
                  tooltip: 'Действия',
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (i) => buttons[i].$3?.call(),
                  itemBuilder: (_) => [
                    for (var i = 0; i < buttons.length; i++)
                      PopupMenuItem(
                        value: i,
                        enabled: buttons[i].$3 != null,
                        child: ListTile(leading: Icon(buttons[i].$1), title: Text(buttons[i].$2)),
                      ),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(children: [
                for (final b in buttons)
                  Tooltip(
                    message: b.$4 ?? '',
                    child: TextButton.icon(onPressed: b.$3, icon: Icon(b.$1, size: 18), label: Text(b.$2)),
                  ),
              ]),
            );
          }),
        ),
      ]),
    );
  }

  Future<void> _afterBulk(Future<bool> f) async {
    if (await f && mounted) _exitSelection();
  }

  Future<void> _bulkActive(Set<String> ids, bool active) =>
      _afterBulk(archiveProductsAction(context, ref, ids, active));

  // ------------------------------------------------------------------- list

  Widget _list(AsyncValue<List<Product>> async, Map<String, Category> catById, bool canCost, bool canEdit) {
    final list = _last;
    if (async.hasError && !async.isLoading) {
      return ErrorView(error: async.error!, onRetry: () => ref.invalidate(productListProvider(_q)));
    }
    if (list == null) return const LoadingView();
    if (list.isEmpty) {
      // Rows of the previous filter were empty: don't claim "nothing found"
      // for the new filter before its first result arrives.
      if (!async.hasValue) return const LoadingView();
      if (_q.isFiltered) {
        return EmptyState(
          icon: Icons.search_off,
          title: 'Ничего не найдено',
          message: _q.search.isEmpty ? 'Попробуйте изменить фильтры' : 'По запросу «${_q.search}» товаров нет',
          action: OutlinedButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Сбросить фильтры'),
          ),
        );
      }
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Каталог пуст',
        message: canEdit
            ? 'Добавьте первый товар или загрузите список из Excel (CSV).'
            : 'Товары добавляет менеджер или администратор.',
        action: !canEdit
            ? null
            : Wrap(spacing: Gap.s, runSpacing: Gap.s, alignment: WrapAlignment.center, children: [
                FilledButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Новый товар')),
                OutlinedButton.icon(
                  onPressed: () => showImportDialog(context),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Импорт CSV'),
                ),
              ]),
      );
    }
    final hasMore = list.length >= _q.limit && _q.limit > 0;
    return Stack(children: [
      ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: list.length + (hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= list.length) {
            _loadMore();
            return const Padding(
              padding: EdgeInsets.all(Gap.l),
              child: Center(child: CircularProgressIndicator.adaptive()),
            );
          }
          final p = list[i];
          return Column(mainAxisSize: MainAxisSize.min, children: [
            ProductRow(
              key: ValueKey(p.id),
              product: p,
              category: p.categoryId == null ? null : catById[p.categoryId],
              showCost: canCost,
              selected: p.id == _openId,
              selectionMode: _selectionMode,
              checked: _checked.contains(p.id),
              onTap: () => _open(p),
              onLongPress: () => setState(() {
                _selectionMode = true;
                _checked.add(p.id);
              }),
              onCheck: (v) => _toggle(p.id, v),
            ),
            const Divider(indent: Gap.l, endIndent: Gap.l),
          ]);
        },
      ),
      if (async.isLoading)
        const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
    ]);
  }
}

// ------------------------------------------------------------- menu chip

class _MenuItem<T> {
  const _MenuItem(this.value, this.label, {this.leading});
  final T value;
  final String label;
  final Widget? leading;
}

class _MenuChip<T> extends StatelessWidget {
  const _MenuChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.items,
    required this.onSelected,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final bool active;
  final List<_MenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final fg = active ? t.colorScheme.onSecondaryContainer : t.colorScheme.onSurface;
    return MenuAnchor(
      builder: (context, ctl, _) => Tooltip(
        message: tooltip ?? '',
        child: Material(
          color: active ? t.colorScheme.secondaryContainer : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: active ? Colors.transparent : t.colorScheme.outlineVariant),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => ctl.isOpen ? ctl.close() : ctl.open(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg)),
                ),
                Icon(Icons.arrow_drop_down, size: 20, color: fg),
              ]),
            ),
          ),
        ),
      ),
      menuChildren: [
        for (final it in items)
          MenuItemButton(
            leadingIcon: it.leading == null ? null : SizedBox(width: 18, child: Center(child: it.leading)),
            onPressed: () => onSelected(it.value),
            child: Text(it.label),
          ),
      ],
    );
  }
}
