// Small dialogs used by the POS screen: quantity, price, discount, manager
// approval, opening a shift, seller choice and the parked receipts list.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/permissions.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../cart_controller.dart';
import '../parked_carts.dart';
import '../pos_providers.dart';

// ------------------------------------------------------------------ quantity

/// Asks for an exact quantity (weight for kg). Returns null when cancelled.
Future<double?> askQty(BuildContext context,
    {required String title, required String unit, double? initial}) {
  final ctl = TextEditingController(
      text: initial == null ? '' : Qty.format(initial).replaceAll(' ', ''));
  ctl.selection = TextSelection(baseOffset: 0, extentOffset: ctl.text.length);
  final key = GlobalKey<FormState>();
  return showDialog<double>(
    context: context,
    builder: (c) {
      void submit() {
        if (!key.currentState!.validate()) return;
        Navigator.pop(c, Qty.round(QtyField.parse(ctl.text)!));
      }

      return AlertDialog(
        title: Text(title),
        content: Form(
          key: key,
          child: SizedBox(
            width: 320,
            child: TextFormField(
              controller: ctl,
              autofocus: true,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: InputDecoration(
                labelText: Qty.isFractional(unit) ? 'Количество / вес' : 'Количество',
                suffixText: Qty.unitLabel(unit),
                helperText: Qty.isFractional(unit) ? 'Например: 0,75' : null,
              ),
              validator: (v) => validateQty(QtyField.parse(v ?? ''), unit),
              onFieldSubmitted: (_) => submit(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Отмена')),
          FilledButton(onPressed: submit, child: const Text('OK')),
        ],
      );
    },
  );
}

// ------------------------------------------------------------------ price

Future<int?> askPrice(BuildContext context, CartLine line) {
  final ctl = TextEditingController(text: Money.toInput(line.unitPrice));
  ctl.selection = TextSelection(baseOffset: 0, extentOffset: ctl.text.length);
  final key = GlobalKey<FormState>();
  return showDialog<int>(
    context: context,
    builder: (c) {
      void submit() {
        if (!key.currentState!.validate()) return;
        Navigator.pop(c, Money.parse(ctl.text));
      }

      return AlertDialog(
        title: const Text('Цена продажи'),
        content: Form(
          key: key,
          child: SizedBox(
            width: 340,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(line.name, style: Theme.of(c).textTheme.titleSmall),
              const SizedBox(height: Gap.xs),
              Text('Цена по прайсу: ${Money.format(line.basePrice)}',
                  style: Theme.of(c).textTheme.bodySmall),
              const SizedBox(height: Gap.m),
              MoneyField(
                label: 'Новая цена',
                controller: ctl,
                autofocus: true,
                required: true,
                onSubmitted: (_) => submit(),
              ),
            ]),
          ),
        ),
        actions: [
          if (line.priceEdited)
            TextButton(
                onPressed: () => Navigator.pop(c, line.basePrice),
                child: const Text('Вернуть цену прайса')),
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Отмена')),
          FilledButton(onPressed: submit, child: const Text('Применить')),
        ],
      );
    },
  );
}

// ------------------------------------------------------------------ discount

class DiscountInput {
  const DiscountInput({this.amount = 0, this.percent = 0});
  final int amount;
  final double percent;
  bool get isZero => amount <= 0 && percent <= 0;
}

/// Manual discount entry, by percent or amount. [base] is the amount the
/// discount applies to (used to validate and show the result).
Future<DiscountInput?> askDiscount(
  BuildContext context, {
  required String title,
  required int base,
  required double limitPercent,
  int currentAmount = 0,
  double currentPercent = 0,
}) {
  return showDialog<DiscountInput>(
    context: context,
    builder: (_) => _DiscountDialog(
      title: title,
      base: base,
      limitPercent: limitPercent,
      currentAmount: currentAmount,
      currentPercent: currentPercent,
    ),
  );
}

class _DiscountDialog extends StatefulWidget {
  const _DiscountDialog({
    required this.title,
    required this.base,
    required this.limitPercent,
    required this.currentAmount,
    required this.currentPercent,
  });
  final String title;
  final int base;
  final double limitPercent;
  final int currentAmount;
  final double currentPercent;

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  late bool _percent = widget.currentAmount <= 0;
  late final _ctl = TextEditingController(
      text: widget.currentPercent > 0
          ? _fmtPct(widget.currentPercent)
          : widget.currentAmount > 0
              ? Money.toInput(widget.currentAmount)
              : '');
  final _key = GlobalKey<FormState>();

  static String _fmtPct(double p) =>
      p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);

  double? get _pctValue => QtyField.parse(_ctl.text.isEmpty ? '0' : _ctl.text);
  int? get _amountValue => _ctl.text.trim().isEmpty ? 0 : Money.parse(_ctl.text);

  int get _discount {
    if (_percent) {
      final p = _pctValue ?? 0;
      return Money.percent(widget.base, p.clamp(0, 100).toDouble());
    }
    return _amountValue ?? 0;
  }

  double get _effectivePct => discountPercentOf(_discount, widget.base);

  String? _validate(String? v) {
    if (_percent) {
      final p = QtyField.parse((v ?? '').isEmpty ? '0' : v!);
      if (p == null) return 'Введите число';
      if (p < 0) return 'Не может быть отрицательной';
      if (p > 100) return 'Не больше 100%';
    } else {
      final a = (v ?? '').trim().isEmpty ? 0 : Money.parse(v!);
      if (a == null) return 'Неверная сумма';
      if (a < 0) return 'Не может быть отрицательной';
      if (a > widget.base) return 'Больше суммы (${Money.format(widget.base)})';
    }
    return null;
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(
        context,
        _percent
            ? DiscountInput(percent: (_pctValue ?? 0).toDouble())
            : DiscountInput(amount: _amountValue ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final over = !withinDiscountLimit(_effectivePct, widget.limitPercent);
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _key,
        child: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Сумма: ${Money.format(widget.base)}', style: t.textTheme.bodyMedium),
            const SizedBox(height: Gap.m),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Процент, %')),
                ButtonSegment(value: false, label: Text('Сумма')),
              ],
              selected: {_percent},
              onSelectionChanged: (s) => setState(() {
                _percent = s.first;
                _ctl.clear();
              }),
            ),
            const SizedBox(height: Gap.m),
            TextFormField(
              controller: _ctl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))],
              decoration: InputDecoration(
                labelText: _percent ? 'Скидка, %' : 'Скидка, сумма',
                suffixText: _percent ? '%' : Money.currency.symbol,
              ),
              validator: _validate,
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Gap.m),
            Text(
              'Скидка: ${Money.format(_discount)} (${_effectivePct.toStringAsFixed(1)}%) · '
              'к оплате ${Money.format(widget.base - _discount)}',
              style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: Gap.xs),
            Text(
              over
                  ? 'Превышает ваш лимит ${_fmtPct(widget.limitPercent)}% — потребуется PIN менеджера'
                  : 'Ваш лимит скидки: ${_fmtPct(widget.limitPercent)}%',
              style: t.textTheme.bodySmall?.copyWith(
                  color: over ? AppColors.warning : t.colorScheme.onSurfaceVariant),
            ),
          ]),
        ),
      ),
      actions: [
        if (widget.currentAmount > 0 || widget.currentPercent > 0)
          TextButton(
              onPressed: () => Navigator.pop(context, const DiscountInput()),
              child: const Text('Убрать скидку')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: _submit, child: const Text('Применить')),
      ],
    );
  }
}

