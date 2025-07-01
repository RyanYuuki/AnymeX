import 'package:flutter/material.dart';
import 'dart:ui';

class AnimatedAppBar extends StatelessWidget {
  final bool isVisible;
  final Duration animationDuration;
  final Curve animationCurve;
  final Widget content;
  final double? height;
  final Color? backgroundColor;
  final double topPadding;
  final double bottomPadding;
  final double offset;
  final bool isAtTop; // New parameter to control transparency/blur
  final double blurSigma; // Blur intensity
  final double backgroundOpacity; // Background opacity when not at top

  const AnimatedAppBar({
    super.key,
    this.height,
    required this.isVisible,
    this.animationDuration = const Duration(milliseconds: 450),
    this.animationCurve = Curves.easeInOut,
    required this.content,
    this.backgroundColor,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.offset = 0,
    this.isAtTop = true,
    this.blurSigma = 10.0,
    this.backgroundOpacity = 0.8,
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
      child: AnimatedContainer(
        duration: animationDuration,
        curve: animationCurve,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isAtTop ? 0 : blurSigma,
              sigmaY: isAtTop ? 0 : blurSigma,
            ),
            child: Container(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: statusBarHeight),
                  if (topPadding > 0) SizedBox(height: topPadding),
                  SizedBox(
                    height: height ?? kToolbarHeight,
                    child: content,
                  ),
                  if (bottomPadding > 0) SizedBox(height: bottomPadding),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
