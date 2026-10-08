import 'supabase_service.dart';

/// Moves a job to a new status and records the *real* previous status in
/// `job_status_history` (the previous status is read from the database, so it
/// can never be wrong even if the screen holding the job is stale).
class JobStatusService {
  static Future<String?> advance({
    required String jobId,
    required String newStatus,
    String? remarks,
  }) async {
    final client = SupabaseService.client;

    final row =
        await client.from('jobs').select('status').eq('id', jobId).single();
    final previousStatus = row['status'] as String?;

    // `updated_at` is maintained by a database trigger.
    await client.from('jobs').update({'status': newStatus}).eq('id', jobId);

    await client.from('job_status_history').insert({
      'job_id': jobId,
      'previous_status': previousStatus,
      'new_status': newStatus,
      'changed_by': SupabaseService.currentUserId,
      'remarks': remarks ?? 'Status updated to $newStatus',
    });

    return previousStatus;
  }
}
