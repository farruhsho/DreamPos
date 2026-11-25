import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/db/database.dart';
import '../../core/doc_number.dart';
import '../../core/money.dart';
import '../../core/printing/pdf_fonts.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/services/sale_service.dart' show paymentMethodLabel;
import '../../l10n/l10n.dart';
import 'customer_logic.dart';
import 'customer_repo.dart';

/// Methods accepted for a debt payment (labels: [paymentMethodLabel]).
const debtPaymentMethods = ['cash', 'card', 'transfer'];

/// Result of an accepted debt payment (for the receipt).
class DebtPaymentInfo {
  DebtPaymentInfo({
    required this.customerName,
    required this.amount,
    required this.method,
    required this.debtBefore,
    required this.cashier,
    required this.at,
  });
  final String customerName;
  final int amount;
  final String method;
  final int debtBefore;
  final String cashier;
  final DateTime at;
  int get debtAfter => debtBefore - amount;
}

// ------------------------------------------------------------------ pay debt

Future<void> showPayDebtDialog(BuildContext context, Customer customer) async {
  final res = await showFormDialog<(DebtPaymentInfo, bool)>(context,
      title: context.l10n.custAcceptDebtPayment, width: 480, child: _PayDebtForm(customer: customer));
  if (res == null || !context.mounted) return;
  showSuccess(context, context.l10n.custPaymentAccepted(Money.format(res.$1.amount)));
  if (res.$2) {
    final store = ProviderScope.containerOf(context).read(settingProvider('store_name')) ?? 'DreamPOS';
    await runGuarded(context, () => printDebtReceipt(res.$1, store: store));
  }
}

class _PayDebtForm extends ConsumerStatefulWidget {
  const _PayDebtForm({required this.customer});
  final Customer customer;
  @override
  ConsumerState<_PayDebtForm> createState() => _PayDebtFormState();
}

class _PayDebtFormState extends ConsumerState<_PayDebtForm> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _method = 'cash';
  bool _print = true;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit(int debt) async {
    if (_busy || !_form.currentState!.validate()) return;
    final amount = Money.parse(_amount.text)!;
    final shift = ref.read(currentShiftProvider).value;
    final user = ref.read(sessionProvider)!.user;
    setState(() => _busy = true);
    try {
      await ref.read(customerServiceProvider).payDebt(
            customerId: widget.customer.id,
            amount: amount,
            method: _method,
            userId: user.id,
            shiftId: shift?.id,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      // Best effort: the payment itself is already committed.
      try {
        await ref.read(customerRepoProvider).markBalanceChanged(widget.customer.id);
      } catch (_) {}
      if (!mounted) return;
      Navigator.pop(
          context,
          (
            DebtPaymentInfo(
              customerName: widget.customer.name,
              amount: amount,
              method: _method,
              debtBefore: debt,
              cashier: user.name,
              at: DateTime.now(),
            ),
            _print
          ));
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
    final l = context.l10n;
    // Live debt: another cashier may have accepted a payment meanwhile.
    final live = ref.watch(customerProvider(widget.customer.id)).value ?? widget.customer;
    final debt = live.debtBalance;
    final shift = ref.watch(currentShiftProvider).value;
    final noShiftForCash = _method == 'cash' && shift == null;
    return Form(
      key: _form,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.m, Gap.xl, Gap.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(live.name, style: t.textTheme.titleMedium),
          const SizedBox(height: Gap.xs),
          Text.rich(TextSpan(children: [
            TextSpan(text: '${l.custCurrentDebt} '),
            TextSpan(
                text: Money.format(debt),
                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ])),
          const SizedBox(height: Gap.l),
          LayoutBuilder(builder: (context, box) {
            final field = MoneyField(
              label: l.custPayAmount,
              controller: _amount,
              autofocus: true,
              required: true,
              allowZero: false,
              validator: (v) => v != null && v > debt ? l.custNotMoreThanDebt(Money.format(debt)) : null,
              onSubmitted: (_) => _submit(debt),
            );
            void fill() => setState(() => _amount.text = Money.toInput(debt));
            // Phones: the amount gets the full width; the shortcut sits
            // below it and shows the sum it will fill in.
            if (box.maxWidth < 380) {
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                field,
                const SizedBox(height: Gap.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: fill,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: Text(l.custFullAmountValue(Money.format(debt))),
                  ),
                ),
              ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: field),
              const SizedBox(width: Gap.s),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: OutlinedButton(onPressed: fill, child: Text(l.custFullAmount)),
              ),
            ]);
          }),
          const SizedBox(height: Gap.l),
          Text(l.commonPaymentMethod, style: t.textTheme.labelLarge),
          const SizedBox(height: Gap.s),
          // On phones (dialog content < 380px) three segments with icons do
          // not fit: drop the icons, keep one full-width control.
          LayoutBuilder(
            builder: (context, box) => SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: box.maxWidth >= 380,
                segments: [
                  for (final m in debtPaymentMethods)
                    ButtonSegment(
                        value: m,
                        label: Text(paymentMethodLabel(m, l), maxLines: 1, softWrap: false),
                        icon: box.maxWidth < 380
                            ? null
                            : Icon(switch (m) {
                                'cash' => Icons.payments_outlined,
                                'card' => Icons.credit_card,
                                _ => Icons.swap_horiz,
                              })),
                ],
                selected: {_method},
                onSelectionChanged: (s) => setState(() => _method = s.first),
              ),
            ),
          ),
          if (noShiftForCash) ...[
            const SizedBox(height: Gap.s),
            Text(l.custShiftClosedCash, style: const TextStyle(color: AppColors.danger)),
          ] else if (_method == 'cash' && shift != null) ...[
            const SizedBox(height: Gap.s),
            Text(l.custCashToShift(docNo(shift.number, shift.deviceCode)),
                style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: Gap.l),
          TextFormField(
            controller: _note,
            decoration: InputDecoration(labelText: l.commonComment),
            onFieldSubmitted: (_) => _submit(debt),
          ),
          CheckboxListTile(
            value: _print,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(l.custPrintSlip),
            onChanged: (v) => setState(() => _print = v ?? false),
          ),
          const SizedBox(height: Gap.s),
          FilledButton.icon(
            onPressed: _busy || noShiftForCash || debt <= 0 ? null : () => _submit(debt),
            icon: const Icon(Icons.check),
            label: Text(l.custAcceptPayment),
          ),
        ]),
      ),
    );
  }
}

