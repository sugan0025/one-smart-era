import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Ultra-Modern Frosted Glass Container with Border Gradient and Glow
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? customBgColor;
  final Border? customBorder;
  final Color? borderColor;
  final double blurAmount;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = 22,
    this.onTap,
    this.customBgColor,
    this.customBorder,
    this.borderColor,
    this.blurAmount = 14,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: customBgColor ?? const Color(0xFF0F172A).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(borderRadius),
            border: customBorder ??
                Border.all(
                  color: borderColor ?? Colors.white.withValues(alpha: 0.12),
                  width: 1.2,
                ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.primary.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: card,
        ),
      );
    }

    return card;
  }
}
