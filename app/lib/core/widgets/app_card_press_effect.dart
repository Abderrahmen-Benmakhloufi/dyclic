import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A subtle tactile press effect that gently scales the child down on press
/// and triggers a soft haptic feedback pulse, giving cards and interactive
/// surfaces a polished physical tactile response without visual disorientation.
class AppCardPressEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration duration;
  final bool enableHaptic;

  const AppCardPressEffect({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.975,
    this.duration = const Duration(milliseconds: 110),
    this.enableHaptic = true,
  });

  @override
  State<AppCardPressEffect> createState() => _AppCardPressEffectState();
}

class _AppCardPressEffectState extends State<AppCardPressEffect> {
  bool _isPressed = false;

  void _handlePressDown() {
    if (!_isPressed) {
      setState(() => _isPressed = true);
      if (widget.enableHaptic) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _handlePressUp() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animatedScale = AnimatedScale(
      scale: _isPressed ? widget.pressedScale : 1.0,
      duration: widget.duration,
      curve: _isPressed ? Curves.easeInOutCubic : Curves.easeOutCubic,
      child: widget.child,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _handlePressDown(),
        onTapUp: (_) => _handlePressUp(),
        onTapCancel: () => _handlePressUp(),
        onTap: widget.onTap,
        child: animatedScale,
      );
    }

    // When child handles its own clicks (e.g. Card with InkWell),
    // use Listener to detect pointer down/up without consuming gesture arena
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _handlePressDown(),
      onPointerUp: (_) => _handlePressUp(),
      onPointerCancel: (_) => _handlePressUp(),
      child: animatedScale,
    );
  }
}
