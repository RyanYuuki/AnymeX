import 'package:anymex/utils/dimensions.dart';
import 'package:flutter/material.dart';

class PlatformBuilder extends StatefulWidget {
  final Widget androidBuilder;
  final Widget desktopBuilder;
  const PlatformBuilder(
      {super.key, required this.androidBuilder, required this.desktopBuilder});

  @override
  State<PlatformBuilder> createState() => _PlatformBuilderState();
}

class _PlatformBuilderState extends State<PlatformBuilder> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > maxMobileWidth) {
        return widget.desktopBuilder;
      } else {
        return widget.androidBuilder;
      }
    });
  }
}
