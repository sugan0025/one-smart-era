import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

class AreaDataPoint {
  final String label; // e.g. 'Mon', 'Tue'
  final double value; // e.g. 38.5
  final String? subtext; // e.g. 'Vol: 4.2k kg'

  const AreaDataPoint({
    required this.label,
    required this.value,
    this.subtext,
  });
}

/// Touch-Scrubbable Cubic Bezier Area Wave Chart with Live Tracking Tooltip
class InteractiveAreaChart extends StatefulWidget {
  final List<AreaDataPoint> data;
  final double height;
  final Color primaryColor;
  final String unitPrefix;
  final String unitSuffix;

  const InteractiveAreaChart({
    super.key,
    required this.data,
    this.height = 190,
    this.primaryColor = AppColors.primary,
    this.unitPrefix = '₹',
    this.unitSuffix = '/kg',
  });

  @override
  State<InteractiveAreaChart> createState() => _InteractiveAreaChartState();
}

class _InteractiveAreaChartState extends State<InteractiveAreaChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _scrubIndex = -1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleScrub(Offset localPos, double width) {
    if (widget.data.isEmpty) return;

    final stepX = width / (widget.data.length - 1);
    final rawIndex = (localPos.dx / stepX).round().clamp(0, widget.data.length - 1);

    if (_scrubIndex != rawIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        _scrubIndex = rawIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return SizedBox(height: widget.height);

    final activePoint = _scrubIndex >= 0 && _scrubIndex < widget.data.length
        ? widget.data[_scrubIndex]
        : widget.data.last;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Cursor Metric Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.primaryColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        activePoint.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.primaryColor,
                        ),
                      ),
                    ),
                    if (activePoint.subtext != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        activePoint.subtext!,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${widget.unitPrefix}${activePoint.value.toStringAsFixed(1)}${widget.unitSuffix}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Interactive Chart Canvas
            GestureDetector(
              onHorizontalDragUpdate: (details) =>
                  _handleScrub(details.localPosition, width),
              onHorizontalDragStart: (details) =>
                  _handleScrub(details.localPosition, width),
              onTapDown: (details) =>
                  _handleScrub(details.localPosition, width),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(width, widget.height),
                    painter: _AreaChartPainter(
                      data: widget.data,
                      color: widget.primaryColor,
                      scrubIndex: _scrubIndex,
                      animProgress: CurvedAnimation(
                        parent: _animController,
                        curve: Curves.easeOutCubic,
                      ).value,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Horizontal X-Axis Days Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: widget.data.asMap().entries.map((e) {
                final idx = e.key;
                final point = e.value;
                final isSelected = (_scrubIndex == -1 && idx == widget.data.length - 1) ||
                    _scrubIndex == idx;

                return Text(
                  point.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? widget.primaryColor : AppColors.textMuted,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<AreaDataPoint> data;
  final Color color;
  final int scrubIndex;
  final double animProgress;

  _AreaChartPainter({
    required this.data,
    required this.color,
    required this.scrubIndex,
    required this.animProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final values = data.map((d) => d.value).toList();
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final stepX = size.width / (data.length - 1);
    final topPadding = 16.0;
    final bottomPadding = 12.0;
    final chartHeight = size.height - topPadding - bottomPadding;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalized = (data[i].value - minVal) / range;
      final y = (size.height - bottomPadding) - (normalized * chartHeight * animProgress);
      points.add(Offset(x, y));
    }

    // Build Smooth Cubic Bezier Path
    final path = Path();
    final fillPath = Path();

    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(points.first.dx, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY1 = p0.dy;
      final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY2 = p1.dy;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    // 1. Draw Multi-Stop Gradient Area Fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.08),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 2. Draw Glowing Stroke Line
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // 3. Draw Grid Guide Lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, topPadding), Offset(size.width, topPadding), gridPaint);
    canvas.drawLine(Offset(0, topPadding + chartHeight / 2), Offset(size.width, topPadding + chartHeight / 2), gridPaint);

    // 4. Draw Active Scrub Scrubber & Glowing Cursor Dot
    final activeIdx = scrubIndex >= 0 && scrubIndex < points.length
        ? scrubIndex
        : points.length - 1;
    final activePoint = points[activeIdx];

    // Vertical Scrubber Line
    final cursorLinePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(activePoint.dx, 0),
      Offset(activePoint.dx, size.height),
      cursorLinePaint,
    );

    // Outer Glow Ring
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(activePoint, 10, glowPaint);

    // Inner Solid Dot
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(activePoint, 4.5, dotPaint);

    // White Center Core
    final corePaint = Paint()..color = Colors.white;
    canvas.drawCircle(activePoint, 2.0, corePaint);
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return oldDelegate.animProgress != animProgress ||
        oldDelegate.scrubIndex != scrubIndex ||
        oldDelegate.data != data;
  }
}
