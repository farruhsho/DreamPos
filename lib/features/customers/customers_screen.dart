import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'customer_detail.dart';
import 'customer_editor.dart';
import 'customer_logic.dart';
import 'customer_repo.dart';

/// CRM: customer list with segments, master-detail card, debts and bonuses.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  CustomerQuery _q = const CustomerQuery();
  String? _selectedId;
  final _searchFocus = FocusNode();
  // Owned here so «Сбросить фильтры» also clears the visible search text.
  final _search = TextEditingController();

  static const _wideBreakpoint = 900.0;

  @override
  void dispose() {
    _searchFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _create(bool wide) async {
    final id = await showCustomerEditor(context);
    if (id == null || !mounted) return;
    showSuccess(context, 'Клиент создан');
    _open(id, wide);
  }

  void _open(String id, bool wide) {
    if (wide) {
      setState(() => _selectedId = id);
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CustomerDetailPage(customerId: id)));
    }
  }

  Future<void> _export(List<Customer> list) async {
    if (list.isEmpty) {
      showError(context, 'Нет клиентов для экспорта');
      return;
    }
    await Clipboard.setData(ClipboardData(text: customersCsv(list)));
    if (mounted) {
      showSuccess(context, 'Скопировано ${list.length} клиентов в формате CSV — вставьте в Excel');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider)!;
    final canEdit = session.can(Perm.editCustomers);
    final all = ref.watch(customersListProvider);
    final overdue = ref.watch(overdueDebtsProvider).value ?? const <String, int>{};
    final now = DateTime.now();
    final filtered = applyCustomerQuery(all.value ?? const [], _q, now: now, overdue: overdue);

    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= _wideBreakpoint;
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () => _searchFocus.requestFocus(),
          if (canEdit) const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => _create(wide),
        },
        child: PageScaffold(
          title: 'Клиенты',
          subtitle: all.hasValue ? 'Всего: ${all.value!.length}' : null,
          padding: EdgeInsets.zero,
          actions: [
            IconButton(
              tooltip: 'Скопировать текущий список в CSV (для Excel)',
              onPressed: () => _export(filtered),
              icon: const Icon(Icons.file_download_outlined),
            ),
            const SizedBox(width: Gap.xs),
            if (canEdit)
              box.maxWidth < 480
                  ? IconButton.filled(
                      tooltip: 'Новый клиент (Ctrl+N)',
                      onPressed: () => _create(wide),
                      icon: const Icon(Icons.person_add_alt))
                  : FilledButton.icon(
                      onPressed: () => _create(wide),
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Новый клиент')),
          ],
          body: AsyncView<List<Customer>>(
            value: all,
            onRetry: () => ref.invalidate(customersListProvider),
            data: (customers) {
              final list = _ListPane(
                all: customers,
                filtered: filtered,
                overdue: overdue,
                query: _q,
                onQuery: (q) => setState(() => _q = q),
                selectedId: wide ? _selectedId : null,
                onOpen: (id) => _open(id, wide),
                onCreate: canEdit ? () => _create(wide) : null,
                searchFocus: _searchFocus,
                searchController: _search,
                wide: wide,
                onReset: () {
                  _search.clear();
                  setState(() => _q = CustomerQuery(sort: _q.sort));
                },
              );
              if (!wide) return list;
              final selectedExists = _selectedId != null && customers.any((c) => c.id == _selectedId);
              return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SizedBox(width: (box.maxWidth * 0.42).clamp(400, 620), child: list),
                const VerticalDivider(width: 1),
                Expanded(
                  child: selectedExists
                      ? CustomerDetailView(
                          key: ValueKey(_selectedId),
                          customerId: _selectedId!,
                          onDeleted: () => setState(() => _selectedId = null),
                        )
                      : const EmptyState(
                          icon: Icons.person_search_outlined,
                          title: 'Выберите клиента',
                          message: 'Здесь появятся покупки, долги, бонусы и любимые товары клиента.',
                        ),
                ),
              ]);
            },
          ),
        ),
      );
    });
  }
}

class _ListPane extends StatelessWidget {
  const _ListPane({
    required this.all,
    required this.filtered,
    required this.overdue,
    required this.query,
    required this.onQuery,
    required this.selectedId,
    required this.onOpen,
    required this.onCreate,
    required this.searchFocus,
    required this.searchController,
    required this.wide,
    required this.onReset,
  });

