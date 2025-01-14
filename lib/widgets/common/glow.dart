import 'package:anymex/controllers/settings/methods.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Glow extends StatelessWidget {
  final Widget child;
  final Alignment begin;
  final Alignment end;

  const Glow({
    super.key,
    required this.child,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    if (theme.brightness == Brightness.dark) {
      return Container(
        color: theme.surface,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.surface.withOpacity(0.3),
                theme.primary.withOpacity(0.4)
              ],
              begin: begin,
              end: end,
            ),
          ),
          child: child,
        ),
      );
    } else {
      return Container(
        color: theme.surface,
        child: child,
      );
    }
  }
}

BoxShadow glowingShadow(BuildContext context) {
  return BoxShadow(
    color: Theme.of(context).colorScheme.primary.withOpacity(
        Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.6),
    blurRadius: 58.0.multiplyBlur(),
    spreadRadius: 10.0.multiplyGlow(),
    offset: const Offset(-2.0, 0),
  );
}

BoxShadow lightGlowingShadow(BuildContext context) {
  return BoxShadow(
    color: Theme.of(context).colorScheme.primary.withOpacity(
        Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.6),
    blurRadius: 59.0.multiplyBlur(),
    spreadRadius: 1.0.multiplyGlow(),
    offset: const Offset(-1.0, 0),
  );
}

Shimmer placeHolderWidget(BuildContext context) {
  return Shimmer.fromColors(
    baseColor: Theme.of(context).colorScheme.surfaceContainer,
    highlightColor: Theme.of(context).colorScheme.primary,
    child: Container(
      width: 80,
      height: 80,
      color: Theme.of(context).colorScheme.secondaryContainer,
    ),
  );
}
