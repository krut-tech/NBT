import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';

final adminDashboardMetricsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final client = SupabaseService.client;
  final now = DateTime.now();
  final todayStr = now.toIso8601String().split('T').first;
  final tomorrowStr = DateTime(now.year, now.month, now.day + 1)
      .toIso8601String()
      .split('T')
      .first;

  int sumInt(Iterable<dynamic> rows, String key) =>
      rows.fold<int>(0, (sum, row) => sum + ((row[key] as num?)?.toInt() ?? 0));

  double sumDouble(Iterable<dynamic> rows, String key) => rows.fold<double>(
        0,
        (sum, row) => sum + ((row[key] as num?)?.toDouble() ?? 0),
      );

  final received = await client
      .from('jobs')
      .select('quantity')
      .eq('received_date', todayStr);

  final produced = await client
      .from('production_entries')
      .select('quantity')
      .gte('created_at', '${todayStr}T00:00:00')
      .lt('created_at', '${tomorrowStr}T00:00:00');

  final jobs = await client.from('jobs').select('status, quantity');

  final deliveries = await client
      .from('deliveries')
      .select('delivered_quantity')
      .eq('delivery_date', todayStr);

  final paymentsToday = await client
      .from('payments')
      .select('amount')
      .eq('payment_date', todayStr);

  final allInvoices = await client.from('invoices').select('grand_total');
  final allPayments = await client.from('payments').select('amount');
  final customers = await client.from('customers').select('opening_balance');
  final stock =
      await client.from('stock_items').select('current_stock, minimum_stock');

  int cold = 0, qc = 0, ready = 0, active = 0;

  for (final row in jobs) {
    final qty = (row['quantity'] as num?)?.toInt() ?? 0;
    switch (row['status']) {
      case 'Cold Chamber':
        cold += qty;
        break;
      case 'QC':
        qc += qty;
        break;
      case 'Ready':
        ready += qty;
        break;
    }

    if (row['status'] != 'Delivered' && row['status'] != 'Scrap') {
      active += qty;
    }
  }

  final totalInvoiced = sumDouble(allInvoices, 'grand_total');
  final totalPaid = sumDouble(allPayments, 'amount');
  final totalOpening = sumDouble(customers, 'opening_balance');

  return {
    'tyresReceivedToday': sumInt(received, 'quantity'),
    'tyresProductionToday': sumInt(produced, 'quantity'),
    'coldChamberCount': cold,
    'qcPendingCount': qc,
    'readyTyresCount': ready,
    'deliveredTodayCount': sumInt(deliveries, 'delivered_quantity'),
    'todayCollection': sumDouble(paymentsToday, 'amount'),
    'totalOutstanding': totalInvoiced + totalOpening - totalPaid,
    'lowStockCount': stock.where((row) {
      final current = (row['current_stock'] as num?)?.toDouble() ?? 0;
      final minimum = (row['minimum_stock'] as num?)?.toDouble() ?? 0;
      return current <= minimum;
    }).length,
    'totalActiveJobs': active,
  };
});
