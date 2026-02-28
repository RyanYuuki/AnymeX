import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:anymex/screens/manga/controller/reader_controller.dart';

/// Draws a brightness-dimming layer and/or a color-tint canvas on top of the
/// reader content, matching Komikku's `ReaderContentOverlay`.
class ReaderContentOverlay extends StatelessWidget {
  const ReaderContentOverlay({super.key, required this.controller});

  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final brightness = controller.customBrightnessValue.value;
      final colorEnabled = controller.colorFilterEnabled.value;
      final colorValue = controller.colorFilterValue.value;
      final blendModeIndex = controller.colorFilterMode.value;

      return Stack(
        children: [
          // Brightness dimmer (negative values only → black overlay)
          if (brightness < 0)
            IgnorePointer(
              child: Opacity(
                opacity: (brightness.abs() / 100.0).clamp(0.0, 1.0),
                child: Container(color: Colors.black),
              ),
            ),

          // Color tint overlay
          if (colorEnabled)
            IgnorePointer(
              child: CustomPaint(
                painter: _ColorOverlayPainter(
                  color: Color(colorValue),
                  blendMode: _blendModeFromIndex(blendModeIndex),
                ),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      );
    });
  }

  static BlendMode _blendModeFromIndex(int index) {
    const modes = [
      BlendMode.srcOver, 
      BlendMode.multiply,
      BlendMode.screen,
      BlendMode.overlay,
      BlendMode.darken,
      BlendMode.lighten,
      BlendMode.colorDodge,
      BlendMode.colorBurn,
      BlendMode.hardLight,
      BlendMode.softLight,
      BlendMode.difference,
      BlendMode.exclusion,
      BlendMode.hue,
      BlendMode.saturation,
      BlendMode.color,
      BlendMode.luminosity,
    ];
    if (index >= 0 && index < modes.length) return modes[index];
    return BlendMode.srcOver;
  }
}

class _ColorOverlayPainter extends CustomPainter {
  const _ColorOverlayPainter({required this.color, required this.blendMode});

  final Color color;
  final BlendMode blendMode;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = color
        ..blendMode = blendMode,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ColorOverlayPainter old) =>
      old.color != color || old.blendMode != blendMode;
}
