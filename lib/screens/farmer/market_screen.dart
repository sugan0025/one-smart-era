import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/mock_data.dart';
import '../../models/crop_model.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/sparkline_chart.dart';
import '../../widgets/staggered_entrance.dart';

/// Live APMC Mandi Market Prices, 7-Day Trends, and Direct Crop Marketplace
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDistrict = 'Erode';

  final List<String> _districts = ['Erode', 'Sathyamangalam', 'Gobichettipalayam', 'Coimbatore', 'Salem'];

  @override
  void initState() {
    super.initState();
    _selectedDistrict = appState.detectedDistrict;
    if (!_districts.contains(_selectedDistrict)) _selectedDistrict = 'Erode';
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddListingDialog() {
    final cropCtrl = TextEditingController(text: 'Tomato');
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.bgDarkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Sell My Harvest', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cropCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Crop Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Price per kg (₹)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Total Quantity (kg)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
                final user = appState.currentUser;

                if (price > 0 && qty > 0 && user != null) {
                  dataRepository.addCropListing(
                    CropListing(
                      id: 'cl_${DateTime.now().millisecondsSinceEpoch}',
                      farmerId: user.uid,
                      farmerName: user.name,
                      farmerPhone: user.phone,
                      crop: cropCtrl.text.trim(),
                      pricePerKg: price,
                      quantityKg: qty,
                      location: user.address,
                    ),
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.success,
                      content: const Text('Harvest listing published to APMC buyers!'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Publish Listing'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final t = appState.t;
        final isTa = appState.isTamil;
        final crops = dataRepository.crops;
        final listings = dataRepository.cropListings;

        return Scaffold(
          appBar: AppBar(
            title: Text(t('mandi')),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'APMC Live Rates'),
                Tab(text: 'Farmer Marketplace'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Live APMC Mandi Rates
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // District Selector Chips
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _districts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final district = _districts[idx];
                          final isSelected = _selectedDistrict == district;

                          return ChoiceChip(
                            label: Text(district),
                            selected: isSelected,
                            selectedColor: AppColors.accent,
                            onSelected: (val) {
                              if (val) {
                                setState(() => _selectedDistrict = district);
                                dataRepository.loadDistrictCropData(district);
                              }
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Crop Cards
                    ...crops.map((c) {
                      final name = isTa
                          ? (MockData.cropOptionsTamil[c.name] ?? c.name)
                          : c.name;
                      final isAlertOn = appState.priceAlerts[c.name] ?? false;

                      return StaggeredEntrance(
                        child: GlassCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: c.demand == 'High'
                                              ? AppColors.success.withValues(alpha: 0.2)
                                              : AppColors.accent.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${c.demand} Demand',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: c.demand == 'High' ? AppColors.success : AppColors.accent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: Icon(
                                          isAlertOn ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                                          color: isAlertOn ? AppColors.accent : AppColors.textSecondary,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          appState.togglePriceAlert(c.name);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: AppColors.accent,
                                              content: Text(
                                                isAlertOn ? 'Price alert disabled for $name' : 'Price alert enabled for $name',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₹${c.currentPrice.toStringAsFixed(1)} / kg',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            c.isBullish ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                            size: 13,
                                            color: c.isBullish ? AppColors.success : AppColors.danger,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Predicted: ₹${c.predictedPrice.toStringAsFixed(1)} (${c.priceDiffPercent >= 0 ? "+" : ""}${c.priceDiffPercent.toStringAsFixed(1)}%)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: c.isBullish ? AppColors.success : AppColors.danger,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SparklineChart(
                                    data: c.history,
                                    width: 100,
                                    height: 46,
                                    isBullish: c.isBullish,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // Tab 2: Direct Farmer Marketplace
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showAddListingDialog,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Post My Harvest for Direct Sale'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (listings.isEmpty)
                      EmptyStateWidget(
                        icon: Icons.storefront_rounded,
                        title: 'No Direct Listings Yet',
                        subtitle: 'Be the first farmer to post harvest produce for APMC buyers!',
                      )
                    else
                      ...listings.map((item) {
                        return StaggeredEntrance(
                          child: GlassCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.eco_rounded, color: AppColors.accent, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.quantityKg.toInt()}kg ${item.crop}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Farmer: ${item.farmerName} • ${item.location}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${item.pricePerKg.toInt()}/kg',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
