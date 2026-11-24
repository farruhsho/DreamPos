import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/printing/receipt.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/services/sale_service.dart';

/// Shown after a successful checkout: big change due, print, new sale.
Future<void> showSaleSuccess(BuildContext context, CheckoutResult result) {
  return showDialog<void>(
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
      if (mounted) showError(context, 'Не удалось напечатать чек: ${errorText(e)}');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final sale = widget.result.sale;
    final change = widget.result.changeDue;
    return AlertDialog(
      icon: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
      title: Text('Чек №${sale.number} проведён'),
      content: SizedBox(
        width: 380,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Сумма чека: ${Money.format(sale.total)}', style: t.textTheme.titleMedium),
          if (sale.discountTotal > 0)
            Text('Скидка: ${Money.format(sale.discountTotal)}', style: t.textTheme.bodyMedium),
          if (sale.bonusEarned > 0)
            Text('Начислено бонусов: ${Money.format(sale.bonusEarned)}',
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
              Text(change > 0 ? 'Сдача' : 'Без сдачи', style: t.textTheme.titleMedium),
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
          label: Text(_printed ? 'Ещё раз' : 'Печать чека'),
        ),
        FilledButton.icon(
          autofocus: true,
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Новая продажа (Enter)'),
        ),
      ],
    );
  }
}
