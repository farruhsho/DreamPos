import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'product_logic.dart';
import 'products_repo.dart';

// ------------------------------------------------------------------ decoding

const _cp1251High = <int>[
  0x0402, 0x0403, 0x201A, 0x0453, 0x201E, 0x2026, 0x2020, 0x2021, 0x20AC, 0x2030, 0x0409, 0x2039, 0x040A, 0x040C, 0x040B, 0x040F, //
  0x0452, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, 0xFFFD, 0x2122, 0x0459, 0x203A, 0x045A, 0x045C, 0x045B, 0x045F, //
  0x00A0, 0x040E, 0x045E, 0x0408, 0x00A4, 0x0490, 0x00A6, 0x00A7, 0x0401, 0x00A9, 0x0404, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x0407, //
  0x00B0, 0x00B1, 0x0406, 0x0456, 0x0491, 0x00B5, 0x00B6, 0x00B7, 0x0451, 0x2116, 0x0454, 0x00BB, 0x0458, 0x0405, 0x0455, 0x0457,
];

/// Decodes Windows-1251 (Excel "CSV" on Russian Windows).
String decodeCp1251(List<int> bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    if (b < 0x80) {
      sb.writeCharCode(b);
    } else if (b >= 0xC0) {
      sb.writeCharCode(0x0410 + b - 0xC0);
    } else {
      sb.writeCharCode(_cp1251High[b - 0x80]);
    }
  }
  return sb.toString();
}

/// UTF-8 (with/without BOM) first, Windows-1251 as fallback.
String decodeCsvBytes(List<int> bytes) {
  try {
    return utf8.decode(bytes).replaceFirst('\uFEFF', '');
  } on FormatException {
    return decodeCp1251(bytes);
  }
}

// -------------------------------------------------------------------- import

Future<void> showImportDialog(BuildContext context) =>
    showFormDialog<void>(context, title: context.l10n.prodImportTitle, width: 980, child: const _ImportDialog());

// Example data for the «Пример» button (demo content, not translated).
const _sample = 'name;barcode;sku;category;price;cost;unit;stock\n'
    'Молоко 3,2% 1 л;4870001234561;M-001;Молочные;12000;9500;шт;24\n' // l10n-ignore
    'Сахар;;S-010;Бакалея;"14 500";11000;кг;12,5'; // l10n-ignore

