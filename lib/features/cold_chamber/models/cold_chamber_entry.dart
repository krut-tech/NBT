import '../../jobs/models/job.dart';

class ColdChamberEntry {
  final String id;
  final String jobId;
  final Job? job;
  final String? chamberName;
  final String? operatorName;
  final int quantity;
  final DateTime? startTime;
  final DateTime? endTime;
  final double? temperature;
  final String status;
  final String? notes;
  final DateTime createdAt;

  ColdChamberEntry({
    required this.id,
    required this.jobId,
    this.job,
    this.chamberName,
    this.operatorName,
    this.quantity = 1,
    this.startTime,
    this.endTime,
    this.temperature,
    this.status = 'Completed',
    this.notes,
    required this.createdAt,
  });

  factory ColdChamberEntry.fromJson(Map<String, dynamic> json) {
    return ColdChamberEntry(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      job: json['jobs'] != null ? Job.fromJson(json['jobs'] as Map<String, dynamic>) : null,
      chamberName: json['chamber_name'] as String?,
      operatorName: json['operator_name'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      temperature: (json['temperature'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'Completed',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