// ------------------------------------------------------------------ approval

/// Pure approval rule (unit-tested): may [approver] authorise a manual
/// discount of [percent] requested by [cashier]? Returns an error or null.
String? approvalError(User approver, User cashier, double percent) {
  final role = Role.parse(approver.role);
  if (!role.can(Perm.applyDiscount)) {
    return '${approver.name}: нет права подтверждать скидки';
  }
  if (approver.maxDiscountPercent <= cashier.maxDiscountPercent) {
    return '${approver.name}: лимит скидки не выше, чем у кассира';
  }
  if (!withinDiscountLimit(percent, approver.maxDiscountPercent)) {
    return 'Лимит ${approver.name} — ${approver.maxDiscountPercent.toStringAsFixed(0)}%, '
        'запрошено ${percent.toStringAsFixed(1)}%';
  }
  return null;
}

/// Asks a manager/owner PIN to approve a discount over the cashier's limit.
/// Does NOT change the current session. Returns the approver or null.
Future<User?> askManagerApproval(BuildContext context,
    {required User cashier, required double percent, required String what}) {
  return showDialog<User>(
    context: context,
    builder: (_) => _ApprovalDialog(cashier: cashier, percent: percent, what: what),
  );
}

class _ApprovalDialog extends ConsumerStatefulWidget {
  const _ApprovalDialog({required this.cashier, required this.percent, required this.what});
  final User cashier;
  final double percent;
  final String what;

