// POS / Касса — the main selling screen.
//
// Wide (>=1000px): product area on the left, cart panel (420px) on the right.
// Narrow: product area + bottom bar with the total; the cart opens as a page.
// The scanner field keeps focus on desktop: scanners type digits + Enter.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'cart_controller.dart';
import 'parked_carts.dart';
import 'pos_actions.dart';
import 'pos_providers.dart';
import 'widgets/cart_panel.dart';
import 'widgets/product_area.dart';

const _kSideCartMinWidth = 900.0;

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'pos-search');
  Timer? _debounce;
  Timer? _errorTimer;
  String _query = '';
  String? _categoryId;
  String? _scanError;
  bool _busy = false;
  final _scanQueue = <String>[];

  static bool get _isDesktop => switch (defaultTargetPlatform) {
    TargetPlatform.windows || TargetPlatform.linux || TargetPlatform.macOS => true,
    _ => false,
  };

  @override
  void dispose() {
    _debounce?.cancel();
    _errorTimer?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  PosActions _actions(BuildContext context) => PosActions(context, ref, refocus: _refocus);

  /// Returns focus to the scanner field (desktop only: on touch devices it
  /// would pop up the on-screen keyboard after every tap).
  void _refocus() {
    if (!mounted || !_isDesktop) return;
    // only when no dialog/route is on top of us
    if (ModalRoute.of(context)?.isCurrent == false) return;
    _searchFocus.requestFocus();
  }

  void _onSearchChanged(String v) {
    if (_scanError != null) setState(() => _scanError = null);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted && _query != v.trim()) setState(() => _query = v.trim());
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    setState(() {
      _query = '';
      _scanError = null;
    });
    _searchFocus.requestFocus();
  }

  /// Enter in the scanner field. The field is cleared at once and codes are
  /// queued, so a fast scanner never glues two barcodes together while the
  /// previous lookup is still running.
  Future<void> _onSubmitted(String v) async {
    final text = v.trim();
    if (text.isEmpty) {
      _searchFocus.requestFocus();
      return;
    }
    _debounce?.cancel();
    _search.clear();
    _scanQueue.add(text);
    if (_busy) return;
    setState(() {
      _busy = true;
      _scanError = null;
    });
    while (_scanQueue.isNotEmpty) {
      final code = _scanQueue.removeAt(0);
      ScanOutcome outcome;
      try {
        outcome = await _actions(context).submitSearch(code);
      } catch (e) {
        if (mounted) showError(context, e);
        outcome = ScanOutcome.failed;
      }
      if (!mounted) return;
      if (outcome == ScanOutcome.added) continue;
      // Put the text back (selected) unless the cashier already typed or
      // scanned something new: the next scan simply replaces it.
      if (_search.text.isEmpty && _scanQueue.isEmpty) {
        _search.text = code;
        _search.selection = TextSelection(baseOffset: 0, extentOffset: code.length);
        _query = code;
      }
      if (outcome == ScanOutcome.notFound) {
        _scanError = 'Не найдено: $code';
        _errorTimer?.cancel();
        _errorTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _scanError = null);
        });
      }
    }
    setState(() {
      _busy = false;
      if (_search.text.isEmpty) _query = '';
    });
    _searchFocus.requestFocus();
  }

  /// Text typed/scanned while the sale-success dialog was open.
  void _onForwardedScan(ScanForward? f) {
    if (f == null) return;
    Future.microtask(() => ref.read(posScanForwardProvider.notifier).consumed());
    if (!mounted) return;
    if (f.submit) {
      _onSubmitted(f.text);
    } else {
      _search.text = f.text;
      _search.selection = TextSelection.collapsed(offset: f.text.length);
      _onSearchChanged(f.text);
      _searchFocus.requestFocus();
    }
  }

  Future<void> _onTapProduct(Product p) async {
    await _actions(context).addProduct(p);
  }

  // ------------------------------------------------------------ keyboard

  bool _editingOtherText() {
    final f = FocusManager.instance.primaryFocus;
    if (f == null || f == _searchFocus) return false;
    final ctx = f.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText || ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final hw = HardwareKeyboard.instance;
    final a = _actions(context);
    final cart = ref.read(cartProvider);
    final ctl = ref.read(cartProvider.notifier);
    final searchFocused = _searchFocus.hasFocus;
    final searchEmpty = _search.text.isEmpty;

    if (e is KeyDownEvent) {
      if (k == LogicalKeyboardKey.f2) {
        _searchFocus.requestFocus();
        _search.selection = TextSelection(baseOffset: 0, extentOffset: _search.text.length);
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.f4) {
        a.attachCustomer();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.f8) {
        a.park();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.f9) {
        a.showParked();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.f12 ||
          ((k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) && hw.isControlPressed)) {
        if (ref.read(posCanSellProvider)) {
          a.pay();
        } else {
          showError(context, 'Смена не открыта. Откройте смену, чтобы продавать');
        }
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.escape && searchFocused && !searchEmpty) {
        _clearSearch();
        return KeyEventResult.handled;
      }
    }

    if (_editingOtherText()) return KeyEventResult.ignored;
    final sel = cart.selected;
    if (sel == null) return KeyEventResult.ignored;
    // while something is typed into the search box, keys belong to it
    if (searchFocused && !searchEmpty) return KeyEventResult.ignored;

    if (k == LogicalKeyboardKey.delete && e is KeyDownEvent) {
      a.removeLine(sel);
      return KeyEventResult.handled;
    }
    final ch = e.character;
    if (k == LogicalKeyboardKey.numpadAdd || ch == '+') {
      ctl.changeQty(sel.key, 1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.numpadSubtract || ch == '-') {
      ctl.changeQty(sel.key, -1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowUp) {
      ctl.selectNext(-1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown) {
      ctl.selectNext(1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final canSell = ref.watch(posCanSellProvider);
    final session = ref.watch(sessionProvider);
    // keep settings (currency!) loaded
    ref.watch(settingsProvider);
    ref.listen(posScanForwardProvider, (_, next) => _onForwardedScan(next));

    return Focus(
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (context, c) {
          // Side-by-side from ~900px of content: a 1024px landscape tablet
          // (minus the navigation rail) still gets the cart next to the grid.
          final wide = c.maxWidth >= _kSideCartMinWidth;
          final productArea = _ProductArea(
            search: PosSearchBar(
              controller: _search,
              focusNode: _searchFocus,
              onChanged: _onSearchChanged,
              onSubmitted: _onSubmitted,
              onClear: _clearSearch,
              error: _scanError,
              busy: _busy,
            ),
            filter: (query: _query, categoryId: _categoryId),
            onCategory: (id) {
              setState(() => _categoryId = id);
              _refocus();
            },
            onTapProduct: _onTapProduct,
            showHints: wide && _isDesktop,
          );
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!canSell)
                  _ShiftBanner(
                    canOpen: session?.can(Perm.openCloseShift) ?? false,
                    onOpen: () => _actions(context).openShift(),
                  ),
                Expanded(
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: productArea),
                            const VerticalDivider(width: 1),
                            SizedBox(
                              width: c.maxWidth >= Breakpoints.expanded
                                  ? 460
                                  : c.maxWidth >= 1100
                                  ? 420
                                  : 380,
                              child: CartPanel(refocus: _refocus),
                            ),
                          ],
                        )
                      : productArea,
                ),
              ],
            ),
            bottomNavigationBar: wide ? null : _CartBottomBar(onOpen: _openCartPage),
          );
        },
      ),
    );
  }

  Future<void> _openCartPage() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _CartPage()));
    _refocus();
  }
}

