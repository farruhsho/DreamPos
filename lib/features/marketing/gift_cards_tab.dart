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
import '../../core/widgets/pickers.dart';
import '../../core/widgets/widgets.dart';
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

  Future<void> _issue() async {
    final card = await showFormDialog<GiftCard>(context,
        title: 'Выпуск сертификата', width: 540, child: const _IssueForm());
    if (card == null || !mounted) return;
    showSuccess(context, 'Сертификат ${card.code} на ${Money.format(card.initialAmount)} выпущен');
    final print = await confirm(context,
        title: 'Распечатать сертификат?', message: 'Код ${card.code}', ok: 'Печать');
    if (print && mounted) await _print(card);
  }

  Future<void> _print(GiftCard g) async {
    final store = ref.read(settingProvider('store_name')) ?? 'DreamPOS';
    await runGuarded(context, () => printGiftCard(g, store: store));
  }

  Future<void> _toggleBlock(GiftCard g, bool block) async {
    final userId = ref.read(sessionProvider)!.user.id;
    if (block) {
      final reason = await promptText(context, title: 'Заблокировать ${g.code}?', label: 'Причина');
      if (reason == null || !mounted) return;
      await runGuarded(context,
          () => ref.read(marketingRepoProvider).setGiftBlocked(g, true, userId: userId, reason: reason),
          success: 'Сертификат заблокирован');
    } else {
      await runGuarded(context, () => ref.read(marketingRepoProvider).setGiftBlocked(g, false, userId: userId),
          success: 'Сертификат разблокирован');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(giftCardsProvider);
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
            .where((g) =>
                q.isEmpty ||
                g.code.contains(q) ||
                (names[g.customerId] ?? '').toUpperCase().contains(_search.toUpperCase()))
            .toList();

        return LayoutBuilder(builder: (context, box) {
          final narrow = box.maxWidth < 600;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.l, Gap.l, Gap.l, 0),
              child: Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
                SizedBox(
                  width: narrow ? box.maxWidth - Gap.l * 2 : 260,
                  child: StatCard(
                      label: 'Активных сертификатов',
                      value: '${active.length}',
                      icon: Icons.card_giftcard,
                      color: AppColors.success),
                ),
                SizedBox(
                  width: narrow ? box.maxWidth - Gap.l * 2 : 260,
                  child: StatCard(
                      label: 'Остаток к погашению',
                      value: Money.format(outstanding),
                      hint: 'обязательства магазина',
                      icon: Icons.account_balance_outlined,
                      color: AppColors.warning),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.l, 0),
              child: Wrap(spacing: Gap.s, runSpacing: Gap.s, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SizedBox(width: 280, child: SearchField(hint: 'Код или клиент', onChanged: (v) => setState(() => _search = v))),
                FilledButton.icon(onPressed: _issue, icon: const Icon(Icons.add_card), label: const Text('Выпустить')),
                OutlinedButton.icon(
                  onPressed: () => showGiftBalanceDialog(context),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Проверить баланс'),
                ),
              ]),
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
                      onSelected: (_) => setState(() => _filter = null)),
                  for (final s in GiftStatus.values) ...[
                    const SizedBox(width: Gap.xs),
                    ChoiceChip(
                        label: Text('${s.label} ${all.where((g) => giftStatusOf(g, now) == s).length}'),
                        selected: _filter == s,
                        onSelected: (_) => setState(() => _filter = s)),
                  ],
                ],
              ),
            ),
            Expanded(
              child: all.isEmpty
                  ? EmptyState(
                      icon: Icons.card_giftcard,
                      title: 'Сертификатов пока нет',
                      message: 'Продавайте подарочные сертификаты — их можно принять в оплату на кассе.',
                      action: FilledButton.icon(
                          onPressed: _issue, icon: const Icon(Icons.add_card), label: const Text('Выпустить сертификат')),
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
                            return Card(
                              child: ListTile(
                                leading: Icon(Icons.card_giftcard, color: giftStatusColor(st)),
                                title: Wrap(spacing: Gap.s, crossAxisAlignment: WrapCrossAlignment.center, children: [
                                  SelectableText(g.code,
                                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                                  StatusChip(st.label, color: giftStatusColor(st)),
                                ]),
                                subtitle: Text([
                                  'выпущен ${formatDate(g.createdAt)}',
                                  g.expiresAt == null ? 'бессрочный' : 'до ${formatDate(g.expiresAt!)}',
                                  if (g.customerId != null) names[g.customerId] ?? 'клиент',
                                ].join(' · ')),
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text(Money.format(g.balance), style: const TextStyle(fontWeight: FontWeight.w700)),
                                    if (g.balance != g.initialAmount)
                                      Text('из ${Money.format(g.initialAmount)}', style: Theme.of(context).textTheme.bodySmall),
                                  ]),
                                  PopupMenuButton<String>(
                                    tooltip: 'Действия',
                                    onSelected: (v) {
                                      switch (v) {
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
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'print', child: Text('Печать')),
                                      const PopupMenuItem(value: 'copy', child: Text('Копировать код')),
                                      if (g.status == 'blocked')
                                        const PopupMenuItem(value: 'unblock', child: Text('Разблокировать'))
                                      else
                                        const PopupMenuItem(
                                            value: 'block',
                                            child: Text('Заблокировать', style: TextStyle(color: AppColors.danger))),
                                    ],
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
            ),
          ]);
        });
      },
    );
  }
}

