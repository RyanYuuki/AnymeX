import 'dart:math' as math;

import 'package:flutter/material.dart';

const List<String> subtitleOutlineTypes = [
  'Hard Anime',
  'Outline',
  'Bold Outline',
  'Double Outline',
  'Drop Shadow',
  'Soft Shadow',
  'Glow',
  'None',
];

String normalizeSubtitleOutlineType(String outlineType) {
  if (subtitleOutlineTypes.contains(outlineType)) return outlineType;

  switch (outlineType) {
    case 'Shine':
      return 'Glow';
    default:
      return 'Outline';
  }
}

String resolveSubtitleFontFamily(String configuredFont) {
  if (configuredFont == 'Default') return 'Poppins';
  if (configuredFont == 'Anime Ace 3') return 'AnimeAce';
  return configuredFont;
}

Widget buildStyledSubtitleText({
  required String text,
  required Color textColor,
  required double fontSize,
  required String fontFamily,
  required String outlineType,
  required double outlineWidth,
  required Color outlineColor,
  Key? key,
}) {
  final normalizedType = normalizeSubtitleOutlineType(outlineType);
  final width = outlineWidth.clamp(0.0, 8.0);
  final style = TextStyle(
    color: textColor,
    fontSize: fontSize,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 0.15,
    shadows: _buildShadows(
      normalizedType: normalizedType,
      outlineWidth: width,
      outlineColor: outlineColor,
    ),
  );

  return Text(
    text,
    key: key,
    textAlign: TextAlign.center,
    style: style,
  );
}

List<Shadow> _buildShadows({
  required String normalizedType,
  required double outlineWidth,
  required Color outlineColor,
}) {
  switch (normalizedType) {
    case 'None':
      return const [];
    case 'Outline':
      return _roundedStroke(outlineColor, outlineWidth);
    case 'Bold Outline':
      return _roundedStroke(outlineColor, outlineWidth + 1.6);
    case 'Double Outline':
      return [
        ..._roundedStroke(Colors.black, outlineWidth + 2.4),
        ..._roundedStroke(outlineColor, outlineWidth),
      ];
    case 'Hard Anime':
      return [
        ..._roundedStroke(Colors.black, outlineWidth + 2.8),
        ..._roundedStroke(outlineColor, outlineWidth + 0.6),
        Shadow(
          color: Colors.black.withValues(alpha: 0.7),
          offset: const Offset(0, 1.2),
          blurRadius: 1.2,
        ),
      ];
    case 'Drop Shadow':
      return [
        ..._roundedStroke(outlineColor, outlineWidth),
        Shadow(
          color: Colors.black.withValues(alpha: 0.85),
          offset: Offset(outlineWidth + 1, outlineWidth + 1),
          blurRadius: 1.2,
        ),
      ];
    case 'Soft Shadow':
      return [
        ..._roundedStroke(outlineColor.withValues(alpha: 0.65), outlineWidth),
        Shadow(
          color: Colors.black.withValues(alpha: 0.7),
          offset: const Offset(0, 1.4),
          blurRadius: 3.4,
        ),
      ];
    case 'Glow':
      return [
        ..._roundedStroke(outlineColor.withValues(alpha: 0.55), outlineWidth),
        Shadow(
          color: outlineColor.withValues(alpha: 0.9),
          blurRadius: 6.0 + outlineWidth,
        ),
      ];
    default:
      return _roundedStroke(outlineColor, outlineWidth);
  }
}

List<Shadow> _roundedStroke(Color color, double radius) {
  if (radius <= 0) return const [];
  final sampleCount = math.max(16, (radius * 10).round());
  final shadows = <Shadow>[];
  for (int i = 0; i < sampleCount; i++) {
    final angle = (2 * math.pi * i) / sampleCount;
    shadows.add(Shadow(
      color: color,
      offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      blurRadius: 0,
    ));
  }
  return shadows;
}
