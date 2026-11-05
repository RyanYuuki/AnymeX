import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/settings/settings.dart';

class SlideAndScaleAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration? delay;
  final double initialScale;
  final double finalScale;
  final Offset initialOffset;
  final Offset finalOffset;
  final Curve curve;

  const SlideAndScaleAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.delay,
    this.initialScale = 0.0,
    this.finalScale = 1.0,
    this.initialOffset = const Offset(1.0, 0.0),
    this.finalOffset = const Offset(0.0, 0.0),
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<Settings>()) {
      final s = Get.find<Settings>();
      if (!s.enableAnimation || s.animationDuration <= 0) {
        return child;
      }
    }

    return child
        .animate(delay: delay)
        .scale(
          begin: Offset(initialScale, initialScale),
          end: Offset(finalScale, finalScale),
          alignment: Alignment.center,
          duration: duration,
          curve: curve,
        )
        .slide(
          begin: initialOffset,
          end: finalOffset,
          duration: duration,
          curve: curve,
        );
  }
}
