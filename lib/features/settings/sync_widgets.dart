// Shared pieces of the multi-register sync UI (spec §10, §11): the sign-in
// form, the store picker, the environment badge and small providers. Used by
// Settings → «Синхронизация» and by the setup wizard's join path.
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/sync/firebase_transport.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/transport.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'settings_widgets.dart';

/// Client-side check of the Firebase project id (`dreampos-test-uz26`).
/// Returns a localized error or null.
String? validateSyncProjectId(String? v, AppLocalizations l) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return l.commonRequired;
  return FirebaseTransport.projectIdPattern.hasMatch(s) ? null : l.syncErrInvalidProject;
}

/// Client-side check of the Web API key (non-empty, key characters only).
String? validateSyncApiKey(String? v, AppLocalizations l) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return l.commonRequired;
  return FirebaseTransport.apiKeyPattern.hasMatch(s) ? null : l.syncErrInvalidApiKey;
}

String? validateSyncEmail(String? v, AppLocalizations l) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return l.commonRequired;
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return l.syncInvalidEmail;
  return null;
}

/// Endpoint and e-mail kept from an earlier sign-in (never the password).
typedef SyncPrefill = ({String? projectId, String? apiKey, String? email});

final syncPrefillProvider = FutureProvider.autoDispose<SyncPrefill>((ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.select(db.syncState).get();
  final m = {for (final r in rows) r.key: r.value};
  return (projectId: m[SyncKeys.projectId], apiKey: m[SyncKeys.apiKey], email: m[SyncKeys.email]);
});

/// `sync_conflicts`, newest first.
final syncConflictsProvider = StreamProvider.autoDispose<List<SyncConflict>>((ref) {
  final db = ref.watch(databaseProvider);
  final q = db.select(db.syncConflicts)
    ..orderBy([(c) => OrderingTerm.desc(c.id)])
    ..limit(200);
  return q.watch();
});

/// True when this database has business data (join is refused then).
final syncHasBusinessDataProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(syncServiceProvider).hasBusinessData(),
);

/// The database is connected to a store (the setup wizard then only offers
/// to finish the interrupted join: a local store must not be created on it).
final syncConnectedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(syncServiceProvider).isConnected(),
);

/// «Тестовый магазин» / «Рабочий магазин» badge.
class SyncEnvBadge extends StatelessWidget {
  const SyncEnvBadge(this.environment, {super.key});
  final StoreEnvironment environment;

  @override
  Widget build(BuildContext context) => StatusChip(
        environment.labelIn(context.l10n),
        color: environment == StoreEnvironment.test ? AppColors.info : AppColors.success,
      );
}

/// Red inline error box (dialogs: a snackbar would be hidden behind them).
class SyncErrorBox extends StatelessWidget {
  const SyncErrorBox(this.error, {super.key, this.action});
  final Object error;
  final Widget? action;

  @override
  Widget build(BuildContext context) => InfoBanner(
        key: const ValueKey('sync-error'),
        icon: Icons.error_outline,
        color: AppColors.danger,
        text: errorText(error),
        action: action,
      );
}

/// Firebase project id, Web API key, e-mail and password. The password lives only in
/// this widget's controller (obscured, never stored).
class SyncSignInForm extends StatefulWidget {
  const SyncSignInForm({
    super.key,
    required this.onSignIn,
    this.prefill,
    this.lockEndpoint = false,
    this.submitLabel,
  });

  /// Throws on failure (shown inline under the fields).
  final Future<void> Function(SyncEndpoint endpoint, String email, String password) onSignIn;
  final SyncPrefill? prefill;

  /// Re-sign-in of a connected database: the endpoint cannot change.
  final bool lockEndpoint;
  final String? submitLabel;

  @override
  State<SyncSignInForm> createState() => _SyncSignInFormState();
}

