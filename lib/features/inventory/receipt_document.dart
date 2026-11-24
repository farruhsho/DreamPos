// Goods receipt document «Приход №N»: detail view (dialog on desktop,
// full-screen page on phones) with printing and reversal («сторно»).
// Public entry point for other modules: [showReceiptDocument].
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'inventory_logic.dart';
import 'inventory_pdf.dart';

/// Opens the goods receipt document (dialog on desktop, full screen on phone).
Future<void> showReceiptDocument(BuildContext context, String receiptId) {
  if (context.isCompact) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Документ прихода')),
          body: SafeArea(
            child: ReceiptDocumentView(receiptId: receiptId, fullPage: true),
          ),
        ),
      ),
    );
  }
  return showFormDialog<void>(
    context,
    title: 'Документ прихода',
    width: 960,
    child: ReceiptDocumentView(receiptId: receiptId),
  );
}

/// Success toast after posting a receipt, with an action opening the document.
void showReceiptPosted(BuildContext context, PostedReceipt r, {String? details}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: Gap.m),
            Expanded(child: Text('Приход №${r.number} проведён${details == null ? '' : ' · $details'}')),
          ],
        ),
        backgroundColor: AppColors.success,
        persist: false,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Открыть',
          textColor: Colors.white,
          onPressed: () {
            if (context.mounted) showReceiptDocument(context, r.id);
          },
        ),
      ),
    );
}

Color receiptStatusColor(String status) => status == ReceiptStatus.reversed ? AppColors.danger : AppColors.success;

/// Status chip «Проведён» / «Сторнирован».
class ReceiptStatusChip extends StatelessWidget {
  const ReceiptStatusChip(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) =>
      StatusChip(receiptStatusLabels[status] ?? status, color: receiptStatusColor(status));
}

/// Asks for a mandatory reversal reason. Returns null when cancelled.
Future<String?> askReceiptReversal(BuildContext context, GoodsReceipt r, {String? supplierName}) {
  return showDialog<String>(context: context, builder: (_) => _ReverseDialog(r, supplierName));
}

class _ReverseDialog extends StatefulWidget {
  const _ReverseDialog(this.r, this.supplierName);
  final GoodsReceipt r;
  final String? supplierName;
  @override
  State<_ReverseDialog> createState() => _ReverseDialogState();
}

class _ReverseDialogState extends State<_ReverseDialog> {
  final _key = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (_key.currentState!.validate()) Navigator.pop(context, _reason.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final r = widget.r;
    return AlertDialog(
      icon: const Icon(Icons.undo, color: AppColors.danger),
      title: Text('Сторнировать приход №${r.number}?'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                [
                  'Остатки товаров уменьшатся на количество из документа, себестоимость будет '
                      'пересчитана. Розничные цены, изменённые этим приходом, вернутся к прежним, '
                      'если их не меняли позже.',
                  if (widget.supplierName != null && r.total != 0)
                    'Долг перед поставщиком ${widget.supplierName} уменьшится на ${Money.format(r.total)}.',
                  'Отменить сторно нельзя.',
                ].join('\n\n'),
                style: t.textTheme.bodyMedium,
              ),
              const SizedBox(height: Gap.l),
              TextFormField(
                controller: _reason,
                autofocus: true,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Причина сторно *'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Укажите причину сторно' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: _submit,
          child: const Text('Сторнировать'),
        ),
      ],
    );
  }
}

/// Body of the receipt document (header, lines, totals, actions).
class ReceiptDocumentView extends ConsumerStatefulWidget {
  const ReceiptDocumentView({super.key, required this.receiptId, this.fullPage = false});
  final String receiptId;

  /// Fills a page (phones) instead of sizing to content inside a dialog.
  final bool fullPage;

  @override
  ConsumerState<ReceiptDocumentView> createState() => _ReceiptDocumentViewState();
}

class _ReceiptDocumentViewState extends ConsumerState<ReceiptDocumentView> {
  bool _asking = false; // reversal dialog open: ignore repeated taps
  bool _busy = false; // reversal running
  bool _printing = false;

  Widget _boxed(Widget child) =>
      widget.fullPage ? child : SizedBox(height: 260, child: child);

  @override
  Widget build(BuildContext context) {
    final id = widget.receiptId;
    final receipt = ref.watch(goodsReceiptProvider(id));
    return AsyncView(
      value: receipt,
      onRetry: () => ref.invalidate(goodsReceiptProvider(id)),
      data: (r) {
        if (r == null) {
          return _boxed(
            const EmptyState(
              icon: Icons.search_off,
              title: 'Документ не найден',
              message: 'Возможно, он был удалён или ещё не синхронизирован',
            ),
          );
        }
        final items = ref.watch(goodsReceiptItemsProvider(id));
        return switch (items) {
          AsyncData(:final value) => _content(r, value),
          AsyncError(:final error) => _boxed(
            ErrorView(error: error, onRetry: () => ref.invalidate(goodsReceiptItemsProvider(id))),
          ),
          _ => _boxed(const LoadingView()),
        };
      },
    );
  }

