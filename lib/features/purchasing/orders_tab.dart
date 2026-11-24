import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/pickers.dart';
import '../../core/widgets/widgets.dart';
import 'po_pdf.dart';
import 'purchasing_logic.dart';
import 'supplier_dialogs.dart';

Color poStatusColor(String s) => switch (s) {
  'draft' => AppColors.warning,
  'ordered' => AppColors.info,
  'received' => AppColors.success,
  _ => AppColors.danger,
};

StatusChip poStatusChip(String s) => StatusChip(poStatusLabels[s] ?? s, color: poStatusColor(s));

/// Opens the order editor. Returns the saved order id.
Future<String?> showPoEditor(BuildContext context, {PurchaseOrder? order, String? supplierId}) =>
    showFormDialog<String>(
      context,
      title: order == null ? 'Новый заказ поставщику' : 'Заказ №${order.number}',
      width: 960,
      child: PoEditor(order: order, supplierId: supplierId),
    );

/// Opens an order: side panel on wide screens is handled by the caller,
/// on narrow screens this pushes a page.
void pushOrderPage(BuildContext context, String orderId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Заказ поставщику')),
        body: Padding(
          padding: const EdgeInsets.all(Gap.m),
          child: OrderDetail(orderId: orderId),
        ),
      ),
    ),
  );
}

// ------------------------------------------------------------------ list

