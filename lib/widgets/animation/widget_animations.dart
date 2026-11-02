import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/settings/settings.dart';

class AnymeXSpring extends StatefulWidget {
  final Widget child;
  final Duration? delay;
  final int index;
  final double slideY;
  final double slideX;
  final double beginScale;
  final double stiffness;
  final double damping;
  final bool fade;
  final bool enabled;
  final bool onScroll;
  final double visibleFraction;
  final Alignment alignment;

  const AnymeXSpring({
    super.key,
    required this.child,
    this.delay,
    this.index = 0,
    this.slideY = 0.0,
    this.slideX = 0.0,
    this.beginScale = 0.7,
    this.stiffness = 320.0,
    this.damping = 0.6,
    this.fade = true,
    this.enabled = true,
    this.onScroll = false,
    this.visibleFraction = 0.08,
    this.alignment = Alignment.center,
  });

  @override
  State<AnymeXSpring> createState() => _AnymeXSpringState();
}

class _AnymeXSpringState extends State<AnymeXSpring>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<ScrollableState> _scrollables = [];
  Timer? _timer;
  Timer? _completionTimer;
  bool _started = false;
  bool _isCompleted = false;
  bool _disabled = false;

  bool get _animationsDisabled {
    if (!widget.enabled) return true;
    if (Get.isRegistered<Settings>()) {
      return Get.find<Settings>().animationDuration <= 0;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _disabled = _animationsDisabled;
    if (_disabled) {
      _isCompleted = true;
      return;
    }

    _controller = AnimationController.unbounded(vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_isCompleted) {
        setState(() {
          _isCompleted = true;
        });
      }
    });

    if (widget.onScroll) {
      _attachScrollables();
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
    } else {
      _start();
    }
  }

  void _attachScrollables() {
    BuildContext? current = context;
    while (current != null) {
      final scrollable = current.findAncestorStateOfType<ScrollableState>();
      if (scrollable == null) break;
      _scrollables.add(scrollable);
      scrollable.position.addListener(_checkVisibility);
      current = scrollable.context;
    }
  }

  void _detachScrollables() {
    for (final scrollable in _scrollables) {
      scrollable.position.removeListener(_checkVisibility);
    }
    _scrollables.clear();
  }

  void _checkVisibility() {
    if (!mounted || _started) return;
    if (_scrollables.isEmpty) {
      _start();
      return;
    }

    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;

    for (final scrollable in _scrollables) {
      final viewport = scrollable.context.findRenderObject();
      if (viewport is! RenderBox || !viewport.attached || !viewport.hasSize) {
        return;
      }

      Offset offset;
      try {
        offset = box.localToGlobal(Offset.zero, ancestor: viewport);
      } catch (_) {
        return;
      }

      final vertical = scrollable.position.axis == Axis.vertical;
      final start = vertical ? offset.dy : offset.dx;
      final size = vertical ? box.size.height : box.size.width;
      final viewportSize =
          vertical ? viewport.size.height : viewport.size.width;

      final visibleStart = start < 0 ? 0.0 : start;
      final visibleEnd =
          start + size > viewportSize ? viewportSize : start + size;
      final visible = visibleEnd - visibleStart;
      final needed =
          (size < viewportSize ? size : viewportSize) * widget.visibleFraction;

      if (visible <= 0 || visible < needed) return;
    }

    _start();
  }

  void _start() {
    if (_started) return;
    _started = true;
    _detachScrollables();

    final delay = widget.delay ??
        Duration(milliseconds: widget.index.clamp(0, 8) * 35);

    if (delay == Duration.zero) {
      _run();
    } else {
      _timer = Timer(delay, _run);
    }
  }

  void _run() {
    if (!mounted) return;
    final spring = SpringDescription.withDampingRatio(
      mass: 1.0,
      stiffness: widget.stiffness,
      ratio: widget.damping,
    );
    _controller.animateWith(SpringSimulation(spring, 0.0, 1.0, 0.0));
    _completionTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted && !_isCompleted) {
        setState(() {
          _isCompleted = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnymeXSpring oldWidget) {
    super.didUpdateWidget(oldWidget);
    final disabledNow = _animationsDisabled;
    if (_disabled != disabledNow) {
      _disabled = disabledNow;
      if (_disabled) {
        _timer?.cancel();
        _completionTimer?.cancel();
        _detachScrollables();
        _isCompleted = true;
        return;
      }
    }
    if (!_started && !_disabled) {
      if (widget.onScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
      } else {
        _start();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _completionTimer?.cancel();
    _detachScrollables();
    if (!_disabled) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_disabled || _isCompleted) return widget.child;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final t = _controller.value;
          final inverse = 1.0 - t;

          Widget result = child!;

          if (widget.slideX != 0.0 || widget.slideY != 0.0) {
            result = FractionalTranslation(
              translation:
                  Offset(widget.slideX * inverse, widget.slideY * inverse),
              child: result,
            );
          }

          if (widget.beginScale != 1.0) {
            result = Transform.scale(
              scale: widget.beginScale + (1.0 - widget.beginScale) * t,
              alignment: widget.alignment,
              child: result,
            );
          }

          if (widget.fade) {
            final opacity = (t / 0.5).clamp(0.0, 1.0);
            if (opacity < 1.0) {
              result = Opacity(
                opacity: opacity,
                child: result,
              );
            }
          }

          return result;
        },
      ),
    );
  }
}

