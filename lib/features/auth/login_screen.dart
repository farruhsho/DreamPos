import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/errors.dart';

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
    _clock = Timer.periodic(const Duration(seconds: 20), (_) => setState(() => _now = DateTime.now()));
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.colorScheme.primary.withValues(alpha: 0.10), t.scaffoldBackgroundColor],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Gap.l),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.xxl, vertical: Gap.xl),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(store, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: Gap.xs),
                  Text('${formatTime(_now)} · ${formatDate(_now)}',
                      style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: Gap.xl),
                  Text('Введите PIN-код', style: t.textTheme.titleMedium),
                  const SizedBox(height: Gap.m),
                  PinPad(onCompleted: _login, error: _error, busy: _busy),
                  if (demo) ...[
                    const SizedBox(height: Gap.m),
                    const StatusChip('Демо-режим', color: AppColors.warning),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
