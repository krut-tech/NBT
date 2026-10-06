import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminDashboardMetricsProvider);
    final userProfile = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Bharat Tyre Remould', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'Role: ${userProfile?.role.toUpperCase() ?? "STAFF"}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminDashboardMetricsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardMetricsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metrics Grid
              metricsAsync.when(
                loading: () => const LoadingIndicator(message: 'Loading factory stats...'),
                error: (err, _) => Text('Error loading dashboard: $err'),
                data: (m) {
                  return Column(
                    children: [
                      // Financial Overview Banner
                      Card(
                        color: AppColors.primary,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Today Collection',
                                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(
                                        CurrencyFormatter.format(m['todayCollection']),
                                        style: const TextStyle(
                                          color: AppColors.ready,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Total Outstanding',
                                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(
                                        CurrencyFormatter.format(m['totalOutstanding']),
                                        style: const TextStyle(
                                          color: AppColors.secondaryLight,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Low Stock Alert Banner
                      if ((m['lowStockCount'] as int) > 0) ...[
                        InkWell(
                          onTap: () => context.push('/stock'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.rejected.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.rejected),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning, color: AppColors.rejected),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${m["lowStockCount"]} raw materials below minimum stock! Tap to restock.',
                                    style: const TextStyle(
                                      color: AppColors.rejected,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.rejected),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Grid Cards
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: [
                          _DashboardCard('Received Today', '${m["tyresReceivedToday"]}', Icons.call_received, AppColors.received),
                          _DashboardCard('Production Today', '${m["tyresProductionToday"]}', Icons.precision_manufacturing, AppColors.production),
                          _DashboardCard('Cold Chamber', '${m["coldChamberCount"]}', Icons.ac_unit, AppColors.coldChamber),
                          _DashboardCard('QC Pending', '${m["qcPendingCount"]}', Icons.verified_outlined, AppColors.qc),
                          _DashboardCard('Ready Tyres', '${m["readyTyresCount"]}', Icons.check_circle_outline, AppColors.ready),
                          _DashboardCard('Delivered Today', '${m["deliveredTodayCount"]}', Icons.local_shipping_outlined, AppColors.delivered),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Quick Action Bar
              const Text(
                'Quick Factory Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickActionButton('Receive Tyres', Icons.add_circle, AppColors.secondary, () => context.push('/jobs/new')),
                    const SizedBox(width: 10),
                    _QuickActionButton('Record Payment', Icons.payment, AppColors.ready, () => context.push('/payments/new')),
                    const SizedBox(width: 10),
                    _QuickActionButton('Tyre Delivery', Icons.local_shipping, AppColors.delivered, () => context.push('/delivery')),
                    const SizedBox(width: 10),
                    _QuickActionButton('Stock Entry', Icons.inventory, AppColors.primary, () => context.push('/stock')),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Module Quick Navigation
              const Text(
                'Business Modules',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _ModuleTile('Production', Icons.precision_manufacturing, AppColors.production, () => context.push('/production')),
                  _ModuleTile('Cold Chamber', Icons.ac_unit, AppColors.coldChamber, () => context.push('/cold-chamber')),
                  _ModuleTile('QC Inspection', Icons.verified, AppColors.qc, () => context.push('/qc')),
                  _ModuleTile('Dispatches', Icons.local_shipping, AppColors.delivered, () => context.push('/delivery')),
                  _ModuleTile('Invoices', Icons.receipt_long, AppColors.primary, () => context.push('/invoices')),
                  _ModuleTile('Payments', Icons.payments, AppColors.ready, () => context.push('/payments')),
                  _ModuleTile('Customer Ledger', Icons.menu_book, AppColors.secondary, () => context.push('/ledger')),
                  _ModuleTile('Stock / Materials', Icons.inventory_2, AppColors.primary, () => context.push('/stock')),
                  _ModuleTile('Reports & Analytics', Icons.bar_chart, AppColors.secondary, () => context.push('/reports')),
                  _ModuleTile('Master Data', Icons.settings_suggest, AppColors.primary, () => context.push('/master-data')),
                  _ModuleTile('Staff Users', Icons.badge_outlined, AppColors.primary, () => context.push('/staff')),
                  _ModuleTile('Suppliers', Icons.store_outlined, AppColors.primary, () => context.push('/suppliers')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(120, 42),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleTile(this.title, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
