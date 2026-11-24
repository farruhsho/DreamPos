import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/demo_seed.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/security/pin.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';

/// First-run wizard: store → currency → owner account → finish.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});
  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int _step = 0;
  final _storeKey = GlobalKey<FormState>();
  final _ownerKey = GlobalKey<FormState>();
  final _store = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _taxId = TextEditingController();
  final _owner = TextEditingController();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  CurrencyConfig _currency = CurrencyConfig.presets.first;
  bool _demo = false;
  bool _busy = false;

  Future<void> _finish() async {
    setState(() => _busy = true);
    final db = ref.read(databaseProvider);
    try {
      final user = await ref.read(authServiceProvider).createUser(
            name: _owner.text.trim(),
            role: Role.owner,
            pin: _pin.text,
          );
      final s = <String, String>{
        'store_name': _store.text.trim(),
        'store_address': _address.text.trim(),
        'store_phone': _phone.text.trim(),
        'store_tax_id': _taxId.text.trim(),
        'currency_code': _currency.code,
        'currency_symbol': _currency.symbol,
        'currency_decimals': '${_currency.decimals}',
        'currency_symbol_before': _currency.symbolBefore ? '1' : '0',
        'require_shift': '1',
        'allow_negative_stock': '0',
        'return_days': '14',
        'loyalty_enabled': '0',
        'loyalty_earn_percent': '2',
        'loyalty_max_redeem_percent': '50',
        'receipt_footer': 'Спасибо за покупку!',
        'demo_mode': _demo ? '1' : '0',
      };
      for (final e in s.entries) {
        await db.setSetting(e.key, e.value);
      }
      Money.currency = _currency;
      if (_demo) await DemoSeeder(db).seed(ownerId: user.id);
      await db.setSetting('setup_done', '1');
      ref.read(sessionProvider.notifier).login(user);
      ref.invalidate(setupDoneProvider);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _next() {
    if (_step == 0 && !_storeKey.currentState!.validate()) return;
    if (_step == 2) {
      if (!_ownerKey.currentState!.validate()) return;
      _finish();
      return;
    }
    setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.l),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(Gap.xl),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Добро пожаловать в DreamPOS',
                      style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: Gap.xs),
                  Text('Настройка займёт меньше минуты. Всё можно изменить позже в «Настройках».',
                      style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: Gap.l),
                  _Steps(step: _step),
                  const SizedBox(height: Gap.xl),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: switch (_step) {
                      0 => _storeStep(),
                      1 => _currencyStep(),
                      _ => _ownerStep(),
                    },
                  ),
                  const SizedBox(height: Gap.xl),
                  Row(children: [
                    if (_step > 0)
                      OutlinedButton(
                          onPressed: _busy ? null : () => setState(() => _step--),
                          child: const Text('Назад')),
                    const Spacer(),
                    FilledButton(
                      onPressed: _busy ? null : _next,
                      child: _busy
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_step == 2 ? 'Начать работу' : 'Далее'),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _storeStep() => Form(
        key: _storeKey,
        child: Column(key: const ValueKey(0), children: [
          TextFormField(
            controller: _store,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Название магазина *'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Введите название' : null,
          ),
          const SizedBox(height: Gap.m),
          TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Адрес')),
          const SizedBox(height: Gap.m),
          Row(children: [
            Expanded(
                child: TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Телефон'))),
            const SizedBox(width: Gap.m),
            Expanded(
                child: TextFormField(
                    controller: _taxId, decoration: const InputDecoration(labelText: 'ИНН / STIR'))),
          ]),
        ]),
      );

  Widget _currencyStep() => Column(key: const ValueKey(1), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Валюта учёта', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Gap.s),
        Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
          for (final c in CurrencyConfig.presets)
            ChoiceChip(
              label: Text('${c.code} · ${c.symbol}'),
              selected: _currency.code == c.code,
              onSelected: (_) => setState(() => _currency = c),
            ),
        ]),
        const SizedBox(height: Gap.m),
        Text('Пример: ${Money.format(1234500 * _currency.factor ~/ 1, c: _currency)}',
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: Gap.s),
        Text('Валюту нельзя менять после первой продажи — от неё зависят все суммы в базе.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning)),
      ]);

  Widget _ownerStep() => Form(
        key: _ownerKey,
        child: Column(key: const ValueKey(2), children: [
          TextFormField(
            controller: _owner,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Ваше имя (владелец) *'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Введите имя' : null,
          ),
          const SizedBox(height: Gap.m),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: TextFormField(
                controller: _pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(labelText: 'PIN-код (4–8 цифр) *', counterText: ''),
                validator: (v) => PinHasher.validate(v ?? ''),
              ),
            ),
            const SizedBox(width: Gap.m),
            Expanded(
              child: TextFormField(
                controller: _pin2,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(labelText: 'Повторите PIN *', counterText: ''),
                validator: (v) => v != _pin.text ? 'PIN не совпадает' : null,
              ),
            ),
          ]),
          const SizedBox(height: Gap.s),
          CheckboxListTile(
            value: _demo,
            onChanged: (v) => setState(() => _demo = v ?? false),
            contentPadding: EdgeInsets.zero,
            title: const Text('Заполнить демо-данными'),
            subtitle: const Text(
                'Товары, клиенты и акции для знакомства с системой. Не включайте для реального магазина.'),
          ),
        ]),
      );
}

class _Steps extends StatelessWidget {
  const _Steps({required this.step});
  final int step;
  @override
  Widget build(BuildContext context) {
    const labels = ['Магазин', 'Валюта', 'Владелец'];
    final t = Theme.of(context);
    return Row(children: [
      for (var i = 0; i < labels.length; i++) ...[
        CircleAvatar(
          radius: 13,
          backgroundColor: i <= step ? t.colorScheme.primary : t.colorScheme.surfaceContainerHighest,
          child: i < step
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text('${i + 1}',
                  style: TextStyle(
                      fontSize: 12,
                      color: i <= step ? Colors.white : t.colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(width: Gap.s),
        Text(labels[i], style: t.textTheme.labelLarge),
        if (i < labels.length - 1)
          const Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: Gap.s), child: Divider())),
      ],
    ]);
  }
}
