// «Документы» in the Приход tab: journal of goods receipt documents with
// period / supplier / status filters and search by number or invoice.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/doc_number.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'inventory_logic.dart';
import 'receipt_document.dart';
import 'stock_tab.dart' show InvChipBar;
import '../../l10n/l10n.dart';

enum ReceiptPeriod {
  today,
  week,
  month,
  all,
  custom;

  String labelIn(AppLocalizations l) => switch (this) {
    ReceiptPeriod.today => l.commonToday,
    ReceiptPeriod.week => l.invDays7,
    ReceiptPeriod.month => l.invDays30,
    ReceiptPeriod.all => l.invAllTime,
    ReceiptPeriod.custom => l.invPeriodCustom,
  };

  String get label => labelIn(L.current);
}

/// Builds the list filter for a period (from inclusive, to exclusive).
ReceiptsFilter receiptsFilterFor({
  required ReceiptPeriod period,
  DateTimeRange? range,
  String? supplierId,
  String? status,
  String? search,
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final (from, to) = switch (period) {
    ReceiptPeriod.today => (today, null),
    ReceiptPeriod.week => (today.subtract(const Duration(days: 6)), null),
    ReceiptPeriod.month => (today.subtract(const Duration(days: 29)), null),
    ReceiptPeriod.all => (null, null),
    ReceiptPeriod.custom => (
      range?.start,
      range == null ? null : DateTime(range.end.year, range.end.month, range.end.day + 1),
    ),
  };
  final s = search?.trim() ?? '';
  return (from: from, to: to, supplierId: supplierId, status: status, search: s.isEmpty ? null : s);
}

class ReceiptDocumentsView extends ConsumerStatefulWidget {
  const ReceiptDocumentsView({super.key});
  @override
  ConsumerState<ReceiptDocumentsView> createState() => _ReceiptDocumentsViewState();
}

class _ReceiptDocumentsViewState extends ConsumerState<ReceiptDocumentsView> {
  ReceiptPeriod _period = ReceiptPeriod.month;
  DateTimeRange? _range;
  String? _supplierId;
  String? _status;
  String _search = '';

  ReceiptsFilter get _filter => receiptsFilterFor(
    period: _period,
    range: _range,
    supplierId: _supplierId,
    status: _status,
    search: _search,
  );

  bool get _filtered =>
      _supplierId != null || _status != null || _search.isNotEmpty || _period != ReceiptPeriod.all;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _range,
      helpText: context.l10n.invDocsPeriod,
    );
    if (r != null && mounted) {
      setState(() {
        _range = r;
        _period = ReceiptPeriod.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final compact = context.isCompact;
    final suppliers = ref.watch(invSuppliersProvider).value ?? const <Supplier>[];
    final supplierNames = ref.watch(invSupplierNamesProvider).value ?? const <String, String>{};
    final f = _filter;

    final search = SearchField(
      hint: compact ? l.invSearchShort : l.invSearchLong,
      onChanged: (v) => setState(() => _search = v),
    );
    final supplier = DropdownButtonFormField<String?>(
      key: ValueKey('rsup$_supplierId${suppliers.length}'),
      initialValue: suppliers.any((s) => s.id == _supplierId) ? _supplierId : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: l.commonSupplier),
      items: [
        DropdownMenuItem(value: null, child: Text(l.invAllSuppliers)),
        for (final s in suppliers)
          DropdownMenuItem(
            value: s.id,
            child: Text(s.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => setState(() => _supplierId = v),
    );
    final status = DropdownButtonFormField<String?>(
      initialValue: _status,
      isExpanded: true,
      decoration: InputDecoration(labelText: l.commonStatus),
      items: [
        DropdownMenuItem(value: null, child: Text(l.commonAll)),
        for (final e in receiptStatusLabelsOf(l).entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: (v) => setState(() => _status = v),
    );
    final periods = [
      for (final p in ReceiptPeriod.values)
        ChoiceChip(
          label: Text(
            p == ReceiptPeriod.custom && _range != null && _period == ReceiptPeriod.custom
                ? '${formatDate(_range!.start)} – ${formatDate(_range!.end)}'
                : p.labelIn(l),
          ),
          selected: _period == p,
          onSelected: (_) => p == ReceiptPeriod.custom ? _pickRange() : setState(() => _period = p),
        ),
    ];
    final filters = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: Gap.s),
              Row(
                children: [
                  Expanded(flex: 3, child: supplier),
                  const SizedBox(width: Gap.s),
                  Expanded(flex: 2, child: status),
                ],
              ),
              const SizedBox(height: Gap.s),
              InvChipBar(children: periods),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: Gap.m),
                  Expanded(flex: 3, child: supplier),
                  const SizedBox(width: Gap.m),
                  Expanded(flex: 2, child: status),
                ],
              ),
              const SizedBox(height: Gap.s),
              Wrap(spacing: Gap.s, runSpacing: Gap.s, children: periods),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(padding: const EdgeInsets.only(top: Gap.s), child: filters),
        const SizedBox(height: Gap.m),
        Expanded(
          child: AsyncView(
            value: ref.watch(goodsReceiptsProvider(f)),
            onRetry: () => ref.invalidate(goodsReceiptsProvider(f)),
            data: (rows) {
              if (rows.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: l.invNoDocs,
                  message: _filtered ? l.invChangeFiltersOrPeriod : l.invPostedAppearHere,
                );
              }
              final posted = rows.where((r) => r.receipt.status == ReceiptStatus.posted);
              final sum = posted.fold<int>(0, (s, r) => s + r.receipt.total);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${rows.length >= receiptsLimit ? l.invDocsCountLimited('${rows.length}', '$receiptsLimit') : l.invDocsCount('${rows.length}')}'
                    ' · ${l.invPostedFor(Money.format(sum))}',
                    style: t.textTheme.bodySmall,
                  ),
                  const SizedBox(height: Gap.s),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) => c.maxWidth >= 820
                          ? _ReceiptsTable(rows: rows, suppliers: supplierNames)
                          : _ReceiptsCards(rows: rows, suppliers: supplierNames),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

String _supplierOf(GoodsReceipt r, Map<String, String> names, AppLocalizations l) =>
    r.supplierId == null ? l.invNoSupplier : names[r.supplierId] ?? l.invDeletedSupplier;

String? _sourceOf(ReceiptListRow row, AppLocalizations l) =>
    row.orderNumber != null ? l.invOrderRef(row.orderNo!) : (row.receipt.orderId != null ? l.invOrder : null);

class _ReceiptsTable extends StatelessWidget {
  const _ReceiptsTable({required this.rows, required this.suppliers});
  final List<ReceiptListRow> rows;
  final Map<String, String> suppliers;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final head = t.textTheme.labelMedium?.copyWith(color: t.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600);
    final muted = t.colorScheme.onSurfaceVariant;
    final l = context.l10n;
    Widget cells({
      required Widget no,
      required Widget date,
      required Widget supplier,
      required Widget invoice,
      required Widget lines,
      required Widget total,
      required Widget status,
      required Widget source,
    }) => Row(
      children: [
        SizedBox(width: 72, child: no),
        SizedBox(width: 128, child: date),
        Expanded(flex: 3, child: supplier),
        const SizedBox(width: Gap.s),
        Expanded(flex: 2, child: invoice),
        SizedBox(width: 72, child: Align(alignment: Alignment.centerRight, child: lines)),
        SizedBox(width: 136, child: Align(alignment: Alignment.centerRight, child: total)),
        const SizedBox(width: Gap.l),
        SizedBox(width: 108, child: Align(alignment: Alignment.centerLeft, child: status)),
        SizedBox(width: 96, child: source),
      ],
    );
    Text txt(String s, {TextStyle? style}) => Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.m),
            child: cells(
              no: txt(l.invNoHeader, style: head),
              date: txt(l.commonDate, style: head),
              supplier: txt(l.commonSupplier, style: head),
              invoice: txt(l.invInvoice, style: head),
              lines: txt(l.invPositionsHeader, style: head),
              total: txt(l.commonAmount, style: head),
              status: txt(l.commonStatus, style: head),
              source: txt(l.invSource, style: head),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final row = rows[i];
                final r = row.receipt;
                final reversed = r.status == ReceiptStatus.reversed;
                return InkWell(
                  key: ValueKey('receipt-row-${r.id}'),
                  onTap: () => showReceiptDocument(context, r.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.m),
                    child: cells(
                      no: txt(l.invNumber(docNo(r.number, r.deviceCode)), style: const TextStyle(fontWeight: FontWeight.w700)),
                      date: txt(formatDateTime(r.createdAt)),
                      supplier: txt(_supplierOf(r, suppliers, l)),
                      invoice: txt(r.supplierInvoice ?? '—', style: TextStyle(color: r.supplierInvoice == null ? muted : null)),
                      lines: txt('${row.lineCount}'),
                      total: txt(
                        Money.format(r.total),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: reversed ? muted : null,
                          decoration: reversed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      status: ReceiptStatusChip(r.status),
                      source: txt(_sourceOf(row, l) ?? '—', style: TextStyle(color: _sourceOf(row, l) == null ? muted : null)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptsCards extends StatelessWidget {
  const _ReceiptsCards({required this.rows, required this.suppliers});
  final List<ReceiptListRow> rows;
  final Map<String, String> suppliers;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final sub = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    final l = context.l10n;
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        final r = row.receipt;
        final reversed = r.status == ReceiptStatus.reversed;
        final extra = [
          if (r.supplierInvoice != null) l.invInvoiceShort(r.supplierInvoice!),
          ?_sourceOf(row, l),
        ].join(' · ');
        return Card(
          key: ValueKey('receipt-row-${r.id}'),
          margin: const EdgeInsets.only(bottom: Gap.s),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showReceiptDocument(context, r.id),
            child: Padding(
              padding: const EdgeInsets.all(Gap.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.invReceiptRef(docNo(r.number, r.deviceCode)),
                          style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      ReceiptStatusChip(r.status),
                    ],
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(
                    '${formatDateTime(r.createdAt)} · ${_supplierOf(r, suppliers, l)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: sub,
                  ),
                  if (extra.isNotEmpty) Text(extra, maxLines: 1, overflow: TextOverflow.ellipsis, style: sub),
                  const SizedBox(height: Gap.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.commonPositionsCount(row.lineCount),
                          style: t.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        Money.format(r.total),
                        style: t.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: reversed ? t.colorScheme.onSurfaceVariant : null,
                          decoration: reversed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
