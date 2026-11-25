// Receipts history & returns.
//
// Tabs: «Чеки» (live list with filters, totals, lazy loading and
// master-detail) and «Возвраты». Deep link: /sales?receipt=<number> opens
// that receipt (used by the warranty module).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/doc_number.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/services/sale_service.dart';
import '../../l10n/l10n.dart';
import 'filter_menu.dart';
import 'sale_detail.dart';
import 'sales_logic.dart';
import 'sales_queries.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

/// A request to open a particular receipt.
class _Focus {
  _Focus(this.saleId, this.number);
  final String saleId;

  /// Display number («15» / «A-15»).
  final String number;
}

class _SalesScreenState extends ConsumerState<SalesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  String? _handledLink;
  _Focus? _focus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    String? receipt;
    try {
      receipt = GoRouterState.of(context).uri.queryParameters['receipt'];
    } catch (_) {
      receipt = null; // not under go_router (tests)
    }
    if (receipt == null) {
      _handledLink = null; // allow the same link to be opened again later
    } else if (receipt != _handledLink) {
      _handledLink = receipt;
      _openByNumber(receipt);
    }
  }

  Future<void> _openByNumber(String raw) async {
    final p = parseDocNo(raw);
    if (p == null) return;
    final sale = await findSaleByNumber(ref.read(databaseProvider), p.number, code: p.code);
    if (!mounted) return;
    if (sale == null) return showError(context, context.l10n.salesReceiptNoNotFound(docNo(p.number, p.code)));
    _tabs.index = 0;
    setState(() => _focus = _Focus(sale.id, docNo(sale.number, sale.deviceCode)));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider); // keeps Money.currency in sync
    final l = context.l10n;
    return PageScaffold(
      title: l.salesTitle,
      subtitle: l.salesSubtitle,
      padding: EdgeInsets.zero,
      bottom: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(icon: const Icon(Icons.receipt_long_outlined), text: l.salesTitle),
          Tab(icon: const Icon(Icons.assignment_return_outlined), text: l.salesTabReturns),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SalesTab(focus: _focus),
          const _ReturnsTab(),
        ],
      ),
    );
  }
}

// ======================================================================= sales

class _SalesTab extends ConsumerStatefulWidget {
  const _SalesTab({this.focus});
  final _Focus? focus;

