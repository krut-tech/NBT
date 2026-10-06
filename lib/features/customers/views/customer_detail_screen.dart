import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  void _callCustomer(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _whatsappCustomer(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final Uri url = Uri.parse('https://wa.me/91$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(customerSummaryProvider(customer.id));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(customer.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.push('/customers/edit', extra: customer),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.secondary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Overview & Tyres'),
              Tab(text: 'Invoices'),
              Tab(text: 'Payments'),
              Tab(text: 'Ledger'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Overview & Tyres
            _CustomerOverviewTab(
              customer: customer,
              summaryAsync: summaryAsync,
              onCall: () => _callCustomer(customer.primaryPhone),
              onWhatsapp: () => _whatsappCustomer(customer.primaryPhone),
            ),

            // Tab 2: Invoices Placeholder / Content
            _CustomerInvoicesTab(customerId: customer.id),

            // Tab 3: Payments Placeholder / Content
            _CustomerPaymentsTab(customerId: customer.id),

            // Tab 4: Ledger Placeholder / Content
            _CustomerLedgerTab(customerId: customer.id, customerName: customer.name),
          ],
        ),
      ),
    );
  }
}

class _CustomerOverviewTab extends StatelessWidget {
  final Customer customer;
  final AsyncValue<Map<String, dynamic>> summaryAsync;
  final VoidCallback onCall;
  final VoidCallback onWhatsapp;

  const _CustomerOverviewTab({
    required this.customer,
    required this.summaryAsync,
    required this.onCall,
    required this.onWhatsapp,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Profile Card
          Card(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.secondary,
                        child: Text(
                          customer.name.isNotEmpty
                              ? customer.name[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (customer.city != null)
                              Text(
                                customer.city!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        onPressed: onCall,
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Call'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: onWhatsapp,
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('WhatsApp'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Metrics Grid
          summaryAsync.when(
            loading: () => const LoadingIndicator(message: 'Loading stats...'),
            error: (err, _) => Text('Error loading summary: $err'),
            data: (summary) {
              final outstanding = summary['outstanding'] as double;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Outstanding Alert Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: outstanding > 0
                          ? AppColors.rejected.withValues(alpha: 0.12)
                          : AppColors.ready.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: outstanding > 0
                            ? AppColors.rejected
                            : AppColors.ready,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Outstanding Balance',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(outstanding),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: outstanding > 0
                                    ? AppColors.rejected
                                    : AppColors.ready,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            minimumSize: const Size(100, 40),
                          ),
                          onPressed: () => context.push('/payments/new',
                              extra: {'customer': customer}),
                          icon: const Icon(Icons.payment, size: 16),
                          label: const Text('Pay'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Tyre Lifecycle Metrics',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _MetricCard(
                        title: 'Total Tyres Received',
                        value: '${summary['totalTyres']}',
                        icon: Icons.tire_repair,
                        color: AppColors.received,
                      ),
                      _MetricCard(
                        title: 'In Production',
                        value: '${summary['inProductionTyres']}',
                        icon: Icons.precision_manufacturing,
                        color: AppColors.production,
                      ),
                      _MetricCard(
                        title: 'Ready for Delivery',
                        value: '${summary['readyTyres']}',
                        icon: Icons.check_circle_outline,
                        color: AppColors.ready,
                      ),
                      _MetricCard(
                        title: 'Total Delivered',
                        value: '${summary['deliveredTyres']}',
                        icon: Icons.local_shipping_outlined,
                        color: AppColors.delivered,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/jobs/new', extra: customer),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Receive New Tyres'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerInvoicesTab extends StatelessWidget {
  final String customerId;

  const _CustomerInvoicesTab({required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 48, color: AppColors.textSecondaryLight),
          const SizedBox(height: 12),
          const Text('Invoices for this customer'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.push('/invoices/new', extra: {'customerId': customerId}),
            icon: const Icon(Icons.add),
            label: const Text('Create Invoice'),
          ),
        ],
      ),
    );
  }
}

class _CustomerPaymentsTab extends StatelessWidget {
  final String customerId;

  const _CustomerPaymentsTab({required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.payment, size: 48, color: AppColors.textSecondaryLight),
          const SizedBox(height: 12),
          const Text('Payment History'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.push('/payments/new', extra: {'customerId': customerId}),
            icon: const Icon(Icons.add),
            label: const Text('Add Payment'),
          ),
        ],
      ),
    );
  }
}

class _CustomerLedgerTab extends StatelessWidget {
  final String customerId;
  final String customerName;

  const _CustomerLedgerTab({
    required this.customerId,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book, size: 48, color: AppColors.textSecondaryLight),
          const SizedBox(height: 12),
          Text('Customer Ledger for $customerName'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.push('/ledger', extra: {'customerId': customerId}),
            icon: const Icon(Icons.visibility),
            label: const Text('View Full Ledger'),
          ),
        ],
      ),
    );
  }
}
