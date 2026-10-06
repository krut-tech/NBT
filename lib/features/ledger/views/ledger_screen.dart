import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../../customers/models/customer.dart';
import '../../customers/providers/customer_provider.dart';
import '../providers/ledger_provider.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  final String? initialCustomerId;

  const LedgerScreen({super.key, this.initialCustomerId});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(ledgerProvider.notifier).fetchCustomerLedger(widget.initialCustomerId!);
      });
    }
  }

  void _shareLedgerWhatsapp(Customer customer, double balance) async {
    final text = 'Hello ${customer.name},\nYour current outstanding ledger balance at New Bharat Tyre Remould is ${CurrencyFormatter.format(balance)}.\nThank you!';
    final phone = customer.primaryPhone.replaceAll(RegExp(r'\D'), '');
    final Uri url = Uri.parse('https://wa.me/91$phone?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerProvider);
    final ledgerAsync = ref.watch(ledgerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Financial Ledger'),
      ),
      body: Column(
        children: [
          // Customer Picker Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: customersAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (customers) {
                if (widget.initialCustomerId != null && _selectedCustomer == null) {
                  final match = customers.where((c) => c.id == widget.initialCustomerId).firstOrNull;
                  if (match != null) _selectedCustomer = match;
                }

                return SearchableDropdown<Customer>(
                  label: 'Select Customer for Ledger',
                  value: _selectedCustomer,
                  items: customers,
                  isRequired: true,
                  itemAsString: (c) => '${c.name} (${c.primaryPhone})',
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCustomer = val);
                      ref.read(ledgerProvider.notifier).fetchCustomerLedger(val.id);
                    }
                  },
                );
              },
            ),
          ),

          // Content
          Expanded(
            child: _selectedCustomer == null
                ? const EmptyStateWidget(
                    icon: Icons.menu_book_outlined,
                    title: 'Select a Customer',
                    description: 'Choose a customer above to view their statement of account.',
                  )
                : ledgerAsync.when(
                    loading: () => const LoadingIndicator(message: 'Computing ledger...'),
                    error: (err, _) => Center(child: Text('Error: $err')),
                    data: (ledgerEntries) {
                      if (ledgerEntries.isEmpty) {
                        return const EmptyStateWidget(
                          icon: Icons.receipt_long_outlined,
                          title: 'No Transactions',
                          description: 'This customer has no invoice or payment transactions yet.',
                        );
                      }

                      final currentBalance = ledgerEntries.first.balance;
                      double totalDebit = 0.0;
                      double totalCredit = 0.0;
                      for (final e in ledgerEntries) {
                        totalDebit += e.debit;
                        totalCredit += e.credit;
                      }

                      return Column(
                        children: [
                          // Summary Card
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Statement Balance',
                                          style: TextStyle(
                                              color: Colors.white70, fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          CurrencyFormatter.format(currentBalance),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(100, 38),
                                      ),
                                      onPressed: () => _shareLedgerWhatsapp(
                                          _selectedCustomer!, currentBalance),
                                      icon: const Icon(Icons.chat, size: 16),
                                      label: const Text('Share'),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white24, height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Debits: ${CurrencyFormatter.format(totalDebit)}',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                    Text(
                                      'Total Credits: ${CurrencyFormatter.format(totalCredit)}',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Ledger List
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: ledgerEntries.length,
                              itemBuilder: (context, index) {
                                final item = ledgerEntries[index];
                                final isDebit = item.debit > 0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: CircleAvatar(
                                      backgroundColor: isDebit
                                          ? AppColors.rejected.withValues(alpha: 0.12)
                                          : AppColors.ready.withValues(alpha: 0.12),
                                      child: Icon(
                                        isDebit
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        color: isDebit
                                            ? AppColors.rejected
                                            : AppColors.ready,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      item.description,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      DateFormatter.formatDate(item.transactionDate),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondaryLight),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          isDebit
                                              ? '+ ${CurrencyFormatter.format(item.debit)}'
                                              : '- ${CurrencyFormatter.format(item.credit)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDebit
                                                ? AppColors.rejected
                                                : AppColors.ready,
                                          ),
                                        ),
                                        Text(
                                          'Bal: ${CurrencyFormatter.format(item.balance)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondaryLight,
                                          ),
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
          ),
        ],
      ),
    );
  }
}
