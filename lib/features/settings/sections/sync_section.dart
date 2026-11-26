// Settings → «Синхронизация» (D-025, spec §10, §11): status card, «Синхронизировать
// сейчас», connect wizard (sign in → create a cloud store or join an existing
// one), disconnect, integrity check (SyncAggregates.verifyAll) and the list of
// sync conflicts (`sync_conflicts`). Behind Perm.manageSettings (the settings
// screen checks it).
import 'dart:async';

import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/doc_number.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/sync/aggregates.dart';
import '../../../core/sync/conflict_text.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/sync/transport.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../settings_widgets.dart';
import '../sync_widgets.dart';

/// «Синхронизация».
class SyncSection extends ConsumerStatefulWidget {
  const SyncSection({super.key});

  @override
  ConsumerState<SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends ConsumerState<SyncSection> {
  bool _busy = false;

  SyncService get _svc => ref.read(syncServiceProvider);

  @override
  void initState() {
    super.initState();
    // Fresh pending count / state when the section opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_svc.refreshStatus().then((_) {}, onError: (_) {}));
    });
  }

  Future<void> _syncNow() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final r = await _svc.syncNow();
      if (mounted) showSuccess(context, context.l10n.syncDoneToast('${r.pushed}', '${r.pulled}'));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() async {
    if (_busy) return;
    final out = await showSyncConnectDialog(context);
    if (!mounted || out == null) return;
    final store = out.store;
    if (store != null) {
      final code = ref.read(syncStatusProvider).deviceCode ?? '';
      showSuccess(context, context.l10n.syncConnectedToast(store.name, code));
    } else if (out.error != null) {
      showError(context, out.error!);
    }
    ref.invalidate(syncHasBusinessDataProvider);
  }

  Future<void> _signInAgain() async {
    if (_busy) return;
    final out = await showSyncConnectDialog(context, reauthOnly: true);
    if (!mounted || out == null) return;
    await _syncNow();
  }

  Future<void> _disconnect(SyncStatus s) async {
    if (_busy) return;
    final l = context.l10n;
    final ok = await confirm(
      context,
      title: l.syncDisconnectTitle,
      message: l.syncDisconnectMessage(s.storeName ?? ''),
      ok: l.syncDisconnect,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    await runGuarded(context, _svc.disconnect, success: context.l10n.syncDisconnectedToast);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final status = ref.watch(syncStatusProvider);
    final available = ref.watch(syncTransportFactoryProvider) != null;
    return SectionView(
      title: l.settingsSecSync,
      description: l.syncSectionDesc,
      children: [
        if (!available && !status.configured) InfoBanner(color: AppColors.warning, text: l.syncUnavailable),
        _StatusCard(
          status: status,
          busy: _busy,
          canConnect: available,
          onConnect: _connect,
          onSyncNow: _syncNow,
          onSignInAgain: _signInAgain,
          onDisconnect: () => _disconnect(status),
        ),
        const _IntegrityCard(),
        const _ConflictsCard(),
      ],
    );
  }
}

