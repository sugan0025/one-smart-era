import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/civic_report_model.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/staggered_entrance.dart';
import '../../widgets/sos_button.dart';
import '../../widgets/charts/interactive_donut_chart.dart';
import '../../widgets/charts/interactive_bar_chart.dart';
import '../../widgets/charts/radial_gauge_card.dart';
import 'report_screen.dart';
import 'civic_map_screen.dart';
import 'schemes_screen.dart';

/// Public Citizen Main Dashboard with Visual Charts & Gamified Civic Points
class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final t = appState.t;
        final user = appState.currentUser;
        final reports = dataRepository.reports;

        // Calculate dynamic category counts
        final roadsCount = reports.where((r) => r.category == 'Roads').length.toDouble();
        final waterCount = reports.where((r) => r.category == 'Water').length.toDouble();
        final sanitationCount = reports.where((r) => r.category == 'Sanitation').length.toDouble();
        final lightCount = reports.where((r) => r.category == 'Street Lights').length.toDouble();
        final healthCount = reports.where((r) => r.category == 'Health').length.toDouble();

        final donutSegments = [
          DonutSegment(label: 'Roads', value: roadsCount > 0 ? roadsCount : 4, color: AppColors.primary),
          DonutSegment(label: 'Water', value: waterCount > 0 ? waterCount : 2, color: AppColors.secondary),
          DonutSegment(label: 'Sanitation', value: sanitationCount > 0 ? sanitationCount : 3, color: AppColors.accent),
          DonutSegment(label: 'Lights', value: lightCount > 0 ? lightCount : 1, color: const Color(0xFFFACC15)),
          DonutSegment(label: 'Health', value: healthCount > 0 ? healthCount : 2, color: AppColors.danger),
        ];

        final civicActivityBars = [
          const BarDataGroup(category: 'Mon', value: 12, barColor: AppColors.primary),
          const BarDataGroup(category: 'Tue', value: 18, barColor: AppColors.primary),
          const BarDataGroup(category: 'Wed', value: 8, barColor: AppColors.primary),
          const BarDataGroup(category: 'Thu', value: 24, barColor: AppColors.accent),
          const BarDataGroup(category: 'Fri', value: 15, barColor: AppColors.primary),
        ];

        final points = user?.civicPoints ?? 180;
        final nextTarget = 300;
        final progress = (points / nextTarget).clamp(0.0, 1.0);

        return Scaffold(
          appBar: OneNationAppBar(
            title: user != null ? 'Hello, ${user.name.split(' ').first} 👋' : t('app_name'),
            showWeather: true,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await appState.fetchWeather();
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero Civic Points Radial Gauge Card
                  StaggeredEntrance(
                    index: 0,
                    child: RadialGaugeCard(
                      title: '🏆 Civic Champion Level',
                      value: progress,
                      displayValue: '$points Pts',
                      subtitle: '${(nextTarget - points)} pts to Platinum',
                      primaryColor: AppColors.primary,
                      warningColor: AppColors.accent,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 2. Quick Action Grid
                  StaggeredEntrance(
                    index: 1,
                    child: const _QuickActionGrid(),
                  ),

                  const SizedBox(height: 24),

                  // 3. Emergency SOS Widget Banner
                  StaggeredEntrance(
                    index: 2,
                    child: const _EmergencySOSBanner(),
                  ),

                  const SizedBox(height: 24),

                  // 4. Ward Issues Category Donut Breakdown
                  StaggeredEntrance(
                    index: 3,
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Ward 1 Grievance Distribution',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Tap Slice',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InteractiveDonutChart(
                            segments: donutSegments,
                            size: 190,
                            strokeWidth: 24,
                            centerTitle: 'Active Issues',
                            centerSubtitle: 'Ward 1',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. Weekly Civic Resolution Activity Bar Chart
                  StaggeredEntrance(
                    index: 4,
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weekly Civic Activity & Upvotes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          InteractiveBarChart(
                            data: civicActivityBars,
                            height: 140,
                            defaultColor: AppColors.primary,
                            unitPrefix: '',
                            unitSuffix: ' actions',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 6. Live Community Grievances
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Community Issues',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CivicMapScreen()),
                        ),
                        child: const Text(
                          'View on Map →',
                          style: TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (reports.isEmpty)
                    EmptyStateWidget(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'No Active Civic Issues',
                      subtitle: 'Your neighborhood is clean and all reports are resolved!',
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reports.take(3).length,
                      itemBuilder: (context, idx) {
                        final rep = reports[idx];
                        return StaggeredEntrance(
                          index: idx + 5,
                          child: _ReportCard(report: rep),
                        );
                      },
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            title: 'Report Issue',
            subtitle: 'Camera + GPS',
            icon: Icons.add_a_photo_rounded,
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            title: 'Civic Map',
            subtitle: 'Live Heatmap',
            icon: Icons.map_rounded,
            color: AppColors.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CivicMapScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            title: 'Welfare Schemes',
            subtitle: 'Check Eligibility',
            icon: Icons.account_balance_rounded,
            color: AppColors.accent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SchemesScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencySOSBanner extends StatelessWidget {
  const _EmergencySOSBanner();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.danger.withValues(alpha: 0.4),
      child: Row(
        children: [
          const SOSButton(size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Emergency Civic Alert',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Press & hold for 3 seconds to trigger immediate municipal SOS alert.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final CivicReport report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.report_problem_rounded, color: AppColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CategoryBadge(category: report.category),
                    StatusBadgeChip(
                      status: report.status,
                      isSlaBreached: report.isSlaBreached,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  report.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        (report.address?.isNotEmpty == true) ? report.address! : (report.wardName ?? 'Ward 1'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.thumb_up_alt_rounded, size: 12, color: report.upvotes > 0 ? AppColors.primaryLight : AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(
                      '${report.upvotes}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
