import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/sync/transport.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/errors.dart';
import '../../l10n/l10n.dart';
import '../settings/sync_widgets.dart';

/// PIN login / lock screen. PINs are unique per user, so PIN alone
/// identifies the cashier (fast shift change at the till).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _error;
  bool _busy = false;
  late DateTime _now = DateTime.now();
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(
      const Duration(seconds: 20),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _login(String pin) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final u = await ref.read(authServiceProvider).loginWithPin(pin);
      ref.read(sessionProvider.notifier).login(u);
    } on BusinessException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final store = ref.watch(settingProvider('store_name')) ?? 'DreamPOS';
    final demo = ref.watch(settingProvider('demo_mode')) == '1';
    final testStore = ref.watch(syncStatusProvider).isTestStore;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              t.colorScheme.primary.withValues(alpha: 0.10),
              t.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Gap.l),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Gap.xxl,
                      vertical: Gap.xl,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'D',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: Gap.m),
                        Text(
                          store,
                          textAlign: TextAlign.center,
                          style: t.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: Gap.xs),
                        Text(
                          '${formatTime(_now)} · ${formatDate(_now)}',
                          style: t.textTheme.bodyMedium?.copyWith(
                            color: t.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Gap.xl),
                        Text(context.l10n.authEnterPin, style: t.textTheme.titleMedium),
                        const SizedBox(height: Gap.m),
                        PinPad(onCompleted: _login, error: _error, busy: _busy),
                        if (demo || testStore) ...[
                          const SizedBox(height: Gap.m),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: Gap.s,
                            runSpacing: Gap.xs,
                            children: [
                              if (demo)
                                StatusChip(
                                  context.l10n.authDemoMode,
                                  color: AppColors.warning,
                                ),
                              // Connected to a `test` cloud store (D-025).
                              if (testStore) SyncEnvBadge(StoreEnvironment.test, key: const ValueKey('login-test-store')),
                            ],
                          ),
                        ],
                        const SizedBox(height: Gap.m),
                        const UiLanguageChip(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
