import 'package:flutter/material.dart';

import '../core/permissions.dart';

/// Single source of truth for main navigation.
class NavItem {
  const NavItem(this.path, this.label, this.icon, this.selectedIcon, this.perm, {this.group = 0});
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Perm perm;
  /// 0 = operations, 1 = management, 2 = admin (used for dividers in drawer)
  final int group;
}

const navItems = <NavItem>[
  NavItem('/dashboard', 'Обзор', Icons.space_dashboard_outlined, Icons.space_dashboard, Perm.viewReports),
  NavItem('/pos', 'Касса', Icons.point_of_sale_outlined, Icons.point_of_sale, Perm.sell),
  NavItem('/sales', 'Чеки', Icons.receipt_long_outlined, Icons.receipt_long, Perm.sell),
  NavItem('/shifts', 'Смена', Icons.schedule_outlined, Icons.schedule, Perm.openCloseShift),
  NavItem('/products', 'Товары', Icons.inventory_2_outlined, Icons.inventory_2, Perm.viewProducts, group: 1),
  NavItem('/inventory', 'Склад', Icons.warehouse_outlined, Icons.warehouse, Perm.stockOps, group: 1),
  NavItem('/purchasing', 'Закупки', Icons.local_shipping_outlined, Icons.local_shipping, Perm.purchasing, group: 1),
  NavItem('/customers', 'Клиенты', Icons.people_outline, Icons.people, Perm.viewCustomers, group: 1),
  NavItem('/marketing', 'Маркетинг', Icons.campaign_outlined, Icons.campaign, Perm.managePromotions, group: 1),
  NavItem('/warranty', 'Гарантия', Icons.verified_user_outlined, Icons.verified_user, Perm.sell, group: 1),
  NavItem('/reports', 'Отчёты', Icons.insights_outlined, Icons.insights, Perm.viewReports, group: 2),
  NavItem('/staff', 'Сотрудники', Icons.badge_outlined, Icons.badge, Perm.manageStaff, group: 2),
  NavItem('/settings', 'Настройки', Icons.settings_outlined, Icons.settings, Perm.manageSettings, group: 2),
];
