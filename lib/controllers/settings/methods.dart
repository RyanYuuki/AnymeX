import 'package:anymex/controllers/settings/settings.dart';
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

  double multiplyRoundness() {
    final settings = Get.find<Settings>();
    return this * settings.cardRoundness;
  }

  double multiplyBlur() {
    final settings = Get.find<Settings>();
    return this * settings.blurMultiplier;
  }
}
int getAnimationDuration() {
  return Get.find<Settings>().animationDuration;
}
