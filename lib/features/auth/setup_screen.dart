import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/demo_seed.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/security/pin.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../settings/sync_widgets.dart' show syncConnectedProvider, syncHasBusinessDataProvider;
import 'setup_join.dart';

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

  /// «Подключиться к существующему магазину» instead of creating a store.
  bool _joining = false;

  Future<void> _finish() async {
    setState(() => _busy = true);
    final db = ref.read(databaseProvider);
    try {
      // A connected database belongs to its store: creating a local store
      // here would push a second owner and these settings to every register.
      if (await ref.read(syncServiceProvider).isConnected()) {
        ref.invalidate(syncConnectedProvider);
        return;
      }
      final user = await ref
          .read(authServiceProvider)
          .createUser(name: _owner.text.trim(), role: Role.owner, pin: _pin.text);
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
        'receipt_footer': L.current.setupDefaultReceiptFooter,
        // receipts start in the language chosen in the wizard (footer matches)
        'receipt_locale': L.current.localeName,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.setupWelcome,
                      style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: Gap.xs),
                    Text(
                      context.l10n.setupIntro,
                      style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: Gap.l),
                    if (ref.watch(syncConnectedProvider).value ?? false)
                      SetupJoinPanel(resume: true, onBack: () {})
                    else if (_joining)
                      SetupJoinPanel(onBack: () => setState(() => _joining = false))
                    else ...[
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
                      Row(
                        children: [
                          if (_step > 0)
                            OutlinedButton(
                              onPressed: _busy ? null : () => setState(() => _step--),
                              child: Text(context.l10n.commonBack),
                            ),
                          const Spacer(),
                          FilledButton(
                            onPressed: _busy ? null : _next,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(_step == 2 ? context.l10n.setupStart : context.l10n.commonNext),
                          ),
                        ],
                      ),
                      if (_step == 0 && _canJoin()) _joinOffer(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Joining is offered only on a fresh, empty database with a transport.
  bool _canJoin() =>
      ref.watch(syncTransportFactoryProvider) != null && ref.watch(syncHasBusinessDataProvider).value == false;

  Widget _joinOffer() {
    final t = Theme.of(context);
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Gap.l),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.m),
              child: Text(l.setupOr, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: Gap.m),
        OutlinedButton.icon(
          key: const ValueKey('setup-join'),
          onPressed: _busy ? null : () => setState(() => _joining = true),
          icon: const Icon(Icons.cloud_download_outlined),
          label: Text(l.setupJoinStore, textAlign: TextAlign.center),
        ),
        const SizedBox(height: Gap.xs),
        Text(
          l.setupJoinStoreHint,
          textAlign: TextAlign.center,
          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _storeStep() => Form(
    key: _storeKey,
    child: Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.coreUiLanguage, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: Gap.s),
        const UiLanguagePicker(),
        const SizedBox(height: Gap.l),
        TextFormField(
          controller: _store,
          autofocus: true,
          decoration: InputDecoration(labelText: context.l10n.setupStoreName),
          validator: (v) => (v ?? '').trim().isEmpty ? context.l10n.setupEnterStoreName : null,
        ),
        const SizedBox(height: Gap.m),
        TextFormField(
          controller: _address,
          decoration: InputDecoration(labelText: context.l10n.commonAddress),
        ),
        const SizedBox(height: Gap.m),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: context.l10n.commonPhone),
              ),
            ),
            const SizedBox(width: Gap.m),
            Expanded(
              child: TextFormField(
                controller: _taxId,
                decoration: InputDecoration(labelText: context.l10n.setupTaxId),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _currencyStep() => Column(
    key: const ValueKey(1),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(context.l10n.setupCurrency, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: Gap.s),
      Wrap(
        spacing: Gap.s,
        runSpacing: Gap.s,
        children: [
          for (final c in CurrencyConfig.presets)
            ChoiceChip(
              label: Text('${c.code} · ${c.symbol}'),
              selected: _currency.code == c.code,
              onSelected: (_) => setState(() => _currency = c),
            ),
        ],
      ),
      const SizedBox(height: Gap.m),
      Text(
        context.l10n.setupCurrencyExample(Money.format(1234500 * _currency.factor ~/ 1, c: _currency)),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: Gap.s),
      Text(
        context.l10n.setupCurrencyWarning,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning),
      ),
    ],
  );

  Widget _ownerStep() => Form(
    key: _ownerKey,
    child: Column(
      key: const ValueKey(2),
      children: [
        TextFormField(
          controller: _owner,
          autofocus: true,
          decoration: InputDecoration(labelText: context.l10n.setupOwnerName),
          validator: (v) => (v ?? '').trim().isEmpty ? context.l10n.commonEnterName : null,
        ),
        const SizedBox(height: Gap.m),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: InputDecoration(labelText: context.l10n.setupPin, counterText: ''),
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
                decoration: InputDecoration(labelText: context.l10n.setupPinRepeat, counterText: ''),
                validator: (v) => v != _pin.text ? context.l10n.setupPinMismatch : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.s),
        CheckboxListTile(
          value: _demo,
          onChanged: (v) => setState(() => _demo = v ?? false),
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.setupDemo),
          subtitle: Text(context.l10n.setupDemoHint),
        ),
      ],
    ),
  );
}

class _Steps extends StatelessWidget {
  const _Steps({required this.step});
  final int step;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = [l.setupStepStore, l.setupStepCurrency, l.setupStepOwner];
    final t = Theme.of(context);
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          CircleAvatar(
            radius: 13,
            backgroundColor: i <= step ? t.colorScheme.primary : t.colorScheme.surfaceContainerHighest,
            child: i < step
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${i + 1}',
                    style: TextStyle(fontSize: 12, color: i <= step ? Colors.white : t.colorScheme.onSurfaceVariant),
                  ),
          ),
          const SizedBox(width: Gap.s),
          Text(labels[i], style: t.textTheme.labelLarge),
          if (i < labels.length - 1)
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Gap.s),
                child: Divider(),
              ),
            ),
        ],
      ],
    );
  }
}
