import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(
        title: 'Обзор',
        body: EmptyState(icon: Icons.construction, title: 'Раздел в разработке'),
      );
}
