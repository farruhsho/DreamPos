import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'categories_dialog.dart';
import 'product_logic.dart';
import 'product_widgets.dart';
import 'products_repo.dart';

/// Opens the product editor: dialog on wide screens, full page on phones.
/// [product] edits an existing product; [copyOf] pre-fills a new one.
/// Returns the saved product id or null when cancelled.
Future<String?> openProductEditor(BuildContext context,
    {Product? product, Product? copyOf, String? categoryId, String? barcode}) {
  final editor =
      ProductEditor(product: product, copyOf: copyOf, categoryId: categoryId, initialBarcode: barcode);
  if (context.isCompact || MediaQuery.sizeOf(context).height < 560) {
    return Navigator.of(context).push<String>(
        MaterialPageRoute(fullscreenDialog: true, builder: (_) => editor));
  }
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (c) => Dialog(
      insetPadding: const EdgeInsets.all(Gap.l),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 820, maxHeight: MediaQuery.sizeOf(c).height * 0.92),
        child: editor,
      ),
    ),
  );
}

class ProductEditor extends ConsumerStatefulWidget {
  const ProductEditor({super.key, this.product, this.copyOf, this.categoryId, this.initialBarcode});
  final Product? product;
  final Product? copyOf;
  final String? categoryId;
  /// Pre-filled barcode for a new product (e.g. scanned but not found).
  final String? initialBarcode;

