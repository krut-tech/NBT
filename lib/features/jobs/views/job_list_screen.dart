import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_chip.dart';
import '../models/job.dart';
import '../providers/job_provider.dart';

class JobListScreen extends ConsumerStatefulWidget {
  const JobListScreen({super.key});

  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';

  final List<String> _statusFilters = ['All', ...AppConstants.tyreStatuses];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tyre Jobs & Batches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/qr-scanner'),
            tooltip: 'Scan Job QR',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(jobProvider.notifier).fetchJobs(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/jobs/new'),
        icon: const Icon(Icons.add),
        label: const Text('Receive Tyres'),
      ),
      body: Column(
        children: [
          // Search Box
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).cardColor,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Job #, Customer, Size, Vehicle...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(jobProvider.notifier)
                              .fetchJobs(search: '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                ref.read(jobProvider.notifier).fetchJobs(search: val);
              },
            ),
          ),

          // Horizontal Status Filter Bar
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _statusFilters.length,
              itemBuilder: (context, index) {
                final status = _statusFilters[index];
                final isSelected = status == _selectedStatus;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(status),
                    selectedColor: AppColors.secondary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedStatus = status);
                      ref
                          .read(jobProvider.notifier)
                          .fetchJobs(status: status);
                    },
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: jobsState.when(
              loading: () => const LoadingIndicator(message: 'Loading jobs...'),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.tire_repair,
                    title: 'No Jobs Found',
                    description: 'No tyre jobs match your search or filter.',
                    buttonText: 'Receive New Tyres',
                    onButtonPressed: () => context.push('/jobs/new'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return _JobCard(
                      job: job,
                      onTap: () =>
                          context.push('/jobs/${job.id}', extra: job),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const _JobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    job.jobNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  StatusChip(status: job.status),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job.customer?.name ?? 'Unknown Customer',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${job.quantity} Tyres',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${job.brand} • ${job.tyreSize}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (job.pattern != null && job.pattern!.isNotEmpty) ...[
                    Text(' • ${job.pattern}',
                        style: const TextStyle(fontSize: 13)),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Received: ${DateFormatter.formatDate(job.receivedDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  if (job.vehicleNumber != null &&
                      job.vehicleNumber!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.directions_bus, size: 14, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          job.vehicleNumber!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