class _SyncSignInFormState extends State<SyncSignInForm> {
  final _form = GlobalKey<FormState>();
  late final _project = TextEditingController(text: widget.prefill?.projectId ?? '');
  late final _key = TextEditingController(text: widget.prefill?.apiKey ?? '');
  late final _email = TextEditingController(text: widget.prefill?.email ?? '');
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _project.dispose();
    _key.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSignIn(
        SyncEndpoint(projectId: _project.text.trim(), apiKey: _key.text.trim()),
        _email.text.trim(),
        _password.text,
      );
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Form(
      key: _form,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('sync-project-id'),
              controller: _project,
              enabled: !_busy && !widget.lockEndpoint,
              autocorrect: false,
              enableSuggestions: false,
              maxLines: 1,
              decoration: InputDecoration(
                labelText: l.syncProjectId,
                hintText: l.syncProjectIdHint,
                helperText: l.syncProjectIdHelp,
                helperMaxLines: 3,
                errorMaxLines: 3,
              ),
              validator: (v) => validateSyncProjectId(v, l),
            ),
            const SizedBox(height: Gap.m),
            TextFormField(
              key: const ValueKey('sync-api-key'),
              controller: _key,
              enabled: !_busy && !widget.lockEndpoint,
              autocorrect: false,
              enableSuggestions: false,
              maxLines: 1,
              decoration: InputDecoration(
                labelText: l.syncApiKey,
                helperText: l.syncApiKeyHelp,
                helperMaxLines: 3,
                errorMaxLines: 3,
              ),
              validator: (v) => validateSyncApiKey(v, l),
            ),
            const SizedBox(height: Gap.m),
            TextFormField(
              key: const ValueKey('sync-email'),
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(labelText: l.syncEmail),
              validator: (v) => validateSyncEmail(v, l),
            ),
            const SizedBox(height: Gap.m),
            TextFormField(
              key: const ValueKey('sync-password'),
              controller: _password,
              enabled: !_busy,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: l.syncPassword,
                helperText: l.syncPasswordNote,
                helperMaxLines: 2,
                suffixIcon: IconButton(
                  tooltip: _obscure ? l.syncPasswordShow : l.syncPasswordHide,
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v ?? '').isEmpty ? l.commonRequired : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: Gap.m),
              SyncErrorBox(_error!),
            ],
            const SizedBox(height: Gap.l),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                key: const ValueKey('sync-sign-in'),
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.login),
                label: Text(widget.submitLabel ?? l.syncSignIn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stores of the signed-in account as a radio list (loading / error / empty).
class SyncStorePicker extends StatelessWidget {
  const SyncStorePicker({
    super.key,
    required this.stores,
    required this.selected,
    required this.onSelected,
    required this.onRetry,
    this.enabled = true,
  });

  final AsyncValue<List<StoreInfo>> stores;
  final String? selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onRetry;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return switch (stores) {
      AsyncData(:final value) when value.isEmpty => InfoBanner(
          icon: Icons.storefront_outlined,
          color: AppColors.warning,
          text: l.syncNoStores,
        ),
      AsyncData(:final value) => RadioGroup<String>(
          groupValue: selected,
          onChanged: (v) {
            if (enabled && v != null) onSelected(v);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in value)
                RadioListTile<String>(
                  key: ValueKey('sync-store-${s.id}'),
                  value: s.id,
                  enabled: enabled,
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Align(alignment: AlignmentDirectional.centerStart, child: SyncEnvBadge(s.environment)),
                ),
            ],
          ),
        ),
      AsyncError(:final error) => SyncErrorBox(
          error,
          action: TextButton(onPressed: onRetry, child: Text(l.commonRetry)),
        ),
      _ => const Padding(
          padding: EdgeInsets.all(Gap.l),
          child: Center(child: CircularProgressIndicator()),
        ),
    };
  }
}

/// Spinner with a line of text (long operations: upload / download).
class SyncProgress extends StatelessWidget {
  const SyncProgress(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.l),
        child: Row(
          children: [
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(width: Gap.m),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
