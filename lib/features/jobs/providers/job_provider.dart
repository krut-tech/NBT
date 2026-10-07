import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../models/job.dart';
import '../models/job_status_history.dart';

class JobFilterState {
  final String searchQuery;
  final String statusFilter;
  final String? customerId;

  JobFilterState({
    this.searchQuery = '',
    this.statusFilter = 'All',
    this.customerId,
  });

  JobFilterState copyWith({
    String? searchQuery,
    String? statusFilter,
    String? customerId,
  }) {
    return JobFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      customerId: customerId ?? this.customerId,
    );
  }
}

class JobNotifier extends StateNotifier<AsyncValue<List<Job>>> {
  JobNotifier() : super(const AsyncValue.loading()) {
    fetchJobs();
  }

  JobFilterState _filters = JobFilterState();
  JobFilterState get filters => _filters;

  Future<void> fetchJobs({
    String? search,
    String? status,
    String? customerId,
  }) async {
    _filters = _filters.copyWith(
      searchQuery: search,
      statusFilter: status,
      customerId: customerId,
    );

    try {
      var query = SupabaseService.client.from('jobs').select('*, customers(*)');

      if (_filters.statusFilter != 'All') {
        query = query.eq('status', _filters.statusFilter);
      }

      if (_filters.customerId != null && _filters.customerId!.isNotEmpty) {
        query = query.eq('customer_id', _filters.customerId!);
      }

      final response = await query.order('created_at', ascending: false);
      var jobs = (response as List).map((json) => Job.fromJson(json)).toList();

      if (_filters.searchQuery.isNotEmpty) {
        final q = _filters.searchQuery.toLowerCase();
        jobs = jobs.where((j) {
          final custName = j.customer?.name.toLowerCase() ?? '';
          return j.jobNumber.toLowerCase().contains(q) ||
              custName.contains(q) ||
              j.tyreSize.toLowerCase().contains(q) ||
              j.brand.toLowerCase().contains(q) ||
              (j.vehicleNumber != null &&
                  j.vehicleNumber!.toLowerCase().contains(q));
        }).toList();
      }

      state = AsyncValue.data(jobs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Job> createJob({
    required String customerId,
    required String tyreSize,
    required String brand,
    String? pattern,
    String? tyreType,
    required int quantity,
    required DateTime receivedDate,
    DateTime? expectedDeliveryDate,
    String? vehicleNumber,
    String? notes,
    List<File> imageFiles = const [],
  }) async {
    try {
      final client = SupabaseService.client;

      // 1. Generate Job Number using SQL function
      final genRes =
          await client.rpc('generate_job_number').single();
      final jobNumber = genRes as String? ??
          'NBT-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // 2. Upload photos if any
      final storageService = StorageService();
      List<String> uploadedPhotoUrls = [];
      for (final file in imageFiles) {
        final url = await storageService.uploadPhoto(
          file: file,
          bucketName: 'tyre-photos',
          folderPath: 'jobs/$jobNumber',
        );
        if (url != null) uploadedPhotoUrls.add(url);
      }

      // 3. Insert Job
      final response = await client
          .from('jobs')
          .insert({
            'job_number': jobNumber,
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
            'status': 'Received',
            'photos': uploadedPhotoUrls,
            'created_by': SupabaseService.currentUserId,
          })
          .select('*, customers(*)')
          .single();

      final newJob = Job.fromJson(response);

      // 4. Insert initial Job Status History
      await client.from('job_status_history').insert({
        'job_id': newJob.id,
        'previous_status': null,
        'new_status': 'Received',
        'changed_by': SupabaseService.currentUserId,
        'remarks': 'Job created & tyres received.',
      });

      // 5. Audit Log
      await AuditService.logAction(
        action: 'CREATE_JOB',
        entityType: 'JOB',
        entityId: newJob.id,
        details: {'job_number': jobNumber, 'quantity': quantity},
      );

      await fetchJobs();
      return newJob;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateJobStatus({
    required String jobId,
    required String currentStatus,
    required String newStatus,
    String? remarks,
  }) async {
    try {
      final client = SupabaseService.client;

      // 1. Update status
      await client
          .from('jobs')
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', jobId);

      // 2. Record status history
      await client.from('job_status_history').insert({
        'job_id': jobId,
        'previous_status': currentStatus,
        'new_status': newStatus,
        'changed_by': SupabaseService.currentUserId,
        'remarks': remarks ?? 'Status updated to $newStatus',
      });

      // 3. Audit Log
      await AuditService.logAction(
        action: 'UPDATE_JOB_STATUS',
        entityType: 'JOB',
        entityId: jobId,
        details: {'from': currentStatus, 'to': newStatus, 'remarks': remarks},
      );

      await fetchJobs();
    } catch (e) {
      rethrow;
    }
  }
}

final jobProvider =
    StateNotifierProvider<JobNotifier, AsyncValue<List<Job>>>(
        (ref) => JobNotifier());

// Status history provider for a specific job
final jobHistoryProvider =
    FutureProvider.family<List<JobStatusHistory>, String>((ref, jobId) async {
  final response = await SupabaseService.client
      .from('job_status_history')
      .select()
      .eq('job_id', jobId)
      .order('created_at', ascending: true);

  return (response as List)
      .map((json) => JobStatusHistory.fromJson(json))
      .toList();
});


final customerJobsProvider =
    FutureProvider.family<List<Job>, String>((ref, customerId) async {
  final response = await SupabaseService.client
      .from('jobs')
      .select('*, customers(*)')
      .eq('customer_id', customerId)
      .order('created_at', ascending: false);

  return (response as List)
      .map((json) => Job.fromJson(json))
      .toList();
});
