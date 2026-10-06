import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../../customers/models/customer.dart';
import '../../customers/providers/customer_provider.dart';
import '../../jobs/models/job.dart';
import '../../jobs/providers/job_provider.dart';
import '../providers/invoice_provider.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  final String? initialCustomerId;

  const InvoiceFormScreen({super.key, this.initialCustomerId});

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Customer? _selectedCustomer;
  Job? _selectedJob;

  final TextEditingController _tyreDetailsController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _rateController = TextEditingController(text: '2200'); // ₹2200 per tyre
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _taxPercentController = TextEditingController(text: '18'); // 18% GST default
  final TextEditingController _notesController = TextEditingController();

  final DateTime _invoiceDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rateController.addListener(_recalculate);
    _quantityController.addListener(_recalculate);
    _discountController.addListener(_recalculate);
    _taxPercentController.addListener(_recalculate);
  }

  void _recalculate() {
    setState(() {});
  }

  @override
  void dispose() {
    _tyreDetailsController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _discountController.dispose();
    _taxPercentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal {
    final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 0.0;
    return qty * rate;
  }

  double get _discount => double.tryParse(_discountController.text.trim()) ?? 0.0;

  double get _taxAmount {
    final afterDisc = _subtotal - _discount;
    final taxPct = double.tryParse(_taxPercentController.text.trim()) ?? 0.0;
    return (afterDisc * taxPct) / 100.0;
  }

  double get _grandTotal => (_subtotal - _discount) + _taxAmount;

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final invoice = await ref.read(invoiceProvider.notifier).createInvoice(
            customerId: _selectedCustomer!.id,
            jobId: _selectedJob?.id,
            tyreDetails: _tyreDetailsController.text.trim().isNotEmpty
                ? _tyreDetailsController.text.trim()
                : '${_selectedJob?.brand ?? ''} ${_selectedJob?.tyreSize ?? ''} Remoulding',
            quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
            rate: double.tryParse(_rateController.text.trim()) ?? 0.0,
            discount: _discount,
            taxPercent: double.tryParse(_taxPercentController.text.trim()) ?? 0.0,
            invoiceDate: _invoiceDate,
            notes: _notesController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice #${invoice.invoiceNumber} generated!'),
            backgroundColor: AppColors.ready,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
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
    final jobsAsync = ref.watch(jobProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Tax Invoice'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Customer
                customersAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (customers) {
                    if (widget.initialCustomerId != null && _selectedCustomer == null) {
                      final match = customers.where((c) => c.id == widget.initialCustomerId).firstOrNull;
                      if (match != null) _selectedCustomer = match;
                    }

                    return SearchableDropdown<Customer>(
                      label: 'Select Customer',
                      value: _selectedCustomer,
                      items: customers,
                      isRequired: true,
                      itemAsString: (c) => '${c.name} (${c.primaryPhone})',
                      onChanged: (val) {
                        setState(() {
                          _selectedCustomer = val;
                          _selectedJob = null;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Optional Job Link
                if (_selectedCustomer != null)
                  jobsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (jobs) {
                      final custJobs = jobs
                          .where((j) => j.customerId == _selectedCustomer!.id)
                          .toList();

                      return SearchableDropdown<Job>(
                        label: 'Link Tyre Job (Optional)',
                        value: _selectedJob,
                        items: custJobs,
                        itemAsString: (j) =>
                            'Job #${j.jobNumber} - ${j.brand} ${j.tyreSize} (${j.quantity} Tyres)',
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedJob = val;
                              _quantityController.text = val.quantity.toString();
                              _tyreDetailsController.text =
                                  '${val.brand} ${val.tyreSize} ${val.pattern ?? ''} Cold Remoulding';
                            });
                          }
                        },
                      );
                    },
                  ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Tyre Remould Description',
                  hint: 'e.g. 10.00-20 MRF Lug Cold Process Remoulding',
                  controller: _tyreDetailsController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Quantity',
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Rate per Tyre (₹)',
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        isRequired: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Discount (₹)',
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'GST Tax %',
                        controller: _taxPercentController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Calculation Card
                Card(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _calcRow('Subtotal:', CurrencyFormatter.format(_subtotal)),
                        _calcRow('Discount:', '- ${CurrencyFormatter.format(_discount)}'),
                        _calcRow('GST Amount:', '+ ${CurrencyFormatter.format(_taxAmount)}'),
                        const Divider(height: 16),
                        _calcRow(
                          'Grand Total:',
                          CurrencyFormatter.format(_grandTotal),
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Notes / Payment Terms',
                  hint: 'e.g. Payment due within 15 days',
                  controller: _notesController,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _saveInvoice,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Generate Invoice & Post to Ledger'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _calcRow(String title, String val, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontSize: isTotal ? 18 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.secondary : null,
            ),
          ),
        ],
      ),
    );
  }
}
