import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnymexPageTransition extends PageTransitionsBuilder {
  /// Constructs a page transition animation that matches the transition used on
  /// Android U.
  const AnymexPageTransition({this.backgroundColor});

  /// The background color during transition between two routes.
  ///
  /// When a new page fades in and the old page fades out, this background color
  /// helps avoid a black background between two page.
  ///
  /// Defaults to [ColorScheme.surface]
  final Color? backgroundColor;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 800);

  @override
  DelegatedTransitionBuilder? get delegatedTransition => (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        bool allowSnapshotting,
        Widget? child,
      ) =>
          _delegatedTransition(context, animation, backgroundColor, child);

  // Used by all of the sliding transition animations.
  static const Curve _transitionCurve = Curves.easeInOutCubicEmphasized;

  // The previous page slides from right to left as the current page appears.
  static final Animatable<Offset> _secondaryBackwardTranslationTween =
      Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-0.25, 0.0),
  ).chain(CurveTween(curve: _transitionCurve));

  // The previous page slides from left to right as the current page disappears.
  static final Animatable<Offset> _secondaryForwardTranslationTween =
      Tween<Offset>(
    begin: const Offset(-0.25, 0.0),
    end: Offset.zero,
  ).chain(CurveTween(curve: _transitionCurve));

  // The fade in transition when the new page appears.
  static final Animatable<double> _fadeInTransition = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).chain(CurveTween(curve: const Interval(0.0, 0.75)));

  // The fade out transition of the old page when the new page appears.
  static final Animatable<double> _fadeOutTransition = Tween<double>(
    begin: 1.0,
    end: 0.0,
  ).chain(CurveTween(curve: const Interval(0.0, 0.25)));

  static Widget _delegatedTransition(
    BuildContext context,
    Animation<double> secondaryAnimation,
    Color? backgroundColor,
    Widget? child,
  ) =>
      DualTransitionBuilder(
        animation: ReverseAnimation(secondaryAnimation),
        forwardBuilder:
            (BuildContext context, Animation<double> animation, Widget? child) {
          return ColoredBox(
            color: animation.isAnimating
                ? backgroundColor ?? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            child: FadeTransition(
              opacity: _fadeInTransition.animate(animation),
              child: SlideTransition(
                position: _secondaryForwardTranslationTween.animate(animation),
                child: child,
              ),
            ),
          );
        },
        reverseBuilder:
            (BuildContext context, Animation<double> animation, Widget? child) {
          return ColoredBox(
            color: animation.isAnimating
                ? backgroundColor ?? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            child: FadeTransition(
              opacity: _fadeOutTransition.animate(animation),
              child: SlideTransition(
                position: _secondaryBackwardTranslationTween.animate(animation),
                child: child,
              ),
            ),
          );
        },
        child: child,
      );

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeForwardsPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      backgroundColor: backgroundColor,
      child: child,
    );
  }
}

typedef DelegatedTransitionBuilder = Widget? Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  bool allowSnapshotting,
  Widget? child,
);

class FadeForwardsPageTransition extends StatelessWidget {
  const FadeForwardsPageTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    this.backgroundColor,
    this.child,
  });

  final Animation<double> animation;

  final Animation<double> secondaryAnimation;

  final Color? backgroundColor;

  final Widget? child;

  // The new page slides in from right to left.
  static final Animatable<Offset> _forwardTranslationTween = Tween<Offset>(
    begin: const Offset(0.25, 0.0),
    end: Offset.zero,
  ).chain(CurveTween(curve: AnymexPageTransition._transitionCurve));

  // The old page slides back from left to right.
  static final Animatable<Offset> _backwardTranslationTween = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0.25, 0.0),
  ).chain(CurveTween(curve: AnymexPageTransition._transitionCurve));

  @override
  Widget build(BuildContext context) {
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder:
          (BuildContext context, Animation<double> animation, Widget? child) {
        return FadeTransition(
          opacity: AnymexPageTransition._fadeInTransition.animate(animation),
          child: SlideTransition(
            position: _forwardTranslationTween.animate(animation),
            child: child,
          ),
        );
      },
      reverseBuilder:
          (BuildContext context, Animation<double> animation, Widget? child) {
        return FadeTransition(
          opacity: AnymexPageTransition._fadeOutTransition.animate(animation),
          child: SlideTransition(
            position: _backwardTranslationTween.animate(animation),
            child: child,
          ),
        );
      },
      child: AnymexPageTransition._delegatedTransition(
        context,
        secondaryAnimation,
        backgroundColor,
        child,
      ),
    );
  }
}