  final List<Customer> all;
  final List<Customer> filtered;
  final Map<String, int> overdue;
  final CustomerQuery query;
  final ValueChanged<CustomerQuery> onQuery;
  final String? selectedId;
  final ValueChanged<String> onOpen;
  final VoidCallback? onCreate;
  final FocusNode searchFocus;
  final TextEditingController searchController;

  /// Master pane of the master-detail layout (mouse/tablet): segment chips
  /// wrap instead of hiding behind a horizontal strip.
  final bool wide;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final receivable = all.fold<int>(0, (s, c) => s + (c.debtBalance > 0 ? c.debtBalance : 0));
    final bonusLiability = all.fold<int>(0, (s, c) => s + c.bonusBalance);
    final overdueTotal = overdue.values.fold<int>(0, (s, v) => s + v);
    final vipMin = vipThreshold(all);
    int count(CustomerSegment s) =>
        all.where((c) => inSegment(c, s, now: now, overdue: overdue, vipMin: vipMin)).length;
    final tags = allTags(all);

    void showDebtors() =>
        onQuery(query.copyWith(segment: CustomerSegment.debtors, sort: CustomerSort.debt));
    final stats = [
      StatCard(label: 'Клиентов', value: '${all.length}', icon: Icons.people_outline),
      StatCard(
        label: 'Дебиторка',
        value: Money.format(receivable),
        icon: Icons.account_balance_wallet_outlined,
        color: receivable > 0 ? AppColors.danger : AppColors.success,
        hint: overdueTotal > 0 ? 'просрочено ${Money.format(overdueTotal)}' : null,
        onTap: showDebtors,
      ),
      StatCard(
        label: 'Бонусные обязательства',
        value: Money.format(bonusLiability),
        icon: Icons.stars_outlined,
        color: AppColors.success,
      ),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Gap.l, Gap.l, Gap.l, 0),
        // Three StatCards need ~240px each; in a phone or in the master pane
        // of the desktop layout a compact strip keeps all three visible.
        child: LayoutBuilder(
          builder: (context, box) => box.maxWidth >= 720
              ? Row(children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0) const SizedBox(width: Gap.s),
                    Expanded(child: stats[i]),
                  ],
                ])
              : _SummaryStrip(items: [
                  ('Клиентов', '${all.length}', null, null),
                  (
                    'Дебиторка',
                    Money.format(receivable),
                    receivable > 0 ? AppColors.danger : AppColors.success,
                    receivable > 0 ? showDebtors : null,
                  ),
                  ('Бонусы', Money.format(bonusLiability), AppColors.success, null),
                ], footnote: overdueTotal > 0 ? 'Просрочено ${Money.format(overdueTotal)}' : null),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.l, 0),
        child: Row(children: [
          Expanded(
            child: SearchField(
              focusNode: searchFocus,
              controller: searchController,
              hint: wide ? 'Имя, телефон или карта (Ctrl+F)' : 'Имя, телефон, карта',
              onChanged: (v) => onQuery(query.copyWith(search: v)),
              onSubmitted: (_) {
                if (filtered.length == 1) onOpen(filtered.first.id);
              },
            ),
          ),
          const SizedBox(width: Gap.s),
          PopupMenuButton<CustomerSort>(
            tooltip: 'Сортировка: ${query.sort.label}',
            icon: const Icon(Icons.sort),
            initialValue: query.sort,
            onSelected: (s) => onQuery(query.copyWith(sort: s)),
            itemBuilder: (_) => [
              for (final s in CustomerSort.values)
                CheckedPopupMenuItem(value: s, checked: s == query.sort, child: Text(s.label)),
            ],
          ),
          if (tags.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: query.tag == null ? 'Фильтр по тегу' : 'Тег: ${query.tag}',
              icon: Badge(isLabelVisible: query.tag != null, child: const Icon(Icons.sell_outlined)),
              onSelected: (t) => onQuery(query.copyWith(tag: () => t.isEmpty ? null : t)),
              itemBuilder: (_) => [
                CheckedPopupMenuItem(value: '', checked: query.tag == null, child: const Text('Все теги')),
                for (final t in tags) CheckedPopupMenuItem(value: t, checked: t == query.tag, child: Text(t)),
              ],
            ),
        ]),
      ),
      LayoutBuilder(builder: (context, box) {
        final chips = <Widget>[
          for (final s in CustomerSegment.values)
            Tooltip(
              message: s.hint,
              child: ChoiceChip(
                label: Text(s == CustomerSegment.all ? s.label : '${s.label} ${count(s)}'),
                selected: query.segment == s,
                onSelected: (_) => onQuery(query.copyWith(segment: s)),
              ),
            ),
          if (query.tag != null)
            InputChip(
              label: Text('#${query.tag}'),
              onDeleted: () => onQuery(query.copyWith(tag: () => null)),
            ),
        ];
        // Phones swipe through the segments; the master pane (mouse, tablet)
        // shows all of them — a mouse cannot scroll a horizontal strip.
        if (!wide) {
          return SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.s),
              itemCount: chips.length,
              separatorBuilder: (_, _) => const SizedBox(width: Gap.xs),
              itemBuilder: (_, i) => chips[i],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.s),
          child: Wrap(spacing: Gap.xs, runSpacing: Gap.xs, children: chips),
        );
      }),
      const Divider(),
      Expanded(child: _buildList(context, now)),
    ]);
  }

  Widget _buildList(BuildContext context, DateTime now) {
    if (all.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'Клиентов пока нет',
        message: 'Добавьте клиентов, чтобы давать скидки, начислять бонусы и продавать в долг.',
        action: onCreate == null
            ? null
            : FilledButton.icon(
                onPressed: onCreate, icon: const Icon(Icons.person_add_alt), label: const Text('Добавить клиента')),
      );
    }
    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Никого не найдено',
        message: query.search.isNotEmpty ? 'Измените запрос или сбросьте фильтры' : query.segment.hint,
        action: OutlinedButton.icon(
            onPressed: onReset, icon: const Icon(Icons.filter_alt_off_outlined), label: const Text('Сбросить фильтры')),
      );
    }
    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const Divider(indent: 72),
      itemBuilder: (context, i) => _CustomerTile(
        customer: filtered[i],
        overdue: overdue[filtered[i].id] ?? 0,
        selected: filtered[i].id == selectedId,
        now: now,
        onTap: () => onOpen(filtered[i].id),
      ),
    );
  }
}