// ------------------------------------------------------------------ issue

class _IssueForm extends ConsumerStatefulWidget {
  const _IssueForm();
  @override
  ConsumerState<_IssueForm> createState() => _IssueFormState();
}

class _IssueFormState extends ConsumerState<_IssueForm> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _amount = TextEditingController();
  DateTime? _expires = () {
    final n = DateTime.now();
    return DateTime(n.year + 1, n.month, n.day);
  }();
  Customer? _customer;
  String _method = 'cash';
  bool _busy = false;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _regen();
  }

  @override
  void dispose() {
    _code.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _regen() async {
    try {
      final c = await ref.read(marketingRepoProvider).generateUniqueGiftCode();
      if (mounted) {
        setState(() {
          _code.text = c;
          _codeError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _codeError = errorText(e));
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _expires ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      helpText: 'Действует до (включительно)',
    );
    if (d != null) setState(() => _expires = d);
  }

  Future<void> _submit() async {
    // Busy flag is taken before the first await: a double Enter must not
    // try to sell the certificate (and take the cash) twice.
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(marketingRepoProvider);
    try {
      if (await repo.isGiftCodeTaken(_code.text)) {
        if (mounted) {
          setState(() {
            _codeError = 'Такой код уже существует';
            _busy = false;
          });
        }
        return;
      }
      final card = await repo.issueGiftCard(
        code: _code.text,
        amount: Money.parse(_amount.text)!,
        method: _method,
        userId: ref.read(sessionProvider)!.user.id,
        expiresAt: _expires == null ? null : DateTime(_expires!.year, _expires!.month, _expires!.day, 23, 59, 59),
        customerId: _customer?.id,
        shiftId: ref.read(currentShiftProvider).value?.id,
      );
      if (mounted) Navigator.pop(context, card);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final shift = ref.watch(currentShiftProvider).value;
    final blocked = _method == 'cash' && shift == null;
    return Form(
      key: _form,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.m, Gap.xl, Gap.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, letterSpacing: 1.5),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
            ],
            decoration: InputDecoration(
              labelText: 'Код сертификата *',
              errorText: _codeError,
              helperText: 'Латинские буквы и цифры, 6–32 символа',
              suffixIcon: IconButton(tooltip: 'Сгенерировать', icon: const Icon(Icons.refresh), onPressed: _regen),
            ),
            validator: (v) {
              final c = normalizeGiftCode(v ?? '');
              if (c.length < 6) return 'Минимум 6 символов';
              if (c.length > 32) return 'Максимум 32 символа';
              return null;
            },
            onChanged: (_) {
              if (_codeError != null) setState(() => _codeError = null);
            },
          ),
          const SizedBox(height: Gap.m),
          MoneyField(
            label: 'Номинал *',
            controller: _amount,
            autofocus: true,
            required: true,
            allowZero: false,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Gap.m),
          InkWell(
            onTap: _pickExpiry,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Действует до',
                prefixIcon: const Icon(Icons.event),
                suffixIcon: _expires == null
                    ? null
                    : IconButton(
                        tooltip: 'Бессрочный', icon: const Icon(Icons.close), onPressed: () => setState(() => _expires = null)),
              ),
              child: Text(_expires == null ? 'Бессрочный' : formatDate(_expires!)),
            ),
          ),
          const SizedBox(height: Gap.m),
          InkWell(
            onTap: () async {
              final c = await pickCustomer(context);
              if (c != null) setState(() => _customer = c);
            },
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Покупатель (необязательно)',
                prefixIcon: const Icon(Icons.person_outline),
                suffixIcon: _customer == null
                    ? const Icon(Icons.search)
                    : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _customer = null)),
              ),
              child: Text(_customer?.name ?? 'Не выбран'),
            ),
          ),
          const SizedBox(height: Gap.l),
          Text('Оплата сертификата', style: t.textTheme.labelLarge),
          const SizedBox(height: Gap.s),
          Wrap(spacing: Gap.xs, runSpacing: Gap.xs, children: [
            for (final e in giftPaymentMethods.entries)
              ChoiceChip(label: Text(e.value), selected: _method == e.key, onSelected: (_) => setState(() => _method = e.key)),
          ]),
          const SizedBox(height: Gap.s),
          Text(
            switch (_method) {
              'cash' => shift == null
                  ? 'Смена закрыта: откройте смену, чтобы принять наличные.'
                  : 'Наличные будут внесены в кассу смены №${shift.number} (внесение «Продажа сертификата»).',
              'free' => 'Сертификат выдаётся бесплатно (подарок, компенсация). Операция попадёт в журнал аудита.',
              _ => 'Безналичная оплата фиксируется в журнале аудита.',
            },
            style: TextStyle(color: blocked ? AppColors.danger : t.colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: Gap.l),
          FilledButton.icon(
            onPressed: _busy || blocked ? null : _submit,
            icon: const Icon(Icons.check),
            label: const Text('Выпустить сертификат'),
          ),
        ]),
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
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
          const Text('Сертификат не найден', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
        if (g != null && st != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Gap.l),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                      child: Text(g.code,
                          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700))),
                  StatusChip(st.label, color: giftStatusColor(st)),
                ]),
                const SizedBox(height: Gap.s),
                Text(Money.format(g.balance), style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text('Номинал ${Money.format(g.initialAmount)}', style: t.textTheme.bodySmall),
                Text(g.expiresAt == null ? 'Бессрочный' : 'Действует до ${formatDate(g.expiresAt!)}',
                    style: t.textTheme.bodySmall),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ PDF

Future<pw.Document> buildGiftCardPdf(GiftCard g, {required String store}) async {
  final theme = await PdfFonts.theme();
  final mono = await PdfFonts.monoBold();
  final doc = pw.Document(theme: theme);
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a6.landscape,
    margin: const pw.EdgeInsets.all(14),
    build: (_) => pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.indigo700, width: 2),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(children: [
          pw.Expanded(child: pw.Text(store, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
          pw.Text('ПОДАРОЧНЫЙ СЕРТИФИКАТ', style: const pw.TextStyle(fontSize: 9, color: PdfColors.indigo700)),
        ]),
        pw.Spacer(),
        pw.Text(Money.format(g.initialAmount),
            style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800)),
        pw.Text(g.expiresAt == null ? 'Бессрочный' : 'Действителен до ${formatDate(g.expiresAt!)}',
            style: const pw.TextStyle(fontSize: 9)),
        pw.Spacer(),
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Expanded(
            child: pw.Text('Предъявите сертификат на кассе.\nОбмену на деньги не подлежит.',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
          ),
          pw.Column(children: [
            pw.BarcodeWidget(barcode: pw.Barcode.code128(), data: g.code, width: 150, height: 40, drawText: false),
            pw.SizedBox(height: 2),
            pw.Text(g.code, style: pw.TextStyle(font: mono, fontSize: 10, letterSpacing: 1.5)),
          ]),
        ]),
      ]),
    ),
  ));
  return doc;
}

Future<void> printGiftCard(GiftCard g, {required String store}) async {
  final doc = await buildGiftCardPdf(g, store: store);
  await Printing.layoutPdf(name: 'Сертификат ${g.code}', onLayout: (_) => doc.save());
}
