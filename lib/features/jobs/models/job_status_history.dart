class JobStatusHistory {
  final String id;
  final String jobId;
  final String? previousStatus;
  final String newStatus;
  final String? changedBy;
  final String? changedByName;
  final String? remarks;
  final DateTime createdAt;

  JobStatusHistory({
    required this.id,
    required this.jobId,
    this.previousStatus,
    required this.newStatus,
    this.changedBy,
    this.changedByName,
    this.remarks,
    required this.createdAt,
  });

  factory JobStatusHistory.fromJson(Map<String, dynamic> json) {
    return JobStatusHistory(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      previousStatus: json['previous_status'] as String?,
      newStatus: json['new_status'] as String,
      changedBy: json['changed_by'] as String?,
      changedByName: json['changed_by_name'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
