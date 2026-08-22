import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Cool Sci-Fi Laser Scan Line and Grid Animation for Crop Doctor AI Analysis
class LaserScannerAnimation extends StatefulWidget {
  final Widget child;
  final bool isScanning;
  final Color scanColor;

  const LaserScannerAnimation({
    super.key,
    required this.child,
    required this.isScanning,
    this.scanColor = AppColors.primaryLight,
  });

  @override
  State<LaserScannerAnimation> createState() => _LaserScannerAnimationState();
}

class _LaserScannerAnimationState extends State<LaserScannerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.isScanning) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant LaserScannerAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isScanning && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        if (widget.isScanning)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _LaserScanPainter(
                    progress: _controller.value,
                    color: widget.scanColor,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _LaserScanPainter extends CustomPainter {
  final double progress;
  final Color color;

  _LaserScanPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;

    // 1. Draw glowing laser line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    // 2. Draw sweeping trailing beam gradient
    final beamHeight = size.height * 0.25;
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.25),
        ],
      ).createShader(Rect.fromLTWH(0, y - beamHeight, size.width, beamHeight));

    canvas.drawRect(Rect.fromLTWH(0, y - beamHeight, size.width, beamHeight), beamPaint);

    // 3. Draw cybernetic corner target reticles
    final reticlePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const cornerLen = 22.0;

    // Top-Left
    canvas.drawLine(const Offset(8, 8), const Offset(8 + cornerLen, 8), reticlePaint);
    canvas.drawLine(const Offset(8, 8), const Offset(8, 8 + cornerLen), reticlePaint);

    // Top-Right
    canvas.drawLine(Offset(size.width - 8, 8), Offset(size.width - 8 - cornerLen, 8), reticlePaint);
    canvas.drawLine(Offset(size.width - 8, 8), Offset(size.width - 8, 8 + cornerLen), reticlePaint);

    // Bottom-Left
    canvas.drawLine(Offset(8, size.height - 8), Offset(8 + cornerLen, size.height - 8), reticlePaint);
    canvas.drawLine(Offset(8, size.height - 8), Offset(8, size.height - 8 - cornerLen), reticlePaint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width - 8, size.height - 8), Offset(size.width - 8 - cornerLen, size.height - 8), reticlePaint);
    canvas.drawLine(Offset(size.width - 8, size.height - 8), Offset(size.width - 8, size.height - 8 - cornerLen), reticlePaint);
  }

  @override
  bool shouldRepaint(covariant _LaserScanPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
