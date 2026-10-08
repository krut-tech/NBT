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
import '../providers/qc_provider.dart';

class QcScreen extends ConsumerWidget {
  const QcScreen({super.key});

  void _showNewQcModal(BuildContext context, WidgetRef ref) {
    Job? selectedJob;
    bool visualCheck = true;
    bool treadCheck = true;
    bool sidewallCheck = true;
    bool airTest = true;
    bool finalInspection = true;
    String finalResult = 'PASS'; // PASS, FAIL, HOLD
    String? selectedDefect;
    final remarksController = TextEditingController();
    final staffNameController = TextEditingController(text: 'QC Inspector');

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
            // 'Hold' jobs can be re-inspected once the issue is sorted out.
            final jobsAsync =
                sheetRef.watch(jobsByStatusProvider('QC,Cold Chamber,Hold'));
            final masterItemsAsync = sheetRef.watch(masterDataProvider);

            List<String> defectTypes = ['Porosity / Blister', 'Tread Separation', 'Sidewall Bulge', 'Bad Curing', 'Casing Damage'];
            masterItemsAsync.whenData((items) {
              final list = items
                  .where((i) => i.category == 'qc_defect_type' && i.name != 'None')
                  .map((i) => i.name)
                  .toList();
              if (list.isNotEmpty) defectTypes = list;
            });

            return StatefulBuilder(
              builder: (_, setState) {
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
                              'QC Quality Inspection',
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
                              label: 'Select Job for Quality Inspection',
                              value: selectedJob,
                              items: eligibleJobs,
                              isRequired: true,
                              itemAsString: (j) =>
                                  '#${j.jobNumber} - ${j.customer?.name ?? 'Unknown'} (${j.quantity} Tyres)',
                              onChanged: (val) => setState(() => selectedJob = val),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        const Text('Quality Checkpoints:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        CheckboxListTile(
                          dense: true,
                          title: const Text('1. Visual Inspection'),
                          subtitle: const Text('No surface defects or blisters'),
                          value: visualCheck,
                          activeColor: AppColors.ready,
                          onChanged: (v) => setState(() => visualCheck = v ?? true),
                        ),
                        CheckboxListTile(
                          dense: true,
                          title: const Text('2. Tread Alignment & Bonding'),
                          subtitle: const Text('Tread properly centered & bonded'),
                          value: treadCheck,
                          activeColor: AppColors.ready,
                          onChanged: (v) => setState(() => treadCheck = v ?? true),
                        ),
                        CheckboxListTile(
                          dense: true,
                          title: const Text('3. Sidewall Condition'),
                          subtitle: const Text('No sidewall separation or cracks'),
                          value: sidewallCheck,
                          activeColor: AppColors.ready,
                          onChanged: (v) => setState(() => sidewallCheck = v ?? true),
                        ),
                        CheckboxListTile(
                          dense: true,
                          title: const Text('4. High Pressure Air Leak Test'),
                          subtitle: const Text('Passed air pressure test'),
                          value: airTest,
                          activeColor: AppColors.ready,
                          onChanged: (v) => setState(() => airTest = v ?? true),
                        ),
                        const SizedBox(height: 16),

                        const Text('Final QC Decision:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('PASS'),
                                selected: finalResult == 'PASS',
                                selectedColor: AppColors.ready,
                                labelStyle: TextStyle(
                                  color: finalResult == 'PASS'
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (_) =>
                                    setState(() => finalResult = 'PASS'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('HOLD'),
                                selected: finalResult == 'HOLD',
                                selectedColor: AppColors.production,
                                labelStyle: TextStyle(
                                  color: finalResult == 'HOLD'
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (_) =>
                                    setState(() => finalResult = 'HOLD'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('FAIL'),
                                selected: finalResult == 'FAIL',
                                selectedColor: AppColors.rejected,
                                labelStyle: TextStyle(
                                  color: finalResult == 'FAIL'
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (_) =>
                                    setState(() => finalResult = 'FAIL'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (finalResult != 'PASS') ...[
                          SearchableDropdown<String>(
                            label: 'Defect Type',
                            value: selectedDefect,
                            items: defectTypes,
                            isRequired: true,
                            itemAsString: (d) => d,
                            onChanged: (val) => setState(() => selectedDefect = val),
                          ),
                          const SizedBox(height: 12),
                        ],

                        CustomTextField(
                          label: 'Inspector Name',
                          controller: staffNameController,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),

                        CustomTextField(
                          label: 'QC Remarks / Comments',
                          hint: 'Enter inspection notes or defect details...',
                          controller: remarksController,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: finalResult == 'PASS'
                                ? AppColors.ready
                                : (finalResult == 'HOLD'
                                    ? AppColors.production
                                    : AppColors.rejected),
                          ),
                          onPressed: () async {
                            final job = selectedJob;
                            if (job == null) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                    content: Text('Please select a job')),
                              );
                              return;
                            }

                            // A tyre cannot PASS with a failed checkpoint.
                            if (finalResult == 'PASS' &&
                                !(visualCheck &&
                                    treadCheck &&
                                    sidewallCheck &&
                                    airTest)) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'All 4 checkpoints must be ticked to PASS. Choose HOLD or FAIL instead.')),
                              );
                              return;
                            }

                            // FAIL / HOLD need a reason.
                            if (finalResult != 'PASS' && selectedDefect == null) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Select a defect type for a FAIL / HOLD result')),
                              );
                              return;
                            }

                            final staffName = staffNameController.text.trim();
                            if (staffName.isEmpty) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                    content: Text('Enter the inspector name')),
                              );
                              return;
                            }

                            final result = finalResult;
                            Navigator.pop(sheetContext);
                            try {
                              await ref
                                  .read(qcProvider.notifier)
                                  .createQcInspection(
                                    jobId: job.id,
                                    visualCheck: visualCheck,
                                    treadCheck: treadCheck,
                                    sidewallCheck: sidewallCheck,
                                    airTest: airTest,
                                    finalInspection: finalInspection,
                                    finalResult: result,
                                    defectType:
                                        result == 'PASS' ? null : selectedDefect,
                                    remarks: remarksController.text.trim(),
                                    qcStaffName: staffName,
                                  );
                              // The job moved to the next stage: refresh the job list.
                              await ref.read(jobProvider.notifier).fetchJobs();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'QC Inspection recorded: $result'),
                                    backgroundColor: result == 'PASS'
                                        ? AppColors.ready
                                        : AppColors.rejected,
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
                          child: Text('Submit QC Result ($finalResult)'),
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
    final inspectionsAsync = ref.watch(qcProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Control (QC)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(qcProvider.notifier).fetchInspections(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.qc,
        foregroundColor: Colors.white,
        onPressed: () => _showNewQcModal(context, ref),
        icon: const Icon(Icons.verified),
        label: const Text('New QC Inspection'),
      ),
      body: inspectionsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading QC records...'),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (inspections) {
          if (inspections.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.verified_outlined,
              title: 'No QC Inspections',
              description: 'Record quality check results here.',
              buttonText: 'Add QC Inspection',
              onButtonPressed: () => _showNewQcModal(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: inspections.length,
            itemBuilder: (context, index) {
              final qc = inspections[index];
              final isPass = qc.finalResult == 'PASS';

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
                            'Job #${qc.job?.jobNumber ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPass
                                  ? AppColors.ready.withValues(alpha: 0.15)
                                  : AppColors.rejected.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              qc.finalResult,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isPass ? AppColors.ready : AppColors.rejected,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Customer: ${qc.job?.customer?.name ?? 'Customer'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Inspector: ${qc.qcStaffName ?? 'QC Staff'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      if (qc.defectType != null && qc.defectType != 'None')
                        Text(
                          'Defect: ${qc.defectType}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.rejected,
                          ),
                        ),
                      if (qc.remarks != null && qc.remarks!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Remarks: ${qc.remarks}',
                          style: const TextStyle(
                              fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                      const Divider(height: 16),
                      Text(
                        DateFormatter.formatDateTime(qc.createdAt),
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
