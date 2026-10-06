import '../../customers/models/customer.dart';

class Job {
  final String id;
  final String jobNumber;
  final String customerId;
  final Customer? customer;
  final String tyreSize;
  final String brand;
  final String? pattern;
  final String? tyreType;
  final int quantity;
  final DateTime receivedDate;
  final DateTime? expectedDeliveryDate;
  final String? vehicleNumber;
  final String? notes;
  final String status;
  final List<String> photos;
  final String? qrCodeData;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Job({
    required this.id,
    required this.jobNumber,
    required this.customerId,
    this.customer,
    required this.tyreSize,
    required this.brand,
    this.pattern,
    this.tyreType,
    required this.quantity,
    required this.receivedDate,
    this.expectedDeliveryDate,
    this.vehicleNumber,
    this.notes,
    required this.status,
    this.photos = const [],
    this.qrCodeData,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String,
      jobNumber: json['job_number'] as String,
      customerId: json['customer_id'] as String,
      customer: json['customers'] != null
          ? Customer.fromJson(json['customers'] as Map<String, dynamic>)
          : null,
      tyreSize: json['tyre_size'] as String,
      brand: json['brand'] as String,
      pattern: json['pattern'] as String?,
      tyreType: json['tyre_type'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      receivedDate: DateTime.parse(json['received_date'] as String),
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'] as String)
          : null,
      vehicleNumber: json['vehicle_number'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'Received',
      photos: json['photos'] != null
          ? List<String>.from(json['photos'] as List)
          : const [],
      qrCodeData: json['qr_code_data'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'tyre_size': tyreSize,
      'brand': brand,
      'pattern': pattern,
      'tyre_type': tyreType,
      'quantity': quantity,
      'received_date': receivedDate.toIso8601String().split('T').first,
      'expected_delivery_date':
          expectedDeliveryDate?.toIso8601String().split('T').first,
      'vehicle_number': vehicleNumber,
      'notes': notes,
      'status': status,
      'photos': photos,
      'qr_code_data': qrCodeData,
    };
  }
}
