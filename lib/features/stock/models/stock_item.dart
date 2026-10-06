class StockItem {
  final String id;
  final String itemName;
  final String category;
  final String unit;
  final double openingStock;
  final double minimumStock;
  final double currentStock;
  final double purchaseRate;
  final String? supplierId;
  final String? notes;
  final DateTime createdAt;

  StockItem({
    required this.id,
    required this.itemName,
    required this.category,
    required this.unit,
    this.openingStock = 0.0,
    this.minimumStock = 0.0,
    this.currentStock = 0.0,
    this.purchaseRate = 0.0,
    this.supplierId,
    this.notes,
    required this.createdAt,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id'] as String,
      itemName: json['item_name'] as String,
      category: json['category'] as String,
      unit: json['unit'] as String,
      openingStock: (json['opening_stock'] as num?)?.toDouble() ?? 0.0,
      minimumStock: (json['minimum_stock'] as num?)?.toDouble() ?? 0.0,
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
      purchaseRate: (json['purchase_rate'] as num?)?.toDouble() ?? 0.0,
      supplierId: json['supplier_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isLowStock => currentStock <= minimumStock;
}
