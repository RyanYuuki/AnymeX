import 'package:flutter/material.dart';

class AnimatedItemWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double slideDistance;
  final Curve curve;

  const AnimatedItemWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.slideDistance = 30.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedItemWrapper> createState() => _AnimatedItemWrapperState();
}

class _AnimatedItemWrapperState extends State<AnimatedItemWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, widget.slideDistance / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Start animation after delay
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      ),
    );
  }
}

// Optional: Staggered version for multiple items
class StaggeredAnimatedItemWrapper extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration baseDuration;
  final Duration staggerDelay;
  final double slideDistance;
  final Curve curve;

  const StaggeredAnimatedItemWrapper({
    super.key,
    required this.child,
    required this.index,
    this.baseDuration = const Duration(milliseconds: 600),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.slideDistance = 30.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedItemWrapper(
      duration: baseDuration,
      delay: Duration(milliseconds: (staggerDelay.inMilliseconds * index)),
      slideDistance: slideDistance,
      curve: curve,
      child: child,
    );
  }
}

// Alternative: Visibility-based animation (more performant for large lists)
class VisibilityAnimatedWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double slideDistance;
  final Curve curve;
  final bool startAnimation;

  const VisibilityAnimatedWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.slideDistance = 30.0,
    this.curve = Curves.easeOutCubic,
    this.startAnimation = true,
  });

  @override
  State<VisibilityAnimatedWrapper> createState() =>
      _VisibilityAnimatedWrapperState();
}

class _VisibilityAnimatedWrapperState extends State<VisibilityAnimatedWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.8, curve: widget.curve),
    ));

    _slideAnimation = Tween<double>(
      begin: widget.slideDistance,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.startAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(VisibilityAnimatedWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startAnimation && !oldWidget.startAnimation) {
      _controller.forward();
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
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