  @override
  ConsumerState<_SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends ConsumerState<_SalesTab> with AutomaticKeepAliveClientMixin {
  SalesFilter _filter = const SalesFilter();
  String? _selected;
  List<SaleRow>? _last;
  final _search = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.focus != null) _applyFocus(widget.focus!);
  }

  @override
  void didUpdateWidget(covariant _SalesTab old) {
    super.didUpdateWidget(old);
    // didUpdateWidget is followed by build, so no setState is needed here
    if (widget.focus != null && widget.focus != old.focus) _applyFocus(widget.focus!);
  }

  void _applyFocus(_Focus f) {
    _search.text = f.number;
    _filter = SalesFilter(period: Period.all, query: f.number);
    _selected = f.saleId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !context.isWide) _openNarrow(f.saleId);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openNarrow(String id) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SaleDetailPage(saleId: id)));

  void _select(String id) {
    if (context.isWide) {
      setState(() => _selected = id);
    } else {
      _openNarrow(id);
    }
  }

  SalesFilter _effective(Session s, String? shiftId) => s.can(Perm.viewAllShifts)
      ? _filter
      : SalesFilter(
          period: Period.all,
          status: _filter.status,
          method: _filter.method,
          shiftId: shiftId ?? '-',
          query: _filter.query,
          limit: _filter.limit,
        );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();
    final shift = ref.watch(currentShiftProvider);
    final restricted = !session.can(Perm.viewAllShifts);
    if (restricted && shift.isLoading) return const LoadingView();
    final f = _effective(session, shift.value?.id);
    final async = ref.watch(salesListProvider(f));
    if (async.hasValue) _last = async.value;
    final totals = ref.watch(salesTotalsProvider(f.copyWith(limit: SalesFilter.pageSize))).value;
    final wide = context.isWide;
    final l = context.l10n;

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(Gap.l, Gap.l, Gap.l, Gap.s), child: _filters(session, restricted)),
        if (restricted)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.l),
            child: Text(
              shift.value == null
                  ? l.salesNoShiftReceipts
                  : l.salesShiftReceipts(docNo(shift.value!.number, shift.value!.deviceCode)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (totals != null && totals.count > 0) _TotalsBar(totals: totals),
        if (async.isLoading && _last != null) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _listBody(async, f)),
      ],
    );

    if (!wide) return list;
    // a receipt hidden by the current search/filters must not linger in the
    // detail pane next to "nothing found"
    final shown = async.value ?? _last;
    final visible = _selected != null && (shown == null || shown.any((r) => r.sale.id == _selected));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 5, child: list),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 6,
          child: !visible
              ? EmptyState(
                  icon: Icons.touch_app_outlined,
                  title: l.salesSelectReceipt,
                  message: l.salesSelectReceiptHint,
                )
              : SaleDetailView(key: ValueKey(_selected), saleId: _selected!),
        ),
      ],
    );
  }

  Widget _listBody(AsyncValue<List<SaleRow>> async, SalesFilter f) {
    final l = context.l10n;
    final rows = async.value ?? _last;
    if (rows == null) {
      if (async.hasError) {
        return ErrorView(error: async.error!, onRetry: () => ref.invalidate(salesListProvider(f)));
      }
      return const LoadingView();
    }
    if (rows.isEmpty) {
      final filtered = _filter.hasFilters;
      final restricted = f.shiftId != null;
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: l.salesNoReceipts,
        message: filtered
            ? l.salesNoReceiptsFiltered
            : restricted
            ? l.salesNoSalesInShift
            : l.salesNoSalesInPeriod,
        action: filtered
            ? OutlinedButton(
                onPressed: () => setState(() {
                  _search.clear();
                  _filter = SalesFilter(period: _filter.period, custom: _filter.custom);
                }),
                child: Text(l.salesResetFilters),
              )
            : !restricted && _filter.period != Period.all
            ? OutlinedButton(
                onPressed: () => setState(() => _filter = _filter.copyWith(period: Period.all)),
                child: Text(l.salesShowAllTime),
              )
            : null,
      );
    }
    final more = rows.length >= f.limit;
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: Gap.xl),
      itemCount: rows.length + (more ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        if (i == rows.length) {
          return Padding(
            padding: const EdgeInsets.all(Gap.l),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _filter = _filter.copyWith(limit: _filter.limit + SalesFilter.pageSize)),
                icon: const Icon(Icons.expand_more),
                label: Text(l.salesShowMore),
              ),
            ),
          );
        }
        final r = rows[i];
        return _SaleTile(row: r, selected: r.sale.id == _selected, onTap: () => _select(r.sale.id));
      },
    );
  }

  Widget _filters(Session session, bool restricted) {
    final staff = ref.watch(staffProvider).value ?? const [];
    final l = context.l10n;
    final search = SearchField(
      controller: _search,
      autofocus: context.isWide,
      hint: l.salesSearchHint,
      onChanged: (v) => setState(() => _filter = _filter.copyWith(query: v)),
    );
    final chips = Wrap(
      spacing: Gap.s,
      runSpacing: Gap.s,
      children: [
        if (!restricted)
          PeriodMenu(
            period: _filter.period,
            custom: _filter.custom,
            onChanged: (p, c) => setState(() => _filter = _filter.copyWith(period: p, custom: c)),
          ),
        FilterMenu<String>(
          label: l.commonStatus,
          value: _filter.status,
          options: [(null, l.commonAll), for (final s in saleStatuses) (s, saleStatusLabel(s, l))],
          onSelected: (v) => setState(() => _filter = _filter.copyWith(status: () => v)),
        ),
        FilterMenu<String>(
          label: l.commonPayment,
          value: _filter.method,
          options: [(null, l.salesAnyFem), for (final m in paymentMethods) (m, paymentMethodLabel(m, l))],
          onSelected: (v) => setState(() => _filter = _filter.copyWith(method: () => v)),
        ),
        if (!restricted && staff.isNotEmpty)
          FilterMenu<String>(
            label: l.commonCashier,
            value: _filter.cashierId,
            options: [(null, l.commonAll), for (final u in staff) (u.id, u.name)],
            onSelected: (v) => setState(() => _filter = _filter.copyWith(cashierId: () => v)),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        search,
        const SizedBox(height: Gap.s),
        chips,
      ],
    );
  }
}

