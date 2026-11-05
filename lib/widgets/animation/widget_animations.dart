import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/animation/slide_scale.dart';

bool get _animationsDisabled {
  if (Get.isRegistered<Settings>()) {
    final s = Get.find<Settings>();
    return !s.enableAnimation || s.animationDuration <= 0;
  }
  return false;
}

double get _animSpeedMultiplier {
  if (Get.isRegistered<Settings>()) {
    final ms = Get.find<Settings>().animationDuration;
    if (ms <= 0) return 0.0;
    return (ms / 200.0).clamp(0.2, 3.0);
  }
  return 1.0;
}

Duration _scaleDuration(int baseMs) {
  final scaled = (baseMs * _animSpeedMultiplier).round();
  return Duration(milliseconds: scaled < 1 ? 1 : scaled);
}

extension AnymeXWidgetAnimations on Widget {
  Widget animateCarouselCard({
    bool target = true,
    int index = 0,
    Duration? delay,
    int duration = 240,
    Offset slideBegin = const Offset(0.35, 0.0),
    double scaleBegin = 0.88,
    Curve curve = Curves.easeOutCubic,
    bool enabled = true,
  }) {
    if (!enabled || _animationsDisabled) return this;
    final staggeredDelay =
        delay ?? Duration(milliseconds: (index.clamp(0, 8)) * 30);
    return animate(target: target ? 1 : 0)
        .fadeIn(
          delay: staggeredDelay,
          duration: _scaleDuration(duration),
          curve: Curves.easeOut,
        )
        .slide(
          begin: slideBegin,
          end: Offset.zero,
          delay: staggeredDelay,
          duration: _scaleDuration(duration),
          curve: curve,
        )
        .scale(
          begin: Offset(scaleBegin, scaleBegin),
          end: const Offset(1.0, 1.0),
          delay: staggeredDelay,
          duration: _scaleDuration(duration),
          curve: curve,
        );
  }

  Widget animatePop({
    int index = 0,
    Duration? delay,
    double beginScale = 0.0,
    double slideX = 1.0,
    double slideY = 0.0,
    double stiffness = 320.0,
    double damping = 0.6,
    bool enabled = true,
    bool isGrid = false,
  }) {
    if (!enabled || _animationsDisabled) return this;
    final staggeredDelay = delay ??
        (index < 10
            ? Duration(milliseconds: (index % (isGrid ? 3 : 5)) * 25)
            : null);
    return SlideAndScaleAnimation(
      initialOffset: Offset(slideX, slideY),
      initialScale: beginScale,
      finalScale: 1.0,
      duration: _scaleDuration(200),
      delay: staggeredDelay,
      child: this,
    );
  }

  Widget animateTileEntrance({
    required int index,
    bool isGrid = false,
    double slideX = 1.0,
    double slideY = 0.0,
    double beginScale = 0.0,
    double stiffness = 320.0,
    double damping = 0.6,
  }) {
    return animatePop(
      index: index,
      isGrid: isGrid,
      slideX: slideX,
      slideY: slideY,
      beginScale: beginScale,
    );
  }

  Widget animateSpring({
    int index = 0,
    Duration? delay,
    double slideY = 0.08,
    double slideX = 0.0,
    double beginScale = 0.92,
    double stiffness = 220.0,
    double damping = 0.78,
    bool fade = true,
    bool enabled = true,
  }) {
    if (!enabled || _animationsDisabled) return this;
    final staggeredDelay =
        delay ?? Duration(milliseconds: index.clamp(0, 6) * 35);
    var a = animate().slide(
      begin: Offset(slideX, slideY),
      end: Offset.zero,
      delay: staggeredDelay,
      duration: _scaleDuration(260),
      curve: Curves.easeOutCubic,
    );
    if (beginScale != 1.0) {
      a = a.scale(
        begin: Offset(beginScale, beginScale),
        end: const Offset(1.0, 1.0),
        delay: staggeredDelay,
        duration: _scaleDuration(260),
        curve: Curves.easeOutCubic,
      );
    }
    if (fade) {
      a = a.fadeIn(
        delay: staggeredDelay,
        duration: _scaleDuration(240),
        curve: Curves.easeOut,
      );
    }
    return a;
  }

