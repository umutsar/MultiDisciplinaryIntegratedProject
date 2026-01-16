import 'package:flutter/material.dart';

/// Pulsing dot animation to convey a "live" indicator.
class PulsingDot extends StatefulWidget {
  const PulsingDot({
    super.key,
    this.color = const Color(0xFF22C55E),
    this.size = 10,
    this.duration = const Duration(milliseconds: 900),
  });

  final Color color;
  final double size;
  final Duration duration;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _t = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final scale = 0.85 + (_t.value * 0.35);
        final glow = 0.15 + (_t.value * 0.25);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size * 2.2,
              height: widget.size * 2.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: glow),
              ),
            ),
            Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

