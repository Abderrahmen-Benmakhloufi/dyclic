import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// An ambient breathing aura widget that gently pulses when [isPulsing] is true.
/// Designed for dyslexia and cognitive ergonomics: provides clear living feedback
/// for active speech without rapid or jarring strobe flashes.
class AppAudioPulseAura extends StatefulWidget {
  final Widget child;
  final bool isPulsing;
  final Color pulseColor;
  final double maxScale;
  final BorderRadius? borderRadius;

  const AppAudioPulseAura({
    super.key,
    required this.child,
    required this.isPulsing,
    this.pulseColor = AppColors.primary,
    this.maxScale = 1.04,
    this.borderRadius,
  });

  @override
  State<AppAudioPulseAura> createState() => _AppAudioPulseAuraState();
}

class _AppAudioPulseAuraState extends State<AppAudioPulseAura>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AppAudioPulseAura oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.animateTo(0, duration: const Duration(milliseconds: 300));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final val = _animation.value;
        final currentScale = 1.0 + (widget.maxScale - 1.0) * val;
        final glowAlpha = (0.28 * val * (widget.isPulsing ? 1.0 : 0.0)).clamp(0.0, 1.0);

        return Transform.scale(
          scale: widget.isPulsing ? currentScale : 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
              boxShadow: widget.isPulsing
                  ? [
                      BoxShadow(
                        color: widget.pulseColor.withValues(alpha: glowAlpha),
                        blurRadius: 16 * val + 4,
                        spreadRadius: 2.5 * val,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
