import 'package:flutter/material.dart';

class PageAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double slideDistance;
  final double bounceHeight;
  final Curve curve;

  const PageAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.slideDistance = 50.0,
    this.bounceHeight = 20.0,
    this.curve = Curves.elasticOut,
  });

  @override
  State<PageAnimation> createState() => _PageAnimationState();
}

class _PageAnimationState extends State<PageAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _bounceAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Opacity animation
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Bouncy slide animation
    _bounceAnimation = Tween<Offset>(
      begin: Offset(0.0, widget.slideDistance / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Scale animation for extra bounce effect
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
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
      position: _bounceAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

class BouncyAnimatedItemWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double slideDistance;
  final double bounceHeight;
  final Curve curve;

  const BouncyAnimatedItemWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.slideDistance = 50.0,
    this.bounceHeight = 20.0,
    this.curve = Curves.elasticOut,
  });

  @override
  State<BouncyAnimatedItemWrapper> createState() =>
      _BouncyAnimatedItemWrapperState();
}

class _BouncyAnimatedItemWrapperState extends State<BouncyAnimatedItemWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _bounceAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Opacity animation
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Bouncy slide animation
    _bounceAnimation = Tween<Offset>(
      begin: Offset(0.0, widget.slideDistance / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Scale animation for extra bounce effect
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
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
      position: _bounceAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

// Staggered bouncy version
class StaggeredBouncyAnimatedWrapper extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration baseDuration;
  final Duration staggerDelay;
  final double slideDistance;
  final double bounceHeight;
  final Curve curve;

  const StaggeredBouncyAnimatedWrapper({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDuration = const Duration(milliseconds: 800),
    this.staggerDelay = const Duration(milliseconds: 150),
    this.slideDistance = 50.0,
    this.bounceHeight = 20.0,
    this.curve = Curves.elasticOut,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyAnimatedItemWrapper(
      duration: baseDuration,
      delay: Duration(milliseconds: (staggerDelay.inMilliseconds * index)),
      slideDistance: slideDistance,
      bounceHeight: bounceHeight,
      curve: curve,
      child: child,
    );
  }
}

// Custom bouncy animation with more control
class CustomBouncyWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double initialScale;
  final double overshootScale;
  final double slideDistance;
  final bool useCustomBounce;

  const CustomBouncyWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
    this.delay = Duration.zero,
    this.initialScale = 0.7,
    this.overshootScale = 1.1,
    this.slideDistance = 60.0,
    this.useCustomBounce = true,
  });

  @override
  State<CustomBouncyWrapper> createState() => _CustomBouncyWrapperState();
}

class _CustomBouncyWrapperState extends State<CustomBouncyWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    if (widget.useCustomBounce) {
      // Custom bounce sequence
      _scaleAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
                  begin: widget.initialScale, end: widget.overshootScale)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 60,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: widget.overshootScale, end: 0.95)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.95, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 20,
        ),
      ]).animate(_controller);
    } else {
      _scaleAnimation = Tween<double>(
        begin: widget.initialScale,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ));
    }

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, widget.slideDistance / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
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
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

// Simple spring bounce wrapper
class SpringBouncyWrapper extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double springTension;
  final double springFriction;

  const SpringBouncyWrapper({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.springTension = 200.0,
    this.springFriction = 8.0,
  });

  @override
  State<SpringBouncyWrapper> createState() => _SpringBouncyWrapperState();
}

class _SpringBouncyWrapperState extends State<SpringBouncyWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: _animation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

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
    this.index = 0,
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
