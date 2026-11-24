import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/pickers.dart';
import '../../core/widgets/widgets.dart';
import 'marketing_repo.dart';
import 'promotion_logic.dart';

Future<String?> showPromotionEditor(BuildContext context, {Promotion? promotion, bool duplicate = false}) {
  return showFormDialog<String>(context,
      title: promotion == null || duplicate ? 'Новая акция' : 'Редактирование акции',
      width: 640,
      child: PromotionEditor(promotion: promotion, duplicate: duplicate));
}

class PromotionEditor extends ConsumerStatefulWidget {
  const PromotionEditor({super.key, this.promotion, this.duplicate = false});
  final Promotion? promotion;
  final bool duplicate;

  @override
  ConsumerState<PromotionEditor> createState() => _PromotionEditorState();
}

class _PromotionEditorState extends ConsumerState<PromotionEditor> {
  final _form = GlobalKey<FormState>();
  late final PromoDraft d = () {
    final p = widget.promotion;
    if (p == null) return PromoDraft();
    final draft = PromoDraft.from(p);
    if (widget.duplicate) {
      draft
        ..id = null
        ..name = '${p.name} (копия)'
        ..code = null
        ..isActive = false;
    }
    return draft;
  }();
  late final _name = TextEditingController(text: d.name);
  late final _percent = TextEditingController(text: d.percent == null ? '' : _fmt(d.percent!));
  late final _amount = TextEditingController(text: d.amount == null ? '' : Money.toInput(d.amount!));
  late final _minOrder = TextEditingController(text: d.minOrderTotal == 0 ? '' : Money.toInput(d.minOrderTotal));
  late final _code = TextEditingController(text: d.code);
  late final _buy = TextEditingController(text: '${d.buyQty}');
  late final _get = TextEditingController(text: '${d.getQty}');
  String? _productName;
  String? _error;
  bool _saving = false;

  static String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';

  @override
  void initState() {
    super.initState();
    if (d.targetId != null && d.type != 'percent_category') _loadProductName(d.targetId!);
  }

  Future<void> _loadProductName(String id) async {
    final db = ref.read(databaseProvider);
    final p = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (mounted) setState(() => _productName = p?.name ?? 'Товар удалён');
  }

