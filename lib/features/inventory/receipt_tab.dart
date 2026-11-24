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
import 'receipt_document.dart';
import 'receipt_documents_view.dart';
import '../../l10n/l10n.dart';

class _Line {
  _Line(this.product)
    : qty = TextEditingController(text: '1'),
      cost = TextEditingController(text: Money.toInput(product.costPrice)),
      price = TextEditingController();
  final Product product;
  final TextEditingController qty;
  final TextEditingController cost;
  final TextEditingController price;
  final key = UniqueKey();

  double? get q => QtyField.parse(qty.text);
  int? get c => Money.parse(cost.text);
  int? get newPrice => price.text.trim().isEmpty ? null : Money.parse(price.text);
  int get total => (q ?? 0) <= 0 || c == null ? 0 : lineValue(q!, c!);

  void dispose() {
    qty.dispose();
    cost.dispose();
    price.dispose();
  }
}

enum _ReceiptView { form, documents }

/// «Приход»: new goods receipt (no purchase order) and the journal of
/// receipt documents, switched by a segmented control. Both views stay alive
/// so a half-filled receipt survives a look at the documents.
class ReceiptTab extends StatefulWidget {
  const ReceiptTab({super.key});
  @override
  State<ReceiptTab> createState() => _ReceiptTabState();
}

class _ReceiptTabState extends State<ReceiptTab> {
  _ReceiptView _view = _ReceiptView.form;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Gap.s),
          child: Align(
            alignment: compact ? Alignment.center : Alignment.centerLeft,
            child: SegmentedButton<_ReceiptView>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _ReceiptView.form,
                  icon: const Icon(Icons.add_box_outlined),
                  label: Text(l.invNewReceipt),
                ),
                ButtonSegment(
                  value: _ReceiptView.documents,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(l.invDocuments),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (v) => setState(() => _view = v.first),
            ),
          ),
        ),
        const SizedBox(height: Gap.s),
        Expanded(
          child: IndexedStack(
            index: _view.index,
            sizing: StackFit.expand,
            children: const [_ReceiptForm(), ReceiptDocumentsView()],
          ),
        ),
      ],
    );
  }
}

/// New goods receipt document without a purchase order.
class _ReceiptForm extends ConsumerStatefulWidget {
  const _ReceiptForm();
  @override
  ConsumerState<_ReceiptForm> createState() => _ReceiptFormState();
}

