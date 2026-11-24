// Warranty / service claims: list with status groups and search,
// master-detail, new claim (by receipt or manual), status workflow.
// Deep link: /warranty?receipt=<number> opens "new claim" for that receipt.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'claim_detail.dart';
import 'claim_form.dart';
import 'warranty_act.dart';
import 'warranty_logic.dart';
import 'warranty_repository.dart';

class WarrantyScreen extends ConsumerStatefulWidget {
  const WarrantyScreen({super.key});

  @override
  ConsumerState<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends ConsumerState<WarrantyScreen> {
  ClaimsFilter _filter = const ClaimsFilter();
  String? _selected;
  List<ClaimRow>? _last;
  String? _handledLink;

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
      _handledLink = null; // the same link may be followed again later
    } else if (receipt != _handledLink) {
      _handledLink = receipt;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _create(receipt: receipt);
      });
    }
  }

  Future<void> _create({String? receipt}) async {
    final claim = await showNewClaim(context, receipt: receipt);
    if (claim == null || !mounted) return;
    setState(() => _selected = claim.id);
    if (!context.isWide) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClaimDetailPage(claimId: claim.id)));
    }
    final print = await confirm(
      context,
      title: context.l10n.warrantyClaimAccepted('${claim.number}'),
      message: context.l10n.warrantyPrintActQuestion,
      ok: context.l10n.warrantyPrintAct,
    );
    if (!print || !mounted) return;
    final db = ref.read(databaseProvider);
    await runGuarded(context, () async {
      final row = await watchClaim(db, claim.id).first;
      if (row != null) await printClaimAct(db, row);
    });
  }

  void _open(String id) {
    if (context.isWide) {
      setState(() => _selected = id);
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClaimDetailPage(claimId: id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider);
    final async = ref.watch(claimsProvider(_filter));
    if (async.hasValue) _last = async.value;
    final wide = context.isWide;
    final l = context.l10n;
    // no claims at all: one centred empty state instead of a pointless split
    final nothingYet =
        (_last?.isEmpty ?? false) && _filter.query.isEmpty && _filter.group == ClaimGroup.all && _selected == null;

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.l, Gap.l, Gap.l, Gap.s),
          child: SearchField(
            autofocus: wide,
            hint: wide ? l.warrantySearchHintWide : l.warrantySearchHint,
            onChanged: (v) => setState(() => _filter = _filter.copyWith(query: v)),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Gap.l),
          child: Row(
            children: [
              for (final g in ClaimGroup.values)
                Padding(
                  padding: const EdgeInsets.only(right: Gap.s),
                  child: ChoiceChip(
                    label: Text(g.labelIn(l)),
                    selected: _filter.group == g,
                    onSelected: (_) => setState(() => _filter = _filter.copyWith(group: g)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Gap.s),
        if (async.isLoading && _last != null) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _listBody(async)),
      ],
    );

    return PageScaffold(
      title: l.warrantyTitle,
      subtitle: l.warrantySubtitle,
      padding: EdgeInsets.zero,
      actions: [
        if (wide)
          FilledButton.icon(onPressed: () => _create(), icon: const Icon(Icons.add), label: Text(l.warrantyNewClaim)),
      ],
      // the empty state already carries the "new claim" button
      fab: wide || nothingYet
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _create(),
              icon: const Icon(Icons.add),
              label: Text(l.warrantyClaimFab),
            ),
      // no claims at all: nothing to search or filter, just the empty state
      body: nothingYet
          ? _listBody(async)
          : !wide
          ? list
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: list),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 6,
                  child: _selected == null
                      ? EmptyState(
                          icon: Icons.touch_app_outlined,
                          title: l.warrantySelectClaim,
                          message: l.warrantySelectClaimHint,
                        )
                      : ClaimDetailView(key: ValueKey(_selected), claimId: _selected!),
                ),
              ],
            ),
    );
  }

  Widget _listBody(AsyncValue<List<ClaimRow>> async) {
    final rows = async.value ?? _last;
    if (rows == null) {
      if (async.hasError) {
        return ErrorView(error: async.error!, onRetry: () => ref.invalidate(claimsProvider(_filter)));
      }
      return const LoadingView();
    }
    if (rows.isEmpty) {
      final filtered = _filter.query.isNotEmpty || _filter.group != ClaimGroup.all;
      final l = context.l10n;
      return EmptyState(
        icon: Icons.verified_user_outlined,
        title: filtered ? l.commonNothingFound : l.warrantyEmptyTitle,
        message: filtered ? l.warrantyEmptyFiltered : l.warrantyEmptyHint,
        action: filtered
            ? null
            : FilledButton.icon(
                onPressed: () => _create(),
                icon: const Icon(Icons.add),
                label: Text(l.warrantyNewClaim),
              ),
      );
    }
    final more = rows.length >= _filter.limit;
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: rows.length + (more ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i == rows.length) {
          return Padding(
            padding: const EdgeInsets.all(Gap.l),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _filter = _filter.copyWith(limit: _filter.limit + ClaimsFilter.pageSize)),
                icon: const Icon(Icons.expand_more),
                label: Text(context.l10n.warrantyShowMore),
              ),
            ),
          );
        }
        return _ClaimTile(row: rows[i], selected: rows[i].claim.id == _selected, onTap: () => _open(rows[i].claim.id));
      },
    );
  }
}

class _ClaimTile extends StatelessWidget {
  const _ClaimTile({required this.row, required this.selected, required this.onTap});
  final ClaimRow row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final c = row.claim;
    final color = warrantyStatusColor(c.status);
    final days = DateTime.now().difference(c.createdAt).inDays;
    final overdue = WStatus.open.contains(c.status) && days >= 14;
    return ListTile(
      selected: selected,
      selectedTileColor: t.colorScheme.primaryContainer.withValues(alpha: 0.35),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(Icons.verified_user_outlined, color: color, size: 20),
      ),
      title: Text(
        '№${c.number} · ${row.productName ?? l.warrantyNoProduct}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          formatDate(c.createdAt),
          ?row.customerName,
          if (c.serialNumber != null) 'S/N ${c.serialNumber}',
          if (row.saleNumber != null) l.warrantyReceiptShort('${row.saleNumber}'),
          c.problem,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          StatusChip(warrantyStatusLabel(c.status, l), color: color),
          if (overdue)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(l.warrantyDaysShort('$days'), style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
