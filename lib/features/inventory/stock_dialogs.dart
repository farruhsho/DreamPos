// Quick per-product dialogs used from the stock overview: receipt,
// write-off, manual correction and movement history.
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'inventory_logic.dart';
import 'receipt_document.dart';
import '../../l10n/l10n.dart';

String? _uid(WidgetRef ref) => ref.read(sessionProvider)?.user.id;

/// Quick receipt of one product (manual, no supplier debt).
Future<void> showQuickReceiptDialog(BuildContext context, Product p) =>
    showFormDialog<void>(context, title: context.l10n.invQuickReceiptTitle(p.name), width: 440, child: _QuickReceipt(p));

class _QuickReceipt extends ConsumerStatefulWidget {
  const _QuickReceipt(this.p);
  final Product p;
  @override
  ConsumerState<_QuickReceipt> createState() => _QuickReceiptState();
}

class _QuickReceiptState extends ConsumerState<_QuickReceipt> {
  final _key = GlobalKey<FormState>();
  final _qty = TextEditingController();
  late int? _cost = widget.p.costPrice;
  bool _busy = false;

  Future<void> _save() async {
    if (_busy || !_key.currentState!.validate()) return;
    setState(() => _busy = true);
    final q = QtyField.parse(_qty.text)!;
    PostedReceipt? posted;
    final ok = await runGuarded(
      context,
      () async => posted = await ref
          .read(inventoryRepoProvider)
          .postReceiptDoc(
            lines: [ReceiptLine(product: widget.p, qty: q, unitCost: _cost ?? widget.p.costPrice)],
            userId: _uid(ref),
          ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      // Toast on the page behind the dialog so «Открыть» outlives it.
      final page = Navigator.of(context).context;
      Navigator.pop(context);
      if (posted != null && page.mounted) {
        showReceiptPosted(page, posted!, details: '${widget.p.name}: ${Qty.format(q, widget.p.unit)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final canCost = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    return Form(
      key: _key,
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.invCurrentStock(Qty.format(widget.p.stockQty, widget.p.unit))),
            const SizedBox(height: Gap.m),
            QtyField(controller: _qty, unit: widget.p.unit, autofocus: true, onSubmitted: (_) => _save()),
            const SizedBox(height: Gap.m),
            if (canCost)
              MoneyField(
                label: l.invUnitCostRequired,
                initial: widget.p.costPrice,
                required: true,
                onChanged: (v) => _cost = v,
                onSubmitted: (_) => _save(),
              ),
            const SizedBox(height: Gap.l),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.add_box_outlined),
              label: Text(l.invPostIn),
            ),
          ],
        ),
      ),
    );
  }
}

/// Write-off form; also embedded in the «Списание» tab.
class WriteOffForm extends ConsumerStatefulWidget {
  const WriteOffForm({super.key, this.product, this.onDone, this.pickProduct});
  final Product? product;
  final VoidCallback? onDone;

  /// Opens a product chooser; when null the product is fixed.
  final Future<Product?> Function()? pickProduct;

  @override
  ConsumerState<WriteOffForm> createState() => _WriteOffFormState();
}

class _WriteOffFormState extends ConsumerState<WriteOffForm> {
  final _key = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _comment = TextEditingController();
  late Product? _p = widget.product;
  /// Index into [writeOffReasonsOf]; the last reason is «Другое».
  int? _reason;
  bool _busy = false;

  double? get _q => QtyField.parse(_qty.text);

  bool get _isOther => _reason == writeOffReasonsOf(L.current).length - 1;

  String? _reasonText(AppLocalizations l) => _reason == null ? null : writeOffReasonsOf(l)[_reason!];

  Future<void> _choose() async {
    final p = await widget.pickProduct?.call();
    if (p != null) setState(() => _p = p);
  }

