import 'dart:io';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/reading_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class ReaderSettings {
  final ReaderController controller;
  ReaderSettings({required this.controller});

  void showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 10),
                  child: Center(
                    child: Text(
                      'Reader Settings',
                      style: TextStyle(
                          fontSize: 18, fontFamily: 'Poppins-SemiBold'),
                    ),
                  ),
                ),
                Obx(() {
                  return CustomTile(
                    title: 'Layout',
                    description:
                        'Currently: ${controller.activeMode.value.name.toUpperCase()}',
                    icon: Iconsax.card,
                    postFix: 0.height(),
                  );
                }),
                Obx(() {
                  final selections = List<bool>.generate(
                    ReadingMode.values.length,
                    (index) =>
                        index ==
                        ReadingMode.values.indexOf(controller.activeMode.value),
                  );
                  return Center(
                    child: ToggleButtons(
                      isSelected: selections,
                      onPressed: (int index) {
                        final mode = ReadingMode.values[index];
                        controller.changeActiveMode(mode);
                        controller.savePreferences();
                      },
                      children: const [
                        Tooltip(
                          message: 'Webtoon',
                          child: Icon(Icons.view_day),
                        ),
                        Tooltip(
                          message: 'LTR',
                          child: Icon(Icons.format_textdirection_l_to_r),
                        ),
                        Tooltip(
                          message: 'RTL',
                          child: Icon(Icons.format_textdirection_r_to_l),
                        ),
                      ],
                    ),
                  );
                }),
                if (!Platform.isAndroid && !Platform.isIOS)
                  Obx(() {
                    return CustomSliderTile(
                      title: 'Image Width',
                      sliderValue: controller.pageWidthMultiplier.value,
                      onChanged: (double value) {
                        controller.pageWidthMultiplier.value = value;
                      },
                      onChangedEnd: (e) => controller.savePreferences(),
                      description: 'Only Works with webtoon mode',
                      icon: Icons.image_aspect_ratio_rounded,
                      min: 1.0,
                      max: 4.0,
                      divisions: 39,
                    );
                  }),
                if (!Platform.isAndroid && !Platform.isIOS)
                  Obx(() {
                    return CustomSliderTile(
                      title: 'Scroll Multiplier',
                      sliderValue: controller.scrollSpeedMultiplier.value,
                      onChanged: (double value) {
                        controller.scrollSpeedMultiplier.value = value;
                      },
                      onChangedEnd: (e) => controller.savePreferences(),
                      description:
                          'Adjust Key Scrolling Speed (Up, Down, Left, Right)',
                      icon: Icons.speed,
                      min: 1.0,
                      max: 5.0,
                      divisions: 9,
                    );
                  }),
                20.height()
              ],
            ),
          ),
        );
      },
    );
  }

  List<bool> createSelectionRange() {
    final ReaderController controller = Get.find<ReaderController>();
    const readingModes = ReadingMode.values;
    final trueIndex = readingModes.indexOf(controller.activeMode.value);
    final newRange = [false, false, false];
    newRange[trueIndex] = true;
    return newRange;
  }
}
