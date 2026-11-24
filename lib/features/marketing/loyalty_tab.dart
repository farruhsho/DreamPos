import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'marketing_repo.dart';

/// Read-only overview of the bonus program; editing lives in Settings.
class LoyaltyTab extends ConsumerWidget {
  const LoyaltyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final stats = ref.watch(loyaltyStatsProvider);
    final canSettings = ref.watch(sessionProvider)!.can(Perm.manageSettings);

    return AsyncView<Map<String, String>>(
      value: settings,
      data: (s) {
        final enabled = s['loyalty_enabled'] == '1';
        final earn = double.tryParse(s['loyalty_earn_percent'] ?? '') ?? 0;
        final redeem = double.tryParse(s['loyalty_max_redeem_percent'] ?? '') ?? 100;
        String pct(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
        return ListView(padding: const EdgeInsets.all(Gap.l), children: [
          SectionCard(
            title: 'Бонусная программа',
            trailing: StatusChip(enabled ? 'Включена' : 'Выключена',
                color: enabled ? AppColors.success : AppColors.warning),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _kv(t, 'Начисление', '${pct(earn)}% от оплаченной суммы (без учёта оплаты бонусами)'),
              _kv(t, 'Оплата бонусами', 'до ${pct(redeem)}% суммы чека'),
              _kv(t, 'Курс', '1 бонус = ${Money.format(Money.currency.factor)}'),
              const SizedBox(height: Gap.s),
              Text(
                'Бонусы начисляются автоматически при продаже клиенту и списываются пропорционально при возврате.',
                style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: Gap.m),
              Align(
                alignment: Alignment.centerLeft,
                child: Tooltip(
                  message: canSettings ? 'Открыть настройки' : 'Нет права изменять настройки',
                  child: OutlinedButton.icon(
                    onPressed: canSettings ? () => context.go('/settings') : null,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Изменить в настройках'),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: Gap.l),
          AsyncView<LoyaltyStats>(
            value: stats,
            onRetry: () => ref.invalidate(loyaltyStatsProvider),
            data: (st) => LayoutBuilder(builder: (context, box) {
              final cols = box.maxWidth >= 900 ? 4 : (box.maxWidth >= 480 ? 2 : 1);
              final cards = [
                StatCard(
                    label: 'Бонусные обязательства',
                    value: Money.format(st.liability),
                    hint: 'у ${st.holders} клиентов',
                    icon: Icons.account_balance_outlined,
                    color: AppColors.warning),
                StatCard(
                    label: 'Начислено за 30 дней',
                    value: Money.format(st.earned30),
                    icon: Icons.add_circle_outline,
                    color: AppColors.success),
                StatCard(
                    label: 'Списано за 30 дней',
                    value: Money.format(st.spent30),
                    icon: Icons.remove_circle_outline,
                    color: AppColors.info),
                StatCard(
                    label: 'Корректировки за 30 дней',
                    value: Money.format(st.adjusted30),
                    hint: 'вручную и при возвратах',
                    icon: Icons.tune),
              ];
              return Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
                for (final c in cards)
                  SizedBox(width: (box.maxWidth - Gap.s * (cols - 1)) / cols, child: c),
              ]);
            }),
          ),
        ]);
      },
    );
  }

  Widget _kv(ThemeData t, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 160, child: Text(k, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant))),
          Expanded(child: Text(v, style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        ]),
      );
}
