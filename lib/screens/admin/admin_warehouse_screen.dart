import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/mock_data.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass_card.dart';

/// Admin Cold Storage & APMC Warehouse Oversight
class AdminWarehouseScreen extends StatelessWidget {
  const AdminWarehouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OneNationAppBar(
        title: 'Cold Storage Capacity ❄️',
        showWeather: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...MockData.warehouseData.map((wh) {
              final int capacity = wh['capacity'] as int;
              final int used = wh['used'] as int;
              final double percent = (used / capacity).clamp(0.0, 1.0);
              final crops = (wh['crops'] as List).cast<String>();

              return GlassCard(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: percent > 0.8
                                ? AppColors.danger.withValues(alpha: 0.2)
                                : AppColors.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(percent * 100).toInt()}% Used',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: percent > 0.8 ? AppColors.danger : AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      wh['location'] as String,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current Stock: $used MT', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('Max Limit: $capacity MT', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percent > 0.8 ? AppColors.danger : AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 6,
                      children: crops.map((crop) {
                        return Chip(
                          label: Text(crop, style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
