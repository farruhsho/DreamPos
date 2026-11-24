import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class ShiftsScreen extends StatelessWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(
        title: 'Смена',
        body: EmptyState(icon: Icons.construction, title: 'Раздел в разработке'),
      );
}
