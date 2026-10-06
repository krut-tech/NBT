class CustomerLedger {
  final String id;
  final String customerId;
  final DateTime transactionDate;
  final String description;
  final double debit;
  final double credit;
  final double balance;
  final String? referenceType;
  final String? referenceId;

  CustomerLedger({
    required this.id,
    required this.customerId,
    required this.transactionDate,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
    this.referenceType,
    this.referenceId,
  });

  factory CustomerLedger.fromJson(Map<String, dynamic> json) {
    return CustomerLedger(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      description: json['description'] as String,
      debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
    );
  }
}