// ------------------------------------------------------------------ status

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.busy,
    required this.canConnect,
    required this.onConnect,
    required this.onSyncNow,
    required this.onSignInAgain,
    required this.onDisconnect,
  });

  final SyncStatus status;
  final bool busy;
  final bool canConnect;
  final VoidCallback onConnect;
  final VoidCallback onSyncNow;
  final VoidCallback onSignInAgain;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context);
    final s = status;
    final (icon, color) = syncPhaseVisual(s.phase);
    final title = s.configured ? s.phase.labelIn(l) : l.syncOffTitle;
    final err = s.lastError;
    final needsSignIn = err != null && (err.kind == SyncErrorKind.auth || err.kind == SyncErrorKind.notSignedIn);
    final syncing = busy || s.phase == SyncPhase.syncing;
    final code = s.deviceCode;

    return Card(
      key: const ValueKey('sync-status-card'),
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: Gap.m),
                Expanded(
                  child: Wrap(
                    spacing: Gap.m,
                    runSpacing: Gap.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: color),
                      ),
                      if (s.configured && s.environment != null) SyncEnvBadge(s.environment!),
                    ],
                  ),
                ),
              ],
            ),
            if (!s.configured) ...[
              const SizedBox(height: Gap.s),
              Text(l.syncOffMessage, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: Gap.m),
            Wrap(
              spacing: Gap.xl,
              runSpacing: Gap.m,
              children: [
                if (s.configured) _Fact(l.syncStoreLabel, s.storeName ?? '—'),
                if (code != null) _Fact(l.syncDeviceCode, code, hint: l.syncDeviceCodeExample(docNo(15, code))),
                if (s.configured) ...[
                  _Fact(l.syncPending, '${s.pending}', key: const ValueKey('sync-pending')),
                  _Fact(l.syncLastSync, s.lastSyncAt == null ? l.syncNever : formatDateTime(s.lastSyncAt!)),
                ],
                if (s.email != null && s.configured) _Fact(l.syncAccount, s.email!),
              ],
            ),
            if (s.configured && err != null) ...[
              const SizedBox(height: Gap.m),
              InfoBanner(
                key: const ValueKey('sync-last-error'),
                icon: s.phase == SyncPhase.offline ? Icons.cloud_off_outlined : Icons.error_outline,
                color: s.phase == SyncPhase.offline ? AppColors.warning : AppColors.danger,
                text: s.nextRetryAt == null
                    ? err.messageIn(l)
                    : '${err.messageIn(l)}\n${l.syncNextRetry(formatTime(s.nextRetryAt!))}',
              ),
            ],
            const SizedBox(height: Gap.l),
            Wrap(
              spacing: Gap.s,
              runSpacing: Gap.s,
              alignment: WrapAlignment.end,
              children: [
                if (!s.configured)
                  FilledButton.icon(
                    key: const ValueKey('sync-connect'),
                    onPressed: busy || !canConnect ? null : onConnect,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: Text(l.syncConnect),
                  ),
                if (s.configured) ...[
                  OutlinedButton.icon(
                    key: const ValueKey('sync-disconnect'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                    onPressed: busy ? null : onDisconnect,
                    icon: const Icon(Icons.link_off),
                    label: Text(l.syncDisconnect),
                  ),
                  if (needsSignIn)
                    OutlinedButton.icon(
                      key: const ValueKey('sync-sign-in-again'),
                      onPressed: busy ? null : onSignInAgain,
                      icon: const Icon(Icons.login),
                      label: Text(l.syncSignInAgain),
                    ),
                  FilledButton.icon(
                    key: const ValueKey('sync-now'),
                    onPressed: syncing ? null : onSyncNow,
                    icon: syncing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync),
                    label: Text(l.syncSyncNow),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon and color of a sync phase (settings card and shell indicator).
(IconData, Color) syncPhaseVisual(SyncPhase p) => switch (p) {
      SyncPhase.off => (Icons.cloud_off_outlined, Colors.grey),
      SyncPhase.idle => (Icons.cloud_done_outlined, AppColors.success),
      SyncPhase.syncing => (Icons.cloud_sync_outlined, AppColors.info),
      SyncPhase.offline => (Icons.cloud_off_outlined, AppColors.warning),
      SyncPhase.error => (Icons.sync_problem, AppColors.danger),
    };

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {super.key, this.hint});
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          Text(value, style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          if (hint != null)
            Text(hint!, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- integrity

/// A cache mismatch ready for display.
class SyncMismatchView {
  const SyncMismatchView({required this.label, required this.subject, required this.cached, required this.derived});
  final String label;
  final String subject;
  final String cached;
  final String derived;
}

const _moneyColumns = {'debt_balance', 'bonus_balance', 'balance', 'paid', 'refunded_total'};
const _qtyColumns = {'stock_qty', 'received_qty', 'returned_qty'};

String _cacheLabel(AggregateMismatch m, AppLocalizations l) => switch ((m.table, m.column)) {
      ('products', 'stock_qty') => l.syncCacheStock,
      ('customers', 'debt_balance') => l.syncCacheDebt,
      ('customers', 'bonus_balance') => l.syncCacheBonus,
      ('suppliers', 'balance') => l.syncCacheSupplierBalance,
      ('gift_cards', 'balance') => l.syncCacheGiftBalance,
      ('gift_cards', 'status') => l.syncCacheGiftStatus,
      ('purchase_orders', 'paid') => l.syncCachePoPaid,
      ('purchase_order_items', 'received_qty') => l.syncCachePoReceived,
      ('sales', 'refunded_total') => l.syncCacheSaleRefunded,
      ('sales', 'status') => l.syncCacheSaleStatus,
      ('sale_items', 'returned_qty') => l.syncCacheReturnedQty,
      _ => '${m.table}.${m.column}',
    };

String _value(String column, Object? v) {
  if (v == null) return '—';
  if (_moneyColumns.contains(column) && v is num) return Money.format(v.toInt());
  if (_qtyColumns.contains(column) && v is num) return Qty.format(v.toDouble());
  return '$v';
}

/// Resolves names / document numbers of the mismatched rows.
Future<List<SyncMismatchView>> describeMismatches(
    AppDatabase db, List<AggregateMismatch> list, AppLocalizations l) async {
  Future<String?> one(String sql, String id, String Function(QueryRowLike r) f) async {
    final r = await db.customSelect(sql, variables: [Variable<String>(id)]).getSingleOrNull();
    return r == null ? null : f(QueryRowLike(r.data));
  }

  final out = <SyncMismatchView>[];
  for (final m in list) {
    String? subject;
    try {
      subject = switch (m.table) {
        'products' || 'customers' || 'suppliers' =>
          await one('SELECT name FROM ${m.table} WHERE id = ?', m.id, (r) => r.str('name')),
        'gift_cards' => await one('SELECT code FROM gift_cards WHERE id = ?', m.id, (r) => r.str('code')),
        'sales' => await one('SELECT number, device_code FROM sales WHERE id = ?', m.id,
            (r) => l.syncSubjectReceipt(docNo(r.integer('number'), r.strOrNull('device_code')))),
        'purchase_orders' => await one('SELECT number, device_code FROM purchase_orders WHERE id = ?', m.id,
            (r) => l.syncSubjectOrder(docNo(r.integer('number'), r.strOrNull('device_code')))),
        'sale_items' => await one(
            'SELECT s.number, s.device_code, i.product_name AS name FROM sale_items i '
            'JOIN sales s ON s.id = i.sale_id WHERE i.id = ?',
            m.id,
            (r) => '${l.syncSubjectReceipt(docNo(r.integer('number'), r.strOrNull('device_code')))} · ${r.str('name')}'),
        'purchase_order_items' => await one(
            'SELECT o.number, o.device_code, p.name FROM purchase_order_items i '
            'JOIN purchase_orders o ON o.id = i.order_id JOIN products p ON p.id = i.product_id WHERE i.id = ?',
            m.id,
            (r) => '${l.syncSubjectOrder(docNo(r.integer('number'), r.strOrNull('device_code')))} · ${r.str('name')}'),
        _ => null,
      };
    } catch (_) {
      subject = null;
    }
    out.add(SyncMismatchView(
      label: _cacheLabel(m, l),
      subject: subject ?? m.id,
      cached: _value(m.column, m.cached),
      derived: _value(m.column, m.derived),
    ));
  }
  return out;
}

/// Minimal typed reader over a raw row map.
class QueryRowLike {
  const QueryRowLike(this.data);
  final Map<String, Object?> data;
  String str(String k) => '${data[k] ?? ''}';
  String? strOrNull(String k) => data[k] as String?;
  int integer(String k) => (data[k] as num?)?.toInt() ?? 0;
}

class _IntegrityCard extends ConsumerStatefulWidget {
  const _IntegrityCard();

  @override
  ConsumerState<_IntegrityCard> createState() => _IntegrityCardState();
}

class _IntegrityCardState extends ConsumerState<_IntegrityCard> {
  bool _running = false;
  List<SyncMismatchView>? _result;
  Object? _error;

  Future<void> _run() async {
    if (_running) return;
    final l = context.l10n;
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final db = ref.read(databaseProvider);
      final list = await SyncAggregates.verifyAll(db);
      final views = await describeMismatches(db, list, l);
      if (mounted) setState(() => _result = views);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context);
    final r = _result;
    return SectionCard(
      key: const ValueKey('sync-integrity'),
      title: l.syncIntegrityTitle,
      subtitle: l.syncIntegrityDesc,
      trailing: Padding(
        padding: const EdgeInsetsDirectional.only(start: Gap.s),
        child: OutlinedButton.icon(
          key: const ValueKey('sync-integrity-run'),
          onPressed: _running ? null : _run,
          icon: _running
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.fact_check_outlined),
          label: Text(l.syncIntegrityRun),
        ),
      ),
      child: _error != null
          ? SyncErrorBox(_error!, action: TextButton(onPressed: _run, child: Text(l.commonRetry)))
          : _running && r == null
              ? const Padding(padding: EdgeInsets.all(Gap.m), child: Center(child: CircularProgressIndicator()))
              : r == null
                  ? Text(l.syncIntegrityNotRun,
                      style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant))
                  : r.isEmpty
                      ? InfoBanner(icon: Icons.verified_outlined, color: AppColors.success, text: l.syncIntegrityOk)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            InfoBanner(
                              icon: Icons.warning_amber_rounded,
                              color: AppColors.warning,
                              text: l.syncIntegrityFound('${r.length}'),
                            ),
                            const SizedBox(height: Gap.s),
                            for (final m in r.take(100))
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: const Icon(Icons.compare_arrows, color: AppColors.warning),
                                title: Text('${m.label}: ${m.subject}', maxLines: 2, overflow: TextOverflow.ellipsis),
                                subtitle: Text(l.syncIntegrityValues(m.cached, m.derived)),
                              ),
                          ],
                        ),
    );
  }
}

