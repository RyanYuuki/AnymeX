import 'package:flutter/material.dart';

class StaggeredFadeScale extends StatefulWidget {
  const StaggeredFadeScale({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 500),
    this.scaleBegin = 0.88,
    this.delayStepMs = 80,
    this.maxDelayMs = 640,
  });

  final Widget child;
  final int index;
  final Duration duration;
  final double scaleBegin;
  final int delayStepMs;
  final int maxDelayMs;

  @override
  State<StaggeredFadeScale> createState() => _StaggeredFadeScaleState();
}

class _StaggeredFadeScaleState extends State<StaggeredFadeScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<double> fadeAnimation;
  late final Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: widget.duration);
    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeIn,
    );
    scaleAnimation = Tween<double>(begin: widget.scaleBegin, end: 1).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutBack),
    );

    final delayMs = (widget.index * widget.delayStepMs).clamp(0, widget.maxDelayMs);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

class StaggeredFadeSlide extends StatefulWidget {
  const StaggeredFadeSlide({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 380),
    this.beginOffset = const Offset(0.04, 0),
    this.delayStepMs = 35,
    this.maxDelayMs = 600,
  });

  final Widget child;
  final int index;
  final Duration duration;
  final Offset beginOffset;
  final int delayStepMs;
  final int maxDelayMs;

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<double> fadeAnimation;
  late final Animation<Offset> slideAnimation;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: widget.duration);
    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeIn,
    );
    slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeOut));

    final delayMs = (widget.index * widget.delayStepMs).clamp(0, widget.maxDelayMs);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: widget.child,
      ),
    );
  }
}