/// Compact summary for narrow panes: three metrics in one card.
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.items, this.footnote});
  final List<(String, String, Color?, VoidCallback?)> items;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const VerticalDivider(width: 1),
              Expanded(
                child: InkWell(
                  onTap: items[i].$4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.m),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(items[i].$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(items[i].$2,
                            style: t.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700, color: items[i].$3)),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ]),
        ),
        if (footnote != null)
          Container(
            color: AppColors.danger.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.xs),
            child: Text(footnote!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ),
      ]),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.overdue,
    required this.selected,
    required this.now,
    required this.onTap,
  });

  final Customer customer;
  final int overdue;
  final bool selected;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = customer;
    final bday = daysUntilBirthday(c.birthday, now);
    final line1 = [
      if (c.phone != null) c.phone!,
      if (c.cardNumber != null) 'карта ${c.cardNumber}',
      if (c.discountPercent > 0) 'скидка ${formatPercent(c.discountPercent)}%',
    ].join(' · ');
    final line2 = [
      'покупки ${Money.format(c.totalSpent)}',
      '${c.visits} виз.',
      c.lastVisitAt == null ? 'не покупал' : 'был ${formatDate(c.lastVisitAt!)}',
    ].join(' · ');
    return ListTile(
      selected: selected,
      selectedTileColor: t.colorScheme.primaryContainer.withValues(alpha: 0.35),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: selected ? t.colorScheme.primary : null,
        foregroundColor: selected ? t.colorScheme.onPrimary : null,
        child: Text(initials(c.name)),
      ),
      title: Row(children: [
        Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
        if (bday != null && bday < birthdayWindowDays) ...[
          const SizedBox(width: Gap.xs),
          Tooltip(
            message: bday == 0 ? 'День рождения сегодня' : 'День рождения через $bday дн.',
            child: const Icon(Icons.cake, size: 16, color: AppColors.warning),
          ),
        ],
      ]),
      // Each line ellipsizes on its own, so a long phone/card line never
      // pushes the purchases summary out of a narrow master pane.
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (line1.isNotEmpty) Text(line1, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(line2, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
      isThreeLine: line1.isNotEmpty,
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (c.debtBalance > 0)
          Text('долг ${Money.format(c.debtBalance)}',
              style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 13)),
        if (overdue > 0) const StatusChip('просрочен', color: AppColors.danger),
        if (c.bonusBalance > 0)
          Text('бонусы ${Money.format(c.bonusBalance)}',
              style: const TextStyle(color: AppColors.success, fontSize: 12)),
      ]),
    );
  }
}