class _ReceiptFormState extends ConsumerState<_ReceiptForm> {
  final _formKey = GlobalKey<FormState>();
  final _lines = <_Line>[];
  final _scan = TextEditingController();
  final _scanFocus = FocusNode();
  final _note = TextEditingController();
  final _invoice = TextEditingController();
  String? _supplierId;
  bool _busy = false;

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    _scan.dispose();
    _scanFocus.dispose();
    _note.dispose();
    _invoice.dispose();
    super.dispose();
  }

  void _add(Product p) {
    setState(() {
      final existing = _lines.where((l) => l.product.id == p.id).firstOrNull;
      if (existing != null) {
        final q = (existing.q ?? 0) + 1;
        existing.qty.text = Qty.format(q);
      } else {
        _lines.add(_Line(p));
      }
    });
  }

  Future<void> _onScan(String code) async {
    if (code.trim().isEmpty) return;
    final p = await findByCode(ref.read(databaseProvider), code);
    if (!mounted) return;
    if (p == null) {
      showError(context, context.l10n.invScanNotFound(code.trim()));
    } else {
      _add(p);
    }
    _scan.clear();
    _scanFocus.requestFocus();
  }

  Future<void> _pick() async {
    final p = await pickProduct(context, title: context.l10n.invAddToReceipt);
    if (p != null) _add(p);
  }

  void _remove(_Line l) => setState(() {
    _lines.remove(l);
    l.dispose();
  });

  Future<void> _clear() async {
    if (_lines.isEmpty) return;
    final l = context.l10n;
    final ok = await confirm(
      context,
      title: l.invClearDocTitle,
      message: l.invClearDocMessage,
      ok: l.commonClear,
      destructive: true,
    );
    if (!ok) return;
    setState(() {
      for (final l in _lines) {
        l.dispose();
      }
      _lines.clear();
      _note.clear();
      _invoice.clear();
      _supplierId = null;
    });
  }

  int get _total => _lines.fold(0, (s, l) => s + l.total);

  Future<void> _post(List<Supplier> suppliers) async {
    if (_busy) return;
    final l = context.l10n;
    if (_lines.isEmpty) {
      showError(context, l.invAddAtLeastOneLine);
      return;
    }
    if (!_formKey.currentState!.validate()) {
      showError(context, l.invCheckFields);
      return;
    }
    final sup = suppliers.where((s) => s.id == _supplierId).firstOrNull;
    final total = _total;
    final ok = await confirm(
      context,
      title: l.invPostReceiptTitle,
      message: [
        l.invPostReceiptMessage('${_lines.length}', Money.format(total)),
        if (sup != null) l.invPostReceiptDebt(sup.name, Money.format(total)),
      ].join('\n\n'),
      ok: l.invPost,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final canPrices = ref.read(sessionProvider)?.can(Perm.editPrices) ?? false;
    final lines = [
      for (final l in _lines)
        ReceiptLine(product: l.product, qty: l.q!, unitCost: l.c!, newPrice: canPrices ? l.newPrice : null),
    ];
    PostedReceipt? posted;
    final invoice = _invoice.text.trim();
    final done = await runGuarded(
      context,
      () async => posted = await ref
          .read(inventoryRepoProvider)
          .postReceiptDoc(
            lines: lines,
            supplierId: _supplierId,
            userId: ref.read(sessionProvider)?.user.id,
            note: _note.text,
            supplierInvoice: invoice.isEmpty ? null : invoice,
            canEditPrices: canPrices,
          ),
    );
    if (!mounted) return;
    if (done && posted != null) {
      showReceiptPosted(context, posted!, details: l.invLinesFor('${lines.length}', Money.format(posted!.total)));
    }
    setState(() {
      _busy = false;
      if (done) {
        for (final l in _lines) {
          l.dispose();
        }
        _lines.clear();
        _note.clear();
        _invoice.clear();
      }
    });
  }

  /// Phones: total on its own line, then two equal full-width buttons.
  Widget _compactFooter(ThemeData t, List<Supplier> suppliers) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.invTotalLine(Money.format(_total)),
                style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(l.invPositionsLower('${_lines.length}'), style: t.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: Gap.s),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton(onPressed: _lines.isEmpty || _busy ? null : _clear, child: Text(l.commonClear)),
            ),
            const SizedBox(width: Gap.s),
            Expanded(
              flex: 3,
              child: FilledButton.icon(
                onPressed: _lines.isEmpty || _busy ? null : () => _post(suppliers),
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(l.invPostReceipt),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    final canPrices = session?.can(Perm.editPrices) ?? false;
    final suppliers = ref.watch(invSuppliersProvider).value ?? const <Supplier>[];
    final header = LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 700;
        final sup = DropdownButtonFormField<String?>(
          key: ValueKey('sup$_supplierId${suppliers.length}'),
          initialValue: suppliers.any((s) => s.id == _supplierId) ? _supplierId : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l.commonSupplier,
            helperText: l.invSupplierHelper,
            helperMaxLines: 2,
          ),
          items: [
            DropdownMenuItem(value: null, child: Text(l.invNoSupplier)),
            for (final s in suppliers)
              DropdownMenuItem(
                value: s.id,
                child: Text(s.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() => _supplierId = v),
        );
        // Shorter labels on phones, where the long ones were cut off.
        final invoice = TextFormField(
          controller: _invoice,
          maxLength: 60,
          decoration: InputDecoration(
            labelText: narrow ? l.invInvoiceNoShort : l.invInvoiceNoLong,
            counterText: '',
          ),
        );
        final note = TextField(
          controller: _note,
          decoration: InputDecoration(labelText: l.commonComment),
        );
        final scan = TextField(
          controller: _scan,
          focusNode: _scanFocus,
          autofocus: true,
          decoration: InputDecoration(
            labelText: narrow ? l.invScanShort : l.invScanLong,
            prefixIcon: const Icon(Icons.qr_code_scanner),
          ),
          onSubmitted: _onScan,
        );
        final pick = FilledButton.tonalIcon(
          onPressed: _pick,
          icon: const Icon(Icons.add),
          label: Text(l.invAddProduct),
        );
        if (narrow) {
          // Scan field and the add button share a row (icon-only on phones) so
          // the document lines start higher on the screen.
          final compactPick = IconButton.filledTonal(
            tooltip: l.invAddProduct,
            onPressed: _pick,
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sup,
              const SizedBox(height: Gap.s),
              Row(
                children: [
                  Expanded(child: invoice),
                  const SizedBox(width: Gap.s),
                  Expanded(child: note),
                ],
              ),
              const SizedBox(height: Gap.m),
              Row(
                children: [
                  Expanded(child: scan),
                  const SizedBox(width: Gap.s),
                  compactPick,
                ],
              ),
            ],
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: sup),
                const SizedBox(width: Gap.m),
                Expanded(flex: 2, child: invoice),
                const SizedBox(width: Gap.m),
                Expanded(flex: 3, child: note),
              ],
            ),
            const SizedBox(height: Gap.m),
            Row(
              children: [
                Expanded(child: scan),
                const SizedBox(width: Gap.m),
                pick,
              ],
            ),
          ],
        );
      },
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: Gap.s),
              children: [
                header,
                const SizedBox(height: Gap.l),
                if (_lines.isEmpty)
                  EmptyState(
                    icon: Icons.move_to_inbox_outlined,
                    title: l.invEmptyDoc,
                    message: l.invEmptyDocMessage,
                  )
                else
                  for (var i = 0; i < _lines.length; i++)
                    _LineRow(
                      key: _lines[i].key,
                      index: i + 1,
                      line: _lines[i],
                      canPrices: canPrices,
                      onChanged: () => setState(() {}),
                      onRemove: () => _remove(_lines[i]),
                    ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(top: Gap.m),
            child: context.isCompact
                ? _compactFooter(t, suppliers)
                : Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: Gap.m,
                    runSpacing: Gap.s,
                    children: [
                      Text(
                        '${l.invTotalLine(Money.format(_total))}  ·  ${l.invPositionsLower('${_lines.length}')}',
                        style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Wrap(
                        spacing: Gap.s,
                        children: [
                          OutlinedButton(
                            onPressed: _lines.isEmpty || _busy ? null : _clear,
                            child: Text(l.commonClear),
                          ),
                          FilledButton.icon(
                            onPressed: _lines.isEmpty || _busy ? null : () => _post(suppliers),
                            icon: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.check),
                            label: Text(l.invPostReceipt),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    super.key,
    required this.index,
    required this.line,
    required this.canPrices,
    required this.onChanged,
    required this.onRemove,
  });
  final int index;
  final _Line line;
  final bool canPrices;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final p = line.product;
    final qty = TextFormField(
      controller: line.qty,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: l.invQtyShort, suffixText: Qty.unitLabel(p.unit, l)),
      onChanged: (_) => onChanged(),
      validator: (v) => validateQty(QtyField.parse(v ?? ''), p.unit),
    );
    final cost = TextFormField(
      controller: line.cost,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: l.invPurchasePrice, suffixText: Money.currency.symbol),
      onChanged: (_) => onChanged(),
      validator: (v) {
        if ((v ?? '').trim().isEmpty) return l.invSpecifyPurchasePrice;
        final m = Money.parse(v!);
        if (m == null) return l.commonInvalidAmount;
        if (m < 0) return l.commonCannotBeNegative;
        return null;
      },
    );
    final price = TextFormField(
      controller: line.price,
      enabled: canPrices,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: l.invNewPrice,
        hintText: Money.toInput(p.price),
        suffixText: Money.currency.symbol,
        helperText: canPrices ? null : l.invNoPricePermission,
      ),
      onChanged: (_) => onChanged(),
      validator: (v) {
        if ((v ?? '').trim().isEmpty) return null;
        final m = Money.parse(v!);
        if (m == null || m <= 0) return l.invInvalidPrice;
        return null;
      },
    );
    final margin = line.c != null && line.c! > 0 ? ((line.newPrice ?? p.price) - line.c!) * 100 / line.c! : null;
    final total = Text(Money.format(line.total), style: const TextStyle(fontWeight: FontWeight.w700));
    final remove = IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline), tooltip: l.invDeleteLine);
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$index. ${p.name}', maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.bodyLarge),
        Text(
          [
            l.invLineInfo(Qty.format(p.stockQty, p.unit), Money.format(p.price)),
            if (margin != null) l.invMarkupPart(margin.toStringAsFixed(0)),
          ].join(' · '),
          style: t.textTheme.bodySmall?.copyWith(
            color: margin != null && margin < 0 ? AppColors.danger : t.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    return Card(
      margin: const EdgeInsets.only(bottom: Gap.s),
      child: Padding(
        padding: const EdgeInsets.all(Gap.m),
        child: LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: title),
                  const SizedBox(width: Gap.m),
                  SizedBox(width: 120, child: qty),
                  const SizedBox(width: Gap.m),
                  SizedBox(width: 150, child: cost),
                  const SizedBox(width: Gap.m),
                  SizedBox(width: 160, child: price),
                  const SizedBox(width: Gap.m),
                  SizedBox(
                    width: 130,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Align(alignment: Alignment.centerRight, child: total),
                    ),
                  ),
                  remove,
                ],
              );
            }
            if (c.maxWidth >= 560) {
              // Tablet: title on top, all inputs + line total in one row.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: title),
                      remove,
                    ],
                  ),
                  const SizedBox(height: Gap.s),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: qty),
                      const SizedBox(width: Gap.s),
                      Expanded(flex: 3, child: cost),
                      const SizedBox(width: Gap.s),
                      Expanded(flex: 3, child: price),
                      const SizedBox(width: Gap.m),
                      SizedBox(
                        width: 120,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Align(alignment: Alignment.centerRight, child: total),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: title),
                    remove,
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
                const SizedBox(height: Gap.s),
                Row(
                  children: [
                    Expanded(child: price),
                    const SizedBox(width: Gap.m),
                    total,
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
