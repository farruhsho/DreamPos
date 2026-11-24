import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/pickers.dart';
import '../../core/widgets/widgets.dart';
import 'inventory_logic.dart';
import 'stock_dialogs.dart';

final _recentWriteOffsProvider = StreamProvider<List<StockMovement>>((ref) {
  final db = ref.watch(databaseProvider);
  final since = DateTime.now().subtract(const Duration(days: 30));
  return (db.select(db.stockMovements)
        ..where((m) => m.type.equals('writeoff') & m.createdAt.isBiggerOrEqualValue(since))
        ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
        ..limit(300))
      .watch();
});

/// «Списание»: write-off form + journal of recent write-offs.
class WriteOffTab extends ConsumerWidget {
  const WriteOffTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = SectionCard(
      title: 'Новое списание',
      child: WriteOffForm(pickProduct: () => pickProduct(context, title: 'Что списываем?')),
    );
    final recent = SectionCard(title: 'Списания за 30 дней', child: const _Recent());
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 1000) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SingleChildScrollView(child: form)),
              const SizedBox(width: Gap.l),
              Expanded(child: SingleChildScrollView(child: recent)),
            ],
          );
        }
        return ListView(
          children: [
            form,
            const SizedBox(height: Gap.l),
            recent,
          ],
        );
      },
    );
  }
}

class _Recent extends ConsumerWidget {
  const _Recent();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCost = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    final products = ref.watch(invProductMapProvider).value ?? const {};
    final users = ref.watch(invUserNamesProvider).value ?? const {};
    return AsyncView(
      value: ref.watch(_recentWriteOffsProvider),
      data: (list) {
        if (list.isEmpty) {
          return const Padding(padding: EdgeInsets.all(Gap.l), child: Text('Списаний за последние 30 дней не было'));
        }
        final total = list.fold<int>(0, (s, m) => s + lineValue(-m.qty, m.unitCost));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canCost)
              Text(
                'Всего по себестоимости: ${Money.format(total)}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger),
              ),
            const SizedBox(height: Gap.s),
            for (final m in list.take(100))
              MovementTile(
                m: m,
                unit: products[m.productId]?.unit ?? 'pcs',
                productName: products[m.productId]?.name ?? '—',
                userName: users[m.userId],
                showType: false,
              ),
          ],
        );
      },
    );
  }
}
