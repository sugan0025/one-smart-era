import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Mini 7-Day APMC Mandi Price Sparkline Chart
class SparklineChart extends StatelessWidget {
  final List<double> data;
  final double width;
  final double height;
  final bool isBullish;
  final Color? lineColor;

  const SparklineChart({
    super.key,
    required this.data,
    this.width = 110,
    this.height = 42,
    this.isBullish = true,
    this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    final color = lineColor ?? (isBullish ? AppColors.success : AppColors.danger);

    return CustomPaint(
      size: Size(width, height),
      painter: _SparklinePainter(data: data, color: color),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minVal = data.reduce(min);
    final maxVal = data.reduce(max);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final stepX = size.width / (data.length - 1);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalized = (data[i] - minVal) / range;
      // Invert Y so highest price is at top
      final y = size.height - (normalized * (size.height - 10)) - 5;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw End Point Dot
    final lastNormalized = (data.last - minVal) / range;
    final lastY = size.height - (lastNormalized * (size.height - 10)) - 5;
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(size.width, lastY), 3.5, dotPaint);

    final dotBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(size.width, lastY), 3.5, dotBorder);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}
