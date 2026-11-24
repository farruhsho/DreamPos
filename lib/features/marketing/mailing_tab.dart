import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../customers/customer_logic.dart';
import '../customers/customer_repo.dart';

/// Segments offered for campaigns.
const mailingSegments = [
  CustomerSegment.birthdays,
  CustomerSegment.sleeping,
  CustomerSegment.debtors,
  CustomerSegment.overdue,
  CustomerSegment.vip,
];

String defaultTemplate(CustomerSegment s) => switch (s) {
  CustomerSegment.birthdays => 'Здравствуйте, {name}! {store} поздравляет вас с днём рождения! Ждём вас за подарком.',
  CustomerSegment.sleeping =>
    'Здравствуйте, {name}! Давно не виделись — в {store} много новинок. Ваши бонусы: {bonus}. Ждём вас!',
  CustomerSegment.debtors ||
  CustomerSegment.overdue => 'Здравствуйте, {name}! Напоминаем, что ваш долг в {store} составляет {debt}. Спасибо!',
  CustomerSegment.vip =>
    'Здравствуйте, {name}! Вы — наш VIP-клиент. Для вас в {store} особые предложения. Ваши бонусы: {bonus}.',
  CustomerSegment.all => 'Здравствуйте, {name}! ',
};

/// Builds customer lists for manual campaigns (no SMS gateway — D-014):
/// copy phones or personalised messages to the clipboard.
class MailingTab extends ConsumerStatefulWidget {
  const MailingTab({super.key});
  @override
  ConsumerState<MailingTab> createState() => _MailingTabState();
}

class _MailingTabState extends ConsumerState<MailingTab> {
  CustomerSegment _segment = CustomerSegment.birthdays;
  late final _template = TextEditingController(text: defaultTemplate(_segment));
  final _excluded = <String>{};

  @override
  void dispose() {
    _template.dispose();
    super.dispose();
  }

  void _setSegment(CustomerSegment s) {
    setState(() {
      // Keep a text the user has written; replace only the stock template.
      final untouched = _template.text.trim().isEmpty || _template.text == defaultTemplate(_segment);
      _segment = s;
      if (untouched) _template.text = defaultTemplate(s);
      _excluded.clear();
    });
  }

