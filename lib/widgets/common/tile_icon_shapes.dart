import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

M3EShapeKind? getTileIconShapeKind(int index) {
  if (index <= 0 || index > M3EShapeKind.values.length) {
    return null;
  }
  return M3EShapeKind.values[index - 1];
}

String getTileIconShapeName(int index) {
  if (index <= 0 || index > M3EShapeKind.values.length) {
    return 'Default';
  }
  final kind = M3EShapeKind.values[index - 1];
  return switch (kind) {
    M3EShapeKind.circle => 'Circle',
    M3EShapeKind.square => 'Rounded Square',
    M3EShapeKind.slanted => 'Slanted Square',
    M3EShapeKind.arch => 'Arch',
    M3EShapeKind.semiCircle => 'Semi Circle',
    M3EShapeKind.oval => 'Oval',
    M3EShapeKind.pill => 'Pill',
    M3EShapeKind.triangle => 'Triangle',
    M3EShapeKind.arrow => 'Arrow',
    M3EShapeKind.fan => 'Fan',
    M3EShapeKind.diamond => 'Diamond',
    M3EShapeKind.clamShell => 'Clam Shell',
    M3EShapeKind.pentagon => 'Pentagon',
    M3EShapeKind.gem => 'Gem',
    M3EShapeKind.sunny => 'Sunny',
    M3EShapeKind.verySunny => 'Very Sunny',
    M3EShapeKind.cookie4Sided => 'Cookie (4-Sided)',
    M3EShapeKind.cookie6Sided => 'Cookie (6-Sided)',
    M3EShapeKind.cookie7Sided => 'Cookie (7-Sided)',
    M3EShapeKind.cookie9Sided => 'Cookie (9-Sided)',
    M3EShapeKind.cookie12Sided => 'Cookie (12-Sided)',
    M3EShapeKind.clover4Leaf => 'Clover (4-Leaf)',
    M3EShapeKind.clover8Leaf => 'Clover (8-Leaf)',
    M3EShapeKind.burst => 'Burst',
    M3EShapeKind.softBurst => 'Soft Burst',
    M3EShapeKind.boom => 'Boom',
    M3EShapeKind.softBoom => 'Soft Boom',
    M3EShapeKind.flower => 'Flower',
    M3EShapeKind.puffy => 'Puffy',
    M3EShapeKind.puffyDiamond => 'Puffy Diamond',
    M3EShapeKind.ghostish => 'Ghostish',
    M3EShapeKind.pixelCircle => 'Pixel Circle',
    M3EShapeKind.pixelTriangle => 'Pixel Triangle',
    M3EShapeKind.bun => 'Bun',
    M3EShapeKind.heart => 'Heart',
  };
}

String getTileIconShapeDescription(int index) {
  if (index <= 0 || index > M3EShapeKind.values.length) {
    return 'Default tile icon shape (Circle for M3 Expressive, Rounded Square for Classic)';
  }
  return 'Material 3 Expressive ${getTileIconShapeName(index).toLowerCase()} prefix container';
}

IconData getTileIconShapeIcon(int index) {
  if (index <= 0 || index > M3EShapeKind.values.length) {
    return Icons.interests_rounded;
  }
  final kind = M3EShapeKind.values[index - 1];
  return switch (kind) {
    M3EShapeKind.circle => Icons.circle_outlined,
    M3EShapeKind.square => Icons.crop_square_rounded,
    M3EShapeKind.slanted => Icons.crop_rotate_rounded,
    M3EShapeKind.arch => Icons.account_balance_rounded,
    M3EShapeKind.semiCircle => Icons.pie_chart_outline_rounded,
    M3EShapeKind.oval => Icons.egg_outlined,
    M3EShapeKind.pill => Icons.medication_liquid_rounded,
    M3EShapeKind.triangle => Icons.change_history_rounded,
    M3EShapeKind.arrow => Icons.arrow_forward_rounded,
    M3EShapeKind.fan => Icons.mode_fan_off_rounded,
    M3EShapeKind.diamond => Icons.diamond_outlined,
    M3EShapeKind.clamShell => Icons.beach_access_rounded,
    M3EShapeKind.pentagon => Icons.pentagon_outlined,
    M3EShapeKind.gem => Icons.diamond_rounded,
    M3EShapeKind.sunny => Icons.wb_sunny_rounded,
    M3EShapeKind.verySunny => Icons.wb_sunny_outlined,
    M3EShapeKind.cookie4Sided => Icons.cookie_rounded,
    M3EShapeKind.cookie6Sided => Icons.cookie_outlined,
    M3EShapeKind.cookie7Sided => Icons.cookie_rounded,
    M3EShapeKind.cookie9Sided => Icons.cookie_outlined,
    M3EShapeKind.cookie12Sided => Icons.cookie_rounded,
    M3EShapeKind.clover4Leaf => Icons.yard_outlined,
    M3EShapeKind.clover8Leaf => Icons.local_florist_rounded,
    M3EShapeKind.burst => Icons.flare_rounded,
    M3EShapeKind.softBurst => Icons.auto_awesome_rounded,
    M3EShapeKind.boom => Icons.bolt_rounded,
    M3EShapeKind.softBoom => Icons.electric_bolt_rounded,
    M3EShapeKind.flower => Icons.local_florist_outlined,
    M3EShapeKind.puffy => Icons.cloud_outlined,
    M3EShapeKind.puffyDiamond => Icons.diamond_rounded,
    M3EShapeKind.ghostish => Icons.sentiment_very_satisfied_rounded,
    M3EShapeKind.pixelCircle => Icons.grain_rounded,
    M3EShapeKind.pixelTriangle => Icons.change_history_outlined,
    M3EShapeKind.bun => Icons.lunch_dining_rounded,
    M3EShapeKind.heart => Icons.favorite_rounded,
  };
}

const int totalTileIconShapes = 36;
