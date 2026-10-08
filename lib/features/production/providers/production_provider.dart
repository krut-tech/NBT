import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/job_status_service.dart';
import '../../../core/services/supabase_service.dart';
import '../models/production_entry.dart';

class ProductionNotifier extends StateNotifier<AsyncValue<List<ProductionEntry>>> {
  ProductionNotifier() : super(const AsyncValue.loading()) {
    fetchEntries();
  }

  Future<void> fetchEntries() async {
    try {
      final response = await SupabaseService.client
          .from('production_entries')
          .select('*, jobs(*, customers(*))')
          .order('created_at', ascending: false);

      final entries = (response as List)
          .map((json) => ProductionEntry.fromJson(json))
          .toList();

      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createProductionEntry({
    required String jobId,
    required String machine,
    required String operatorName,
    required int quantity,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
  }) async {
    try {
      final client = SupabaseService.client;

      // 1. Insert Production Entry
      await client.from('production_entries').insert({
        'job_id': jobId,
        'machine': machine,
        'operator_name': operatorName,
        'quantity': quantity,
        'start_time': (startTime ?? DateTime.now()).toIso8601String(),
        'end_time': (endTime ?? DateTime.now()).toIso8601String(),
        'status': 'Completed',
        'notes': notes,
        'created_by': SupabaseService.currentUserId,
      });

      // 2. Advance Job Status to 'Cold Chamber' (+ history with the real previous status)
      await JobStatusService.advance(
        jobId: jobId,
        newStatus: 'Cold Chamber',
        remarks: 'Building complete. Moved to Cold Chamber.',
      );

      // 3. Audit Log
      await AuditService.logAction(
        action: 'PRODUCTION_COMPLETED',
        entityType: 'JOB',
        entityId: jobId,
        details: {'machine': machine, 'operator': operatorName, 'quantity': quantity},
      );

      await fetchEntries();
    } catch (e) {
      rethrow;
    }
  }
}

final productionProvider = StateNotifierProvider<ProductionNotifier,
    AsyncValue<List<ProductionEntry>>>((ref) => ProductionNotifier());
