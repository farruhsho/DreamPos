// Warranty claim workflow rules (pure Dart).
import 'package:flutter/material.dart';

import '../../core/theme.dart';

class WStatus {
  WStatus._();
  static const received = 'received';
  static const inRepair = 'in_repair';
  static const replaced = 'replaced';
  static const refunded = 'refunded';
  static const rejected = 'rejected';
  static const returnedToClient = 'returned_to_client';

  static const all = [received, inRepair, replaced, refunded, rejected, returnedToClient];
  static const open = [received, inRepair];
  static const resolved = [replaced, refunded, rejected];
}

/// received -> in_repair -> (replaced | refunded | rejected) -> returned_to_client
/// A claim may be decided straight from "received" (e.g. obvious defect).
const _transitions = <String, List<String>>{
  WStatus.received: [WStatus.inRepair, WStatus.replaced, WStatus.refunded, WStatus.rejected],
  WStatus.inRepair: [WStatus.replaced, WStatus.refunded, WStatus.rejected],
  WStatus.replaced: [WStatus.returnedToClient],
  WStatus.refunded: [WStatus.returnedToClient],
  WStatus.rejected: [WStatus.returnedToClient],
  WStatus.returnedToClient: [],
};

List<String> nextStatuses(String from) => _transitions[from] ?? const [];

bool canTransition(String from, String to) => nextStatuses(from).contains(to);

bool isClosed(String s) => s == WStatus.returnedToClient;

/// A resolution note is mandatory when the claim is decided.
bool resolutionRequired(String to) => WStatus.resolved.contains(to);

String warrantyStatusLabel(String s) => switch (s) {
  WStatus.received => 'Принят',
  WStatus.inRepair => 'В ремонте',
  WStatus.replaced => 'Замена',
  WStatus.refunded => 'Возврат денег',
  WStatus.rejected => 'Отказ',
  WStatus.returnedToClient => 'Выдан клиенту',
  _ => s,
};

/// Label of the action button that moves a claim INTO [s].
String warrantyActionLabel(String s) => switch (s) {
  WStatus.inRepair => 'Передать в ремонт',
  WStatus.replaced => 'Заменить товар',
  WStatus.refunded => 'Вернуть деньги',
  WStatus.rejected => 'Отказать',
  WStatus.returnedToClient => 'Выдать клиенту',
  _ => warrantyStatusLabel(s),
};

IconData warrantyActionIcon(String s) => switch (s) {
  WStatus.inRepair => Icons.build_outlined,
  WStatus.replaced => Icons.swap_horiz,
  WStatus.refunded => Icons.currency_exchange,
  WStatus.rejected => Icons.do_not_disturb_alt,
  WStatus.returnedToClient => Icons.handshake_outlined,
  _ => Icons.circle_outlined,
};

Color warrantyStatusColor(String s) => switch (s) {
  WStatus.received => AppColors.info,
  WStatus.inRepair => AppColors.warning,
  WStatus.replaced => AppColors.success,
  WStatus.refunded => AppColors.brand,
  WStatus.rejected => AppColors.danger,
  WStatus.returnedToClient => Colors.grey,
  _ => Colors.grey,
};

enum WarrantyState { none, active, expired }

/// Warranty state of a sold item at [now] (the whole last day counts).
WarrantyState warrantyState(DateTime? until, DateTime now) {
  if (until == null) return WarrantyState.none;
  final end = DateTime(until.year, until.month, until.day).add(const Duration(days: 1));
  return now.isBefore(end) ? WarrantyState.active : WarrantyState.expired;
}

/// Filter groups shown as chips in the list.
enum ClaimGroup {
  all('Все', null),
  open('В работе', WStatus.open),
  inRepair('В ремонте', [WStatus.inRepair]),
  resolved('Решены', WStatus.resolved),
  closed('Выданы', [WStatus.returnedToClient]);

  const ClaimGroup(this.label, this.statuses);
  final String label;
  final List<String>? statuses;
}
