import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/supabase_service.dart';
import '../models/stock_item.dart';
import '../models/stock_transaction.dart';

class StockNotifier extends StateNotifier<AsyncValue<List<StockItem>>> {
  StockNotifier() : super(const AsyncValue.loading()) {
    fetchStockItems();
  }

  Future<void> fetchStockItems() async {
    try {
      final response = await SupabaseService.client
          .from('stock_items')
          .select()
          .order('item_name', ascending: true);

      final items =
          (response as List).map((json) => StockItem.fromJson(json)).toList();

      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addStockItem({
    required String itemName,
    required String category,
    required String unit,
    double openingStock = 0.0,
    double minimumStock = 0.0,
    double purchaseRate = 0.0,
    String? notes,
  }) async {
    try {
      final client = SupabaseService.client;

      await client.from('stock_items').insert({
        'item_name': itemName.trim(),
        'category': category,
        'unit': unit,
        'opening_stock': openingStock,
        'minimum_stock': minimumStock,
        'current_stock': openingStock,
        'purchase_rate': purchaseRate,
        'notes': notes,
      });

      await fetchStockItems();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> recordTransaction({
    required String itemId,
    required String transactionType, // 'IN' or 'OUT'
    required double quantity,
    double unitRate = 0.0,
    String? purchaseInvoice,
    String? reason,
    required DateTime transactionDate,
  }) async {
    try {
      final client = SupabaseService.client;

      final totalAmount = quantity * unitRate;

      // 1. Insert Stock Transaction (Database trigger auto-updates current_stock on stock_items)
      await client.from('stock_transactions').insert({
        'item_id': itemId,
        'transaction_type': transactionType,
        'quantity': quantity,
        'unit_rate': unitRate,
        'total_amount': totalAmount,
        'purchase_invoice': purchaseInvoice,
        'reason': reason,
        'transaction_date': transactionDate.toIso8601String().split('T').first,
        'created_by': SupabaseService.currentUserId,
      });

      // 2. Audit log
      await AuditService.logAction(
        action: 'STOCK_$transactionType',
        entityType: 'STOCK',
        entityId: itemId,
        details: {'quantity': quantity, 'reason': reason},
      );

      await fetchStockItems();
    } catch (e) {
      rethrow;
    }
  }
}

final stockProvider =
    StateNotifierProvider<StockNotifier, AsyncValue<List<StockItem>>>(
        (ref) => StockNotifier());

// Low stock items count
final lowStockCountProvider = Provider<int>((ref) {
  return ref.watch(stockProvider).maybeWhen(
        data: (items) => items.where((i) => i.isLowStock).length,
        orElse: () => 0,
      );
});

// Stock transactions list provider
final stockTransactionsProvider =
    FutureProvider<List<StockTransaction>>((ref) async {
  final response = await SupabaseService.client
      .from('stock_transactions')
      .select('*, stock_items(*)')
      .order('created_at', ascending: false);

  return (response as List)
      .map((json) => StockTransaction.fromJson(json))
      .toList();
});
