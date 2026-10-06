import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/app_notification.dart';

class NotificationNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  RealtimeChannel? _subscription;

  NotificationNotifier() : super(const AsyncValue.loading()) {
    fetchNotifications();
    _subscribeRealtime();
  }

  Future<void> fetchNotifications() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final response = await SupabaseService.client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      final list = (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();

      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeRealtime() {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    _subscription = SupabaseService.client
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            fetchNotifications();
          },
        )
        .subscribe();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      await fetchNotifications();
    } catch (e) {
      // Non-blocking notification error
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier,
    AsyncValue<List<AppNotification>>>((ref) => NotificationNotifier());

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).maybeWhen(
        data: (notifications) =>
            notifications.where((n) => !n.isRead).length,
        orElse: () => 0,
      );
});
