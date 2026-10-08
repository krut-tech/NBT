import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../../customers/models/customer.dart';
import '../../customers/providers/customer_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../invoices/models/invoice.dart';
import '../../invoices/providers/invoice_provider.dart';
import '../../master_data/providers/master_data_provider.dart';
import '../providers/payment_provider.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;

  const PaymentFormScreen({super.key, this.initialData});

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Customer? _selectedCustomer;
  Invoice? _selectedInvoice;
  String _selectedMethod = 'Cash';

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      if (widget.initialData!['amount'] != null) {
        _amountController.text = widget.initialData!['amount'].toString();
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid payment amount')),
      );
      return;
    }

    final invoice = _selectedInvoice;
    if (invoice != null && amount > invoice.balanceAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Amount is more than the invoice balance (${CurrencyFormatter.format(invoice.balanceAmount)})'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payment = await ref.read(paymentProvider.notifier).recordPayment(
            customerId: _selectedCustomer!.id,
            invoiceId: _selectedInvoice?.id,
            amount: amount,
            paymentDate: _paymentDate,
            paymentMethod: _selectedMethod,
            referenceNumber: _referenceController.text.trim(),
            notes: _notesController.text.trim(),
          );

      // The payment changed the invoice balance, the ledger and the dashboard numbers.
      ref.read(invoiceProvider.notifier).fetchInvoices();
      ref.invalidate(customerSummaryProvider);
      ref.invalidate(adminDashboardMetricsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Payment Receipt #${payment.receiptNumber} recorded successfully!'),
            backgroundColor: AppColors.ready,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${friendlyError(e)}'),
            backgroundColor: AppColors.rejected,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerProvider);
    final invoicesAsync = ref.watch(invoiceProvider);
    final paymentMethods = ref.watch(paymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Customer Payment'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Customer Selector
                customersAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (customers) {
                    final initialCustId = widget.initialData?['customerId'];
                    if (initialCustId != null && _selectedCustomer == null) {
                      final match = customers
                          .where((c) => c.id == initialCustId)
                          .firstOrNull;
                      if (match != null) _selectedCustomer = match;
                    }

                    return SearchableDropdown<Customer>(
                      label: 'Customer',
                      value: _selectedCustomer,
                      items: customers,
                      isRequired: true,
                      itemAsString: (c) => '${c.name} (${c.primaryPhone})',
                      onChanged: (val) {
                        setState(() {
                          _selectedCustomer = val;
                          _selectedInvoice = null;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Link Invoice
                if (_selectedCustomer != null)
                  invoicesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (invoices) {
                      final unpaidInvoices = invoices
                          .where((i) =>
                              i.customerId == _selectedCustomer!.id &&
                              i.status != 'Paid')
                          .toList();

                      return SearchableDropdown<Invoice>(
                        label: 'Link to Unpaid Invoice (Optional)',
                        value: _selectedInvoice,
                        items: unpaidInvoices,
                        itemAsString: (i) =>
                            'Invoice #${i.invoiceNumber} (Bal: ${CurrencyFormatter.format(i.balanceAmount)})',
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedInvoice = val;
                              _amountController.text =
                                  val.balanceAmount.toString();
                            });
                          }
                        },
                      );
                    },
                  ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Payment Amount (₹)',
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  isRequired: true,
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                const SizedBox(height: 12),

                SearchableDropdown<String>(
                  label: 'Payment Method',
                  value: _selectedMethod,
                  items: paymentMethods,
                  isRequired: true,
                  itemAsString: (m) => m,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMethod = val);
                  },
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Reference / UTR / Cheque No.',
                  hint: 'e.g. UPI Ref 1234567890',
                  controller: _referenceController,
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Notes / Remarks',
                  controller: _notesController,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _savePayment,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Record Payment & Credit Ledger'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
