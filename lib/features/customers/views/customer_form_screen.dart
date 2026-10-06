import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final Customer? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _gstController;
  late TextEditingController _openingBalanceController;
  late TextEditingController _notesController;

  String _customerType = 'Fleet Owner';
  bool _gstApplicable = false;
  bool _isLoading = false;

  final List<String> _customerTypes = [
    'Fleet Owner',
    'Transport Company',
    'Retail Dealer',
    'Individual',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.primaryPhone ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _cityController = TextEditingController(text: c?.city ?? '');
    _gstController = TextEditingController(text: c?.gstNumber ?? '');
    _openingBalanceController =
        TextEditingController(text: c?.openingBalance.toString() ?? '0');
    _notesController = TextEditingController(text: c?.notes ?? '');

    if (c != null) {
      _customerType = c.customerType;
      _gstApplicable = c.gstApplicable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _gstController.dispose();
    _openingBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final customerData = Customer(
        id: widget.customer?.id ?? '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        mobileNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        customerType: _customerType,
        gstApplicable: _gstApplicable,
        gstNumber: _gstApplicable ? _gstController.text.trim() : null,
        openingBalance:
            double.tryParse(_openingBalanceController.text.trim()) ?? 0.0,
        notes: _notesController.text.trim(),
      );

      if (widget.customer == null) {
        await ref.read(customerProvider.notifier).addCustomer(customerData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer added successfully!'),
              backgroundColor: AppColors.ready,
            ),
          );
        }
      } else {
        await ref
            .read(customerProvider.notifier)
            .updateCustomer(widget.customer!.id, customerData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer updated successfully!'),
              backgroundColor: AppColors.ready,
            ),
          );
        }
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save customer: $e'),
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
    final isEdit = widget.customer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Customer' : 'New Customer Entry'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: 'Customer Name',
                  hint: 'e.g. Raj Transport Co.',
                  controller: _nameController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.business_outlined),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Mobile Number',
                  hint: 'e.g. 9825012345',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: 16),

                SearchableDropdown<String>(
                  label: 'Customer Type',
                  value: _customerType,
                  items: _customerTypes,
                  itemAsString: (item) => item,
                  onChanged: (val) {
                    if (val != null) setState(() => _customerType = val);
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'City / Location',
                  hint: 'e.g. Ahmedabad',
                  controller: _cityController,
                  prefixIcon: const Icon(Icons.location_city_outlined),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Full Address',
                  hint: 'Enter workshop / yard address',
                  controller: _addressController,
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.map_outlined),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('GST Registered Customer'),
                  subtitle: const Text('Enable to record GST Number'),
                  value: _gstApplicable,
                  activeThumbColor: AppColors.secondary,
                  onChanged: (val) => setState(() => _gstApplicable = val),
                ),

                if (_gstApplicable) ...[
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: 'GSTIN Number',
                    hint: 'e.g. 24AAAAA0000A1Z5',
                    controller: _gstController,
                    prefixIcon: const Icon(Icons.receipt_long_outlined),
                  ),
                ],
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Opening Balance (₹)',
                  hint: '0.00 (Positive = Debit/Owes Us)',
                  controller: _openingBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Notes / Remarks',
                  hint: 'Special instructions or vehicle details',
                  controller: _notesController,
                  maxLines: 2,
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? 'Update Customer' : 'Save Customer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
