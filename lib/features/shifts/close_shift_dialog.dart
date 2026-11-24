import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'shift_logic.dart';
import 'shift_providers.dart';
import 'z_report.dart';

/// Opens the close-shift (Z) flow. Returns true when the shift was closed.
Future<bool> showCloseShiftDialog(BuildContext context, String shiftId) async {
  // The caller (open-shift dashboard) is unmounted as soon as the shift is
  // closed, so the Z-report is shown from the navigator's own context.
  final navContext = Navigator.of(context).context;
  final closed = await showFormDialog<bool>(
    context,
    title: context.l10n.shiftClosingTitle,
    width: 620,
    child: _CloseShiftForm(shiftId: shiftId),
  );
  if (closed == true && navContext.mounted) {
    await showZReportDialog(navContext, shiftId, title: navContext.l10n.shiftClosed);
  }
  return closed == true;
}

class _CloseShiftForm extends ConsumerStatefulWidget {
  const _CloseShiftForm({required this.shiftId});
  final String shiftId;

  @override
  ConsumerState<_CloseShiftForm> createState() => _CloseShiftFormState();
}

class _CloseShiftFormState extends ConsumerState<_CloseShiftForm> {
  bool _byDenomination = true;
  CashCount _count = CashCount();
  int? _total;
  int _collection = 0;
  final _note = TextEditingController();
  final _totalCtl = TextEditingController();
  final _collectionCtl = TextEditingController();
  final Map<int, TextEditingController> _denCtl = {};
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    _totalCtl.dispose();
    _collectionCtl.dispose();
    for (final c in _denCtl.values) {
      c.dispose();
    }
    super.dispose();
  }

  int? get _counted => _byDenomination ? _count.total : _total;

  Future<void> _submit(int expected) async {
    if (_busy) return;
    final l = context.l10n;
    final err = validateClose(
        counted: _counted, expected: expected, note: _note.text, collection: _collection, l: l);
    setState(() => _error = err);
    if (err != null) return;
    final counted = _counted!;
    final diff = counted - expected;
    final ok = await confirm(
      context,
      title: l.shiftCloseConfirmTitle,
      message: [
        l.shiftCountedValue(Money.format(counted)),
        l.shiftExpectedValue(Money.format(expected)),
        if (diff != 0) '${diff < 0 ? l.shiftShortage : l.shiftSurplus}: ${Money.format(diff.abs())}',
        if (_collection > 0) l.shiftCollectionAtCloseValue(Money.format(_collection)),
        '',
        l.shiftCloseConfirmMessage,
      ].join('\n'),
      ok: l.shiftCloseAction,
    );
    if (!ok || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final db = ref.read(databaseProvider);
    final collection = _collection;
    final parts = <String>[
      if (_note.text.trim().isNotEmpty) _note.text.trim(),
      // Written to the shift note in the DB: not translated.
      if (_byDenomination && _count.pieces > 0) 'Купюры: ${_count.describe(Money.currency)}', // l10n-ignore
    ];
    setState(() => _busy = true);
    final success = await runGuarded(
      context,
      () => closeShiftWithCollection(
        db,
        shiftId: widget.shiftId,
        userId: session.user.id,
        counted: counted,
        collection: collection,
        note: parts.isEmpty ? null : parts.join('\n'),
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) Navigator.pop(context, true);
  }

  TextEditingController _ctlFor(int d) =>
      _denCtl.putIfAbsent(d, () => TextEditingController(text: '${_count.counts[d] ?? ''}'));

  @override
  Widget build(BuildContext context) {
    final fig = ref.watch(shiftFiguresProvider(widget.shiftId));
    return AsyncView(value: fig, data: (f) => _form(context, f.expectedCash, giftCashNet: f.report.giftCashNet));
  }

  Widget _form(BuildContext context, int expected, {int giftCashNet = 0}) {
    final t = Theme.of(context);
    final l = context.l10n;
    final counted = _counted;
    final diff = counted == null ? null : counted - expected;
    final kind = counted == null ? null : classifyDiff(counted, expected);
    final diffColor = switch (kind) {
      CashDiff.shortage => AppColors.danger,
      CashDiff.surplus => AppColors.warning,
      CashDiff.exact => AppColors.success,
      null => t.colorScheme.onSurfaceVariant,
    };
    final dens = denominationsFor(Money.currency);
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.enter, control: true): () => _submit(expected)},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.shiftCountCashHint,
                    style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: Gap.m),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                          value: true, icon: const Icon(Icons.payments_outlined), label: Text(l.shiftByDenomination)),
                      ButtonSegment(
                          value: false, icon: const Icon(Icons.calculate_outlined), label: Text(l.shiftByTotal)),
                    ],
                    selected: {_byDenomination},
                    onSelectionChanged: (s) => setState(() {
                      _byDenomination = s.first;
                      if (!_byDenomination && _total == null && _count.total > 0) {
                        _total = _count.total;
                        _totalCtl.text = Money.toInput(_total!);
                      }
                    }),
                  ),
                  const SizedBox(height: Gap.m),
                  if (_byDenomination)
                    LayoutBuilder(
                      builder: (context, c) {
                        final cols = c.maxWidth >= 480 ? 2 : 1;
                        final w = (c.maxWidth - Gap.m * (cols - 1)) / cols;
                        return Wrap(
                          spacing: Gap.m,
                          runSpacing: Gap.s,
                          children: [
                            for (final (i, d) in dens.indexed)
                              SizedBox(
                                width: w,
                                child: _DenominationRow(
                                  key: ValueKey('den_$d'),
                                  denomination: d,
                                  controller: _ctlFor(d),
                                  autofocus: i == 0,
                                  onChanged: (n) => setState(() => _count = _count.withCount(d, n)),
                                ),
                              ),
                          ],
                        );
                      },
                    )
                  else
                    MoneyField(
                      key: const ValueKey('close_total'),
                      label: l.shiftCashInDrawer,
                      controller: _totalCtl,
                      autofocus: true,
                      onChanged: (v) => setState(() => _total = v),
                      onSubmitted: (_) => _submit(expected),
                    ),
                  const SizedBox(height: Gap.l),
                  Card(
                    color: diffColor.withValues(alpha: 0.06),
                    child: Padding(
                      padding: const EdgeInsets.all(Gap.l),
                      child: Column(
                        children: [
                          _kv(context, l.shiftExpectedInDrawer, Money.format(expected)),
                          if (giftCashNet != 0)
                            _kv(
                              context,
                              l.shiftInclGiftCash,
                              '${giftCashNet < 0 ? '−' : '+'}${Money.format(giftCashNet.abs())}',
                            ),
                          _kv(context, l.shiftCounted, counted == null ? '—' : Money.format(counted), bold: true),
                          const Divider(height: Gap.l),
                          _kv(
                            context,
                            switch (kind) {
                              CashDiff.shortage => l.shiftShortage,
                              CashDiff.surplus => l.shiftSurplus,
                              _ => l.shiftDifference,
                            },
                            diff == null ? '—' : Money.format(diff.abs()),
                            color: diffColor,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Gap.l),
                  TextField(
                    controller: _note,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: diff != null && diff != 0 ? l.shiftDiffReasonLabel : l.shiftNoteOptional,
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: Gap.m),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(l.shiftCollectionAtClose),
                    subtitle: Text(
                      _collection > 0
                          ? l.shiftCollectionSummary(
                              Money.format(_collection), Money.format((counted ?? 0) - _collection))
                          : l.shiftCollectionHint,
                      style: t.textTheme.bodySmall,
                    ),
                    children: [
                      MoneyField(
                        key: const ValueKey('close_collection'),
                        label: l.shiftCollectionAmount,
                        controller: _collectionCtl,
                        onChanged: (v) => setState(() => _collection = v ?? 0),
                      ),
                      const SizedBox(height: Gap.s),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: counted == null || counted <= 0
                              ? null
                              : () => setState(() {
                                  _collection = counted;
                                  _collectionCtl.text = Money.toInput(counted);
                                }),
                          child: Text(l.shiftCollectAll),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Gap.s),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                    ),
                ],
              ),
            ),
          ),
          // On phones the summary card scrolls away behind the denomination
          // list, so the running total stays pinned above the buttons.
          if (MediaQuery.sizeOf(context).height < 900 || MediaQuery.sizeOf(context).width < 600)
            Container(
              key: const ValueKey('close_sticky_total'),
              padding: const EdgeInsets.symmetric(horizontal: Gap.xl, vertical: Gap.s),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: t.colorScheme.outlineVariant)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: Gap.m,
                runSpacing: 2,
                children: [
                  Text(l.shiftCountedValue(counted == null ? '—' : Money.format(counted)),
                      style: t.textTheme.titleSmall),
                  if (diff != null)
                    Text(
                      diff == 0
                          ? l.shiftNoDifference
                          : '${diff < 0 ? l.shiftShortageLower : l.shiftSurplusLower} ${Money.format(diff.abs())}',
                      style: t.textTheme.bodySmall?.copyWith(color: diffColor, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.l),
            child: OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: Gap.s,
              children: [
                TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(l.commonCancel)),
                FilledButton.icon(
                  key: const ValueKey('close_submit'),
                  onPressed: _busy ? null : () => _submit(expected),
                  icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.lock_clock),
                  label: Text(l.shiftCloseAction),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v, {Color? color, bool bold = false}) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(k, style: t.bodyMedium?.copyWith(color: color)),
          ),
          Text(
            v,
            style: (bold ? t.titleMedium : t.bodyMedium)?.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DenominationRow extends StatelessWidget {
  const _DenominationRow({
    super.key,
    required this.denomination,
    required this.controller,
    required this.onChanged,
    this.autofocus = false,
  });

  final int denomination;
  final TextEditingController controller;
  final ValueChanged<int> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final n = int.tryParse(controller.text) ?? 0;
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(Money.format(denomination, withSymbol: false), textAlign: TextAlign.right, style: t.titleSmall),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Gap.s),
          child: Text('×'),
        ),
        SizedBox(
          width: 76,
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
            onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
          ),
        ),
        const SizedBox(width: Gap.s),
        Expanded(
          child: Text(
            n == 0 ? '' : '= ${Money.format(denomination * n, withSymbol: false)}',
            textAlign: TextAlign.right,
            style: t.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