  Future<void> _save() async {
    final p = _p;
    final l = context.l10n;
    if (_busy) return;
    if (p == null) {
      showError(context, l.invSelectProduct);
      return;
    }
    if (!_key.currentState!.validate()) return;
    if (_reason == null) {
      showError(context, l.invSpecifyWriteoffReason);
      return;
    }
    if (_isOther && _comment.text.trim().isEmpty) {
      showError(context, l.invDescribeReason);
      return;
    }
    final q = _q!;
    final value = lineValue(q, p.costPrice);
    final ok = await confirm(
      context,
      title: l.invWriteoffConfirmTitle,
      message: l.invWriteoffConfirmMessage(p.name, Qty.format(q, p.unit), Money.format(value), _reasonText(l)!),
      ok: l.invWriteoffAction,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final reason = [_reasonText(l)!, if (_comment.text.trim().isNotEmpty) _comment.text.trim()].join(': ');
    final done = await runGuarded(
      context,
      () => ref.read(stockServiceProvider).writeOff(productId: p.id, qty: q, reason: reason, userId: _uid(ref)),
      success: l.invWrittenOff(Qty.format(q, p.unit), p.name),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (done) {
        _qty.clear();
        _comment.clear();
        _reason = null;
        if (widget.pickProduct != null) _p = null;
      }
    });
    if (done) widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final reasons = writeOffReasonsOf(l);
    final canCost = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    // Live product (stock may change while the form is open).
    final live = _p == null ? null : ref.watch(invProductMapProvider).value?[_p!.id] ?? _p;
    final q = _q;
    return Form(
      key: _key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.pickProduct != null)
            OutlinedButton.icon(
              onPressed: _choose,
              icon: const Icon(Icons.search),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(live?.name ?? l.invChooseProduct, overflow: TextOverflow.ellipsis),
              ),
            ),
          if (live != null) ...[
            const SizedBox(height: Gap.s),
            Text(
              canCost
                  ? l.invStockLineWithCost(Qty.format(live.stockQty, live.unit), Money.format(live.costPrice))
                  : l.invStockLine(Qty.format(live.stockQty, live.unit)),
              style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: Gap.m),
          QtyField(
            controller: _qty,
            unit: live?.unit,
            autofocus: widget.pickProduct == null,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: Gap.m),
          Text(l.commonReason, style: t.textTheme.labelLarge),
          const SizedBox(height: Gap.s),
          Wrap(
            spacing: Gap.s,
            runSpacing: Gap.s,
            children: [
              for (final (i, r) in reasons.indexed)
                ChoiceChip(label: Text(r), selected: _reason == i, onSelected: (_) => setState(() => _reason = i)),
            ],
          ),
          const SizedBox(height: Gap.m),
          TextField(
            controller: _comment,
            decoration: InputDecoration(labelText: _isOther ? l.invCommentRequired : l.commonComment),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: Gap.l),
          ListenableBuilder(
            listenable: _qty,
            builder: (_, _) {
              final v = (live != null && q != null && q > 0) ? lineValue(q, live.costPrice) : 0;
              return Row(
                children: [
                  if (canCost)
                    Expanded(
                      child: Text(
                        l.invWriteoffSum(Money.format(v)),
                        style: t.textTheme.titleMedium?.copyWith(
                          color: v > 0 ? AppColors.danger : t.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                    onPressed: _busy ? null : _save,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: Text(l.invWriteoffAction),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

Future<void> showWriteOffDialog(BuildContext context, Product p) => showFormDialog<void>(
  context,
  title: context.l10n.invWriteoff,
  width: 520,
  child: Builder(
    builder: (c) => SingleChildScrollView(
      padding: const EdgeInsets.all(Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(p.name, style: Theme.of(c).textTheme.titleMedium),
          WriteOffForm(product: p, onDone: () => Navigator.pop(c)),
        ],
      ),
    ),
  ),
);

/// Manual correction to an absolute quantity.
Future<void> showAdjustDialog(BuildContext context, WidgetRef ref, Product p) async {
  final key = GlobalKey<FormState>();
  final qty = TextEditingController(text: Qty.format(p.stockQty));
  final reason = TextEditingController();
  final l = context.l10n;
  var busy = false;
  Future<void> submit(BuildContext c) async {
    if (busy || !key.currentState!.validate()) return;
    final n = QtyField.parse(qty.text)!;
    if (Qty.round(n - p.stockQty) == 0) {
      showError(c, l.invStockUnchanged);
      return;
    }
    busy = true;
    final ok = await runGuarded(
      c,
      () => ref
          .read(stockServiceProvider)
          .setStock(productId: p.id, newQty: n, reason: reason.text.trim(), userId: ref.read(sessionProvider)?.user.id),
      success: l.invStockCorrected,
    );
    busy = false;
    if (ok && c.mounted) Navigator.pop(c);
  }

  await showFormDialog<void>(
    context,
    title: l.invAdjustTitle,
    width: 440,
    child: Builder(
      builder: (c) => Form(
        key: key,
        child: Padding(
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(p.name, style: Theme.of(c).textTheme.titleMedium),
              Text(l.invBookStock(Qty.format(p.stockQty, p.unit))),
              const SizedBox(height: Gap.m),
              QtyField(
                controller: qty,
                label: l.invActualStock,
                unit: p.unit,
                allowZero: true,
                autofocus: true,
                onSubmitted: (_) => submit(c),
              ),
              const SizedBox(height: Gap.m),
              TextFormField(
                controller: reason,
                decoration: InputDecoration(labelText: l.invReasonRequired),
                validator: (v) => (v ?? '').trim().isEmpty ? l.invSpecifyAdjustReason : null,
                onFieldSubmitted: (_) => submit(c),
              ),
              const SizedBox(height: Gap.s),
              Text(l.invUseCountHint, style: Theme.of(c).textTheme.bodySmall),
              const SizedBox(height: Gap.l),
              FilledButton(onPressed: () => submit(c), child: Text(l.commonSave)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Last movements of a product.
Future<void> showProductHistoryDialog(BuildContext context, Product p) =>
    showFormDialog<void>(context, title: context.l10n.invHistoryTitle(p.name), width: 640, child: _ProductHistory(p));

final _productMovesProvider = StreamProvider.family<List<StockMovement>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.stockMovements)
        ..where((m) => m.productId.equals(id))
        ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
        ..limit(200))
      .watch();
});

class _ProductHistory extends ConsumerWidget {
  const _ProductHistory(this.p);
  final Product p;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numbers = ref.watch(goodsReceiptNumbersProvider).value ?? const <String, String>{};
    // Grows with the history up to 480px instead of always reserving it.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 480),
      child: AsyncView(
        value: ref.watch(_productMovesProvider(p.id)),
        data: (list) => list.isEmpty
            ? SizedBox(
                height: 240,
                child: EmptyState(icon: Icons.swap_vert, title: context.l10n.invNoMovementsYet),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(Gap.s),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, i) => _refTile(context, numbers, list[i], p.unit),
              ),
      ),
    );
  }
}

/// Movement tile with its source document («Приход №N») opening on tap.
Widget _refTile(BuildContext context, Map<String, String> numbers, StockMovement m, String unit) {
  final reference = movementReference(m, numbers);
  return MovementTile(
    m: m,
    unit: unit,
    reference: reference,
    onTap: reference == null ? null : () => showReceiptDocument(context, m.refId!),
  );
}

Color movementColor(String type) => switch (type) {
  'sale' => AppColors.info,
  'receipt' || 'return' => AppColors.success,
  'writeoff' || 'receipt_reversal' => AppColors.danger,
  _ => AppColors.warning,
};

class MovementTile extends StatelessWidget {
  const MovementTile({
    super.key,
    required this.m,
    required this.unit,
    this.productName,
    this.userName,
    this.showType = true,
    this.reference,
    this.onTap,
  });
  final StockMovement m;

  /// Source document, e.g. «Приход №12»; shown as a link when [onTap] is set.
  final String? reference;
  final VoidCallback? onTap;

  /// Hide the type chip in single-type journals (e.g. write-offs).
  final bool showType;
  final String unit;
  final String? productName;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final sign = m.qty > 0 ? '+' : '';
    // On phones the type moves into the subtitle so the product name keeps
    // the width; wider layouts show a fixed-width chip column.
    final compact = context.isCompact;
    final details = [
      if (productName != null) formatDateTime(m.createdAt),
      if (m.reason != null && m.reason!.isNotEmpty) m.reason!,
      if (m.unitCost > 0 && (m.type == 'receipt' || m.type == 'receipt_reversal')) l.invPriceDetail(Money.format(m.unitCost)),
      ?userName,
    ].join(' · ');
    final color = movementColor(m.type);
    return ListTile(
      dense: true,
      onTap: onTap,
      title: Text(
        productName ?? formatDateTime(m.createdAt),
        maxLines: compact ? 2 : 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            if (showType && compact)
              TextSpan(
                text: details.isEmpty ? movementLabel(m.type, l) : '${movementLabel(m.type, l)} · ',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            if (reference != null) ...[
              TextSpan(
                text: reference,
                style: TextStyle(
                  color: onTap != null ? t.colorScheme.primary : null,
                  fontWeight: FontWeight.w600,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
              if (details.isNotEmpty) const TextSpan(text: ' · '),
            ],
            TextSpan(text: details),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      // Fixed-width slot so titles line up regardless of the chip label.
      leading: showType && !compact
          ? SizedBox(
              width: 128,
              child: Align(
                alignment: Alignment.centerLeft,
                // Longer uz/ky labels scale down instead of overflowing the slot.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: StatusChip(movementLabel(m.type, l), color: color),
                ),
              ),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$sign${Qty.format(m.qty, unit)}',
            style: t.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: m.qty >= 0 ? AppColors.success : AppColors.danger,
            ),
          ),
          Text(
            l.invStockAfter(Qty.format(m.qtyAfter, unit)),
            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
