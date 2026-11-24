// Warranty claim card: data, status workflow actions, act printing, history.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'warranty_act.dart';
import 'warranty_logic.dart';
import 'warranty_repository.dart';

class ClaimDetailPage extends StatelessWidget {
  const ClaimDetailPage({super.key, required this.claimId});
  final String claimId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Гарантийная заявка')),
    body: ClaimDetailView(claimId: claimId),
  );
}

class ClaimDetailView extends ConsumerWidget {
  const ClaimDetailView({super.key, required this.claimId});
  final String claimId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncView<ClaimRow?>(
    value: ref.watch(claimProvider(claimId)),
    onRetry: () => ref.invalidate(claimProvider(claimId)),
    data: (row) => row == null ? const EmptyState(icon: Icons.search_off, title: 'Заявка не найдена') : _Body(row: row),
  );
}

class _Body extends ConsumerWidget {
  const _Body({required this.row});
  final ClaimRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final c = row.claim;
    final next = nextStatuses(c.status);
    final wState = warrantyState(row.warrantyUntil, c.createdAt);
    final history = ref.watch(claimHistoryProvider(c.id)).value ?? const [];

    return ListView(
      padding: const EdgeInsets.all(Gap.l),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Заявка №${c.number}', style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    'принята ${formatDateTime(c.createdAt)}${row.userName == null ? '' : ' · ${row.userName}'}',
                    style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            StatusChip(warrantyStatusLabel(c.status), color: warrantyStatusColor(c.status)),
          ],
        ),
        const SizedBox(height: Gap.m),
        Wrap(
          spacing: Gap.s,
          runSpacing: Gap.s,
          children: [
            for (final (i, s) in next.indexed)
              i == 0
                  ? FilledButton.icon(
                      onPressed: () => _change(context, ref, s),
                      icon: Icon(warrantyActionIcon(s)),
                      label: Text(warrantyActionLabel(s)),
                    )
                  : OutlinedButton.icon(
                      style: s == WStatus.rejected ? OutlinedButton.styleFrom(foregroundColor: AppColors.danger) : null,
                      onPressed: () => _change(context, ref, s),
                      icon: Icon(warrantyActionIcon(s)),
                      label: Text(warrantyActionLabel(s)),
                    ),
            OutlinedButton.icon(
              onPressed: () => runGuarded(context, () => printClaimAct(ref.read(databaseProvider), row)),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Акт приёма'),
            ),
          ],
        ),
        if (c.status == WStatus.refunded) ...[const SizedBox(height: Gap.m), _RefundHint(row: row)],
        const SizedBox(height: Gap.m),
        SectionCard(
          title: 'Товар',
          child: Column(
            children: [
              _kv(context, 'Наименование', row.productName ?? '—'),
              _kv(context, 'Серийный номер', c.serialNumber ?? '—'),
              _kv(
                context,
                'Покупка',
                row.saleNumber == null ? 'без чека' : 'чек №${row.saleNumber} от ${formatDate(row.saleDate!)}',
                trailing: row.saleNumber == null
                    ? null
                    : IconButton(
                        tooltip: 'Открыть чек',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context.go('/sales?receipt=${row.saleNumber}'),
                        icon: const Icon(Icons.open_in_new, size: 18),
                      ),
              ),
              _kv(
                context,
                'Гарантия',
                switch (wState) {
                  WarrantyState.none => 'не установлена',
                  WarrantyState.active => 'до ${formatDate(row.warrantyUntil!)}',
                  WarrantyState.expired => 'истекла ${formatDate(row.warrantyUntil!)}',
                },
                color: switch (wState) {
                  WarrantyState.active => AppColors.success,
                  WarrantyState.expired => AppColors.danger,
                  WarrantyState.none => null,
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.m),
        SectionCard(
          title: 'Клиент',
          child: Column(
            children: [
              _kv(context, 'Имя', row.customerName ?? 'не указан'),
              if (row.customerPhone != null) _kv(context, 'Телефон', row.customerPhone!),
            ],
          ),
        ),
        const SizedBox(height: Gap.m),
        SectionCard(title: 'Неисправность', child: SelectableText(c.problem)),
        if ((c.resolution ?? '').isNotEmpty) ...[
          const SizedBox(height: Gap.m),
          SectionCard(title: 'Решение', child: SelectableText(c.resolution!)),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: Gap.m),
          SectionCard(
            title: 'История',
            child: Column(
              children: [
                for (final (e, user) in history)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history, size: 20),
                    title: Text(_historyTitle(e.action, e.details)),
                    subtitle: Text('${formatDateTime(e.at)}${user == null ? '' : ' · $user'}'),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _historyTitle(String action, String? details) {
    if (action == 'warranty.create') return 'Заявка принята';
    final d = details ?? '';
    final m = RegExp(r'^(\w+)→(\w+)(.*)$').firstMatch(d);
    if (m == null) return d;
    final rest = m.group(3)!.replaceFirst(RegExp(r'^;\s*'), '');
    return '${warrantyStatusLabel(m.group(1)!)} → ${warrantyStatusLabel(m.group(2)!)}'
        '${rest.isEmpty ? '' : ': $rest'}';
  }

  Future<void> _change(BuildContext context, WidgetRef ref, String to) async {
    final session = ref.read(sessionProvider)!;
    final r = await showDialog<(String, bool)>(
      context: context,
      builder: (_) =>
          _StatusDialog(row: row, to: to, canWriteOff: session.can(Perm.stockOps) && row.claim.productId != null),
    );
    if (r == null || !context.mounted) return;
    final ok = await runGuarded(
      context,
      () => ref
          .read(warrantyRepositoryProvider)
          .changeStatus(
            claimId: row.claim.id,
            to: to,
            userId: session.user.id,
            note: r.$1,
            writeOff: r.$2,
            stock: ref.read(stockServiceProvider),
          ),
      success: 'Статус: ${warrantyStatusLabel(to)}${r.$2 ? ' · 1 ед. списана' : ''}',
    );
    if (ok && to == WStatus.refunded && context.mounted) {
      final go = await confirm(
        context,
        title: 'Оформите возврат денег',
        message:
            'Деньги возвращаются только через возврат по чеку в разделе «Чеки» — '
            'так касса, склад и отчёты останутся верными. Перейти к оформлению?',
        ok: row.saleNumber == null ? 'Открыть «Чеки»' : 'Открыть чек №${row.saleNumber}',
      );
      if (go && context.mounted) {
        context.go(row.saleNumber == null ? '/sales' : '/sales?receipt=${row.saleNumber}');
      }
    }
  }
}

class _RefundHint extends StatelessWidget {
  const _RefundHint({required this.row});
  final ClaimRow row;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Gap.m),
    decoration: BoxDecoration(
      color: AppColors.info.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: AppColors.info),
        const SizedBox(width: Gap.m),
        const Expanded(child: Text('Решение — возврат денег. Оформите возврат по чеку (без возврата на склад).')),
        TextButton(
          onPressed: () => context.go(row.saleNumber == null ? '/sales' : '/sales?receipt=${row.saleNumber}'),
          child: const Text('К чеку'),
        ),
      ],
    ),
  );
}

class _StatusDialog extends StatefulWidget {
  const _StatusDialog({required this.row, required this.to, required this.canWriteOff});
  final ClaimRow row;
  final String to;
  final bool canWriteOff;

  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> {
  final _note = TextEditingController();
  final _key = GlobalKey<FormState>();
  late bool _writeOff = widget.to == WStatus.replaced && widget.canWriteOff;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool _closed = false;

  void _ok() {
    // guard: a double click must not pop the page under the dialog
    if (_closed || !_key.currentState!.validate()) return;
    _closed = true;
    Navigator.pop(context, (_note.text.trim(), _writeOff));
  }

  @override
  Widget build(BuildContext context) {
    final to = widget.to;
    final required = resolutionRequired(to);
    final hint = switch (to) {
      WStatus.inRepair => 'Сервисный центр, ориентировочный срок',
      WStatus.replaced => 'Например: заменён на новый, серийный № …',
      WStatus.refunded => 'Например: дефект подтверждён, возврат денег',
      WStatus.rejected => 'Причина отказа: следы удара, вскрытие, нарушение условий…',
      WStatus.returnedToClient => 'Кому и когда выдано',
      _ => null,
    };
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.enter, control: true): _ok},
      child: AlertDialog(
        scrollable: true,
        title: Text(warrantyActionLabel(to)),
        content: Form(
          key: _key,
          child: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Заявка №${widget.row.claim.number}: ${warrantyStatusLabel(widget.row.claim.status)} → '
                  '${warrantyStatusLabel(to)}',
                ),
                const SizedBox(height: Gap.m),
                TextFormField(
                  controller: _note,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: required ? 'Решение *' : 'Комментарий',
                    hintText: hint,
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => required && (v ?? '').trim().isEmpty ? 'Укажите решение' : null,
                ),
                if (to == WStatus.replaced) ...[
                  const SizedBox(height: Gap.s),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _writeOff,
                    onChanged: widget.canWriteOff ? (v) => setState(() => _writeOff = v ?? false) : null,
                    title: const Text('Списать 1 ед. со склада'),
                    subtitle: Text(
                      widget.canWriteOff
                          ? 'Причина: «Гарантийная замена» — выданный клиенту товар уйдёт из остатка'
                          : 'Недоступно: нет прав на складские операции или не указан товар',
                    ),
                  ),
                ],
                if (to == WStatus.refunded) ...[
                  const SizedBox(height: Gap.s),
                  const Text(
                    'Статус не двигает деньги. После сохранения оформите возврат по чеку в разделе «Чеки».',
                    style: TextStyle(color: AppColors.info),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            style: to == WStatus.rejected ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
            onPressed: _ok,
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

Widget _kv(BuildContext context, String k, String v, {Color? color, Widget? trailing}) {
  final t = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(k, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(
            v,
            style: TextStyle(fontWeight: FontWeight.w500, color: color),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
