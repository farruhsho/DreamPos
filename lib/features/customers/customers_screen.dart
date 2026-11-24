import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(
        title: 'Клиенты',
        body: EmptyState(icon: Icons.construction, title: 'Раздел в разработке'),
      );
}