  @override
  void dispose() {
    for (final c in [_name, _percent, _amount, _minOrder, _code, _buy, _get]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setType(String t) {
    setState(() {
      final wasCategory = d.type == 'percent_category';
      final isCategory = t == 'percent_category';
      if (wasCategory != isCategory) {
        d.targetId = null;
        _productName = null;
      }
      d.type = t;
      _error = null;
    });
  }

  void _collect() {
    d
      ..name = _name.text
      ..percent = double.tryParse(_percent.text.trim().replaceAll(',', '.'))
      ..amount = Money.parse(_amount.text)
      ..minOrderTotal = Money.parse(_minOrder.text) ?? 0
      ..code = normalizePromoCode(_code.text)
      ..buyQty = int.tryParse(_buy.text.trim()) ?? 0
      ..getQty = int.tryParse(_get.text.trim()) ?? 0;
  }

  Future<void> _save() async {
    // Guard before any await so a double Enter cannot create two promotions.
    if (_saving) return;
    _form.currentState!.validate();
    _collect();
    // Fast synchronous check for an immediate message; code uniqueness and
    // the full validation are re-checked by the repo inside a transaction.
    final err = validatePromo(d);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(marketingRepoProvider);
    try {
      final id = await repo.savePromotion(d, userId: ref.read(sessionProvider)!.user.id);
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = errorText(e);
        });
      }
    }
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final initial = (start ? d.startDay : d.endDay) ?? (start ? now : (d.startDay ?? now).add(const Duration(days: 7)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      helpText: start ? 'Дата начала' : 'Последний день акции',
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        d.startDay = picked;
      } else {
        d.endDay = picked;
      }
      _error = null;
    });
  }

  Future<void> _pickProduct() async {
    final p = await pickProduct(context, title: 'Товар для акции');
    if (p == null) return;
    setState(() {
      d.targetId = p.id;
      _productName = p.name;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final status = promoStatus(isActive: d.isActive, startsAt: d.startsAt, endsAt: d.endsAt, now: DateTime.now());
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
      },
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.m, Gap.xl, Gap.m),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Название *', hintText: 'Например: Скидка выходного дня'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Введите название' : null,
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: Gap.m),
                DropdownButtonFormField<String>(
                  initialValue: d.type,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Тип акции'),
                  items: [
                    for (final ty in promoTypes) DropdownMenuItem(value: ty, child: Text(promoTypeLabel(ty))),
                  ],
                  onChanged: (v) => _setType(v!),
                ),
                const SizedBox(height: Gap.s),
                Container(
                  padding: const EdgeInsets.all(Gap.m),
                  decoration: BoxDecoration(
                    color: t.colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline, size: 18, color: t.colorScheme.primary),
                    const SizedBox(width: Gap.s),
                    Expanded(child: Text(promoTypeHelp(d.type), style: t.textTheme.bodySmall)),
                  ]),
                ),
                const SizedBox(height: Gap.m),
                ..._typeFields(t),
                const SizedBox(height: Gap.m),
                Text('Период действия', style: t.textTheme.labelLarge),
                const SizedBox(height: Gap.s),
                _pair(
                  _dateBox('С', d.startDay, () => _pickDate(true), () => setState(() => d.startDay = null)),
                  _dateBox('По (включительно)', d.endDay, () => _pickDate(false), () => setState(() => d.endDay = null)),
                ),
                const SizedBox(height: Gap.s),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: d.isActive,
                  title: const Text('Акция включена'),
                  subtitle: Text('Статус: ${status.label}'),
                  onChanged: (v) => setState(() => d.isActive = v),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Gap.s),
                    child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                  ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.l),
            // OverflowBar stacks the buttons instead of overflowing at 360px.
            child: OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: Gap.s,
                overflowSpacing: Gap.s,
                overflowAlignment: OverflowBarAlignment.end,
                children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(d.id == null ? 'Создать' : 'Сохранить'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  /// Two fields side by side on wide dialogs, stacked on phones.
  Widget _pair(Widget a, Widget b) => MediaQuery.sizeOf(context).width >= 560
      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: a),
          const SizedBox(width: Gap.m),
          Expanded(child: b),
        ])
      : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: Gap.m), b]);

  Widget _dateBox(String label, DateTime? value, VoidCallback onTap, VoidCallback onClear) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: value == null
                ? const Icon(Icons.calendar_month)
                : IconButton(tooltip: 'Очистить', icon: const Icon(Icons.close), onPressed: onClear),
          ),
          child: Text(value == null ? 'не ограничено' : formatDate(value)),
        ),
      );

  List<Widget> _typeFields(ThemeData t) {
    final fields = <Widget>[];
    final type = d.type;

    if (type == 'promo_code') {
      fields.addAll([
        TextFormField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            // Deny whitespace with the stock formatter (it keeps the selection
            // valid); a custom replaceAll changed the length and crashed.
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
            TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
          ],
          decoration: const InputDecoration(labelText: 'Промокод *', hintText: 'SALE10', prefixIcon: Icon(Icons.local_offer_outlined)),
          validator: (v) => (v ?? '').trim().length < 3 ? 'Минимум 3 символа' : null,
          onFieldSubmitted: (_) => _save(),
        ),
        const SizedBox(height: Gap.m),
        Wrap(spacing: Gap.m, runSpacing: Gap.s, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('Скидка:', style: t.textTheme.bodyMedium),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              const ButtonSegment(value: true, label: Text('%')),
              ButtonSegment(value: false, label: Text('сумма, ${Money.currency.symbol}')),
            ],
            selected: {d.percentMode},
            onSelectionChanged: (s) => setState(() => d.percentMode = s.first),
          ),
        ]),
        const SizedBox(height: Gap.m),
      ]);
    }

    if (promoTypeHasTarget(type)) {
      if (type == 'percent_category') {
        final cats = ref.watch(categoriesListProvider);
        fields.add(cats.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(errorText(e)),
          data: (list) => list.isEmpty
              ? const Text('Сначала создайте категории в разделе «Товары»', style: TextStyle(color: AppColors.warning))
              : DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: list.any((c) => c.id == d.targetId) ? d.targetId : null,
                  decoration: const InputDecoration(labelText: 'Категория *', prefixIcon: Icon(Icons.category_outlined)),
                  items: [for (final c in list) DropdownMenuItem(value: c.id, child: Text(c.name))],
                  onChanged: (v) => setState(() => d.targetId = v),
                ),
        ));
      } else {
        fields.add(InkWell(
          onTap: _pickProduct,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: const InputDecoration(
                labelText: 'Товар *', prefixIcon: Icon(Icons.inventory_2_outlined), suffixIcon: Icon(Icons.search)),
            child: Text(_productName ?? 'Выбрать товар…', overflow: TextOverflow.ellipsis),
          ),
        ));
      }
      fields.add(const SizedBox(height: Gap.m));
    }

    if (type == 'buy_x_get_y') {
      final buy = int.tryParse(_buy.text) ?? 0;
      final get = int.tryParse(_get.text) ?? 0;
      fields.addAll([
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _buy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Купи (шт.)'),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Минимум 1' : null,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: Gap.m),
          Expanded(
            child: TextFormField(
              controller: _get,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Получи бесплатно (шт.)'),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Минимум 1' : null,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ]),
        if (buy > 0 && get > 0)
          Padding(
            padding: const EdgeInsets.only(top: Gap.s),
            child: Text('В чеке из ${buy + get} шт. — $get шт. бесплатно',
                style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ),
      ]);
      return fields;
    }

    final usesPercent = type == 'promo_code' ? d.percentMode : promoTypeIsPercent(type);
    final valueField = usesPercent
        ? TextFormField(
            controller: _percent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: const InputDecoration(labelText: 'Скидка *', suffixText: '%'),
            validator: (v) {
              final p = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
              if (p == null) return 'Введите процент';
              if (p <= 0 || p > 100) return 'Больше 0 и не больше 100';
              return null;
            },
            onFieldSubmitted: (_) => _save(),
          )
        : MoneyField(
            key: const ValueKey('amount'),
            label: 'Сумма скидки *',
            controller: _amount,
            required: true,
            allowZero: false,
            onSubmitted: (_) => _save(),
          );
    if (promoTypeHasMinOrder(type)) {
      fields.add(_pair(
        valueField,
        MoneyField(
          label: 'Мин. сумма чека',
          controller: _minOrder,
          helper: 'Пусто — без ограничения',
          onSubmitted: (_) => _save(),
        ),
      ));
    } else {
      fields.add(valueField);
    }
    return fields;
  }
}