  Widget _content(GoodsReceipt r, List<GoodsReceiptItem> items) {
    final t = Theme.of(context);
    final products = ref.watch(invProductMapProvider).value ?? const <String, Product>{};
    final suppliers = ref.watch(invSupplierNamesProvider).value ?? const <String, String>{};
    final users = ref.watch(invUserNamesProvider).value ?? const <String, String>{};
    final orderNumber = r.orderId == null ? null : ref.watch(invOrderNumberProvider(r.orderId!)).value;
    final lines = receiptDocLines(items, products);
    final supplierName = r.supplierId == null ? null : suppliers[r.supplierId] ?? 'Удалённый поставщик';
    final author = r.userId == null ? null : users[r.userId];
    final reversedBy = r.reversedBy == null ? null : users[r.reversedBy];
    final reversed = r.status == ReceiptStatus.reversed;
    final canReverse = !reversed && (ref.watch(sessionProvider)?.can(Perm.stockOps) ?? false);
    final compact = context.isCompact;

    final info = Wrap(
      spacing: Gap.xl,
      runSpacing: Gap.m,
      children: [
        _Info('Дата', formatDateTime(r.createdAt)),
        _Info('Поставщик', supplierName ?? 'Без поставщика'),
        _Info('Накладная поставщика', r.supplierInvoice ?? '—'),
        _Info('Источник', orderNumber != null ? 'Заказ №$orderNumber' : (r.orderId != null ? 'Заказ' : 'Ручной приход')),
        if (author != null) _Info('Принял', author),
        if (r.note != null && r.note!.isNotEmpty) _Info('Комментарий', r.note!, wide: true),
      ],
    );

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Приход №${r.number}',
            style: t.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              decoration: reversed ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        ReceiptStatusChip(r.status),
      ],
    );

    final reversal = reversed
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Gap.m),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.undo, color: AppColors.danger),
                const SizedBox(width: Gap.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          'Сторнирован',
                          if (r.reversedAt != null) formatDateTime(r.reversedAt!),
                          ?reversedBy,
                        ].join(' · '),
                        style: t.textTheme.titleSmall?.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700),
                      ),
                      if (r.reverseReason != null) Text('Причина: ${r.reverseReason}'),
                    ],
                  ),
                ),
              ],
            ),
          )
        : null;

    final qtyTotal = lines.fold<double>(0, (s, l) => s + l.item.qty);
    final totals = Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Gap.m,
      runSpacing: Gap.xs,
      children: [
        Text(
          'Позиций: ${lines.length} · количество ${Qty.format(qtyTotal)}',
          style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
        ),
        Text(
          'Итого: ${Money.format(r.total)}',
          style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );

    final body = ListView(
      shrinkWrap: !widget.fullPage,
      padding: EdgeInsets.fromLTRB(compact ? Gap.m : Gap.xl, Gap.m, compact ? Gap.m : Gap.xl, Gap.m),
      children: [
        header,
        const SizedBox(height: Gap.m),
        info,
        if (reversal != null) ...[const SizedBox(height: Gap.m), reversal],
        const SizedBox(height: Gap.l),
        Text('Позиции', style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: Gap.s),
        if (lines.isEmpty)
          const Padding(
            padding: EdgeInsets.all(Gap.l),
            child: Text('В документе нет позиций'),
          )
        else
          LayoutBuilder(
            builder: (context, c) => c.maxWidth >= _linesTableMinWidth ? _LinesTable(lines) : _LinesCards(lines),
          ),
        const SizedBox(height: Gap.m),
        totals,
      ],
    );

    final printBtn = OutlinedButton.icon(
      onPressed: _printing
          ? null
          : () => _print(r, lines, supplierName: supplierName, orderNumber: orderNumber, author: author, reversedBy: reversedBy),
      icon: _printing
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.print_outlined),
      label: const Text('Печать'),
    );
    final reverseBtn = canReverse
        ? FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: _busy || _asking ? null : () => _reverse(r, supplierName),
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.undo),
            label: const Text('Сторнировать'),
          )
        : null;
    final actions = Padding(
      padding: EdgeInsets.fromLTRB(compact ? Gap.m : Gap.xl, Gap.m, compact ? Gap.m : Gap.xl, Gap.l),
      child: compact
          ? Row(
              children: [
                Expanded(child: printBtn),
                if (reverseBtn != null) ...[const SizedBox(width: Gap.s), Expanded(child: reverseBtn)],
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                printBtn,
                if (reverseBtn != null) ...[const SizedBox(width: Gap.s), reverseBtn],
              ],
            ),
    );

    return Column(
      mainAxisSize: widget.fullPage ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(fit: widget.fullPage ? FlexFit.tight : FlexFit.loose, child: body),
        const Divider(height: 1),
        actions,
      ],
    );
  }

  Future<void> _print(
    GoodsReceipt r,
    List<ReceiptDocLine> lines, {
    String? supplierName,
    int? orderNumber,
    String? author,
    String? reversedBy,
  }) async {
    if (_printing) return;
    setState(() => _printing = true);
    await runGuarded(
      context,
      () => printReceiptDocument(
        ref.read(databaseProvider),
        receipt: r,
        lines: lines,
        supplierName: supplierName,
        orderNumber: orderNumber,
        authorName: author,
        reversedByName: reversedBy,
      ),
    );
    if (mounted) setState(() => _printing = false);
  }

  Future<void> _reverse(GoodsReceipt r, String? supplierName) async {
    if (_busy || _asking) return;
    setState(() => _asking = true);
    final reason = await askReceiptReversal(context, r, supplierName: supplierName);
    if (!mounted) return;
    setState(() {
      _asking = false;
      _busy = reason != null;
    });
    if (reason == null) return;
    await runGuarded(
      context,
      () => ref
          .read(inventoryRepoProvider)
          .reverseReceipt(r.id, reason: reason, userId: ref.read(sessionProvider)?.user.id),
      success: 'Приход №${r.number} сторнирован',
    );
    if (mounted) setState(() => _busy = false);
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value, {this.wide = false});
  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 140, maxWidth: wide ? 600 : 280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          Text(value, style: t.textTheme.bodyLarge, maxLines: wide ? 4 : 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

String _priceText(ReceiptDocLine l) => l.priceChanged
    ? '${Money.format(l.item.newPrice!)}${l.item.oldPrice == null ? '' : ' (было ${Money.format(l.item.oldPrice!)})'}'
    : '—';

/// Fixed numeric columns of [_LinesTable] (32+100+120+130+200) plus row
/// padding take 606px; below this width «Товар» would get under ~200px and
/// the cards layout is used instead.
const _linesTableMinWidth = 820.0;

class _LinesTable extends StatelessWidget {
  const _LinesTable(this.lines);
  final List<ReceiptDocLine> lines;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final head = t.textTheme.labelMedium?.copyWith(color: t.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600);
    Widget row(List<Widget> cells, {Color? color}) => Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.s),
      child: Row(children: cells),
    );
    Widget num(String s, double w, {TextStyle? style}) =>
        SizedBox(width: w, child: Text(s, textAlign: TextAlign.right, style: style, maxLines: 1, overflow: TextOverflow.ellipsis));
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), [
            SizedBox(width: 32, child: Text('№', style: head)),
            Expanded(child: Text('Товар', style: head)),
            num('Кол-во', 100, style: head),
            num('Цена закупки', 120, style: head),
            num('Сумма', 130, style: head),
            num('Новая розн. цена', 200, style: head),
          ]),
          for (var i = 0; i < lines.length; i++) ...[
            const Divider(height: 1),
            row([
              SizedBox(width: 32, child: Text('${i + 1}')),
              Expanded(child: Text(lines[i].name, maxLines: 2, overflow: TextOverflow.ellipsis)),
              num(Qty.format(lines[i].item.qty, lines[i].unit), 100),
              num(Money.format(lines[i].item.unitCost), 120),
              num(Money.format(lines[i].total), 130, style: const TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // New price and «(было …)» on separate lines so big sums fit.
                    Text(
                      lines[i].priceChanged ? Money.format(lines[i].item.newPrice!) : '—',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lines[i].priceChanged && lines[i].item.oldPrice != null)
                      Text(
                        'было ${Money.format(lines[i].item.oldPrice!)}',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _LinesCards extends StatelessWidget {
  const _LinesCards(this.lines);
  final List<ReceiptDocLine> lines;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final sub = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: Gap.s),
            child: Padding(
              padding: const EdgeInsets.all(Gap.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}. ${lines[i].name}', maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.bodyLarge),
                  const SizedBox(height: Gap.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${Qty.format(lines[i].item.qty, lines[i].unit)} × ${Money.format(lines[i].item.unitCost)}',
                          style: sub,
                        ),
                      ),
                      Text(Money.format(lines[i].total), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if (lines[i].priceChanged) Text('Розничная цена: ${_priceText(lines[i])}', style: sub),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
