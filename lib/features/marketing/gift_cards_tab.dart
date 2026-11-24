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
      final reason = await promptText(context, title: 'Заблокировать ${g.code}?', label: 'Причина');
      if (reason == null || !mounted) return;
      await runGuarded(
        context,
        () => ref.read(marketingRepoProvider).setGiftBlocked(g, true, userId: userId, reason: reason),
        success: 'Сертификат заблокирован',
      );
    } else {
      await runGuarded(
        context,
        () => ref.read(marketingRepoProvider).setGiftBlocked(g, false, userId: userId),
        success: 'Сертификат разблокирован',
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
                  segments: const [
                    ButtonSegment(value: false, icon: Icon(Icons.card_giftcard), label: Text('Сертификаты')),
                    ButtonSegment(value: true, icon: Icon(Icons.receipt_long_outlined), label: Text('Продажи')),
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
    final issueBlocked = session == null || !session.can(Perm.sell)
        ? 'Нет права продавать'
        : shift == null
        ? 'Откройте смену, чтобы продать сертификат'
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
                                label: narrow ? 'Активных' : 'Активных сертификатов',
                                value: '${active.length}',
                                hint: narrow ? 'сертификатов' : null,
                                icon: narrow ? null : Icons.card_giftcard,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: Gap.s),
                            SizedBox(
                              width: narrow ? (box.maxWidth - Gap.l * 2 - Gap.s) / 2 : 260,
                              child: StatCard(
                                label: narrow ? 'К погашению' : 'Остаток к погашению',
                                value: Money.format(outstanding),
                                hint: narrow ? 'на сертификатах' : 'обязательства магазина',
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
                            child: SearchField(hint: 'Код или клиент', onChanged: (v) => setState(() => _search = v)),
                          ),
                          Tooltip(
                            message: issueBlocked ?? 'Продажа сертификата (аванс, не выручка)',
                            child: FilledButton.icon(
                              key: const Key('gift-issue'),
                              onPressed: issueBlocked == null ? _issue : null,
                              icon: const Icon(Icons.add_card),
                              label: const Text('Выпустить'),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => showGiftBalanceDialog(context),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Проверить баланс'),
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
                            label: Text('Все ${all.length}'),
                            selected: _filter == null,
                            onSelected: (_) => setState(() => _filter = null),
                          ),
                          for (final s in GiftStatus.values) ...[
                            const SizedBox(width: Gap.xs),
                            ChoiceChip(
                              label: Text('${s.label} ${all.where((g) => giftStatusOf(g, now) == s).length}'),
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
                              title: 'Сертификатов пока нет',
                              // a blocked call to action says why right here
                              // (a tooltip needs hover / long-press)
                              message:
                                  issueBlocked ??
                                  'Продавайте подарочные сертификаты — их можно принять в оплату на кассе.',
                              action: Tooltip(
                                message: issueBlocked ?? 'Продажа сертификата (аванс, не выручка)',
                                child: FilledButton.icon(
                                  key: const Key('gift-issue-empty'),
                                  onPressed: issueBlocked == null ? _issue : null,
                                  icon: const Icon(Icons.add_card),
                                  label: const Text('Выпустить сертификат'),
                                ),
                              ),
                            )
                          : list.isEmpty
                          ? const EmptyState(icon: Icons.search_off, title: 'Ничего не найдено')
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
                                  customerName: g.customerId == null ? null : names[g.customerId] ?? 'клиент',
                                  onTap: () => showGiftCardDetail(context, g.id),
                                  onAction: (v) {
                                    switch (v) {
                                      case 'details':
                                        showGiftCardDetail(context, g.id);
                                      case 'print':
                                        _print(g);
                                      case 'copy':
                                        Clipboard.setData(ClipboardData(text: g.code));
                                        showSuccess(context, 'Код скопирован');
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
                        StatusChip(status.label, color: giftStatusColor(status)),
                        const SizedBox(width: Gap.s),
                        Expanded(
                          child: Text(
                            g.balance != g.initialAmount ? 'из ${Money.format(g.initialAmount)}' : 'номинал',
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
                        'выпущен ${formatDate(g.createdAt)}',
                        g.expiresAt == null ? 'бессрочный' : 'до ${formatDate(g.expiresAt!)}',
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
                tooltip: 'Действия',
                onSelected: onAction,
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'details', child: Text('Документ продажи')),
                  const PopupMenuItem(value: 'print', child: Text('Бланк сертификата')),
                  const PopupMenuItem(value: 'copy', child: Text('Копировать код')),
                  if (g.status == 'blocked')
                    const PopupMenuItem(value: 'unblock', child: Text('Разблокировать'))
                  else
                    const PopupMenuItem(
                      value: 'block',
                      child: Text('Заблокировать', style: TextStyle(color: AppColors.danger)),
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
    showFormDialog<void>(context, title: 'Баланс сертификата', width: 460, child: const _BalanceCheck());

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
              labelText: 'Код (введите или отсканируйте)',
              prefixIcon: const Icon(Icons.qr_code_scanner),
              suffixIcon: IconButton(icon: const Icon(Icons.search), tooltip: 'Найти', onPressed: _find),
            ),
            onSubmitted: (_) => _find(),
          ),
          const SizedBox(height: Gap.l),
          if (_searched && g == null)
            const Text(
              'Сертификат не найден',
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
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
                        StatusChip(st.label, color: giftStatusColor(st)),
                      ],
                    ),
                    const SizedBox(height: Gap.s),
                    Text(
                      Money.format(g.balance),
                      style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text('Номинал ${Money.format(g.initialAmount)}', style: t.textTheme.bodySmall),
                    Text(
                      g.expiresAt == null ? 'Бессрочный' : 'Действует до ${formatDate(g.expiresAt!)}',
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
                  child: pw.Text(store, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Text('ПОДАРОЧНЫЙ СЕРТИФИКАТ', style: const pw.TextStyle(fontSize: 9, color: PdfColors.indigo700)),
              ],
            ),
            pw.Spacer(),
            pw.Text(
              Money.format(g.initialAmount),
              style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800),
            ),
            pw.Text(
              g.expiresAt == null ? 'Бессрочный' : 'Действителен до ${formatDate(g.expiresAt!)}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Spacer(),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'Предъявите сертификат на кассе.\nОбмену на деньги не подлежит.',
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
  await Printing.layoutPdf(name: 'Сертификат ${g.code}', onLayout: (_) => doc.save());
}
