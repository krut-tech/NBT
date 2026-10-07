import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminDashboardMetricsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics & Visual Charts')),
      body: metricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Unable to load analytics: $err'),
        )),
        data: (m) => _AnalyticsBody(metrics: m),
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const _AnalyticsBody({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final received = (metrics['tyresReceivedToday'] as num?)?.toDouble() ?? 0;
    final produced = (metrics['tyresProductionToday'] as num?)?.toDouble() ?? 0;
    final chamber = (metrics['coldChamberCount'] as num?)?.toDouble() ?? 0;
    final qc = (metrics['qcPendingCount'] as num?)?.toDouble() ?? 0;
    final ready = (metrics['readyTyresCount'] as num?)?.toDouble() ?? 0;
    final delivered = (metrics['deliveredTodayCount'] as num?)?.toDouble() ?? 0;

    final values = [received, produced, chamber, qc, ready, delivered];
    final maxValue = values.fold<double>(1, (max, value) => value > max ? value : max);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today\'s Factory Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    maxY: maxValue + (maxValue * 0.2),
                    alignment: BarChartAlignment.spaceAround,
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const labels = ['Recv', 'Prod', 'Chm', 'QC', 'Ready', 'Del'];
                            final i = value.toInt();
                            return i >= 0 && i < labels.length
                                ? Text(labels[i], style: const TextStyle(fontSize: 10))
                                : const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 34),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      _bar(0, received, AppColors.received),
                      _bar(1, produced, AppColors.production),
                      _bar(2, chamber, AppColors.coldChamber),
                      _bar(3, qc, AppColors.qc),
                      _bar(4, ready, AppColors.ready),
                      _bar(5, delivered, AppColors.delivered),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Current Tyre Lifecycle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 210,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 42,
                        sections: _pieSections(received, produced, chamber, qc, ready),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: const [
                      _LegendItem('Received', AppColors.received),
                      _LegendItem('Production', AppColors.production),
                      _LegendItem('Cold Chamber', AppColors.coldChamber),
                      _LegendItem('QC', AppColors.qc),
                      _LegendItem('Ready', AppColors.ready),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 18,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  static List<PieChartSectionData> _pieSections(
    double received,
    double produced,
    double chamber,
    double qc,
    double ready,
  ) {
    final data = [
      ('Rec', received, AppColors.received),
      ('Prod', produced, AppColors.production),
      ('Chm', chamber, AppColors.coldChamber),
      ('QC', qc, AppColors.qc),
      ('Ready', ready, AppColors.ready),
    ];

    final total = data.fold<double>(0, (sum, item) => sum + item.$2);
    if (total <= 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: 'No data',
          radius: 42,
          color: AppColors.textSecondaryLight,
        ),
      ];
    }

    return data
        .where((item) => item.$2 > 0)
        .map(
          (item) => PieChartSectionData(
            value: item.$2,
            title: item.$1,
            radius: 42,
            color: item.$3,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        )
        .toList();
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
