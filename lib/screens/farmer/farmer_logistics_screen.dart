import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/mock_data.dart';
import '../../models/logistics_model.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/staggered_entrance.dart';

/// Cold Storage Capacity Monitoring & Farm-to-Mandi Pickup Booking
class FarmerLogisticsScreen extends StatefulWidget {
  const FarmerLogisticsScreen({super.key});

  @override
  State<FarmerLogisticsScreen> createState() => _FarmerLogisticsScreenState();
}

class _FarmerLogisticsScreenState extends State<FarmerLogisticsScreen> {
  final _cropController = TextEditingController(text: 'Tomato');
  final _weightController = TextEditingController(text: '500');
  final _addressController = TextEditingController();

  String _selectedWarehouse = 'wh1';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = appState.currentUser?.address ?? 'Sathyamangalam, Erode';
  }

  @override
  void dispose() {
    _cropController.dispose();
    _weightController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final crop = _cropController.text.trim();
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final address = _addressController.text.trim();
    final user = appState.currentUser;

    if (crop.isEmpty || weight <= 0 || address.isEmpty || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: const Text('Please fill all logistics pickup details correctly.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final warehouse = MockData.warehouseData.firstWhere(
      (w) => w['id'] == _selectedWarehouse,
      orElse: () => MockData.warehouseData.first,
    );

    final req = LogisticsRequest(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      farmerId: user.uid,
      farmerName: user.name,
      farmerPhone: user.phone,
      crop: crop,
      weightKg: weight,
      pickupAddress: address,
      pickupLoc: appState.userLocation,
      warehouseId: warehouse['id'] as String,
      warehouseName: warehouse['name'] as String,
      status: 'Requested',
    );

    await dataRepository.submitLogisticsRequest(req);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: const Text('Pickup request confirmed! Municipal logistics officer notified.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final t = appState.t;
        final logistics = dataRepository.logistics;

        return Scaffold(
          appBar: AppBar(
            title: Text(t('logistics')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Cold Storage Occupancy Meter
                const Text(
                  'Cold Storage Occupancy Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                ...MockData.warehouseData.map((wh) {
                  final int capacity = wh['capacity'] as int;
                  final int used = wh['used'] as int;
                  final double percent = (used / capacity).clamp(0.0, 1.0);
                  final isSelected = _selectedWarehouse == wh['id'];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedWarehouse = wh['id'] as String),
                    child: GlassCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      customBorder: isSelected
                          ? Border.all(color: AppColors.secondary, width: 1.5)
                          : null,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  wh['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '$used / $capacity MT (${(percent * 100).toInt()}%)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            wh['location'] as String,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 6,
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percent > 0.8 ? AppColors.danger : AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // 2. Cooperative Freight Pooling Banner
                GlassCard(
                  customBgColor: const Color(0xFF0F766E).withValues(alpha: 0.25),
                  customBorder: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.groups_rounded, color: AppColors.primaryLight, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('cooperative_pool'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              t('pool_savings'),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.8),
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Book Pickup Form Card
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Book Farm-to-Mandi Pickup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _cropController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: t('crop_type'),
                          prefixIcon: const Icon(Icons.eco_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: t('quantity_kg'),
                          prefixIcon: const Icon(Icons.scale_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _addressController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Farm Pickup Location',
                          prefixIcon: Icon(Icons.location_on_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),

                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(t('book_logistics')),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Logistics Requests Timeline Tracker
                const Text(
                  'My Active Logistics Requests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                if (logistics.isEmpty)
                  EmptyStateWidget(
                    icon: Icons.local_shipping_outlined,
                    title: 'No Transport Requests',
                    subtitle: 'Booked pickups to APMC mandis will show real-time progress here.',
                  )
                else
                  ...logistics.map((req) {
                    return StaggeredEntrance(
                      child: GlassCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${req.weightKg.toInt()} kg ${req.crop}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    req.status,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Facility: ${req.warehouseName ?? "Sathyamangalam Cold Storage"}',
                              style: const TextStyle(fontSize: 12, color: AppColors.primaryLight),
                            ),
                            Text(
                              'Pickup: ${req.pickupAddress}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            if (req.scheduledTime != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Scheduled: ${req.scheduledTime}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}
