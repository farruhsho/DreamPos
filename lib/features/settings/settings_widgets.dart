import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'settings_logic.dart';

/// Saves settings with audit as the current user.
Future<int> applySettings(WidgetRef ref, Map<String, String> values) =>
    saveSettings(ref.read(databaseProvider), values, userId: ref.read(sessionProvider)?.user.id);

String? currentUserId(WidgetRef ref) => ref.read(sessionProvider)?.user.id;

/// Shares "has unsaved changes" between a section form and the screen, so
/// switching sections / leaving the page can ask before discarding edits.
class SettingsDirtyScope extends InheritedWidget {
  const SettingsDirtyScope({super.key, required this.dirty, required super.child});
  final ValueNotifier<bool> dirty;

  static ValueNotifier<bool>? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SettingsDirtyScope>()?.dirty;

  @override
  bool updateShouldNotify(SettingsDirtyScope oldWidget) => dirty != oldWidget.dirty;
}

Future<bool> confirmDiscard(BuildContext context) => confirm(
  context,
  title: 'Отменить изменения?',
  message: 'В разделе есть несохранённые изменения. Если уйти, они будут потеряны.',
  ok: 'Не сохранять',
  destructive: true,
);

/// Scrollable section body with constrained width and optional sticky save bar.
class SectionView extends StatelessWidget {
  const SectionView({super.key, required this.title, required this.children, this.description, this.bottom});

  final String title;
  final String? description;
  final List<Widget> children;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final showTitle = context.isWide;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(context.isCompact ? Gap.m : Gap.xl),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showTitle)
                        Text(title, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                      if (description != null) ...[
                        if (showTitle) const SizedBox(height: Gap.xs),
                        Text(
                          description!,
                          style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                        ),
                      ],
                      if (showTitle || description != null) const SizedBox(height: Gap.l),
                      for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(height: Gap.l), c],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ?bottom,
      ],
    );
  }
}

