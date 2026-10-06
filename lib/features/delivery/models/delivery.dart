import '../../customers/models/customer.dart';
import '../../jobs/models/job.dart';

class Delivery {
  final String id;
  final String deliveryNumber;
  final String customerId;
  final Customer? customer;
  final String jobId;
  final Job? job;
  final int readyQuantity;
  final int deliveredQuantity;
  final int remainingQuantity;
  final DateTime deliveryDate;
  final String? vehicleNumber;
  final String? driverName;
  final String? receivedBy;
  final String? signatureUrl;
  final String? proofPhotoUrl;
  final String? notes;
  final DateTime createdAt;

  Delivery({
    required this.id,
    required this.deliveryNumber,
    required this.customerId,
    this.customer,
    required this.jobId,
    this.job,
    required this.readyQuantity,
    required this.deliveredQuantity,
    required this.remainingQuantity,
    required this.deliveryDate,
    this.vehicleNumber,
    this.driverName,
    this.receivedBy,
    this.signatureUrl,
    this.proofPhotoUrl,
    this.notes,
    required this.createdAt,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] as String,
      deliveryNumber: json['delivery_number'] as String,
      customerId: json['customer_id'] as String,
      customer: json['customers'] != null
          ? Customer.fromJson(json['customers'] as Map<String, dynamic>)
          : null,
      jobId: json['job_id'] as String,
      job: json['jobs'] != null
          ? Job.fromJson(json['jobs'] as Map<String, dynamic>)
          : null,
      readyQuantity: (json['ready_quantity'] as num?)?.toInt() ?? 0,
      deliveredQuantity: (json['delivered_quantity'] as num?)?.toInt() ?? 0,
      remainingQuantity: (json['remaining_quantity'] as num?)?.toInt() ?? 0,
      deliveryDate: DateTime.parse(json['delivery_date'] as String),
      vehicleNumber: json['vehicle_number'] as String?,
      driverName: json['driver_name'] as String?,
      receivedBy: json['received_by'] as String?,
      signatureUrl: json['signature_url'] as String?,
      proofPhotoUrl: json['proof_photo_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