class AnymeXEntrance extends StatelessWidget {
  final Widget child;
  final Duration? delay;
  final Duration duration;
  final double slideX;
  final double slideY;
  final double beginScale;
  final bool fade;
  final bool enabled;
  final Curve curve;
  final Alignment alignment;

  const AnymeXEntrance({
    super.key,
    required this.child,
    this.delay,
    this.duration = const Duration(milliseconds: 220),
    this.slideX = 0.0,
    this.slideY = 0.05,
    this.beginScale = 0.95,
    this.fade = true,
    this.enabled = true,
    this.curve = Curves.easeOutCubic,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return AnymeXSpring(
      delay: delay,
      slideX: slideX,
      slideY: slideY,
      beginScale: beginScale,
      fade: fade,
      enabled: enabled,
      alignment: alignment,
      child: child,
    );
  }
}

extension AnymeXWidgetAnimations on Widget {
  Widget animateTileEntrance({
    required int index,
    bool isGrid = false,
    double slideY = 0.0,
    double beginScale = 0.7,
    double stiffness = 320.0,
    double damping = 0.6,
  }) {
    return AnymeXSpring(
      index: index,
      delay: Duration(milliseconds: (index % (isGrid ? 3 : 6)) * 35),
      slideY: slideY,
      beginScale: beginScale,
      stiffness: stiffness,
      damping: damping,
      child: this,
    );
  }

  Widget animateSpring({
    int index = 0,
    Duration? delay,
    double slideY = 0.06,
    double slideX = 0.0,
    double beginScale = 0.92,
    double stiffness = 220.0,
    double damping = 0.78,
    bool fade = true,
    bool enabled = true,
  }) {
    return AnymeXSpring(
      index: index,
      delay: delay,
      slideY: slideY,
      slideX: slideX,
      beginScale: beginScale,
      stiffness: stiffness,
      damping: damping,
      fade: fade,
      enabled: enabled,
      child: this,
    );
  }

  Widget animateFadeUp({
    int index = 0,
    Duration? delay,
    double slideY = 0.08,
    double stiffness = 200.0,
    double damping = 0.9,
    bool enabled = true,
  }) {
    return AnymeXSpring(
      index: index,
      delay: delay,
      slideY: slideY,
      beginScale: 1.0,
      stiffness: stiffness,
      damping: damping,
      fade: true,
      enabled: enabled,
      child: this,
    );
  }

  Widget animateFadeDown({
    int index = 0,
    Duration? delay,
    double slideY = 0.08,
    double stiffness = 200.0,
    double damping = 0.9,
    bool enabled = true,
  }) {
    return AnymeXSpring(
      index: index,
      delay: delay,
      slideY: -slideY,
      beginScale: 1.0,
      stiffness: stiffness,
      damping: damping,
      fade: true,
      enabled: enabled,
      child: this,
    );
  }

