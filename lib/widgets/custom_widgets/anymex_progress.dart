import 'package:flutter/material.dart';

class AnymexProgressIndicator extends StatelessWidget {
  final double? value;
  final double? strokeWidth;
  final Color? backgroundColor;

  const AnymexProgressIndicator({
    super.key,
    this.value,
    this.strokeWidth,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      value: value,
      year2023: false,
      strokeWidth: strokeWidth ?? 4,
      backgroundColor: backgroundColor,
    );
  }
}
