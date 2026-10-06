import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/supabase_service.dart';
import '../models/delivery.dart';

class DeliveryNotifier extends StateNotifier<AsyncValue<List<Delivery>>> {
  DeliveryNotifier() : super(const AsyncValue.loading()) {
    fetchDeliveries();
  }

  Future<void> fetchDeliveries() async {
    try {
      final response = await SupabaseService.client
          .from('deliveries')
          .select('*, customers(*), jobs(*)')
          .order('created_at', ascending: false);

      final deliveries =
          (response as List).map((json) => Delivery.fromJson(json)).toList();

      state = AsyncValue.data(deliveries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Delivery> createDelivery({
    required String customerId,
    required String jobId,
    required int readyQuantity,
    required int deliveredQuantity,
    required DateTime deliveryDate,
    String? vehicleNumber,
    String? driverName,
    String? receivedBy,
    String? notes,
  }) async {
    try {
      final client = SupabaseService.client;

      // 1. Generate Delivery Number
      final genRes = await client.rpc('generate_delivery_number').single();
      final deliveryNumber = genRes as String? ??
          'DEL-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final remainingQuantity = readyQuantity - deliveredQuantity;

      // 2. Insert Delivery Record
      final response = await client
          .from('deliveries')
          .insert({
            'delivery_number': deliveryNumber,
            'customer_id': customerId,
            'job_id': jobId,
            'ready_quantity': readyQuantity,
            'delivered_quantity': deliveredQuantity,
            'remaining_quantity': remainingQuantity > 0 ? remainingQuantity : 0,
            'delivery_date': deliveryDate.toIso8601String().split('T').first,
            'vehicle_number': vehicleNumber,
            'driver_name': driverName,
            'received_by': receivedBy,
            'notes': notes,
            'created_by': SupabaseService.currentUserId,
          })
          .select('*, customers(*), jobs(*)')
          .single();

      final delivery = Delivery.fromJson(response);

      // 3. Update Job status if fully delivered
      final newJobStatus = remainingQuantity <= 0 ? 'Delivered' : 'Ready';
      await client
          .from('jobs')
          .update({'status': newJobStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', jobId);

      // 4. Record history
      await client.from('job_status_history').insert({
        'job_id': jobId,
        'previous_status': 'Ready',
        'new_status': newJobStatus,
        'changed_by': SupabaseService.currentUserId,
        'remarks':
            'Delivered $deliveredQuantity tyres. Remaining: ${remainingQuantity > 0 ? remainingQuantity : 0}',
      });

      // 5. Audit Log
      await AuditService.logAction(
        action: 'CREATE_DELIVERY',
        entityType: 'DELIVERY',
        entityId: delivery.id,
        details: {
          'delivery_number': deliveryNumber,
          'delivered_quantity': deliveredQuantity,
          'received_by': receivedBy
        },
      );

      await fetchDeliveries();
      return delivery;
    } catch (e) {
      rethrow;
    }
  }
}

final deliveryProvider =
    StateNotifierProvider<DeliveryNotifier, AsyncValue<List<Delivery>>>(
        (ref) => DeliveryNotifier());
