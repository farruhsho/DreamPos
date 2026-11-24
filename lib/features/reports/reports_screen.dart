import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(
        title: 'Отчёты',
        body: EmptyState(icon: Icons.construction, title: 'Раздел в разработке'),
      );
}
