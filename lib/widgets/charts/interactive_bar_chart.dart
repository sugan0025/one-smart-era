import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

class BarDataGroup {
  final String category; // e.g. 'Erode', 'Sathy'
  final double value; // e.g. 38.0
  final double? secondaryValue; // e.g. Budget Allocated vs Spent
  final Color? barColor;

  const BarDataGroup({
    required this.category,
    required this.value,
    this.secondaryValue,
    this.barColor,
  });
}

/// Interactive Animated Multi-Bar Comparison Chart
class InteractiveBarChart extends StatefulWidget {
  final List<BarDataGroup> data;
  final double height;
  final Color defaultColor;
  final String unitPrefix;
  final String unitSuffix;
  final ValueChanged<BarDataGroup>? onBarSelected;

  const InteractiveBarChart({
    super.key,
    required this.data,
    this.height = 180,
    this.defaultColor = AppColors.primary,
    this.unitPrefix = '₹',
    this.unitSuffix = '',
    this.onBarSelected,
  });

  @override
  State<InteractiveBarChart> createState() => _InteractiveBarChartState();
}

class _InteractiveBarChartState extends State<InteractiveBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return SizedBox(height: widget.height);

    final double maxVal = widget.data.fold(
      0.0,
      (prev, d) => max(prev, max(d.value, d.secondaryValue ?? 0.0)),
    );
    final safeMax = maxVal == 0 ? 1.0 : maxVal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selected Bar Tooltip Banner
        if (_selectedIndex >= 0 && _selectedIndex < widget.data.length)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: (widget.data[_selectedIndex].barColor ?? widget.defaultColor)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (widget.data[_selectedIndex].barColor ?? widget.defaultColor)
                    .withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.data[_selectedIndex].category,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${widget.unitPrefix}${widget.data[_selectedIndex].value.toStringAsFixed(1)}${widget.unitSuffix}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: widget.data[_selectedIndex].barColor ?? widget.defaultColor,
                  ),
                ),
              ],
            ),
          ),

        // Bars Canvas
        SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              final anim = CurvedAnimation(
                parent: _animController,
                curve: Curves.easeOutBack,
              ).value;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: widget.data.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final isSelected = _selectedIndex == idx;
                  final color = item.barColor ?? widget.defaultColor;
                  final normalizedHeight = (item.value / safeMax) * (widget.height - 30);
                  final barHeight = max(8.0, normalizedHeight * anim.clamp(0.0, 1.0));

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedIndex = (_selectedIndex == idx) ? -1 : idx;
                        });
                        widget.onBarSelected?.call(item);
                      },
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Value Label over Bar
                            if (isSelected)
                              Text(
                                '${item.value.toInt()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            const SizedBox(height: 4),

                            // Rounded Gradient Bar Container
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: barHeight,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: isSelected
                                      ? [color, color.withValues(alpha: 0.6)]
                                      : [color.withValues(alpha: 0.8), color.withValues(alpha: 0.35)],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                                  width: isSelected ? 1.5 : 0.8,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Category Label
                            Text(
                              item.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? color : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
