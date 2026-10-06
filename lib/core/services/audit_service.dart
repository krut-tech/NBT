import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class AuditService {
  static Future<void> logAction({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? details,
    String? userName,
    String? userRole,
  }) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      await SupabaseService.client.from('audit_logs').insert({
        'user_id': user.id,
        'user_name': userName ?? user.email ?? 'Staff',
        'user_role': userRole ?? 'staff',
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'details': details ?? {},
      });
    } catch (e) {
      // Non-blocking log recording
      debugPrint('Audit log error: $e');
    }
  }
}
