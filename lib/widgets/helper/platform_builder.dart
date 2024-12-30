import 'dart:io';
import 'package:anymex/constants/contants.dart';
import 'package:flutter/material.dart';

double getResponsiveSize(context,
    {required double mobileSize, required double dektopSize}) {
  final currentWidth = MediaQuery.of(context).size.width;
  if (currentWidth > maxMobileWidth) {
    return dektopSize;
  } else {
    return mobileSize;
  }
}

dynamic getResponsiveValue(context,
    {required dynamic mobileValue, required dynamic desktopValue}) {
  final currentWidth = MediaQuery.of(context).size.width;
  if (currentWidth > maxMobileWidth) {
    return desktopValue;
  } else {
    return mobileValue;
  }
}

int getResponsiveCrossAxisCount(
  BuildContext context, {
  int baseColumns = 2,
  int maxColumns = 6,
  int mobileBreakpoint = 600,
  int tabletBreakpoint = 1200,
  int mobileItemWidth = 200,
  int tabletItemWidth = 200,
  int desktopItemWidth = 200,
}) {
  final currentWidth = MediaQuery.of(context).size.width;
  const mobileBreakpoint = 600;
  const tabletBreakpoint = 1200;

  int crossAxisCount;
  if (currentWidth < mobileBreakpoint) {
    crossAxisCount = (currentWidth / mobileItemWidth).floor();
  } else if (currentWidth < tabletBreakpoint) {
    crossAxisCount = (currentWidth / tabletItemWidth).floor();
  } else {
    crossAxisCount = (currentWidth / desktopItemWidth).floor();
  }

  return crossAxisCount.clamp(baseColumns, maxColumns);
}

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
