import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme_registry.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemedReaderTopControls extends StatelessWidget {
  const ThemedReaderTopControls({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();
    final controller = Get.find<ReaderController>();

    return Obx(() {
      final theme = ReaderControlThemeRegistry.resolve(
          settings.readerControlThemeRx.value);
      return theme.buildTopControls(context, controller);
    });
  }
}

class ThemedReaderBottomControls extends StatelessWidget {
  const ThemedReaderBottomControls({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();
    final controller = Get.find<ReaderController>();

    return Obx(() {
      final theme = ReaderControlThemeRegistry.resolve(
          settings.readerControlThemeRx.value);
      return theme.buildBottomControls(context, controller);
    });
  }
}

class ThemedReaderCenterControls extends StatelessWidget {
  const ThemedReaderCenterControls({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();
    final controller = Get.find<ReaderController>();

    return Obx(() {
      final theme = ReaderControlThemeRegistry.resolve(
          settings.readerControlThemeRx.value);
      return theme.buildCenterControls(context, controller);
    });
  }
}
