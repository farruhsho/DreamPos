import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/printing/pdf_fonts.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/permissions.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'gift_card_detail.dart';
import 'gift_sale_dialog.dart';
import 'gift_sales_list.dart';
import 'marketing_repo.dart';

Color giftStatusColor(GiftStatus s) => switch (s) {
  GiftStatus.active => AppColors.success,
  GiftStatus.used => Colors.grey,
  GiftStatus.expired => AppColors.warning,
  GiftStatus.blocked => AppColors.danger,
};

class GiftCardsTab extends ConsumerStatefulWidget {
  const GiftCardsTab({super.key});
  @override
  ConsumerState<GiftCardsTab> createState() => _GiftCardsTabState();
}

class _GiftCardsTabState extends ConsumerState<GiftCardsTab> {
  GiftStatus? _filter;
  String _search = '';

  bool _salesView = false;

  /// «Выпустить» = the shared «Продажа сертификата» flow (also on the POS).
  Future<void> _issue() => sellGiftCard(context, ref);

  Future<void> _print(GiftCard g) async {
    final store = ref.read(settingProvider('store_name')) ?? 'DreamPOS';
    await runGuarded(context, () => printGiftCard(g, store: store));
  }

  Future<void> _toggleBlock(GiftCard g, bool block) async {
    final userId = ref.read(sessionProvider)!.user.id;
    if (block) {
      final reason = await promptText(
        context,
        title: context.l10n.mktBlockTitle(g.code),
        label: context.l10n.commonReason,
      );
      if (reason == null || !mounted) return;
      await runGuarded(
        context,
        () => ref.read(marketingRepoProvider).setGiftBlocked(g, true, userId: userId, reason: reason),
        success: context.l10n.mktGiftBlockedMsg,
      );
    } else {
      await runGuarded(
        context,
        () => ref.read(marketingRepoProvider).setGiftBlocked(g, false, userId: userId),
        success: context.l10n.mktGiftUnblockedMsg,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.l, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.card_giftcard),
                      label: Text(context.l10n.mktTabGiftCards),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: Text(context.l10n.mktGiftSalesSegment),
                    ),
                  ],
                  selected: {_salesView},
                  onSelectionChanged: (v) => setState(() => _salesView = v.first),
                ),
              ),
            ),
            Expanded(child: _salesView ? const GiftSalesList() : _cards(context)),
          ],
        ),
      ),
    );
  }

  Widget _cards(BuildContext context) {
    final async = ref.watch(giftCardsProvider);
    final session = ref.watch(sessionProvider);
    final shift = ref.watch(currentShiftProvider).value;
    final l = context.l10n;
    final issueBlocked = session == null || !session.can(Perm.sell)
        ? l.mktNoSellRight
        : shift == null
        ? l.errOpenShiftToSellGift
        : null;
    final names = ref.watch(customerNamesProvider).value ?? const <String, String>{};
    final now = DateTime.now();
    return AsyncView<List<GiftCard>>(
      value: async,
      onRetry: () => ref.invalidate(giftCardsProvider),
      data: (all) {
        final active = all.where((g) => giftStatusOf(g, now) == GiftStatus.active).toList();
        final outstanding = active.fold<int>(0, (s, g) => s + g.balance);
        final q = _search.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
        final list = all
            .where((g) => _filter == null || giftStatusOf(g, now) == _filter)
            .where(
              (g) =>
                  q.isEmpty ||
                  g.code.contains(q) ||
                  (names[g.customerId] ?? '').toUpperCase().contains(_search.toUpperCase()),
            )
            .toList();

        return LayoutBuilder(
          builder: (context, box) {
            final narrow = box.maxWidth < 600;
            return Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.l, 0),
                      // Phones: two cards side by side without icons instead of
                      // two full-width cards (~170px) above the list.
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: narrow ? (box.maxWidth - Gap.l * 2 - Gap.s) / 2 : 260,
                              child: StatCard(
                                label: narrow ? l.mktStatActiveShort : l.mktStatActive,
                                value: '${active.length}',
                                hint: narrow ? l.mktStatActiveHint : null,
                                icon: narrow ? null : Icons.card_giftcard,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: Gap.s),
                            SizedBox(
                              width: narrow ? (box.maxWidth - Gap.l * 2 - Gap.s) / 2 : 260,
                              child: StatCard(
                                label: narrow ? l.mktStatOutstandingShort : l.mktStatOutstanding,
                                value: Money.format(outstanding),
                                hint: narrow ? l.mktStatOutstandingHintShort : l.mktStatOutstandingHint,
                                icon: narrow ? null : Icons.account_balance_outlined,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.l, 0),
                      child: Wrap(
                        spacing: Gap.s,
                        runSpacing: Gap.s,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: narrow ? double.infinity : 280,
                            child: SearchField(hint: l.mktGiftSearchHint, onChanged: (v) => setState(() => _search = v)),
                          ),
                          Tooltip(
                            message: issueBlocked ?? l.mktGiftSaleTooltip,
                            child: FilledButton.icon(
                              key: const Key('gift-issue'),
                              onPressed: issueBlocked == null ? _issue : null,
                              icon: const Icon(Icons.add_card),
                              label: Text(l.mktIssue),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => showGiftBalanceDialog(context),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: Text(l.mktCheckBalance),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.s),
                        children: [
                          ChoiceChip(
                            label: Text(l.mktChipAll('${all.length}')),
                            selected: _filter == null,
                            onSelected: (_) => setState(() => _filter = null),
                          ),
                          for (final s in GiftStatus.values) ...[
                            const SizedBox(width: Gap.xs),
                            ChoiceChip(
                              label: Text('${s.labelIn(l)} ${all.where((g) => giftStatusOf(g, now) == s).length}'),
                              selected: _filter == s,
                              onSelected: (_) => setState(() => _filter = s),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: all.isEmpty
                          ? EmptyState(
                              icon: Icons.card_giftcard,
                              title: l.mktGiftsEmptyTitle,
                              // a blocked call to action says why right here
                              // (a tooltip needs hover / long-press)
                              message: issueBlocked ?? l.mktGiftsEmptyMessage,
                              action: Tooltip(
                                message: issueBlocked ?? l.mktGiftSaleTooltip,
                                child: FilledButton.icon(
                                  key: const Key('gift-issue-empty'),
                                  onPressed: issueBlocked == null ? _issue : null,
                                  icon: const Icon(Icons.add_card),
                                  label: Text(l.mktIssueGift),
                                ),
                              ),
                            )
                          : list.isEmpty
                          ? EmptyState(icon: Icons.search_off, title: l.commonNothingFound)
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
                              itemCount: list.length,
                              separatorBuilder: (_, _) => const SizedBox(height: Gap.s),
                              itemBuilder: (_, i) {
                                final g = list[i];
                                final st = giftStatusOf(g, now);
                                return _GiftRow(
                                  card: g,
                                  status: st,
                                  customerName: g.customerId == null ? null : names[g.customerId] ?? l.mktCustomerLower,
                                  onTap: () => showGiftCardDetail(context, g.id),
                                  onAction: (v) {
                                    switch (v) {
                                      case 'details':
                                        showGiftCardDetail(context, g.id);
                                      case 'print':
                                        _print(g);
                                      case 'copy':
                                        Clipboard.setData(ClipboardData(text: g.code));
                                        showSuccess(context, l.mktCodeCopied);
                                      case 'block':
                                        _toggleBlock(g, true);
                                      case 'unblock':
                                        _toggleBlock(g, false);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// One certificate: code and balance on the first line (balance right-aligned
/// and as prominent as the code), status and dates below.
class _GiftRow extends StatelessWidget {
  const _GiftRow({
    required this.card,
    required this.status,
    required this.customerName,
    required this.onAction,
    required this.onTap,
  });
  final GiftCard card;
  final VoidCallback onTap;
  final GiftStatus status;
  final String? customerName;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final g = card;
    final muted = status != GiftStatus.active;
    final meta = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.xs, Gap.m),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.card_giftcard, size: 20, color: giftStatusColor(status)),
                        const SizedBox(width: Gap.s),
                        Expanded(
                          child: Text(
                            g.code,
                            maxLines: 1,
                            style: t.textTheme.titleSmall?.copyWith(
                              fontFamily: AppFonts.mono,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: Gap.s),
                        Text(
                          Money.format(g.balance),
                          style: t.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: muted ? t.colorScheme.onSurfaceVariant : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.xs),
                    Row(
                      children: [
                        StatusChip(status.labelIn(l), color: giftStatusColor(status)),
                        const SizedBox(width: Gap.s),
                        Expanded(
                          child: Text(
                            g.balance != g.initialAmount ? l.mktOfAmount(Money.format(g.initialAmount)) : l.mktFaceValueLower,
                            style: meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.xs),
                    Text(
                      [
                        l.mktIssuedOn(formatDate(g.createdAt)),
                        g.expiresAt == null ? l.mktNoExpiryLower : l.mktUntil(formatDate(g.expiresAt!)),
                        ?customerName,
                      ].join(' · '),
                      style: meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: l.commonActions,
                onSelected: onAction,
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'details', child: Text(l.mktSaleDocument)),
                  PopupMenuItem(value: 'print', child: Text(l.mktGiftBlank)),
                  PopupMenuItem(value: 'copy', child: Text(l.mktCopyCode)),
                  if (g.status == 'blocked')
                    PopupMenuItem(value: 'unblock', child: Text(l.mktUnblock))
                  else
                    PopupMenuItem(
                      value: 'block',
                      child: Text(l.mktBlock, style: const TextStyle(color: AppColors.danger)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ balance

Future<void> showGiftBalanceDialog(BuildContext context) =>
    showFormDialog<void>(context, title: context.l10n.mktGiftBalanceTitle, width: 460, child: const _BalanceCheck());

class _BalanceCheck extends ConsumerStatefulWidget {
  const _BalanceCheck();
  @override
  ConsumerState<_BalanceCheck> createState() => _BalanceCheckState();
}

class _BalanceCheckState extends ConsumerState<_BalanceCheck> {
  final _code = TextEditingController();
  GiftCard? _card;
  bool _searched = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final c = await ref.read(marketingRepoProvider).giftByCode(_code.text);
    if (mounted) {
      setState(() {
        _card = c;
        _searched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final g = _card;
    final st = g == null ? null : giftStatusOf(g, DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.m, Gap.xl, Gap.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l.mktCodeEnterOrScan,
              prefixIcon: const Icon(Icons.qr_code_scanner),
              suffixIcon: IconButton(icon: const Icon(Icons.search), tooltip: l.mktFind, onPressed: _find),
            ),
            onSubmitted: (_) => _find(),
          ),
          const SizedBox(height: Gap.l),
          if (_searched && g == null)
            Text(
              l.errGiftNotFound,
              style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
            ),
          if (g != null && st != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Gap.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            g.code,
                            style: const TextStyle(fontFamily: 'RobotoMono', fontWeight: FontWeight.w700),
                          ),
                        ),
                        StatusChip(st.labelIn(l), color: giftStatusColor(st)),
                      ],
                    ),
                    const SizedBox(height: Gap.s),
                    Text(
                      Money.format(g.balance),
                      style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(l.mktFaceValueAmount(Money.format(g.initialAmount)), style: t.textTheme.bodySmall),
                    Text(
                      g.expiresAt == null ? l.mktNoExpiry : l.mktValidUntil(formatDate(g.expiresAt!)),
                      style: t.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ PDF

Future<pw.Document> buildGiftCardPdf(GiftCard g, {required String store}) async {
  final theme = await PdfFonts.theme();
  final mono = await PdfFonts.monoBold();
  final doc = pw.Document(theme: theme);
  // a customer document: printed in the receipt language of the store
  final l = L.receipt;
  String p(String s) => L.printable(s);
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a6.landscape,
      margin: const pw.EdgeInsets.all(14),
      build: (_) => pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.indigo700, width: 2),
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(p(store), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Text(p(l.mktPdfGiftTitle), style: const pw.TextStyle(fontSize: 9, color: PdfColors.indigo700)),
              ],
            ),
            pw.Spacer(),
            pw.Text(
              Money.format(g.initialAmount),
              style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800),
            ),
            pw.Text(
              p(g.expiresAt == null ? l.mktNoExpiry : l.mktPdfValidUntil(formatDate(g.expiresAt!))),
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Spacer(),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    p(l.mktPdfGiftNote),
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                  ),
                ),
                pw.Column(
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.code128(),
                      data: g.code,
                      width: 150,
                      height: 40,
                      drawText: false,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(g.code, style: pw.TextStyle(font: mono, fontSize: 10, letterSpacing: 1.5)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return doc;
}

Future<void> printGiftCard(GiftCard g, {required String store}) async {
  final doc = await buildGiftCardPdf(g, store: store);
  await Printing.layoutPdf(name: L.current.corePrintJobGift(g.code), onLayout: (_) => doc.save());
}