/// Sticky bar shown when a form has unsaved edits.
class SaveBar extends StatelessWidget {
  const SaveBar({
    super.key,
    required this.visible,
    required this.saving,
    required this.onSave,
    required this.onReset,
  });
  final bool visible;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final compact = context.isCompact;
    return !visible
        ? const SizedBox.shrink()
        : Material(
            color: t.colorScheme.surfaceContainerHigh,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.s),
                // On phones the buttons take the whole bar (no icon/hint) so
                // nothing overflows at 360px.
                child: Row(
                  children: [
                    if (!compact) ...[
                      Icon(Icons.edit_note, color: t.colorScheme.primary),
                      const SizedBox(width: Gap.s),
                    ],
                    Expanded(
                      child: compact
                          ? const SizedBox.shrink()
                          : const Text(
                              'Есть несохранённые изменения (Ctrl+S — сохранить)',
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    TextButton(onPressed: saving ? null : onReset, child: const Text('Отменить')),
                    const SizedBox(width: Gap.s),
                    FilledButton.icon(
                      onPressed: saving ? null : onSave,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : (compact ? null : const Icon(Icons.save_outlined)),
                      label: const Text('Сохранить'),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}

/// Text-field based settings form: tracks a baseline, dirty state, saves only
/// changed keys (so two admins editing different fields don't overwrite each
/// other) and reloads from DB when the settings change elsewhere.
mixin SettingsFormMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _ctls = {};
  Map<String, String> _baseline = {};
  bool saving = false;
  bool _loading = false;
  ValueNotifier<bool>? _dirtyScope;

  List<String> get formKeys;

  /// Display value when the key is missing in the DB.
  String defaultFor(String key) => '';
  String toDisplay(String key, String stored) => stored;
  String toStored(String key, String display) => display.trim();

  TextEditingController ctl(String key) =>
      _ctls.putIfAbsent(key, () => TextEditingController()..addListener(_changed));

  String _display(String key) {
    final v = _baseline[key];
    return v == null ? defaultFor(key) : toDisplay(key, v);
  }

  bool get dirty => formKeys.any((k) => ctl(k).text != _display(k));

  void _changed() {
    if (_loading || !mounted) return;
    _dirtyScope?.value = dirty;
    setState(() {});
  }

  void loadFrom(Map<String, String> s) {
    _loading = true;
    _baseline = {
      for (final k in formKeys)
        if (s.containsKey(k)) k: s[k]!,
    };
    for (final k in formKeys) {
      final d = _display(k);
      if (ctl(k).text != d) ctl(k).text = d;
    }
    _loading = false;
    _dirtyScope?.value = false;
  }

  @override
  void initState() {
    super.initState();
    loadFrom(ref.read(settingsProvider).value ?? const {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dirtyScope = SettingsDirtyScope.maybeOf(context);
  }

  @override
  void dispose() {
    _dirtyScope?.value = false;
    for (final c in _ctls.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Call from build(): reloads untouched forms when settings change elsewhere.
  void listenSettings() {
    ref.listen(settingsProvider, (_, next) {
      final s = next.value;
      if (s == null || dirty || saving) return;
      if (mounted) setState(() => loadFrom(s));
    });
  }

  /// Extra validation beyond field validators. Return an error to abort.
  String? validateForm() => null;

  Future<void> save() async {
    if (saving || !dirty) return;
    if (!(formKey.currentState?.validate() ?? false)) return;
    final err = validateForm();
    if (err != null) {
      showError(context, err);
      return;
    }
    final changes = <String, String>{
      for (final k in formKeys)
        if (ctl(k).text != _display(k)) k: toStored(k, ctl(k).text),
    };
    setState(() => saving = true);
    final ok = await runGuarded(context, () async {
      await applySettings(ref, changes);
    }, success: 'Настройки сохранены');
    if (!mounted) return;
    setState(() {
      saving = false;
      if (ok) {
        final merged = {..._baseline, ...changes};
        loadFrom(merged);
      }
    });
  }

  void reset() => setState(() => loadFrom(_baseline));

  /// Wraps the form with Ctrl+S and a sticky save bar.
  Widget buildForm({required String title, String? description, required List<Widget> children}) {
    listenSettings();
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): save,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): save,
      },
      child: Focus(
        autofocus: false,
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SectionView(
            title: title,
            description: description,
            bottom: SaveBar(visible: dirty, saving: saving, onSave: save, onReset: reset),
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A switch bound to a setting, applied (and audited) immediately.
class SettingSwitch extends ConsumerWidget {
  const SettingSwitch({
    super.key,
    required this.settingKey,
    required this.title,
    this.subtitle,
    this.defaultOn = false,
    this.confirmChange,
    this.enabled = true,
    this.icon,
  });

  final String settingKey;
  final String title;
  final String? subtitle;
  final bool defaultOn;
  final IconData? icon;
  final bool enabled;

  /// Return false to cancel the change (e.g. after a warning dialog).
  final Future<bool> Function(BuildContext context, bool newValue)? confirmChange;

  static bool isOn(String? v, {bool defaultOn = false}) => v == null ? defaultOn : v != '0' && v.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = isOn(ref.watch(settingProvider(settingKey)), defaultOn: defaultOn);
    return SwitchListTile(
      secondary: icon == null ? null : Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: on,
      onChanged: !enabled
          ? null
          : (v) async {
              if (confirmChange != null && !await confirmChange!(context, v)) return;
              if (!context.mounted) return;
              await runGuarded(
                context,
                () => applySettings(ref, {settingKey: v ? '1' : '0'}),
                success: v ? '«$title» — включено' : '«$title» — выключено',
              );
            },
    );
  }
}

/// Card with a list of controls (switch tiles etc.) without inner padding.
class TileCard extends StatelessWidget {
  const TileCard({super.key, required this.children, this.title});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.l, Gap.l, Gap.l, Gap.xs),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        for (final (i, c) in children.indexed) ...[
          if (i > 0) const Divider(indent: Gap.l, endIndent: Gap.l),
          c,
        ],
      ],
    ),
  );
}

/// Left-aligned box that keeps short inputs (percent, days, a picker) from
/// stretching across the whole 860px card on desktop.
class NarrowField extends StatelessWidget {
  const NarrowField({super.key, required this.child, this.maxWidth = 360});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Colored information / warning banner.
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, this.icon = Icons.info_outline, this.color, this.action});
  final String text;
  final IconData icon;
  final Color? color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.info;
    return Container(
      padding: const EdgeInsets.all(Gap.m),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(width: Gap.m),
          Expanded(child: Text(text)),
          if (action != null) ...[const SizedBox(width: Gap.s), action!],
        ],
      ),
    );
  }
}

/// Copies text and confirms with a toast.
Future<void> copyToClipboard(BuildContext context, String text, {String message = 'Скопировано'}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showSuccess(context, message);
}