class FadeForwardsCustomTransition extends CustomTransition {
  FadeForwardsCustomTransition({this.backgroundColor});

  final Color? backgroundColor;

  static const Curve _transitionCurve = Curves.easeInOutCubicEmphasized;

  // The new page slides in from right to left
  static final Animatable<Offset> _forwardTranslationTween = Tween<Offset>(
    begin: const Offset(0.25, 0.0),
    end: Offset.zero,
  ).chain(CurveTween(curve: _transitionCurve));

  // The old page slides back from left to right
  static final Animatable<Offset> _backwardTranslationTween = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0.25, 0.0),
  ).chain(CurveTween(curve: _transitionCurve));

  // The previous page slides from right to left as current page appears
  static final Animatable<Offset> _secondaryBackwardTranslationTween =
      Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-0.25, 0.0),
  ).chain(CurveTween(curve: _transitionCurve));

  // The previous page slides from left to right as current page disappears
  static final Animatable<Offset> _secondaryForwardTranslationTween =
      Tween<Offset>(
    begin: const Offset(-0.25, 0.0),
    end: Offset.zero,
  ).chain(CurveTween(curve: _transitionCurve));

  // Fade in transition for new page
  static final Animatable<double> _fadeInTransition = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).chain(CurveTween(curve: const Interval(0.0, 0.75)));

  // Fade out transition for old page
  static final Animatable<double> _fadeOutTransition = Tween<double>(
    begin: 1.0,
    end: 0.0,
  ).chain(CurveTween(curve: const Interval(0.0, 0.25)));

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder:
          (BuildContext context, Animation<double> animation, Widget? child) {
        return FadeTransition(
          opacity: _fadeInTransition.animate(animation),
          child: SlideTransition(
            position: _forwardTranslationTween.animate(animation),
            child: child,
          ),
        );
      },
      reverseBuilder:
          (BuildContext context, Animation<double> animation, Widget? child) {
        return FadeTransition(
          opacity: _fadeOutTransition.animate(animation),
          child: SlideTransition(
            position: _backwardTranslationTween.animate(animation),
            child: child,
          ),
        );
      },
      child: DualTransitionBuilder(
        animation: ReverseAnimation(secondaryAnimation),
        forwardBuilder:
            (BuildContext context, Animation<double> animation, Widget? child) {
          return ColoredBox(
            color: animation.isAnimating
                ? backgroundColor ?? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            child: FadeTransition(
              opacity: _fadeInTransition.animate(animation),
              child: SlideTransition(
                position: _secondaryForwardTranslationTween.animate(animation),
                child: KeyedSubtree(
                  key: const ValueKey<String>('forward_page'),
                  child: child!,
                ),
              ),
            ),
          );
        },
        reverseBuilder:
            (BuildContext context, Animation<double> animation, Widget? child) {
          return ColoredBox(
            color: animation.isAnimating
                ? backgroundColor ?? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            child: FadeTransition(
              opacity: _fadeOutTransition.animate(animation),
              child: SlideTransition(
                position: _secondaryBackwardTranslationTween.animate(animation),
                child: KeyedSubtree(
                  key: const ValueKey<String>('reverse_page'),
                  child: child!,
                ),
              ),
            ),
          );
        },
        child: child,
      ),
    );
  }
}
