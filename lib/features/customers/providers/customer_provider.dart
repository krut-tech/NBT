import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../models/customer.dart';

class CustomerNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  CustomerNotifier() : super(const AsyncValue.loading()) {
    fetchCustomers();
  }

  String _searchQuery = '';
  String _customerTypeFilter = 'All';

  String get searchQuery => _searchQuery;
  String get customerTypeFilter => _customerTypeFilter;

  Future<void> fetchCustomers({String? search, String? type}) async {
    if (search != null) _searchQuery = search;
    if (type != null) _customerTypeFilter = type;

    try {
      var query = SupabaseService.client.from('customers').select();

      if (_customerTypeFilter != 'All') {
        query = query.eq('customer_type', _customerTypeFilter);
      }

      final response = await query.order('name', ascending: true);
      var customers = (response as List)
          .map((json) => Customer.fromJson(json))
          .toList();

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        customers = customers.where((c) {
          return c.name.toLowerCase().contains(q) ||
              (c.phone != null && c.phone!.contains(q)) ||
              (c.city != null && c.city!.toLowerCase().contains(q));
        }).toList();
      }

      state = AsyncValue.data(customers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Customer?> addCustomer(Customer customer) async {
    try {
      final response = await SupabaseService.client
          .from('customers')
          .insert(customer.toJson())
          .select()
          .single();

      final newCustomer = Customer.fromJson(response);
      await fetchCustomers();
      return newCustomer;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCustomer(String id, Customer customer) async {
    try {
      await SupabaseService.client
          .from('customers')
          .update(customer.toJson())
          .eq('id', id);

      await fetchCustomers();
    } catch (e) {
      rethrow;
    }
  }
}

final customerProvider =
    StateNotifierProvider<CustomerNotifier, AsyncValue<List<Customer>>>(
        (ref) => CustomerNotifier());

// Customer Summary metrics provider
final customerSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, customerId) async {
  final client = SupabaseService.client;

  // 1. Fetch tyres/jobs
  final jobsRes = await client
      .from('jobs')
      .select('id, quantity, status')
      .eq('customer_id', customerId);

  int totalTyres = 0;
  int pendingTyres = 0;
  int inProductionTyres = 0;
  int readyTyres = 0;
  int deliveredTyres = 0;

  for (final j in jobsRes) {
    final qty = (j['quantity'] as num?)?.toInt() ?? 1;
    final status = j['status'] as String? ?? 'Received';

    totalTyres += qty;
    if (status == 'Delivered') {
      deliveredTyres += qty;
    } else if (status == 'Ready') {
      readyTyres += qty;
    } else if (status == 'Production' || status == 'Cold Chamber' || status == 'QC') {
      inProductionTyres += qty;
    } else if (status == 'Received' || status == 'Inspection' || status == 'Approved') {
      pendingTyres += qty;
    }
  }

  // 2. Fetch billing & payments
  final invoicesRes = await client
      .from('invoices')
      .select('grand_total')
      .eq('customer_id', customerId);

  double totalBilling = 0.0;
  for (final inv in invoicesRes) {
    totalBilling += (inv['grand_total'] as num?)?.toDouble() ?? 0.0;
  }

  final paymentsRes = await client
      .from('payments')
      .select('amount')
      .eq('customer_id', customerId);

  double totalPaid = 0.0;
  for (final pay in paymentsRes) {
    totalPaid += (pay['amount'] as num?)?.toDouble() ?? 0.0;
  }

  // Fetch customer opening balance
  final custRes = await client
      .from('customers')
      .select('opening_balance')
      .eq('id', customerId)
      .maybeSingle();

  double openingBalance = (custRes?['opening_balance'] as num?)?.toDouble() ?? 0.0;
  double outstanding = (totalBilling + openingBalance) - totalPaid;

  return {
    'totalTyres': totalTyres,
    'pendingTyres': pendingTyres,
    'inProductionTyres': inProductionTyres,
    'readyTyres': readyTyres,
    'deliveredTyres': deliveredTyres,
    'totalBilling': totalBilling,
    'totalPaid': totalPaid,
    'openingBalance': openingBalance,
    'outstanding': outstanding,
  };
});
