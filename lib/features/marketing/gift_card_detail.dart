// Gift card detail: the card plus its sale document (D-023) with reprint and
// «Аннулировать продажу».
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/doc_number.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/printing/gift_receipt.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'gift_cards_tab.dart' show giftStatusColor, printGiftCard;
import 'gift_sales_logic.dart';
import 'marketing_repo.dart';

Future<void> showGiftCardDetail(BuildContext context, String giftCardId) => showFormDialog<void>(
  context,
  title: context.l10n.commonGiftCard,
  width: 600,
  child: GiftCardDetail(giftCardId: giftCardId),
);

Color giftSaleStatusColor(String status) => status == GiftSaleStatus.voided ? AppColors.danger : AppColors.success;

String giftPaymentsText(List<GiftCardSalePayment> pays, [AppLocalizations? l]) {
  final methods = giftPaymentMethodsIn(l ?? L.current);
  return pays.map((p) => '${methods[p.method] ?? p.method} ${Money.format(p.amount)}').join(' + ');
}

class GiftCardDetail extends ConsumerStatefulWidget {
  const GiftCardDetail({super.key, required this.giftCardId});
  final String giftCardId;

  @override
  ConsumerState<GiftCardDetail> createState() => _GiftCardDetailState();
}

class _GiftCardDetailState extends ConsumerState<GiftCardDetail> {
  bool _busy = false;

  Future<void> _guard(Future<void> Function() job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reprint(GiftCardSale sale) =>
      _guard(() => runGuarded(context, () => printGiftReceipt(ref.read(databaseProvider), sale.id, copy: true)));

  Future<void> _printBlank(GiftCard g) => _guard(
    () => runGuarded(context, () => printGiftCard(g, store: ref.read(settingProvider('store_name')) ?? 'DreamPOS')),
  );

  Future<void> _void(GiftSaleRow row) => _guard(() async {
    final sale = row.sale;
    final l = context.l10n;
    final reason = await promptText(
      context,
      title: l.mktVoidSaleTitle(docNo(sale.number, sale.deviceCode)),
      label: l.mktReasonRequired,
    );
    if (reason == null || !mounted) return;
    final ok = await confirm(
      context,
      title: l.mktVoidSaleQuestion(docNo(sale.number, sale.deviceCode)),
      message: l.mktVoidSaleMessage(row.code, Money.format(sale.amount), giftPaymentsText(row.payments, l)),
      ok: l.mktVoid,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final shift = ref.read(currentShiftProvider).value;
    await runGuarded(
      context,
      () => ref
          .read(giftCardServiceProvider)
          .voidSale(sale.id, reason: reason, userId: ref.read(sessionProvider)!.user.id, shiftId: shift?.id),
      success: l.mktSaleVoided(docNo(sale.number, sale.deviceCode)),
    );
  });

  @override
  Widget build(BuildContext context) {
    final cardAsync = ref.watch(giftCardByIdProvider(widget.giftCardId));
    return AsyncView<GiftCard?>(
      value: cardAsync,
      onRetry: () => ref.invalidate(giftCardByIdProvider(widget.giftCardId)),
      data: (g) {
        final l = context.l10n;
        if (g == null) return EmptyState(icon: Icons.search_off, title: l.errGiftNotFound);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardHeader(card: g),
              const SizedBox(height: Gap.m),
              Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _printBlank(g),
                    icon: const Icon(Icons.card_giftcard),
                    label: Text(l.mktBlank),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: g.code));
                      showSuccess(context, l.mktCodeCopied);
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(l.mktCopyCode),
                  ),
                ],
              ),
              const SizedBox(height: Gap.l),
              Text(l.mktSaleDocument, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Gap.s),
              _saleSection(g),
            ],
          ),
        );
      },
    );
  }

  Widget _saleSection(GiftCard g) {
    final async = ref.watch(giftSaleRowByCardProvider(g.id));
    return async.when(
      loading: () => const Padding(padding: EdgeInsets.all(Gap.l), child: LinearProgressIndicator()),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(giftSaleRowByCardProvider(g.id))),
      data: (row) {
        if (row == null) {
          return Text(
            context.l10n.mktNoSaleDocument,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          );
        }
        return _SaleDocument(row: row, busy: _busy, onPrint: () => _reprint(row.sale), onVoid: () => _void(row));
      },
    );
  }
}

