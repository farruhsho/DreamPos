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
final syncConnectedProvider = FutureProvider.autoDispose<bool>((ref) => ref.watch(syncServiceProvider).isConnected());

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

/// How [SyncSignInForm] offers registration: a «Войти | Создать аккаунт
/// владельца» switch above the fields (Settings), or a «Нет аккаунта?
/// Зарегистрироваться» link under them (setup wizard).
enum SyncAuthSwitch { segmented, link }

/// Minimum password length of a new cloud account (Firebase itself accepts 6).
const syncMinPasswordLength = 8;

/// Firebase project id, Web API key, e-mail and password. The password lives only in
/// this widget's controllers (obscured, never stored). With [onSignUp] the
/// form also offers «Создать аккаунт владельца»: the same project fields,
/// e-mail, a new password (at least [syncMinPasswordLength] characters) and
/// its repetition.
class SyncSignInForm extends StatefulWidget {
  const SyncSignInForm({
    super.key,
    required this.onSignIn,
    this.onSignUp,
    this.authSwitch = SyncAuthSwitch.segmented,
    this.prefill,
    this.lockEndpoint = false,
    this.submitLabel,
    this.signUpIntro,
    this.onBusyChanged,
    this.onRegisterChanged,
  });

  /// Throws on failure (shown inline under the fields).
  final Future<void> Function(SyncEndpoint endpoint, String email, String password) onSignIn;

  /// Registers the owner account; null hides registration. Throws on
  /// failure (shown inline).
  final Future<void> Function(SyncEndpoint endpoint, String email, String password)? onSignUp;
  final SyncAuthSwitch authSwitch;
  final SyncPrefill? prefill;

  /// Re-sign-in of a connected database: the endpoint cannot change.
  final bool lockEndpoint;
  final String? submitLabel;

  /// Text of the banner above the register fields (default
  /// `syncSignUpIntro`; the setup wizard says what it can do next).
  final String? signUpIntro;

  /// A sign-in or registration is in flight (true) or over (false): the
  /// host disables its close / back controls meanwhile, so the account is
  /// never created behind a closed dialog.
  final ValueChanged<bool>? onBusyChanged;

  /// The user switched between «Войти» (false) and registration (true).
  final ValueChanged<bool>? onRegisterChanged;

  @override
  State<SyncSignInForm> createState() => _SyncSignInFormState();
}

class _SyncSignInFormState extends State<SyncSignInForm> {
  final _form = GlobalKey<FormState>();
  late final _project = TextEditingController(text: widget.prefill?.projectId ?? '');
  late final _key = TextEditingController(text: widget.prefill?.apiKey ?? '');
  late final _email = TextEditingController(text: widget.prefill?.email ?? '');
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  final _passwordFocus = FocusNode();
  final _repeatFocus = FocusNode();

  /// Field focused when the form opens: the first one still to fill in.
  late final String _autofocus = _firstEmptyField();
  bool _obscure = true;
  bool _busy = false;
  bool _register = false;
  Object? _error;

  bool get _canRegister => widget.onSignUp != null;

  @override
  void dispose() {
    _project.dispose();
    _key.dispose();
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    _passwordFocus.dispose();
    _repeatFocus.dispose();
    super.dispose();
  }

  String _firstEmptyField() {
    if (!widget.lockEndpoint) {
      if (_project.text.trim().isEmpty) return 'project';
      if (_key.text.trim().isEmpty) return 'key';
    }
    return _email.text.trim().isEmpty ? 'email' : 'password';
  }

  void _setRegister(bool v) {
    if (_busy || v == _register) return;
    setState(() {
      _register = v;
      _error = null;
      _repeat.clear();
    });
    widget.onRegisterChanged?.call(v);
  }

  /// «Аккаунт с этим email уже есть» → «Войти с этим email»: back to sign-in
  /// with the e-mail kept, the password selected for the existing one.
  void _signInWithThisEmail() {
    _setRegister(false);
    _password.selection = TextSelection(baseOffset: 0, extentOffset: _password.text.length);
    _passwordFocus.requestFocus();
  }

