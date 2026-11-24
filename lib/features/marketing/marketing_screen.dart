import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'gift_cards_tab.dart';
import 'loyalty_tab.dart';
import 'mailing_tab.dart';
import 'promotions_tab.dart';

/// Marketing: promotions, gift cards, loyalty overview, customer lists.
class MarketingScreen extends StatelessWidget {
  const MarketingScreen({super.key});

  static List<Tab> _tabs(AppLocalizations l) => [
    Tab(icon: const Icon(Icons.campaign_outlined), text: l.mktTabPromos),
    Tab(icon: const Icon(Icons.card_giftcard), text: l.mktTabGiftCards),
    Tab(icon: const Icon(Icons.stars_outlined), text: l.mktTabLoyalty),
    Tab(icon: const Icon(Icons.forward_to_inbox_outlined), text: l.mktTabMailing),
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs(context.l10n);
    return DefaultTabController(
      length: tabs.length,
      child: PageScaffold(
        title: context.l10n.mktTitle,
        padding: EdgeInsets.zero,
        // Left-aligned compact tabs on every size: stretched across a 1440px
        // monitor they drifted far from the width-capped content below.
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: Gap.s),
          labelPadding: const EdgeInsets.symmetric(horizontal: Gap.l),
          tabs: tabs,
        ),
        body: const TabBarView(children: [
          PromotionsTab(),
          GiftCardsTab(),
          LoyaltyTab(),
          MailingTab(),
        ]),
      ),
    );
  }
}
