import 'stock_item.dart';

class StockTransaction {
  final String id;
  final String itemId;
  final StockItem? stockItem;
  final String transactionType; // IN, OUT
  final double quantity;
  final double unitRate;
  final double totalAmount;
  final String? purchaseInvoice;
  final String? reason;
  final DateTime transactionDate;
  final DateTime createdAt;

  StockTransaction({
    required this.id,
    required this.itemId,
    this.stockItem,
    required this.transactionType,
    required this.quantity,
    this.unitRate = 0.0,
    this.totalAmount = 0.0,
    this.purchaseInvoice,
    this.reason,
    required this.transactionDate,
    required this.createdAt,
  });

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      stockItem: json['stock_items'] != null
          ? StockItem.fromJson(json['stock_items'] as Map<String, dynamic>)
          : null,
      transactionType: json['transaction_type'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitRate: (json['unit_rate'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      purchaseInvoice: json['purchase_invoice'] as String?,
      reason: json['reason'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
