import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'customer_logic.dart';
import 'customer_repo.dart';

/// Opens the create/edit dialog. Returns the saved customer id.
Future<String?> showCustomerEditor(BuildContext context, {Customer? customer}) =>
    showFormDialog<String>(context,
        title: customer == null ? context.l10n.custNew : context.l10n.custEditTitle,
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
      helpText: context.l10n.custBirthday,
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
        if (mounted) setState(() => _cardError = context.l10n.custCardTaken);
        return release();
      }
      await _onPhoneDone();
    } catch (e) {
      if (mounted) showError(context, e);
      return release();
    }
    if (!mounted) return;
    if (_dupes.isNotEmpty) {
      final l = context.l10n;
      final ok = await confirm(context,
          title: l.custPhoneUsedTitle,
          message: l.custPhoneUsedMessage(_phone.text, _dupes.first.name),
          ok: l.commonSave);
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
    final l = context.l10n;

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
                  decoration: InputDecoration(
                      labelText: l.custNameField, counterText: '', prefixIcon: const Icon(Icons.person_outline)),
                  validator: (v) => (v ?? '').trim().isEmpty ? l.custEnterName : null,
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
                      labelText: l.commonPhone,
                      hintText: '+998 90 123 45 67',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      helperText: _dupes.isEmpty ? null : l.custPhoneExists(_dupes.map((d) => d.name).join(', ')),
                      helperStyle: const TextStyle(color: AppColors.warning),
                      helperMaxLines: 2,
                    ),
                    validator: (v) {
                      final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      if (d.isNotEmpty && d.length < 7) return l.custPhoneTooShort;
                      if (d.length > 15) return l.custPhoneTooLong;
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
                        (v ?? '').trim().isNotEmpty && !isValidEmail(v!) ? l.custEmailInvalidFormat : null,
                    onFieldSubmitted: (_) => _save(),
                  ),
                ),
                const SizedBox(height: Gap.m),
                pair(
                  TextFormField(
                    controller: _card,
                    decoration: InputDecoration(
                      labelText: l.custCardNumber,
                      prefixIcon: const Icon(Icons.credit_card),
                      errorText: _cardError,
                      // An icon button: a text button ate half the field and
                      // truncated the label to «Номер кар…» on an empty field.
                      suffixIcon: IconButton(
                        tooltip: l.custGenerateCard,
                        onPressed: _generateCard,
                        icon: const Icon(Icons.autorenew),
                      ),
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
                        labelText: l.custBirthday,
                        prefixIcon: const Icon(Icons.cake_outlined),
                        suffixIcon: _birthday == null
                            ? const Icon(Icons.calendar_month)
                            : IconButton(
                                tooltip: l.commonClear,
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() => _birthday = null)),
                      ),
                      child: Text(_birthday == null ? l.custNotSet : formatDate(_birthday!)),
                    ),
                  ),
                ),
                const SizedBox(height: Gap.m),
                pair(
                  _tip(!canDiscount, l.custNoDiscountPerm,
                    TextFormField(
                      controller: _discount,
                      enabled: canDiscount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      decoration: InputDecoration(
                          labelText: l.custPersonalDiscount,
                          suffixText: '%',
                          prefixIcon: const Icon(Icons.percent),
                          helperText: l.custDiscountHelper,
                          helperMaxLines: 2),
                      validator: (v) {
                        final p = _parsePercent(v ?? '');
                        if (p == null) return l.commonEnterNumber;
                        if (p < 0 || p > 100) return l.custPercentRange;
                        return null;
                      },
                      onFieldSubmitted: (_) => _save(),
                    ),
                  ),
                  _tip(!canDebt, l.custNoDebtPerm,
                    canDebt
                        ? MoneyField(
                            label: l.custDebtLimit,
                            controller: _debtLimit,
                            helper: l.custDebtLimitHelper,
                            onSubmitted: (_) => _save(),
                          )
                        : InputDecorator(
                            decoration: InputDecoration(
                                labelText: l.custDebtLimit, enabled: false, helperText: l.custManagerOnly),
                            child: Text(Money.format(c?.debtLimit ?? 0)),
                          ),
                  ),
                ),
                const SizedBox(height: Gap.m),
                TextFormField(
                  controller: _tags,
                  decoration: InputDecoration(
                      labelText: l.custTags,
                      helperText: l.custTagsHelper,
                      prefixIcon: const Icon(Icons.sell_outlined)),
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
                  decoration: InputDecoration(labelText: l.custNote, alignLabelWithHint: true),
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
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(c == null ? l.commonCreate : l.commonSave),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
