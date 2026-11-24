import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(
        title: 'Уведомления',
        body: EmptyState(icon: Icons.construction, title: 'Раздел в разработке'),
      );
}