class _ImportDialog extends ConsumerStatefulWidget {
  const _ImportDialog();
  @override
  ConsumerState<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<_ImportDialog> {
  final _text = TextEditingController();
  final _path = TextEditingController();
  bool _update = true;
  bool _busy = false;
  ImportParseResult? _parsed;
  List<PlannedImport>? _plan;

  @override
  void dispose() {
    _text.dispose();
    _path.dispose();
    super.dispose();
  }

  Future<void> _loadFile() async {
    var path = _path.text.trim();
    if (path.startsWith('"') && path.endsWith('"') && path.length > 1) {
      path = path.substring(1, path.length - 1);
    }
    final l = context.l10n;
    if (path.isEmpty) {
      showError(context, l.prodImpEnterPath);
      return;
    }
    try {
      final f = File(path);
      if (!await f.exists()) throw Exception(l.prodImpFileNotFound(path));
      final len = await f.length();
      if (len > 20 * 1024 * 1024) throw Exception(l.prodImpFileTooBig);
      final text = decodeCsvBytes(await f.readAsBytes());
      if (!mounted) return;
      setState(() => _text.text = text);
      showSuccess(context, l.prodImpFileLoaded(p.basename(path)));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _check() async {
    if (_busy) return;
    final l = context.l10n;
    if (_text.text.trim().isEmpty) {
      showError(context, l.prodImpPasteOrLoad);
      return;
    }
    setState(() => _busy = true);
    try {
      final parsed = parseImport(_text.text, currency: Money.currency);
      if (parsed.rows.isEmpty) throw Exception(l.prodImpNoRows);
      if (parsed.rows.length > 20000) throw Exception(l.prodImpTooManyRows('${parsed.rows.length}'));
      final plan = await ref.read(productsRepoProvider).planImport(parsed.rows, updateExisting: _update);
      if (!mounted) return;
      setState(() {
        _parsed = parsed;
        _plan = plan;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    if (_busy) return;
    final plan = _plan!;
    final todo = plan.where((x) => x.action != ImportAction.skip).length;
    final l = context.l10n;
    if (todo == 0) {
      showError(context, l.prodImpNothing);
      return;
    }
    final session = ref.read(sessionProvider)!;
    setState(() => _busy = true);
    try {
      final res = await ref.read(productsRepoProvider).applyImport(plan,
          userId: session.user.id,
          canEditPrices: session.can(Perm.editPrices),
          canSetCost: session.can(Perm.viewCost));
      if (!mounted) return;
      showSuccess(
          context,
          '${l.prodImpDone('${res.created}', '${res.updated}')}'
          '${res.skipped > 0 ? l.prodImpDoneSkipped('${res.skipped}') : ''}'
          '${res.categoriesCreated > 0 ? l.prodImpDoneCategories('${res.categoriesCreated}') : ''}');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.l),
      child: plan == null ? _input() : _preview(plan),
    );
  }

  Widget _input() {
    final t = Theme.of(context);
    final l = context.l10n;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
        l.prodImpIntro,
        style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: Gap.m),
      Flexible(
        child: TextField(
          controller: _text,
          autofocus: true,
          minLines: 8,
          maxLines: 16,
          style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 13),
          decoration: InputDecoration(
            hintText: l.prodImpPasteHint,
            alignLabelWithHint: true,
          ),
        ),
      ),
      const SizedBox(height: Gap.m),
      LayoutBuilder(builder: (context, c) {
        final field = TextField(
          controller: _path,
          decoration: InputDecoration(
            labelText: l.prodImpOrPath,
            hintText: l.prodImpPathHint,
            prefixIcon: const Icon(Icons.insert_drive_file_outlined, size: 20),
          ),
          onSubmitted: (_) => _loadFile(),
        );
        final load = OutlinedButton(onPressed: _loadFile, child: Text(l.prodImpLoad));
        if (c.maxWidth < 480) {
          // Phone: a path field squeezed next to the button is unreadable.
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            field,
            const SizedBox(height: Gap.s),
            Align(alignment: Alignment.centerRight, child: load),
          ]);
        }
        return Row(children: [Expanded(child: field), const SizedBox(width: Gap.s), load]);
      }),
      const SizedBox(height: Gap.s),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _update,
        onChanged: (v) => setState(() => _update = v),
        title: Text(l.prodImpUpdateExisting),
        subtitle: Text(l.prodImpUpdateExistingHint),
      ),
      const SizedBox(height: Gap.s),
      Wrap(alignment: WrapAlignment.end, spacing: Gap.s, runSpacing: Gap.s, children: [
        TextButton.icon(
          onPressed: () => setState(() => _text.text = _sample),
          icon: const Icon(Icons.article_outlined),
          label: Text(l.prodImpSample),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton.icon(
          onPressed: _busy ? null : _check,
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(l.prodImpCheck),
        ),
      ]),
    ]);
  }

  Widget _preview(List<PlannedImport> plan) {
    final t = Theme.of(context);
    final parsed = _parsed!;
    final create = plan.where((x) => x.action == ImportAction.create).length;
    final update = plan.where((x) => x.action == ImportAction.update).length;
    final skip = plan.length - create - update;
    final newCats = <String>{
      for (final x in plan)
        if (x.action != ImportAction.skip && x.row.category != null) x.row.category!.toLowerCase()
    };
    final known = {
      for (final c in ref.read(productCategoriesProvider).value ?? const []) c.name.toLowerCase()
    };
    newCats.removeAll(known);
    final canPrice = ref.read(sessionProvider)?.can(Perm.editPrices) ?? false;
    final l = context.l10n;

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
        StatusChip(l.prodImpRows('${plan.length}')),
        StatusChip(l.prodImpNew('$create'), color: AppColors.success),
        StatusChip(l.prodImpUpdateCount('$update'), color: AppColors.info),
        if (skip > 0) StatusChip(l.prodImpSkipErrors('$skip'), color: AppColors.danger),
        if (newCats.isNotEmpty) StatusChip(l.prodImpNewCategories('${newCats.length}'), color: AppColors.warning),
        StatusChip(
            parsed.hasHeader
                ? l.prodImpDelimiterWithHeader(parsed.delimiterLabel)
                : l.prodImpDelimiterNoHeader(parsed.delimiterLabel),
            color: t.colorScheme.outline),
      ]),
      if (update > 0 && !canPrice)
        Padding(
          padding: const EdgeInsets.only(top: Gap.s),
          child: Text(l.prodImpNoPricePerm, style: const TextStyle(color: AppColors.warning)),
        ),
      const SizedBox(height: Gap.m),
      Flexible(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 460),
          decoration: BoxDecoration(
            border: Border.all(color: t.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: plan.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (_, i) {
              final x = plan[i];
              final r = x.row;
              final (label, color) = switch (x.action) {
                ImportAction.create => (l.commonNew, AppColors.success),
                ImportAction.update => (l.prodImpUpdate, AppColors.info),
                ImportAction.skip => r.isValid ? (l.prodImpSkip, AppColors.warning) : (l.commonError, AppColors.danger),
              };
              final details = [
                if (r.barcode != null) r.barcode!,
                if (r.sku != null) l.prodSkuShort(r.sku!),
                if (r.category != null) r.category!,
                if (r.price != null) Money.format(r.price!),
                if (r.stock != null) l.prodStockAfterShort(Qty.format(r.stock!, r.unit, l)),
              ].join(' · ');
              final notes = [...r.warnings, ?x.note];
              return ListTile(
                dense: true,
                leading: SizedBox(
                  width: 44,
                  child: Text('${r.line}',
                      textAlign: TextAlign.right,
                      style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                ),
                title: Text(r.name.isEmpty ? l.prodImpNoName : r.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (details.isNotEmpty) Text(details, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (notes.isNotEmpty)
                    Text(notes.join('; '),
                        style: TextStyle(color: x.action == ImportAction.skip ? AppColors.danger : AppColors.warning)),
                ]),
                trailing: StatusChip(label, color: color),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: Gap.l),
      Wrap(alignment: WrapAlignment.end, spacing: Gap.s, runSpacing: Gap.s, children: [
        TextButton.icon(
          onPressed: _busy ? null : () => setState(() => _plan = null),
          icon: const Icon(Icons.arrow_back),
          label: Text(l.prodImpBackToData),
        ),
        FilledButton.icon(
          onPressed: _busy || create + update == 0 ? null : _apply,
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.file_download_done),
          label: Text(l.prodImpImportN('${create + update}')),
        ),
      ]),
    ]);
  }
}

