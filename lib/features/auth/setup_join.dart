// Setup wizard, first step: «Подключиться к существующему магазину» (D-025,
// spec §10). A fresh install signs in to the cloud, picks a store, registers
// as the next register, pulls everything (users included) and lands on the
// login screen. Only offered for an empty database. When a join was
// interrupted (network, app closed) the wizard reopens this panel in its
// «resume» state: the database is already connected, so only the download is
// repeated.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/transport.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import '../settings/settings_widgets.dart' show InfoBanner;
import '../settings/sync_widgets.dart';

class SetupJoinPanel extends ConsumerStatefulWidget {
  const SetupJoinPanel({super.key, required this.onBack, this.resume = false});

  /// Back to creating a new local store.
  final VoidCallback onBack;

  /// The database is already connected (an earlier join did not finish):
  /// only «Повторить загрузку», never back to a local store.
  final bool resume;

  @override
  ConsumerState<SetupJoinPanel> createState() => _SetupJoinPanelState();
}

class _SetupJoinPanelState extends ConsumerState<SetupJoinPanel> {
  String? _email;
  AsyncValue<List<StoreInfo>> _stores = const AsyncLoading();
  String? _storeId;
  bool _busy = false;
  Object? _error;

  /// Connected, but the first download failed: retry with syncNow.
  late bool _partial = widget.resume;

  /// Resuming needs a new sign-in (the stored session was rejected).
  bool _needSignIn = false;

  SyncService get _svc => ref.read(syncServiceProvider);

  Future<void> _signIn(SyncEndpoint endpoint, String email, String password) async {
    final s = await _svc.signIn(endpoint: endpoint, email: email, password: password);
    if (!mounted) return;
    setState(() {
      _email = s.email;
      _needSignIn = false;
    });
    if (_partial) {
      await _join();
    } else {
      unawaited(_loadStores());
    }
  }

  Future<void> _loadStores() async {
    setState(() => _stores = const AsyncLoading());
    try {
      final list = await _svc.listStores();
      if (!mounted) return;
      setState(() {
        _stores = AsyncData(list);
        if (list.length == 1) _storeId = list.first.id;
      });
    } catch (e, st) {
      if (mounted) setState(() => _stores = AsyncError(e, st));
    }
  }

  Future<void> _join() async {
    if (_busy || (_storeId == null && !_partial)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_partial) {
        await _svc.syncNow();
      } else {
        await _svc.joinStore(_storeId!);
      }
      if (!mounted) return;
      showSuccess(context, context.l10n.setupJoinDone);
      // setup_done was set by the engine after the full download: the router
      // now goes to the PIN login (users came from the cloud).
      ref.invalidate(setupDoneProvider);
    } catch (e) {
      final connected = await _svc.isConnected().catchError((_) => false);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e;
        _partial = connected;
        _needSignIn = connected &&
            e is SyncException &&
            (e.kind == SyncErrorKind.auth || e.kind == SyncErrorKind.notSignedIn);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context);
    final prefill = ref.watch(syncPrefillProvider);
    final signedIn = _email != null;
    if (_partial && (widget.resume || _needSignIn)) return _resumeView(context, prefill);
    return Column(
      key: const ValueKey('setup-join-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.coreUiLanguage, style: t.textTheme.titleSmall),
        const SizedBox(height: Gap.s),
        const UiLanguagePicker(),
        const SizedBox(height: Gap.l),
        Text(l.setupJoinTitle, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: Gap.xs),
        Text(l.setupJoinIntro, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        const SizedBox(height: Gap.l),
        if (!signedIn)
          switch (prefill) {
            AsyncData(:final value) => SyncSignInForm(prefill: value, onSignIn: _signIn),
            AsyncError() => SyncSignInForm(onSignIn: _signIn),
            _ => const Center(child: CircularProgressIndicator()),
          }
        else ...[
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
              const SizedBox(width: Gap.s),
              Expanded(child: Text(l.syncSignedInAs(_email!))),
            ],
          ),
          const SizedBox(height: Gap.m),
          Text(l.syncChooseStore, style: t.textTheme.titleSmall),
          const SizedBox(height: Gap.s),
          SyncStorePicker(
            stores: _stores,
            selected: _storeId,
            enabled: !_busy && !_partial,
            onSelected: (id) => setState(() => _storeId = id),
            onRetry: _loadStores,
          ),
          if (_busy) SyncProgress(l.syncDownloading),
          if (_partial && !_busy) ...[
            const SizedBox(height: Gap.m),
            InfoBanner(icon: Icons.cloud_off_outlined, color: AppColors.warning, text: l.setupJoinPartial),
          ],
          if (_error != null) ...[
            const SizedBox(height: Gap.m),
            SyncErrorBox(_error!),
          ],
          const SizedBox(height: Gap.l),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              key: const ValueKey('setup-join-submit'),
              onPressed: _busy || _storeId == null || !_stores.hasValue ? null : _join,
              icon: const Icon(Icons.cloud_download_outlined),
              label: Text(_partial ? l.setupJoinRetry : l.syncConnect),
            ),
          ),
        ],
        const SizedBox(height: Gap.m),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('setup-join-back'),
            // Once connected the database belongs to the store: no way back.
            onPressed: _busy || _partial ? null : widget.onBack,
            icon: const Icon(Icons.arrow_back),
            label: Text(l.setupJoinNewStore),
          ),
        ),
      ],
    );
  }

  /// The database is connected but the download is not complete: retry it
  /// (signing in again first when the stored session was rejected).
  Widget _resumeView(BuildContext context, AsyncValue<SyncPrefill> prefill) {
    final l = context.l10n;
    final t = Theme.of(context);
    return Column(
      key: const ValueKey('setup-join-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.coreUiLanguage, style: t.textTheme.titleSmall),
        const SizedBox(height: Gap.s),
        const UiLanguagePicker(),
        const SizedBox(height: Gap.l),
        Text(l.setupJoinTitle, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: Gap.m),
        InfoBanner(icon: Icons.cloud_off_outlined, color: AppColors.warning, text: l.setupJoinPartial),
        if (_needSignIn) ...[
          const SizedBox(height: Gap.l),
          switch (prefill) {
            AsyncData(:final value) =>
              SyncSignInForm(prefill: value, lockEndpoint: value.url != null, onSignIn: _signIn),
            AsyncError() => SyncSignInForm(onSignIn: _signIn),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ],
        if (_busy) SyncProgress(l.syncDownloading),
        if (_error != null) ...[
          const SizedBox(height: Gap.m),
          SyncErrorBox(_error!),
        ],
        if (!_needSignIn) ...[
          const SizedBox(height: Gap.l),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              key: const ValueKey('setup-join-submit'),
              onPressed: _busy ? null : _join,
              icon: const Icon(Icons.cloud_download_outlined),
              label: Text(l.setupJoinRetry),
            ),
          ),
        ],
      ],
    );
  }
}
