import 'package:flutter/material.dart';

import '../core/permissions.dart';
import '../l10n/l10n.dart';

/// Single source of truth for main navigation.
class NavItem {
  const NavItem(this.path, this.labelOf, this.icon, this.selectedIcon, this.perm, {this.group = 0});
  final String path;

  /// Label in the given language (`n.labelOf(context.l10n)` in widgets).
  final String Function(AppLocalizations l) labelOf;

  /// Label in the UI language.
  String get label => labelOf(L.current);
  final IconData icon;
  final IconData selectedIcon;
  final Perm perm;
  /// 0 = operations, 1 = management, 2 = admin (used for dividers in drawer)
  final int group;
}

const navItems = <NavItem>[
  NavItem('/dashboard', _dashboard, Icons.space_dashboard_outlined, Icons.space_dashboard, Perm.viewReports),
  NavItem('/pos', _pos, Icons.point_of_sale_outlined, Icons.point_of_sale, Perm.sell),
  NavItem('/sales', _sales, Icons.receipt_long_outlined, Icons.receipt_long, Perm.sell),
  NavItem('/shifts', _shifts, Icons.schedule_outlined, Icons.schedule, Perm.openCloseShift),
  NavItem('/products', _products, Icons.inventory_2_outlined, Icons.inventory_2, Perm.viewProducts, group: 1),
  NavItem('/inventory', _inventory, Icons.warehouse_outlined, Icons.warehouse, Perm.stockOps, group: 1),
  NavItem('/purchasing', _purchasing, Icons.local_shipping_outlined, Icons.local_shipping, Perm.purchasing, group: 1),
  NavItem('/customers', _customers, Icons.people_outline, Icons.people, Perm.viewCustomers, group: 1),
  NavItem('/marketing', _marketing, Icons.campaign_outlined, Icons.campaign, Perm.managePromotions, group: 1),
  NavItem('/warranty', _warranty, Icons.verified_user_outlined, Icons.verified_user, Perm.sell, group: 1),
  NavItem('/reports', _reports, Icons.insights_outlined, Icons.insights, Perm.viewReports, group: 2),
  NavItem('/staff', _staff, Icons.badge_outlined, Icons.badge, Perm.manageStaff, group: 2),
  NavItem('/settings', _settings, Icons.settings_outlined, Icons.settings, Perm.manageSettings, group: 2),
];

// Const tear-offs so navItems can stay const.
String _dashboard(AppLocalizations l) => l.navDashboard;
String _pos(AppLocalizations l) => l.navPos;
String _sales(AppLocalizations l) => l.navSales;
String _shifts(AppLocalizations l) => l.navShifts;
String _products(AppLocalizations l) => l.navProducts;
String _inventory(AppLocalizations l) => l.navInventory;
String _purchasing(AppLocalizations l) => l.navPurchasing;
String _customers(AppLocalizations l) => l.navCustomers;
String _marketing(AppLocalizations l) => l.navMarketing;
String _warranty(AppLocalizations l) => l.navWarranty;
String _reports(AppLocalizations l) => l.navReports;
String _staff(AppLocalizations l) => l.navStaff;
String _settings(AppLocalizations l) => l.navSettings;
