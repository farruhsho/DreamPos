import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(
        title: 'Склад',
        body: EmptyState(icon: Icons.construction, title: 'Раздел в разработке'),
      );
}
