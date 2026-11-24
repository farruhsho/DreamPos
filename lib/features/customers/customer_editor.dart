import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'customer_logic.dart';
import 'customer_repo.dart';

/// Opens the create/edit dialog. Returns the saved customer id.
Future<String?> showCustomerEditor(BuildContext context, {Customer? customer}) =>
    showFormDialog<String>(context,
        title: customer == null ? 'Новый клиент' : 'Редактирование клиента',
        width: 620,
        child: CustomerEditor(customer: customer));

class CustomerEditor extends ConsumerStatefulWidget {
  const CustomerEditor({super.key, this.customer});
  final Customer? customer;

  @override
  ConsumerState<CustomerEditor> createState() => _CustomerEditorState();
}

class _CustomerEditorState extends ConsumerState<CustomerEditor> {
  final _form = GlobalKey<FormState>();
  late final Customer? c = widget.customer;
  late final _name = TextEditingController(text: c?.name);
  late final _phone = TextEditingController(text: c?.phone);
  late final _email = TextEditingController(text: c?.email);
  late final _card = TextEditingController(text: c?.cardNumber);
  late final _discount =
      TextEditingController(text: c == null || c!.discountPercent == 0 ? '' : _exactPercent(c!.discountPercent));
  late final _debtLimit = TextEditingController(text: c == null ? '' : Money.toInput(c!.debtLimit));
  late final _tags = TextEditingController(text: c?.tags);
  late final _note = TextEditingController(text: c?.note);
  late DateTime? _birthday = c?.birthday;
  final _phoneFocus = FocusNode();
  List<Customer> _dupes = const [];
  String? _cardError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus) _onPhoneDone();
    });
  }

  @override
  void dispose() {
    for (final t in [_name, _phone, _email, _card, _discount, _debtLimit, _tags, _note]) {
      t.dispose();
    }
    _phoneFocus.dispose();
    super.dispose();
  }

  /// Shows the stored percent without rounding (formatPercent rounds to one
  /// decimal, which would silently change e.g. 12.25% on save).
  static String _exactPercent(double p) {
    var s = p.toStringAsFixed(4);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s.replaceAll('.', ',');
  }

  Future<void> _onPhoneDone() async {
    if (!mounted) return;
    final raw = _phone.text;
    if (raw.trim().isEmpty) {
      if (_dupes.isNotEmpty) setState(() => _dupes = const []);
      return;
    }
    final n = normalizePhone(raw);
    if (n != raw) _phone.text = n;
    final d = await ref.read(customerRepoProvider).phoneDuplicates(n, exceptId: c?.id);
    if (mounted) setState(() => _dupes = d);
  }

  Future<void> _generateCard() async {
    try {
      final code = await ref.read(customerRepoProvider).generateUniqueCard();
      if (!mounted) return;
      setState(() {
        _card.text = code;
        _cardError = null;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      initialDatePickerMode: _birthday == null ? DatePickerMode.year : DatePickerMode.day,
      helpText: 'День рождения',
    );
    if (d != null) setState(() => _birthday = d);
  }

  double? _parsePercent(String s) =>
      s.trim().isEmpty ? 0 : double.tryParse(s.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    // Guard is taken before the first await: a double Enter / double click
    // must not create the customer twice.
    if (_saving) return;
    setState(() {
      _cardError = null;
      _saving = true;
    });
    void release() {
      if (mounted) setState(() => _saving = false);
    }

    if (!_form.currentState!.validate()) return release();
    final session = ref.read(sessionProvider)!;
    final repo = ref.read(customerRepoProvider);
    final card = _card.text.trim();
    try {
      if (card.isNotEmpty && await repo.isCardTaken(card, exceptId: c?.id)) {
        if (mounted) setState(() => _cardError = 'Эта карта уже привязана к другому клиенту');
        return release();
      }
      await _onPhoneDone();
    } catch (e) {
      if (mounted) showError(context, e);
      return release();
    }
    if (!mounted) return;
    if (_dupes.isNotEmpty) {
      final ok = await confirm(context,
          title: 'Телефон уже используется',
          message: 'Номер ${_phone.text} уже есть у клиента «${_dupes.first.name}». '
              'Сохранить ещё одного клиента с этим номером?',
          ok: 'Сохранить');
      if (!ok || !mounted) return release();
    }
    try {
      final id = await repo.save(
        CustomerDraft(
          id: c?.id,
          name: _name.text,
          phone: _phone.text,
          email: _email.text,
          cardNumber: card,
          birthday: _birthday,
          discountPercent: _parsePercent(_discount.text) ?? 0,
          debtLimit: Money.parse(_debtLimit.text) ?? 0,
          tags: parseTags(_tags.text),
          note: _note.text,
        ),
        userId: session.user.id,
        canEditDiscount: session.can(Perm.editCustomers),
        canEditDebtLimit: session.can(Perm.manageDebts),
      );
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showError(context, e);
      }
    }
  }

  Widget _tip(bool show, String message, Widget child) =>
      show ? Tooltip(message: message, child: child) : child;

  void _addTag(String tag) {
    final tags = parseTags(_tags.text);
    if (tags.contains(tag)) return;
    _tags.text = joinTags([...tags, tag]) ?? '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider)!;
    final canDiscount = session.can(Perm.editCustomers);
    final canDebt = session.can(Perm.manageDebts);
    final existingTags = allTags(ref.watch(customersListProvider).value ?? const []);
    final currentTags = parseTags(_tags.text);
    final wide = MediaQuery.sizeOf(context).width >= 560;

    Widget pair(Widget a, Widget b) => wide
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: a),
            const SizedBox(width: Gap.m),
            Expanded(child: b),
          ])
        : Column(children: [a, const SizedBox(height: Gap.m), b]);

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
                  textCapitalization: TextCapitalization.words,
                  maxLength: 160,
                  decoration: const InputDecoration(
                      labelText: 'Имя *', counterText: '', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Введите имя клиента' : null,
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: Gap.m),
                pair(
                  TextFormField(
                    controller: _phone,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-\s]'))],
                    decoration: InputDecoration(
                      labelText: 'Телефон',
                      hintText: '+998 90 123 45 67',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      helperText: _dupes.isEmpty ? null : 'Уже есть: ${_dupes.map((d) => d.name).join(', ')}',
                      helperStyle: const TextStyle(color: AppColors.warning),
                    ),
                    validator: (v) {
                      final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      if (d.isNotEmpty && d.length < 7) return 'Слишком короткий номер';
                      if (d.length > 15) return 'Слишком длинный номер';
                      return null;
                    },
                    onFieldSubmitted: (_) => _save(),
                  ),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email)),
                    validator: (v) =>
                        (v ?? '').trim().isNotEmpty && !isValidEmail(v!) ? 'Неверный формат email' : null,
                    onFieldSubmitted: (_) => _save(),
                  ),
                ),
                const SizedBox(height: Gap.m),
                pair(
                  TextFormField(
                    controller: _card,
                    decoration: InputDecoration(
                      labelText: 'Номер карты',
                      prefixIcon: const Icon(Icons.credit_card),
                      errorText: _cardError,
                      suffixIcon: TextButton(onPressed: _generateCard, child: const Text('Сгенерировать')),
                    ),
                    onChanged: (_) {
                      if (_cardError != null) setState(() => _cardError = null);
                    },
                    onFieldSubmitted: (_) => _save(),
                  ),
                  InkWell(
                    onTap: _pickBirthday,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'День рождения',
                        prefixIcon: const Icon(Icons.cake_outlined),
                        suffixIcon: _birthday == null
                            ? const Icon(Icons.calendar_month)
                            : IconButton(
                                tooltip: 'Очистить',
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() => _birthday = null)),
                      ),
                      child: Text(_birthday == null ? 'Не указан' : formatDate(_birthday!)),
                    ),
                  ),
                ),
                const SizedBox(height: Gap.m),
                pair(
                  _tip(!canDiscount, 'Нет права изменять скидку',
                    TextFormField(
                      controller: _discount,
                      enabled: canDiscount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      decoration: const InputDecoration(
                          labelText: 'Персональная скидка',
                          suffixText: '%',
                          prefixIcon: Icon(Icons.percent),
                          helperText: 'Не суммируется с акциями: берётся лучшая'),
                      validator: (v) {
                        final p = _parsePercent(v ?? '');
                        if (p == null) return 'Введите число';
                        if (p < 0 || p > 100) return 'От 0 до 100%';
                        return null;
                      },
                      onFieldSubmitted: (_) => _save(),
                    ),
                  ),
                  _tip(!canDebt, 'Нет права управлять долгами',
                    canDebt
                        ? MoneyField(
                            label: 'Лимит долга',
                            controller: _debtLimit,
                            helper: '0 — продажа в долг запрещена',
                            onSubmitted: (_) => _save(),
                          )
                        : InputDecorator(
                            decoration: const InputDecoration(
                                labelText: 'Лимит долга', enabled: false, helperText: 'Только для менеджера'),
                            child: Text(Money.format(c?.debtLimit ?? 0)),
                          ),
                  ),
                ),
                const SizedBox(height: Gap.m),
                TextFormField(
                  controller: _tags,
                  decoration: const InputDecoration(
                      labelText: 'Теги',
                      helperText: 'Через запятую, например: опт, постоянный',
                      prefixIcon: Icon(Icons.sell_outlined)),
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _save(),
                ),
                if (existingTags.any((t) => !currentTags.contains(t))) ...[
                  const SizedBox(height: Gap.s),
                  Wrap(spacing: Gap.xs, runSpacing: Gap.xs, children: [
                    for (final t in existingTags.where((t) => !currentTags.contains(t)).take(12))
                      ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: Text(t),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _addTag(t)),
                  ]),
                ],
                const SizedBox(height: Gap.m),
                TextFormField(
                  controller: _note,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Заметка', alignLabelWithHint: true),
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
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(c == null ? 'Создать' : 'Сохранить'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
