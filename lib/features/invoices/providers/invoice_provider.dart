import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/supabase_service.dart';
import '../models/invoice.dart';

class InvoiceNotifier extends StateNotifier<AsyncValue<List<Invoice>>> {
  InvoiceNotifier() : super(const AsyncValue.loading()) {
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    try {
      final response = await SupabaseService.client
          .from('invoices')
          .select('*, customers(*), jobs(*)')
          .order('created_at', ascending: false);

      final invoices =
          (response as List).map((json) => Invoice.fromJson(json)).toList();

      state = AsyncValue.data(invoices);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Invoice> createInvoice({
    required String customerId,
    String? jobId,
    required String tyreDetails,
    required int quantity,
    required double rate,
    double discount = 0.0,
    double taxPercent = 0.0,
    required DateTime invoiceDate,
    String? notes,
  }) async {
    try {
      final client = SupabaseService.client;

      // 1. Generate Invoice Number
      final genRes = await client.rpc('generate_invoice_number');
      final invoiceNumber = genRes as String? ??
          'INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final subtotal = quantity * rate;
      final afterDiscount = subtotal - discount;
      final taxAmount = (afterDiscount * taxPercent) / 100.0;
      final grandTotal = afterDiscount + taxAmount;

      // 2. Insert Invoice
      final response = await client
          .from('invoices')
          .insert({
            'invoice_number': invoiceNumber,
            'customer_id': customerId,
            'job_id': jobId,
            'tyre_details': tyreDetails,
            'quantity': quantity,
            'rate': rate,
            'subtotal': subtotal,
            'discount': discount,
            'tax_percent': taxPercent,
            'tax_amount': taxAmount,
            'grand_total': grandTotal,
            'paid_amount': 0.0,
            'balance_amount': grandTotal,
            'status': 'Unpaid',
            'invoice_date': invoiceDate.toIso8601String().split('T').first,
            'notes': notes,
            'created_by': SupabaseService.currentUserId,
          })
          .select('*, customers(*), jobs(*)')
          .single();

      final invoice = Invoice.fromJson(response);

      // 3. Post DEBIT transaction to Customer Ledger
      await client.from('customer_ledgers').insert({
        'customer_id': customerId,
        'transaction_date': invoiceDate.toIso8601String().split('T').first,
        'description': 'Tax Invoice #$invoiceNumber - $tyreDetails ($quantity Tyres)',
        'debit': grandTotal,
        'credit': 0.0,
        'balance': grandTotal, // Note: running balance is computed
        'reference_type': 'INVOICE',
        'reference_id': invoice.id,
      });

      // 4. Audit Log
      await AuditService.logAction(
        action: 'CREATE_INVOICE',
        entityType: 'INVOICE',
        entityId: invoice.id,
        details: {
          'invoice_number': invoiceNumber,
          'grand_total': grandTotal,
          'customer_id': customerId
        },
      );

      await fetchInvoices();
      return invoice;
    } catch (e) {
      rethrow;
    }
  }
}

final invoiceProvider =
    StateNotifierProvider<InvoiceNotifier, AsyncValue<List<Invoice>>>(
        (ref) => InvoiceNotifier());