  void _setBusy(bool v) {
    setState(() {
      _busy = v;
      if (v) _error = null;
    });
    widget.onBusyChanged?.call(v);
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_form.currentState?.validate() ?? false)) return;
    final register = _register && _canRegister;
    _setBusy(true);
    try {
      final endpoint = SyncEndpoint(projectId: _project.text.trim(), apiKey: _key.text.trim());
      if (register) {
        await widget.onSignUp!(endpoint, _email.text.trim(), _password.text);
      } else {
        await widget.onSignIn(endpoint, _email.text.trim(), _password.text);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  String? _validatePassword(String? v, AppLocalizations l) {
    final s = v ?? '';
    if (s.isEmpty) return l.commonRequired;
    if (_register && _canRegister && s.length < syncMinPasswordLength) return l.syncPasswordTooShort;
    return null;
  }

  Widget _modeSwitch(AppLocalizations l) {
    // Text only (no icons): «Создать аккаунт владельца» needs the width on a
    // phone and may wrap to a second line.
    Widget label(String key, String text) =>
        Text(text, key: ValueKey(key), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis);
    return SegmentedButton<bool>(
      key: const ValueKey('sync-auth-mode'),
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      segments: [
        ButtonSegment(value: false, label: label('sync-auth-sign-in', l.syncAuthModeSignIn), enabled: !_busy),
        ButtonSegment(value: true, label: label('sync-auth-sign-up', l.syncAuthModeSignUp), enabled: !_busy),
      ],
      selected: {_register},
      onSelectionChanged: (v) => _setRegister(v.first),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final register = _register && _canRegister;
    // Each field validates once it was edited (a form-level mode would mark
    // every empty field red as soon as the first one is typed in); _submit
    // validates them all.
    const live = AutovalidateMode.onUserInteraction;
    final error = _error;
    return Form(
      key: _form,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_canRegister && widget.authSwitch == SyncAuthSwitch.segmented) ...[
              _modeSwitch(l),
              const SizedBox(height: Gap.l),
            ],
            if (register) ...[
              InfoBanner(
                key: const ValueKey('sync-sign-up-intro'),
                icon: Icons.person_add_alt_1_outlined,
                text: widget.signUpIntro ?? l.syncSignUpIntro,
              ),
              const SizedBox(height: Gap.l),
            ],
            TextFormField(
              key: const ValueKey('sync-project-id'),
              controller: _project,
              enabled: !_busy && !widget.lockEndpoint,
              autofocus: _autofocus == 'project',
              autovalidateMode: live,
              textInputAction: TextInputAction.next,
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
              autofocus: _autofocus == 'key',
              autovalidateMode: live,
              textInputAction: TextInputAction.next,
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
              autofocus: _autofocus == 'email',
              autovalidateMode: live,
              textInputAction: TextInputAction.next,
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
              focusNode: _passwordFocus,
              enabled: !_busy,
              autofocus: _autofocus == 'password',
              autovalidateMode: live,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: [register ? AutofillHints.newPassword : AutofillHints.password],
              textInputAction: register ? TextInputAction.next : TextInputAction.done,
              decoration: InputDecoration(
                labelText: l.syncPassword,
                helperText: register ? l.syncPasswordNewHelp : l.syncPasswordNote,
                helperMaxLines: 2,
                errorMaxLines: 2,
                suffixIcon: IconButton(
                  tooltip: _obscure ? l.syncPasswordShow : l.syncPasswordHide,
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => _validatePassword(v, l),
              // Register: Enter goes straight to the repetition (the default
              // «next» would land on the show/hide button and a second Enter
              // would reveal the password).
              onEditingComplete: register ? _repeatFocus.requestFocus : null,
              onFieldSubmitted: register ? null : (_) => _submit(),
            ),
            if (register) ...[
              const SizedBox(height: Gap.m),
              TextFormField(
                key: const ValueKey('sync-password-repeat'),
                controller: _repeat,
                focusNode: _repeatFocus,
                enabled: !_busy,
                autovalidateMode: live,
                textInputAction: TextInputAction.done,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(labelText: l.syncPasswordRepeat, errorMaxLines: 2),
                validator: (v) {
                  if ((v ?? '').isEmpty) return l.commonRequired;
                  return v == _password.text ? null : l.syncPasswordMismatch;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: Gap.m),
              SyncErrorBox(error),
              // Under the box, not beside it: a long message on a phone
              // would otherwise be squeezed into a narrow column.
              if (register && error is SyncException && error.kind == SyncErrorKind.emailExists)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    key: const ValueKey('sync-email-exists-sign-in'),
                    onPressed: _signInWithThisEmail,
                    icon: const Icon(Icons.login),
                    label: Text(l.syncSignInWithThisEmail),
                  ),
                ),
            ],
            const SizedBox(height: Gap.l),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                key: ValueKey(register ? 'sync-sign-up' : 'sync-sign-in'),
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(register ? Icons.person_add_alt_1_outlined : Icons.login),
                label: Text(register ? l.syncSignUpSubmit : (widget.submitLabel ?? l.syncSignIn)),
              ),
            ),
            if (_canRegister && widget.authSwitch == SyncAuthSwitch.link) ...[
              const SizedBox(height: Gap.s),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  key: ValueKey(register ? 'sync-auth-to-sign-in' : 'sync-auth-to-sign-up'),
                  onPressed: _busy ? null : () => _setRegister(!register),
                  child: Text(register ? l.syncHaveAccountSignIn : l.syncNoAccountSignUp, textAlign: TextAlign.end),
                ),
              ),
            ],
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
