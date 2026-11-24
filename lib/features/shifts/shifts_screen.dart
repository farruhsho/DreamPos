import 'package:flutter/material.dart';

import 'shifts_view.dart';
import 'z_report.dart';
import 'z_report_pdf.dart';

/// Cash shift: open/close (Z), live X-report, cash operations, history.
/// Route entry point; wires PDF printing into [ShiftsView].
class ShiftsScreen extends StatelessWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    zReportPrinter ??= printZReport;
    return const ShiftsView();
  }
}
