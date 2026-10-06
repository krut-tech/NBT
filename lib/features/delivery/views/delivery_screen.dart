import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../../jobs/models/job.dart';
import '../../jobs/providers/job_provider.dart';
import '../providers/delivery_provider.dart';

class DeliveryScreen extends ConsumerWidget {
  const DeliveryScreen({super.key});

  void _showNewDeliveryModal(BuildContext context, WidgetRef ref) {
    Job? selectedJob;
    final quantityController = TextEditingController(text: '1');
    final vehicleController = TextEditingController();
    final driverController = TextEditingController();
    final receivedByController = TextEditingController();
    final notesController = TextEditingController();
    DateTime deliveryDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final jobsAsync = ref.watch(jobProvider);

            return StatefulBuilder(
              builder: (context, setState) {
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
                              'Dispatch & Delivery Entry',
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

                        jobsAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Error loading jobs: $e'),
                          data: (jobs) {
                            final readyJobs =
                                jobs.where((j) => j.status == 'Ready').toList();

                            return SearchableDropdown<Job>(
                              label: 'Select Ready Job for Delivery',
                              value: selectedJob,
                              items: readyJobs,
                              isRequired: true,
                              itemAsString: (j) =>
                                  '#${j.jobNumber} - ${j.customer?.name} (${j.quantity} Tyres Ready)',
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    selectedJob = val;
                                    quantityController.text =
                                        val.quantity.toString();
                                    vehicleController.text =
                                        val.vehicleNumber ?? '';
                                  });
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        CustomTextField(
                          label: 'Quantity Delivered',
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),

                        CustomTextField(
                          label: 'Delivery Vehicle Number',
                          hint: 'e.g. GJ-01-XX-9999',
                          controller: vehicleController,
                          prefixIcon: const Icon(Icons.directions_bus_outlined),
                        ),
                        const SizedBox(height: 12),

                        CustomTextField(
                          label: 'Driver Name',
                          hint: 'e.g. Mukesh Bhai',
                          controller: driverController,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        const SizedBox(height: 12),

                        CustomTextField(
                          label: 'Received By (Customer Rep)',
                          hint: 'e.g. Suresh Patel (Gate Keeper)',
                          controller: receivedByController,
                          isRequired: true,
                          prefixIcon: const Icon(Icons.assignment_ind_outlined),
                        ),
                        const SizedBox(height: 12),

                        CustomTextField(
                          label: 'Delivery Notes',
                          controller: notesController,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.delivered,
                          ),
                          onPressed: () async {
                            if (selectedJob == null) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                    content: Text('Please select a ready job')),
                              );
                              return;
                            }

                            final delQty = int.tryParse(
                                    quantityController.text.trim()) ??
                                1;

                            Navigator.pop(sheetContext);
                            try {
                              await ref
                                  .read(deliveryProvider.notifier)
                                  .createDelivery(
                                    customerId: selectedJob!.customerId,
                                    jobId: selectedJob!.id,
                                    readyQuantity: selectedJob!.quantity,
                                    deliveredQuantity: delQty,
                                    deliveryDate: deliveryDate,
                                    vehicleNumber:
                                        vehicleController.text.trim(),
                                    driverName: driverController.text.trim(),
                                    receivedBy:
                                        receivedByController.text.trim(),
                                    notes: notesController.text.trim(),
                                  );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Delivery recorded & job dispatched!'),
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
                          child: const Text('Confirm Tyre Delivery'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveriesAsync = ref.watch(deliveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatches & Deliveries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(deliveryProvider.notifier).fetchDeliveries(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.delivered,
        foregroundColor: Colors.white,
        onPressed: () => _showNewDeliveryModal(context, ref),
        icon: const Icon(Icons.local_shipping),
        label: const Text('New Delivery'),
      ),
      body: deliveriesAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading deliveries...'),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (deliveries) {
          if (deliveries.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.local_shipping_outlined,
              title: 'No Deliveries Recorded',
              description: 'Record tyre dispatches & delivery challans here.',
              buttonText: 'Add Delivery',
              onButtonPressed: () => _showNewDeliveryModal(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final del = deliveries[index];
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
                            del.deliveryNumber,
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
                              color: AppColors.delivered.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${del.deliveredQuantity} Delivered',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.delivered,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Customer: ${del.customer?.name ?? 'Customer'}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Job #${del.job?.jobNumber ?? 'N/A'} • Received By: ${del.receivedBy ?? '-'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      if (del.vehicleNumber != null && del.vehicleNumber!.isNotEmpty)
                        Text(
                          'Vehicle: ${del.vehicleNumber} • Driver: ${del.driverName ?? '-'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormatter.formatDate(del.deliveryDate),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            'Remaining: ${del.remainingQuantity}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