/// 80mm receipt for a debt payment, in the receipt language ([L.receipt])
/// unless [l] is given.
Future<pw.Document> buildDebtReceiptPdf(DebtPaymentInfo p, {required String store, AppLocalizations? l}) async {
  final tr = l ?? L.receipt;
  String pr(String s) => L.printable(s);
  final font = await PdfFonts.mono();
  final bold = await PdfFonts.monoBold();
  final doc = pw.Document();
  final s = pw.TextStyle(font: font, fontSize: 8);
  final b = pw.TextStyle(font: bold, fontSize: 9);
  pw.Widget row(String left, String r, {bool strong = false}) => pw.Row(children: [
        pw.Expanded(child: pw.Text(pr(left), style: strong ? b : s)),
        pw.Text(r, style: strong ? b : s),
      ]);
  doc.addPage(pw.Page(
    pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm),
    build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      pw.Center(child: pw.Text(store, style: b)),
      pw.SizedBox(height: 4),
      pw.Center(child: pw.Text(pr(tr.custPdfSlipTitle), style: b)),
      pw.Center(child: pw.Text(pr(tr.custPdfSlipSubtitle), style: s)),
      pw.SizedBox(height: 6),
      row(tr.commonDate, formatDateTime(p.at)),
      row(tr.commonCustomer, p.customerName),
      row(tr.commonCashier, p.cashier),
      pw.Divider(),
      row(tr.custPdfDebtBefore, Money.format(p.debtBefore)),
      row(tr.custPdfPaid(paymentMethodLabel(p.method, tr)), Money.format(p.amount), strong: true),
      row(tr.custPdfDebtAfter, Money.format(p.debtAfter), strong: true),
      pw.Divider(),
      pw.SizedBox(height: 12),
      pw.Text(pr(tr.custPdfSignature), style: s),
      pw.SizedBox(height: 8),
      pw.Center(child: pw.Text(pr(tr.custThanks), style: s)),
    ]),
  ));
  return doc;
}

Future<void> printDebtReceipt(DebtPaymentInfo p, {required String store}) async {
  final doc = await buildDebtReceiptPdf(p, store: store);
  await Printing.layoutPdf(name: L.receipt.custPdfJobName(p.customerName), onLayout: (_) => doc.save());
}

// ------------------------------------------------------------------ bonus

Future<bool> showBonusAdjustDialog(BuildContext context, Customer customer) async {
  final ok = await showFormDialog<bool>(context,
      title: context.l10n.custLedgerBonusAdjust, width: 460, child: _BonusForm(customer: customer));
  return ok ?? false;
}

class _BonusForm extends ConsumerStatefulWidget {
  const _BonusForm({required this.customer});
  final Customer customer;
  @override
  ConsumerState<_BonusForm> createState() => _BonusFormState();
}

