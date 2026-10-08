import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/job_status_service.dart';
import '../../../core/services/supabase_service.dart';
import '../models/qc_inspection.dart';

class QcNotifier extends StateNotifier<AsyncValue<List<QcInspection>>> {
  QcNotifier() : super(const AsyncValue.loading()) {
    fetchInspections();
  }

  Future<void> fetchInspections() async {
    try {
      final response = await SupabaseService.client
          .from('qc_inspections')
          .select('*, jobs(*, customers(*))')
          .order('created_at', ascending: false);

      final inspections = (response as List)
          .map((json) => QcInspection.fromJson(json))
          .toList();

      state = AsyncValue.data(inspections);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createQcInspection({
    required String jobId,
    required bool visualCheck,
    required bool treadCheck,
    required bool sidewallCheck,
    required bool airTest,
    required bool finalInspection,
    required String finalResult, // PASS, FAIL, HOLD
    String? defectType,
    String? remarks,
    String? qcStaffName,
  }) async {
    try {
      final client = SupabaseService.client;

      // 1. Insert QC Record
      await client.from('qc_inspections').insert({
        'job_id': jobId,
        'visual_check': visualCheck,
        'tread_check': treadCheck,
        'sidewall_check': sidewallCheck,
        'air_test': airTest,
        'final_inspection': finalInspection,
        'final_result': finalResult,
        'defect_type': defectType,
        'remarks': remarks,
        'qc_staff_id': SupabaseService.currentUserId,
        'qc_staff_name': qcStaffName ?? 'QC Inspector',
      });

      // 2. Determine target job status
      String newJobStatus = 'Ready';
      if (finalResult == 'FAIL') {
        newJobStatus = 'Rejected';
      } else if (finalResult == 'HOLD') {
        newJobStatus = 'Hold';
      }

      // 3. Update Job Status (+ history with the real previous status)
      await JobStatusService.advance(
        jobId: jobId,
        newStatus: newJobStatus,
        remarks: 'QC Inspection: $finalResult. ${remarks ?? ''}'.trim(),
      );

      // 4. Audit Log
      await AuditService.logAction(
        action: 'QC_INSPECTION',
        entityType: 'JOB',
        entityId: jobId,
        details: {'result': finalResult, 'defect': defectType, 'remarks': remarks},
      );

      await fetchInspections();
    } catch (e) {
      rethrow;
    }
  }
}

final qcProvider = StateNotifierProvider<QcNotifier,
    AsyncValue<List<QcInspection>>>((ref) => QcNotifier());
