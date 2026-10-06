import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/pdf_generator.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../models/invoice.dart';
import '../providers/invoice_provider.dart';

class InvoiceListScreen extends ConsumerWidget {
  const InvoiceListScreen({super.key});

  void _printInvoice(Invoice invoice) async {
    final pdfBytes = await PdfGenerator.generateInvoicePdf(
      invoiceNumber: invoice.invoiceNumber,
      customerName: invoice.customer?.name ?? 'Customer',
      customerPhone: invoice.customer?.primaryPhone ?? '-',
      customerGst: invoice.customer?.gstNumber,
      customerAddress: invoice.customer?.address,
      tyreDetails: invoice.tyreDetails ?? 'Cold Tyre Remoulding',
      quantity: invoice.quantity,
      rate: invoice.rate,
      subtotal: invoice.subtotal,
      discount: invoice.discount,
      taxAmount: invoice.taxAmount,
      grandTotal: invoice.grandTotal,
      invoiceDate: invoice.invoiceDate,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(invoiceProvider.notifier).fetchInvoices(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/invoices/new'),
        icon: const Icon(Icons.add),
        label: const Text('Generate Invoice'),
      ),
      body: invoicesAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading invoices...'),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (invoices) {
          if (invoices.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'No Invoices Found',
              description: 'Generate invoices for customer tyre jobs.',
              buttonText: 'Create Invoice',
              onButtonPressed: () => context.push('/invoices/new'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final inv = invoices[index];
              final isPaid = inv.status == 'Paid';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            inv.invoiceNumber,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? AppColors.ready.withValues(alpha: 0.15)
                                  : AppColors.rejected.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              inv.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? AppColors.ready : AppColors.rejected,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Text(
                        inv.customer?.name ?? 'Customer Name',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        inv.tyreDetails ?? 'Tyre Remoulding',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grand Total: ${CurrencyFormatter.format(inv.grandTotal)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormatter.formatDate(inv.invoiceDate),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.picture_as_pdf_outlined,
                                    color: AppColors.primary),
                                onPressed: () => _printInvoice(inv),
                                tooltip: 'Print / Share PDF',
                              ),
                              if (!isPaid)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    minimumSize: const Size(80, 36),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                  ),
                                  onPressed: () => context.push(
                                    '/payments/new',
                                    extra: {
                                      'customerId': inv.customerId,
                                      'invoiceId': inv.id,
                                      'amount': inv.balanceAmount
                                    },
                                  ),
                                  child: const Text('Pay'),
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
          );
        },
      ),
    );
  }
}
