import 'package:flutter/material.dart';

/// Micro-Animation Widget for Staggered Fade and Slide Entrance
class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 400),
    this.offset = const Offset(0, 24),
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
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
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.translate(
            offset: _slideAnim.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
