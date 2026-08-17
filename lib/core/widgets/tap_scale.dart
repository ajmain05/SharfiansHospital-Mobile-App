import 'package:flutter/material.dart';

/// Wraps any widget with a subtle scale + haptic tap animation.
/// Uses only AnimationController — zero extra packages.
/// Perfect for cards, buttons, and list tiles.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: widget.scaleFactor,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.reverse();
  void _onTapUp(_) {
    _ctrl.forward();
    widget.onTap?.call();
  }
  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Fade+Slide page transition — lightweight, feels native.
Widget slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const begin = Offset(0, 0.04);
  const end = Offset.zero;
  final tween = Tween(begin: begin, end: end)
      .chain(CurveTween(curve: Curves.easeOutCubic));

  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: SlideTransition(
      position: animation.drive(tween),
      child: child,
    ),
  );
}

/// Fade-only transition — ultra-smooth for tab-like navigation.
Widget fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    child: child,
  );
}

/// Scale+fade transition — premium feel for modal-like screens.
Widget scaleUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final scaleTween = Tween<double>(begin: 0.94, end: 1.0)
      .chain(CurveTween(curve: Curves.easeOutCubic));

  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: ScaleTransition(
      scale: animation.drive(scaleTween),
      child: child,
    ),
  );
}
