import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/printing/receipt.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../domain/services/sale_service.dart';
import '../pos_providers.dart';

/// Shown after a successful checkout: big change due, print, new sale.
///
/// The cashier often scans the next customer's first item while this dialog
/// is still open. Typed characters are collected instead of being lost; Enter
/// closes the dialog ("new sale") and the result carries what was typed:
/// `submit: true` for digits + Enter (a scan — add the product), `false` when
/// the dialog was closed otherwise (the text just goes into the search field).
Future<ScanForward?> showSaleSuccess(BuildContext context, CheckoutResult result) {
  return showDialog<ScanForward>(
    context: context,
    builder: (_) => SaleSuccessDialog(result: result),
  );
}

class SaleSuccessDialog extends ConsumerStatefulWidget {
  const SaleSuccessDialog({super.key, required this.result});
  final CheckoutResult result;

  @override
  ConsumerState<SaleSuccessDialog> createState() => _SaleSuccessDialogState();
}

class _SaleSuccessDialogState extends ConsumerState<SaleSuccessDialog> {
  bool _printing = false;
  bool _printed = false;
  final _typed = StringBuffer();

  static final _scanChar = RegExp(r'^[0-9A-Za-z*.,\-]$');

  void _close() {
    final text = _typed.toString();
    Navigator.pop(context, text.isEmpty ? null : (text: text, submit: false));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      final text = _typed.toString();
      Navigator.pop(context, text.isEmpty ? null : (text: text, submit: true));
      return KeyEventResult.handled;
    }
    final ch = e.character;
    if (ch != null && _scanChar.hasMatch(ch)) {
      _typed.write(ch);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.backspace && _typed.isNotEmpty) {
      final t = _typed.toString();
      _typed
        ..clear()
        ..write(t.substring(0, t.length - 1));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void initState() {
    super.initState();
    if (ref.read(settingProvider('auto_print_receipt')) == '1') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _print());
    }
  }

  Future<void> _print() async {
    if (_printing) return;
    setState(() => _printing = true);
    try {
      await printReceipt(ref.read(databaseProvider), widget.result.sale.id);
      if (mounted) setState(() => _printed = true);
    } catch (e) {
      if (mounted) showError(context, context.l10n.posPrintFailed(errorText(e)));
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final sale = widget.result.sale;
    final change = widget.result.changeDue;
    final l = context.l10n;
    return Focus(
      onKeyEvent: _onKey,
      child: AlertDialog(
      icon: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
      title: Text(l.posSaleDone('${sale.number}')),
      content: SizedBox(
        width: 380,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.posReceiptSum(Money.format(sale.total)), style: t.textTheme.titleMedium),
          if (sale.discountTotal > 0)
            Text(l.posDiscountValue(Money.format(sale.discountTotal)), style: t.textTheme.bodyMedium),
          if (sale.bonusEarned > 0)
            Text(l.posBonusEarned(Money.format(sale.bonusEarned)),
                style: t.textTheme.bodyMedium?.copyWith(color: AppColors.success)),
          const SizedBox(height: Gap.l),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Gap.l),
            decoration: BoxDecoration(
              color: (change > 0 ? AppColors.warning : AppColors.success).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              Text(change > 0 ? l.commonChange : l.posNoChange, style: t.textTheme.titleMedium),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(Money.format(change),
                    key: const Key('success-change'),
                    style: t.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: change > 0 ? AppColors.warning : AppColors.success)),
              ),
            ]),
          ),
        ]),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        OutlinedButton.icon(
          onPressed: _printing ? null : _print,
          icon: _printing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(_printed ? Icons.done : Icons.print_outlined),
          label: Text(_printed ? l.posPrintAgain : l.posPrintReceipt),
        ),
        FilledButton.icon(
          autofocus: true,
          onPressed: _close,
          icon: const Icon(Icons.add_shopping_cart),
          label: Text(l.posNewSale),
        ),
      ],
    ),
    );
  }
}
