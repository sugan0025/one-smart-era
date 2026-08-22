import 'package:flutter/material.dart';

/// Shimmer Loading Skeleton Placeholder
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (_controller.value * 2.5), -0.3),
              end: Alignment(1.0 + (_controller.value * 2.5), 0.3),
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.16),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
          ),
        );
      },
    );
  }
}
