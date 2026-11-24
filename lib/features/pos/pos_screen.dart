import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(
        title: 'Касса',
        body: EmptyState(icon: Icons.construction, title: 'Раздел в разработке'),
      );
}
