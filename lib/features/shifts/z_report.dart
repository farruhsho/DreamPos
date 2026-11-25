// X/Z report widgets: on-screen view, print menu, dialog.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/doc_number.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../core/db/database.dart';
import '../../domain/errors.dart';
import '../../l10n/l10n.dart';
import 'report_data.dart';
import 'shift_providers.dart';

export 'report_data.dart';

/// Prints an X/Z report (roll or A4). Installed by [ShiftsScreen] with the
/// PDF implementation from z_report_pdf.dart; kept as a hook so the screen
/// body does not depend on the PDF stack (and stays testable headless).
typedef ZReportPrintFn = Future<void> Function(AppDatabase db, String shiftId, {required bool a4, bool showProfit});

ZReportPrintFn? zReportPrinter;

/// Print menu (80mm roll / A4).
class PrintReportButton extends ConsumerWidget {
  const PrintReportButton({super.key, required this.shiftId, this.filled = false});
  final String shiftId;
  final bool filled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final l = context.l10n;
    final profit = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    Future<void> go(bool a4) => runGuarded(context, () async {
      final p = zReportPrinter;
      if (p == null) throw BusinessException(l.shiftPrintUnavailable);
      await p(db, shiftId, a4: a4, showProfit: profit);
    });
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.receipt_outlined),
          onPressed: () => go(false),
          child: Text(l.shiftRoll80),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.description_outlined),
          onPressed: () => go(true),
          child: Text(l.shiftSheetA4),
        ),
      ],
      builder: (context, c, _) {
        void toggle() => c.isOpen ? c.close() : c.open();
        return filled
            ? FilledButton.icon(onPressed: toggle, icon: const Icon(Icons.print), label: Text(l.commonPrint))
            : OutlinedButton.icon(onPressed: toggle, icon: const Icon(Icons.print), label: Text(l.commonPrint));
      },
    );
  }
}

/// On-screen report table (used for X live view sections and Z dialog).
class ReportSectionsView extends StatelessWidget {
  const ReportSectionsView({super.key, required this.data});
  final ZReportData data;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final loc = context.l10n;
    final diff = data.figures.difference;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final sec in data.sections(loc)) ...[
          Padding(
            padding: const EdgeInsets.only(top: Gap.m, bottom: Gap.xs),
            child: Text(sec.title, style: t.textTheme.titleSmall?.copyWith(color: t.colorScheme.primary)),
          ),
          for (final l in sec.lines)
            Padding(
              padding: EdgeInsets.only(left: l.indent ? Gap.l : 0, top: 2, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      l.label,
                      style: l.indent
                          ? t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)
                          : t.textTheme.bodyMedium?.copyWith(fontWeight: l.bold ? FontWeight.w600 : null),
                    ),
                  ),
                  const SizedBox(width: Gap.m),
                  Expanded(
                    flex: 4,
                    child: Text(
                      l.value,
                      textAlign: TextAlign.right,
                      style: t.textTheme.bodyMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: l.bold ? FontWeight.w700 : null,
                        color: (l.label == loc.shiftShortage && diff != null)
                            ? AppColors.danger
                            : l.label == loc.shiftSurplus
                            ? AppColors.warning
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
        ],
      ],
    );
  }
}

/// Loads and shows a closed shift's Z-report with print actions.
class ZReportPanel extends ConsumerWidget {
  const ZReportPanel({super.key, required this.shiftId, this.scrollable = true});
  final String shiftId;
  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fig = ref.watch(shiftFiguresProvider(shiftId));
    final users = ref.watch(shiftUsersProvider).value ?? const {};
    final settings = ref.watch(settingsProvider).value ?? const {};
    final profit = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    return AsyncView(
      value: fig,
      onRetry: () => ref.invalidate(shiftFiguresProvider(shiftId)),
      data: (f) {
        final d = ZReportData(
          figures: f,
          settings: settings,
          openedByName: users[f.shift.openedBy]?.name ?? '—',
          closedByName: f.shift.closedBy == null ? null : users[f.shift.closedBy]?.name ?? '—',
          showProfit: profit,
        );
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.shiftReportHeader(d.titleIn(context.l10n), docNo(f.shift.number, f.shift.deviceCode)),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PrintReportButton(shiftId: shiftId),
              ],
            ),
            ReportSectionsView(data: d),
          ],
        );
        return scrollable ? SingleChildScrollView(child: content) : content;
      },
    );
  }
}

Future<void> showZReportDialog(BuildContext context, String shiftId, {String? title}) {
  return showFormDialog<void>(
    context,
    title: title ?? context.l10n.shiftReportTitle,
    width: 560,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.l),
      child: ZReportPanel(shiftId: shiftId),
    ),
  );
}
