import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../../customers/models/customer.dart';
import '../../customers/providers/customer_provider.dart';
import '../../master_data/providers/master_data_provider.dart';
import '../providers/job_provider.dart';

class JobFormScreen extends ConsumerStatefulWidget {
  final Customer? preselectedCustomer;

  const JobFormScreen({super.key, this.preselectedCustomer});

  @override
  ConsumerState<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends ConsumerState<JobFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Customer? _selectedCustomer;
  String? _selectedTyreSize;
  String? _selectedBrand;
  String? _selectedPattern;
  String? _selectedTyreType = 'Radial';

  int _quantity = 1;
  DateTime _receivedDate = DateTime.now();
  DateTime? _expectedDeliveryDate = DateTime.now().add(const Duration(days: 3));

  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final StorageService _storageService = StorageService();
  final List<File> _selectedPhotos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preselectedCustomer;
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool fromCamera) async {
    final file = fromCamera
        ? await _storageService.pickImageFromCamera()
        : await _storageService.pickImageFromGallery();

    if (file != null) {
      setState(() {
        _selectedPhotos.add(file);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isReceivedDate) async {
    final initialDate = isReceivedDate
        ? _receivedDate
        : (_expectedDeliveryDate ?? DateTime.now().add(const Duration(days: 3)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isReceivedDate) {
          _receivedDate = picked;
        } else {
          _expectedDeliveryDate = picked;
        }
      });
    }
  }

  Future<void> _saveJob() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    if (_selectedTyreSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select tyre size')),
      );
      return;
    }

    if (_selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select brand')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final job = await ref.read(jobProvider.notifier).createJob(
            customerId: _selectedCustomer!.id,
            tyreSize: _selectedTyreSize!,
            brand: _selectedBrand!,
            pattern: _selectedPattern,
            tyreType: _selectedTyreType,
            quantity: _quantity,
            receivedDate: _receivedDate,
            expectedDeliveryDate: _expectedDeliveryDate,
            vehicleNumber: _vehicleController.text.trim(),
            notes: _notesController.text.trim(),
            imageFiles: _selectedPhotos,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job #${job.jobNumber} created successfully!'),
            backgroundColor: AppColors.ready,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create job: $e'),
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
    final tyreSizes = ref.watch(tyreSizesProvider);
    final tyreBrands = ref.watch(tyreBrandsProvider);
    final tyrePatterns = ref.watch(tyrePatternsProvider);
    final tyreTypes = ref.watch(tyreTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Tyres / New Job'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section 1: Customer
                const Text(
                  '1. Customer Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                customersAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading customers: $e'),
                  data: (customers) => SearchableDropdown<Customer>(
                    label: 'Customer',
                    value: _selectedCustomer,
                    items: customers,
                    isRequired: true,
                    itemAsString: (c) => '${c.name} (${c.primaryPhone})',
                    onChanged: (val) => setState(() => _selectedCustomer = val),
                  ),
                ),
                const SizedBox(height: 20),

                // Section 2: Tyre Specifications
                const Text(
                  '2. Tyre Specifications',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                SearchableDropdown<String>(
                  label: 'Tyre Size',
                  value: _selectedTyreSize,
                  items: tyreSizes,
                  isRequired: true,
                  itemAsString: (item) => item,
                  onChanged: (val) => setState(() => _selectedTyreSize = val),
                ),
                const SizedBox(height: 12),

                SearchableDropdown<String>(
                  label: 'Brand',
                  value: _selectedBrand,
                  items: tyreBrands,
                  isRequired: true,
                  itemAsString: (item) => item,
                  onChanged: (val) => setState(() => _selectedBrand = val),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: SearchableDropdown<String>(
                        label: 'Pattern',
                        value: _selectedPattern,
                        items: tyrePatterns,
                        itemAsString: (item) => item,
                        onChanged: (val) => setState(() => _selectedPattern = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SearchableDropdown<String>(
                        label: 'Type',
                        value: _selectedTyreType,
                        items: tyreTypes,
                        itemAsString: (item) => item,
                        onChanged: (val) => setState(() => _selectedTyreType = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quantity counter
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tyre Quantity',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Number of tyres in this job batch',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Section 3: Dates & Transport
                const Text(
                  '3. Dates & Transport Info',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Received Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(DateFormatter.formatDate(_receivedDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Expected Delivery',
                            prefixIcon: Icon(Icons.event_available),
                          ),
                          child: Text(
                            _expectedDeliveryDate != null
                                ? DateFormatter.formatDate(_expectedDeliveryDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Vehicle Number',
                  hint: 'e.g. GJ-01-AB-1234',
                  controller: _vehicleController,
                  prefixIcon: const Icon(Icons.directions_bus_outlined),
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Notes / Remarks',
                  hint: 'Mention casing condition, damages if any...',
                  controller: _notesController,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // Section 4: Photos
                const Text(
                  '4. Tyre Inspection Photos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(true),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(false),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_selectedPhotos.isNotEmpty)
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedPhotos.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_selectedPhotos[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 10,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _selectedPhotos.removeAt(index);
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _saveJob,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Job / Receive Tyres'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
