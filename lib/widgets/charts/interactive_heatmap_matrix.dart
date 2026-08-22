import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../glass_card.dart';

class HeatmapCell {
  final String wardName;
  final String category;
  final int count;
  final String status;

  const HeatmapCell({
    required this.wardName,
    required this.category,
    required this.count,
    this.status = 'Normal',
  });
}

/// Interactive Ward Grievance Density Heatmap Matrix
class InteractiveHeatmapMatrix extends StatefulWidget {
  final List<String> wards;
  final List<String> categories;
  final Map<String, int> densityData; // 'Ward1_Roads' -> count
  final ValueChanged<String>? onCellSelected;

  const InteractiveHeatmapMatrix({
    super.key,
    required this.wards,
    required this.categories,
    required this.densityData,
    this.onCellSelected,
  });

  @override
  State<InteractiveHeatmapMatrix> createState() =>
      _InteractiveHeatmapMatrixState();
}

class _InteractiveHeatmapMatrixState extends State<InteractiveHeatmapMatrix> {
  String? _selectedKey;

  Color _getCellColor(int count) {
    if (count == 0) return Colors.white.withValues(alpha: 0.05);
    if (count == 1) return AppColors.primary.withValues(alpha: 0.4);
    if (count == 2) return AppColors.accent.withValues(alpha: 0.5);
    return AppColors.danger.withValues(alpha: 0.7);
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ward Grievance Density Matrix',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  _LegendDot(color: AppColors.primary, label: 'Low'),
                  const SizedBox(width: 8),
                  _LegendDot(color: AppColors.accent, label: 'Med'),
                  const SizedBox(width: 8),
                  _LegendDot(color: AppColors.danger, label: 'High'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Header Category Columns
          Row(
            children: [
              const SizedBox(width: 60), // Ward label spacer
              ...widget.categories.map((cat) {
                return Expanded(
                  child: Text(
                    cat.substring(0, min(4, cat.length)),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),

          // Matrix Rows
          ...widget.wards.map((ward) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      ward,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  ...widget.categories.map((cat) {
                    final key = '${ward}_$cat';
                    final count = widget.densityData[key] ?? 0;
                    final isSelected = _selectedKey == key;
                    final cellColor = _getCellColor(count);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedKey = isSelected ? null : key;
                          });
                          widget.onCellSelected?.call(key);
                        },
                        child: Container(
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : (count > 0
                                      ? cellColor.withValues(alpha: 0.8)
                                      : Colors.white.withValues(alpha: 0.06)),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            count > 0 ? '$count' : '',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
