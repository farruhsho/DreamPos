import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/services/sale_service.dart' show paymentMethodLabel;
import 'customer_dialogs.dart';
import 'customer_editor.dart';
import 'customer_logic.dart';
import 'customer_repo.dart';

/// Full-screen card for narrow layouts.
class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({super.key, required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Карточка клиента')),
    body: CustomerDetailView(customerId: customerId, onDeleted: () => Navigator.pop(context)),
  );
}

enum _DetailTab { sales, ledger, favorites }

class CustomerDetailView extends ConsumerStatefulWidget {
  const CustomerDetailView({super.key, required this.customerId, this.onDeleted});
  final String customerId;
  final VoidCallback? onDeleted;

  @override
  ConsumerState<CustomerDetailView> createState() => _CustomerDetailViewState();
}

class _CustomerDetailViewState extends ConsumerState<CustomerDetailView> {
  _DetailTab _tab = _DetailTab.sales;

  Future<void> _delete(Customer c) async {
    if (c.debtBalance != 0) {
      showError(
        context,
        c.debtBalance > 0
            ? 'Нельзя удалить клиента с долгом ${Money.format(c.debtBalance)}. Сначала примите оплату.'
            : 'Нельзя удалить клиента с переплатой.',
      );
      return;
    }
    final ok = await confirm(
      context,
      title: 'Удалить клиента?',
      message:
          '«${c.name}» будет скрыт из списка. История продаж сохранится.'
          '${c.bonusBalance > 0 ? '\nБонусы ${Money.format(c.bonusBalance)} будут недоступны.' : ''}',
      ok: 'Удалить',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await runGuarded(
      context,
      () => ref.read(customerRepoProvider).delete(c.id, userId: ref.read(sessionProvider)!.user.id),
      success: 'Клиент удалён',
    );
    if (done) widget.onDeleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(customerProvider(widget.customerId));
    return AsyncView<Customer?>(
      value: async,
      onRetry: () => ref.invalidate(customerProvider(widget.customerId)),
      data: (c) {
        if (c == null || c.deletedAt != null) {
          return const EmptyState(icon: Icons.person_off_outlined, title: 'Клиент не найден или удалён');
        }
        return _buildBody(c);
      },
    );
  }

  Widget _buildBody(Customer c) {
    final t = Theme.of(context);
    final session = ref.watch(sessionProvider)!;
    final overdue = ref.watch(overdueDebtsProvider).value?[c.id] ?? 0;
    final canEdit = session.can(Perm.editCustomers);
    final canPay = session.can(Perm.manageDebts) || session.can(Perm.sell);
    final canBonus = session.can(Perm.managePromotions);
    final avg = c.visits > 0 ? (c.totalSpent / c.visits).round() : 0;
    final tags = parseTags(c.tags);
    final bday = daysUntilBirthday(c.birthday, DateTime.now());

    return LayoutBuilder(
      builder: (context, box) {
        final wideKpis = box.maxWidth >= 760;
        final shortTabs = box.maxWidth < 560;
        final kpis = <Widget>[
          StatCard(label: 'Сумма покупок', value: Money.format(c.totalSpent), icon: Icons.shopping_bag_outlined),
          StatCard(label: 'Визитов', value: '${c.visits}', icon: Icons.repeat),
          StatCard(label: 'Средний чек', value: Money.format(avg), icon: Icons.receipt_outlined),
          StatCard(
            label: 'Последний визит',
            value: c.lastVisitAt == null ? '—' : formatDate(c.lastVisitAt!),
            hint: c.lastVisitAt == null ? 'Покупок ещё не было' : _ago(c.lastVisitAt!),
            icon: Icons.event_outlined,
          ),
          StatCard(
            label: 'Долг',
            value: Money.format(c.debtBalance),
            color: c.debtBalance > 0 ? AppColors.danger : AppColors.success,
            hint: overdue > 0
                ? 'Просрочено ${Money.format(overdue)}'
                : (c.debtLimit > 0 ? 'Лимит ${Money.format(c.debtLimit)}' : 'Кредит не открыт'),
            icon: Icons.account_balance_wallet_outlined,
          ),
          StatCard(
            label: 'Бонусы',
            value: Money.format(c.bonusBalance),
            color: AppColors.success,
            icon: Icons.stars_outlined,
          ),
        ];

        return ListView(
          padding: const EdgeInsets.all(Gap.l),
          children: [
            // ---- header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 28, child: Text(initials(c.name), style: t.textTheme.titleLarge)),
                const SizedBox(width: Gap.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(c.name, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: Gap.xs),
                      Wrap(
                        spacing: Gap.m,
                        runSpacing: Gap.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (c.phone != null) _InfoChip(icon: Icons.phone_outlined, text: c.phone!, copy: true),
                          if (c.email != null) _InfoChip(icon: Icons.alternate_email, text: c.email!, copy: true),
                          if (c.cardNumber != null) _InfoChip(icon: Icons.credit_card, text: c.cardNumber!, copy: true),
                          if (c.birthday != null)
                            _InfoChip(
                              icon: Icons.cake_outlined,
                              text:
                                  '${formatDate(c.birthday!)}${bday == 0
                                      ? ' · сегодня!'
                                      : bday != null && bday < 7
                                      ? ' · через $bday дн.'
                                      : ''}',
                            ),
                          if (c.discountPercent > 0)
                            StatusChip('Скидка ${formatPercent(c.discountPercent)}%', color: AppColors.info),
                          for (final tag in tags) StatusChip(tag),
                        ],
                      ),
                      if (c.note != null) ...[
                        const SizedBox(height: Gap.s),
                        Text(c.note!, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
                // Destructive action lives in an overflow menu so it never sits in
                // the same row as (or wraps under) the everyday actions.
                if (canEdit)
                  PopupMenuButton<String>(
                    tooltip: 'Ещё',
                    icon: const Icon(Icons.more_vert),
                    onSelected: (v) {
                      if (v == 'delete') _delete(c);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline, color: AppColors.danger),
                          title: Text('Удалить клиента', style: TextStyle(color: AppColors.danger)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: Gap.l),
            // ---- actions
            if (shortTabs)
              _PhoneActions(
                primary: c.debtBalance > 0
                    ? _perm(
                        canPay,
                        'Нет права принимать оплату',
                        FilledButton.icon(
                          onPressed: canPay ? () => showPayDebtDialog(context, c) : null,
                          icon: const Icon(Icons.payments_outlined),
                          label: const Text('Принять оплату долга'),
                        ),
                      )
                    : null,
                actions: [
                  (
                    Icons.edit_outlined,
                    'Изменить',
                    canEdit ? () => showCustomerEditor(context, customer: c) : null,
                    canEdit ? null : 'Нет права редактировать клиентов',
                  ),
                  if (c.debtBalance > 0)
                    (Icons.sms_outlined, 'Напомнить', () => showDebtReminderDialog(context, ref, c), null),
                  (
                    Icons.stars_outlined,
                    'Бонусы',
                    canBonus ? () => showBonusAdjustDialog(context, c) : null,
                    canBonus ? null : 'Нужно право «Акции и бонусы»',
                  ),
                ],
              )
            else
              Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [
                  if (c.debtBalance > 0)
                    _perm(
                      canPay,
                      'Нет права принимать оплату',
                      FilledButton.icon(
                        onPressed: canPay ? () => showPayDebtDialog(context, c) : null,
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Принять оплату долга'),
                      ),
                    ),
                  _perm(
                    canEdit,
                    'Нет права редактировать клиентов',
                    OutlinedButton.icon(
                      onPressed: canEdit ? () => showCustomerEditor(context, customer: c) : null,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Изменить'),
                    ),
                  ),
                  if (c.debtBalance > 0)
                    OutlinedButton.icon(
                      onPressed: () => showDebtReminderDialog(context, ref, c),
                      icon: const Icon(Icons.sms_outlined),
                      label: const Text('Напоминание'),
                    ),
                  _perm(
                    canBonus,
                    'Нужно право «Акции и бонусы»',
                    OutlinedButton.icon(
                      onPressed: canBonus ? () => showBonusAdjustDialog(context, c) : null,
                      icon: const Icon(Icons.stars_outlined),
                      label: const Text('Бонусы'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: Gap.l),
            // ---- KPIs
            if (!wideKpis)
              _KpiGrid(c: c, avg: avg, overdue: overdue, cols: box.maxWidth >= 520 ? 3 : 2)
            else
              for (var r = 0; r < kpis.length; r += 3) ...[
                if (r > 0) const SizedBox(height: Gap.s),
                // Equal-height rows: a card with a hint line no longer sticks
                // out next to its neighbours.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = r; i < r + 3; i++) ...[
                        if (i > r) const SizedBox(width: Gap.s),
                        Expanded(child: i < kpis.length ? kpis[i] : const SizedBox()),
                      ],
                    ],
                  ),
                ),
              ],
            const SizedBox(height: Gap.l),
            // Narrow panes: full-width segments with short labels, so the third
            // tab is never cut off behind a horizontal scroll.
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: shortTabs ? double.infinity : null,
                child: SegmentedButton<_DetailTab>(
                  segments: shortTabs
                      ? const [
                          ButtonSegment(value: _DetailTab.sales, label: Text('Покупки'), tooltip: 'Покупки'),
                          ButtonSegment(value: _DetailTab.ledger, label: Text('Операции'), tooltip: 'Долги и бонусы'),
                          ButtonSegment(value: _DetailTab.favorites, label: Text('Любимое'), tooltip: 'Любимые товары'),
                        ]
                      : const [
                          ButtonSegment(
                            value: _DetailTab.sales,
                            label: Text('Покупки'),
                            icon: Icon(Icons.receipt_long_outlined),
                          ),
                          ButtonSegment(
                            value: _DetailTab.ledger,
                            label: Text('Долги и бонусы'),
                            icon: Icon(Icons.history),
                          ),
                          ButtonSegment(
                            value: _DetailTab.favorites,
                            label: Text('Любимые товары'),
                            icon: Icon(Icons.favorite_border),
                          ),
                        ],
                  selected: {_tab},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
            ),
            const SizedBox(height: Gap.m),
            switch (_tab) {
              _DetailTab.sales => _SalesHistory(customerId: c.id),
              _DetailTab.ledger => _LedgerHistory(customerId: c.id),
              _DetailTab.favorites => _Favorites(customerId: c.id),
            },
          ],
        );
      },
    );
  }

  Widget _perm(bool allowed, String reason, Widget child) => allowed ? child : Tooltip(message: reason, child: child);
}

/// Phone action bar: the primary action full width, everyday actions as
/// equal-width icon tiles in one row (thumb-sized, no ragged wrapping).
class _PhoneActions extends StatelessWidget {
  const _PhoneActions({required this.primary, required this.actions});
  final Widget? primary;
  final List<(IconData, String, VoidCallback?, String?)> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (primary != null) ...[SizedBox(height: 48, child: primary), const SizedBox(height: Gap.s)],
        Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: Gap.s),
              Expanded(
                child: Tooltip(
                  message: actions[i].$4 ?? actions[i].$2,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 60),
                      padding: const EdgeInsets.symmetric(horizontal: Gap.xs, vertical: Gap.s),
                    ),
                    onPressed: actions[i].$3,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(actions[i].$1, size: 20),
                        const SizedBox(height: 4),
                        Text(actions[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Narrow layout of the six KPIs: one card with a 2- or 3-column grid, not six
/// full-width StatCards that push the history far below the fold.
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.c, required this.avg, required this.overdue, required this.cols});
  final int cols;
  final Customer c;
  final int avg;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cells = <(String, String, Color?, String?)>[
      ('Сумма покупок', Money.format(c.totalSpent), null, null),
      ('Визитов', '${c.visits}', null, null),
      ('Средний чек', Money.format(avg), null, null),
      (
        'Последний визит',
        c.lastVisitAt == null ? '—' : formatDate(c.lastVisitAt!),
        null,
        c.lastVisitAt == null ? 'покупок не было' : _ago(c.lastVisitAt!),
      ),
      (
        'Долг',
        Money.format(c.debtBalance),
        c.debtBalance > 0 ? AppColors.danger : AppColors.success,
        overdue > 0
            ? 'просрочено ${Money.format(overdue)}'
            : (c.debtLimit > 0 ? 'лимит ${Money.format(c.debtLimit)}' : 'кредит не открыт'),
      ),
      ('Бонусы', Money.format(c.bonusBalance), AppColors.success, null),
    ];
    Widget cell((String, String, Color?, String?) e) => Padding(
      padding: const EdgeInsets.all(Gap.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            e.$1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              e.$2,
              style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: e.$3),
            ),
          ),
          if (e.$4 != null)
            Text(
              e.$4!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.bodySmall?.copyWith(
                color: e.$4!.startsWith('просрочено') ? AppColors.danger : t.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
    return Card(
      child: Column(
        children: [
          for (var r = 0; r < cells.length; r += cols) ...[
            if (r > 0) const Divider(height: 1),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = r; i < r + cols && i < cells.length; i++) ...[
                    if (i > r) const VerticalDivider(width: 1),
                    Expanded(child: cell(cells[i])),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _ago(DateTime d) {
  final days = DateTime.now().difference(d).inDays;
  if (days <= 0) return 'сегодня';
  if (days == 1) return 'вчера';
  return '$days дн. назад';
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text, this.copy = false});
  final IconData icon;
  final String text;
  final bool copy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: t.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: t.textTheme.bodyMedium),
      ],
    );
    if (!copy) return row;
    return Tooltip(
      message: 'Скопировать',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: text));
          if (context.mounted) showSuccess(context, 'Скопировано: $text');
        },
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: row),
      ),
    );
  }
}