class _BonusFormState extends ConsumerState<_BonusForm> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  bool _add = true;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit(int balance) async {
    if (_busy || !_form.currentState!.validate()) return;
    final amount = Money.parse(_amount.text)!;
    setState(() => _busy = true);
    final service = ref.read(customerServiceProvider);
    final repo = ref.read(customerRepoProvider);
    final userId = ref.read(sessionProvider)!.user.id;
    final ok = await runGuarded(
      context,
      () async {
        await service.adjustBonus(
          customerId: widget.customer.id,
          delta: _add ? amount : -amount,
          userId: userId,
          reason: _reason.text.trim(),
        );
        // adjustBonus neither sets updatedAt nor marks the row for sync.
        try {
          await repo.markBalanceChanged(widget.customer.id);
        } catch (_) {}
      },
      success: _add
          ? context.l10n.custBonusAdded(Money.format(amount))
          : context.l10n.custBonusRemoved(Money.format(amount)),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(customerProvider(widget.customer.id)).value ?? widget.customer;
    final balance = live.bonusBalance;
    final l = context.l10n;
    return Form(
      key: _form,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.m, Gap.xl, Gap.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.custBonusHeader(live.name, Money.format(balance))),
          const SizedBox(height: Gap.l),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(l.custBonusAdd), icon: const Icon(Icons.add)),
              ButtonSegment(value: false, label: Text(l.custBonusRemove), icon: const Icon(Icons.remove)),
            ],
            selected: {_add},
            onSelectionChanged: (s) => setState(() => _add = s.first),
          ),
          const SizedBox(height: Gap.l),
          MoneyField(
            label: l.custBonusAmount,
            controller: _amount,
            autofocus: true,
            required: true,
            allowZero: false,
            validator: (v) =>
                !_add && v != null && v > balance ? l.custBonusOnlyOnBalance(Money.format(balance)) : null,
            onSubmitted: (_) => _submit(balance),
          ),
          const SizedBox(height: Gap.m),
          TextFormField(
            controller: _reason,
            decoration: InputDecoration(labelText: l.custReasonRequired, hintText: l.custReasonHint),
            validator: (v) => (v ?? '').trim().length < 3 ? l.custReasonError : null,
            onFieldSubmitted: (_) => _submit(balance),
          ),
          const SizedBox(height: Gap.l),
          FilledButton(onPressed: _busy ? null : () => _submit(balance), child: Text(l.commonApply)),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ reminder

Future<void> showDebtReminderDialog(BuildContext context, WidgetRef ref, Customer c) async {
  final store = ref.read(settingProvider('store_name')) ?? L.receipt.custOurStore;
  final storePhone = ref.read(settingProvider('store_phone'));
  final repo = ref.read(customerRepoProvider);
  final charges = await repo.debtCharges(customerId: c.id);
  final overdue = computeOverdue(charges, {c.id: c.debtBalance}, DateTime.now())[c.id] ?? 0;
  final text = debtReminderText(
    name: c.name,
    store: store,
    debt: c.debtBalance,
    overdue: overdue,
    dueDate: earliestUnpaidDue(charges, c.debtBalance),
    storePhone: storePhone,
  );
  if (!context.mounted) return;
  await showFormDialog<void>(
    context,
    title: context.l10n.custReminderTitle,
    width: 520,
    child: _ReminderForm(text: text, phone: c.phone),
  );
}

/// Owns its controller so it is disposed together with the dialog route
/// (disposing right after showDialog returns races the exit animation).
class _ReminderForm extends StatefulWidget {
  const _ReminderForm({required this.text, this.phone});
  final String text;
  final String? phone;
  @override
  State<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<_ReminderForm> {
  late final _ctl = TextEditingController(text: widget.text);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _copyPhone(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (mounted) showSuccess(context, context.l10n.custPhoneCopied);
  }

  Future<void> _copyText() async {
    if (_ctl.text.trim().isEmpty) {
      showError(context, context.l10n.custReminderEmpty);
      return;
    }
    // Capture the messenger first: the dialog context is gone after pop.
    final messenger = ScaffoldMessenger.maybeOf(context);
    final copied = context.l10n.custReminderCopied;
    await Clipboard.setData(ClipboardData(text: _ctl.text));
    if (!mounted) return;
    Navigator.pop(context);
    messenger?.showSnackBar(SnackBar(
      content: Text(copied),
      backgroundColor: AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.phone;
    final l = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.m, Gap.xl, Gap.l),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (phone != null) Text(l.custPhoneValue(phone), style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: Gap.s),
        TextField(controller: _ctl, minLines: 4, maxLines: 8, autofocus: true),
        const SizedBox(height: Gap.s),
        Text(l.custReminderSendHint,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: Gap.l),
        Wrap(alignment: WrapAlignment.end, spacing: Gap.s, runSpacing: Gap.s, children: [
          if (phone != null)
            OutlinedButton.icon(
              onPressed: () => _copyPhone(phone),
              icon: const Icon(Icons.phone),
              label: Text(l.custCopyPhone),
            ),
          FilledButton.icon(
            onPressed: _copyText,
            icon: const Icon(Icons.copy),
            label: Text(l.custCopyText),
          ),
        ]),
      ]),
    );
  }
}
