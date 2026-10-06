class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? mobileNumber;
  final String? address;
  final String? city;
  final String customerType;
  final bool gstApplicable;
  final String? gstNumber;
  final double openingBalance;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.mobileNumber,
    this.address,
    this.city,
    this.customerType = 'Fleet Owner',
    this.gstApplicable = false,
    this.gstNumber,
    this.openingBalance = 0.0,
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      mobileNumber: json['mobile_number'] as String? ?? json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      customerType: json['customer_type'] as String? ?? 'Fleet Owner',
      gstApplicable: json['gst_applicable'] as bool? ?? false,
      gstNumber: json['gst_number'] as String?,
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone ?? mobileNumber,
      'mobile_number': mobileNumber ?? phone,
      'address': address,
      'city': city,
      'customer_type': customerType,
      'gst_applicable': gstApplicable,
      'gst_number': gstNumber,
      'opening_balance': openingBalance,
      'notes': notes,
      'is_active': isActive,
    };
  }

  String get primaryPhone => (mobileNumber?.isNotEmpty == true)
      ? mobileNumber!
      : (phone ?? '-');
}