  @override
  ConsumerState<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends ConsumerState<ProductEditor> {
  final _form = GlobalKey<FormState>();
  late final ProductDraft d;
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _barcode;
  late final TextEditingController _sku;
  late final TextEditingController _minStock;
  late final TextEditingController _initStock;
  late final TextEditingController _warranty;
  late final TextEditingController _vatOther;
  String? _barcodeError;
  String? _skuHint;
  bool _dirty = false;
  bool _saving = false;

  bool get _isNew => widget.product == null;

  @override
  void initState() {
    super.initState();
    final src = widget.product ?? widget.copyOf;
    d = src == null ? ProductDraft(categoryId: widget.categoryId) : ProductDraft.fromProduct(src);
    if (widget.copyOf != null) {
      d
        ..name = '${widget.copyOf!.name} (копия)'
        ..barcode = null
        ..sku = null
        ..isActive = true;
    }
    if (_isNew && widget.initialBarcode != null) d.barcode = widget.initialBarcode;
    _name = TextEditingController(text: d.name);
    _desc = TextEditingController(text: d.description ?? '');
    _barcode = TextEditingController(text: d.barcode ?? '');
    _sku = TextEditingController(text: d.sku ?? '');
    _minStock = TextEditingController(text: Qty.format(d.minStock));
    _initStock = TextEditingController(text: '0');
    _warranty = TextEditingController(text: d.warrantyMonths.toString());
    _vatOther = TextEditingController(
        text: vatPresets.contains(d.vatPercent) ? '' : formatPercent(d.vatPercent).replaceAll('%', ''));
    if (_isNew) {
      ref.read(productsRepoProvider).suggestSku().then((s) {
        if (mounted) setState(() => _skuHint = s);
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _barcode, _sku, _minStock, _initStock, _warranty, _vatOther]) {
      c.dispose();
    }
    super.dispose();
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _generateBarcode() async {
    if (_barcode.text.trim().isNotEmpty) {
      final ok = await confirm(context,
          title: 'Заменить штрихкод?',
          message: 'Текущий штрихкод ${_barcode.text.trim()} будет заменён внутренним. '
              'Старые этикетки перестанут сканироваться.',
          ok: 'Заменить');
      if (!ok) return;
    }
    final code = await ref.read(productsRepoProvider).nextInternalBarcode();
    if (!mounted) return;
    setState(() {
      _barcode.text = code;
      _barcodeError = null;
      _dirty = true;
    });
  }

  Future<void> _addCategory() async {
    final id = await showCategoryEditDialog(context);
    if (id != null && mounted) {
      setState(() {
        d.categoryId = id;
        _dirty = true;
      });
    }
  }

  Future<void> _close() async {
    if (_dirty) {
      final ok = await confirm(context,
          title: 'Закрыть без сохранения?',
          message: 'Внесённые изменения будут потеряны.',
          ok: 'Закрыть',
          destructive: true);
      if (!ok) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    // Guard the whole flow (barcode check + confirmations), not just the
    // write: a second Ctrl+S/Enter while awaiting would create a duplicate.
    if (_saving) return;
    _saving = true;
    try {
      final saved = await _doSave();
      if (!saved && mounted) setState(() => _saving = false);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showError(context, e);
      }
    }
  }

  /// Returns true when the product was saved and the editor closed.
  Future<bool> _doSave() async {
    setState(() => _barcodeError = null);
    if (!_form.currentState!.validate()) {
      showError(context, 'Проверьте выделенные поля');
      return false;
    }
    final session = ref.read(sessionProvider);
    if (session == null) return false;
    final repo = ref.read(productsRepoProvider);
    d
      ..name = _name.text.trim()
      ..description = _desc.text
      ..barcode = _barcode.text.trim()
      ..sku = _sku.text.trim()
      ..minStock = parseDecimal(_minStock.text) ?? 0
      ..initialStock = _isNew ? (parseDecimal(_initStock.text) ?? 0) : 0
      ..warrantyMonths = int.tryParse(_warranty.text.trim()) ?? 0;

    final bc = d.barcode!;
    if (bc.isNotEmpty) {
      final owner = await repo.barcodeOwner(bc, excludeId: widget.product?.id);
      if (owner != null) {
        if (!mounted) return false;
        setState(() => _barcodeError = 'Уже используется: «${owner.name}»');
        showError(context, 'Штрихкод $bc уже присвоен товару «${owner.name}»');
        return false;
      }
    }
    if (!mounted) return false;
    final priceTouched = _isNew || d.price != widget.product!.price || d.costPrice != widget.product!.costPrice;
    if (priceTouched && session.can(Perm.viewCost) && d.costPrice > 0 && d.price < d.costPrice) {
      final ok = await confirm(context,
          title: 'Цена ниже себестоимости',
          message: 'Цена ${Money.format(d.price)} меньше себестоимости ${Money.format(d.costPrice)}. '
              'Каждая продажа будет убыточной. Сохранить?',
          ok: 'Сохранить');
      if (!ok || !mounted) return false;
    }
    if (priceTouched && d.price == 0) {
      final ok = await confirm(context,
          title: 'Нулевая цена',
          message: 'Товар будет продаваться бесплатно. Продолжить?',
          ok: 'Сохранить');
      if (!ok || !mounted) return false;
    }
    setState(() {}); // shows the progress indicator on the save button
    final id = await repo.saveProduct(d,
        existing: widget.product,
        userId: session.user.id,
        canEditPrices: _isNew || session.can(Perm.editPrices));
    if (!mounted) return true;
    showSuccess(context, _isNew ? 'Товар «${d.name}» создан' : 'Изменения сохранены');
    Navigator.of(context).pop(id);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();
    ref.watch(settingsProvider); // keeps Money.currency fresh
    final canPrice = _isNew || session.can(Perm.editPrices);
    final canCost = session.can(Perm.viewCost);
    final compact = context.isCompact;
    final title = _isNew ? (widget.copyOf != null ? 'Копия товара' : 'Новый товар') : 'Редактирование товара';

    final body = Form(
      key: _form,
      onChanged: _touch,
      child: ListView(
        padding: EdgeInsets.fromLTRB(compact ? Gap.l : Gap.xl, Gap.s, compact ? Gap.l : Gap.xl, Gap.l),
        children: [
          _basicSection(),
          _pricesSection(canPrice, canCost),
          _codesSection(),
          _stockSection(),
          _extraSection(),
        ],
      ),
    );

    final saveBtn = FilledButton.icon(
      onPressed: _saving ? null : _save,
      icon: _saving
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.check),
      label: Text(_isNew ? 'Создать товар' : 'Сохранить'),
    );

    final content = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.escape): _close,
      },
      child: PopScope(
        canPop: !_dirty,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: compact
            ? Scaffold(
                appBar: AppBar(
                  leading: IconButton(icon: const Icon(Icons.close), tooltip: 'Закрыть', onPressed: _close),
                  title: Text(title),
                ),
                body: body,
                bottomNavigationBar: SafeArea(
                  child: Padding(padding: const EdgeInsets.all(Gap.m), child: saveBtn),
                ),
              )
            : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.l, Gap.s, Gap.s),
                  child: Row(children: [
                    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
                    IconButton(onPressed: _close, icon: const Icon(Icons.close), tooltip: 'Закрыть (Esc)'),
                  ]),
                ),
                Flexible(child: body),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.xl, vertical: Gap.m),
                  child: Row(children: [
                    Expanded(
                      child: Text('Ctrl+S — сохранить, Esc — закрыть',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                    TextButton(onPressed: _close, child: const Text('Отмена')),
                    const SizedBox(width: Gap.s),
                    saveBtn,
                  ]),
                ),
              ]),
      ),
    );
    return FocusScope(autofocus: true, child: content);
  }

  // ---------------------------------------------------------------- sections

  Widget _basicSection() {
    final cats = ref.watch(productCategoriesProvider).value ?? const <Category>[];
    final hasCat = d.categoryId == null || cats.any((c) => c.id == d.categoryId);
    return FormSection(title: 'Основное', icon: Icons.inventory_2_outlined, children: [
      TextFormField(
        controller: _name,
        autofocus: true,
        maxLength: 200,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Название *', counterText: ''),
        validator: (v) => (v ?? '').trim().isEmpty ? 'Введите название товара' : null,
        onFieldSubmitted: (_) => _save(),
      ),
      FieldRow(children: [
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              key: ValueKey('cat-${d.categoryId}-${cats.length}'),
              initialValue: hasCat ? d.categoryId : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Категория'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Без категории')),
                for (final c in cats)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(children: [
                      CategoryDot(color: c.color),
                      const SizedBox(width: Gap.s),
                      Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                    ]),
                  ),
              ],
              onChanged: (v) => setState(() {
                d.categoryId = v;
                _dirty = true;
              }),
            ),
          ),
          IconButton(
              tooltip: 'Новая категория', onPressed: _addCategory, icon: const Icon(Icons.add_circle_outline)),
        ]),
        DropdownButtonFormField<String>(
          initialValue: d.unit,
          decoration: InputDecoration(
            labelText: 'Единица измерения',
            helperText: Qty.isFractional(d.unit) ? 'Дробное количество (весовой товар)' : null,
          ),
          items: [
            for (final u in Qty.units) DropdownMenuItem(value: u, child: Text(_unitName(u))),
          ],
          onChanged: (v) => setState(() {
            d.unit = v ?? 'pcs';
            _dirty = true;
          }),
        ),
      ]),
      TextFormField(
        controller: _desc,
        minLines: 1,
        maxLines: 4,
        decoration: const InputDecoration(labelText: 'Описание'),
      ),
      Wrap(spacing: Gap.l, runSpacing: Gap.s, children: [
        _switch('Активен (продаётся)', d.isActive, (v) => d.isActive = v),
        _switch('Избранное на кассе', d.isFavorite, (v) => d.isFavorite = v),
      ]),
    ]);
  }

  Widget _switch(String label, bool value, void Function(bool) set) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
              value: value,
              onChanged: (v) => setState(() {
                    set(v);
                    _dirty = true;
                  })),
          const SizedBox(width: Gap.xs),
          // Flexible: long labels wrap on 360px phones instead of overflowing.
          Flexible(child: Text(label)),
        ],
      );

  Widget _pricesSection(bool canPrice, bool canCost) {
    final t = Theme.of(context);
    final margin = marginPercent(d.price, d.costPrice);
    final markup = markupPercent(d.price, d.costPrice);
    final below = canCost && d.costPrice > 0 && d.price < d.costPrice;
    return FormSection(title: 'Цены', icon: Icons.sell_outlined, children: [
      FieldRow(children: [
        canPrice
            ? MoneyField(
                label: 'Розничная цена *',
                initial: d.price == 0 && _isNew && widget.copyOf == null ? null : d.price,
                required: true,
                onChanged: (v) => setState(() => d.price = v ?? 0),
                onSubmitted: (_) => _save(),
              )
            : ReadOnlyField(
                label: 'Розничная цена',
                value: Money.format(d.price),
                helper: 'Нет права менять цены'),
        if (canCost)
          canPrice
              ? MoneyField(
                  label: 'Себестоимость',
                  // New product: empty like the other price fields, not a bare "0".
                  initial: d.costPrice == 0 && _isNew && widget.copyOf == null ? null : d.costPrice,
                  helper: _isNew ? 'Для начального остатка' : 'Средняя, по приходам',
                  onChanged: (v) => setState(() => d.costPrice = v ?? 0),
                  onSubmitted: (_) => _save(),
                )
              : ReadOnlyField(label: 'Себестоимость', value: Money.format(d.costPrice)),
        canPrice
            ? MoneyField(
                label: 'Оптовая цена',
                initial: d.wholesalePrice,
                onChanged: (v) => setState(() => d.wholesalePrice = v),
                onSubmitted: (_) => _save(),
              )
            : ReadOnlyField(
                label: 'Оптовая цена',
                value: d.wholesalePrice == null ? '—' : Money.format(d.wholesalePrice!)),
      ]),
      if (canCost)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.s + 2),
          decoration: BoxDecoration(
            color: (below ? AppColors.danger : t.colorScheme.primary).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Wrap(spacing: Gap.xl, runSpacing: Gap.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text.rich(TextSpan(children: [
              const TextSpan(text: 'Маржа: '),
              TextSpan(text: formatPercent(margin), style: const TextStyle(fontWeight: FontWeight.w700)),
            ])),
            Text.rich(TextSpan(children: [
              const TextSpan(text: 'Наценка: '),
              TextSpan(text: formatPercent(markup), style: const TextStyle(fontWeight: FontWeight.w700)),
            ])),
            Text.rich(TextSpan(children: [
              const TextSpan(text: 'Прибыль с единицы: '),
              TextSpan(
                  text: Money.format(d.price - d.costPrice),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ])),
            if (below)
              const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                SizedBox(width: Gap.xs),
                Text('Цена ниже себестоимости',
                    style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
              ]),
          ]),
        ),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('НДС (включён в цену)', style: t.textTheme.bodySmall),
        const SizedBox(height: Gap.xs),
        Wrap(spacing: Gap.s, runSpacing: Gap.s, crossAxisAlignment: WrapCrossAlignment.center, children: [
          for (final v in vatPresets)
            ChoiceChip(
              label: Text(v == 0 ? 'Без НДС' : '${v.toStringAsFixed(0)}%'),
              selected: d.vatPercent == v,
              onSelected: !canPrice
                  ? null
                  : (_) => setState(() {
                        d.vatPercent = v;
                        _vatOther.clear();
                        _dirty = true;
                      }),
            ),
          SizedBox(
            width: 110,
            child: TextFormField(
              controller: _vatOther,
              enabled: canPrice,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(
                hintText: 'Другой',
                suffixText: '%',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return null;
                final x = parseDecimal(v);
                if (x == null || x < 0 || x > 100) return '0–100';
                return null;
              },
              onChanged: (v) {
                if (v.trim().isEmpty) {
                  // Cleared custom value: fall back to "без НДС" rather than
                  // keeping an invisible custom rate.
                  if (!vatPresets.contains(d.vatPercent)) setState(() => d.vatPercent = 0);
                  return;
                }
                final x = parseDecimal(v);
                if (x != null && x >= 0 && x <= 100) setState(() => d.vatPercent = x);
              },
            ),
          ),
        ]),
      ]),
    ]);
  }

  Widget _codesSection() {
    final bc = _barcode.text.trim();
    String? bcHelper;
    var bcInvalid = false;
    if (RegExp(r'^\d{13}$').hasMatch(bc)) {
      bcInvalid = !Ean13.isValid(bc);
      bcHelper = !bcInvalid
          ? (bc.startsWith(Ean13.internalPrefix) ? 'Внутренний EAN-13' : 'EAN-13 ✓')
          : 'Неверная контрольная цифра EAN-13';
    }
    return FormSection(title: 'Коды', icon: Icons.qr_code_2, children: [
      FieldRow(children: [
        // Generate sits inside the field as a suffix icon: the 13-digit code
        // keeps the full field width (a text button ate ~150px on phones).
        TextFormField(
          controller: _barcode,
          decoration: InputDecoration(
            labelText: 'Штрихкод',
            hintText: 'Отсканируйте или введите',
            errorText: _barcodeError,
            helperText: bcHelper,
            helperMaxLines: 2,
            helperStyle: bcInvalid
                ? const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w500)
                : null,
            prefixIcon: const Icon(Icons.qr_code_scanner, size: 20),
            suffixIcon: IconButton(
              key: const ValueKey('generate-barcode'),
              tooltip: 'Сгенерировать внутренний EAN-13 (префикс 200)',
              onPressed: _generateBarcode,
              icon: const Icon(Icons.autorenew),
            ),
          ),
          onChanged: (_) => setState(() => _barcodeError = null),
          validator: (v) {
            final s = (v ?? '').trim();
            if (s.length > 64) return 'Слишком длинный штрихкод';
            if (s.contains(' ')) return 'Штрихкод не должен содержать пробелы';
            return null;
          },
          onFieldSubmitted: (_) => _save(),
        ),
        TextFormField(
          controller: _sku,
          decoration: InputDecoration(
            labelText: 'Артикул (SKU)',
            hintText: _skuHint == null ? null : 'Свободный: $_skuHint',
            suffixIcon: _skuHint == null
                ? null
                : IconButton(
                    tooltip: 'Подставить $_skuHint',
                    icon: const Icon(Icons.auto_fix_high, size: 20),
                    onPressed: () => setState(() {
                      _sku.text = _skuHint!;
                      _dirty = true;
                    }),
                  ),
          ),
          onFieldSubmitted: (_) => _save(),
        ),
      ]),
    ]);
  }

  Widget _stockSection() {
    final p = widget.product;
    return FormSection(title: 'Склад', icon: Icons.warehouse_outlined, children: [
      Wrap(spacing: Gap.l, runSpacing: Gap.s, children: [
        _switch('Учитывать остаток', d.trackStock, (v) => d.trackStock = v),
        if (d.trackStock) _switch('Разрешить продажу в минус', d.allowNegativeStock, (v) => d.allowNegativeStock = v),
      ]),
      if (d.trackStock)
        FieldRow(children: [
          TextFormField(
            controller: _minStock,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(
              labelText: 'Минимальный остаток',
              suffixText: Qty.unitLabel(d.unit),
              helperText: 'Ниже — товар помечается «Мало»',
            ),
            validator: (v) {
              final x = parseDecimal((v ?? '').isEmpty ? '0' : v);
              if (x == null || x < 0) return 'Введите число ≥ 0';
              return null;
            },
            onFieldSubmitted: (_) => _save(),
          ),
          if (_isNew)
            TextFormField(
              controller: _initStock,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: InputDecoration(
                labelText: 'Начальный остаток',
                suffixText: Qty.unitLabel(d.unit),
                helperText: 'Оприходуется как «Начальный остаток»',
              ),
              validator: (v) {
                final x = parseDecimal((v ?? '').isEmpty ? '0' : v);
                if (x == null || x < 0) return 'Введите число ≥ 0';
                if (!Qty.isFractional(d.unit) && x != x.roundToDouble()) return 'Только целое число';
                return null;
              },
              onFieldSubmitted: (_) => _save(),
            )
          else
            ReadOnlyField(
              label: 'Текущий остаток',
              value: Qty.format(p!.stockQty, p.unit),
              helper: 'Изменяется в разделе «Склад»: приход, списание, инвентаризация',
            ),
        ]),
    ]);
  }

  Widget _extraSection() {
    final suppliers = ref.watch(productSuppliersProvider).value ?? const <Supplier>[];
    final hasSup = d.supplierId == null || suppliers.any((s) => s.id == d.supplierId);
    return FormSection(title: 'Гарантия и поставщик', icon: Icons.verified_user_outlined, children: [
      FieldRow(children: [
        TextFormField(
          controller: _warranty,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Гарантия',
            suffixText: 'мес.',
            helperText: '0 — без гарантии',
          ),
          validator: (v) {
            final x = int.tryParse((v ?? '').isEmpty ? '0' : v!);
            if (x == null || x < 0 || x > 240) return 'От 0 до 240 месяцев';
            return null;
          },
          onFieldSubmitted: (_) => _save(),
        ),
        DropdownButtonFormField<String?>(
          key: ValueKey('sup-${suppliers.length}'),
          initialValue: hasSup ? d.supplierId : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Поставщик',
            helperText: suppliers.isEmpty ? 'Поставщики добавляются в разделе «Закупки»' : null,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Не указан')),
            for (final s in suppliers)
              DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() {
            d.supplierId = v;
            _dirty = true;
          }),
        ),
      ]),
    ]);
  }
}

String _unitName(String u) => switch (u) {
      'pcs' => 'Штука (шт)',
      'kg' => 'Килограмм (кг)',
      'g' => 'Грамм (г)',
      'l' => 'Литр (л)',
      'm' => 'Метр (м)',
      'pack' => 'Упаковка (уп)',
      _ => u,
    };
