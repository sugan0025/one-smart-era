import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

class DonutSegment {
  final String label;
  final double value;
  final Color color;
  final IconData? icon;

  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });
}

/// Interactive 360° Animated Donut Chart with Tap-to-Inspect and Center Tooltip
class InteractiveDonutChart extends StatefulWidget {
  final List<DonutSegment> segments;
  final double size;
  final double strokeWidth;
  final String centerTitle;
  final String? centerSubtitle;
  final ValueChanged<DonutSegment?>? onSegmentSelected;

  const InteractiveDonutChart({
    super.key,
    required this.segments,
    this.size = 200,
    this.strokeWidth = 26,
    this.centerTitle = 'Total',
    this.centerSubtitle,
    this.onSegmentSelected,
  });

  @override
  State<InteractiveDonutChart> createState() => _InteractiveDonutChartState();
}

class _InteractiveDonutChartState extends State<InteractiveDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double get totalValue =>
      widget.segments.fold(0.0, (sum, s) => sum + s.value);

  void _handleTap(TapUpDetails details, Size size) {
    if (widget.segments.isEmpty || totalValue == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final touch = details.localPosition - center;
    final distance = touch.distance;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - widget.strokeWidth - 10;

    // Verify tap is within donut ring
    if (distance < innerRadius || distance > outerRadius + 12) {
      setState(() => _selectedIndex = -1);
      widget.onSegmentSelected?.call(null);
      return;
    }

    double angle = atan2(touch.dy, touch.dx);
    if (angle < 0) angle += 2 * pi;
    // Normalize to -pi/2 start
    angle = (angle + pi / 2) % (2 * pi);

    double currentAngle = 0;
    for (int i = 0; i < widget.segments.length; i++) {
      final sweep = (widget.segments[i].value / totalValue) * 2 * pi;
      if (angle >= currentAngle && angle <= currentAngle + sweep) {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedIndex = (_selectedIndex == i) ? -1 : i;
        });
        widget.onSegmentSelected?.call(
          _selectedIndex == -1 ? null : widget.segments[_selectedIndex],
        );
        return;
      }
      currentAngle += sweep;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = totalValue;

    return Column(
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: GestureDetector(
            onTapUp: (details) => _handleTap(details, Size(widget.size, widget.size)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _DonutPainter(
                        segments: widget.segments,
                        total: total,
                        strokeWidth: widget.strokeWidth,
                        selectedIndex: _selectedIndex,
                        animValue: CurvedAnimation(
                          parent: _animController,
                          curve: Curves.easeOutBack,
                        ).value,
                      ),
                    );
                  },
                ),

                // Center Dynamic Badge
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_selectedIndex >= 0 && _selectedIndex < widget.segments.length) ...[
                      Text(
                        widget.segments[_selectedIndex].label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.segments[_selectedIndex].value.toInt()}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: widget.segments[_selectedIndex].color,
                        ),
                      ),
                      Text(
                        '${((widget.segments[_selectedIndex].value / (total > 0 ? total : 1)) * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ] else ...[
                      Text(
                        widget.centerTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${total.toInt()}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (widget.centerSubtitle != null)
                        Text(
                          widget.centerSubtitle!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryLight,
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Interactive Legend Pills
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: widget.segments.asMap().entries.map((entry) {
            final idx = entry.key;
            final seg = entry.value;
            final isSelected = _selectedIndex == idx;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedIndex = isSelected ? -1 : idx;
                });
                widget.onSegmentSelected?.call(isSelected ? null : seg);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? seg.color.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? seg.color : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: seg.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      seg.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${seg.value.toInt()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? seg.color : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double total;
  final double strokeWidth;
  final int selectedIndex;
  final double animValue;

  _DonutPainter({
    required this.segments,
    required this.total,
    required this.strokeWidth,
    required this.selectedIndex,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty || total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width - strokeWidth - 10) / 2;

    double startAngle = -pi / 2;

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final sweep = (seg.value / total) * 2 * pi * animValue.clamp(0.0, 1.0);
      final isSelected = selectedIndex == i;

      final radius = isSelected ? baseRadius + 4 : baseRadius;
      final currentStroke = isSelected ? strokeWidth + 4 : strokeWidth;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke
        ..strokeCap = StrokeCap.butt;

      if (isSelected) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.solid, 3.0);
      }

      // Small gap between segments
      final gap = segments.length > 1 ? 0.04 : 0.0;
      final adjustedSweep = max(0.0, sweep - gap);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (gap / 2),
        adjustedSweep,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.animValue != animValue ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.segments != segments;
  }
}
