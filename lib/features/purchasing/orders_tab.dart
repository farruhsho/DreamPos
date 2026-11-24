import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/pickers.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/services/receipt_service.dart' show ReceiptStatus;
import '../inventory/inventory_logic.dart' show receiptStatusLabels;
import '../inventory/receipt_document.dart';
import 'po_pdf.dart';
import 'purchasing_logic.dart';
import 'supplier_dialogs.dart';
import '../../l10n/l10n.dart';

Color poStatusColor(String s) => switch (s) {
  'draft' => AppColors.warning,
  'ordered' => AppColors.info,
  poPartialStatus => AppColors.brand,
  'received' => AppColors.success,
  _ => AppColors.danger,
};

/// Chip for a (display) status; pass [poDisplayStatus] for `ordered` orders.
StatusChip poStatusChip(String s) => StatusChip(poStatusLabels[s] ?? s, color: poStatusColor(s));

/// Opens the order editor. Returns the saved order id.
Future<String?> showPoEditor(BuildContext context, {PurchaseOrder? order, String? supplierId}) =>
    showFormDialog<String>(
      context,
      title: order == null ? context.l10n.purNewPo : context.l10n.purOrderNumber('${order.number}'),
      width: 960,
      child: PoEditor(order: order, supplierId: supplierId),
    );

