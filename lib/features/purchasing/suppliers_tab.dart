import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'orders_tab.dart';
import 'purchasing_logic.dart';
import 'supplier_dialogs.dart';
import 'supplier_ledger.dart';
import '../../l10n/l10n.dart';

/// «Поставщики»: directory, balances, payments and order history.
class SuppliersTab extends ConsumerStatefulWidget {
  const SuppliersTab({super.key});
  @override
  ConsumerState<SuppliersTab> createState() => _SuppliersTabState();
}

class _SuppliersTabState extends ConsumerState<SuppliersTab> {
  String _q = '';
  bool _debtOnly = false;
  String? _selected;

  void _open(String id, bool wide) {
    if (wide) {
      setState(() => _selected = id);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(context.l10n.commonSupplier)),
            body: Padding(
              padding: const EdgeInsets.all(Gap.m),
              child: SupplierDetail(supplierId: id),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _create(bool wide) async {
    final id = await showSupplierForm(context);
    if (id != null && mounted) _open(id, wide);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1000;
        final list = AsyncView(
          value: ref.watch(purSuppliersProvider),
          onRetry: () => ref.invalidate(purSuppliersProvider),
          data: (all) {
            final totalDebt = all.fold<int>(0, (s, x) => s + (x.balance > 0 ? x.balance : 0));
            final q = _q.toLowerCase();
            final shown = all.where((s) {
              if (_debtOnly && s.balance <= 0) return false;
              if (q.isEmpty) return true;
              return s.name.toLowerCase().contains(q) ||
                  (s.phone ?? '').contains(q) ||
                  (s.contactPerson ?? '').toLowerCase().contains(q) ||
                  (s.taxId ?? '').contains(q);
            }).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SearchField(hint: l.commonSearch, onChanged: (v) => setState(() => _q = v)),
                    ),
                    const SizedBox(width: Gap.s),
                    FilledButton.icon(
                      onPressed: () => _create(wide),
                      icon: const Icon(Icons.add),
                      label: Text(l.commonSupplier),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.s),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Gap.s,
                  runSpacing: Gap.xs,
                  children: [
                    FilterChip(
                      label: Text(l.purDebtOnly),
                      selected: _debtOnly,
                      onSelected: (v) => setState(() => _debtOnly = v),
                    ),
                    Text(
                      l.purWeOwe(Money.format(totalDebt)),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.s),
                Expanded(
                  child: all.isEmpty
                      ? EmptyState(
                          icon: Icons.local_shipping_outlined,
                          title: l.purNoSuppliers,
                          message: l.purNoSuppliersMessage,
                          action: FilledButton(
                            onPressed: () => _create(wide),
                            child: Text(l.purAddSupplier),
                          ),
                        )
                      : shown.isEmpty
                      ? EmptyState(icon: Icons.search_off, title: l.commonNothingFound)
                      : ListView.separated(
                          itemCount: shown.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (_, i) {
                            final s = shown[i];
                            return ListTile(
                              selected: wide && s.id == _selected,
                              leading: CircleAvatar(child: Text(s.name.characters.first.toUpperCase())),
                              title: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                [?s.contactPerson, ?s.phone].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: _BalanceText(s.balance),
                              onTap: () => _open(s.id, wide),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
        if (!wide) return list;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 400, child: list),
            const VerticalDivider(width: Gap.xl),
            Expanded(
              child: _selected == null
                  ? EmptyState(icon: Icons.storefront_outlined, title: l.purSelectSupplier)
                  : SupplierDetail(
                      key: ValueKey(_selected),
                      supplierId: _selected!,
                      onDeleted: () => setState(() => _selected = null),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _BalanceText extends StatelessWidget {
  const _BalanceText(this.balance);
  final int balance;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final muted = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    if (balance == 0) return Text(l.purNoDebt, style: muted);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          Money.format(balance.abs()),
          style: t.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: balance > 0 ? AppColors.danger : AppColors.success,
          ),
        ),
        Text(balance > 0 ? l.purOurDebtLower : l.purAdvanceLower, style: muted),
      ],
    );
  }
}

class SupplierDetail extends ConsumerWidget {
  const SupplierDetail({super.key, required this.supplierId, this.onDeleted});
  final String supplierId;
  final VoidCallback? onDeleted;

  Future<void> _delete(BuildContext context, WidgetRef ref, Supplier s) async {
    final l = context.l10n;
    final ok = await confirm(
      context,
      title: l.purDeleteSupplierTitle(s.name),
      message: l.purDeleteSupplierMessage,
      ok: l.commonDelete,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final done = await runGuarded(
      context,
      () => ref.read(purchasingRepoProvider).deleteSupplier(s.id, userId: ref.read(sessionProvider)?.user.id),
      success: l.purSupplierDeleted,
    );
    if (done) {
      onDeleted?.call();
      if (onDeleted == null && context.mounted) Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final l = context.l10n;
    return AsyncView(
      value: ref.watch(purSupplierProvider(supplierId)),
      data: (s) {
        if (s == null || s.deletedAt != null) {
          return EmptyState(icon: Icons.search_off, title: l.purSupplierNotFound);
        }
        final info = [
          if (s.contactPerson != null) (Icons.person_outline, s.contactPerson!),
          if (s.phone != null) (Icons.phone_outlined, s.phone!),
          if (s.taxId != null) (Icons.badge_outlined, l.purTaxIdValue(s.taxId!)),
          if (s.address != null) (Icons.place_outlined, s.address!),
          if (s.note != null) (Icons.notes, s.note!),
        ];
        final head = <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(s.name, style: t.textTheme.headlineSmall)),
              IconButton(
                tooltip: l.commonEdit,
                onPressed: () => showSupplierForm(context, supplier: s),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: l.commonDelete,
                onPressed: () => _delete(context, ref, s),
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              ),
            ],
          ),
          for (final (icon, text) in info)
            Padding(
              padding: const EdgeInsets.only(top: Gap.xs),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: t.colorScheme.onSurfaceVariant),
                  const SizedBox(width: Gap.s),
                  Expanded(child: Text(text)),
                ],
              ),
            ),
          const SizedBox(height: Gap.m),
          Builder(
            builder: (context) {
              final debt = StatCard(
                label: s.balance >= 0 ? l.purOurDebtToSupplier : l.purAdvanceWithSupplier,
                value: Money.format(s.balance.abs()),
                icon: Icons.account_balance_wallet_outlined,
                color: s.balance > 0 ? AppColors.danger : AppColors.success,
              );
              final pay = FilledButton.icon(
                onPressed: () => showSupplierPaymentDialog(context, s),
                icon: const Icon(Icons.payments_outlined),
                label: Text(l.purPay),
              );
              final order = OutlinedButton.icon(
                onPressed: () async {
                  final id = await showPoEditor(context, supplierId: s.id);
                  if (id != null && context.mounted) pushOrderPage(context, id);
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(l.purNewOrder),
              );
              // Phones: full-width balance card and two equal buttons
              // instead of a ragged wrap.
              if (context.isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    debt,
                    const SizedBox(height: Gap.s),
                    Row(
                      children: [
                        Expanded(child: pay),
                        const SizedBox(width: Gap.s),
                        Expanded(child: order),
                      ],
                    ),
                  ],
                );
              }
              return Wrap(
                spacing: Gap.m,
                runSpacing: Gap.m,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(width: 260, child: debt),
                  pay,
                  order,
                ],
              );
            },
          ),
          const SizedBox(height: Gap.m),
        ];
        final tabBar = TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: l.purTabLedger),
            Tab(text: l.purTabOrders),
            Tab(text: l.purTabPayments),
          ],
        );
        final views = TabBarView(
          children: [
            SupplierLedgerView(supplierId: s.id),
            _Orders(supplierId: s.id),
            _Payments(supplierId: s.id),
          ],
        );
        // Phones: the header scrolls away and the tab bar stays pinned, so
        // the ledger gets the whole screen height.
        if (context.isCompact) {
          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: head),
                ),
                SliverPersistentHeader(pinned: true, delegate: _PinnedTabBar(tabBar, t.scaffoldBackgroundColor)),
              ],
              body: Padding(
                padding: const EdgeInsets.only(top: Gap.s),
                child: views,
              ),
            ),
          );
        }
        return DefaultTabController(
          length: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...head,
              tabBar,
              const SizedBox(height: Gap.s),
              Expanded(child: views),
            ],
          ),
        );
      },
    );
  }
}