  @override
  ConsumerState<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends ConsumerState<_ApprovalDialog> {
  String? _error;
  bool _busy = false;

  Future<void> _verify(String pin) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? err;
    try {
      final u = await ref.read(authServiceProvider).verifyApprover(pin);
      err = u.id == widget.cashier.id
          ? 'Нужен PIN другого сотрудника (менеджера или владельца)'
          : approvalError(u, widget.cashier, widget.percent);
      if (err == null) {
        if (mounted) Navigator.pop(context, u);
        return;
      }
    } catch (e) {
      err = errorText(e);
    }
    if (!mounted) return;
    setState(() {
      _error = err;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return AlertDialog(
      title: const Text('Подтверждение менеджера'),
      content: SizedBox(
        width: 340,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            '${widget.what}: ${widget.percent.toStringAsFixed(1)}% — больше лимита кассира '
            '(${widget.cashier.maxDiscountPercent.toStringAsFixed(0)}%).\n'
            'Менеджер или владелец вводит свой PIN.',
            style: t.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Gap.l),
          PinPad(onCompleted: _verify, error: _error, busy: _busy),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
      ],
    );
  }
}

// ------------------------------------------------------------------ shift

/// Opens a shift. Returns true when opened.
Future<bool> showOpenShiftDialog(BuildContext context) async {
  final r = await showDialog<bool>(context: context, builder: (_) => const _OpenShiftDialog());
  return r ?? false;
}

class _OpenShiftDialog extends ConsumerStatefulWidget {
  const _OpenShiftDialog();
  @override
  ConsumerState<_OpenShiftDialog> createState() => _OpenShiftDialogState();
}

class _OpenShiftDialogState extends ConsumerState<_OpenShiftDialog> {
  final _key = GlobalKey<FormState>();
  int _cash = 0;
  bool _busy = false;

  Future<void> _submit() async {
    if (_busy || !_key.currentState!.validate()) return;
    final s = ref.read(sessionProvider);
    if (s == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(shiftServiceProvider).open(userId: s.user.id, openingCash: _cash);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Открыть смену'),
      content: Form(
        key: _key,
        child: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Пересчитайте наличные в денежном ящике и введите сумму размена.'),
            const SizedBox(height: Gap.l),
            MoneyField(
              label: 'Размен в кассе',
              initial: 0,
              autofocus: true,
              helper: 'Можно 0, если ящик пуст',
              onChanged: (v) => _cash = v ?? 0,
              onSubmitted: (_) => _submit(),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
        FilledButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.lock_open),
          label: const Text('Открыть смену'),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ seller

/// Returns '' to reset to "the cashier", a user id, or null when cancelled.
Future<String?> pickSeller(BuildContext context, {String? current}) {
  return showFormDialog<String>(
    context,
    title: 'Продавец-консультант',
    width: 420,
    child: Consumer(builder: (context, ref, _) {
      final users = ref.watch(posActiveUsersProvider);
      return SizedBox(
        height: 380,
        child: AsyncView(
          value: users,
          data: (list) => ListView(children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Кассир (по умолчанию)'),
              selected: current == null,
              onTap: () => Navigator.pop(context, ''),
            ),
            const Divider(),
            for (final u in list)
              ListTile(
                leading: CircleAvatar(child: Text(u.name.characters.first.toUpperCase())),
                title: Text(u.name),
                subtitle: Text(Role.parse(u.role).label),
                selected: u.id == current,
                trailing: u.id == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, u.id),
              ),
          ]),
        ),
      );
    }),
  );
}

// ------------------------------------------------------------------ parked

/// Shows parked receipts. Returns the chosen one (already removed from the
/// list) or null.
Future<ParkedCart?> showParkedList(BuildContext context) {
  return showFormDialog<ParkedCart>(
    context,
    title: 'Отложенные чеки',
    width: 560,
    child: const _ParkedList(),
  );
}

class _ParkedList extends ConsumerWidget {
  const _ParkedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parked = ref.watch(parkedCartsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.l),
      child: SizedBox(
        height: 420,
        child: AsyncView(
          value: parked,
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.pause_circle_outline,
                title: 'Нет отложенных чеков',
                message: 'Отложите текущий чек (F8), чтобы обслужить следующего покупателя',
              );
            }
            final sorted = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return ListView.separated(
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (_, i) {
                final p = sorted[i];
                final names = p.cart.lines.map((l) => l.name).take(3).join(', ');
                return ListTile(
                  autofocus: i == 0,
                  leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                  title: Text(p.note ?? p.cart.customerName ?? 'Чек от ${formatTime(p.createdAt)}'),
                  subtitle: Text([
                    '${formatDateTime(p.createdAt)} · ${p.cart.lines.length} поз.',
                    if (p.cashierName != null) p.cashierName!,
                    names,
                  ].join('\n')),
                  isThreeLine: true,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(Money.format(p.grossTotal),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    IconButton(
                      tooltip: 'Удалить отложенный чек',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await confirm(context,
                            title: 'Удалить отложенный чек?',
                            message: 'Товары из этого чека будут потеряны.',
                            ok: 'Удалить',
                            destructive: true);
                        if (ok) await ref.read(parkedCartsProvider.notifier).remove(p.id);
                      },
                    ),
                  ]),
                  onTap: () async {
                    final taken = await ref.read(parkedCartsProvider.notifier).take(p.id);
                    if (context.mounted) Navigator.pop(context, taken);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
