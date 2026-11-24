import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/report_table.dart';

/// Card with a sortable table and an export menu (CSV / PDF / print).
class ReportTableCard extends StatefulWidget {
  const ReportTableCard({
    super.key,
    required this.table,
    this.initialSort,
    this.initialAscending = false,
    this.pageSize = 50,
    this.emptyText = 'Нет данных за период',
    this.header,
  });

  final RTable table;
  final int? initialSort;
  final bool initialAscending;
  final int pageSize;
  final String emptyText;
  /// Extra widget between the title and the table (filters, legend).
  final Widget? header;

  @override
  State<ReportTableCard> createState() => _ReportTableCardState();
}

class _ReportTableCardState extends State<ReportTableCard> {
  late int? _sort = widget.initialSort;
  late bool _asc = widget.initialAscending;
  late int _shown = widget.pageSize;

  @override
  void didUpdateWidget(covariant ReportTableCard old) {
    super.didUpdateWidget(old);
    // Columns can change (cost columns hidden, product/category switch):
    // never keep a sort index that no longer exists.
    final s = _sort;
    if (s != null && s >= widget.table.columns.length) {
      _sort = widget.initialSort != null && widget.initialSort! < widget.table.columns.length
          ? widget.initialSort
          : null;
      _asc = widget.initialAscending;
    }
  }

  List<List<RCell>> get _sorted {
    final rows = [...widget.table.rows];
    final i = _sort;
    if (i == null || i >= widget.table.columns.length) return rows;
    rows.sort((a, b) {
      final Comparable<dynamic> x = a[i].sort ?? a[i].text;
      final Comparable<dynamic> y = b[i].sort ?? b[i].text;
      final c = x.compareTo(y);
      return _asc ? c : -c;
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final table = widget.table;
    final rows = _sorted;
    final visible = rows.take(_shown).toList();
    return SectionCard(
      title: table.title,
      trailing: ExportMenu(table: table),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ?widget.header,
        if (table.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Gap.xl),
            child: Center(
                child: Text(widget.emptyText,
                    style: t.textTheme.bodyMedium
                        ?.copyWith(color: t.colorScheme.onSurfaceVariant))),
          )
        else
          LayoutBuilder(builder: (context, c) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: c.maxWidth),
                child: DataTable(
                  sortColumnIndex: _sort,
                  sortAscending: _asc,
                  headingRowHeight: 40,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 44,
                  columnSpacing: 20,
                  horizontalMargin: 8,
                  headingTextStyle: t.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600, color: t.colorScheme.onSurfaceVariant),
                  columns: [
                    for (var i = 0; i < table.columns.length; i++)
                      DataColumn(
                        label: Text(table.columns[i].title),
                        tooltip: table.columns[i].tooltip,
                        numeric: table.columns[i].numeric,
                        onSort: (col, asc) => setState(() {
                          if (_sort == col) {
                            _asc = !_asc;
                          } else {
                            _sort = col;
                            _asc = !table.columns[col].numeric;
                          }
                        }),
                      ),
                  ],
                  rows: [
                    for (final r in visible) DataRow(cells: [for (final c in r) _cell(c)]),
                    if (table.totals != null && _shown >= rows.length)
                      DataRow(
                        color: WidgetStatePropertyAll(
                            t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                        cells: [
                          for (final c in table.totals!)
                            DataCell(Text(c.text,
                                style: const TextStyle(fontWeight: FontWeight.w700))),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }),
        if (rows.length > _shown)
          Padding(
            padding: const EdgeInsets.only(top: Gap.s),
            child: Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _shown += 200),
                icon: const Icon(Icons.expand_more),
                label: Text('Показать ещё (показано ${visible.length} из ${rows.length})'),
              ),
            ),
          ),
      ]),
    );
  }

  DataCell _cell(RCell c) {
    if (c.chipColor != null) return DataCell(StatusChip(c.text, color: Color(c.chipColor!)));
    return DataCell(Text(c.text,
        style: c.colorValue == null ? null : TextStyle(color: Color(c.colorValue!))));
  }
}

/// Export popup: copy CSV, save CSV, save PDF, print.
class ExportMenu extends ConsumerWidget {
  const ExportMenu({super.key, required this.table, this.compact = true});
  final RTable table;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(settingProvider('store_name'));
    return PopupMenuButton<String>(
      tooltip: 'Экспорт',
      enabled: !table.isEmpty,
      icon: const Icon(Icons.ios_share),
      onSelected: (v) => _run(context, v, store),
      itemBuilder: (_) => const [
        PopupMenuItem(
            value: 'copy',
            child: ListTile(
                leading: Icon(Icons.copy), title: Text('Копировать CSV'), dense: true)),
        PopupMenuItem(
            value: 'csv',
            child: ListTile(
                leading: Icon(Icons.table_view), title: Text('Сохранить CSV (Excel)'), dense: true)),
        PopupMenuItem(
            value: 'pdf',
            child: ListTile(
                leading: Icon(Icons.picture_as_pdf), title: Text('Сохранить PDF'), dense: true)),
        PopupMenuItem(
            value: 'print',
            child: ListTile(leading: Icon(Icons.print), title: Text('Печать'), dense: true)),
      ],
    );
  }

  Future<void> _run(BuildContext context, String action, String? store) async {
    switch (action) {
      case 'copy':
        await runGuarded(context, () => Clipboard.setData(ClipboardData(text: table.toCsv())),
            success: 'Таблица скопирована — вставьте в Excel или сообщение');
      case 'csv':
        String? path;
        final ok = await runGuarded(context, () async => path = await saveCsv(table));
        if (ok && context.mounted && path != null) await showSavedDialog(context, path!);
      case 'pdf':
        String? path;
        final ok =
            await runGuarded(context, () async => path = await savePdf(table, storeName: store));
        if (ok && context.mounted && path != null) await showSavedDialog(context, path!);
      case 'print':
        await runGuarded(context, () async {
          final bytes = await table.toPdf(storeName: store);
          await Printing.layoutPdf(onLayout: (_) async => bytes, name: table.fileBaseName());
        });
    }
  }
}

Future<void> showSavedDialog(BuildContext context, String path) => showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success),
        title: const Text('Файл сохранён'),
        content: SelectableText(path),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: path));
              Navigator.pop(c);
            },
            icon: const Icon(Icons.copy),
            label: const Text('Копировать путь'),
          ),
          FilledButton(
              autofocus: true, onPressed: () => Navigator.pop(c), child: const Text('Готово')),
        ],
      ),
    );