class _Payments extends ConsumerWidget {
  const _Payments({required this.supplierId});
  final String supplierId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final l = context.l10n;
    final canCash = ref.watch(sessionProvider)?.can(Perm.cashInOut) ?? false;
    return AsyncView(
      value: ref.watch(purSupplierPaymentsProvider(supplierId)),
      onRetry: () => ref.invalidate(purSupplierPaymentsProvider(supplierId)),
      data: (list) => list.isEmpty
          ? EmptyState(icon: Icons.payments_outlined, title: l.purNoPaymentsYet)
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (_, i) {
                final p = list[i];
                final cancelled = p.cancelledAt != null;
                final allowed = supplierPaymentCancelAllowed(p, canCash: canCash);
                final muted = t.colorScheme.onSurfaceVariant;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    cancelled ? Icons.block : Icons.north_east,
                    color: cancelled ? muted : AppColors.success,
                  ),
                  title: Wrap(
                    spacing: Gap.s,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        Money.format(p.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cancelled ? muted : null,
                          decoration: cancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (cancelled) StatusChip(l.purCancelledFem, color: AppColors.danger),
                    ],
                  ),
                  subtitle: Text(
                    [
                      [formatDateTime(p.createdAt), paymentMethodLabelsOf(l)[p.method] ?? p.method, ?p.note].join(' · '),
                      if (cancelled)
                        l.purCancelledAt(formatDateTime(p.cancelledAt!)) +
                            (p.cancelReason == null ? '' : ': ${p.cancelReason}'),
                    ].join('\n'),
                  ),
                  trailing: cancelled
                      ? null
                      : IconButton(
                          tooltip: allowed ? l.purCancelPayment : l.purNoCashPermission,
                          onPressed: allowed ? () => cancelSupplierPaymentFlow(context, ref, p) : null,
                          icon: const Icon(Icons.undo, color: AppColors.danger),
                        ),
                );
              },
            ),
    );
  }
}