// --------------------------------------------------------------- conflicts

String syncConflictKindLabel(String kind, AppLocalizations l) => ConflictText.kindLabel(l, kind);

IconData _conflictIcon(String kind) => switch (kind) {
      SyncConflictKind.uniqueBarcode => Icons.qr_code_2,
      SyncConflictKind.uniqueCard => Icons.badge_outlined,
      SyncConflictKind.uniqueGiftCode => Icons.card_giftcard,
      SyncConflictKind.negativeStock => Icons.inventory_2_outlined,
      SyncConflictKind.negativeGiftBalance => Icons.card_giftcard,
      SyncConflictKind.negativeBonus => Icons.loyalty_outlined,
      SyncConflictKind.uniqueNumber => Icons.tag,
      SyncConflictKind.voidReturn || SyncConflictKind.overReturn => Icons.assignment_return_outlined,
      SyncConflictKind.identity => Icons.content_copy_outlined,
      SyncConflictKind.doubleVoid || SyncConflictKind.voidRedeem => Icons.card_giftcard,
      SyncConflictKind.rejected => Icons.block_outlined,
      'normalize' => Icons.tune,
      _ => Icons.warning_amber_rounded,
    };

class _ConflictsCard extends ConsumerStatefulWidget {
  const _ConflictsCard();

