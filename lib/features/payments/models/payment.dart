import '../../customers/models/customer.dart';
import '../../invoices/models/invoice.dart';

class Payment {
  final String id;
  final String receiptNumber;
  final String customerId;
  final Customer? customer;
  final String? invoiceId;
  final Invoice? invoice;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? referenceNumber;
  final String? receiptImageUrl;
  final String? notes;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.receiptNumber,
    required this.customerId,
    this.customer,
    this.invoiceId,
    this.invoice,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.referenceNumber,
    this.receiptImageUrl,
    this.notes,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      receiptNumber: json['receipt_number'] as String,
      customerId: json['customer_id'] as String,
      customer: json['customers'] != null
          ? Customer.fromJson(json['customers'] as Map<String, dynamic>)
          : null,
      invoiceId: json['invoice_id'] as String?,
      invoice: json['invoices'] != null
          ? Invoice.fromJson(json['invoices'] as Map<String, dynamic>)
          : null,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      paymentMethod: json['payment_method'] as String? ?? 'Cash',
      referenceNumber: json['reference_number'] as String?,
      receiptImageUrl: json['receipt_image_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
