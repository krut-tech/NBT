import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.bar_chart, color: AppColors.secondary, size: 30),
              title: const Text('Visual Production & Financial Charts', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Interactive graphs for factory output & collection'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/reports/analytics'),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(Icons.tire_repair, color: AppColors.primary, size: 30),
              title: const Text('Tyre Lifecycle & Status Report', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Received, Production, Chamber, QC, Ready & Delivered'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/jobs'),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: AppColors.ready, size: 30),
              title: const Text('Invoices & Collection Report', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Tax invoices, receipts & unpaid balance list'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/invoices'),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2, color: AppColors.production, size: 30),
              title: const Text('Stock & Material Consumption Report', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Tread rubber, bonding cement, chemicals & low stock'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/stock/transactions'),
            ),
          ),
        ],
      ),
    );
  }
}