  Widget animateSlideLeft({
    int index = 0,
    Duration? delay,
    double slideX = 0.08,
    double stiffness = 220.0,
    double damping = 0.85,
    bool enabled = true,
  }) {
    return AnymeXSpring(
      index: index,
      delay: delay,
      slideX: slideX,
      slideY: 0.0,
      beginScale: 0.94,
      stiffness: stiffness,
      damping: damping,
      fade: true,
      enabled: enabled,
      child: this,
    );
  }

  Widget animateSlideRight({
    int index = 0,
    Duration? delay,
    double slideX = 0.08,
    double stiffness = 220.0,
    double damping = 0.85,
    bool enabled = true,
  }) {
    return AnymeXSpring(
      index: index,
      delay: delay,
      slideX: -slideX,
      slideY: 0.0,
      beginScale: 0.94,
      stiffness: stiffness,
      damping: damping,
      fade: true,
      enabled: enabled,
      child: this,
    );
  }

  Widget animateScale({
    int index = 0,
    Duration? delay,
    double beginScale = 0.88,
    double stiffness = 260.0,
    double damping = 0.72,
    bool enabled = true,
  }) {
    return AnymeXSpring(
      index: index,
      delay: delay,
      slideY: 0.0,
      beginScale: beginScale,
      stiffness: stiffness,
      damping: damping,
      fade: true,
      enabled: enabled,
      child: this,
    );
  }

  Widget animatePop({
    int index = 0,
    Duration? delay,
    double beginScale = 0.7,
    double slideY = 0.0,
    double stiffness = 320.0,
    double damping = 0.6,
    bool enabled = true,
    bool isGrid = false,
  }) {
    return AnymeXSpring(
      index: index,
      delay: delay ??
          Duration(milliseconds: (index % (isGrid ? 3 : 6)) * 35),
      slideY: slideY,
      beginScale: beginScale,
      stiffness: stiffness,
      damping: damping,
      enabled: enabled,
      child: this,
    );
  }

  Widget animateOnScroll({
    int index = 0,
    Duration? delay,
    double slideY = 0.08,
    double beginScale = 0.94,
    double stiffness = 180.0,
    double damping = 0.82,
    double visibleFraction = 0.08,
    bool enabled = true,
  }) {
    return AnymeXSpring(
      index: index,
      delay: delay ?? Duration.zero,
      slideY: slideY,
      beginScale: beginScale,
      stiffness: stiffness,
      damping: damping,
      onScroll: true,
      visibleFraction: visibleFraction,
      enabled: enabled,
      child: this,
    );
  }

  Widget animateSection({
    Duration? delay,
    double slideY = 0.08,
    double beginScale = 0.94,
    double stiffness = 180.0,
    double damping = 0.82,
    bool onScroll = true,
    double visibleFraction = 0.08,
    Alignment alignment = Alignment.topCenter,
    bool enabled = true,
  }) {
    return AnymeXSpring(
      delay: delay ?? Duration.zero,
      slideY: slideY,
      beginScale: beginScale,
      stiffness: stiffness,
      damping: damping,
      onScroll: onScroll,
      visibleFraction: visibleFraction,
      alignment: alignment,
      enabled: enabled,
      child: this,
    );
  }

  Widget animateListItem({
    required int index,
    int staggerCount = 4,
    int staggerMs = 35,
    double slideY = 0.06,
    double beginScale = 0.94,
    double stiffness = 250.0,
    double damping = 0.78,
    bool onScroll = true,
    bool enabled = true,
  }) {
    return AnymeXSpring(
      delay: Duration(milliseconds: (index % staggerCount) * staggerMs),
      slideY: slideY,
      beginScale: beginScale,
      stiffness: stiffness,
      damping: damping,
      onScroll: onScroll,
      visibleFraction: 0.08,
      alignment: Alignment.bottomCenter,
      enabled: enabled,
      child: this,
    );
  }

  Widget animateGridItem({
    required int index,
    int columns = 3,
    int staggerMs = 40,
    double beginScale = 0.88,
    double stiffness = 260.0,
    double damping = 0.74,
    bool onScroll = true,
    bool enabled = true,
  }) {
    return AnymeXSpring(
      delay: Duration(milliseconds: (index % columns) * staggerMs),
      slideY: 0.04,
      beginScale: beginScale,
      stiffness: stiffness,
      damping: damping,
      onScroll: onScroll,
      visibleFraction: 0.08,
      enabled: enabled,
      child: this,
    );
  }
}
