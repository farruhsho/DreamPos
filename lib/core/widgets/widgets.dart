// Shared UI kit. Features should build screens from these so the product
// looks consistent: PageScaffold, EmptyState, ErrorView, AsyncView,
// MoneyField, QtyField, SearchField, StatCard, StatusChip, toasts, dialogs.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/errors.dart';
import '../money.dart';
import '../theme.dart';

export 'pin_pad.dart';

/// Standard page: title bar + optional actions + body with max width.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.fab,
    this.subtitle,
    this.bottom,
    this.padding = const EdgeInsets.all(Gap.l),
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final Widget? fab;
  final PreferredSizeWidget? bottom;
  final EdgeInsets padding;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: leading,
        automaticallyImplyLeading: leading == null,
        title: subtitle == null
            ? Text(title)
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
        actions: [...actions, const SizedBox(width: Gap.s)],
        bottom: bottom,
      ),
      floatingActionButton: fab,
      body: Padding(padding: padding, child: body),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(Gap.l),
              decoration: BoxDecoration(
                color: t.colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: t.colorScheme.primary),
            ),
            const SizedBox(height: Gap.l),
            Text(title, style: t.textTheme.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: Gap.s),
              Text(message!,
                  style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: Gap.l), action!],
          ]),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.error_outline,
        title: 'Что-то пошло не так',
        message: errorText(error),
        action: onRetry == null
            ? null
            : OutlinedButton.icon(
                onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Повторить')),
      );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator.adaptive());
}

/// Renders an AsyncValue with consistent loading/error UI.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.data, this.onRetry});
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => switch (value) {
        AsyncData(:final value) => data(value),
        AsyncError(:final error) => ErrorView(error: error, onRetry: onRetry),
        _ => const LoadingView(),
      };
}

String errorText(Object e) {
  if (e is BusinessException) return e.message;
  final s = e.toString();
  if (s.contains('UNIQUE constraint failed')) {
    if (s.contains('barcode')) return 'Товар с таким штрихкодом уже существует';
    if (s.contains('card_number')) return 'Карта с таким номером уже есть';
    if (s.contains('code')) return 'Такой код уже существует';
    return 'Такая запись уже существует';
  }
  return s.replaceFirst('Exception: ', '');
}

// ------------------------------------------------------------------ toasts

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white),
        const SizedBox(width: Gap.m),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: AppColors.success,
    ));
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white),
        const SizedBox(width: Gap.m),
        Expanded(child: Text(errorText(error))),
      ]),
      backgroundColor: AppColors.danger,
      duration: const Duration(seconds: 5),
    ));
}

/// Runs [action], shows success/error toast. Returns true on success.
Future<bool> runGuarded(BuildContext context, Future<void> Function() action,
    {String? success}) async {
  try {
    await action();
    if (success != null && context.mounted) showSuccess(context, success);
    return true;
  } catch (e) {
    if (context.mounted) showError(context, e);
    return false;
  }
}

Future<bool> confirm(BuildContext context,
    {required String title,
    String? message,
    String ok = 'Подтвердить',
    String cancel = 'Отмена',
    bool destructive = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(cancel)),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
              : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Asks for a single line of text (e.g. a reason). Returns null if cancelled.
Future<String?> promptText(BuildContext context,
    {required String title, String? label, String? initial, bool required = true}) {
  final ctl = TextEditingController(text: initial);
  final key = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Form(
        key: key,
        child: SizedBox(
          width: 380,
          child: TextFormField(
            controller: ctl,
            autofocus: true,
            decoration: InputDecoration(labelText: label),
            validator: (v) => required && (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
            onFieldSubmitted: (_) {
              if (key.currentState!.validate()) Navigator.pop(c, ctl.text.trim());
            },
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Отмена')),
        FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(c, ctl.text.trim());
            },
            child: const Text('OK')),
      ],
    ),
  );
}

// ------------------------------------------------------------------ inputs

/// Money input bound to minor units.
class MoneyField extends StatefulWidget {
  const MoneyField({
    super.key,
    required this.label,
    this.initial,
    this.onChanged,
    this.validator,
    this.required = false,
    this.allowZero = true,
    this.autofocus = false,
    this.controller,
    this.onSubmitted,
    this.helper,
    this.enabled = true,
  });

  final String label;
  final bool enabled;
  final int? initial;
  final ValueChanged<int?>? onChanged;
  final String? Function(int?)? validator;
  final bool required;
  final bool allowZero;
  final bool autofocus;
  final TextEditingController? controller;
  final ValueChanged<int?>? onSubmitted;
  final String? helper;

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  late final TextEditingController _c = widget.controller ??
      TextEditingController(
          text: widget.initial == null ? '' : Money.groupInput(Money.toInput(widget.initial!)));

