import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/supabase_service.dart';
import '../models/payment.dart';

class PaymentNotifier extends StateNotifier<AsyncValue<List<Payment>>> {
  PaymentNotifier() : super(const AsyncValue.loading()) {
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    try {
      final response = await SupabaseService.client
          .from('payments')
          .select('*, customers(*), invoices(*)')
          .order('created_at', ascending: false);

      final payments =
          (response as List).map((json) => Payment.fromJson(json)).toList();

      state = AsyncValue.data(payments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Payment> recordPayment({
    required String customerId,
    String? invoiceId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? referenceNumber,
    String? notes,
  }) async {
    try {
      final client = SupabaseService.client;

      // 1. Generate Payment Receipt Number
      final genRes = await client.rpc('generate_payment_number');
      final receiptNumber = genRes as String? ??
          'PAY-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // 2. Insert Payment Record
      final response = await client
          .from('payments')
          .insert({
            'receipt_number': receiptNumber,
            'customer_id': customerId,
            'invoice_id': invoiceId,
            'amount': amount,
            'payment_date': paymentDate.toIso8601String().split('T').first,
            'payment_method': paymentMethod,
            'reference_number': referenceNumber,
            'notes': notes,
            'created_by': SupabaseService.currentUserId,
          })
          .select('*, customers(*), invoices(*)')
          .single();

      final payment = Payment.fromJson(response);

      // 3. Post CREDIT transaction to Customer Ledger
      await client.from('customer_ledgers').insert({
        'customer_id': customerId,
        'transaction_date': paymentDate.toIso8601String().split('T').first,
        'description':
            'Payment Receipt #$receiptNumber via $paymentMethod ${referenceNumber != null ? '(Ref: $referenceNumber)' : ''}',
        'debit': 0.0,
        'credit': amount,
        'balance': 0.0,
        'reference_type': 'PAYMENT',
        'reference_id': payment.id,
      });

      // 4. Update linked Invoice if present
      if (invoiceId != null) {
        final invRes = await client
            .from('invoices')
            .select('grand_total, paid_amount')
            .eq('id', invoiceId)
            .maybeSingle();

        if (invRes != null) {
          final total = (invRes['grand_total'] as num?)?.toDouble() ?? 0.0;
          final currentPaid = (invRes['paid_amount'] as num?)?.toDouble() ?? 0.0;
          final newPaid = currentPaid + amount;
          final newBalance = total - newPaid;
          final newStatus = newBalance <= 0
              ? 'Paid'
              : (newPaid > 0 ? 'Partially Paid' : 'Unpaid');

          await client.from('invoices').update({
            'paid_amount': newPaid,
            'balance_amount': newBalance > 0 ? newBalance : 0.0,
            'status': newStatus,
          }).eq('id', invoiceId);
        }
      }

      // 5. Audit Log
      await AuditService.logAction(
        action: 'RECORD_PAYMENT',
        entityType: 'PAYMENT',
        entityId: payment.id,
        details: {
          'receipt_number': receiptNumber,
          'amount': amount,
          'customer_id': customerId
        },
      );

      await fetchPayments();
      return payment;
    } catch (e) {
      rethrow;
    }
  }
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, AsyncValue<List<Payment>>>(
        (ref) => PaymentNotifier());
