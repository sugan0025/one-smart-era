import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Dynamic 60fps Animated Mesh Gradient Background with Role-Specific Presets
class AnimatedMeshBackground extends StatefulWidget {
  final Widget? child;
  final String roleTheme; // 'Public', 'Farmer', 'Admin'

  const AnimatedMeshBackground({
    super.key,
    this.child,
    this.roleTheme = 'Public',
  });

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
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
        // Base Solid Dark Layer
        Container(color: AppColors.bgDark),

        // Animated Mesh Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return CustomPaint(
              size: Size.infinite,
              painter: _RoleMeshGradientPainter(
                animationValue: t,
                roleTheme: widget.roleTheme,
              ),
            );
          },
        ),

        // Child content
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _RoleMeshGradientPainter extends CustomPainter {
  final double animationValue;
  final String roleTheme;

  _RoleMeshGradientPainter({
    required this.animationValue,
    required this.roleTheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    Color primaryGlow;
    Color secondaryGlow;
    Color accentGlow;

    if (roleTheme == 'Farmer') {
      // Warm Amber, Solar Orange & Forest Green
      primaryGlow = const Color(0xFFD97706); // Amber
      secondaryGlow = const Color(0xFF15803D); // Leaf Green
      accentGlow = const Color(0xFFC2410C); // Burnt Orange
    } else if (roleTheme == 'Admin') {
      // Command Blue, Indigo & Deep Cyan
      primaryGlow = const Color(0xFF0284C7); // Sky Blue
      secondaryGlow = const Color(0xFF4F46E5); // Indigo
      accentGlow = const Color(0xFF0E7490); // Cyan
    } else {
      // Public Citizen: Deep Emerald, Teal & Cyan
      primaryGlow = const Color(0xFF0F766E); // Deep Teal
      secondaryGlow = const Color(0xFF0369A1); // Ocean Blue
      accentGlow = const Color(0xFF10B981); // Emerald
    }

    // Blob 1: Top Left
    final p1 = Offset(
      w * 0.2 + sin(animationValue * 2 * pi) * 45,
      h * 0.15 + cos(animationValue * 2 * pi) * 35,
    );
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryGlow.withValues(alpha: 0.45),
          Colors.transparent,
        ],
        radius: 0.65,
      ).createShader(Rect.fromCircle(center: p1, radius: w * 0.75));
    canvas.drawCircle(p1, w * 0.75, paint1);

    // Blob 2: Bottom Right
    final p2 = Offset(
      w * 0.85 + cos(animationValue * 2 * pi) * 55,
      h * 0.8 + sin(animationValue * 2 * pi) * 45,
    );
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          secondaryGlow.withValues(alpha: 0.35),
          Colors.transparent,
        ],
        radius: 0.6,
      ).createShader(Rect.fromCircle(center: p2, radius: w * 0.7));
    canvas.drawCircle(p2, w * 0.7, paint2);

    // Blob 3: Center Left
    final p3 = Offset(
      w * 0.1 + cos(animationValue * pi) * 35,
      h * 0.55 + sin(animationValue * pi) * 55,
    );
    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          accentGlow.withValues(alpha: 0.25),
          Colors.transparent,
        ],
        radius: 0.5,
      ).createShader(Rect.fromCircle(center: p3, radius: w * 0.55));
    canvas.drawCircle(p3, w * 0.55, paint3);
  }

  @override
  bool shouldRepaint(covariant _RoleMeshGradientPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.roleTheme != roleTheme;
  }
}
