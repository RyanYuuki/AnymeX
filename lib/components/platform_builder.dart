import 'dart:io';

import 'package:anymex/utils/dimensions.dart';
import 'package:flutter/material.dart';

class PlatformBuilder extends StatefulWidget {
  final Widget androidBuilder;
  final Widget desktopBuilder;
  final bool strictMode;
  const PlatformBuilder(
      {super.key,
      required this.androidBuilder,
      required this.desktopBuilder,
      this.strictMode = false});

  @override
  State<PlatformBuilder> createState() => _PlatformBuilderState();
}

class _PlatformBuilderState extends State<PlatformBuilder> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (widget.strictMode) {
        if (!Platform.isAndroid && !Platform.isIOS) {
          return widget.desktopBuilder;
        } else {
          return widget.androidBuilder;
        }
      } else {
        if (constraints.maxWidth > maxMobileWidth) {
          return widget.desktopBuilder;
        } else {
          return widget.androidBuilder;
        }
      }
    });
  }
}
