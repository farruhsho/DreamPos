import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class WarrantyScreen extends StatelessWidget {
  const WarrantyScreen({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(
        title: 'Гарантия',
        body: EmptyState(icon: Icons.construction, title: 'Раздел в разработке'),
      );
}
