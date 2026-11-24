import '../l10n/l10n.dart';

/// Role-based access control.
enum Role {
  owner,
  admin,
  manager,
  cashier,
  storekeeper;

  /// Localized name in [l].
  String labelIn(AppLocalizations l) => switch (this) {
        Role.owner => l.roleOwner,
        Role.admin => l.roleAdmin,
        Role.manager => l.roleManager,
        Role.cashier => l.roleCashier,
        Role.storekeeper => l.roleStorekeeper,
      };

  /// Localized name in the UI language.
  String get label => labelIn(L.current);

  static Role parse(String s) =>
      Role.values.firstWhere((r) => r.name == s, orElse: () => Role.cashier);
}

enum Perm {
  sell,
  applyDiscount,
  voidSale,
  refund,
  openCloseShift,
  cashInOut,
  viewProducts,
  editProducts,
  editPrices,
  viewCost,
  stockOps, // receipts, write-offs, inventory counts
  purchasing,
  viewCustomers,
  editCustomers,
  manageDebts,
  managePromotions,
  viewReports,
  viewAllShifts,
  manageStaff,
  manageSettings,
  viewAudit,
}

const _rolePerms = <Role, Set<Perm>>{
  Role.owner: {...Perm.values},
  Role.admin: {...Perm.values},
  Role.manager: {
    Perm.sell,
    Perm.applyDiscount,
    Perm.voidSale,
    Perm.refund,
    Perm.openCloseShift,
    Perm.cashInOut,
    Perm.viewProducts,
    Perm.editProducts,
    Perm.editPrices,
    Perm.viewCost,
    Perm.stockOps,
    Perm.purchasing,
    Perm.viewCustomers,
    Perm.editCustomers,
    Perm.manageDebts,
    Perm.managePromotions,
    Perm.viewReports,
    Perm.viewAllShifts,
  },
  Role.cashier: {
    Perm.sell,
    Perm.openCloseShift,
    Perm.cashInOut,
    Perm.viewProducts,
    Perm.viewCustomers,
    Perm.editCustomers,
  },
  Role.storekeeper: {
    Perm.viewProducts,
    Perm.editProducts,
    Perm.viewCost,
    Perm.stockOps,
    Perm.purchasing,
  },
};

extension RolePerms on Role {
  bool can(Perm p) => _rolePerms[this]!.contains(p);
}
