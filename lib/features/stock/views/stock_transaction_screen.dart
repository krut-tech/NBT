import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/stock_provider.dart';

class StockTransactionScreen extends ConsumerWidget {
  const StockTransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(stockTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Movement Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(stockTransactionsProvider),
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading movements...'),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history_outlined,
              title: 'No Movements Recorded',
              description: 'Stock IN and Stock OUT logs will appear here.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final txn = transactions[index];
              final isIn = txn.transactionType == 'IN';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: isIn
                        ? AppColors.ready.withValues(alpha: 0.12)
                        : AppColors.rejected.withValues(alpha: 0.12),
                    child: Icon(
                      isIn ? Icons.add_shopping_cart : Icons.precision_manufacturing,
                      color: isIn ? AppColors.ready : AppColors.rejected,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    txn.stockItem?.itemName ?? 'Material Item',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reason: ${txn.reason ?? '-'}'),
                      if (txn.purchaseInvoice != null && txn.purchaseInvoice!.isNotEmpty)
                        Text('Invoice: ${txn.purchaseInvoice}'),
                      Text(DateFormatter.formatDate(txn.transactionDate),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isIn ? "+" : "-"} ${txn.quantity} ${txn.stockItem?.unit ?? ''}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isIn ? AppColors.ready : AppColors.rejected,
                        ),
                      ),
                      if (txn.totalAmount > 0)
                        Text(
                          CurrencyFormatter.format(txn.totalAmount),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