  @override
  void dispose() {
    if (widget.controller == null) _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _c,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
        const MoneyGroupingFormatter(),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: Money.currency.symbol,
        helperText: widget.helper,
      ),
      onChanged: (v) => widget.onChanged?.call(Money.parse(v)),
      onFieldSubmitted: (v) => widget.onSubmitted?.call(Money.parse(v)),
      validator: (v) {
        final parsed = (v == null || v.trim().isEmpty) ? null : Money.parse(v);
        if (widget.required && (v == null || v.trim().isEmpty)) return 'Обязательное поле';
        if (v != null && v.trim().isNotEmpty && parsed == null) return 'Неверная сумма';
        if (parsed != null && parsed < 0) return 'Не может быть отрицательной';
        if (!widget.allowZero && parsed == 0) return 'Должна быть больше нуля';
        return widget.validator?.call(parsed);
      },
    );
  }
}

/// Quantity input (supports decimals for weighted goods).
class QtyField extends StatelessWidget {
  const QtyField({
    super.key,
    required this.controller,
    this.label = 'Количество',
    this.unit,
    this.allowZero = false,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? unit;
  final bool allowZero;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  static double? parse(String s) => double.tryParse(s.replaceAll(',', '.').replaceAll(' ', ''));

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        decoration: InputDecoration(
            labelText: label, suffixText: unit == null ? null : Qty.unitLabel(unit!)),
        onFieldSubmitted: onSubmitted,
        validator: (v) {
          final q = parse(v ?? '');
          if (q == null) return 'Введите число';
          if (q < 0 || (!allowZero && q == 0)) return 'Должно быть больше нуля';
          if (unit != null && !Qty.isFractional(unit!) && q != q.roundToDouble()) {
            return 'Только целое число';
          }
          return null;
        },
      );
}

/// Search box with debounce.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.onChanged,
    this.hint = 'Поиск',
    this.autofocus = false,
    this.controller,
    this.focusNode,
    this.onSubmitted,
    this.debounce = const Duration(milliseconds: 250),
  });

  final ValueChanged<String> onChanged;
  final String hint;
  final bool autofocus;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final Duration debounce;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _c = widget.controller ?? TextEditingController();
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    if (widget.controller == null) _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _c,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ListenableBuilder(
            listenable: _c,
            builder: (_, _) => _c.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Очистить',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _c.clear();
                      widget.onChanged('');
                    }),
          ),
        ),
        onChanged: (v) {
          _t?.cancel();
          _t = Timer(widget.debounce, () => widget.onChanged(v.trim()));
        },
        onSubmitted: widget.onSubmitted,
      );
}

// ------------------------------------------------------------------ display

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.hint,
    this.onTap,
    this.dense = false,
  });

  /// Compact tile for phone grids: no icon, smaller paddings and value.
  final bool dense;
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = color ?? t.colorScheme.primary;
    final showIcon = icon != null && !dense;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(dense ? Gap.m : Gap.l),
          child: Row(children: [
            if (showIcon) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: c),
              ),
              const SizedBox(width: Gap.m),
            ],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label,
                    style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: (dense ? t.textTheme.titleMedium : t.textTheme.titleLarge)
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (hint != null)
                  Text(hint!,
                      style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Section with a title inside a card.
class SectionCard extends StatelessWidget {
  const SectionCard(
      {super.key, required this.title, required this.child, this.trailing, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(Gap.l),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ]),
                ),
                ?trailing,
              ]),
            ),
            const SizedBox(height: Gap.m),
            child,
          ]),
        ),
      );
}

/// Responsive helper.
extension ResponsiveContext on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;
  bool get isCompact => width < Breakpoints.compact;
  bool get isWide => width >= Breakpoints.medium;
}

/// Dialog wrapper with a constrained width for forms.
Future<T?> showFormDialog<T>(BuildContext context,
    {required String title, required Widget child, double width = 520}) {
  return showDialog<T>(
    context: context,
    builder: (c) => Dialog(
      insetPadding: const EdgeInsets.all(Gap.l),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: MediaQuery.sizeOf(c).height * 0.9),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.l, Gap.s, 0),
            child: Row(children: [
              Expanded(child: Text(title, style: Theme.of(c).textTheme.titleLarge)),
              IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close), tooltip: 'Закрыть'),
            ]),
          ),
          Flexible(child: child),
        ]),
      ),
    ),
  );
}

/// Groups digits of a money input as the user types ("1234567" -> "1 234 567").
class MoneyGroupingFormatter extends TextInputFormatter {
  const MoneyGroupingFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final grouped = Money.groupInput(newValue.text);
    if (grouped == newValue.text) return newValue;
    // keep the caret after the same number of digits/separators
    final before = newValue.selection.end.clamp(0, newValue.text.length);
    final significant =
        newValue.text.substring(0, before).replaceAll(RegExp(r'[\s\u00A0]'), '').length;
    var pos = 0, seen = 0;
    while (pos < grouped.length && seen < significant) {
      if (grouped[pos] != ' ') seen++;
      pos++;
    }
    return TextEditingValue(text: grouped, selection: TextSelection.collapsed(offset: pos));
  }
}

/// Russian plural: pluralRu(5, 'товар', 'товара', 'товаров') -> 'товаров'.
String pluralRu(int n, String one, String few, String many) {
  final m10 = n.abs() % 10, m100 = n.abs() % 100;
  if (m10 == 1 && m100 != 11) return one;
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
  return many;
}

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
String formatDateTime(DateTime d) =>
    '${formatDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
