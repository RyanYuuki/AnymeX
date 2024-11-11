import 'package:flutter/material.dart';

class Ripple extends StatefulWidget {
  final Widget child;
  final Color color;
  final double duration;
  final bool centered;

  const Ripple({
    super.key,
    required this.child,
    required this.color,
    required this.duration,
    this.centered = false,
  });

  @override
  _RippleState createState() => _RippleState();
}

class _RippleState extends State<Ripple> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.duration.toInt()),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
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
        return CustomPaint(
          painter: RipplePainter(
            animation: _animation.value,
            color: widget.color,
            centered: widget.centered,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class RipplePainter extends CustomPainter {
  final double animation;
  final Color color;
  final bool centered;

  RipplePainter({
    required this.animation,
    required this.color,
    this.centered = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = centered
        ? Offset(size.width / 2, size.height / 2)
        : Offset(size.width, size.height);
    final radius = size.width * animation;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) {
    return animation != oldDelegate.animation ||
        color != oldDelegate.color ||
        centered != oldDelegate.centered;
  }
}
