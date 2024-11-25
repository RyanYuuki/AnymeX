import 'package:flutter/material.dart';

class iconWithName extends StatelessWidget {
  final IconData icon;
  final String name;
  final bool isVertical;
  final Color color;
  final double size;
  final Color backgroundColor;
  final BorderRadius? borderRadius;
  final Color TextColor;
  final double fontSize;
  final bool isGapped;
  const iconWithName({
    super.key,
    required this.icon,
    required this.name,
    this.isVertical = true,
    this.color = Colors.black,
    this.size = 16.0,
    this.fontSize = 12.0,
    this.backgroundColor = Colors.white,
    this.borderRadius,
    this.TextColor = Colors.black,
    this.isGapped = true,
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  SizedBox(width: isGapped ? 2.0 : 0.0),
                  Text(name,
                      style: TextStyle(
                          fontSize: fontSize,
                          color: TextColor,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
    );
  }
}
