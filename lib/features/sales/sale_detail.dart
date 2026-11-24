// Receipt detail: header, items, payments, returns + actions
// (reprint, text preview, return, void).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/printing/receipt.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/services/sale_service.dart';
import 'return_slip.dart';
import 'return_wizard.dart';
import 'sales_logic.dart';
import 'sales_queries.dart';

/// Full-page detail for narrow screens.
class SaleDetailPage extends StatelessWidget {
  const SaleDetailPage({super.key, required this.saleId, this.focusReturnId});
  final String saleId;

  /// Opened from the returns list: that return is shown first and highlighted.
  final String? focusReturnId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(focusReturnId == null ? 'Чек' : 'Возврат')),
    body: SaleDetailView(saleId: saleId, focusReturnId: focusReturnId),
  );
}

class SaleDetailView extends ConsumerWidget {
  const SaleDetailView({super.key, required this.saleId, this.focusReturnId});
  final String saleId;
  final String? focusReturnId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(saleDetailProvider(saleId));
    return AsyncView<SaleDetail?>(
      value: async,
      onRetry: () => ref.invalidate(saleDetailProvider(saleId)),
      data: (d) => d == null
          ? const EmptyState(icon: Icons.search_off, title: 'Чек не найден')
          : _DetailBody(d: d, focusReturnId: focusReturnId),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.d, this.focusReturnId});
  final SaleDetail d;
  final String? focusReturnId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = d.sale;
    final t = Theme.of(context);
    final session = ref.watch(sessionProvider);
    final shift = ref.watch(currentShiftProvider).value;
    final canRefund = session?.can(Perm.refund) ?? false;
    final canVoid = session?.can(Perm.voidSale) ?? false;
    final voidBlock = voidBlockReason(s, shift);
    final returnBlock = !canReturnStatus(s.status)
        ? (s.status == 'voided' ? 'Чек аннулирован' : 'Все товары уже возвращены')
        : !d.hasReturnable
        ? 'Все товары уже возвращены'
        : null;

    final actions = _ActionGrid(
      children: [
        if (canRefund)
          _ActionButton(
            primary: true,
            icon: Icons.assignment_return_outlined,
            label: 'Возврат',
            disabledReason: returnBlock,
            onPressed: () => _startReturn(context, ref),
          ),
        OutlinedButton.icon(
          onPressed: () => runGuarded(context, () => printReceipt(ref.read(databaseProvider), s.id, copy: true)),
          icon: const Icon(Icons.print_outlined),
          label: const Text('Копия чека'),
        ),
        OutlinedButton.icon(
          onPressed: () => _preview(context, ref),
          icon: const Icon(Icons.text_snippet_outlined),
          label: const Text('Текст чека'),
        ),
        if (canVoid)
          _ActionButton(
            danger: true,
            icon: Icons.block,
            label: 'Аннулировать',
            disabledReason: voidBlock,
            onPressed: () => _void(context, ref),
          ),
      ],
    );

    // opened from the returns list: the selected return goes right under
    // the header instead of below the fold
    final returnsFirst = focusReturnId != null && d.returns.any((r) => r.ret.id == focusReturnId);
    final returns = SectionCard(
      title: 'Возвраты (${d.returns.length})',
      child: Column(
        children: [
          for (final r in d.returns) _ReturnBlock(r: r, units: d.units, focused: r.ret.id == focusReturnId),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(Gap.l),
      children: [
        // ---------------- header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Чек №${s.number}', style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    [formatDateTime(s.createdAt), if (d.shift != null) 'смена №${d.shift!.number}'].join(' · '),
                    style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            StatusChip(saleStatusLabel(s.status), color: saleStatusColor(s.status)),
          ],
        ),
        const SizedBox(height: Gap.m),
        actions,
        if (s.status == 'voided' && s.voidReason != null) ...[
          const SizedBox(height: Gap.m),
          InfoBanner(color: AppColors.danger, icon: Icons.block, text: 'Аннулирован: ${s.voidReason}'),
        ],
        if (returnsFirst) ...[const SizedBox(height: Gap.m), returns],
        const SizedBox(height: Gap.m),
        // ---------------- people
        SectionCard(
          title: 'Участники',
          child: Column(
            children: [
              _kv(context, 'Кассир', d.cashierName ?? '—'),
              if (d.sellerName != null && s.sellerId != s.cashierId) _kv(context, 'Продавец', d.sellerName!),
              _kv(context, 'Клиент', d.customer?.name ?? 'без клиента'),
              // own row: a phone number must never break across lines
              if ((d.customer?.phone ?? '').isNotEmpty)
                _kv(context, 'Телефон', d.customer!.phone!.replaceAll(' ', '\u00A0')),
              if (s.promoCode != null) _kv(context, 'Промокод', s.promoCode!),
              if ((s.note ?? '').isNotEmpty) _kv(context, 'Примечание', s.note!),
            ],
          ),
        ),
        const SizedBox(height: Gap.m),
        // ---------------- items
        SectionCard(
          title: 'Товары (${d.items.length})',
          child: Column(
            children: [
              for (final it in d.items) ...[
                _ItemRow(item: it, unit: d.unitOf(it)),
                if (it != d.items.last) const Divider(height: Gap.l),
              ],
            ],
          ),
        ),
        const SizedBox(height: Gap.m),
        // ---------------- totals & payments
        SectionCard(
          title: 'Оплата',
          child: Column(
            children: [
              if (s.discountTotal > 0) ...[
                _kv(context, 'Сумма без скидки', Money.format(s.subtotal)),
                _kv(context, 'Скидка', '−${Money.format(s.discountTotal)}', color: AppColors.warning),
              ],
              _kv(context, 'Итого', Money.format(s.total), bold: true),
              if (s.vatTotal > 0) _kv(context, 'в т.ч. НДС', Money.format(s.vatTotal)),
              const Divider(height: Gap.l),
              for (final p in d.payments)
                _kv(
                  context,
                  paymentMethodLabel(p.method) + (p.reference == null ? '' : ' (${p.reference})'),
                  Money.format(p.method == 'cash' ? p.amount + s.changeDue : p.amount),
                ),
              if (s.changeDue > 0) _kv(context, 'Сдача', Money.format(s.changeDue)),
              if (s.bonusEarned > 0)
                _kv(context, 'Начислено бонусов', Money.format(s.bonusEarned), color: AppColors.success),
              if (s.refundedTotal > 0 && s.status != 'voided')
                _kv(context, 'Возвращено', '−${Money.format(s.refundedTotal)}', color: AppColors.danger, bold: true),
            ],
          ),
        ),
        if (d.returns.isNotEmpty && !returnsFirst) ...[const SizedBox(height: Gap.m), returns],
      ],
    );
  }

  Future<void> _startReturn(BuildContext context, WidgetRef ref) async {
    final ret = await showReturnWizard(context, d);
    if (ret == null || !context.mounted) return;
    await showReturnDone(context, ref, ret, d.sale.number);
  }

  Future<void> _preview(BuildContext context, WidgetRef ref) async {
    try {
      final data = await ReceiptData.load(ref.read(databaseProvider), d.sale.id, copy: true);
      final text = data.toText();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.xl),
          title: Text('Чек №${d.sale.number}'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              // "paper" look; the fixed-width receipt is scaled down on
              // narrow phones instead of wrapping its columns
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.l),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Theme.of(c).colorScheme.outlineVariant),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: SelectableText(
                    text,
                    style: const TextStyle(fontFamily: AppFonts.mono, fontSize: 12.5, color: Colors.black87),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                showSuccess(c, 'Текст чека скопирован');
              },
              icon: const Icon(Icons.copy),
              label: const Text('Копировать'),
            ),
            FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Закрыть')),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _void(BuildContext context, WidgetRef ref) async {
    final reason = await promptText(context, title: 'Аннулировать чек №${d.sale.number}', label: 'Причина *');
    if (reason == null || reason.trim().isEmpty || !context.mounted) return;
    final ok = await confirm(
      context,
      title: 'Аннулировать чек?',
      message:
          'Чек №${d.sale.number} на ${Money.format(d.sale.total)} будет отменён целиком: '
          'товар вернётся на склад, оплата — по исходным способам. Действие необратимо.',
      ok: 'Аннулировать',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final shift = ref.read(currentShiftProvider).value;
    await runGuarded(
      context,
      () => ref
          .read(saleServiceProvider)
          .voidSale(d.sale.id, userId: ref.read(sessionProvider)!.user.id, reason: reason.trim(), shiftId: shift?.id),
      success: 'Чек №${d.sale.number} аннулирован',
    );
  }
}

