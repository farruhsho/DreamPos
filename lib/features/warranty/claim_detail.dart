// Warranty claim card: data, status workflow actions, act printing, history.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/doc_number.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'warranty_act.dart';
import 'warranty_logic.dart';
import 'warranty_repository.dart';

class ClaimDetailPage extends StatelessWidget {
  const ClaimDetailPage({super.key, required this.claimId});
  final String claimId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.warrantyClaimTitle)),
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
    data: (row) =>
        row == null ? EmptyState(icon: Icons.search_off, title: context.l10n.warrantyClaimNotFound) : _Body(row: row),
  );
}

class _Body extends ConsumerWidget {
  const _Body({required this.row});
  final ClaimRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final l = context.l10n;
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
                  Text(
                    l.warrantyClaimNumber(docNo(c.number, c.deviceCode)),
                    style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${l.warrantyAcceptedAt(formatDateTime(c.createdAt))}'
                    '${row.userName == null ? '' : ' · ${row.userName}'}',
                    style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            StatusChip(warrantyStatusLabel(c.status, l), color: warrantyStatusColor(c.status)),
          ],
        ),
        const SizedBox(height: Gap.m),
        _ActionGrid(
          children: [
            for (final (i, s) in next.indexed)
              i == 0
                  ? FilledButton.icon(
                      onPressed: () => _change(context, ref, s),
                      icon: Icon(warrantyActionIcon(s)),
                      label: Text(warrantyActionLabel(s, l)),
                    )
                  : OutlinedButton.icon(
                      style: s == WStatus.rejected ? OutlinedButton.styleFrom(foregroundColor: AppColors.danger) : null,
                      onPressed: () => _change(context, ref, s),
                      icon: Icon(warrantyActionIcon(s)),
                      label: Text(warrantyActionLabel(s, l)),
                    ),
            OutlinedButton.icon(
              onPressed: () => runGuarded(context, () => printClaimAct(ref.read(databaseProvider), row)),
              icon: const Icon(Icons.print_outlined),
              label: Text(l.warrantyActButton),
            ),
          ],
        ),
        if (c.status == WStatus.refunded) ...[const SizedBox(height: Gap.m), _RefundHint(row: row)],
        const SizedBox(height: Gap.m),
        SectionCard(
          title: l.commonProduct,
          child: Column(
            children: [
              _kv(context, l.warrantyProductName, row.productName ?? '—'),
              _kv(context, l.warrantySerialNumber, c.serialNumber ?? '—'),
              _kv(
                context,
                l.warrantyPurchase,
                row.saleNumber == null
                    ? l.warrantyNoReceipt
                    : l.warrantyReceiptRef(row.saleNo!, formatDate(row.saleDate!)),
                trailing: row.saleNumber == null
                    ? null
                    : IconButton(
                        tooltip: l.warrantyOpenReceipt,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context.go('/sales?receipt=${row.saleNo}'),
                        icon: const Icon(Icons.open_in_new, size: 18),
                      ),
              ),
              _kv(
                context,
                l.warrantyWarranty,
                switch (wState) {
                  WarrantyState.none => l.warrantyNotSet,
                  WarrantyState.active => l.warrantyUntil(formatDate(row.warrantyUntil!)),
                  WarrantyState.expired => l.warrantyExpiredOn(formatDate(row.warrantyUntil!)),
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
          title: l.commonCustomer,
          child: Column(
            children: [
              _kv(context, l.commonPersonName, row.customerName ?? l.warrantyNotSpecified),
              if (row.customerPhone != null) _kv(context, l.commonPhone, row.customerPhone!),
            ],
          ),
        ),
        const SizedBox(height: Gap.m),
        SectionCard(title: l.warrantyProblem, child: SelectableText(c.problem)),
        if ((c.resolution ?? '').isNotEmpty) ...[
          const SizedBox(height: Gap.m),
          SectionCard(title: l.warrantyResolution, child: SelectableText(c.resolution!)),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: Gap.m),
          SectionCard(
            title: l.warrantyHistory,
            child: Column(
              children: [
                for (final (e, user) in history)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history, size: 20),
                    title: Text(_historyTitle(l, e.action, e.details)),
                    subtitle: Text('${formatDateTime(e.at)}${user == null ? '' : ' · $user'}'),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _historyTitle(AppLocalizations l, String action, String? details) {
    if (action == 'warranty.create') return l.warrantyHistoryCreated;
    final d = details ?? '';
    final m = RegExp(r'^(\w+)→(\w+)(.*)$').firstMatch(d);
    if (m == null) return d;
    final rest = m.group(3)!.replaceFirst(RegExp(r'^;\s*'), '');
    return '${warrantyStatusLabel(m.group(1)!, l)} → ${warrantyStatusLabel(m.group(2)!, l)}'
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
    final l = context.l10n;
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
      success: r.$2
          ? l.warrantyStatusChangedWriteOff(warrantyStatusLabel(to, l))
          : l.warrantyStatusChanged(warrantyStatusLabel(to, l)),
    );
    if (ok && to == WStatus.refunded && context.mounted) {
      final go = await confirm(
        context,
        title: l.warrantyRefundTitle,
        message: l.warrantyRefundMessage,
        ok: row.saleNumber == null ? l.warrantyOpenReceipts : l.warrantyOpenReceiptNumber(row.saleNo!),
      );
      if (go && context.mounted) {
        context.go(row.saleNumber == null ? '/sales' : '/sales?receipt=${row.saleNo}');
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
        Expanded(child: Text(context.l10n.warrantyRefundHint)),
        TextButton(
          onPressed: () => context.go(row.saleNumber == null ? '/sales' : '/sales?receipt=${row.saleNo}'),
          child: Text(context.l10n.warrantyToReceipt),
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
    final l = context.l10n;
    final required = resolutionRequired(to);
    final hint = switch (to) {
      WStatus.inRepair => l.warrantyHintInRepair,
      WStatus.replaced => l.warrantyHintReplaced,
      WStatus.refunded => l.warrantyHintRefunded,
      WStatus.rejected => l.warrantyHintRejected,
      WStatus.returnedToClient => l.warrantyHintReturned,
      _ => null,
    };
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.enter, control: true): _ok},
      child: AlertDialog(
        scrollable: true,
        title: Text(warrantyActionLabel(to, l)),
        content: Form(
          key: _key,
          child: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.warrantyTransition(
                    docNo(widget.row.claim.number, widget.row.claim.deviceCode),
                    warrantyStatusLabel(widget.row.claim.status, l),
                    warrantyStatusLabel(to, l),
                  ),
                ),
                const SizedBox(height: Gap.m),
                TextFormField(
                  controller: _note,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: required ? l.warrantyResolutionRequired : l.commonComment,
                    hintText: hint,
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => required && (v ?? '').trim().isEmpty ? l.warrantyEnterResolution : null,
                ),
                if (to == WStatus.replaced) ...[
                  const SizedBox(height: Gap.s),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _writeOff,
                    onChanged: widget.canWriteOff ? (v) => setState(() => _writeOff = v ?? false) : null,
                    title: Text(l.warrantyWriteOffOne),
                    subtitle: Text(widget.canWriteOff ? l.warrantyWriteOffHint : l.warrantyWriteOffUnavailable),
                  ),
                ],
                if (to == WStatus.refunded) ...[
                  const SizedBox(height: Gap.s),
                  Text(l.warrantyRefundNote, style: const TextStyle(color: AppColors.info)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
          FilledButton(
            style: to == WStatus.rejected ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
            onPressed: _ok,
            child: Text(l.commonSave),
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

/// Status actions: one row when they all fit; otherwise the primary action
/// gets a full-width row and the rest an even two-column grid, so no single
/// button is left dangling on its own line and phone targets stay large.
class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      if (c.maxWidth >= 860 || children.length < 3) {
        return Wrap(spacing: Gap.s, runSpacing: Gap.s, children: children);
      }
      final rest = children.sublist(1);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          children.first,
          for (var i = 0; i < rest.length; i += 2) ...[
            const SizedBox(height: Gap.s),
            Row(
              children: [
                Expanded(child: rest[i]),
                const SizedBox(width: Gap.s),
                Expanded(child: i + 1 < rest.length ? rest[i + 1] : const SizedBox.shrink()),
              ],
            ),
          ],
        ],
      );
    },
  );
}
