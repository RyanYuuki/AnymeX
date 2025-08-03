import 'dart:io';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
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
        const topCornerRadius = BorderRadius.vertical(top: Radius.circular(16));
        return ClipRRect(
          borderRadius: topCornerRadius,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 10),
                    child: Center(
                      child: Text(
                        'Reader Settings',
                        style: TextStyle(
                            fontSize: 18, fontFamily: 'Poppins-SemiBold'),
                      ),
                    ),
                  ),
                  Obx(() {
                    final currentLayout = controller.readingLayout.value;
                    return CustomTile(
                      title: 'Layout',
                      description: switch (currentLayout) {
                        MangaPageViewMode.continuous => 'Continuous',
                        MangaPageViewMode.paged => 'Paged',
                      },
                      icon: Iconsax.card,
                      postFix: Row(
                        spacing: 4,
                        children: [
                          for (final layout in [
                            MangaPageViewMode.continuous,
                            MangaPageViewMode.paged
                          ])
                            IconButton.filled(
                              isSelected: layout == currentLayout,
                              style: IconButton.styleFrom(
                                backgroundColor: layout == currentLayout
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.2)
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer,
                                foregroundColor: layout == currentLayout
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).iconTheme.color,
                              ),
                              tooltip: switch (layout) {
                                MangaPageViewMode.continuous => 'Continuous',
                                MangaPageViewMode.paged => 'Paged',
                              },
                              icon: switch (layout) {
                                MangaPageViewMode.continuous =>
                                  const Icon(Iconsax.slider_vertical),
                                MangaPageViewMode.paged =>
                                  const Icon(Iconsax.grid_9),
                              },
                              onPressed: () {
                                controller.changeReadingLayout(layout);
                              },
                            )
                        ],
                      ),
                    );
                  }),
                  Obx(() {
                    final currentDirection = controller.readingDirection.value;
                    return CustomTile(
                      title: 'Direction',
                      description: switch (currentDirection) {
                        MangaPageViewDirection.down => "Top-Down",
                        MangaPageViewDirection.right => "LTR",
                        MangaPageViewDirection.up => "Bottom-Up",
                        MangaPageViewDirection.left => "RTL",
                      },
                      icon: Iconsax.direct_right,
                      postFix: Row(
                        spacing: 4,
                        children: [
                          for (final direction in [
                            MangaPageViewDirection.down,
                            MangaPageViewDirection.right,
                            MangaPageViewDirection.up,
                            MangaPageViewDirection.left,
                          ])
                            IconButton.filled(
                              isSelected: direction == currentDirection,
                              enableFeedback: true,
                              tooltip: switch (direction) {
                                MangaPageViewDirection.down => "Top-Down",
                                MangaPageViewDirection.right => "LTR",
                                MangaPageViewDirection.up => "Bottom-Up",
                                MangaPageViewDirection.left => "RTL",
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: direction == currentDirection
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.2)
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer,
                                foregroundColor: direction == currentDirection
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).iconTheme.color,
                              ),
                              icon: switch (direction) {
                                MangaPageViewDirection.down =>
                                  const Icon(Iconsax.arrow_down),
                                MangaPageViewDirection.right =>
                                  const Icon(Iconsax.arrow_right_1),
                                MangaPageViewDirection.up =>
                                  const Icon(Iconsax.arrow_up_3),
                                MangaPageViewDirection.left =>
                                  const Icon(Iconsax.arrow_left),
                              },
                              onPressed: () {
                                controller.changeReadingDirection(direction);
                              },
                            )
                        ],
                      ),
                    );
                  }),
                  Obx(() {
                    return CustomSwitchTile(
                      icon: Iconsax.pharagraphspacing,
                      title: "Spaced Pages",
                      description: "Continuous Mode only",
                      switchValue: controller.spacedPages.value,
                      onChanged: (val) => controller.toggleSpacedPages(),
                    );
                  }),
                  // Obx(() {
                  //   return CustomSwitchTile(
                  //     icon: Iconsax.arrow,
                  //     title: "Overscroll",
                  //     description: "To Prev/Next Chapter",
                  //     switchValue: controller.overscrollToChapter.value,
                  //     onChanged: (val) =>
                  //         controller.toggleOverscrollToChapter(),
                  //   );
                  // }),
                  Obx(() {
                    return CustomSwitchTile(
                      icon: Iconsax.eye,
                      title: "Persistent Page Indicator",
                      description: "Always show page indicator",
                      switchValue: controller.showPageIndicator.value,
                      onChanged: (val) => controller.togglePageIndicator(),
                    );
                  }),
                  Obx(() {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: CustomSliderTile(
                        title: 'Preload Page',
                        sliderValue: controller.preloadPages.value.toDouble(),
                        onChanged: (double value) {
                          controller.preloadPages.value = value.toInt();
                        },
                        onChangedEnd: (e) => controller.savePreferences(),
                        description:
                            'Preload Pages ahead of time for faster loading (Consumes more network and ram)',
                        icon: Icons.image_aspect_ratio_rounded,
                        min: 1.0,
                        max: 15.0,
                        label: controller.preloadPages.value.toString(),
                        divisions: 15,
                      ),
                    );
                  }),
                  if (!Platform.isAndroid && !Platform.isIOS)
                    Obx(() {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: CustomSliderTile(
                          title: 'Image Width',
                          sliderValue: controller.pageWidthMultiplier.value,
                          onChanged: (double value) {
                            controller.pageWidthMultiplier.value = value;
                          },
                          onChangedEnd: (e) => controller.savePreferences(),
                          description: 'Continuous Mode only',
                          icon: Icons.image_aspect_ratio_rounded,
                          min: 1.0,
                          max: 2.5,
                          divisions: 15,
                        ),
                      );
                    }),
                  if (!Platform.isAndroid && !Platform.isIOS)
                    Obx(() {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: CustomSliderTile(
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
                        ),
                      );
                    }),
                  20.height()
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
