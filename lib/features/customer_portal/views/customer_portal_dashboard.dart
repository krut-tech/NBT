import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../jobs/providers/job_provider.dart';

class CustomerPortalDashboard extends ConsumerWidget {
  const CustomerPortalDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(authProvider).value;
    final customerId = userProfile?.customerId;

    if (customerId == null || customerId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Portal')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_off_outlined, size: 64, color: AppColors.textSecondaryLight),
                const SizedBox(height: 16),
                const Text(
                  'Customer Profile Not Linked',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please contact New Bharat Tyre Remould office staff to link your phone number to your business account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.read(authProvider.notifier).signOut(),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final summaryAsync = ref.watch(customerSummaryProvider(customerId));
    final jobsAsync = ref.watch(customerJobsProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${userProfile?.fullName ?? "Customer"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerSummaryProvider(customerId));
          ref.read(jobProvider.notifier).fetchJobs(customerId: customerId);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              summaryAsync.when(
                loading: () => const LoadingIndicator(message: 'Loading portal data...'),
                error: (err, _) => Text('Error: $err'),
                data: (summary) {
                  final outstanding = summary['outstanding'] as double;
                  return Card(
                    color: AppColors.primary,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Outstanding Balance',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(outstanding),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: outstanding > 0
                                  ? AppColors.secondaryLight
                                  : AppColors.ready,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Tyres Sent: ${summary["totalTyres"]}',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              Text(
                                'Ready for Pick: ${summary["readyTyres"]}',
                                style: const TextStyle(
                                    color: AppColors.ready,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/ledger', extra: {'customerId': customerId}),
                      icon: const Icon(Icons.menu_book),
                      label: const Text('View Ledger'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                      onPressed: () => context.push('/payments'),
                      icon: const Icon(Icons.receipt),
                      label: const Text('Invoices'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Your Tyre Jobs & Real-Time Tracking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Jobs list
              jobsAsync.when(
                loading: () => const LoadingIndicator(message: 'Loading tyres...'),
                error: (err, _) => Text('Error: $err'),
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: const [
                            Icon(Icons.tire_repair, size: 40, color: AppColors.textSecondaryLight),
                            SizedBox(height: 8),
                            Text('No active tyre jobs found.'),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          title: Text(
                            'Job #${job.jobNumber} (${job.quantity} Tyres)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${job.brand} • ${job.tyreSize}'),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Text('Status: ',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    job.status,
                                    style: TextStyle(
                                      color: AppColors.getStatusColor(job.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.push('/jobs/${job.id}', extra: job),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
