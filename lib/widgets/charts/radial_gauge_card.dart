import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../glass_card.dart';

/// Glowing Circular Speedometer / Occupancy Radial Progress Gauge Card
class RadialGaugeCard extends StatelessWidget {
  final String title;
  final double value; // 0.0 to 1.0
  final String displayValue;
  final String subtitle;
  final Color primaryColor;
  final Color? warningColor;
  final double size;

  const RadialGaugeCard({
    super.key,
    required this.title,
    required this.value,
    required this.displayValue,
    required this.subtitle,
    this.primaryColor = AppColors.primary,
    this.warningColor,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    final clampedVal = value.clamp(0.0, 1.0);
    final color = (clampedVal > 0.8 && warningColor != null)
        ? warningColor!
        : primaryColor;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(clampedVal * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Custom Painted Arc Gauge
          SizedBox(
            width: size,
            height: size * 0.75,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: clampedVal),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(size, size * 0.75),
                      painter: _RadialGaugePainter(
                        progress: animatedProgress,
                        color: color,
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayValue,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadialGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.42;

    const startAngle = pi * 0.85;
    const sweepAngle = pi * 1.3;

    // 1. Background Arc Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // 2. Glowing Progress Arc
    final activeSweep = sweepAngle * progress;
    if (activeSweep > 0) {
      final progressPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0.6),
            color,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        progressPaint,
      );

      // 3. Glowing Needle Head Indicator
      final needleAngle = startAngle + activeSweep;
      final headX = center.dx + radius * cos(needleAngle);
      final headY = center.dy + radius * sin(needleAngle);

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
      canvas.drawCircle(Offset(headX, headY), 9.0, glowPaint);

      final corePaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(headX, headY), 4.0, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
