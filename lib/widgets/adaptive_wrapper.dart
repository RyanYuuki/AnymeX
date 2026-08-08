import 'dart:io' show Platform;
import 'package:flutter/material.dart';

class MyAdaptiveWrapper extends StatelessWidget {
  final Widget child;

  const MyAdaptiveWrapper({super.key, required this.child});

  bool _isAndroidTV(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dpi = MediaQuery.of(context).devicePixelRatio;
    return Platform.isAndroid && size.width > 1000 && dpi < 2.0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mq = MediaQuery.of(context);
        final isTV = _isAndroidTV(context);

        return MediaQuery(
          data: mq.copyWith(
            textScaler: (isTV ? const TextScaler.linear(0.7) : mq.textScaler),
            devicePixelRatio: isTV ? 2.5 : mq.devicePixelRatio,
          ),
          child: child,
        );
      },
    );
  }
}