/// Opens an order: side panel on wide screens is handled by the caller,
/// on narrow screens this pushes a page.
void pushOrderPage(BuildContext context, String orderId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.purPoShort)),
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
  String? _status; // null = active (draft+ordered, incl. partly received); else a display status
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
    final l = context.l10n;
    final names = ref.watch(purSupplierNamesProvider).value ?? const {};
    final partly = ref.watch(purPartlyReceivedOrderIdsProvider).value ?? const <String>{};
    final statusLabels = poStatusLabelsOf(l);
    String shownStatus(PurchaseOrder o) => poDisplayStatus(o.status, anyReceived: partly.contains(o.id));
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1000;
        final list = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: SearchField(hint: l.purSearchOrder, onChanged: (v) => setState(() => _q = v)),
                ),
                const SizedBox(width: Gap.s),
                FilledButton.icon(
                  onPressed: () => _create(wide),
                  icon: const Icon(Icons.add),
                  label: Text(l.purOrderButton),
                ),
              ],
            ),
            const SizedBox(height: Gap.s),
            _ChipBar(
              children: [
                ChoiceChip(
                  label: Text(l.purActive),
                  selected: !_all && _status == null,
                  onSelected: (_) => setState(() {
                    _all = false;
                    _status = null;
                  }),
                ),
                for (final s in statusLabels.keys)
                  ChoiceChip(
                    label: Text(statusLabels[s]!),
                    selected: _status == s,
                    onSelected: (_) => setState(() {
                      _all = false;
                      _status = s;
                    }),
                  ),
                ChoiceChip(
                  label: Text(l.commonAll),
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
                      if (_status != null && shownStatus(o) != _status) return false;
                    }
                    if (q.isEmpty) return true;
                    return '${o.number}'.contains(q) || (names[o.supplierId] ?? '').toLowerCase().contains(q);
                  }).toList();
                  if (orders.isEmpty) {
                    return EmptyState(
                      icon: Icons.local_shipping_outlined,
                      title: l.purNoOrders,
                      message: l.purNoOrdersMessage,
                      action: FilledButton(onPressed: () => _create(wide), child: Text(l.purCreateOrder)),
                    );
                  }
                  if (shown.isEmpty) return EmptyState(icon: Icons.search_off, title: l.purNoOrdersForFilter);
                  return ListView.separated(
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (_, i) {
                      final o = shown[i];
                      return ListTile(
                        selected: wide && o.id == _selected,
                        title: Text(
                          l.purOrderListTitle('${o.number}', names[o.supplierId] ?? '—'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [
                            formatDate(o.createdAt),
                            Money.format(o.total),
                            if (o.expectedAt != null && o.status == 'ordered') l.purExpectedOn(formatDate(o.expectedAt!)),
                          ].join(' · '),
                        ),
                        trailing: poStatusChip(shownStatus(o)),
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
                  ? EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: l.purSelectOrder,
                      message: l.purSelectOrderMessage,
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
    final l = context.l10n;
    final canCost = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    final products = ref.watch(purProductMapProvider).value ?? const {};
    return AsyncView(
      value: ref.watch(purOrderProvider(orderId)),
      data: (o) {
        if (o == null) return EmptyState(icon: Icons.search_off, title: l.purOrderNotFound);
        final sup = ref.watch(purSupplierProvider(o.supplierId)).value;
        return AsyncView(
          value: ref.watch(purOrderItemsProvider(orderId)),
          data: (items) {
            final ordered = items.fold<int>(0, (s, i) => s + (i.qty * i.unitCost).round());
            // Actual value at invoice cost (receipts); falls back to the
            // ordered cost while the receipts stream is loading.
            final receivedEst =
                ref.watch(purOrderReceivedValueProvider(orderId)).value ??
                items.fold<int>(0, (s, i) => s + (i.receivedQty * i.unitCost).round());
            final shownStatus = poDisplayStatusOf(o, items);
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
                      success: l.purOrderSent('${o.number}'),
                    ),
                    icon: const Icon(Icons.send_outlined),
                    label: Text(l.purMarkOrdered),
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
                    label: Text(context.isCompact ? l.purReceiveShort : l.purReceiveGoods),
                  )
                : FilledButton.icon(
                    onPressed: () => showReceiveDialog(context, o),
                    icon: const Icon(Icons.move_to_inbox),
                    label: Text(l.purReceiveGoods),
                  );
            final primary = markOrdered ?? receive;
            final secondary = <Widget>[
              if (draft)
                OutlinedButton.icon(
                  onPressed: () => showPoEditor(context, order: o),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l.commonEdit),
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
                  label: Text(l.purPay),
                ),
            ];
            final menu = PopupMenuButton<String>(
              tooltip: l.commonMore,
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
                PopupMenuItem(
                  value: 'print',
                  child: ListTile(leading: const Icon(Icons.print_outlined), title: Text(l.commonPrint)),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(leading: const Icon(Icons.share_outlined), title: Text(l.purActShare)),
                ),
                if (o.status == 'draft' || o.status == 'ordered')
                  PopupMenuItem(
                    value: 'cancel',
                    child: ListTile(
                      leading: const Icon(Icons.block, color: AppColors.danger),
                      title: Text(items.any((i) => i.receivedQty > 0) ? l.purCloseWithoutRest : l.purCancelOrder),
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
                              Flexible(child: Text(l.purOrderNumber('${o.number}'), style: t.textTheme.headlineSmall)),
                              const SizedBox(width: Gap.s),
                              poStatusChip(shownStatus),
                            ],
                          ),
                          Text(sup?.name ?? '—', style: t.textTheme.titleMedium),
                          Text(
                            [
                              l.purCreatedOn(formatDateTime(o.createdAt)),
                              if (o.expectedAt != null) l.purExpectedOn(formatDate(o.expectedAt!)),
                              if (o.receivedAt != null) l.purReceivedOn(formatDateTime(o.receivedAt!)),
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
                      StatusChip(l.purOrderAmount(Money.format(ordered)), color: AppColors.info),
                      StatusChip(l.purReceivedAmount(Money.format(receivedEst)), color: AppColors.success),
                      StatusChip(l.purPaidAmount(Money.format(o.paid)), color: AppColors.warning),
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
                        Padding(padding: const EdgeInsets.all(Gap.l), child: Text(l.purNoLinesAdded)),
                    ],
                  ),
                ),
                if (!draft) ...[const SizedBox(height: Gap.m), OrderReceipts(orderId: o.id, canCost: canCost)],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, PurchaseOrder o, List<PurchaseOrderItem> items) async {
    final partial = items.any((i) => i.receivedQty > 0);
    final l = context.l10n;
    final reason = await promptText(
      context,
      title: partial ? l.purCloseOrderTitle('${o.number}') : l.purCancelOrderTitle('${o.number}'),
      label: l.commonReason,
      required: false,
    );
    if (reason == null || !context.mounted) return;
    await runGuarded(
      context,
      () => ref
          .read(purchasingRepoProvider)
          .cancelOrder(o.id, userId: ref.read(sessionProvider)?.user.id, reason: reason),
      success: partial ? l.purOrderClosed : l.purOrderCancelled,
    );
  }
}

/// «Приходы по заказу»: receipt documents of the order (№, дата, сумма,
/// статус); tap opens the receipt document.
class OrderReceipts extends ConsumerWidget {
  const OrderReceipts({super.key, required this.orderId, this.canCost = true});
  final String orderId;
  final bool canCost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final l = context.l10n;
    final muted = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    final async = ref.watch(purOrderReceiptsProvider(orderId));
    return SectionCard(
      title: l.purOrderReceipts,
      subtitle: switch (async) {
        AsyncData(:final value) when value.isNotEmpty => l.commonDocumentsCount(value.length),
        _ => null,
      },
      child: switch (async) {
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(purOrderReceiptsProvider(orderId)),
        ),
        AsyncData(:final value) when value.isEmpty => Text(l.purNoReceiptsYet, style: muted),
        AsyncData(:final value) => Column(
          children: [
            for (var i = 0; i < value.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _ReceiptTile(r: value[i], canCost: canCost),
            ],
          ],
        ),
        _ => const Padding(padding: EdgeInsets.all(Gap.m), child: LoadingView()),
      },
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({required this.r, required this.canCost});
  final GoodsReceipt r;
  final bool canCost;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final reversed = r.status == ReceiptStatus.reversed;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        reversed ? Icons.undo : Icons.move_to_inbox_outlined,
        color: reversed ? AppColors.danger : AppColors.success,
      ),
      title: Text(l.purReceiptNumber('${r.number}'), style: TextStyle(decoration: reversed ? TextDecoration.lineThrough : null)),
      subtitle: Text(
        [formatDateTime(r.createdAt), if (r.supplierInvoice != null) l.purInvoiceShort(r.supplierInvoice!)].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canCost) ...[
            Text(
              Money.format(r.total),
              style: t.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: reversed ? t.colorScheme.onSurfaceVariant : null,
              ),
            ),
            const SizedBox(width: Gap.m),
          ],
          StatusChip(receiptStatusLabels[r.status] ?? r.status, color: reversed ? AppColors.danger : AppColors.success),
        ],
      ),
      onTap: () => showReceiptDocument(context, r.id),
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
    final l = context.l10n;
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
                    Text(p?.name ?? l.purDeletedProduct, style: t.textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      l.purItemProgress(Qty.format(it.qty, unit), Qty.format(it.receivedQty, unit)) +
                          (rest > 0 ? l.purItemRestSuffix(Qty.format(rest, unit)) : ''),
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
      showError(context, context.l10n.purProductNotFound(code.trim()));
    } else {
      _add(p);
    }
    _scanFocus.requestFocus();
  }

  Future<void> _save({bool send = false}) async {
    if (_busy) return;
    final loc = context.l10n;
    if (_supplierId == null) {
      showError(context, loc.purSelectSupplier);
      return;
    }
    if (_lines.isEmpty) {
      showError(context, loc.purAddOneProduct);
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
      showSuccess(context, send ? loc.purOrderSavedSent : loc.purDraftSaved);
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
    final loc = context.l10n;
    final suppliers = ref.watch(purSuppliersProvider).value ?? const <Supplier>[];
    if (_loading) return const SizedBox(height: 200, child: LoadingView());
    final total = _lines.fold<int>(0, (s, l) => s + l.total);
    final supField = DropdownButtonFormField<String>(
      // Re-create once the supplier stream arrives so a preset supplier shows.
      key: ValueKey('posup${suppliers.length}'),
      initialValue: suppliers.any((s) => s.id == _supplierId) ? _supplierId : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: loc.purSupplierRequired),
      validator: (v) => v == null ? loc.purSelectSupplier : null,
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
      label: Text(_expected == null ? loc.purDeliveryDate : loc.purDeliveryOn(formatDate(_expected!))),
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
      decoration: InputDecoration(labelText: loc.commonNote),
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
                    decoration: InputDecoration(labelText: loc.commonBarcode, prefixIcon: const Icon(Icons.qr_code_scanner)),
                    onSubmitted: _onScan,
                  ),
                ),
                const SizedBox(width: Gap.s),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final p = await pickProduct(context, title: loc.purAddToOrder);
                    if (p != null) _add(p);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(loc.commonProduct),
                ),
              ],
            ),
            const SizedBox(height: Gap.m),
            Flexible(
              child: _lines.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(Gap.xl),
                      child: Text(loc.purEditorEmptyHint, textAlign: TextAlign.center),
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
                          decoration: InputDecoration(labelText: loc.purPoColQty, suffixText: Qty.unitLabel(l.product.unit)),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final q = QtyField.parse(v ?? '');
                            if (q == null || q <= 0) return loc.purQtyMoreThanZeroCap;
                            if (!Qty.isFractional(l.product.unit) && q != q.roundToDouble()) return loc.purQtyWholeCap;
                            return null;
                          },
                        );
                        final cost = TextFormField(
                          controller: l.cost,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: loc.commonPrice, suffixText: Money.currency.symbol),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if ((v ?? '').trim().isEmpty) return loc.purEnterPrice;
                            final m = Money.parse(v!);
                            return m == null || m < 0 ? loc.purInvalid : null;
                          },
                        );
                        return Padding(
                          key: l.key,
                          padding: const EdgeInsets.symmetric(vertical: Gap.s),
                          child: _LineLayout(
                            title: Text(l.product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              loc.purStockValue(Qty.format(l.product.stockQty, l.product.unit)),
                              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                            ),
                            qty: qty,
                            cost: cost,
                            total: Text(Money.format(l.total), style: const TextStyle(fontWeight: FontWeight.w600)),
                            trailing: IconButton(
                              tooltip: loc.purDeleteLine,
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
                    loc.purEditorTotal(Money.format(total), '${_lines.length}'),
                    style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: Gap.s),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _save(send: true),
                    icon: const Icon(Icons.send_outlined),
                    label: Text(loc.purSaveAndSend),
                  ),
                  const SizedBox(height: Gap.s),
                  OutlinedButton(onPressed: _busy ? null : () => _save(), child: Text(loc.purSaveDraft)),
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
                    loc.purEditorTotal(Money.format(total), '${_lines.length}'),
                    style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Wrap(
                    spacing: Gap.s,
                    runSpacing: Gap.s,
                    children: [
                      OutlinedButton(onPressed: _busy ? null : () => _save(), child: Text(loc.purSaveDraft)),
                      FilledButton.icon(
                        onPressed: _busy ? null : () => _save(send: true),
                        icon: const Icon(Icons.send_outlined),
                        label: Text(loc.purSaveAndSend),
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
    showFormDialog<void>(
      context,
      title: context.l10n.purReceiveTitle('${o.number}'),
      width: 860,
      child: _ReceiveForm(o),
    );

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
  final _invoice = TextEditingController();
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
    _invoice.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final lines = _lines!;
    if (_busy || !_key.currentState!.validate()) return;
    final loc = context.l10n;
    final active = lines.where((l) => l.q > 0).toList();
    if (active.isEmpty) {
      showError(context, loc.purReceiveEnterQty);
      return;
    }
    final value = active.fold<int>(0, (s, l) => s + (l.q * l.c).round());
    final full = lines.every((l) => l.q >= remainingQty(l.item));
    final ok = await confirm(
      context,
      title: loc.purReceiveConfirmTitle,
      message:
          '${loc.purReceiveConfirmMessage('${active.length}', Money.format(value))}\n'
          '${full ? loc.purReceiveWillClose : loc.purReceiveStaysOpen}',
      ok: loc.purReceiveShort,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final r = await ref
          .read(purchasingRepoProvider)
          .receiveOrderDoc(
            widget.o.id,
            [for (final l in active) ReceiveLineInput(itemId: l.item.id, qty: l.q, unitCost: l.c)],
            userId: ref.read(sessionProvider)?.user.id,
            supplierInvoice: _invoice.text,
          );
      if (!mounted) return;
      showSuccess(
        context,
        loc.purReceiptPosted('${r.receipt.number}', Money.format(r.result.value)) +
            (r.result.fullyReceived ? loc.purFullyReceivedSuffix : ''),
      );
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
    final loc = context.l10n;
    final lines = _lines;
    if (lines == null) return const SizedBox(height: 200, child: LoadingView());
    if (lines.isEmpty) {
      return Padding(padding: const EdgeInsets.all(Gap.xl), child: Text(loc.purAllReceived));
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
            TextField(
              controller: _invoice,
              maxLength: 60,
              decoration: InputDecoration(
                labelText: loc.purSupplierInvoiceNo,
                prefixIcon: const Icon(Icons.description_outlined),
                counterText: '',
              ),
            ),
            const SizedBox(height: Gap.xs),
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
                  label: Text(loc.purAllAsOrdered),
                ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    for (final l in lines) {
                      l.qty.text = '0';
                    }
                  }),
                  icon: const Icon(Icons.exposure_zero),
                  label: Text(loc.purZeroAll),
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
                    decoration: InputDecoration(labelText: loc.purReceivedField, suffixText: Qty.unitLabel(unit)),
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) {
                      final q = QtyField.parse(v ?? '');
                      if (q == null || q < 0) return loc.purNumberGeZero;
                      if (q > rest + 1e-9) return loc.purMaxQty(Qty.format(rest));
                      if (!Qty.isFractional(unit) && q != q.roundToDouble()) return loc.purQtyWholeCap;
                      return null;
                    },
                  );
                  final cost = TextFormField(
                    controller: l.cost,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: loc.purPurchasePrice, suffixText: Money.currency.symbol),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return loc.purEnterPrice;
                      final m = Money.parse(v!);
                      return m == null || m < 0 ? loc.purInvalid : null;
                    },
                  );
                  return Padding(
                    // Room for the floating field labels below the divider.
                    padding: const EdgeInsets.symmetric(vertical: Gap.s),
                    child: _LineLayout(
                      title: Text(l.product?.name ?? '—', maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        loc.purOrderedRest(Qty.format(l.item.qty, unit), Qty.format(rest, unit)),
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
                    loc.purToPost(Money.format(value)),
                    style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: const Icon(Icons.move_to_inbox),
                  label: Text(loc.purReceiveShort),
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
