import '../../customers/models/customer.dart';
import '../../jobs/models/job.dart';

class Invoice {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final Customer? customer;
  final String? jobId;
  final Job? job;
  final String? tyreDetails;
  final int quantity;
  final double rate;
  final double subtotal;
  final double discount;
  final double taxPercent;
  final double taxAmount;
  final double grandTotal;
  final double paidAmount;
  final double balanceAmount;
  final String status; // Unpaid, Partially Paid, Paid
  final DateTime invoiceDate;
  final String? notes;
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    this.customer,
    this.jobId,
    this.job,
    this.tyreDetails,
    required this.quantity,
    required this.rate,
    required this.subtotal,
    this.discount = 0.0,
    this.taxPercent = 0.0,
    this.taxAmount = 0.0,
    required this.grandTotal,
    this.paidAmount = 0.0,
    required this.balanceAmount,
    this.status = 'Unpaid',
    required this.invoiceDate,
    this.notes,
    required this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      customerId: json['customer_id'] as String,
      customer: json['customers'] != null
          ? Customer.fromJson(json['customers'] as Map<String, dynamic>)
          : null,
      jobId: json['job_id'] as String?,
      job: json['jobs'] != null
          ? Job.fromJson(json['jobs'] as Map<String, dynamic>)
          : null,
      tyreDetails: json['tyre_details'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (json['tax_percent'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (json['balance_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Unpaid',
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
