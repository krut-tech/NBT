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
import '../../master_data/providers/master_data_provider.dart';
import '../providers/production_provider.dart';

class ProductionListScreen extends ConsumerWidget {
  const ProductionListScreen({super.key});

  void _showNewProductionModal(BuildContext context, WidgetRef ref) {
    Job? selectedJob;
    String? selectedMachine;
    String? selectedOperator;
    final quantityController = TextEditingController(text: '1');
    final notesController = TextEditingController();

    // NOTE: inside the sheet use `sheetRef` / `sheetContext`; the outer `ref` and
    // `context` (this screen) are used after the sheet is closed.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (_, sheetRef, __) {
            final jobsAsync =
                sheetRef.watch(jobsByStatusProvider('Approved,Production'));
            final machines = sheetRef.watch(machinesProvider);
            final operators = sheetRef.watch(operatorsProvider);

            return StatefulBuilder(
              builder: (_, setSheetState) {
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
                              'New Production Entry',
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

                        // Job selector
                        jobsAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Error loading jobs: $e'),
                          data: (eligibleJobs) {
                            return SearchableDropdown<Job>(
                              label: 'Select Approved Job',
                              value: selectedJob,
                              items: eligibleJobs,
                              isRequired: true,
                              itemAsString: (j) =>
                                  '#${j.jobNumber} - ${j.customer?.name ?? 'Unknown'} (${j.quantity} Tyres)',
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() {
                                    selectedJob = val;
                                    quantityController.text =
                                        val.quantity.toString();
                                  });
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        SearchableDropdown<String>(
                          label: 'Machine Used',
                          value: selectedMachine,
                          items: machines,
                          isRequired: true,
                          itemAsString: (m) => m,
                          onChanged: (val) =>
                              setSheetState(() => selectedMachine = val),
                        ),
                        const SizedBox(height: 12),

                        SearchableDropdown<String>(
                          label: 'Operator Name',
                          value: selectedOperator,
                          items: operators,
                          isRequired: true,
                          itemAsString: (op) => op,
                          onChanged: (val) =>
                              setSheetState(() => selectedOperator = val),
                        ),
                        const SizedBox(height: 12),

                        CustomTextField(
                          label: 'Quantity Built',
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),

                        CustomTextField(
                          label: 'Notes / Material Consumed',
                          hint: 'e.g. Tread rubber 18kg, Cement 2L',
                          controller: notesController,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.production,
                          ),
                          onPressed: () async {
                            final job = selectedJob;
                            final machine = selectedMachine;
                            final operator = selectedOperator;
                            if (job == null || machine == null || operator == null) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please fill all required fields')),
                              );
                              return;
                            }

                            final qty =
                                int.tryParse(quantityController.text.trim());
                            if (qty == null || qty < 1 || qty > job.quantity) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Quantity must be between 1 and ${job.quantity}')),
                              );
                              return;
                            }

                            Navigator.pop(sheetContext);
                            try {
                              await ref
                                  .read(productionProvider.notifier)
                                  .createProductionEntry(
                                    jobId: job.id,
                                    machine: machine,
                                    operatorName: operator,
                                    quantity: qty,
                                    notes: notesController.text.trim(),
                                  );
                              // The job moved to the next stage: refresh the job list.
                              await ref.read(jobProvider.notifier).fetchJobs();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Production completed & job moved to Cold Chamber!'),
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
                          child: const Text('Complete Production Entry'),
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
    final entriesAsync = ref.watch(productionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Production & Building'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(productionProvider.notifier).fetchEntries(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.production,
        foregroundColor: Colors.white,
        onPressed: () => _showNewProductionModal(context, ref),
        icon: const Icon(Icons.precision_manufacturing),
        label: const Text('New Production Entry'),
      ),
      body: entriesAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading production log...'),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.precision_manufacturing,
              title: 'No Production Log',
              description: 'Record building machine operations here.',
              buttonText: 'Add Production Entry',
              onButtonPressed: () => _showNewProductionModal(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
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
                            'Job #${entry.job?.jobNumber ?? 'N/A'}',
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
                              color: AppColors.production.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              entry.machine ?? 'Machine',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.production,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Customer: ${entry.job?.customer?.name ?? 'Customer'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Operator: ${entry.operatorName ?? 'Operator'} • Qty: ${entry.quantity}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Notes: ${entry.notes}',
                          style: const TextStyle(
                              fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                      const Divider(height: 16),
                      Text(
                        DateFormatter.formatDateTime(entry.createdAt),
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
          );
        },
      ),
    );
  }
}
