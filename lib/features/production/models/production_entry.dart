import '../../jobs/models/job.dart';

class ProductionEntry {
  final String id;
  final String jobId;
  final Job? job;
  final String? machine;
  final String? operatorName;
  final int quantity;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;
  final String? notes;
  final List<String> photos;
  final DateTime createdAt;

  ProductionEntry({
    required this.id,
    required this.jobId,
    this.job,
    this.machine,
    this.operatorName,
    this.quantity = 1,
    this.startTime,
    this.endTime,
    this.status = 'Completed',
    this.notes,
    this.photos = const [],
    required this.createdAt,
  });

  factory ProductionEntry.fromJson(Map<String, dynamic> json) {
    return ProductionEntry(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      job: json['jobs'] != null ? Job.fromJson(json['jobs'] as Map<String, dynamic>) : null,
      machine: json['machine'] as String?,
      operatorName: json['operator_name'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      status: json['status'] as String? ?? 'Completed',
      notes: json['notes'] as String?,
      photos: json['photos'] != null
          ? List<String>.from(json['photos'] as List)
          : const [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