  Future<void> _copy(String text, String msg) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showSuccess(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final async = ref.watch(customersListProvider);
    final overdue = ref.watch(overdueDebtsProvider).value ?? const <String, int>{};
    final store = ref.watch(settingProvider('store_name')) ?? 'наш магазин';
    final now = DateTime.now();

    return AsyncView<List<Customer>>(
      value: async,
      onRetry: () => ref.invalidate(customersListProvider),
      data: (all) {
        final list = applyCustomerQuery(
          all,
          CustomerQuery(segment: _segment),
          now: now,
          overdue: overdue,
        );
        final withPhone = list.where((c) => c.phone != null && !_excluded.contains(c.id)).toList();
        final noPhone = list.where((c) => c.phone == null).length;
        int count(CustomerSegment s) => applyCustomerQuery(
          all,
          CustomerQuery(segment: s),
          now: now,
          overdue: overdue,
        ).length;

        final controls = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Сегмент', style: t.textTheme.labelLarge),
            const SizedBox(height: Gap.s),
            Wrap(
              spacing: Gap.xs,
              runSpacing: Gap.xs,
              children: [
                for (final s in mailingSegments)
                  Tooltip(
                    message: s.hint,
                    // Counts as on the customer list, so an empty segment is
                    // visible before it is picked.
                    child: ChoiceChip(
                      label: Text('${s.label} ${count(s)}'),
                      selected: _segment == s,
                      onSelected: (_) => _setSegment(s),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Gap.l),
            TextField(
              controller: _template,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Текст сообщения', alignLabelWithHint: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Gap.xs),
            Text(
              'Подстановки: {name} — имя, {fullname}, {store}, {debt}, {bonus}, {discount}',
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: Gap.l),
            // Narrow column (phone, desktop side panel): full-width buttons
            // instead of two ragged ones.
            LayoutBuilder(
              builder: (context, bx) {
                final buttons = [
                  FilledButton.icon(
                    onPressed: withPhone.isEmpty
                        ? null
                        : () => _copy(
                            withPhone.map((c) => c.phone!).join('\n'),
                            'Скопировано телефонов: ${withPhone.length}',
                          ),
                    icon: const Icon(Icons.phone),
                    label: Text('Копировать телефоны (${withPhone.length})'),
                  ),
                  OutlinedButton.icon(
                    onPressed: withPhone.isEmpty
                        ? null
                        : () => _copy(
                            withPhone
                                .map((c) => '${c.name} — ${c.phone}\n${fillTemplate(_template.text, c, store: store)}')
                                .join('\n\n'),
                            'Скопировано сообщений: ${withPhone.length}',
                          ),
                    icon: const Icon(Icons.copy_all),
                    label: const Text('Копировать сообщения'),
                  ),
                ];
                if (bx.maxWidth >= 480) return Wrap(spacing: Gap.s, runSpacing: Gap.s, children: buttons);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buttons[0],
                    const SizedBox(height: Gap.s),
                    buttons[1],
                  ],
                );
              },
            ),
            const SizedBox(height: Gap.m),
            Container(
              padding: const EdgeInsets.all(Gap.m),
              decoration: BoxDecoration(
                color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'SMS-шлюз не подключён: скопируйте список и отправьте сообщения через мессенджер или телефон. '
                '${noPhone > 0 ? 'Без телефона: $noPhone клиент(ов) — они не попадут в список.' : ''}',
                style: t.textTheme.bodySmall,
              ),
            ),
          ],
        );

        Widget tile(Customer c) {
          final bday = daysUntilBirthday(c.birthday, now);
          return CheckboxListTile(
            value: c.phone != null && !_excluded.contains(c.id),
            onChanged: c.phone == null
                ? null
                : (v) => setState(() => v == true ? _excluded.remove(c.id) : _excluded.add(c.id)),
            title: Text(c.name),
            subtitle: Text(
              [
                c.phone ?? 'нет телефона',
                if (_segment == CustomerSegment.birthdays && bday != null) bday == 0 ? 'сегодня' : 'через $bday дн.',
                if (_segment == CustomerSegment.sleeping && c.lastVisitAt != null) 'был ${formatDate(c.lastVisitAt!)}',
                if (c.debtBalance > 0) 'долг ${Money.format(c.debtBalance)}',
                if (_segment == CustomerSegment.vip) 'покупки ${Money.format(c.totalSpent)}',
              ].join(' · '),
            ),
            secondary: (overdue[c.id] ?? 0) > 0 ? const StatusChip('просрочен', color: AppColors.danger) : null,
          );
        }

        final empty = EmptyState(icon: Icons.groups_outlined, title: 'В сегменте никого нет', message: _segment.hint);
        final header = Text('${_segment.label}: ${list.length}', style: t.textTheme.titleMedium);

        return LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth >= 900) {
              // Capped like the other marketing tabs: a 900px recipient row put
              // the checkbox far from the name.
              return Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 420,
                        child: SingleChildScrollView(padding: const EdgeInsets.all(Gap.l), child: controls),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(padding: const EdgeInsets.all(Gap.l), child: header),
                            Expanded(
                              child: list.isEmpty
                                  ? empty
                                  : ListView.separated(
                                      itemCount: list.length,
                                      separatorBuilder: (_, _) => const Divider(),
                                      itemBuilder: (_, i) => tile(list[i]),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: Gap.l),
              itemCount: list.length + 2,
              itemBuilder: (_, i) {
                if (i == 0) return Padding(padding: const EdgeInsets.all(Gap.l), child: controls);
                if (i == 1) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.l),
                    child: list.isEmpty ? empty : header,
                  );
                }
                return tile(list[i - 2]);
              },
            );
          },
        );
      },
    );
  }
}
