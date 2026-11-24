import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(
        title: 'Сотрудники',
        body: EmptyState(icon: Icons.construction, title: 'Раздел в разработке'),
      );
}
