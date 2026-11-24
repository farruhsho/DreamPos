import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'gift_cards_tab.dart';
import 'loyalty_tab.dart';
import 'mailing_tab.dart';
import 'promotions_tab.dart';

/// Marketing: promotions, gift cards, loyalty overview, customer lists.
class MarketingScreen extends StatelessWidget {
  const MarketingScreen({super.key});

  static const _tabs = [
    Tab(icon: Icon(Icons.campaign_outlined), text: 'Акции'),
    Tab(icon: Icon(Icons.card_giftcard), text: 'Сертификаты'),
    Tab(icon: Icon(Icons.stars_outlined), text: 'Лояльность'),
    Tab(icon: Icon(Icons.forward_to_inbox_outlined), text: 'Рассылки'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: PageScaffold(
        title: 'Маркетинг',
        padding: EdgeInsets.zero,
        // Left-aligned compact tabs on every size: stretched across a 1440px
        // monitor they drifted far from the width-capped content below.
        bottom: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: EdgeInsets.symmetric(horizontal: Gap.s),
          labelPadding: EdgeInsets.symmetric(horizontal: Gap.l),
          tabs: _tabs,
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
