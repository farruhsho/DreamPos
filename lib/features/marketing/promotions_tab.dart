import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'marketing_repo.dart';
import 'promo_simulator.dart';
import 'promotion_editor.dart';
import 'promotion_logic.dart';

Color promoStatusColor(PromoStatus s) => switch (s) {
  PromoStatus.active => AppColors.success,
  PromoStatus.scheduled => AppColors.info,
  PromoStatus.finished => Colors.grey,
  PromoStatus.disabled => AppColors.warning,
};

class PromotionsTab extends ConsumerStatefulWidget {
  const PromotionsTab({super.key});
  @override
  ConsumerState<PromotionsTab> createState() => _PromotionsTabState();
}

class _PromotionsTabState extends ConsumerState<PromotionsTab> {
  PromoStatus? _status;
  String _search = '';

  Future<void> _create() async {
    final id = await showPromotionEditor(context);
    if (id != null && mounted) showSuccess(context, context.l10n.mktPromoSaved);
  }

  Future<void> _delete(Promotion p) async {
    final ok = await confirm(
      context,
      title: context.l10n.mktDeletePromoTitle,
      message: context.l10n.mktDeletePromoMessage(p.name),
      ok: context.l10n.commonDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await runGuarded(
      context,
      () => ref.read(marketingRepoProvider).deletePromotion(p, userId: ref.read(sessionProvider)!.user.id),
      success: context.l10n.mktPromoDeleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(promotionsProvider);
    final cats = {for (final c in ref.watch(categoriesListProvider).value ?? const <Category>[]) c.id: c.name};
    final prods = ref.watch(promoProductNamesProvider).value ?? const <String, String>{};
    final now = DateTime.now();
    final l = context.l10n;

    return AsyncView<List<Promotion>>(
      value: async,
      onRetry: () => ref.invalidate(promotionsProvider),
      data: (all) {
        int count(PromoStatus s) => all.where((p) => statusOf(p, now) == s).length;
        final q = _search.toLowerCase();
        final list =
            all
                .where((p) => _status == null || statusOf(p, now) == _status)
                .where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || (p.code ?? '').toLowerCase().contains(q))
                .toList()
              // Dart's sort is not stable: tie-break by newest first so rows do
              // not jump around when the stream re-emits.
              ..sort((a, b) {
                final r = statusOf(a, now).index.compareTo(statusOf(b, now).index);
                return r != 0 ? r : b.createdAt.compareTo(a.createdAt);
              });

        // Cap the width on wide monitors: a 1400px row with the switch at
        // the far edge is hard to scan.
        return Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Gap.l, Gap.l, Gap.l, 0),
                  child: Wrap(
                    spacing: Gap.s,
                    runSpacing: Gap.s,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: context.width < 600 ? double.infinity : 320,
                        child: SearchField(
                          hint: l.mktPromoSearchHint,
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _create,
                        icon: const Icon(Icons.add),
                        label: Text(l.mktNewPromo),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => showPromoSimulator(context),
                        icon: const Icon(Icons.calculate_outlined),
                        label: Text(l.mktTestOnReceipt),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.s),
                    children: [
                      ChoiceChip(
                        label: Text(l.mktChipAll('${all.length}')),
                        selected: _status == null,
                        onSelected: (_) => setState(() => _status = null),
                      ),
                      for (final s in PromoStatus.values) ...[
                        const SizedBox(width: Gap.xs),
                        ChoiceChip(
                          label: Text('${s.labelIn(l)} ${count(s)}'),
                          selected: _status == s,
                          onSelected: (_) => setState(() => _status = s),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: all.isEmpty
                      ? EmptyState(
                          icon: Icons.campaign_outlined,
                          title: l.mktPromosEmptyTitle,
                          message: l.mktPromosEmptyMessage,
                          action: FilledButton.icon(
                            onPressed: _create,
                            icon: const Icon(Icons.add),
                            label: Text(l.mktCreatePromo),
                          ),
                        )
                      : list.isEmpty
                      ? EmptyState(icon: Icons.filter_alt_off_outlined, title: l.mktPromosNoMatch)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: Gap.s),
                          itemBuilder: (_, i) {
                            final p = list[i];
                            final target = p.type == 'percent_category' ? cats[p.targetId] : prods[p.targetId];
                            return _PromoCard(
                              promotion: p,
                              status: statusOf(p, now),
                              description: describePromo(p, targetName: target, l: l),
                              onEdit: () => showPromotionEditor(context, promotion: p),
                              onDuplicate: () => showPromotionEditor(context, promotion: p, duplicate: true),
                              onDelete: () => _delete(p),
                              onToggle: (v) => runGuarded(
                                context,
                                () => ref
                                    .read(marketingRepoProvider)
                                    .setPromotionActive(p, v, userId: ref.read(sessionProvider)!.user.id),
                              ),
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
  }
}

const _maxContentWidth = 1100.0;

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.promotion,
    required this.status,
    required this.description,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onToggle,
  });

  final Promotion promotion;
  final PromoStatus status;
  final String description;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final p = promotion;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.s, Gap.m),
          child: LayoutBuilder(
            builder: (context, box) => Row(
              children: [
                // Phones: the type icon would leave the text ~150px and wrap it
                // into four lines next to the switch; the status chip carries
                // the colour anyway.
                if (box.maxWidth >= 420) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: promoStatusColor(status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(switch (p.type) {
                      'promo_code' => Icons.local_offer_outlined,
                      'buy_x_get_y' => Icons.redeem_outlined,
                      'percent_category' => Icons.category_outlined,
                      'percent_product' => Icons.inventory_2_outlined,
                      _ => Icons.receipt_long_outlined,
                    }, color: promoStatusColor(status)),
                  ),
                  const SizedBox(width: Gap.m),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: Gap.s,
                        runSpacing: Gap.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(p.name, style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          StatusChip(status.labelIn(l), color: promoStatusColor(status)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(description, style: t.textTheme.bodyMedium),
                      Text(
                        '${promoTypeLabel(p.type, l)} · ${formatPeriod(p.startsAt, p.endsAt, l)}',
                        style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: p.isActive ? l.mktTurnOff : l.mktTurnOn,
                  child: Switch(value: p.isActive, onChanged: onToggle),
                ),
                PopupMenuButton<String>(
                  tooltip: l.commonActions,
                  onSelected: (v) => switch (v) {
                    'edit' => onEdit(),
                    'dup' => onDuplicate(),
                    _ => onDelete(),
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(leading: const Icon(Icons.edit_outlined), title: Text(l.commonEdit)),
                    ),
                    PopupMenuItem(
                      value: 'dup',
                      child: ListTile(leading: const Icon(Icons.copy), title: Text(l.mktDuplicate)),
                    ),
                    PopupMenuItem(
                      value: 'del',
                      child: ListTile(
                        leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                        title: Text(l.commonDelete, style: const TextStyle(color: AppColors.danger)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
