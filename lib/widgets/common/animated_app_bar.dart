import 'package:flutter/material.dart';

class AnimatedAppBar extends StatelessWidget {
  final bool isVisible;
  final Duration animationDuration;
  final Curve animationCurve;
  final Widget content;
  final Color? backgroundColor;
  final double topPadding;
  final double bottomPadding;
  final double offset;

  const AnimatedAppBar.animatedAppBar({
    super.key,
    required this.isVisible,
    this.animationDuration = const Duration(milliseconds: 450),
    this.animationCurve = Curves.easeInOut,
    required this.content,
    this.backgroundColor,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.offset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final appBarContentHeight = kToolbarHeight + topPadding + bottomPadding;

    return AnimatedPositioned(
      duration: animationDuration,
      curve: animationCurve,
      top: isVisible ? 0 : -(appBarContentHeight + statusBarHeight + offset),
      left: 0,
      right: 0,
      child: Container(
        color: backgroundColor ??
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface.withOpacity(0.80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: statusBarHeight),
            if (topPadding > 0) SizedBox(height: topPadding),
            SizedBox(
              height: kToolbarHeight,
              child: content,
            ),
            if (bottomPadding > 0) SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }
}
