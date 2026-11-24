import 'package:flutter/material.dart';

/// Lets an empty/error state scroll instead of overflowing on short screens
/// (phones in landscape, tall filter bars).
class FillScroll extends StatelessWidget {
  const FillScroll({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: c.maxHeight.isFinite ? c.maxHeight : 0),
        child: child,
      ),
    ),
  );
}