// ------------------------------------------------------------------ parts

class _ProductArea extends StatelessWidget {
  const _ProductArea({
    required this.search,
    required this.filter,
    required this.onCategory,
    required this.onTapProduct,
    required this.showHints,
  });

  final Widget search;
  final ProductFilter filter;
  final ValueChanged<String?> onCategory;
  final ValueChanged<Product> onTapProduct;
  final bool showHints;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final compact = context.isCompact;
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? Gap.m : Gap.l, Gap.m, compact ? Gap.m : Gap.l, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: Gap.s),
          CategoryChips(selected: filter.categoryId, onSelected: onCategory),
          const SizedBox(height: Gap.s),
          Expanded(
            child: ProductGrid(filter: filter, onTap: onTapProduct),
          ),
          if (showHints)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Gap.s),
              child: Text(
                'F2 поиск · F4 клиент · F8 отложить · F9 отложенные · F12 / Ctrl+Enter оплата · '
                'Del удалить · +/− количество · ↑↓ выбор позиции · Esc очистить поиск · 3*код — несколько штук',
                style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _ShiftBanner extends StatelessWidget {
  const _ShiftBanner({required this.canOpen, required this.onOpen});
  final bool canOpen;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Material(
      color: AppColors.warning.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.m),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Gap.m,
          runSpacing: Gap.s,
          children: [
            const Icon(Icons.lock_clock, color: AppColors.warning),
            Text(
              canOpen
                  ? 'Смена не открыта — продажи недоступны'
                  : 'Смена не открыта. Попросите менеджера открыть смену',
              style: t.textTheme.titleSmall?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700),
            ),
            if (canOpen)
              FilledButton.icon(
                key: const Key('pos-open-shift'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
                onPressed: onOpen,
                icon: const Icon(Icons.lock_open),
                label: const Text('Открыть смену'),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartBottomBar extends ConsumerWidget {
  const _CartBottomBar({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final cart = ref.watch(cartProvider);
    final quote = ref.watch(cartQuoteProvider).value;
    final total = quote?.total ?? cart.grossTotal;
    return Material(
      color: t.colorScheme.surfaceContainer,
      shape: Border(top: BorderSide(color: t.colorScheme.outlineVariant)),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.m, Gap.s),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: cart.isNotEmpty,
                  label: Text('${cart.lines.length}'),
                  child: const Icon(Icons.shopping_cart_outlined, size: 28),
                ),
                const SizedBox(width: Gap.m),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cart.isEmpty ? 'Чек пуст' : 'Итого · ${cart.lines.length} поз.',
                        style: t.textTheme.bodySmall,
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Money.format(total),
                          key: const Key('bottom-total'),
                          style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  key: const Key('pos-open-cart'),
                  onPressed: onOpen,
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Чек'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartPage extends ConsumerWidget {
  const _CartPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final canSellGift = ref.watch(sessionProvider)?.can(Perm.sell) ?? false;
    final giftHint = giftSaleMenuHint(canSell: canSellGift, hasShift: ref.watch(currentShiftProvider).value != null);
    final parked = ref.watch(parkedCartsProvider).value?.length ?? 0;
    final a = PosActions(
      context,
      ref,
      onSold: () {
        if (context.mounted) Navigator.of(context).maybePop();
      },
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(cart.isEmpty ? 'Чек' : 'Чек · ${cart.lines.length} поз.'),
        // Two clear targets instead of four look-alike icons: parked carts
        // (with a count) and a labelled menu for the rarer actions.
        actions: [
          IconButton(
            tooltip: 'Отложенные чеки',
            onPressed: a.showParked,
            icon: Badge(
              isLabelVisible: parked > 0,
              label: Text('$parked'),
              child: const Icon(Icons.inventory_outlined),
            ),
          ),
          PopupMenuButton<String>(
            key: const Key('pos-cart-menu'),
            tooltip: 'Действия с чеком',
            onSelected: (v) => switch (v) {
              'park' => a.park(),
              'seller' => a.chooseSeller(),
              'clear' => a.clearCart(),
              'gift' => a.sellGiftCard(),
              _ => null,
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'park',
                enabled: cart.isNotEmpty,
                child: const ListTile(leading: Icon(Icons.pause_circle_outline), title: Text('Отложить чек')),
              ),
              const PopupMenuItem(
                value: 'seller',
                child: ListTile(leading: Icon(Icons.badge_outlined), title: Text('Продавец')),
              ),
              PopupMenuItem(
                value: 'gift',
                enabled: canSellGift,
                child: ListTile(
                  leading: const Icon(Icons.card_giftcard),
                  title: const Text('Продать сертификат'),
                  subtitle: giftHint == null ? null : Text(giftHint),
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                enabled: cart.isNotEmpty,
                child: const ListTile(
                  leading: Icon(Icons.delete_sweep_outlined, color: AppColors.danger),
                  title: Text('Очистить чек'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: CartPanel(
          showHeader: false,
          onSold: () {
            if (context.mounted) Navigator.of(context).maybePop();
          },
        ),
      ),
    );
  }
}