class OrdersTab extends ConsumerStatefulWidget {
  const OrdersTab({super.key});
  @override
  ConsumerState<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<OrdersTab> {
  String? _status; // null = active (draft+ordered)
  bool _all = false;
  String _q = '';
  String? _selected;

  Future<void> _create(bool wide) async {
    final id = await showPoEditor(context);
    if (id == null || !mounted) return;
    wide ? setState(() => _selected = id) : pushOrderPage(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final names = ref.watch(purSupplierNamesProvider).value ?? const {};
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1000;
        final list = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: SearchField(hint: 'Поиск заказа', onChanged: (v) => setState(() => _q = v)),
                ),
                const SizedBox(width: Gap.s),
                FilledButton.icon(
                  onPressed: () => _create(wide),
                  icon: const Icon(Icons.add),
                  label: const Text('Заказ'),
                ),
              ],
            ),
            const SizedBox(height: Gap.s),
            _ChipBar(
              children: [
                ChoiceChip(
                  label: const Text('Активные'),
                  selected: !_all && _status == null,
                  onSelected: (_) => setState(() {
                    _all = false;
                    _status = null;
                  }),
                ),
                for (final s in poStatusLabels.keys)
                  ChoiceChip(
                    label: Text(poStatusLabels[s]!),
                    selected: _status == s,
                    onSelected: (_) => setState(() {
                      _all = false;
                      _status = s;
                    }),
                  ),
                ChoiceChip(
                  label: const Text('Все'),
                  selected: _all,
                  onSelected: (_) => setState(() {
                    _all = true;
                    _status = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: Gap.s),
            Expanded(
              child: AsyncView(
                value: ref.watch(purOrdersProvider),
                onRetry: () => ref.invalidate(purOrdersProvider),
                data: (orders) {
                  final q = _q.toLowerCase();
                  final shown = orders.where((o) {
                    if (!_all) {
                      if (_status == null && o.status != 'draft' && o.status != 'ordered') return false;
                      if (_status != null && o.status != _status) return false;
                    }
                    if (q.isEmpty) return true;
                    return '${o.number}'.contains(q) || (names[o.supplierId] ?? '').toLowerCase().contains(q);
                  }).toList();
                  if (orders.isEmpty) {
                    return EmptyState(
                      icon: Icons.local_shipping_outlined,
                      title: 'Заказов поставщикам пока нет',
                      message: 'Создайте заказ вручную или воспользуйтесь вкладкой «Автозаказ»',
                      action: FilledButton(onPressed: () => _create(wide), child: const Text('Создать заказ')),
                    );
                  }
                  if (shown.isEmpty) return const EmptyState(icon: Icons.search_off, title: 'Нет заказов по фильтру');
                  return ListView.separated(
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (_, i) {
                      final o = shown[i];
                      return ListTile(
                        selected: wide && o.id == _selected,
                        title: Text(
                          '№${o.number} · ${names[o.supplierId] ?? '—'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [
                            formatDate(o.createdAt),
                            Money.format(o.total),
                            if (o.expectedAt != null && o.status == 'ordered') 'ожидается ${formatDate(o.expectedAt!)}',
                          ].join(' · '),
                        ),
                        trailing: poStatusChip(o.status),
                        onTap: () => wide ? setState(() => _selected = o.id) : pushOrderPage(context, o.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
        if (!wide) return list;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 400, child: list),
            const VerticalDivider(width: Gap.xl),
            Expanded(
              child: _selected == null
                  ? const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Выберите заказ',
                      message: 'Откройте заказ из списка слева или создайте новый',
                    )
                  : OrderDetail(key: ValueKey(_selected), orderId: _selected!),
            ),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------------ detail

class OrderDetail extends ConsumerWidget {
  const OrderDetail({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final canCost = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    final products = ref.watch(purProductMapProvider).value ?? const {};
    return AsyncView(
      value: ref.watch(purOrderProvider(orderId)),
      data: (o) {
        if (o == null) return const EmptyState(icon: Icons.search_off, title: 'Заказ не найден');
        final sup = ref.watch(purSupplierProvider(o.supplierId)).value;
        return AsyncView(
          value: ref.watch(purOrderItemsProvider(orderId)),
          data: (items) {
            final ordered = items.fold<int>(0, (s, i) => s + (i.qty * i.unitCost).round());
            final receivedEst = items.fold<int>(0, (s, i) => s + (i.receivedQty * i.unitCost).round());
            final hasRemaining = items.any((i) => remainingQty(i) > 0);
            final draft = o.status == 'draft';
            final canReceive = (o.status == 'ordered' || draft) && hasRemaining;
            final markOrdered = draft
                ? FilledButton.icon(
                    onPressed: () => runGuarded(
                      context,
                      () => ref
                          .read(purchasingRepoProvider)
                          .markOrdered(o.id, userId: ref.read(sessionProvider)?.user.id),
                      success: 'Заказ №${o.number} отправлен поставщику',
                    ),
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Отметить заказанным'),
                  )
                : null;
            // A draft's next step is «Отметить заказанным»; receiving stays
            // available but secondary, so only one filled button shows.
            final receive = !canReceive
                ? null
                : draft
                ? OutlinedButton.icon(
                    onPressed: () => showReceiveDialog(context, o),
                    icon: const Icon(Icons.move_to_inbox),
                    // Shares a phone row with «Изменить»: keep it one line.
                    label: Text(context.isCompact ? 'Принять' : 'Принять товар'),
                  )
                : FilledButton.icon(
                    onPressed: () => showReceiveDialog(context, o),
                    icon: const Icon(Icons.move_to_inbox),
                    label: const Text('Принять товар'),
                  );
            final primary = markOrdered ?? receive;
            final secondary = <Widget>[
              if (draft)
                OutlinedButton.icon(
                  onPressed: () => showPoEditor(context, order: o),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Изменить'),
                ),
              if (receive != null && receive != primary) receive,
              if (sup != null && o.status != 'cancelled' && !draft)
                OutlinedButton.icon(
                  onPressed: () => showSupplierPaymentDialog(
                    context,
                    sup,
                    order: o,
                    suggested: receivedEst - o.paid > 0 ? receivedEst - o.paid : null,
                  ),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Оплатить'),
                ),
            ];
            final menu = PopupMenuButton<String>(
              tooltip: 'Ещё',
              onSelected: (a) async {
                final db = ref.read(databaseProvider);
                switch (a) {
                  case 'print':
                    await runGuarded(context, () => printPo(db, o));
                  case 'share':
                    await runGuarded(context, () => sharePo(db, o));
                  case 'cancel':
                    await _cancel(context, ref, o, items);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'print',
                  child: ListTile(leading: Icon(Icons.print_outlined), title: Text('Печать')),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: ListTile(leading: Icon(Icons.share_outlined), title: Text('Отправить PDF')),
                ),
                if (o.status == 'draft' || o.status == 'ordered')
                  PopupMenuItem(
                    value: 'cancel',
                    child: ListTile(
                      leading: const Icon(Icons.block, color: AppColors.danger),
                      title: Text(items.any((i) => i.receivedQty > 0) ? 'Закрыть без остатка' : 'Отменить заказ'),
                    ),
                  ),
              ],
            );
            // Phones: the primary action is a full-width button, secondary
            // actions share one row with the overflow menu.
            final Widget actionBar = context.isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (primary != null) ...[primary, const SizedBox(height: Gap.s)],
                      Row(
                        children: [
                          for (var i = 0; i < secondary.length; i++) ...[
                            if (i > 0) const SizedBox(width: Gap.s),
                            Expanded(child: secondary[i]),
                          ],
                          if (secondary.isEmpty) const Spacer(),
                          menu,
                        ],
                      ),
                    ],
                  )
                : Wrap(
                    spacing: Gap.s,
                    runSpacing: Gap.s,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [?primary, ...secondary, menu],
                  );
            return ListView(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text('Заказ №${o.number}', style: t.textTheme.headlineSmall)),
                              const SizedBox(width: Gap.s),
                              poStatusChip(o.status),
                            ],
                          ),
                          Text(sup?.name ?? '—', style: t.textTheme.titleMedium),
                          Text(
                            [
                              'создан ${formatDateTime(o.createdAt)}',
                              if (o.expectedAt != null) 'ожидается ${formatDate(o.expectedAt!)}',
                              if (o.receivedAt != null) 'получен ${formatDateTime(o.receivedAt!)}',
                            ].join(' · '),
                            style: t.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.m),
                actionBar,
                const SizedBox(height: Gap.m),
                if (canCost)
                  Wrap(
                    spacing: Gap.m,
                    runSpacing: Gap.s,
                    children: [
                      StatusChip('Сумма заказа ${Money.format(ordered)}', color: AppColors.info),
                      StatusChip('Принято на ${Money.format(receivedEst)}', color: AppColors.success),
                      StatusChip('Оплачено ${Money.format(o.paid)}', color: AppColors.warning),
                    ],
                  ),
                if (o.note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Gap.s),
                    child: Text(o.note!),
                  ),
                const SizedBox(height: Gap.m),
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _ItemRow(it: items[i], p: products[items[i].productId], canCost: canCost),
                      ],
                      if (items.isEmpty)
                        const Padding(padding: EdgeInsets.all(Gap.l), child: Text('Позиции не добавлены')),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, PurchaseOrder o, List<PurchaseOrderItem> items) async {
    final partial = items.any((i) => i.receivedQty > 0);
    final reason = await promptText(
      context,
      title: partial ? 'Закрыть заказ №${o.number} без остатка?' : 'Отменить заказ №${o.number}?',
      label: 'Причина',
      required: false,
    );
    if (reason == null || !context.mounted) return;
    await runGuarded(
      context,
      () => ref
          .read(purchasingRepoProvider)
          .cancelOrder(o.id, userId: ref.read(sessionProvider)?.user.id, reason: reason),
      success: partial ? 'Заказ закрыт' : 'Заказ отменён',
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.it, required this.p, required this.canCost});
  final PurchaseOrderItem it;
  final Product? p;
  final bool canCost;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final unit = p?.unit ?? 'pcs';
    final rest = remainingQty(it);
    final progress = it.qty <= 0 ? 0.0 : (it.receivedQty / it.qty).clamp(0.0, 1.0);
    // Custom row instead of ListTile: the progress bar spans the full row
    // width, so bars line up regardless of the amount column's width.
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.l, Gap.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p?.name ?? 'Удалённый товар', style: t.textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      'заказано ${Qty.format(it.qty, unit)} · принято ${Qty.format(it.receivedQty, unit)}'
                      '${rest > 0 ? ' · осталось ${Qty.format(rest, unit)}' : ''}',
                      style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (canCost) ...[
                const SizedBox(width: Gap.m),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Money.format((it.qty * it.unitCost).round()),
                      style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '× ${Money.format(it.unitCost)}',
                      style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: Gap.s),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              color: progress >= 1 ? AppColors.success : AppColors.info,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status chips: wrapping on wide screens, one horizontally scrolling row on
/// phones so the order list starts right below the search.
class _ChipBar extends StatelessWidget {
  const _ChipBar({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!context.isCompact) return Wrap(spacing: Gap.s, runSpacing: Gap.xs, children: children);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: Gap.s), children[i]],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ editor

class _EdLine {
  _EdLine(this.product, double qty, int cost)
    : qty = TextEditingController(text: Qty.format(qty)),
      cost = TextEditingController(text: Money.toInput(cost));
  final Product product;
  final TextEditingController qty;
  final TextEditingController cost;
  final key = UniqueKey();
  double? get q => QtyField.parse(qty.text);
  int? get c => Money.parse(cost.text);
  int get total => (q ?? 0) <= 0 || c == null ? 0 : ((q!) * c!).round();
  void dispose() {
    qty.dispose();
    cost.dispose();
  }
}

class PoEditor extends ConsumerStatefulWidget {
  const PoEditor({super.key, this.order, this.supplierId});
  final PurchaseOrder? order;
  final String? supplierId;
  @override
  ConsumerState<PoEditor> createState() => _PoEditorState();
}

class _PoEditorState extends ConsumerState<PoEditor> {
  final _key = GlobalKey<FormState>();
  final _lines = <_EdLine>[];
  final _scan = TextEditingController();
  final _scanFocus = FocusNode();
  late final _note = TextEditingController(text: widget.order?.note);
  late String? _supplierId = widget.order?.supplierId ?? widget.supplierId;
  late DateTime? _expected = widget.order?.expectedAt;
  bool _loading = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) _loadLines();
  }

  Future<void> _loadLines() async {
    setState(() => _loading = true);
    final db = ref.read(databaseProvider);
    final items = await (db.select(db.purchaseOrderItems)..where((i) => i.orderId.equals(widget.order!.id))).get();
    final ps = await (db.select(db.products)..where((p) => p.id.isIn(items.map((i) => i.productId)))).get();
    final map = {for (final p in ps) p.id: p};
    if (!mounted) return;
    setState(() {
      for (final i in items) {
        final p = map[i.productId];
        if (p != null) _lines.add(_EdLine(p, i.qty, i.unitCost));
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    _scan.dispose();
    _scanFocus.dispose();
    _note.dispose();
    super.dispose();
  }

  void _add(Product p) => setState(() {
    final ex = _lines.where((l) => l.product.id == p.id).firstOrNull;
    if (ex != null) {
      ex.qty.text = Qty.format((ex.q ?? 0) + 1);
    } else {
      _lines.add(_EdLine(p, 1, p.costPrice));
    }
  });

  Future<void> _onScan(String code) async {
    _scan.clear();
    if (code.trim().isEmpty) return;
    final p = await findByCode(ref.read(databaseProvider), code);
    if (!mounted) return;
    if (p == null) {
      showError(context, 'Товар «${code.trim()}» не найден');
    } else {
      _add(p);
    }
    _scanFocus.requestFocus();
  }

  Future<void> _save({bool send = false}) async {
    if (_busy) return;
    if (_supplierId == null) {
      showError(context, 'Выберите поставщика');
      return;
    }
    if (_lines.isEmpty) {
      showError(context, 'Добавьте хотя бы один товар');
      return;
    }
    if (!_key.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(purchasingRepoProvider);
    final uid = ref.read(sessionProvider)?.user.id;
    try {
      final id = await repo.saveDraftOrder(
        id: widget.order?.id,
        supplierId: _supplierId!,
        lines: [for (final l in _lines) PoLineInput(productId: l.product.id, qty: l.q!, unitCost: l.c!)],
        expectedAt: _expected,
        note: _note.text,
        userId: uid,
      );
      if (send) await repo.markOrdered(id, userId: uid);
      if (!mounted) return;
      showSuccess(context, send ? 'Заказ сохранён и отмечен как отправленный' : 'Черновик заказа сохранён');
      Navigator.pop(context, id);
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final suppliers = ref.watch(purSuppliersProvider).value ?? const <Supplier>[];
    if (_loading) return const SizedBox(height: 200, child: LoadingView());
    final total = _lines.fold<int>(0, (s, l) => s + l.total);
    final supField = DropdownButtonFormField<String>(
      // Re-create once the supplier stream arrives so a preset supplier shows.
      key: ValueKey('posup${suppliers.length}'),
      initialValue: suppliers.any((s) => s.id == _supplierId) ? _supplierId : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Поставщик *'),
      validator: (v) => v == null ? 'Выберите поставщика' : null,
      items: [
        for (final s in suppliers)
          DropdownMenuItem(
            value: s.id,
            child: Text(s.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => setState(() => _supplierId = v),
    );
    final dateBtn = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
      icon: const Icon(Icons.event_outlined),
      label: Text(_expected == null ? 'Дата поставки' : 'Поставка ${formatDate(_expected!)}'),
      onPressed: () async {
        final now = DateTime.now();
        final d = await showDatePicker(
          context: context,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 2),
          initialDate: _expected ?? now.add(const Duration(days: 3)),
        );
        if (d != null) setState(() => _expected = d);
      },
    );
    final noteField = TextField(
      controller: _note,
      decoration: const InputDecoration(labelText: 'Примечание'),
    );
    final header = LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              supField,
              const SizedBox(height: Gap.s),
              noteField,
              const SizedBox(height: Gap.s),
              dateBtn,
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 3, child: supField),
            const SizedBox(width: Gap.m),
            dateBtn,
            const SizedBox(width: Gap.m),
            Expanded(flex: 3, child: noteField),
          ],
        );
      },
    );
    return Form(
      key: _key,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.m, Gap.xl, Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: Gap.m),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _scan,
                    focusNode: _scanFocus,
                    autofocus: widget.order == null && _supplierId != null,
                    decoration: const InputDecoration(labelText: 'Штрихкод', prefixIcon: Icon(Icons.qr_code_scanner)),
                    onSubmitted: _onScan,
                  ),
                ),
                const SizedBox(width: Gap.s),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final p = await pickProduct(context, title: 'Добавить в заказ');
                    if (p != null) _add(p);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Товар'),
                ),
              ],
            ),
            const SizedBox(height: Gap.m),
            Flexible(
              child: _lines.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(Gap.xl),
                      child: Text(
                        'Добавьте товары: сканером, кнопкой «Товар» или из вкладки «Автозаказ»',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _lines.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (_, i) {
                        final l = _lines[i];
                        final qty = TextFormField(
                          controller: l.qty,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: 'Кол-во', suffixText: Qty.unitLabel(l.product.unit)),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final q = QtyField.parse(v ?? '');
                            if (q == null || q <= 0) return 'Больше 0';
                            if (!Qty.isFractional(l.product.unit) && q != q.roundToDouble()) return 'Целое';
                            return null;
                          },
                        );
                        final cost = TextFormField(
                          controller: l.cost,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: 'Цена', suffixText: Money.currency.symbol),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if ((v ?? '').trim().isEmpty) return 'Укажите цену';
                            final m = Money.parse(v!);
                            return m == null || m < 0 ? 'Неверно' : null;
                          },
                        );
                        return Padding(
                          key: l.key,
                          padding: const EdgeInsets.symmetric(vertical: Gap.s),
                          child: _LineLayout(
                            title: Text(l.product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              'остаток ${Qty.format(l.product.stockQty, l.product.unit)}',
                              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                            ),
                            qty: qty,
                            cost: cost,
                            total: Text(Money.format(l.total), style: const TextStyle(fontWeight: FontWeight.w600)),
                            trailing: IconButton(
                              tooltip: 'Удалить строку',
                              onPressed: () => setState(() {
                                _lines.remove(l);
                                l.dispose();
                              }),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            const SizedBox(height: Gap.s),
            if (context.isCompact)
              // Phones: full-width buttons, primary first (closest to the total).
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Итого: ${Money.format(total)} · позиций ${_lines.length}',
                    style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: Gap.s),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _save(send: true),
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Сохранить и отправить'),
                  ),
                  const SizedBox(height: Gap.s),
                  OutlinedButton(onPressed: _busy ? null : () => _save(), child: const Text('Сохранить черновик')),
                ],
              )
            else
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: Gap.m,
                runSpacing: Gap.s,
                children: [
                  Text(
                    'Итого: ${Money.format(total)} · позиций ${_lines.length}',
                    style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Wrap(
                    spacing: Gap.s,
                    runSpacing: Gap.s,
                    children: [
                      OutlinedButton(onPressed: _busy ? null : () => _save(), child: const Text('Сохранить черновик')),
                      FilledButton.icon(
                        onPressed: _busy ? null : () => _save(send: true),
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Сохранить и отправить'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ receive

Future<void> showReceiveDialog(BuildContext context, PurchaseOrder o) =>
    showFormDialog<void>(context, title: 'Приёмка по заказу №${o.number}', width: 860, child: _ReceiveForm(o));

class _RecLine {
  _RecLine(this.item, this.product)
    : qty = TextEditingController(text: Qty.format(remainingQty(item))),
      cost = TextEditingController(text: Money.toInput(item.unitCost));
  final PurchaseOrderItem item;
  final Product? product;
  final TextEditingController qty;
  final TextEditingController cost;
  double get q => QtyField.parse(qty.text) ?? 0;
  int get c => Money.parse(cost.text) ?? 0;
}

class _ReceiveForm extends ConsumerStatefulWidget {
  const _ReceiveForm(this.o);
  final PurchaseOrder o;
  @override
  ConsumerState<_ReceiveForm> createState() => _ReceiveFormState();
}

class _ReceiveFormState extends ConsumerState<_ReceiveForm> {
  final _key = GlobalKey<FormState>();
  List<_RecLine>? _lines;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final items = await (db.select(db.purchaseOrderItems)..where((i) => i.orderId.equals(widget.o.id))).get();
    final ps = await (db.select(db.products)..where((p) => p.id.isIn(items.map((i) => i.productId)))).get();
    final map = {for (final p in ps) p.id: p};
    if (!mounted) return;
    setState(
      () => _lines = [
        for (final i in items)
          if (remainingQty(i) > 0) _RecLine(i, map[i.productId]),
      ],
    );
  }

  @override
  void dispose() {
    for (final l in _lines ?? const <_RecLine>[]) {
      l.qty.dispose();
      l.cost.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final lines = _lines!;
    if (_busy || !_key.currentState!.validate()) return;
    final active = lines.where((l) => l.q > 0).toList();
    if (active.isEmpty) {
      showError(context, 'Укажите принятое количество хотя бы по одной позиции');
      return;
    }
    final value = active.fold<int>(0, (s, l) => s + (l.q * l.c).round());
    final full = lines.every((l) => l.q >= remainingQty(l.item));
    final ok = await confirm(
      context,
      title: 'Принять товар?',
      message:
          'Позиций: ${active.length} на сумму ${Money.format(value)}.\n'
          'Остатки увеличатся, долг поставщику вырастет на эту сумму.\n'
          '${full ? 'Заказ будет закрыт как полученный.' : 'Заказ останется открытым — недопоставку можно принять позже.'}',
      ok: 'Принять',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final r = await ref.read(purchasingRepoProvider).receiveOrder(widget.o.id, [
        for (final l in active) ReceiveLineInput(itemId: l.item.id, qty: l.q, unitCost: l.c),
      ], userId: ref.read(sessionProvider)?.user.id);
      if (!mounted) return;
      showSuccess(context, 'Принято на ${Money.format(r.value)}${r.fullyReceived ? ' — заказ получен полностью' : ''}');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final lines = _lines;
    if (lines == null) return const SizedBox(height: 200, child: LoadingView());
    if (lines.isEmpty) {
      return const Padding(padding: EdgeInsets.all(Gap.xl), child: Text('Все позиции заказа уже приняты'));
    }
    final value = lines.fold<int>(0, (s, l) => s + (l.q * l.c).round());
    return Form(
      key: _key,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: Gap.s,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() {
                    for (final l in lines) {
                      l.qty.text = Qty.format(remainingQty(l.item));
                    }
                  }),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Всё по заказу'),
                ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    for (final l in lines) {
                      l.qty.text = '0';
                    }
                  }),
                  icon: const Icon(Icons.exposure_zero),
                  label: const Text('Обнулить'),
                ),
              ],
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: lines.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, i) {
                  final l = lines[i];
                  final unit = l.product?.unit ?? 'pcs';
                  final rest = remainingQty(l.item);
                  final qty = TextFormField(
                    controller: l.qty,
                    autofocus: i == 0,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Принято', suffixText: Qty.unitLabel(unit)),
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) {
                      final q = QtyField.parse(v ?? '');
                      if (q == null || q < 0) return 'Число ≥ 0';
                      if (q > rest + 1e-9) return 'Макс. ${Qty.format(rest)}';
                      if (!Qty.isFractional(unit) && q != q.roundToDouble()) return 'Целое';
                      return null;
                    },
                  );
                  final cost = TextFormField(
                    controller: l.cost,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Цена закупки', suffixText: Money.currency.symbol),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return 'Укажите цену';
                      final m = Money.parse(v!);
                      return m == null || m < 0 ? 'Неверно' : null;
                    },
                  );
                  return Padding(
                    // Room for the floating field labels below the divider.
                    padding: const EdgeInsets.symmetric(vertical: Gap.s),
                    child: _LineLayout(
                      title: Text(l.product?.name ?? '—', maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        'заказано ${Qty.format(l.item.qty, unit)} · осталось ${Qty.format(rest, unit)}',
                        style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                      ),
                      qty: qty,
                      cost: cost,
                      costWidth: 160,
                      total: Text(
                        Money.format((l.q * l.c).round()),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: Gap.s),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'К оприходованию: ${Money.format(value)}',
                    style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: const Icon(Icons.move_to_inbox),
                  label: const Text('Принять'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared document-line layout for the PO editor and the receive dialog:
/// one aligned row on wide dialogs (name | qty | cost | total | action), a
/// two-line block on phones so inputs never get squeezed.
class _LineLayout extends StatelessWidget {
  const _LineLayout({
    required this.title,
    required this.subtitle,
    required this.qty,
    required this.cost,
    required this.total,
    this.trailing,
    this.costWidth = 150,
  });
  final Widget title;
  final Widget subtitle;
  final Widget qty;
  final Widget cost;
  final Widget total;
  final Widget? trailing;
  final double costWidth;

  @override
  Widget build(BuildContext context) {
    final info = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, subtitle]);
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 620) {
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: Gap.s),
              SizedBox(width: 130, child: qty),
              const SizedBox(width: Gap.s),
              SizedBox(width: costWidth, child: cost),
              const SizedBox(width: Gap.s),
              SizedBox(
                width: 120,
                child: Align(alignment: Alignment.centerRight, child: total),
              ),
              trailing ?? const SizedBox(width: Gap.s),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: info),
                ?trailing,
              ],
            ),
            const SizedBox(height: Gap.s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: qty),
                const SizedBox(width: Gap.s),
                Expanded(child: cost),
              ],
            ),
            const SizedBox(height: Gap.xs),
            Align(alignment: Alignment.centerRight, child: total),
          ],
        );
      },
    );
  }
}
