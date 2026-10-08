import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../models/stock_item.dart';
import '../providers/stock_provider.dart';

class StockListScreen extends ConsumerStatefulWidget {
  const StockListScreen({super.key});

  @override
  ConsumerState<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends ConsumerState<StockListScreen> {
  void _showNewItemModal(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final openingController = TextEditingController(text: '0');
    final minController = TextEditingController(text: '10');
    final rateController = TextEditingController(text: '0');
    String selectedCategory = 'Tread Rubber';
    String selectedUnit = 'KG';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add New Raw Material / Stock Item',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    CustomTextField(
                      label: 'Item Name',
                      hint: 'e.g. Pre-cured Tread Rubber 10.00-20',
                      controller: nameController,
                      isRequired: true,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: SearchableDropdown<String>(
                            label: 'Category',
                            value: selectedCategory,
                            items: const [
                              'Tread Rubber',
                              'Bonding Material',
                              'Rubber Cement',
                              'Chemical',
                              'Consumables',
                              'Packing Material',
                              'Tools',
                              'Other'
                            ],
                            itemAsString: (c) => c,
                            onChanged: (val) {
                              if (val != null) selectedCategory = val;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SearchableDropdown<String>(
                            label: 'Unit',
                            value: selectedUnit,
                            items: const [
                              'KG',
                              'Litre',
                              'Piece',
                              'Meter',
                              'Box',
                              'Set'
                            ],
                            itemAsString: (u) => u,
                            onChanged: (val) {
                              if (val != null) selectedUnit = val;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Opening Stock',
                            controller: openingController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Min Stock Alert',
                            controller: minController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      label: 'Purchase Rate (₹)',
                      controller: rateController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;

                        Navigator.pop(sheetContext);
                        try {
                          await ref.read(stockProvider.notifier).addStockItem(
                                itemName: nameController.text.trim(),
                                category: selectedCategory,
                                unit: selectedUnit,
                                openingStock: double.tryParse(
                                        openingController.text.trim()) ??
                                    0.0,
                                minimumStock: double.tryParse(
                                        minController.text.trim()) ??
                                    0.0,
                                purchaseRate: double.tryParse(
                                        rateController.text.trim()) ??
                                    0.0,
                              );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Stock Item Added!'),
                                backgroundColor: AppColors.ready,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed: $e'),
                                backgroundColor: AppColors.rejected,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Add Stock Item'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTransactionModal(
      BuildContext context, WidgetRef ref, StockItem item, bool isStockIn) {
    final qtyController = TextEditingController(text: '1');
    final rateController =
        TextEditingController(text: item.purchaseRate.toString());
    final invoiceController = TextEditingController();
    final reasonController = TextEditingController(
        text: isStockIn ? 'Purchase' : 'Factory Production');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isStockIn
                          ? 'Stock IN (+ Entry)'
                          : 'Stock OUT (- Consumption)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isStockIn ? AppColors.ready : AppColors.rejected,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                Text('Item: ${item.itemName} (${item.unit})'),
                const Divider(),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Quantity (${item.unit})',
                  controller: qtyController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  isRequired: true,
                ),
                const SizedBox(height: 12),

                if (isStockIn) ...[
                  CustomTextField(
                    label: 'Unit Purchase Rate (₹)',
                    controller: rateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Supplier Bill / Invoice #',
                    controller: invoiceController,
                  ),
                  const SizedBox(height: 12),
                ],

                CustomTextField(
                  label: 'Reason / Purpose',
                  controller: reasonController,
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isStockIn ? AppColors.ready : AppColors.rejected,
                  ),
                  onPressed: () async {
                    final qty =
                        double.tryParse(qtyController.text.trim()) ?? 0.0;
                    if (qty <= 0) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                            content: Text('Enter a quantity greater than 0')),
                      );
                      return;
                    }
                    if (!isStockIn && qty > item.currentStock) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Only ${item.currentStock} ${item.unit} in stock')),
                      );
                      return;
                    }

                    Navigator.pop(sheetContext);
                    try {
                      await ref.read(stockProvider.notifier).recordTransaction(
                            itemId: item.id,
                            transactionType: isStockIn ? 'IN' : 'OUT',
                            quantity: qty,
                            unitRate: double.tryParse(
                                    rateController.text.trim()) ??
                                0.0,
                            purchaseInvoice: invoiceController.text.trim(),
                            reason: reasonController.text.trim(),
                            transactionDate: DateTime.now(),
                          );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Stock ${isStockIn ? "Added" : "Deducted"} Successfully!'),
                            backgroundColor:
                                isStockIn ? AppColors.ready : AppColors.rejected,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed: ${friendlyError(e)}'),
                            backgroundColor: AppColors.rejected,
                          ),
                        );
                      }
                    }
                  },
                  child: Text('Confirm Stock ${isStockIn ? "IN" : "OUT"}'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(stockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Raw Material Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/stock/transactions'),
            tooltip: 'Transaction Log',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(stockProvider.notifier).fetchStockItems(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        onPressed: () => _showNewItemModal(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Material'),
      ),
      body: stockAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading inventory...'),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) {
          if (items.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.inventory_2_outlined,
              title: 'No Raw Material Items',
              description: 'Add tread rubber, cement, and chemical stock.',
              buttonText: 'Add Material Item',
              onButtonPressed: () => _showNewItemModal(context, ref),
            );
          }

          final lowStockItems = items.where((i) => i.isLowStock).toList();

          return Column(
            children: [
              // Low stock alert banner
              if (lowStockItems.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: AppColors.rejected.withValues(alpha: 0.15),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: AppColors.rejected),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${lowStockItems.length} items below minimum stock threshold!',
                          style: const TextStyle(
                            color: AppColors.rejected,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isLow = item.isLowStock;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isLow
                              ? AppColors.rejected
                              : AppColors.borderLight,
                          width: isLow ? 1.5 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.itemName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Current Stock: ',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color:
                                                AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        Text(
                                          '${item.currentStock} ${item.unit}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isLow
                                                ? AppColors.rejected
                                                : AppColors.ready,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Min Stock: ${item.minimumStock} ${item.unit} • Rate: ${CurrencyFormatter.format(item.purchaseRate)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            AppColors.ready.withValues(alpha: 0.12),
                                      ),
                                      icon: const Icon(Icons.add,
                                          color: AppColors.ready),
                                      onPressed: () => _showTransactionModal(
                                          context, ref, item, true),
                                      tooltip: 'Stock IN',
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            AppColors.rejected.withValues(alpha: 0.12),
                                      ),
                                      icon: const Icon(Icons.remove,
                                          color: AppColors.rejected),
                                      onPressed: () => _showTransactionModal(
                                          context, ref, item, false),
                                      tooltip: 'Stock OUT',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
