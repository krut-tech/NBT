import '../../jobs/models/job.dart';

class QcInspection {
  final String id;
  final String jobId;
  final Job? job;
  final bool visualCheck;
  final bool treadCheck;
  final bool sidewallCheck;
  final bool airTest;
  final bool finalInspection;
  final String finalResult; // PASS, FAIL, HOLD
  final String? defectType;
  final String? remarks;
  final String? qcStaffName;
  final String? photoUrl;
  final DateTime createdAt;

  QcInspection({
    required this.id,
    required this.jobId,
    this.job,
    this.visualCheck = true,
    this.treadCheck = true,
    this.sidewallCheck = true,
    this.airTest = true,
    this.finalInspection = true,
    required this.finalResult,
    this.defectType,
    this.remarks,
    this.qcStaffName,
    this.photoUrl,
    required this.createdAt,
  });

  factory QcInspection.fromJson(Map<String, dynamic> json) {
    return QcInspection(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      job: json['jobs'] != null ? Job.fromJson(json['jobs'] as Map<String, dynamic>) : null,
      visualCheck: json['visual_check'] as bool? ?? true,
      treadCheck: json['tread_check'] as bool? ?? true,
      sidewallCheck: json['sidewall_check'] as bool? ?? true,
      airTest: json['air_test'] as bool? ?? true,
      finalInspection: json['final_inspection'] as bool? ?? true,
      finalResult: json['final_result'] as String? ?? 'PASS',
      defectType: json['defect_type'] as String?,
      remarks: json['remarks'] as String?,
      qcStaffName: json['qc_staff_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
