import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/models/customer.dart';
import '../../customers/providers/customer_provider.dart';

final staffListProvider = FutureProvider<List<UserProfile>>((ref) async {
  final response = await SupabaseService.client
      .from('profiles')
      .select()
      .order('full_name', ascending: true);

  return (response as List).map((json) => UserProfile.fromJson(json)).toList();
});

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  /// Who may change whom (the database enforces the same rules):
  /// admins manage everybody except themselves, managers manage non-admins.
  bool _canManage(UserProfile actor, UserProfile target) {
    if (actor.id == target.id) return false;
    if (actor.isAdmin) return true;
    return actor.isManager && !target.isAdmin;
  }

  Future<void> _changeRole(BuildContext context, WidgetRef ref,
      UserProfile target, String role) async {
    try {
      await ref
          .read(authRepositoryProvider)
          .updateRole(userId: target.id, role: role);
      ref.invalidate(staffListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${target.fullName} is now ${AppConstants.getRoleDisplayName(role)}'),
            backgroundColor: AppColors.ready,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not change role: ${friendlyError(e)}'),
            backgroundColor: AppColors.rejected,
          ),
        );
      }
    }
  }

  Future<void> _linkCustomer(
      BuildContext context, WidgetRef ref, UserProfile target) async {
    final customers = ref.read(customerProvider).valueOrNull ?? <Customer>[];
    Customer? selected =
        customers.where((c) => c.id == target.customerId).firstOrNull;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: Text('Link ${target.fullName} to a customer'),
              content: SearchableDropdown<Customer>(
                label: 'Customer',
                value: selected,
                items: customers,
                itemAsString: (c) => '${c.name} (${c.primaryPhone})',
                onChanged: (val) => setDialogState(() => selected = val),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  child: const Text('Link'),
                ),
              ],
            );
          },
        );
      },
    );

    final customer = selected;
    if (confirmed != true || customer == null) return;

    try {
      await ref
          .read(authRepositoryProvider)
          .updateCustomerLink(userId: target.id, customerId: customer.id);
      ref.invalidate(staffListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${target.fullName} linked to ${customer.name}'),
            backgroundColor: AppColors.ready,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not link customer: ${friendlyError(e)}'),
            backgroundColor: AppColors.rejected,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);
    final actor = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff & User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(staffListProvider),
          ),
        ],
      ),
      body: staffAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading user profiles...'),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.people_outline,
              title: 'No Profiles Found',
              description:
                  'People who register appear here. Open the menu on a user to give them a staff role.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final user = profiles[index];

              final canManage = actor != null && _canManage(actor, user);
              final assignableRoles = AppConstants.allRoles
                  .where((r) => r != user.role && (actor?.isAdmin == true || r != AppConstants.roleAdmin))
                  .toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Role: ${AppConstants.getRoleDisplayName(user.role)} ${user.phone != null ? "• ${user.phone}" : ""}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user.role,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      if (canManage)
                        PopupMenuButton<String>(
                          tooltip: 'Manage account',
                          onSelected: (value) {
                            if (value == 'link') {
                              _linkCustomer(context, ref, user);
                            } else {
                              _changeRole(context, ref, user, value);
                            }
                          },
                          itemBuilder: (_) => [
                            for (final role in assignableRoles)
                              PopupMenuItem<String>(
                                value: role,
                                child: Text(
                                    'Make ${AppConstants.getRoleDisplayName(role)}'),
                              ),
                            if (user.isCustomer)
                              const PopupMenuItem<String>(
                                value: 'link',
                                child: Text('Link to customer record'),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
