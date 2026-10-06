import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/supabase_service.dart';
import '../models/cold_chamber_entry.dart';

class ColdChamberNotifier extends StateNotifier<AsyncValue<List<ColdChamberEntry>>> {
  ColdChamberNotifier() : super(const AsyncValue.loading()) {
    fetchEntries();
  }

  Future<void> fetchEntries() async {
    try {
      final response = await SupabaseService.client
          .from('cold_chamber_entries')
          .select('*, jobs(*, customers(*))')
          .order('created_at', ascending: false);

      final entries = (response as List)
          .map((json) => ColdChamberEntry.fromJson(json))
          .toList();

      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createChamberEntry({
    required String jobId,
    required String chamberName,
    required String operatorName,
    required int quantity,
    required double temperature,
    String? notes,
  }) async {
    try {
      final client = SupabaseService.client;

      // 1. Insert Cold Chamber Entry
      await client.from('cold_chamber_entries').insert({
        'job_id': jobId,
        'chamber_name': chamberName,
        'operator_name': operatorName,
        'quantity': quantity,
        'temperature': temperature,
        'start_time': DateTime.now().toIso8601String(),
        'end_time': DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
        'status': 'Completed',
        'notes': notes,
        'created_by': SupabaseService.currentUserId,
      });

      // 2. Advance Job Status to 'QC'
      await client
          .from('jobs')
          .update({'status': 'QC', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', jobId);

      // 3. Record status history
      await client.from('job_status_history').insert({
        'job_id': jobId,
        'previous_status': 'Cold Chamber',
        'new_status': 'QC',
        'changed_by': SupabaseService.currentUserId,
        'remarks': 'Cold curing complete ($temperature°C). Moved to QC.',
      });

      // 4. Audit Log
      await AuditService.logAction(
        action: 'COLD_CHAMBER_COMPLETED',
        entityType: 'JOB',
        entityId: jobId,
        details: {'chamber': chamberName, 'temp': temperature, 'quantity': quantity},
      );

      await fetchEntries();
    } catch (e) {
      rethrow;
    }
  }
}

final coldChamberProvider = StateNotifierProvider<ColdChamberNotifier,
    AsyncValue<List<ColdChamberEntry>>>((ref) => ColdChamberNotifier());