  @override
  ConsumerState<_ConflictsCard> createState() => _ConflictsCardState();
}

class _ConflictsCardState extends ConsumerState<_ConflictsCard> {
  bool _showResolved = false;

  Future<void> _mark(Iterable<int> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final db = ref.read(databaseProvider);
    await runGuarded(context, () async {
      await (db.update(db.syncConflicts)..where((c) => c.id.isIn(list)))
          .write(const SyncConflictsCompanion(resolved: Value(true)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context);
    final all = ref.watch(syncConflictsProvider);
    final open = all.value?.where((c) => !c.resolved).toList() ?? const <SyncConflict>[];
    return SectionCard(
      key: const ValueKey('sync-conflicts'),
      title: l.syncConflictsTitle,
      subtitle: l.syncConflictsSubtitle,
      trailing: open.isEmpty
          ? null
          : IconButton(
              key: const ValueKey('sync-conflicts-mark-all'),
              tooltip: l.syncConflictsMarkAll,
              onPressed: () => _mark(open.map((c) => c.id)),
              icon: const Icon(Icons.done_all),
            ),
      child: AsyncView(
        value: all,
        onRetry: () => ref.invalidate(syncConflictsProvider),
        data: (list) {
          final shown = _showResolved ? list : open;
          final hasResolved = list.length > open.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Gap.s),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.success),
                      const SizedBox(width: Gap.m),
                      Expanded(child: Text(l.syncConflictsEmpty)),
                    ],
                  ),
                ),
              for (final (c, body) in [for (final c in shown) (c, ConflictText.body(l, c))])
                ListTile(
                  key: ValueKey('sync-conflict-${c.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    c.resolved ? Icons.check_circle_outline : _conflictIcon(c.kind),
                    color: c.resolved ? t.colorScheme.outline : AppColors.warning,
                  ),
                  title: Text(syncConflictKindLabel(c.kind, l)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (body != null && body.isNotEmpty)
                        Text(body, maxLines: 5, overflow: TextOverflow.ellipsis),
                      Text(formatDateTime(c.at)),
                    ],
                  ),
                  isThreeLine: body != null && body.isNotEmpty,
                  trailing: c.resolved
                      ? null
                      : IconButton(
                          tooltip: l.syncConflictMarkRead,
                          onPressed: () => _mark([c.id]),
                          icon: const Icon(Icons.done),
                        ),
                ),
              if (hasResolved)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.syncConflictsShowResolved),
                  value: _showResolved,
                  onChanged: (v) => setState(() => _showResolved = v),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------- connect dialog

/// Result of the connect dialog: [store] on success; [error] when the
/// database got connected but the first sync failed (the status shows it).
class SyncConnectOutcome {
  const SyncConnectOutcome({this.store, this.error});
  final StoreInfo? store;
  final Object? error;
}

/// Sign in → create a cloud store or join an existing one. With
/// [reauthOnly] (connected database, session expired) only the sign-in step
/// is shown and the endpoint is fixed. Returns null when cancelled.
Future<SyncConnectOutcome?> showSyncConnectDialog(BuildContext context, {bool reauthOnly = false}) =>
    showDialog<SyncConnectOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ConnectDialog(reauthOnly: reauthOnly),
    );

