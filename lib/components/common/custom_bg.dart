import 'package:flutter/material.dart';

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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.surface.withOpacity(0.3),
              theme.primary.withOpacity(0.3)
            ],
            begin: begin,
            end: end,
          ),
        ),
        child: child,
      );
    } else {
      return Container(
        color: theme.surface,
        child: child,
      );
    }
  }
}
