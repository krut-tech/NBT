class AppConstants {
  static const String appName = 'New Bharat Tyre Remould';
  static const String companyTagline = 'Cold Process Tyre Remoulding';

  // Tyre Status List
  static const List<String> tyreStatuses = [
    'Received',
    'Inspection',
    'Approved',
    'Production',
    'Cold Chamber',
    'QC',
    'Ready',
    'Delivered',
    'Rejected',
    'Scrap',
    'Hold',
  ];

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleProductionStaff = 'production_staff';
  static const String roleQcStaff = 'qc_staff';
  static const String roleBillingStaff = 'billing_staff';
  static const String roleCustomer = 'customer';

  static const List<String> allRoles = [
    roleAdmin,
    roleManager,
    roleProductionStaff,
    roleQcStaff,
    roleBillingStaff,
    roleCustomer,
  ];

  static String getRoleDisplayName(String role) {
    switch (role) {
      case roleAdmin:
        return 'Admin';
      case roleManager:
        return 'Manager';
      case roleProductionStaff:
        return 'Production Staff';
      case roleQcStaff:
        return 'QC Staff';
      case roleBillingStaff:
        return 'Billing Staff';
      case roleCustomer:
        return 'Customer';
      default:
        return role;
    }
  }

  // Master Categories
  static const String categoryTyreSize = 'tyre_size';
  static const String categoryTyreBrand = 'tyre_brand';
  static const String categoryPattern = 'pattern';
  static const String categoryTyreType = 'tyre_type';
  static const String categoryMachine = 'machine';
  static const String categoryColdChamber = 'cold_chamber';
  static const String categoryOperator = 'operator';
  static const String categoryQcDefectType = 'qc_defect_type';
  static const String categoryStockCategory = 'stock_category';
  static const String categoryUnit = 'unit';
  static const String categoryPaymentMethod = 'payment_method';
  static const String categoryCustomerType = 'customer_type';
}
