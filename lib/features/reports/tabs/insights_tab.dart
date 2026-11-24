import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/nav.dart';
import '../../../core/permissions.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/insights.dart';
import '../report_providers.dart';
import '../widgets/kpi.dart';

/// True when the current user may open [route] (respects nav permissions).
bool canOpenRoute(Session? s, String route) {
  if (s == null) return false;
  final item = navItems.firstWhereOrNull((n) => route.startsWith(n.path));
  return item == null || s.can(item.perm);
}

({Color color, IconData icon, String label}) severityStyle(InsightSeverity s) => switch (s) {
      InsightSeverity.critical => (color: AppColors.danger, icon: Icons.error_outline, label: 'Срочно'),
      InsightSeverity.warning => (color: AppColors.warning, icon: Icons.warning_amber_rounded, label: 'Внимание'),
      InsightSeverity.info => (color: AppColors.info, icon: Icons.lightbulb_outline, label: 'Совет'),
      InsightSeverity.positive => (color: AppColors.success, icon: Icons.thumb_up_alt_outlined, label: 'Хорошо'),
    };

class InsightsTab extends ConsumerWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(insightsDataProvider);
    final session = ref.watch(sessionProvider);
    final withCost = session?.can(Perm.viewCost) ?? false;
    final t = Theme.of(context);
    return AsyncView<InsightData>(
      value: data,
      onRetry: () => ref.invalidate(insightsDataProvider),
      data: (d) {
        final list = buildInsights(d, withCost: withCost);
        return ListView(padding: const EdgeInsets.all(Gap.l), children: [
          LayoutBuilder(builder: (context, c) {
            final intro = Row(children: [
              Icon(Icons.auto_awesome, color: t.colorScheme.primary),
              const SizedBox(width: Gap.s),
              Expanded(
                child: Text(
                  'Подсказки по вашим данным за последние 30 дней. Считаются на этом устройстве, '
                  'без интернета; каждая объясняет, откуда взялись цифры.',
                  style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                ),
              ),
            ]);
            final refresh = OutlinedButton.icon(
              onPressed: () => ref.invalidate(insightsDataProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Обновить'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
            );
            // wide: refresh button at the right edge; phone: under the text
            if (c.maxWidth >= 600) {
              return Row(children: [Expanded(child: intro), const SizedBox(width: Gap.m), refresh]);
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              intro,
              const SizedBox(height: Gap.s),
              refresh,
            ]);
          }),
          const SizedBox(height: Gap.m),
          if (list.isEmpty)
            const EmptyState(
              icon: Icons.auto_awesome,
              title: 'Пока нечего подсказать',
              message: 'Подсказки появятся, когда накопятся продажи хотя бы за неделю. '
                  'Проблем с остатками, долгами и маржой не найдено.',
            )
          else
            ResponsiveGrid(minTile: 340, maxColumns: 3, children: [
              for (final i in list)
                InsightCard(insight: i, canOpen: i.route != null && canOpenRoute(session, i.route!)),
            ]),
        ]);
      },
    );
  }
}

class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight, required this.canOpen});
  final Insight insight;
  final bool canOpen;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final st = severityStyle(insight.severity);
    return Card(
      key: ValueKey('insight-${insight.id}'),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 4, color: st.color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Gap.l),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(st.icon, color: st.color, size: 20),
                  const SizedBox(width: Gap.s),
                  StatusChip(st.label, color: st.color),
                ]),
                const SizedBox(height: Gap.s),
                Text(insight.title,
                    style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: Gap.xs),
                Text(insight.explanation,
                    style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                if (insight.action != null && canOpen) ...[
                  const SizedBox(height: Gap.s),
                  // Cards in one grid row share a height: keep every action
                  // link on the same baseline at the bottom of its card.
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 44)),
                    onPressed: () => context.go(insight.route!),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(insight.action!),
                  ),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
