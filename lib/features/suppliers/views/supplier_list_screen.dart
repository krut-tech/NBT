import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/supplier_provider.dart';

class SupplierListScreen extends ConsumerWidget {
  const SupplierListScreen({super.key});

  void _showAddSupplierModal(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final productsController = TextEditingController();
    final addressController = TextEditingController();
    final gstController = TextEditingController();

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
                    const Text(
                      'Add Material Supplier',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  label: 'Supplier Name',
                  hint: 'e.g. Gujarat Rubber Pvt Ltd',
                  controller: nameController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.business_outlined),
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Mobile Number',
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Products Supplied',
                  hint: 'e.g. Tread Rubber, Cushion Gum, Cement',
                  controller: productsController,
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Address',
                  controller: addressController,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'GST Number',
                  controller: gstController,
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    Navigator.pop(sheetContext);
                    try {
                      await ref.read(supplierProvider.notifier).addSupplier(
                            name: nameController.text.trim(),
                            mobile: mobileController.text.trim(),
                            productsSupplied: productsController.text.trim(),
                            address: addressController.text.trim(),
                            gstNumber: gstController.text.trim(),
                          );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Supplier Added Successfully!'),
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
                  child: const Text('Save Supplier'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _callSupplier(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(supplierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers & Vendors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(supplierProvider.notifier).fetchSuppliers(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddSupplierModal(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Supplier'),
      ),
      body: suppliersAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading suppliers...'),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.local_shipping_outlined,
              title: 'No Suppliers Recorded',
              description: 'Add raw material vendors and suppliers here.',
              buttonText: 'Add Supplier',
              onButtonPressed: () => _showAddSupplierModal(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final sup = suppliers[index];
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
                            sup.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          if (sup.mobile != null && sup.mobile!.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.call, color: AppColors.ready),
                              onPressed: () => _callSupplier(sup.mobile!),
                            ),
                        ],
                      ),
                      if (sup.productsSupplied != null && sup.productsSupplied!.isNotEmpty)
                        Text(
                          'Products: ${sup.productsSupplied}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      if (sup.mobile != null) Text('Phone: ${sup.mobile}', style: const TextStyle(fontSize: 12)),
                      if (sup.gstNumber != null) Text('GST: ${sup.gstNumber}', style: const TextStyle(fontSize: 12)),
                      if (sup.address != null) Text('Address: ${sup.address}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
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
