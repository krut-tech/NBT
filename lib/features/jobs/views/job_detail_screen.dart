import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_chip.dart';
import '../models/job.dart';
import '../models/job_status_history.dart';
import '../providers/job_provider.dart';

class JobDetailScreen extends ConsumerWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  void _showStatusUpdateDialog(BuildContext context, WidgetRef ref, Job job) {
    String selectedStatus = job.status;
    final TextEditingController remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: Text('Update Job #${job.jobNumber} Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select New Status:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    items: AppConstants.tyreStatuses
                        .map((st) => DropdownMenuItem(
                              value: st,
                              child: Text(st),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedStatus = val);
                    },
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Remarks / Reason',
                      hintText: 'e.g. Curing complete, moved to QC',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  // Nothing to update while the current status is still selected.
                  onPressed: selectedStatus == job.status
                      ? null
                      : () async {
                          final newStatus = selectedStatus;
                          Navigator.pop(dialogContext);
                          try {
                            await ref.read(jobProvider.notifier).updateJobStatus(
                                  jobId: job.id,
                                  newStatus: newStatus,
                                  remarks: remarksController.text.trim(),
                                );
                            // Refresh this screen (job banner + history timeline).
                            ref.invalidate(jobByIdProvider(job.id));
                            ref.invalidate(jobHistoryProvider(job.id));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Job status updated to $newStatus successfully!'),
                                  backgroundColor: AppColors.ready,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update status: $e'),
                                  backgroundColor: AppColors.rejected,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Update Status'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `this.job` is the snapshot the screen was opened with; always show the live row
    // so the status banner / lifecycle bar update right after a status change.
    final job = ref.watch(jobByIdProvider(this.job.id)).valueOrNull ?? this.job;
    final historyAsync = ref.watch(jobHistoryProvider(job.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Job #${job.jobNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_attributes),
            onPressed: () => _showStatusUpdateDialog(context, ref, job),
            tooltip: 'Update Status',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner Card
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          job.jobNumber,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        StatusChip(status: job.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          job.customer?.name ?? 'Customer Name',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Visual Lifecycle Timeline
            const Text(
              'Tyre Remoulding Lifecycle Stage',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _LifecycleProgressBar(currentStatus: job.status),
            const SizedBox(height: 20),

            // Specifications Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Job Specifications',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),

                    _DetailRow('Quantity', '${job.quantity} Tyres'),
                    _DetailRow('Tyre Size', job.tyreSize),
                    _DetailRow('Brand', job.brand),
                    _DetailRow('Pattern', job.pattern ?? '-'),
                    _DetailRow('Tyre Type', job.tyreType ?? '-'),
                    _DetailRow(
                        'Received Date', DateFormatter.formatDate(job.receivedDate)),
                    _DetailRow(
                        'Expected Delivery',
                        job.expectedDeliveryDate != null
                            ? DateFormatter.formatDate(job.expectedDeliveryDate!)
                            : '-'),
                    _DetailRow('Vehicle Number', job.vehicleNumber ?? '-'),
                    _DetailRow('Notes', job.notes ?? '-'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // QR Code Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Job QR Tracking Code',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    QrImageView(
                      data: job.jobNumber,
                      version: QrVersions.auto,
                      size: 160.0,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan this QR code in factory to pull up Job #${job.jobNumber}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Photos Section
            if (job.photos.isNotEmpty) ...[
              const Text(
                'Inspection & Production Photos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: job.photos.length,
                  itemBuilder: (context, index) {
                    final url = job.photos[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(url),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ),
                    onPressed: () => _showStatusUpdateDialog(context, ref, job),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Update Status'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status Audit History Timeline
            const Text(
              'Status History & Audit Trail',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            historyAsync.when(
              loading: () => const LoadingIndicator(message: 'Loading history...'),
              error: (err, _) => Text('Error history: $err'),
              data: (historyList) {
                if (historyList.isEmpty) {
                  return const Text('No history recorded yet.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    final item = historyList[index];
                    return _HistoryItem(item: item);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LifecycleProgressBar extends StatelessWidget {
  final String currentStatus;

  const _LifecycleProgressBar({required this.currentStatus});

  static const List<String> stages = [
    'Received',
    'Inspection',
    'Approved',
    'Production',
    'Cold Chamber',
    'QC',
    'Ready',
    'Delivered'
  ];

  @override
  Widget build(BuildContext context) {
    int currentIndex = stages.indexOf(currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stages.asMap().entries.map((entry) {
          final idx = entry.key;
          final stage = entry.value;
          final isCompleted = idx <= currentIndex;
          final isCurrent = idx == currentIndex;

          return Row(
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: isCurrent ? 16 : 12,
                    backgroundColor: isCompleted
                        ? AppColors.getStatusColor(stage)
                        : Colors.grey.shade300,
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle,
                      size: isCurrent ? 18 : 12,
                      color: isCompleted ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stage,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted
                          ? AppColors.textPrimaryLight
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              if (idx < stages.length - 1)
                Container(
                  width: 28,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: idx < currentIndex
                      ? AppColors.secondary
                      : Colors.grey.shade300,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final JobStatusHistory item;

  const _HistoryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.getStatusColor(item.newStatus).withValues(alpha: 0.2),
          child: Icon(
            Icons.history,
            color: AppColors.getStatusColor(item.newStatus),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            if (item.previousStatus != null) ...[
              Text(
                item.previousStatus!,
                style: const TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const Icon(Icons.arrow_right_alt, size: 16),
            ],
            StatusChip(status: item.newStatus, fontSize: 11),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.remarks != null && item.remarks!.isNotEmpty)
              Text(
                item.remarks!,
                style: const TextStyle(fontSize: 13),
              ),
            Text(
              DateFormatter.formatDateTime(item.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }
}
