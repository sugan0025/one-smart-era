import 'package:flutter/material.dart';

/// Concentric Expanding Pulse Rings Animation
class PulseRingAnimation extends StatefulWidget {
  final Widget child;
  final Color ringColor;
  final double maxRadius;
  final bool animate;

  const PulseRingAnimation({
    super.key,
    required this.child,
    this.ringColor = const Color(0xFFEF4444),
    this.maxRadius = 36,
    this.animate = true,
  });

  @override
  State<PulseRingAnimation> createState() => _PulseRingAnimationState();
}

class _PulseRingAnimationState extends State<PulseRingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant PulseRingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
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
      alignment: Alignment.center,
      children: [
        if (widget.animate)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final val = _controller.value;
              return Container(
                width: widget.maxRadius * 2 * val,
                height: widget.maxRadius * 2 * val,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.ringColor.withValues(alpha: (1.0 - val) * 0.6),
                    width: 2.0,
                  ),
                ),
              );
            },
          ),
        widget.child,
      ],
    );
  }
}
