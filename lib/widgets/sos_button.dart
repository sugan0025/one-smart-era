import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state.dart';

/// 3-Second Hold Emergency SOS Button with Ripple and Haptic Feedback
class SOSButton extends StatefulWidget {
  final VoidCallback? onSOSCompleted;
  final double size;

  const SOSButton({
    super.key,
    this.onSOSCompleted,
    this.size = 72,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  double _holdProgress = 0.0;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
    });
    HapticFeedback.mediumImpact();
    _startHoldTimer();
  }

  void _onTapUp(TapUpDetails details) {
    _cancelHold();
  }

  void _onTapCancel() {
    _cancelHold();
  }

  void _cancelHold() {
    if (_isHolding && _holdProgress < 1.0) {
      setState(() {
        _isHolding = false;
        _holdProgress = 0.0;
      });
    }
  }

  void _startHoldTimer() async {
    const totalSteps = 30;
    for (int i = 1; i <= totalSteps; i++) {
      if (!_isHolding) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isHolding) return;

      setState(() {
        _holdProgress = i / totalSteps;
      });

      if (i % 8 == 0) {
        HapticFeedback.lightImpact();
      }
    }

    if (_isHolding && _holdProgress >= 1.0) {
      HapticFeedback.vibrate();
      appState.triggerSOS();
      if (widget.onSOSCompleted != null) {
        widget.onSOSCompleted!();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    appState.t('sos_sent'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      setState(() {
        _isHolding = false;
        _holdProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.05);
          return Transform.scale(
            scale: _isHolding ? 1.08 : scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.dangerGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withValues(
                      alpha: 0.35 + (_pulseController.value * 0.25),
                    ),
                    blurRadius: 22 + (_pulseController.value * 8),
                    spreadRadius: 2 + (_pulseController.value * 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circular Progress Indicator when holding
                  if (_isHolding)
                    SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: CircularProgressIndicator(
                        value: _holdProgress,
                        strokeWidth: 4.5,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.crisis_alert_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isHolding ? '${((1 - _holdProgress) * 3).ceil()}s' : 'SOS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
