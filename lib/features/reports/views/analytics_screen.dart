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
      appBar: AppBar(
        title: const Text('Analytics & Visual Charts'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Factory Output & Production',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Bar Chart Container
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 20,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                                    return Text(days[value.toInt()], style: const TextStyle(fontSize: 11));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            _makeBarGroup(0, 12, AppColors.received),
                            _makeBarGroup(1, 15, AppColors.production),
                            _makeBarGroup(2, 10, AppColors.coldChamber),
                            _makeBarGroup(3, 14, AppColors.qc),
                            _makeBarGroup(4, 18, AppColors.ready),
                            _makeBarGroup(5, 16, AppColors.delivered),
                            _makeBarGroup(6, 8, AppColors.secondary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Tyre Lifecycle Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Pie Chart Container
            metricsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => Text('Error: $err'),
              data: (m) {
                final received = (m['tyresReceivedToday'] as num).toDouble() + 5;
                final prod = (m['tyresProductionToday'] as num).toDouble() + 8;
                final chamber = (m['coldChamberCount'] as num).toDouble() + 4;
                final ready = (m['readyTyresCount'] as num).toDouble() + 6;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 180,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  color: AppColors.received,
                                  value: received,
                                  title: 'Rec',
                                  radius: 40,
                                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                PieChartSectionData(
                                  color: AppColors.production,
                                  value: prod,
                                  title: 'Prod',
                                  radius: 40,
                                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                PieChartSectionData(
                                  color: AppColors.coldChamber,
                                  value: chamber,
                                  title: 'Chamber',
                                  radius: 40,
                                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                PieChartSectionData(
                                  color: AppColors.ready,
                                  value: ready,
                                  title: 'Ready',
                                  radius: 40,
                                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: const [
                            _LegendItem('Received', AppColors.received),
                            _LegendItem('Production', AppColors.production),
                            _LegendItem('Cold Chamber', AppColors.coldChamber),
                            _LegendItem('Ready', AppColors.ready),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
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
