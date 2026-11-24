import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class PurchasingScreen extends StatelessWidget {
  const PurchasingScreen({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(
        title: 'Закупки',
        body: EmptyState(icon: Icons.construction, title: 'Раздел в разработке'),
      );
}
