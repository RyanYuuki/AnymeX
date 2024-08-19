import 'package:flutter/material.dart';

class IconWithName extends StatelessWidget {
  final IconData icon;
  final String name;
  final bool isVertical;
  final Color color;
  final double size;
  final Color backgroundColor;
  final BorderRadius? borderRadius;

  const IconWithName({super.key, 
    required this.icon,
    required this.name,
    this.isVertical = true,
    this.color = Colors.black,
    this.size = 16.0,
    this.backgroundColor = Colors.white,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      height: 20,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: isVertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: size, color: color),
                const SizedBox(height: 8.0),
                Text(name, style: const TextStyle(fontSize: 14.0)),
              ],
            )
          : Center(
              child: Row(
                children: [
                  Icon(icon, size: size, color: color),
                  const SizedBox(width: 2.0),
                  Text(name,
                      style: const TextStyle(
                          fontSize: 12.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
    );
  }
}
