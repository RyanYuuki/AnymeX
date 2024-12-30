import 'package:anymex/controllers/Settings/settings.dart';
import 'package:get/get.dart';

extension UIMultiplierExtension on num {
  double multiplyRadius() {
    final settings = Get.find<Settings>();
    return this * settings.radiusMultiplier;
  }

  double multiplyGlow() {
    final settings = Get.find<Settings>();
    return this * settings.glowMultiplier;
  }
}

int getAnimationDuration() {
  return Get.find<Settings>().animationDuration;
}
