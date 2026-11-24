import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/permissions.dart';
import '../core/providers.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/setup_screen.dart';
import '../features/customers/customers_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/marketing/marketing_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/pos/pos_screen.dart';
import '../features/products/products_screen.dart';
import '../features/purchasing/purchasing_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/sales/sales_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shifts/shifts_screen.dart';
import '../features/staff/staff_screen.dart';
import '../features/warranty/warranty_screen.dart';
import 'nav.dart';
import 'shell.dart';

/// Landing page for a role.
String homeFor(Session s) => s.can(Perm.sell)
    ? '/pos'
    : s.can(Perm.viewReports)
        ? '/dashboard'
        : s.can(Perm.stockOps)
            ? '/inventory'
            : '/products';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  Page<void> page(Widget child) => NoTransitionPage(child: child);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final setup = ref.read(setupDoneProvider);
      if (setup.isLoading) return null;
      final done = setup.value ?? false;
      final loc = state.matchedLocation;
      if (!done) return loc == '/setup' ? null : '/setup';
      if (loc == '/setup') return '/login';
      final session = ref.read(sessionProvider);
      if (session == null) return loc == '/login' ? null : '/login';
      if (loc == '/login' || loc == '/') return homeFor(session);
      // permission guard
      for (final n in navItems) {
        if (loc.startsWith(n.path) && !session.can(n.perm)) return homeFor(session);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/login'),
      GoRoute(path: '/setup', builder: (_, _) => const SetupScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/dashboard', pageBuilder: (_, _) => page(const DashboardScreen())),
          GoRoute(path: '/pos', pageBuilder: (_, _) => page(const PosScreen())),
          GoRoute(path: '/sales', pageBuilder: (_, _) => page(const SalesScreen())),
          GoRoute(path: '/shifts', pageBuilder: (_, _) => page(const ShiftsScreen())),
          GoRoute(path: '/products', pageBuilder: (_, _) => page(const ProductsScreen())),
          GoRoute(path: '/inventory', pageBuilder: (_, _) => page(const InventoryScreen())),
          GoRoute(path: '/purchasing', pageBuilder: (_, _) => page(const PurchasingScreen())),
          GoRoute(path: '/customers', pageBuilder: (_, _) => page(const CustomersScreen())),
          GoRoute(path: '/marketing', pageBuilder: (_, _) => page(const MarketingScreen())),
          GoRoute(path: '/warranty', pageBuilder: (_, _) => page(const WarrantyScreen())),
          GoRoute(path: '/reports', pageBuilder: (_, _) => page(const ReportsScreen())),
          GoRoute(path: '/staff', pageBuilder: (_, _) => page(const StaffScreen())),
          GoRoute(path: '/settings', pageBuilder: (_, _) => page(const SettingsScreen())),
          GoRoute(path: '/notifications', pageBuilder: (_, _) => page(const NotificationsScreen())),
        ],
      ),
    ],
  );
});
