class Supplier {
  final String id;
  final String name;
  final String? mobile;
  final String? address;
  final String? gstNumber;
  final String? productsSupplied;
  final String? notes;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    this.mobile,
    this.address,
    this.gstNumber,
    this.productsSupplied,
    this.notes,
    required this.createdAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      name: json['name'] as String,
      mobile: json['mobile'] as String?,
      address: json['address'] as String?,
      gstNumber: json['gst_number'] as String?,
      productsSupplied: json['products_supplied'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
