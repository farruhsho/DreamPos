import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class MarketingScreen extends StatelessWidget {
  const MarketingScreen({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(
        title: 'Маркетинг',
        body: EmptyState(icon: Icons.construction, title: 'Раздел в разработке'),
      );
}
