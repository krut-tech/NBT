import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../models/customer_ledger.dart';

class LedgerNotifier extends StateNotifier<AsyncValue<List<CustomerLedger>>> {
  LedgerNotifier() : super(const AsyncValue.loading());

  Future<void> fetchCustomerLedger(String customerId) async {
    state = const AsyncValue.loading();
    try {
      final client = SupabaseService.client;

      // 1. Fetch opening balance of customer
      final custRes = await client
          .from('customers')
          .select('opening_balance, name')
          .eq('id', customerId)
          .maybeSingle();

      final double openingBal =
          (custRes?['opening_balance'] as num?)?.toDouble() ?? 0.0;

      // 2. Fetch all ledger rows chronologically
      final response = await client
          .from('customer_ledgers')
          .select()
          .eq('customer_id', customerId)
          .order('transaction_date', ascending: true)
          .order('created_at', ascending: true);

      final rawList =
          (response as List).map((json) => CustomerLedger.fromJson(json)).toList();

      // 3. Compute running balance
      double runningBal = openingBal;
      final List<CustomerLedger> computedList = [];

      // Add Opening Balance Header Entry if non-zero
      if (openingBal != 0) {
        computedList.add(CustomerLedger(
          id: 'op_bal',
          customerId: customerId,
          transactionDate: DateTime(2026, 1, 1),
          description: 'Opening Balance',
          debit: openingBal > 0 ? openingBal : 0.0,
          credit: openingBal < 0 ? openingBal.abs() : 0.0,
          balance: runningBal,
          referenceType: 'OPENING_BALANCE',
        ));
      }

      for (final item in rawList) {
        runningBal += (item.debit - item.credit);
        computedList.add(CustomerLedger(
          id: item.id,
          customerId: item.customerId,
          transactionDate: item.transactionDate,
          description: item.description,
          debit: item.debit,
          credit: item.credit,
          balance: runningBal,
          referenceType: item.referenceType,
          referenceId: item.referenceId,
        ));
      }

      state = AsyncValue.data(computedList.reversed.toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final ledgerProvider =
    StateNotifierProvider<LedgerNotifier, AsyncValue<List<CustomerLedger>>>(
        (ref) => LedgerNotifier());