enum _Mode { create, join }

class _ConnectDialog extends ConsumerStatefulWidget {
  const _ConnectDialog({required this.reauthOnly});
  final bool reauthOnly;

  @override
  ConsumerState<_ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends ConsumerState<_ConnectDialog> {
  final _createForm = GlobalKey<FormState>();
  final _name = TextEditingController();
  int _step = 0;
  String? _email;
  _Mode _mode = _Mode.create;
  StoreEnvironment _env = StoreEnvironment.test;
  /// Why production cannot be chosen (demo database / test data), or null.
  String? _prodBlock;
  String? _joinBlock;

  /// The store this disconnected database may rejoin despite its data.
  ({String id, String? name})? _rejoin;
  AsyncValue<List<StoreInfo>> _stores = const AsyncLoading();
  String? _storeId;
  bool _busy = false;
  Object? _error;

  SyncService get _svc => ref.read(syncServiceProvider);

  @override
  void initState() {
    super.initState();
    _name.text = ref.read(settingProvider('store_name')) ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _signIn(SyncEndpoint endpoint, String email, String password) async {
    final session = await _svc.signIn(endpoint: endpoint, email: email, password: password);
    if (!mounted) return;
    if (widget.reauthOnly) {
      Navigator.of(context).pop(const SyncConnectOutcome());
      return;
    }
    final block = await _svc.joinBlockReason();
    final rejoin = block == null ? null : await _svc.previousStore();
    final demo = await ref.read(databaseProvider).getSetting('demo_mode') == '1';
    final testData = await _svc.wasOnTestStore();
    if (!mounted) return;
    final l = context.l10n;
    setState(() {
      _email = session.email;
      // Reconnecting to the store this register was disconnected from is
      // allowed with data (only that store is offered then).
      _rejoin = rejoin != null && block == SyncException(SyncErrorKind.notEmpty).message ? rejoin : null;
      _joinBlock = _rejoin == null ? block : null;
      _prodBlock = demo ? l.syncEnvProductionDemo : (testData ? l.syncErrTestData : null);
      _mode = _joinBlock == null ? _Mode.join : _Mode.create;
      _step = 1;
    });
    unawaited(_loadStores());
  }

  Future<void> _loadStores() async {
    setState(() => _stores = const AsyncLoading());
    try {
      var list = await _svc.listStores();
      final rejoin = _rejoin;
      if (rejoin != null) list = [for (final s in list) if (s.id == rejoin.id) s];
      if (!mounted) return;
      setState(() {
        _stores = AsyncData(list);
        if (list.length == 1) _storeId = list.first.id;
      });
    } catch (e, st) {
      if (mounted) setState(() => _stores = AsyncError(e, st));
    }
  }

  bool get _canSubmit =>
      !_busy && (_mode == _Mode.create || (_joinBlock == null && _storeId != null && _stores.hasValue));

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (_mode == _Mode.create && !(_createForm.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = _mode == _Mode.create
          ? await _svc.createStoreAndUpload(name: _name.text.trim(), environment: _env)
          : await _svc.joinStore(_storeId!);
      if (mounted) Navigator.of(context).pop(SyncConnectOutcome(store: info));
    } catch (e) {
      // Connected but the first sync failed: close, the status shows it.
      final connected = await _svc.isConnected().catchError((_) => false);
      if (!mounted) return;
      if (connected) {
        Navigator.of(context).pop(SyncConnectOutcome(error: e));
        return;
      }
      setState(() {
        _busy = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context);
    final prefill = ref.watch(syncPrefillProvider);
    return Dialog(
      insetPadding: const EdgeInsets.all(Gap.l),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.l, Gap.s, 0),
              child: Row(
                children: [
                  const Icon(Icons.cloud_outlined),
                  const SizedBox(width: Gap.m),
                  Expanded(
                    child: Text(
                      widget.reauthOnly ? l.syncSignInAgain : l.syncConnectTitle,
                      style: t.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: l.commonClose,
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.m, Gap.xl, Gap.xl),
                child: _step == 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l.syncSignInIntro,
                              style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: Gap.l),
                          switch (prefill) {
                            AsyncData(:final value) => SyncSignInForm(
                                prefill: value,
                                lockEndpoint: widget.reauthOnly && value.projectId != null,
                                onSignIn: _signIn,
                              ),
                            AsyncError() => SyncSignInForm(onSignIn: _signIn),
                            _ => const Center(child: CircularProgressIndicator()),
                          },
                        ],
                      )
                    : _chooseStep(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chooseStep(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            const SizedBox(width: Gap.s),
            Expanded(child: Text(l.syncSignedInAs(_email ?? ''))),
          ],
        ),
        const SizedBox(height: Gap.l),
        Text(l.syncChooseAction, style: t.textTheme.titleSmall),
        RadioGroup<_Mode>(
          groupValue: _mode,
          onChanged: (v) {
            if (!_busy && v != null) setState(() => _mode = v);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<_Mode>(
                key: const ValueKey('sync-mode-join'),
                value: _Mode.join,
                enabled: !_busy && _joinBlock == null,
                contentPadding: EdgeInsets.zero,
                title: Text(l.syncJoinStore),
                subtitle: Text(
                  _joinBlock ??
                      (_rejoin == null ? l.syncJoinStoreHint : l.syncJoinRejoinHint(_rejoin!.name ?? '')),
                  style: _joinBlock == null ? null : const TextStyle(color: AppColors.warning),
                ),
              ),
              RadioListTile<_Mode>(
                key: const ValueKey('sync-mode-create'),
                value: _Mode.create,
                enabled: !_busy,
                contentPadding: EdgeInsets.zero,
                title: Text(l.syncCreateStore),
                subtitle: Text(l.syncCreateStoreHint),
              ),
            ],
          ),
        ),
        const Divider(height: Gap.xl),
        if (_mode == _Mode.create)
          Form(
            key: _createForm,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey('sync-store-name'),
                  controller: _name,
                  enabled: !_busy,
                  decoration: InputDecoration(labelText: l.syncStoreName),
                  validator: (v) => (v ?? '').trim().isEmpty ? l.commonRequired : null,
                ),
                const SizedBox(height: Gap.m),
                Text(l.syncEnvironment, style: t.textTheme.titleSmall),
                RadioGroup<StoreEnvironment>(
                  groupValue: _env,
                  onChanged: (v) {
                    if (!_busy && v != null) setState(() => _env = v);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<StoreEnvironment>(
                        key: const ValueKey('sync-env-test'),
                        value: StoreEnvironment.test,
                        enabled: !_busy,
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.syncEnvTest),
                        subtitle: Text(l.syncEnvTestHint),
                      ),
                      RadioListTile<StoreEnvironment>(
                        key: const ValueKey('sync-env-production'),
                        value: StoreEnvironment.production,
                        enabled: !_busy && _prodBlock == null,
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.syncEnvProduction),
                        subtitle: Text(_prodBlock ?? l.syncEnvProductionHint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else ...[
          Text(l.syncChooseStore, style: t.textTheme.titleSmall),
          const SizedBox(height: Gap.s),
          SyncStorePicker(
            stores: _stores,
            selected: _storeId,
            enabled: !_busy,
            onSelected: (id) => setState(() => _storeId = id),
            onRetry: _loadStores,
          ),
        ],
        if (_busy) SyncProgress(_mode == _Mode.create ? l.syncUploading : l.syncDownloading),
        if (_error != null) ...[
          const SizedBox(height: Gap.m),
          SyncErrorBox(_error!),
        ],
        const SizedBox(height: Gap.l),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: Gap.s,
          runSpacing: Gap.s,
          children: [
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: Text(l.commonCancel),
            ),
            FilledButton.icon(
              key: const ValueKey('sync-submit'),
              onPressed: _canSubmit ? _submit : null,
              icon: Icon(_mode == _Mode.create ? Icons.cloud_upload_outlined : Icons.cloud_download_outlined),
              label: Text(_mode == _Mode.create ? l.syncCreateAndUpload : l.syncConnect),
            ),
          ],
        ),
      ],
    );
  }
}