class _TotalsBar extends StatelessWidget {
  const _TotalsBar({required this.totals});
  final SalesTotals totals;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _TotalsStrip(
      items: [
        (l.salesReceiptsLabel, '${totals.count}', null),
        (l.salesSalesLabel, Money.format(totals.gross), null),
        if (totals.refunded > 0) (l.salesTabReturns, '−${Money.format(totals.refunded)}', AppColors.danger),
        (l.commonTotal, Money.format(totals.net), AppColors.success),
        if (totals.voided > 0) (l.salesVoidedLabel, '${totals.voided}', AppColors.danger),
      ],
    );
  }
}

/// Compact summary strip above a list (label over bold value).
class _TotalsStrip extends StatelessWidget {
  const _TotalsStrip({required this.items});
  final List<(String, String, Color?)> items;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget item(String label, String value, Color? color) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        Text(
          value,
          style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.s),
      padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.s),
      decoration: BoxDecoration(
        color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(spacing: Gap.xl, runSpacing: Gap.s, children: [for (final (k, v, c) in items) item(k, v, c)]),
    );
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.row, required this.selected, required this.onTap});
  final SaleRow row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final s = row.sale;
    final color = saleStatusColor(s.status);
    final now = DateTime.now();
    final sameDay = s.createdAt.year == now.year && s.createdAt.month == now.month && s.createdAt.day == now.day;
    final muted = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    return ListTile(
      selected: selected,
      selectedTileColor: t.colorScheme.primaryContainer.withValues(alpha: 0.35),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(saleStatusIcon(s.status), color: color, size: 20),
      ),
      title: Row(
        children: [
          Text('№${docNo(s.number, s.deviceCode)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: Gap.s),
          Flexible(
            child: Text(
              sameDay ? formatTime(s.createdAt) : formatDateTime(s.createdAt),
              style: muted,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        _meta([
          ?row.cashierName,
          ?row.customerName,
          l.salesPositionsShort('${row.itemsCount}'),
          if (row.methods.isNotEmpty) row.methods.map((m) => paymentMethodLabel(m, l)).join(', '),
        ]),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Money.format(s.total),
            style: t.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              decoration: s.status == 'voided' ? TextDecoration.lineThrough : null,
              color: s.status == 'voided' ? t.colorScheme.onSurfaceVariant : null,
            ),
          ),
          if (s.status != 'completed') ...[
            const SizedBox(height: 2),
            StatusChip(saleStatusLabel(s.status, l), color: color),
          ],
        ],
      ),
    );
  }
}

// ======================================================================= returns

class _ReturnsTab extends ConsumerStatefulWidget {
  const _ReturnsTab();
  @override
  ConsumerState<_ReturnsTab> createState() => _ReturnsTabState();
}

class _ReturnsTabState extends ConsumerState<_ReturnsTab> with AutomaticKeepAliveClientMixin {
  ReturnsFilter _filter = const ReturnsFilter();
  String? _selectedSale;
  String? _selectedReturn;
  List<ReturnRow>? _last;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();
    final restricted = !session.can(Perm.viewAllShifts);
    final shift = ref.watch(currentShiftProvider);
    if (restricted && shift.isLoading) return const LoadingView();
    // users without "view all shifts" see only returns of the current shift
    final f = restricted ? _filter.copyWith(shiftId: () => shift.value?.id ?? '-', limit: _filter.limit) : _filter;
    final async = ref.watch(returnsListProvider(f));
    final totals = ref.watch(returnsTotalsProvider(f.copyWith(limit: SalesFilter.pageSize))).value;
    if (async.hasValue) _last = async.value;
    final rows = async.value ?? _last;
    final wide = context.isWide;
    final l = context.l10n;

