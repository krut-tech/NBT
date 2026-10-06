import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';

final adminDashboardMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = SupabaseService.client;
  final todayStr = DateTime.now().toIso8601String().split('T').first;

  // 1. Tyres received today
  final receivedTodayRes = await client
      .from('jobs')
      .select('quantity')
      .eq('received_date', todayStr);

  int tyresReceivedToday = 0;
  for (final row in receivedTodayRes) {
    tyresReceivedToday += (row['quantity'] as num?)?.toInt() ?? 1;
  }

  // 2. Production today count
  final prodTodayRes = await client
      .from('production_entries')
      .select('quantity')
      .gte('created_at', '${todayStr}T00:00:00');

  int tyresProductionToday = 0;
  for (final row in prodTodayRes) {
    tyresProductionToday += (row['quantity'] as num?)?.toInt() ?? 1;
  }

  // 3. Counts by status
  final allJobsRes = await client.from('jobs').select('status, quantity');

  int coldChamberCount = 0;
  int qcPendingCount = 0;
  int readyTyresCount = 0;
  int totalActiveJobs = 0;

  for (final j in allJobsRes) {
    final status = j['status'] as String? ?? '';
    final qty = (j['quantity'] as num?)?.toInt() ?? 1;

    if (status == 'Cold Chamber') coldChamberCount += qty;
    if (status == 'QC') qcPendingCount += qty;
    if (status == 'Ready') readyTyresCount += qty;
    if (status != 'Delivered' && status != 'Scrap') totalActiveJobs += qty;
  }

  // 4. Delivered today
  final deliveredTodayRes = await client
      .from('deliveries')
      .select('delivered_quantity')
      .eq('delivery_date', todayStr);

  int deliveredTodayCount = 0;
  for (final row in deliveredTodayRes) {
    deliveredTodayCount += (row['delivered_quantity'] as num?)?.toInt() ?? 0;
  }

  // 5. Today's payment collection
  final paymentsTodayRes = await client
      .from('payments')
      .select('amount')
      .eq('payment_date', todayStr);

  double todayCollection = 0.0;
  for (final row in paymentsTodayRes) {
    todayCollection += (row['amount'] as num?)?.toDouble() ?? 0.0;
  }

  // 6. Total outstanding amount
  final invoicesRes = await client.from('invoices').select('grand_total');
  double totalInvoiced = 0.0;
  for (final row in invoicesRes) {
    totalInvoiced += (row['grand_total'] as num?)?.toDouble() ?? 0.0;
  }

  final allPaymentsRes = await client.from('payments').select('amount');
  double totalPaid = 0.0;
  for (final row in allPaymentsRes) {
    totalPaid += (row['amount'] as num?)?.toDouble() ?? 0.0;
  }

  final custRes = await client.from('customers').select('opening_balance');
  double totalOpeningBal = 0.0;
  for (final row in custRes) {
    totalOpeningBal += (row['opening_balance'] as num?)?.toDouble() ?? 0.0;
  }

  double totalOutstanding = (totalInvoiced + totalOpeningBal) - totalPaid;

  // 7. Low stock items count
  final stockRes = await client.from('stock_items').select('current_stock, minimum_stock');
  int lowStockCount = 0;
  for (final row in stockRes) {
    final cur = (row['current_stock'] as num?)?.toDouble() ?? 0.0;
    final min = (row['minimum_stock'] as num?)?.toDouble() ?? 0.0;
    if (cur <= min) lowStockCount++;
  }

  return {
    'tyresReceivedToday': tyresReceivedToday,
    'tyresProductionToday': tyresProductionToday,
    'coldChamberCount': coldChamberCount,
    'qcPendingCount': qcPendingCount,
    'readyTyresCount': readyTyresCount,
    'deliveredTodayCount': deliveredTodayCount,
    'todayCollection': todayCollection,
    'totalOutstanding': totalOutstanding,
    'lowStockCount': lowStockCount,
    'totalActiveJobs': totalActiveJobs,
  };
});
