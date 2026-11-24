import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'orders_tab.dart';
import 'purchasing_logic.dart';
import 'supplier_dialogs.dart';

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
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Поставщик')),
          body: Padding(padding: const EdgeInsets.all(Gap.m), child: SupplierDetail(supplierId: id)),
        ),
      ));
    }
  }

  Future<void> _create(bool wide) async {
    final id = await showSupplierForm(context);
    if (id != null && mounted) _open(id, wide);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
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
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: SearchField(hint: 'Название, телефон, ИНН', onChanged: (v) => setState(() => _q = v))),
              const SizedBox(width: Gap.s),
              FilledButton.icon(onPressed: () => _create(wide), icon: const Icon(Icons.add), label: const Text('Поставщик')),
            ]),
            const SizedBox(height: Gap.s),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Gap.s,
              runSpacing: Gap.xs,
              children: [
                FilterChip(
                  label: const Text('Только с долгом'),
                  selected: _debtOnly,
                  onSelected: (v) => setState(() => _debtOnly = v),
                ),
                Text('Мы должны: ${Money.format(totalDebt)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
              ],
            ),
            const SizedBox(height: Gap.s),
            Expanded(
              child: all.isEmpty
                  ? EmptyState(
                      icon: Icons.local_shipping_outlined,
                      title: 'Поставщиков пока нет',
                      message: 'Добавьте поставщиков, чтобы вести заказы и учитывать долги',
                      action: FilledButton(onPressed: () => _create(wide), child: const Text('Добавить поставщика')))
                  : shown.isEmpty
                      ? const EmptyState(icon: Icons.search_off, title: 'Ничего не найдено')
                      : ListView.separated(
                          itemCount: shown.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (_, i) {
                            final s = shown[i];
                            return ListTile(
                              selected: wide && s.id == _selected,
                              leading: CircleAvatar(child: Text(s.name.characters.first.toUpperCase())),
                              title: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text([?s.contactPerson, ?s.phone].join(' · '),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: _BalanceText(s.balance),
                              onTap: () => _open(s.id, wide),
                            );
                          },
                        ),
            ),
          ]);
        },
      );
      if (!wide) return list;
      return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(width: 400, child: list),
        const VerticalDivider(width: Gap.xl),
        Expanded(
          child: _selected == null
              ? const EmptyState(icon: Icons.storefront_outlined, title: 'Выберите поставщика')
              : SupplierDetail(
                  key: ValueKey(_selected),
                  supplierId: _selected!,
                  onDeleted: () => setState(() => _selected = null)),
        ),
      ]);
    });
  }
}

class _BalanceText extends StatelessWidget {
  const _BalanceText(this.balance);
  final int balance;
  @override
  Widget build(BuildContext context) {
    if (balance == 0) return Text('0', style: Theme.of(context).textTheme.bodySmall);
    return Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(Money.format(balance.abs()),
          style: TextStyle(fontWeight: FontWeight.w700, color: balance > 0 ? AppColors.danger : AppColors.success)),
      Text(balance > 0 ? 'наш долг' : 'аванс', style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class SupplierDetail extends ConsumerWidget {
  const SupplierDetail({super.key, required this.supplierId, this.onDeleted});
  final String supplierId;
  final VoidCallback? onDeleted;

  Future<void> _delete(BuildContext context, WidgetRef ref, Supplier s) async {
    final ok = await confirm(context,
        title: 'Удалить поставщика «${s.name}»?',
        message: 'Поставщик будет скрыт из списков. История заказов и оплат сохранится.',
        ok: 'Удалить',
        destructive: true);
    if (!ok || !context.mounted) return;
    final done = await runGuarded(
        context, () => ref.read(purchasingRepoProvider).deleteSupplier(s.id, userId: ref.read(sessionProvider)?.user.id),
        success: 'Поставщик удалён');
    if (done) {
      onDeleted?.call();
      if (onDeleted == null && context.mounted) Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    return AsyncView(
      value: ref.watch(purSupplierProvider(supplierId)),
      data: (s) {
        if (s == null || s.deletedAt != null) {
          return const EmptyState(icon: Icons.search_off, title: 'Поставщик не найден или удалён');
        }
        final info = [
          if (s.contactPerson != null) (Icons.person_outline, s.contactPerson!),
          if (s.phone != null) (Icons.phone_outlined, s.phone!),
          if (s.taxId != null) (Icons.badge_outlined, 'ИНН ${s.taxId}'),
          if (s.address != null) (Icons.place_outlined, s.address!),
          if (s.note != null) (Icons.notes, s.note!),
        ];
        return DefaultTabController(
          length: 2,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(s.name, style: t.textTheme.headlineSmall)),
              IconButton(
                  tooltip: 'Изменить',
                  onPressed: () => showSupplierForm(context, supplier: s),
                  icon: const Icon(Icons.edit_outlined)),
              IconButton(
                  tooltip: 'Удалить',
                  onPressed: () => _delete(context, ref, s),
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger)),
            ]),
            for (final (icon, text) in info)
              Padding(
                padding: const EdgeInsets.only(top: Gap.xs),
                child: Row(children: [
                  Icon(icon, size: 18, color: t.colorScheme.onSurfaceVariant),
                  const SizedBox(width: Gap.s),
                  Expanded(child: Text(text)),
                ]),
              ),
            const SizedBox(height: Gap.m),
            Wrap(spacing: Gap.m, runSpacing: Gap.m, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SizedBox(
                width: 260,
                child: StatCard(
                  label: s.balance >= 0 ? 'Наш долг поставщику' : 'Аванс у поставщика',
                  value: Money.format(s.balance.abs()),
                  icon: Icons.account_balance_wallet_outlined,
                  color: s.balance > 0 ? AppColors.danger : AppColors.success,
                ),
              ),
              FilledButton.icon(
                  onPressed: () => showSupplierPaymentDialog(context, s),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Оплатить')),
              OutlinedButton.icon(
                  onPressed: () async {
                    final id = await showPoEditor(context, supplierId: s.id);
                    if (id != null && context.mounted) pushOrderPage(context, id);
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Новый заказ')),
            ]),
            const SizedBox(height: Gap.m),
            const TabBar(tabs: [Tab(text: 'Оплаты'), Tab(text: 'Заказы')]),
            Expanded(
              child: TabBarView(children: [
                _Payments(supplierId: s.id),
                _Orders(supplierId: s.id),
              ]),
            ),
          ]),
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
    return AsyncView(
      value: ref.watch(purSupplierPaymentsProvider(supplierId)),
      data: (list) => list.isEmpty
          ? const EmptyState(icon: Icons.payments_outlined, title: 'Оплат ещё не было')
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (_, i) {
                final p = list[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.north_east, color: AppColors.success),
                  title: Text(Money.format(p.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text([
                    formatDateTime(p.createdAt),
                    paymentMethodLabels[p.method] ?? p.method,
                    ?p.note,
                  ].join(' · ')),
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
    return AsyncView(
      value: ref.watch(purSupplierOrdersProvider(supplierId)),
      data: (list) => list.isEmpty
          ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'Заказов ещё не было')
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (_, i) {
                final o = list[i];
                return ListTile(
                  dense: true,
                  title: Text('№${o.number} · ${Money.format(o.total)}'),
                  subtitle: Text(formatDate(o.createdAt)),
                  trailing: poStatusChip(o.status),
                  onTap: () => pushOrderPage(context, o.id),
                );
              },
            ),
    );
  }
}
