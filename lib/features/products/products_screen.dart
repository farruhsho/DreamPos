import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(
        title: 'Товары',
        body: EmptyState(icon: Icons.construction, title: 'Раздел в разработке'),
      );
}
