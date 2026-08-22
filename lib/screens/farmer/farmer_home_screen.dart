import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/staggered_entrance.dart';
import '../../widgets/charts/interactive_area_chart.dart';
import '../../widgets/charts/interactive_bar_chart.dart';
import '../../widgets/charts/radial_gauge_card.dart';
import 'market_screen.dart';
import 'crop_doctor_screen.dart';
import 'farmer_logistics_screen.dart';

/// Farmer Hub Main Dashboard with Interactive Area Wave Charts & Cold Storage Gauges
class FarmerHomeScreen extends StatelessWidget {
  const FarmerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final user = appState.currentUser;

        const mandiTrendData = [
          AreaDataPoint(label: 'Mon', value: 34.0, subtext: 'Vol: 2.1k kg'),
          AreaDataPoint(label: 'Tue', value: 36.5, subtext: 'Vol: 3.4k kg'),
          AreaDataPoint(label: 'Wed', value: 35.0, subtext: 'Vol: 1.8k kg'),
          AreaDataPoint(label: 'Thu', value: 39.0, subtext: 'Vol: 4.8k kg'),
          AreaDataPoint(label: 'Fri', value: 42.5, subtext: 'Vol: 5.2k kg'),
          AreaDataPoint(label: 'Sat', value: 40.0, subtext: 'Vol: 3.1k kg'),
          AreaDataPoint(label: 'Today', value: 44.0, subtext: 'High Demand 🔥'),
        ];

        const districtComparisonBars = [
          BarDataGroup(category: 'Erode', value: 42.0, barColor: AppColors.accent),
          BarDataGroup(category: 'Sathy', value: 44.0, barColor: AppColors.primary),
          BarDataGroup(category: 'Gobi', value: 39.5, barColor: AppColors.secondary),
          BarDataGroup(category: 'Coimbatore', value: 46.0, barColor: Color(0xFFF97316)),
          BarDataGroup(category: 'Salem', value: 41.0, barColor: Color(0xFFEAB308)),
        ];

        return Scaffold(
          appBar: OneNationAppBar(
            title: user != null ? 'Farmer ${user.name.split(' ').first} 🌾' : 'Farmer Hub',
            showWeather: true,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await appState.fetchWeather();
              dataRepository.loadDistrictCropData(appState.detectedDistrict);
            },
            color: AppColors.accent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Cold Storage Occupancy Radial Gauge
                  StaggeredEntrance(
                    index: 0,
                    child: const RadialGaugeCard(
                      title: '❄️ Sathy Cold Storage Capacity',
                      value: 0.64,
                      displayValue: '320 / 500 MT',
                      subtitle: '180 MT Capacity Free',
                      primaryColor: AppColors.accent,
                      warningColor: AppColors.danger,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 2. Quick Farmer Action Shortcuts
                  StaggeredEntrance(
                    index: 1,
                    child: const _FarmerActionGrid(),
                  ),

                  const SizedBox(height: 24),

                  // 3. Touch-Scrubbable 7-Day APMC Mandi Price Curve
                  StaggeredEntrance(
                    index: 2,
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tomato (Nattu) 7-Day Price Trend',
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
                                  '+12% ↗',
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
                            data: mandiTrendData,
                            height: 160,
                            primaryColor: AppColors.accent,
                            unitPrefix: '₹',
                            unitSuffix: '/kg',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Multi-Mandi Price Comparison Bar Chart
                  StaggeredEntrance(
                    index: 3,
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tamil Nadu Mandi Price Comparison',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const InteractiveBarChart(
                            data: districtComparisonBars,
                            height: 140,
                            defaultColor: AppColors.accent,
                            unitPrefix: '₹',
                            unitSuffix: '/kg',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. Agro Advisory Rotating Banner
                  StaggeredEntrance(
                    index: 4,
                    child: const _AgroAdvisoryCard(),
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

class _AgroAdvisoryCard extends StatelessWidget {
  const _AgroAdvisoryCard();

  @override
  Widget build(BuildContext context) {
    final advisory = appState.currentAdvisory;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.accent.withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_sunny_rounded, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🌾 Agro Weather Advisory',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.rotate_right_rounded, size: 18, color: AppColors.textMuted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => appState.rotateAdvisory(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  advisory,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmerActionGrid extends StatelessWidget {
  const _FarmerActionGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FarmerTile(
            title: 'Mandi Rates',
            subtitle: '5 Mandis Live',
            icon: Icons.storefront_rounded,
            color: AppColors.accent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MarketScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FarmerTile(
            title: 'AI Crop Doctor',
            subtitle: 'Leaf Scanner',
            icon: Icons.healing_rounded,
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CropDoctorScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FarmerTile(
            title: 'Logistics',
            subtitle: 'Cold Storage',
            icon: Icons.local_shipping_rounded,
            color: AppColors.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FarmerLogisticsScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

class _FarmerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FarmerTile({
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
