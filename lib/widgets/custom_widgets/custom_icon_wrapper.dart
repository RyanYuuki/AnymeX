import 'package:flutter/material.dart';

class AnymexIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? size;
  const AnymexIcon(this.icon, {super.key, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primary.withOpacity(0.2),
            theme.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: size ?? 20,
        color: color,
      ),
    );
  }
}

class AnymexIconWrapper extends StatelessWidget {
  final Widget child;
  const AnymexIconWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primary.withOpacity(0.2),
              theme.primary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: child);
  }
}
