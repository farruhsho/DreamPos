import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(
        title: 'Настройки',
        body: EmptyState(icon: Icons.construction, title: 'Раздел в разработке'),
      );
}