// ------------------------------------------------------------------ history

class _SalesHistory extends ConsumerWidget {
  const _SalesHistory({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<List<Sale>>(
      value: ref.watch(customerSalesProvider(customerId)),
      data: (sales) {
        if (sales.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Покупок пока нет',
            message: 'Выберите клиента на кассе, чтобы копить историю и бонусы.',
          );
        }
        return Card(
          child: Column(
            children: [
              for (final s in sales) ...[_SaleTile(sale: s), if (s != sales.last) const Divider()],
            ],
          ),
        );
      },
    );
  }
}

class _SaleTile extends ConsumerWidget {
  const _SaleTile({required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final s = sale;
    final color = switch (s.status) {
      'voided' => AppColors.danger,
      'returned' || 'partially_returned' => AppColors.warning,
      _ => AppColors.success,
    };
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text('Чек №${s.number}', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        [
          formatDateTime(s.createdAt),
          if (s.discountTotal > 0) 'скидка ${Money.format(s.discountTotal)}',
          if (s.refundedTotal > 0) 'возврат ${Money.format(s.refundedTotal)}',
        ].join(' · '),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Money.format(s.total),
            style: t.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              decoration: s.status == 'voided' ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 2),
          StatusChip(saleStatusLabel(s.status), color: color),
        ],
      ),
      childrenPadding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.m),
      children: [
        Consumer(
          builder: (context, ref, _) {
            final items = ref.watch(saleItemsProvider(s.id));
            return items.when(
              loading: () => const Padding(padding: EdgeInsets.all(Gap.m), child: LinearProgressIndicator()),
              error: (e, _) => Text(errorText(e), style: const TextStyle(color: AppColors.danger)),
              data: (list) => Column(
                children: [
                  for (final i in list)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      // Name and "qty × price" stacked so long names are not
                      // squeezed to a few pixels on phones.
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(i.productName, style: t.textTheme.bodyMedium),
                                Text(
                                  [
                                    '${Qty.format(i.qty)} × ${Money.format(i.unitPrice)}',
                                    if (i.discount > 0) 'скидка ${Money.format(i.discount)}',
                                    if (i.returnedQty > 0) 'возвращено ${Qty.format(i.returnedQty)}',
                                  ].join(' · '),
                                  style: t.textTheme.bodySmall?.copyWith(
                                    color: i.returnedQty > 0 ? AppColors.warning : t.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: Gap.m),
                          Text(Money.format(i.total), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  if (s.bonusEarned > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Начислено бонусов: ${Money.format(s.bonusEarned)}',
                        style: const TextStyle(color: AppColors.success, fontSize: 12),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LedgerHistory extends ConsumerWidget {
  const _LedgerHistory({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final now = DateTime.now();
    return AsyncView<List<LedgerEntry>>(
      value: ref.watch(customerLedgerProvider(customerId)),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(icon: Icons.history, title: 'Операций по долгу и бонусам нет');
        }
        return Card(
          child: Column(
            children: [
              for (final e in list) ...[
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (isDebtKind(e.kind) ? AppColors.danger : AppColors.success).withValues(
                      alpha: 0.12,
                    ),
                    child: Icon(
                      isDebtKind(e.kind) ? Icons.account_balance_wallet_outlined : Icons.stars_outlined,
                      color: isDebtKind(e.kind) ? AppColors.danger : AppColors.success,
                      size: 20,
                    ),
                  ),
                  title: Text(ledgerKindLabel(e.kind)),
                  subtitle: Text(
                    [
                      formatDateTime(e.createdAt),
                      if (e.paymentMethod != null) paymentMethodLabel(e.paymentMethod!),
                      if (e.dueDate != null) 'срок до ${formatDate(e.dueDate!)}',
                      if (e.note != null) e.note!,
                    ].join(' · '),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${e.amount > 0 ? '+' : ''}${Money.format(e.amount)}',
                        style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: _amountColor(e)),
                      ),
                      Text('остаток ${Money.format(e.balanceAfter)}', style: t.textTheme.bodySmall),
                      if (e.kind == 'debt_sale' && e.dueDate != null && e.dueDate!.isBefore(now))
                        const Text('срок прошёл', style: TextStyle(color: AppColors.danger, fontSize: 11)),
                    ],
                  ),
                ),
                if (e != list.last) const Divider(),
              ],
            ],
          ),
        );
      },
    );
  }

  static Color? _amountColor(LedgerEntry e) {
    if (isDebtKind(e.kind)) return e.amount > 0 ? AppColors.danger : AppColors.success;
    return e.amount > 0 ? AppColors.success : AppColors.warning;
  }
}

class _Favorites extends ConsumerWidget {
  const _Favorites({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<List<FavoriteProduct>>(
      value: ref.watch(favoriteProductsProvider(customerId)),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(icon: Icons.favorite_border, title: 'Пока нет данных о покупках');
        }
        final maxQ = list.first.qty;
        return Card(
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++)
                ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(list[i].name),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: LinearProgressIndicator(
                      value: maxQ <= 0 ? 0 : list[i].qty / maxQ,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // ListTile's trailing style is labelSmall: set the size
                      // explicitly so the money is the most prominent figure.
                      Text(
                        Money.format(list[i].total),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text('куплено ${Qty.format(list[i].qty)}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
