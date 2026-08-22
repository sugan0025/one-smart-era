import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/staggered_entrance.dart';
import '../../widgets/charts/interactive_area_chart.dart';
import '../../widgets/charts/interactive_heatmap_matrix.dart';

/// City Analytics, Grievance Resolution Metrics & Interactive Heatmap Matrix
class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final reports = dataRepository.reports;

        final wards = ['Ward 1', 'Ward 2', 'Ward 3', 'Ward 4', 'Ward 5'];
        final categories = ['Roads', 'Water', 'Waste', 'Light', 'Health'];

        // Heatmap density mapping
        final Map<String, int> density = {
          'Ward 1_Roads': 2,
          'Ward 1_Water': 1,
          'Ward 1_Waste': 0,
          'Ward 1_Light': 1,
          'Ward 1_Health': 0,
          'Ward 2_Roads': 1,
          'Ward 2_Water': 0,
          'Ward 2_Waste': 2,
          'Ward 2_Light': 0,
          'Ward 2_Health': 1,
          'Ward 3_Roads': 3,
          'Ward 3_Water': 2,
          'Ward 3_Waste': 1,
          'Ward 3_Light': 2,
          'Ward 3_Health': 0,
          'Ward 4_Roads': 0,
          'Ward 4_Water': 1,
          'Ward 4_Waste': 1,
          'Ward 4_Light': 0,
          'Ward 4_Health': 1,
          'Ward 5_Roads': 0,
          'Ward 5_Water': 0,
          'Ward 5_Waste': 0,
          'Ward 5_Light': 0,
          'Ward 5_Health': 0,
        };

        const velocityTrend = [
          AreaDataPoint(label: 'Mon', value: 8.0, subtext: '8 Resolved'),
          AreaDataPoint(label: 'Tue', value: 12.0, subtext: '12 Resolved'),
          AreaDataPoint(label: 'Wed', value: 10.5, subtext: '10 Resolved'),
          AreaDataPoint(label: 'Thu', value: 15.0, subtext: '15 Resolved'),
          AreaDataPoint(label: 'Fri', value: 18.0, subtext: '18 Resolved'),
          AreaDataPoint(label: 'Sat', value: 14.0, subtext: '14 Resolved'),
          AreaDataPoint(label: 'Sun', value: 20.0, subtext: '20 Resolved 🔥'),
        ];

        return Scaffold(
          appBar: const OneNationAppBar(
            title: 'City Analytics & Heatmap 📊',
            showWeather: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Resolution Speed Summary
                StaggeredEntrance(
                  index: 0,
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Service Level Agreement (SLA) Health',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            _MetricItem(label: 'Avg Resolution', val: '2.4 Days', color: AppColors.success),
                            _MetricItem(label: 'On-Time Fixes', val: '89%', color: AppColors.secondary),
                            _MetricItem(label: 'SLA Breached', val: '1 Issue', color: AppColors.danger),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Incident Velocity Area Wave Chart
                StaggeredEntrance(
                  index: 1,
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Weekly Resolution Velocity',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '+24% Velocity',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const InteractiveAreaChart(
                          data: velocityTrend,
                          height: 150,
                          primaryColor: AppColors.secondary,
                          unitPrefix: '',
                          unitSuffix: ' fixes',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 3. Interactive Ward Grievance Heatmap Matrix
                StaggeredEntrance(
                  index: 2,
                  child: InteractiveHeatmapMatrix(
                    wards: wards,
                    categories: categories,
                    densityData: density,
                    onCellSelected: (key) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.secondary,
                          duration: const Duration(seconds: 1),
                          content: Text('Inspecting incidents in $key'),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String val;
  final Color color;

  const _MetricItem({required this.label, required this.val, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