    Widget body;
    if (rows == null) {
      body = async.hasError
          ? ErrorView(error: async.error!, onRetry: () => ref.invalidate(returnsListProvider(f)))
          : const LoadingView();
    } else if (rows.isEmpty) {
      body = EmptyState(
        icon: Icons.assignment_return_outlined,
        title: l.salesNoReturns,
        message: _filter.query.isNotEmpty || _filter.method != null
            ? l.salesChangeSearch
            : l.salesNoReturnsHint,
      );
    } else {
      final more = rows.length >= f.limit;
      body = ListView.separated(
        padding: const EdgeInsets.only(bottom: Gap.xl),
        itemCount: rows.length + (more ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          if (i == rows.length) {
            return Padding(
              padding: const EdgeInsets.all(Gap.l),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _filter = _filter.copyWith(limit: _filter.limit + SalesFilter.pageSize)),
                  icon: const Icon(Icons.expand_more),
                  label: Text(l.salesShowMore),
                ),
              ),
            );
          }
          final r = rows[i];
          final t = Theme.of(context);
          return ListTile(
            selected: r.ret.id == _selectedReturn,
            selectedTileColor: t.colorScheme.primaryContainer.withValues(alpha: 0.35),
            leading: CircleAvatar(
              backgroundColor: AppColors.danger.withValues(alpha: 0.12),
              child: const Icon(Icons.assignment_return, color: AppColors.danger, size: 20),
            ),
            title: Text(
              l.salesReturnTitle(docNo(r.ret.number, r.ret.deviceCode), r.saleNo),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _meta([
                formatDateTime(r.ret.createdAt),
                paymentMethodLabel(r.ret.refundMethod, l),
                ?r.userName,
                ?r.customerName,
                l.salesPositionsShort('${r.itemsCount}'),
                if ((r.ret.reason ?? '').isNotEmpty) r.ret.reason!,
              ]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              '−${Money.format(r.ret.total)}',
              style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.danger),
            ),
            onTap: () {
              if (wide) {
                setState(() {
                  _selectedSale = r.ret.saleId;
                  _selectedReturn = r.ret.id;
                });
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SaleDetailPage(saleId: r.ret.saleId, focusReturnId: r.ret.id)),
                );
              }
            },
          );
        },
      );
    }

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.l, Gap.l, Gap.l, Gap.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SearchField(
                hint: l.salesReturnsSearchHint,
                onChanged: (v) => setState(() => _filter = _filter.copyWith(query: v)),
              ),
              const SizedBox(height: Gap.s),
              Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [
                  if (!restricted)
                    PeriodMenu(
                      period: _filter.period,
                      custom: _filter.custom,
                      onChanged: (p, c) => setState(() => _filter = _filter.copyWith(period: p, custom: c)),
                    ),
                  FilterMenu<String>(
                    label: l.salesMethodLabel,
                    value: _filter.method,
                    options: [
                      (null, l.salesAnyMasc),
                      for (final m in refundMethodOptions(hasCustomer: true)) (m, paymentMethodLabel(m, l)),
                    ],
                    onSelected: (v) => setState(() => _filter = _filter.copyWith(method: () => v)),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (restricted)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.l),
            child: Text(
              shift.value == null
                  ? l.salesNoShiftReturns
                  : l.salesShiftReturns(docNo(shift.value!.number, shift.value!.deviceCode)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (totals != null && totals.count > 0)
          _TotalsStrip(
            items: [
              (l.salesReturnsCountLabel, '${totals.count}', null),
              (l.salesSumLabel, '−${Money.format(totals.sum)}', AppColors.danger),
            ],
          ),
        if (async.isLoading && _last != null) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: body),
      ],
    );

    if (!wide) return list;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 5, child: list),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 6,
          child: _selectedSale == null
              ? EmptyState(
                  icon: Icons.touch_app_outlined,
                  title: l.salesSelectReturn,
                  message: l.salesSelectReturnHint,
                )
              : SaleDetailView(
                  key: ValueKey(_selectedReturn),
                  saleId: _selectedSale!,
                  focusReturnId: _selectedReturn,
                ),
        ),
      ],
    );
  }
}

/// Joins list-row details with " · ", keeping short values like "2 поз." and
/// each separator glued to the next value, so a wrapped line never starts
/// with a dot or splits a number from its unit.
String _meta(List<String> parts) =>
    parts.map((p) => p.length <= 12 ? p.replaceAll(' ', '\u00A0') : p).join('\u00A0· ');
