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
import '../providers/cold_chamber_provider.dart';

class ColdChamberScreen extends ConsumerWidget {
  const ColdChamberScreen({super.key});

  void _showNewChamberModal(BuildContext context, WidgetRef ref) {
    Job? selectedJob;
    String? selectedChamber;
    String? selectedOperator;
    final quantityController = TextEditingController(text: '1');
    final tempController = TextEditingController(text: '115'); // 115°C default
    final notesController = TextEditingController();

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
            final chambers = ref.watch(coldChambersProvider);
            final operators = ref.watch(operatorsProvider);

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
                          'Cold Chamber Process Entry',
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
                      data: (jobs) {
                        final eligibleJobs = jobs.where((j) =>
                            j.status == 'Cold Chamber' ||
                            j.status == 'Production').toList();

                        return SearchableDropdown<Job>(
                          label: 'Select Job in Chamber Queue',
                          value: selectedJob,
                          items: eligibleJobs,
                          isRequired: true,
                          itemAsString: (j) =>
                              '#${j.jobNumber} - ${j.customer?.name} (${j.quantity} Tyres)',
                          onChanged: (val) {
                            if (val != null) {
                              selectedJob = val;
                              quantityController.text = val.quantity.toString();
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    SearchableDropdown<String>(
                      label: 'Cold Chamber Unit',
                      value: selectedChamber,
                      items: chambers,
                      isRequired: true,
                      itemAsString: (c) => c,
                      onChanged: (val) => selectedChamber = val,
                    ),
                    const SizedBox(height: 12),

                    SearchableDropdown<String>(
                      label: 'Operator Name',
                      value: selectedOperator,
                      items: operators,
                      isRequired: true,
                      itemAsString: (op) => op,
                      onChanged: (val) => selectedOperator = val,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Curing Temp (°C)',
                            controller: tempController,
                            keyboardType: TextInputType.number,
                            isRequired: true,
                            prefixIcon: const Icon(Icons.thermostat),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Quantity Cured',
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      label: 'Notes / Curing Remarks',
                      hint: 'Curing pressure, time duration notes',
                      controller: notesController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coldChamber,
                      ),
                      onPressed: () async {
                        if (selectedJob == null ||
                            selectedChamber == null ||
                            selectedOperator == null) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                                content: Text('Please fill all required fields')),
                          );
                          return;
                        }

                        Navigator.pop(sheetContext);
                        try {
                          await ref
                              .read(coldChamberProvider.notifier)
                              .createChamberEntry(
                                jobId: selectedJob!.id,
                                chamberName: selectedChamber!,
                                operatorName: selectedOperator!,
                                quantity: int.tryParse(
                                        quantityController.text.trim()) ??
                                    1,
                                temperature: double.tryParse(
                                        tempController.text.trim()) ??
                                    115.0,
                                notes: notesController.text.trim(),
                              );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Cold curing completed & job moved to QC!'),
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
                      child: const Text('Complete Curing Process'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(coldChamberProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cold Chamber Process'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(coldChamberProvider.notifier).fetchEntries(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.coldChamber,
        foregroundColor: Colors.white,
        onPressed: () => _showNewChamberModal(context, ref),
        icon: const Icon(Icons.ac_unit),
        label: const Text('Cold Chamber Entry'),
      ),
      body: entriesAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading curing log...'),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.ac_unit,
              title: 'No Cold Chamber Log',
              description: 'Record cold process curing batches here.',
              buttonText: 'Add Curing Entry',
              onButtonPressed: () => _showNewChamberModal(context, ref),
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
                              color: AppColors.coldChamber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              entry.chamberName ?? 'Chamber',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.coldChamber,
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
                        'Operator: ${entry.operatorName ?? 'Operator'} • Temp: ${entry.temperature ?? 115}°C • Qty: ${entry.quantity}',
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
