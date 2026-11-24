import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'marketing_repo.dart';

/// Read-only overview of the bonus program; editing lives in Settings.
class LoyaltyTab extends ConsumerWidget {
  const LoyaltyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final l = context.l10n;
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
        // Same 1100px cap as the promotions and gift-card tabs.
        return LayoutBuilder(
          builder: (context, outer) {
            final narrowKv = outer.maxWidth < 520;
            return Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: ListView(
                  padding: const EdgeInsets.all(Gap.l),
                  children: [
                    SectionCard(
                      title: l.mktLoyaltyProgram,
                      trailing: StatusChip(
                        enabled ? l.mktLoyaltyOn : l.mktLoyaltyOff,
                        color: enabled ? AppColors.success : AppColors.warning,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _kv(
                            t,
                            narrowKv,
                            l.mktLoyaltyEarn,
                            l.mktLoyaltyEarnValue(pct(earn)),
                          ),
                          _kv(t, narrowKv, l.mktLoyaltyRedeem, l.mktLoyaltyRedeemValue(pct(redeem))),
                          _kv(t, narrowKv, l.mktLoyaltyRate, l.mktLoyaltyRateValue(Money.format(Money.currency.factor))),
                          const SizedBox(height: Gap.s),
                          Text(
                            l.mktLoyaltyNote,
                            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: Gap.m),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Tooltip(
                              message: canSettings ? l.mktOpenSettings : l.mktNoSettingsRight,
                              child: OutlinedButton.icon(
                                onPressed: canSettings ? () => context.go('/settings') : null,
                                icon: const Icon(Icons.settings_outlined),
                                label: Text(l.mktEditInSettings),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Gap.l),
                    AsyncView<LoyaltyStats>(
                      value: stats,
                      onRetry: () => ref.invalidate(loyaltyStatsProvider),
                      data: (st) => LayoutBuilder(
                        builder: (context, box) {
                          // Phones: 2 columns without icons (four full-width cards were
                          // ~350px of scrolling); the value then fits without scaling.
                          final cols = box.maxWidth >= 1000 ? 4 : 2; // 4 columns truncate labels below ~1000px
                          // Phones: no icons and short labels, the period moves to the hint.
                          final icons = box.maxWidth >= 480;
                          final cards = [
                            StatCard(
                              label: icons ? l.mktStatLiability : l.mktStatLiabilityShort,
                              value: Money.format(st.liability),
                              hint: l.mktStatHolders('${st.holders}'),
                              icon: icons ? Icons.account_balance_outlined : null,
                              color: AppColors.warning,
                            ),
                            StatCard(
                              label: icons ? l.mktStatEarned30 : l.mktStatEarned,
                              hint: icons ? null : l.mktStat30Days,
                              value: Money.format(st.earned30),
                              icon: icons ? Icons.add_circle_outline : null,
                              color: AppColors.success,
                            ),
                            StatCard(
                              label: icons ? l.mktStatSpent30 : l.mktStatSpent,
                              hint: icons ? null : l.mktStat30Days,
                              value: Money.format(st.spent30),
                              icon: icons ? Icons.remove_circle_outline : null,
                              color: AppColors.info,
                            ),
                            StatCard(
                              label: icons ? l.mktStatAdjusted30 : l.mktStatAdjusted,
                              value: Money.format(st.adjusted30),
                              hint: icons ? l.mktStatAdjustedHint : l.mktStat30Days,
                              icon: icons ? Icons.tune : null,
                            ),
                          ];
                          final w = (box.maxWidth - Gap.s * (cols - 1)) / cols;
                          return Column(
                            children: [
                              for (var r = 0; r < cards.length; r += cols) ...[
                                if (r > 0) const SizedBox(height: Gap.s),
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      for (var i = r; i < r + cols && i < cards.length; i++) ...[
                                        if (i > r) const SizedBox(width: Gap.s),
                                        SizedBox(width: w, child: cards[i]),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Label/value row; on phones the label sits above the value so the value
  /// is not squeezed into a 150px column.
  Widget _kv(ThemeData t, bool narrow, String k, String v) {
    final label = Text(k, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant));
    final value = Text(v, style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600));
    return Padding(
      padding: EdgeInsets.symmetric(vertical: narrow ? 5 : 3),
      child: narrow
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [label, value])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 160, child: label),
                Expanded(child: value),
              ],
            ),
    );
  }
}
