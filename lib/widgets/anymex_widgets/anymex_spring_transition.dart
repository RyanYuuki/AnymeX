import 'package:flutter/material.dart';

enum SpringTransitionDirection {
  bottomToTop,
  topToBottom,
  leftToRight,
  rightToLeft,
}

class AnymeXSpringTransition extends StatefulWidget {
  final Widget child;
  final SpringTransitionDirection direction;
  final Duration duration;
  final Duration delay;
  final double initialOffset;
  final Curve curve;
  final bool animateScale;
  final double initialScale;
  final bool animateOpacity;
  final bool enabled;

  const AnymeXSpringTransition({
    super.key,
    required this.child,
    this.direction = SpringTransitionDirection.bottomToTop,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.initialOffset = 40.0,
    this.curve = const Cubic(0.34, 1.56, 0.64, 1.0),
    this.animateScale = true,
    this.initialScale = 0.9,
    this.animateOpacity = true,
    this.enabled = true,
  });

  @override
  State<AnymeXSpringTransition> createState() => _AnymeXSpringTransitionState();
}

class _AnymeXSpringTransitionState extends State<AnymeXSpringTransition>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    Offset beginOffset;
    switch (widget.direction) {
      case SpringTransitionDirection.bottomToTop:
        beginOffset = Offset(0.0, widget.initialOffset);
        break;
      case SpringTransitionDirection.topToBottom:
        beginOffset = Offset(0.0, -widget.initialOffset);
        break;
      case SpringTransitionDirection.leftToRight:
        beginOffset = Offset(-widget.initialOffset, 0.0);
        break;
      case SpringTransitionDirection.rightToLeft:
        beginOffset = Offset(widget.initialOffset, 0.0);
        break;
    }

    final curvedAnimation = CurvedAnimation(
      parent: _controller!,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(curvedAnimation);

    _scaleAnimation = Tween<double>(
      begin: widget.initialScale,
      end: 1.0,
    ).animate(curvedAnimation);

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeOut,
    ));

    if (widget.delay == Duration.zero) {
      _controller!.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted && _controller != null) {
          _controller!.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _controller == null) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        Widget current = Transform.translate(
          offset: _slideAnimation.value,
          child: child,
        );

        if (widget.animateScale) {
          current = Transform.scale(
            scale: _scaleAnimation.value,
            child: current,
          );
        }

        if (widget.animateOpacity) {
          current = Opacity(
            opacity: _opacityAnimation.value,
            child: current,
          );
        }

        return current;
      },
      child: widget.child,
    );
  }
}
