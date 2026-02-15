import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_theme_data.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_theme_registry.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemedTopControls extends StatelessWidget {
  const ThemedTopControls({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();
    final controller = Get.find<PlayerController>();

    return Obx(() {
      final theme =
          PlayerControlThemeRegistry.resolve(settings.playerControlThemeRx.value);
      final data = PlayerTopSectionData.fromContext(context, controller);
      return theme.buildTopControls(context, data);
    });
  }
}

class ThemedCenterControls extends StatelessWidget {
  const ThemedCenterControls({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();
    final controller = Get.find<PlayerController>();

    return Obx(() {
      final theme =
          PlayerControlThemeRegistry.resolve(settings.playerControlThemeRx.value);
      final data = PlayerCenterSectionData.fromContext(context, controller);
      return theme.buildCenterControls(context, data);
    });
  }
}

class ThemedBottomControls extends StatelessWidget {
  const ThemedBottomControls({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();
    final controller = Get.find<PlayerController>();

    return Obx(() {
      final theme =
          PlayerControlThemeRegistry.resolve(settings.playerControlThemeRx.value);
      final data = PlayerBottomSectionData.fromContext(context, controller);
      return theme.buildBottomControls(context, data);
    });
  }
}