// -------------------------------------------------------------------- export

/// Exports products (current filter or [ids]) to CSV: copies to clipboard and
/// saves to the Documents folder.
Future<void> exportProductsCsv(BuildContext context, WidgetRef ref, ProductQuery q, {Set<String>? ids}) async {
  final session = ref.read(sessionProvider);
  final repo = ref.read(productsRepoProvider);
  final l = context.l10n;
  String csv;
  try {
    csv = await repo.exportCsv(q, ids: ids, includeCost: session?.can(Perm.viewCost) ?? false);
  } catch (e) {
    if (context.mounted) showError(context, e);
    return;
  }
  // Count parsed rows (names may contain quoted line breaks), minus header.
  final count = parseCsvRows(csv, ';').length - 1;
  if (count <= 0) {
    if (context.mounted) showError(context, l.prodExpNothing);
    return;
  }
  await Clipboard.setData(ClipboardData(text: csv));
  String? path;
  Object? saveError;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final name = 'dreampos_${l.prodExpFileStem}_${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}.csv';
    path = p.join(dir.path, name);
    // BOM so Excel opens UTF-8 Cyrillic correctly.
    await File(path).writeAsString('\uFEFF$csv', encoding: utf8);
  } catch (e) {
    saveError = e;
    path = null;
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.check_circle, color: AppColors.success, size: 36),
      title: Text(l.prodExpDoneTitle('$count')),
      content: SizedBox(
        width: 460,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.prodExpCopied),
          const SizedBox(height: Gap.m),
          if (path != null) ...[
            Text(l.prodExpSaved),
            const SizedBox(height: Gap.xs),
            SelectableText(path, style: const TextStyle(fontWeight: FontWeight.w600)),
          ] else
            Text(l.prodExpSaveFailed(errorText(saveError ?? '')),
                style: const TextStyle(color: AppColors.warning)),
        ]),
      ),
      actions: [
        if (path != null)
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: path!)),
            child: Text(l.prodExpCopyPath),
          ),
        FilledButton(onPressed: () => Navigator.pop(c), child: Text(l.commonDone)),
      ],
    ),
  );
}