class _CardHeader extends ConsumerWidget {
  const _CardHeader({required this.card});
  final GiftCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final l = context.l10n;
    final g = card;
    final st = giftStatusOf(g, DateTime.now());
    final names = ref.watch(customerNamesProvider).value ?? const <String, String>{};
    final meta = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SelectableText(
                groupGiftCode(g.code),
                maxLines: 1,
                style: t.textTheme.titleLarge?.copyWith(fontFamily: AppFonts.mono, fontWeight: FontWeight.w700),
              ),
            ),
            StatusChip(st.labelIn(l), color: giftStatusColor(st)),
          ],
        ),
        const SizedBox(height: Gap.s),
        Text(Money.format(g.balance), style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        Text(
          [
            l.mktFaceValueLowerAmount(Money.format(g.initialAmount)),
            g.expiresAt == null ? l.coreGiftNoExpiry : l.mktUntil(formatDate(g.expiresAt!)),
            if (g.customerId != null) names[g.customerId] ?? l.mktCustomerLower,
          ].join(' · '),
          style: meta,
        ),
      ],
    );
  }
}

class _SaleDocument extends ConsumerWidget {
  const _SaleDocument({required this.row, required this.busy, required this.onPrint, required this.onVoid});
  final GiftSaleRow row;
  final bool busy;
  final VoidCallback onPrint;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final l = context.l10n;
    final s = row.sale;
    final voided = s.status == GiftSaleStatus.voided;
    final meta = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);

    // Why «Аннулировать продажу» is disabled (tooltip), null when allowed.
    String? blocked;
    var checking = false;
    if (!voided) {
      final session = ref.watch(sessionProvider);
      final shift = ref.watch(currentShiftProvider).value;
      final reason = ref.watch(giftSaleVoidBlockReasonProvider(s.id));
      if (session == null || !session.can(Perm.voidSale)) {
        blocked = l.mktNoVoidRight;
      } else if (shift == null) {
        blocked = l.mktOpenShiftToVoid;
      } else if (reason.isLoading) {
        blocked = l.mktChecking;
        checking = true;
      } else if (reason.hasError) {
        blocked = errorText(reason.error!);
      } else {
        blocked = reason.value;
      }
    }

    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: meta)),
          Expanded(child: Text(value)),
        ],
      ),
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.mktSaleNumber(docNo(s.number, s.deviceCode)),
                    style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                StatusChip(giftSaleStatusLabel(s.status, l), color: giftSaleStatusColor(s.status)),
              ],
            ),
            const SizedBox(height: Gap.s),
            line(l.commonDate, formatDateTime(s.createdAt)),
            line(l.commonCashier, row.cashierName ?? '—'),
            line(l.commonAmount, Money.format(s.amount)),
            for (final p in row.payments)
              line(
                giftPaymentMethodsIn(l)[p.method] ?? p.method,
                [Money.format(p.amount), if (p.reference != null) '№ ${p.reference}'].join(' · '),
              ),
            if (s.changeDue > 0) line(l.commonChange, Money.format(s.changeDue)),
            if (s.note != null && s.note!.isNotEmpty) line(l.commonComment, s.note!),
            if (voided) ...[
              const SizedBox(height: Gap.s),
              Text(
                '${l.mktVoidedAt(s.voidedAt == null ? '' : formatDateTime(s.voidedAt!))}'
                '${s.voidReason == null ? '' : ' · ${s.voidReason}'}',
                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: Gap.m),
            Wrap(
              spacing: Gap.s,
              runSpacing: Gap.s,
              children: [
                OutlinedButton.icon(
                  key: const Key('gift-sale-reprint'),
                  onPressed: busy ? null : onPrint,
                  icon: const Icon(Icons.print_outlined),
                  label: Text(l.commonPrint),
                ),
                if (!voided)
                  Tooltip(
                    message: blocked ?? l.mktVoidTooltip,
                    child: FilledButton.icon(
                      key: const Key('gift-sale-void'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                      onPressed: busy || blocked != null ? null : onVoid,
                      icon: const Icon(Icons.block),
                      label: Text(l.mktVoidSale),
                    ),
                  ),
              ],
            ),
            if (!voided && blocked != null && !checking)
              Padding(
                padding: const EdgeInsets.only(top: Gap.xs),
                child: Text(blocked, style: meta),
              ),
          ],
        ),
      ),
    );
  }
}