class _Orders extends ConsumerWidget {
  const _Orders({required this.supplierId});
  final String supplierId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final partly = ref.watch(purPartlyReceivedOrderIdsProvider).value ?? const <String>{};
    return AsyncView(
      value: ref.watch(purSupplierOrdersProvider(supplierId)),
      data: (list) => list.isEmpty
          ? EmptyState(icon: Icons.receipt_long_outlined, title: l.purNoOrdersYet)
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (_, i) {
                final o = list[i];
                return ListTile(
                  title: Text(l.purOrderNumber('${o.number}')),
                  subtitle: Text(formatDate(o.createdAt)),
                  // Amount right-aligned next to the status, like other lists.
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Money.format(o.total),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: Gap.m),
                      poStatusChip(poDisplayStatus(o.status, anyReceived: partly.contains(o.id))),
                    ],
                  ),
                  onTap: () => pushOrderPage(context, o.id),
                );
              },
            ),
    );
  }
}

class _PinnedTabBar extends SliverPersistentHeaderDelegate {
  _PinnedTabBar(this.bar, this.color);
  final TabBar bar;
  final Color color;

  @override
  double get minExtent => bar.preferredSize.height;
  @override
  double get maxExtent => bar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => ColoredBox(color: color, child: bar);

  @override
  bool shouldRebuild(_PinnedTabBar old) => old.bar != bar || old.color != color;
}
