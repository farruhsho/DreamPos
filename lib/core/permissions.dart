/// Role-based access control.
enum Role {
  owner('Владелец'),
  admin('Администратор'),
  manager('Менеджер'),
  cashier('Кассир'),
  storekeeper('Кладовщик');

  const Role(this.label);
  final String label;

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
