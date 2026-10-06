class UserProfile {
  final String id;
  final String fullName;
  final String? phone;
  final String role;
  final String? customerId;
  final bool isActive;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.fullName,
    this.phone,
    required this.role,
    this.customerId,
    this.isActive = true,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'User',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'customer',
      customerId: json['customer_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'customer_id': customerId,
      'is_active': isActive,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isProductionStaff => role == 'production_staff';
  bool get isQcStaff => role == 'qc_staff';
  bool get isBillingStaff => role == 'billing_staff';
  bool get isCustomer => role == 'customer';

  bool get isStaff =>
      isAdmin || isManager || isProductionStaff || isQcStaff || isBillingStaff;
}
