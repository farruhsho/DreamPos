// «Продажи сертификатов»: gift card sale documents (D-023) with period and
// status filters. Tap a row to open the card detail (reprint / void).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'gift_card_detail.dart';
import 'gift_sales_logic.dart';

enum GiftSalesPeriod {
  today('Сегодня'),
  week('7 дней'),
  month('30 дней'),
  all('Всё время');

  const GiftSalesPeriod(this.label);
  final String label;

  /// Start of the period (inclusive) relative to [now]; null = no bound.
  DateTime? from(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    return switch (this) {
      GiftSalesPeriod.today => day,
      GiftSalesPeriod.week => day.subtract(const Duration(days: 6)),
      GiftSalesPeriod.month => day.subtract(const Duration(days: 29)),
      GiftSalesPeriod.all => null,
    };
  }
}

class GiftSalesList extends ConsumerStatefulWidget {
  const GiftSalesList({super.key, this.clock = DateTime.now});

  /// Source of "now" (tests move it across midnight).
  final DateTime Function() clock;
  @override
  ConsumerState<GiftSalesList> createState() => _GiftSalesListState();
}

class _GiftSalesListState extends ConsumerState<GiftSalesList> {
  GiftSalesPeriod _period = GiftSalesPeriod.month;
  String? _status;

  /// Kept in state: a filter rebuilt from DateTime.now() on every build
  /// would re-create the provider each frame. It is tied to the calendar day
  /// it was made on and rebuilt when the day changes (a screen left open
  /// overnight must not show yesterday under «Сегодня»).
  late GiftSalesFilter _filter;
  late DateTime _filterDay;
  Timer? _midnight;

  static DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  GiftSalesFilter _makeFilter() {
    final now = widget.clock();
    _filterDay = _dayOf(now);
    _scheduleMidnight(now);
    return GiftSalesFilter(from: _period.from(now), status: _status);
  }

  void _scheduleMidnight(DateTime now) {
    _midnight?.cancel();
    final next = DateTime(now.year, now.month, now.day + 1);
    // +1 s: land safely on the new day
    _midnight = Timer(next.difference(now) + const Duration(seconds: 1), () {
      if (mounted) setState(() {}); // build() notices the new day
    });
  }

  @override
  void initState() {
    super.initState();
    _filter = _makeFilter();
  }

  @override
  void dispose() {
    _midnight?.cancel();
    super.dispose();
  }

  void _set({GiftSalesPeriod? period, String? status, bool clearStatus = false}) {
    setState(() {
      _period = period ?? _period;
      if (clearStatus) {
        _status = null;
      } else if (status != null) {
        _status = status;
      }
      _filter = _makeFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    // the timer may be late (app suspended): any rebuild re-checks the day
    if (_dayOf(widget.clock()) != _filterDay) _filter = _makeFilter();
    final async = ref.watch(giftSalesProvider(_filter));
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.s),
          // Wrap, not a horizontal list: on a phone every filter stays visible.
          child: Wrap(
            spacing: Gap.xs,
            runSpacing: Gap.xs,
            children: [
              for (final p in GiftSalesPeriod.values)
                ChoiceChip(
                  label: Text(p.label),
                  selected: _period == p,
                  onSelected: (_) => _set(period: p),
                ),
              const SizedBox(width: Gap.m, height: 1),
              ChoiceChip(
                label: const Text('Все'),
                selected: _status == null,
                onSelected: (_) => _set(clearStatus: true),
              ),
              for (final e in giftSaleStatusLabels.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: _status == e.key,
                  onSelected: (_) => _set(status: e.key),
                ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<List<GiftSaleRow>>(
            value: async,
            onRetry: () => ref.invalidate(giftSalesProvider(_filter)),
            data: (rows) {
              if (rows.isEmpty) {
                return const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Продаж сертификатов нет',
                  message: 'За выбранный период нет документов с таким статусом.',
                );
              }
              final completed = rows.where((r) => r.sale.status == GiftSaleStatus.completed);
              final total = completed.fold<int>(0, (s, r) => s + r.sale.amount);
              final voided = rows.length - completed.length;
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
                itemCount: rows.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: Gap.s),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Text(
                      [
                        '${rows.length} ${pluralRu(rows.length, 'документ', 'документа', 'документов')}',
                        'проведено на ${Money.format(total)}',
                        if (voided > 0) 'аннулировано: $voided',
                      ].join(' · '),
                      style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                    );
                  }
                  final r = rows[i - 1];
                  return _SaleRow(row: r, onTap: () => showGiftCardDetail(context, r.sale.giftCardId));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.row, required this.onTap});
  final GiftSaleRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final s = row.sale;
    final voided = s.status == GiftSaleStatus.voided;
    final meta = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.l, Gap.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('№${s.number}', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: Gap.s),
                  Expanded(
                    child: Text(
                      row.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.bodyMedium?.copyWith(fontFamily: AppFonts.mono, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(width: Gap.s),
                  Text(
                    Money.format(s.amount),
                    style: t.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: voided ? TextDecoration.lineThrough : null,
                      color: voided ? t.colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.xs),
              Row(
                children: [
                  StatusChip(giftSaleStatusLabels[s.status] ?? s.status, color: giftSaleStatusColor(s.status)),
                  const SizedBox(width: Gap.s),
                  Expanded(
                    child: Text(
                      giftPaymentsText(row.payments),
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
                  formatDateTime(s.createdAt),
                  ?row.cashierName,
                  ?row.customerName,
                  if (voided && s.voidReason != null) 'причина: ${s.voidReason}',
                ].join(' · '),
                style: meta,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
