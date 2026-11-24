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

/// «Приход»: goods receipt document without a purchase order.
class ReceiptTab extends ConsumerStatefulWidget {
  const ReceiptTab({super.key});
  @override
  ConsumerState<ReceiptTab> createState() => _ReceiptTabState();
}

class _ReceiptTabState extends ConsumerState<ReceiptTab> {
  final _formKey = GlobalKey<FormState>();
  final _lines = <_Line>[];
  final _scan = TextEditingController();
  final _scanFocus = FocusNode();
  final _note = TextEditingController();
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
    super.dispose();
  }

  void _add(Product p) {
    setState(() {
      final existing = _lines.where((l) => l.product.id == p.id).firstOrNull;
      if (existing != null) {
        final q = (existing.q ?? 0) + 1;
        existing.qty.text = Qty.format(q).replaceAll(',', '.');
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
      showError(context, 'Товар со штрихкодом/артикулом «${code.trim()}» не найден');
    } else {
      _add(p);
    }
    _scan.clear();
    _scanFocus.requestFocus();
  }

  Future<void> _pick() async {
    final p = await pickProduct(context, title: 'Добавить в приход');
    if (p != null) _add(p);
  }

  void _remove(_Line l) => setState(() {
        _lines.remove(l);
        l.dispose();
      });

  Future<void> _clear() async {
    if (_lines.isEmpty) return;
    final ok = await confirm(context,
        title: 'Очистить документ?', message: 'Все позиции будут удалены из документа.', ok: 'Очистить', destructive: true);
    if (!ok) return;
    setState(() {
      for (final l in _lines) {
        l.dispose();
      }
      _lines.clear();
      _note.clear();
      _supplierId = null;
    });
  }

  int get _total => _lines.fold(0, (s, l) => s + l.total);

  Future<void> _post(List<Supplier> suppliers) async {
    if (_busy) return;
    if (_lines.isEmpty) {
      showError(context, 'Добавьте хотя бы одну позицию');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      showError(context, 'Проверьте выделенные поля');
      return;
    }
    final sup = suppliers.where((s) => s.id == _supplierId).firstOrNull;
    final total = _total;
    final ok = await confirm(context,
        title: 'Провести приход?',
        message: 'Позиций: ${_lines.length}\nСумма: ${Money.format(total)}'
            '${sup != null ? '\n\nДолг перед «${sup.name}» увеличится на ${Money.format(total)}' : ''}',
        ok: 'Провести');
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final canPrices = ref.read(sessionProvider)?.can(Perm.editPrices) ?? false;
    final lines = [
      for (final l in _lines)
        ReceiptLine(product: l.product, qty: l.q!, unitCost: l.c!, newPrice: canPrices ? l.newPrice : null),
    ];
    final done = await runGuarded(
      context,
      () => ref.read(inventoryRepoProvider).postReceipt(
          lines: lines,
          supplierId: _supplierId,
          userId: ref.read(sessionProvider)?.user.id,
          note: _note.text,
          canEditPrices: canPrices),
      success: 'Приход проведён: ${lines.length} поз. на ${Money.format(total)}',
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (done) {
        for (final l in _lines) {
          l.dispose();
        }
        _lines.clear();
        _note.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final session = ref.watch(sessionProvider);
    final canPrices = session?.can(Perm.editPrices) ?? false;
    final suppliers = ref.watch(invSuppliersProvider).value ?? const <Supplier>[];
    final header = LayoutBuilder(builder: (context, c) {
      final narrow = c.maxWidth < 700;
      final sup = DropdownButtonFormField<String?>(
        key: ValueKey('sup$_supplierId${suppliers.length}'),
        initialValue: suppliers.any((s) => s.id == _supplierId) ? _supplierId : null,
        isExpanded: true,
        decoration: const InputDecoration(
            labelText: 'Поставщик', helperText: 'Если указан, сумма прихода добавится к долгу поставщику'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Без поставщика')),
          for (final s in suppliers) DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => setState(() => _supplierId = v),
      );
      final note = TextField(
          controller: _note, decoration: const InputDecoration(labelText: 'Комментарий (накладная №, дата…)'));
      final scan = TextField(
        controller: _scan,
        focusNode: _scanFocus,
        autofocus: true,
        decoration: const InputDecoration(
            labelText: 'Сканируйте штрихкод или введите артикул',
            prefixIcon: Icon(Icons.qr_code_scanner)),
        onSubmitted: _onScan,
      );
      final pick = FilledButton.tonalIcon(onPressed: _pick, icon: const Icon(Icons.add), label: const Text('Добавить товар'));
      if (narrow) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          sup,
          const SizedBox(height: Gap.s),
          note,
          const SizedBox(height: Gap.m),
          scan,
          const SizedBox(height: Gap.s),
          pick,
        ]);
      }
      return Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: sup),
          const SizedBox(width: Gap.m),
          Expanded(child: note),
        ]),
        const SizedBox(height: Gap.m),
        Row(children: [Expanded(child: scan), const SizedBox(width: Gap.m), pick]),
      ]);
    });

    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: ListView(children: [
            header,
            const SizedBox(height: Gap.l),
            if (_lines.isEmpty)
              const EmptyState(
                  icon: Icons.move_to_inbox_outlined,
                  title: 'Документ пуст',
                  message: 'Отсканируйте товар или нажмите «Добавить товар». '
                      'Для приёмки по заказу поставщику используйте раздел «Закупки».')
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
          ]),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(top: Gap.m),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Gap.m,
            runSpacing: Gap.s,
            children: [
              Text('Итого: ${Money.format(_total)}  ·  позиций ${_lines.length}',
                  style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Wrap(spacing: Gap.s, children: [
                OutlinedButton(onPressed: _lines.isEmpty || _busy ? null : _clear, child: const Text('Очистить')),
                FilledButton.icon(
                  onPressed: _lines.isEmpty || _busy ? null : () => _post(suppliers),
                  icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: const Text('Провести приход'),
                ),
              ]),
            ],
          ),
        ),
      ]),
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
    final p = line.product;
    final qty = TextFormField(
      controller: line.qty,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: 'Кол-во', suffixText: Qty.unitLabel(p.unit)),
      onChanged: (_) => onChanged(),
      validator: (v) => validateQty(QtyField.parse(v ?? ''), p.unit),
    );
    final cost = TextFormField(
      controller: line.cost,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: 'Цена закупки', suffixText: Money.currency.symbol),
      onChanged: (_) => onChanged(),
      validator: (v) {
        if ((v ?? '').trim().isEmpty) return 'Укажите цену закупки';
        final m = Money.parse(v!);
        if (m == null) return 'Неверная сумма';
        if (m < 0) return 'Не может быть отрицательной';
        return null;
      },
    );
    final price = TextFormField(
      controller: line.price,
      enabled: canPrices,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
          labelText: 'Новая розн. цена',
          hintText: Money.toInput(p.price),
          suffixText: Money.currency.symbol,
          helperText: canPrices ? null : 'Нет права менять цены'),
      onChanged: (_) => onChanged(),
      validator: (v) {
        if ((v ?? '').trim().isEmpty) return null;
        final m = Money.parse(v!);
        if (m == null || m <= 0) return 'Неверная цена';
        return null;
      },
    );
    final margin = line.c != null && line.c! > 0 ? ((line.newPrice ?? p.price) - line.c!) * 100 / line.c! : null;
    final total = Text(Money.format(line.total), style: const TextStyle(fontWeight: FontWeight.w700));
    final remove = IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline), tooltip: 'Удалить строку');
    final title = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$index. ${p.name}', maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.bodyLarge),
      Text(
          'Остаток ${Qty.format(p.stockQty, p.unit)} · розн. ${Money.format(p.price)}'
          '${margin != null ? ' · наценка ${margin.toStringAsFixed(0)}%' : ''}',
          style: t.textTheme.bodySmall?.copyWith(
              color: margin != null && margin < 0 ? AppColors.danger : t.colorScheme.onSurfaceVariant)),
    ]);
    return Card(
      margin: const EdgeInsets.only(bottom: Gap.s),
      child: Padding(
        padding: const EdgeInsets.all(Gap.m),
        child: LayoutBuilder(builder: (context, c) {
          if (c.maxWidth >= 900) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 4, child: title),
              const SizedBox(width: Gap.m),
              SizedBox(width: 120, child: qty),
              const SizedBox(width: Gap.m),
              SizedBox(width: 150, child: cost),
              const SizedBox(width: Gap.m),
              SizedBox(width: 160, child: price),
              const SizedBox(width: Gap.m),
              SizedBox(width: 130, child: Padding(padding: const EdgeInsets.only(top: 14), child: Align(alignment: Alignment.centerRight, child: total))),
              remove,
            ]);
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [Expanded(child: title), remove]),
            const SizedBox(height: Gap.s),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: qty),
              const SizedBox(width: Gap.s),
              Expanded(child: cost),
            ]),
            const SizedBox(height: Gap.s),
            Row(children: [Expanded(child: price), const SizedBox(width: Gap.m), total]),
          ]);
        }),
      ),
    );
  }
}
