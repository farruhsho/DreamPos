// Receipt detail: header, items, payments, returns + actions
// (reprint, text preview, return, void).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/doc_number.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/printing/receipt.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/services/sale_service.dart';
import '../../l10n/l10n.dart';
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
    appBar: AppBar(title: Text(focusReturnId == null ? context.l10n.commonReceipt : context.l10n.commonReturn)),
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
          ? EmptyState(icon: Icons.search_off, title: context.l10n.salesReceiptNotFound)
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
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    final shift = ref.watch(currentShiftProvider).value;
    final canRefund = session?.can(Perm.refund) ?? false;
    final canVoid = session?.can(Perm.voidSale) ?? false;
    final voidBlock = voidBlockReason(s, shift);
    final returnBlock = !canReturnStatus(s.status)
        ? (s.status == 'voided' ? l.salesReceiptVoided : l.salesAllReturned)
        : !d.hasReturnable
        ? l.salesAllReturned
        : null;

    final actions = _ActionGrid(
      children: [
        if (canRefund)
          _ActionButton(
            primary: true,
            icon: Icons.assignment_return_outlined,
            label: l.commonReturn,
            disabledReason: returnBlock,
            onPressed: () => _startReturn(context, ref),
          ),
        OutlinedButton.icon(
          onPressed: () => runGuarded(context, () => printReceipt(ref.read(databaseProvider), s.id, copy: true)),
          icon: const Icon(Icons.print_outlined),
          label: Text(l.salesReceiptCopy),
        ),
        OutlinedButton.icon(
          onPressed: () => _preview(context, ref),
          icon: const Icon(Icons.text_snippet_outlined),
          label: Text(l.salesReceiptText),
        ),
        if (canVoid)
          _ActionButton(
            danger: true,
            icon: Icons.block,
            label: l.salesVoid,
            disabledReason: voidBlock,
            onPressed: () => _void(context, ref),
          ),
      ],
    );

    // opened from the returns list: the selected return goes right under
    // the header instead of below the fold
    final returnsFirst = focusReturnId != null && d.returns.any((r) => r.ret.id == focusReturnId);
    final returns = SectionCard(
      title: l.salesReturnsSection('${d.returns.length}'),
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
                  Text(l.salesReceiptNo(docNo(s.number, s.deviceCode)), style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    [formatDateTime(s.createdAt), if (d.shift != null) l.salesShiftNo(docNo(d.shift!.number, d.shift!.deviceCode))].join(' · '),
                    style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            StatusChip(saleStatusLabel(s.status, l), color: saleStatusColor(s.status)),
          ],
        ),
        const SizedBox(height: Gap.m),
        actions,
        if (s.status == 'voided' && s.voidReason != null) ...[
          const SizedBox(height: Gap.m),
          InfoBanner(color: AppColors.danger, icon: Icons.block, text: l.salesVoidedReason(s.voidReason!)),
        ],
        if (returnsFirst) ...[const SizedBox(height: Gap.m), returns],
        const SizedBox(height: Gap.m),
        // ---------------- people
        SectionCard(
          title: l.salesParticipants,
          child: Column(
            children: [
              _kv(context, l.commonCashier, d.cashierName ?? '—'),
              if (d.sellerName != null && s.sellerId != s.cashierId) _kv(context, l.salesSeller, d.sellerName!),
              _kv(context, l.commonCustomer, d.customer?.name ?? l.salesNoCustomer),
              // own row: a phone number must never break across lines
              if ((d.customer?.phone ?? '').isNotEmpty)
                _kv(context, l.commonPhone, d.customer!.phone!.replaceAll(' ', '\u00A0')),
              if (s.promoCode != null) _kv(context, l.salesPromoCode, s.promoCode!),
              if ((s.note ?? '').isNotEmpty) _kv(context, l.commonNote, s.note!),
            ],
          ),
        ),
        const SizedBox(height: Gap.m),
        // ---------------- items
        SectionCard(
          title: l.salesItemsSection('${d.items.length}'),
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
          title: l.commonPayment,
          child: Column(
            children: [
              if (s.discountTotal > 0) ...[
                _kv(context, l.salesSubtotal, Money.format(s.subtotal)),
                _kv(context, l.commonDiscount, '−${Money.format(s.discountTotal)}', color: AppColors.warning),
              ],
              _kv(context, l.commonTotal, Money.format(s.total), bold: true),
              if (s.vatTotal > 0) _kv(context, l.salesVatIncluded, Money.format(s.vatTotal)),
              const Divider(height: Gap.l),
              for (final p in d.payments)
                _kv(
                  context,
                  paymentMethodLabel(p.method, l) + (p.reference == null ? '' : ' (${p.reference})'),
                  Money.format(p.method == 'cash' ? p.amount + s.changeDue : p.amount),
                ),
              if (s.changeDue > 0) _kv(context, l.commonChange, Money.format(s.changeDue)),
              if (s.bonusEarned > 0)
                _kv(context, l.salesBonusEarned, Money.format(s.bonusEarned), color: AppColors.success),
              if (s.refundedTotal > 0 && s.status != 'voided')
                _kv(context, l.salesRefunded, '−${Money.format(s.refundedTotal)}', color: AppColors.danger, bold: true),
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
    await showReturnDone(context, ref, ret, docNo(d.sale.number, d.sale.deviceCode));
  }

  Future<void> _preview(BuildContext context, WidgetRef ref) async {
    try {
      final data = await ReceiptData.load(ref.read(databaseProvider), d.sale.id, copy: true);
      final text = data.toText();
      if (!context.mounted) return;
      final l = context.l10n;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.xl),
          title: Text(l.salesReceiptNo(docNo(d.sale.number, d.sale.deviceCode))),
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
                showSuccess(c, l.salesReceiptTextCopied);
              },
              icon: const Icon(Icons.copy),
              label: Text(l.salesCopy),
            ),
            FilledButton(onPressed: () => Navigator.pop(c), child: Text(l.commonClose)),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _void(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final reason = await promptText(
      context,
      title: l.salesVoidPromptTitle(docNo(d.sale.number, d.sale.deviceCode)),
      label: l.salesReasonRequiredLabel,
    );
    if (reason == null || reason.trim().isEmpty || !context.mounted) return;
    final ok = await confirm(
      context,
      title: l.salesVoidConfirmTitle,
      message: l.salesVoidConfirmMessage(docNo(d.sale.number, d.sale.deviceCode), Money.format(d.sale.total)),
      ok: l.salesVoid,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final shift = ref.read(currentShiftProvider).value;
    await runGuarded(
      context,
      () => ref
          .read(saleServiceProvider)
          .voidSale(d.sale.id, userId: ref.read(sessionProvider)!.user.id, reason: reason.trim(), shiftId: shift?.id),
      success: l.salesVoidDone(docNo(d.sale.number, d.sale.deviceCode)),
    );
  }
}

/// Success dialog after a return: summary, print slip, warranty hint.
/// [saleNo]: display number of the sale («15» / «A-15»).
Future<void> showReturnDone(BuildContext context, WidgetRef ref, Return ret, String saleNo) {
  final db = ref.read(databaseProvider);
  final l = context.l10n;
  return showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.check_circle, color: AppColors.success, size: 40),
      title: Text(l.salesReturnDoneTitle(docNo(ret.number, ret.deviceCode))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${refundMethodHint(ret.refundMethod, l)}: ${Money.format(ret.total)}',
            textAlign: TextAlign.center,
            style: Theme.of(c).textTheme.titleMedium,
          ),
          if (!ret.restock) ...[
            const SizedBox(height: Gap.m),
            Text(
              l.salesNotRestockedHint,
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
              context.go('/warranty?receipt=${Uri.encodeQueryComponent(saleNo)}');
            },
            child: Text(l.salesWarrantyClaim),
          ),
        OutlinedButton.icon(
          onPressed: () => runGuarded(c, () => printReturnSlip(db, ret.id)),
          icon: const Icon(Icons.print_outlined),
          label: Text(l.salesReturnSlip),
        ),
        FilledButton(autofocus: true, onPressed: () => Navigator.pop(c), child: Text(l.commonDone)),
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
    final l = context.l10n;
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
              Text('${Qty.format(it.qty, unit, l)} × ${Money.format(it.unitPrice)}', style: muted),
              if (it.discount > 0)
                Text(l.salesItemDiscount(Money.format(it.discount)), style: muted?.copyWith(color: AppColors.warning)),
              if (it.warrantyUntil != null) Text(l.salesItemWarranty(formatDate(it.warrantyUntil!)), style: muted),
              if (it.returnedQty > 0)
                Text(
                  l.salesReturnedQty(Qty.format(it.returnedQty, unit, l)),
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
    final l = context.l10n;
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
                  l.salesReturnHeader(docNo(r.ret.number, r.ret.deviceCode), formatDateTime(r.ret.createdAt)),
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
              paymentMethodLabel(r.ret.refundMethod, l),
              if (r.userName != null) r.userName!,
              r.ret.restock ? l.salesToStock : l.salesNoRestock,
            ].join(' · '),
            style: muted,
          ),
          if ((r.ret.reason ?? '').isNotEmpty) Text(l.salesReasonValue(r.ret.reason!), style: muted),
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
                  label: Text(l.salesReturnSlip),
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
