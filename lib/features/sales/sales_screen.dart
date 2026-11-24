import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(
        title: 'Чеки',
        body: EmptyState(icon: Icons.construction, title: 'Раздел в разработке'),
      );
}
