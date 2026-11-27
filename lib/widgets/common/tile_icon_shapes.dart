import 'package:anymex/l10n/l10n_extension.dart';
import 'package:get/get.dart';
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
    M3EShapeKind.circle => Get.context!.l10n.shapeCircle,
    M3EShapeKind.square => Get.context!.l10n.shapeRoundedSquare,
    M3EShapeKind.slanted => Get.context!.l10n.shapeSlantedSquare,
    M3EShapeKind.arch => Get.context!.l10n.shapeArch,
    M3EShapeKind.semiCircle => Get.context!.l10n.shapeSemiCircle,
    M3EShapeKind.oval => Get.context!.l10n.shapeOval,
    M3EShapeKind.pill => Get.context!.l10n.shapePill,
    M3EShapeKind.triangle => Get.context!.l10n.shapeTriangle,
    M3EShapeKind.arrow => Get.context!.l10n.shapeArrow,
    M3EShapeKind.fan => Get.context!.l10n.shapeFan,
    M3EShapeKind.diamond => Get.context!.l10n.shapeDiamond,
    M3EShapeKind.clamShell => Get.context!.l10n.shapeClamShell,
    M3EShapeKind.pentagon => Get.context!.l10n.shapePentagon,
    M3EShapeKind.gem => Get.context!.l10n.shapeGem,
    M3EShapeKind.sunny => Get.context!.l10n.shapeSunny,
    M3EShapeKind.verySunny => Get.context!.l10n.shapeVerySunny,
    M3EShapeKind.cookie4Sided => Get.context!.l10n.shapeCookie4,
    M3EShapeKind.cookie6Sided => Get.context!.l10n.shapeCookie6,
    M3EShapeKind.cookie7Sided => Get.context!.l10n.shapeCookie7,
    M3EShapeKind.cookie9Sided => Get.context!.l10n.shapeCookie9,
    M3EShapeKind.cookie12Sided => Get.context!.l10n.shapeCookie12,
    M3EShapeKind.clover4Leaf => Get.context!.l10n.shapeClover4,
    M3EShapeKind.clover8Leaf => Get.context!.l10n.shapeClover8,
    M3EShapeKind.burst => Get.context!.l10n.shapeBurst,
    M3EShapeKind.softBurst => Get.context!.l10n.shapeSoftBurst,
    M3EShapeKind.boom => Get.context!.l10n.shapeBoom,
    M3EShapeKind.softBoom => Get.context!.l10n.shapeSoftBoom,
    M3EShapeKind.flower => Get.context!.l10n.shapeFlower,
    M3EShapeKind.puffy => Get.context!.l10n.shapePuffy,
    M3EShapeKind.puffyDiamond => Get.context!.l10n.shapePuffyDiamond,
    M3EShapeKind.ghostish => Get.context!.l10n.shapeGhostish,
    M3EShapeKind.pixelCircle => Get.context!.l10n.shapePixelCircle,
    M3EShapeKind.pixelTriangle => Get.context!.l10n.shapePixelTriangle,
    M3EShapeKind.bun => Get.context!.l10n.shapeBun,
    M3EShapeKind.heart => Get.context!.l10n.shapeHeart,
  };
}

String getTileIconShapeDescription(int index) {
  if (index <= 0 || index > M3EShapeKind.values.length) {
    return Get.context!.l10n.tileShapeDefaultDesc;
  }
  return Get.context!.l10n.tileShapeDesc(getTileIconShapeName(index).toLowerCase());
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
