import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/notification_provider.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(notificationProvider.notifier).fetchNotifications(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading alerts...'),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none_outlined,
              title: 'No Notifications',
              description: 'You are all caught up with factory alerts.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: item.isRead
                    ? null
                    : AppColors.secondary.withValues(alpha: 0.08),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: item.isRead
                        ? Colors.grey.shade300
                        : AppColors.secondary,
                    child: Icon(
                      Icons.notifications,
                      color: item.isRead ? Colors.grey.shade700 : Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight:
                          item.isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.message,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormatter.formatDateTime(item.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    ref
                        .read(notificationProvider.notifier)
                        .markAsRead(item.id);

                    if (item.relatedType == 'JOB' && item.relatedId != null) {
                      context.push('/jobs/${item.relatedId}');
                    } else if (item.relatedType == 'INVOICE') {
                      context.push('/invoices');
                    } else if (item.relatedType == 'PAYMENT') {
                      context.push('/payments');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
