import 'package:flutter/material.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';

/// Icon micro-interactions (DESIGN_SYSTEM §5). Every one is instant when the
/// OS asks to reduce motion.

/// Traces [icon]'s stroke from nothing to complete whenever [active] turns
/// true; otherwise shows it fully drawn.
class DrawOnIcon extends StatefulWidget {
  const new(
    this.icon, {
    required this.active,
    this.size = 24,
    this.color,
    this.strokeWidth = 1.8,
    this.duration = const Duration(milliseconds: 350),
    super.key,
  });

  final NavmaasIcon icon;
  final bool active;
  final double size;
  final Color? color;
  final double strokeWidth;
  final Duration duration;

  @override
  State<DrawOnIcon> createState() => _DrawOnIconState();
}

class _DrawOnIconState extends State<DrawOnIcon>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );

  @override
  void didUpdateWidget(DrawOnIcon old) {
    super.didUpdateWidget(old);
    if (widget.active &&
        !old.active &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => NmIcon(
      widget.icon,
      size: widget.size,
      color: widget.color,
      strokeWidth: widget.strokeWidth,
      progress: Curves.easeOut.transform(_controller.value),
    ),
  );
}

/// Shrinks [child] to 92 % while a finger is down on it.
class PressScale extends StatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  var _down = false;

  void _set(bool down) {
    if (down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: Duration(milliseconds: _down ? 120 : 200),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
