import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'staff_logic.dart';
import 'staff_providers.dart';

/// Create ([user] == null) or edit a staff member. Returns the saved user.
Future<User?> showUserFormDialog(BuildContext context, {User? user}) => showFormDialog<User>(
  context,
  title: user == null ? 'Новый сотрудник' : 'Сотрудник: ${user.name}',
  width: 560,
  child: UserForm(user: user),
);

/// Asks for a new PIN (with confirmation). Returns null if cancelled.
Future<String?> showPinDialog(BuildContext context, {required String title, String? message}) =>
    showFormDialog<String>(
      context,
      title: title,
      width: 420,
      child: _PinForm(message: message),
    );

class UserForm extends ConsumerStatefulWidget {
  const UserForm({super.key, this.user});
  final User? user;

  @override
  ConsumerState<UserForm> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<UserForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user?.name);
  late final _phone = TextEditingController(text: widget.user?.phone);
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  late final _discount = TextEditingController(text: _pct(widget.user?.maxDiscountPercent ?? 0));
  late final _commission = TextEditingController(text: _pct(widget.user?.commissionPercent ?? 0));
  late Role _role = widget.user == null ? Role.cashier : Role.parse(widget.user!.role);
  late int _plan = widget.user?.salesPlan ?? 0;
  late bool _changePin = widget.user == null;
  bool _busy = false;

  bool get _creating => widget.user == null;

  static String _pct(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString().replaceAll('.', ',');

  static double? _parsePct(String s) => s.trim().isEmpty ? 0 : double.tryParse(s.trim().replaceAll(',', '.'));

  @override
  void dispose() {
    for (final c in [_name, _phone, _pin, _pin2, _discount, _commission]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    final actor = ref.read(sessionProvider)?.user;
    if (actor == null) return;
    final input = UserInput(
      name: _name.text,
      role: _role,
      phone: _phone.text,
      pin: _changePin ? _pin.text : null,
      maxDiscountPercent: _parsePct(_discount.text) ?? 0,
      commissionPercent: _parsePct(_commission.text) ?? 0,
      salesPlan: _plan,
    );
    final err = input.validate(creating: _creating);
    if (err != null) {
      showError(context, err);
      return;
    }
    final isMe = widget.user?.id == actor.id;
    if (isMe && _role != Role.parse(widget.user!.role) && !_role.can(Perm.manageStaff)) {
      final ok = await confirm(
        context,
        title: 'Понизить собственную роль?',
        message:
            'После сохранения у вас («${_role.label}») не будет доступа к разделу «Сотрудники». '
            'Вернуть права сможет только владелец или администратор.',
        ok: 'Понизить',
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    setState(() => _busy = true);
    final svc = ref.read(staffServiceProvider);
    User? saved;
    final ok = await runGuarded(context, () async {
      saved = _creating
          ? await svc.create(input, actor: actor)
          : await svc.update(widget.user!.id, input, actor: actor);
    }, success: _creating ? 'Сотрудник добавлен' : 'Изменения сохранены');
    // Editing yourself: keep the live session (name, role, limits) in sync.
    if (mounted && ok && saved != null && saved!.id == ref.read(sessionProvider)?.user.id) {
      ref.read(sessionProvider.notifier).login(saved!);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, saved);
  }

  void _onRole(Role r) {
    setState(() {
      final wasFull = _role == Role.owner || _role == Role.admin;
      final isFull = r == Role.owner || r == Role.admin;
      final d = _parsePct(_discount.text) ?? 0;
      // Owner/admin are not limited by default; going back to a limited role
      // drops the 100% default so a cashier does not inherit it by accident.
      if (isFull && !wasFull && d == 0) _discount.text = '100';
      if (!isFull && wasFull && d == 100) _discount.text = '0';
      _role = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final actorRole = ref.watch(sessionProvider)?.role ?? Role.cashier;
    final users = ref.watch(staffUsersProvider).value ?? const <User>[];
    final roles = Role.values.where((r) => canAssignRole(actorRole, r) || r == _role).toList();
    final ownerGuard = widget.user == null
        ? null
        : lastOwnerGuard(
            users,
            userId: widget.user!.id,
            newRole: Role.cashier,
            newActive: widget.user!.isActive,
          );
    final roleLocked =
        widget.user != null &&
        ((!canAssignRole(actorRole, _role) && _role == Role.owner) || ownerGuard != null);

    String? pctValidator(String? v) {
      final p = _parsePct(v ?? '');
      if (p == null) return 'Введите число';
      if (p < 0 || p > 100) return 'От 0 до 100';
      return null;
    }

    return Form(
      key: _form,
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit},
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const ValueKey('user_name'),
                      controller: _name,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Имя *'),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Введите имя' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: Gap.m),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Телефон', hintText: '+998 90 123 45 67'),
                      validator: (v) {
                        final p = (v ?? '').trim();
                        if (p.isEmpty) return null;
                        return RegExp(r'^\+?[0-9\s\-()]{5,20}$').hasMatch(p)
                            ? null
                            : 'Неверный формат телефона';
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: Gap.m),
                    Tooltip(
                      message: roleLocked
                          ? (ownerGuard ?? 'Изменить роль владельца может только владелец')
                          : '',
                      child: DropdownButtonFormField<Role>(
                        isExpanded: true,
                        key: const ValueKey('user_role'),
                        initialValue: _role,
                        decoration: InputDecoration(
                          labelText: 'Роль *',
                          helperText: roleLocked ? ownerGuard : null,
                          helperMaxLines: 2,
                        ),
                        items: [for (final r in roles) DropdownMenuItem(value: r, child: Text(r.label))],
                        onChanged: roleLocked ? null : (r) => _onRole(r ?? _role),
                      ),
                    ),
                    const SizedBox(height: Gap.l),
                    Text('PIN для входа', style: t.textTheme.labelLarge),
                    if (!_creating)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Сбросить PIN'),
                        subtitle: const Text('Сотрудник будет входить с новым PIN'),
                        value: _changePin,
                        onChanged: (v) => setState(() => _changePin = v),
                      ),
                    if (_changePin) ...[
                      const SizedBox(height: Gap.s),
                      Row(
                        children: [
                          Expanded(child: _pinField(_pin, 'PIN *', key: const ValueKey('user_pin'))),
                          const SizedBox(width: Gap.m),
                          Expanded(
                            child: _pinField(
                              _pin2,
                              'Повторите PIN *',
                              key: const ValueKey('user_pin2'),
                              validator: (v) => v != _pin.text ? 'PIN не совпадает' : null,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: Gap.xs),
                        child: Text(
                          '4–8 цифр, уникальный для каждого сотрудника',
                          style: t.textTheme.bodySmall,
                        ),
                      ),
                    ],
                    const SizedBox(height: Gap.l),
                    Text('Ограничения и мотивация', style: t.textTheme.labelLarge),
                    const SizedBox(height: Gap.s),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _discount,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                            decoration: const InputDecoration(
                              labelText: 'Макс. скидка',
                              suffixText: '%',
                              helperText: 'без согласования',
                            ),
                            validator: pctValidator,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ),
                        const SizedBox(width: Gap.m),
                        Expanded(
                          child: TextFormField(
                            controller: _commission,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                            decoration: const InputDecoration(
                              labelText: 'Комиссия',
                              suffixText: '%',
                              helperText: 'от чистой выручки',
                            ),
                            validator: pctValidator,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.m),
                    MoneyField(
                      label: 'План продаж на месяц',
                      initial: _plan == 0 ? null : _plan,
                      helper: '0 или пусто — без плана',
                      onChanged: (v) => _plan = v ?? 0,
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.m, Gap.xl, Gap.l),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: Gap.s,
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  FilledButton(
                    key: const ValueKey('user_save'),
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? 'Сохранение…' : (_creating ? 'Добавить' : 'Сохранить')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinField(TextEditingController c, String label, {Key? key, String? Function(String?)? validator}) =>
      TextFormField(
        key: key,
        controller: c,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
        decoration: InputDecoration(labelText: label, counterText: ''),
        validator: (v) {
          if ((v ?? '').isEmpty) return 'Введите PIN';
          if ((v ?? '').length < 4) return 'Минимум 4 цифры';
          return validator?.call(v);
        },
        onFieldSubmitted: (_) => _submit(),
      );
}

class _PinForm extends StatefulWidget {
  const _PinForm({this.message});
  final String? message;

  @override
  State<_PinForm> createState() => _PinFormState();
}

class _PinFormState extends State<_PinForm> {
  final _form = GlobalKey<FormState>();
  final _a = TextEditingController();
  final _b = TextEditingController();

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _ok() {
    if (_form.currentState!.validate()) Navigator.pop(context, _a.text);
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration dec(String l) => InputDecoration(labelText: l, counterText: '');
    final fmt = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)];
    return Form(
      key: _form,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.message != null) ...[Text(widget.message!), const SizedBox(height: Gap.m)],
            TextFormField(
              controller: _a,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: fmt,
              decoration: dec('Новый PIN'),
              validator: (v) => (v ?? '').length < 4 ? 'От 4 до 8 цифр' : null,
            ),
            const SizedBox(height: Gap.m),
            TextFormField(
              controller: _b,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: fmt,
              decoration: dec('Повторите PIN'),
              validator: (v) => v != _a.text ? 'PIN не совпадает' : null,
              onFieldSubmitted: (_) => _ok(),
            ),
            const SizedBox(height: Gap.l),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: Gap.s,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                FilledButton(onPressed: _ok, child: const Text('OK')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Money formatting shortcut for plan text.
String planText(int plan) => plan <= 0 ? 'без плана' : Money.format(plan);

/// Color per role chip.
Color roleColor(Role r) => switch (r) {
  Role.owner => AppColors.brand,
  Role.admin => AppColors.info,
  Role.manager => AppColors.success,
  Role.cashier => AppColors.warning,
  Role.storekeeper => const Color(0xFF6D28D9),
};