/// Success dialog after a return: summary, print slip, warranty hint.
Future<void> showReturnDone(BuildContext context, WidgetRef ref, Return ret, int saleNumber) {
  final db = ref.read(databaseProvider);
  return showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.check_circle, color: AppColors.success, size: 40),
      title: Text('Возврат №${ret.number} оформлен'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${refundMethodHint(ret.refundMethod)}: ${Money.format(ret.total)}',
            textAlign: TextAlign.center,
            style: Theme.of(c).textTheme.titleMedium,
          ),
          if (!ret.restock) ...[
            const SizedBox(height: Gap.m),
            const Text(
              'Товар не возвращён на склад. Если это брак по гарантии — оформите гарантийную заявку.',
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        if (!ret.restock)
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              context.go('/warranty?receipt=$saleNumber');
            },
            child: const Text('Гарантийная заявка'),
          ),
        OutlinedButton.icon(
          onPressed: () => runGuarded(c, () => printReturnSlip(db, ret.id)),
          icon: const Icon(Icons.print_outlined),
          label: const Text('Акт возврата'),
        ),
        FilledButton(autofocus: true, onPressed: () => Navigator.pop(c), child: const Text('Готово')),
      ],
    ),
  );
}

Widget _kv(BuildContext context, String k, String v, {Color? color, bool bold = false}) {
  final t = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(k, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(width: Gap.m),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: TextStyle(color: color, fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.unit});
  final SaleItem item;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final it = item;
    final muted = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(it.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('${Qty.format(it.qty, unit)} × ${Money.format(it.unitPrice)}', style: muted),
              if (it.discount > 0)
                Text('скидка ${Money.format(it.discount)}', style: muted?.copyWith(color: AppColors.warning)),
              if (it.warrantyUntil != null) Text('гарантия до ${formatDate(it.warrantyUntil!)}', style: muted),
              if (it.returnedQty > 0)
                Text(
                  'возвращено ${Qty.format(it.returnedQty, unit)}',
                  style: muted?.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
        Text(Money.format(it.total), style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ReturnBlock extends StatelessWidget {
  const _ReturnBlock({required this.r, required this.units, this.focused = false});
  final ReturnWithItems r;
  final Map<String, String> units;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final muted = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    return Container(
      margin: const EdgeInsets.only(bottom: Gap.s),
      padding: const EdgeInsets.all(Gap.m),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: focused ? 0.09 : 0.05),
        borderRadius: BorderRadius.circular(10),
        border: focused ? Border.all(color: AppColors.danger.withValues(alpha: 0.5)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Возврат №${r.ret.number} · ${formatDateTime(r.ret.createdAt)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '−${Money.format(r.ret.total)}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger),
              ),
            ],
          ),
          Text(
            [
              paymentMethodLabel(r.ret.refundMethod),
              if (r.userName != null) r.userName!,
              r.ret.restock ? 'на склад' : 'без возврата на склад',
            ].join(' · '),
            style: muted,
          ),
          if ((r.ret.reason ?? '').isNotEmpty) Text('Причина: ${r.ret.reason}', style: muted),
          const SizedBox(height: Gap.xs),
          for (final (ri, name) in r.items)
            Text(
              '• $name — ${Qty.format(ri.qty, units[ri.productId])} = ${Money.format(ri.amount)}',
              style: t.textTheme.bodySmall,
            ),
          Align(
            alignment: Alignment.centerRight,
            child: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => TextButton.icon(
                  onPressed: () => runGuarded(context, () => printReturnSlip(ref.read(databaseProvider), r.ret.id)),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('Акт возврата'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.disabledReason,
    this.primary = false,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String? disabledReason;
  final bool primary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final enabled = disabledReason == null;
    final Widget b = primary
        ? FilledButton.icon(onPressed: enabled ? onPressed : null, icon: Icon(icon), label: Text(label))
        : OutlinedButton.icon(
            style: danger && enabled ? OutlinedButton.styleFrom(foregroundColor: AppColors.danger) : null,
            onPressed: enabled ? onPressed : null,
            icon: Icon(icon),
            label: Text(label),
          );
    return enabled ? b : Tooltip(message: disabledReason!, child: b);
  }
}

/// Detail actions: one row when they fit, otherwise an even two-column grid
/// (no lone button wrapping onto its own line, full-width thumb targets).
class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      if (c.maxWidth >= 600 || children.length < 3) {
        return Wrap(spacing: Gap.s, runSpacing: Gap.s, children: children);
      }
      return Column(
        children: [
          for (var i = 0; i < children.length; i += 2) ...[
            if (i > 0) const SizedBox(height: Gap.s),
            Row(
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: Gap.s),
                Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox.shrink()),
              ],
            ),
          ],
        ],
      );
    },
  );
}