  Widget animateFadeUp({
    int index = 0,
    Duration? delay,
    double slideY = 0.08,
    double stiffness = 200.0,
    double damping = 0.9,
    bool enabled = true,
  }) {
    if (!enabled || _animationsDisabled) return this;
    final staggeredDelay =
        delay ?? Duration(milliseconds: index.clamp(0, 6) * 30);
    return animate()
        .fadeIn(
          delay: staggeredDelay,
          duration: _scaleDuration(240),
          curve: Curves.easeOut,
        )
        .slideY(
          begin: slideY,
          end: 0,
          delay: staggeredDelay,
          duration: _scaleDuration(240),
          curve: Curves.easeOutCubic,
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
    if (!enabled || _animationsDisabled) return this;
    final staggeredDelay =
        delay ?? Duration(milliseconds: index.clamp(0, 6) * 30);
    return animate()
        .fadeIn(
          delay: staggeredDelay,
          duration: _scaleDuration(240),
          curve: Curves.easeOut,
        )
        .slideY(
          begin: -slideY,
          end: 0,
          delay: staggeredDelay,
          duration: _scaleDuration(240),
          curve: Curves.easeOutCubic,
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
    if (!enabled || _animationsDisabled) return this;
    final staggeredDelay =
        delay ?? Duration(milliseconds: index.clamp(0, 6) * 30);
    return animate()
        .fadeIn(
          delay: staggeredDelay,
          duration: _scaleDuration(240),
          curve: Curves.easeOut,
        )
        .slideX(
          begin: slideX,
          end: 0,
          delay: staggeredDelay,
          duration: _scaleDuration(240),
          curve: Curves.easeOutCubic,
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
    if (!enabled || _animationsDisabled) return this;
    final staggeredDelay =
        delay ?? Duration(milliseconds: index.clamp(0, 6) * 30);
    return animate()
        .fadeIn(
          delay: staggeredDelay,
          duration: _scaleDuration(240),
          curve: Curves.easeOut,
        )
        .slideX(
          begin: -slideX,
          end: 0,
          delay: staggeredDelay,
          duration: _scaleDuration(240),
          curve: Curves.easeOutCubic,
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
    if (!enabled || _animationsDisabled) return this;
    final staggeredDelay =
        delay ?? Duration(milliseconds: index.clamp(0, 6) * 30);
    return animate()
        .fadeIn(
          delay: staggeredDelay,
          duration: _scaleDuration(240),
          curve: Curves.easeOut,
        )
        .scale(
          begin: Offset(beginScale, beginScale),
          end: const Offset(1.0, 1.0),
          delay: staggeredDelay,
          duration: _scaleDuration(260),
          curve: Curves.easeOutCubic,
        );
  }

  Widget animateSection({
    Duration? delay,
    double slideY = 0.06,
    double beginScale = 0.95,
    double stiffness = 180.0,
    double damping = 0.82,
    bool onScroll = true,
    double visibleFraction = 0.08,
    Alignment alignment = Alignment.topCenter,
    bool enabled = true,
  }) {
    if (!enabled || _animationsDisabled) return this;
    return animate()
        .fadeIn(
          delay: delay ?? Duration.zero,
          duration: _scaleDuration(250),
          curve: Curves.easeOut,
        )
        .slideY(
          begin: slideY,
          end: 0,
          delay: delay ?? Duration.zero,
          duration: _scaleDuration(280),
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: Offset(beginScale, beginScale),
          end: const Offset(1.0, 1.0),
          alignment: alignment,
          delay: delay ?? Duration.zero,
          duration: _scaleDuration(280),
          curve: Curves.easeOutCubic,
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
    return animateSection(
      delay: delay ?? Duration(milliseconds: index.clamp(0, 6) * 35),
      slideY: slideY,
      beginScale: beginScale,
      enabled: enabled,
    );
  }

  Widget animateListItem({
    required int index,
    int staggerCount = 4,
    int staggerMs = 30,
    double slideY = 0.06,
    double beginScale = 0.94,
    double stiffness = 250.0,
    double damping = 0.78,
    bool onScroll = true,
    bool enabled = true,
  }) {
    if (!enabled || _animationsDisabled) return this;
    final staggeredDelay =
        Duration(milliseconds: (index % staggerCount) * staggerMs);
    return animate()
        .fadeIn(
          delay: staggeredDelay,
          duration: _scaleDuration(220),
          curve: Curves.easeOut,
        )
        .slideY(
          begin: slideY,
          end: 0,
          delay: staggeredDelay,
          duration: _scaleDuration(250),
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: Offset(beginScale, beginScale),
          end: const Offset(1.0, 1.0),
          alignment: Alignment.bottomCenter,
          delay: staggeredDelay,
          duration: _scaleDuration(250),
          curve: Curves.easeOutCubic,
        );
  }

  Widget animateGridItem({
    required int index,
    int columns = 3,
    int staggerMs = 35,
    double beginScale = 0.90,
    double stiffness = 260.0,
    double damping = 0.74,
    bool onScroll = true,
    bool enabled = true,
  }) {
    if (!enabled || _animationsDisabled) return this;
    final staggeredDelay =
        Duration(milliseconds: (index % columns) * staggerMs);
    return animate()
        .fadeIn(
          delay: staggeredDelay,
          duration: _scaleDuration(220),
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.05,
          end: 0,
          delay: staggeredDelay,
          duration: _scaleDuration(250),
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: Offset(beginScale, beginScale),
          end: const Offset(1.0, 1.0),
          delay: staggeredDelay,
          duration: _scaleDuration(250),
          curve: Curves.easeOutCubic,
        );
  }
}
