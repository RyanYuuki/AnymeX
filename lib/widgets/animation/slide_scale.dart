import 'package:flutter/material.dart';

class SlideAndScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double initialScale;
  final double finalScale;
  final Offset initialOffset;
  final Offset finalOffset;

  const SlideAndScaleAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.initialScale = 0.0,
    this.finalScale = 1.0,
    this.initialOffset = const Offset(1.0, 0.0),
    this.finalOffset = const Offset(0.0, 0.0),
  });

  @override
  SlideAndScaleAnimationState createState() => SlideAndScaleAnimationState();
}

class SlideAndScaleAnimationState extends State<SlideAndScaleAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.initialScale,
      end: widget.finalScale,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.initialOffset,
      end: widget.finalOffset,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}
