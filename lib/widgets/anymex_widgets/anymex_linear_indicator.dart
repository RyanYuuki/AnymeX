import 'package:flutter/material.dart';
import 'package:material3_expressive_loading_indicator/material3_expressive_loading_indicator.dart';

class AnymeXLinearIndicator extends StatelessWidget {
  final double? value;
  final double? minHeight;
  final Color? backgroundColor;
  final Color? color;

  const AnymeXLinearIndicator({
    super.key,
    this.value,
    this.minHeight,
    this.backgroundColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ExpressiveLinearProgressIndicator(
      value: value,
      minHeight: minHeight,
      backgroundColor: backgroundColor,
      color: color,
      waveSpeed: 0.01,
      wavelength: 40,
      borderRadius: BorderRadius.circular(50),
    );
  }
}
