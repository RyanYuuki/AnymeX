import 'dart:io';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme_registry.dart';
import 'package:anymex/screens/settings/sub_settings/settings_tap_zones.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';

class ReaderSettings {
  final ReaderController controller;
  ReaderSettings({required this.controller});

  void showSettings(BuildContext context) {
    final settings = Get.find<Settings>();
    final wasVolumeEnabled = controller.volumeKeysEnabled.value;
    if (wasVolumeEnabled) {
      controller.pauseVolumeKeys();
    }

    void showReaderControlThemeDialog() {
      showSelectionDialog<String>(
        title: 'Reader Control Theme',
        items: ReaderControlThemeRegistry.themes.map((e) => e.id).toList(),
        selectedItem: settings.readerControlThemeRx,
        getTitle: (id) => ReaderControlThemeRegistry.resolve(id).name,
        onItemSelected: (id) {
          settings.readerControlTheme = id;
        },
        leadingIcon: Icons.style_rounded,
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        const topCornerRadius = BorderRadius.vertical(top: Radius.circular(16));
        return ClipRRect(
          borderRadius: topCornerRadius,
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
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
                    final themeId = settings.readerControlThemeRx.value;
                    return CustomTile(
                      title: 'Control Theme',
                      description:
                          ReaderControlThemeRegistry.resolve(themeId).name,
                      icon: Icons.style_rounded,
                      onTap: showReaderControlThemeDialog,
                    );
                  }),
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
                                        .opaque(0.2)
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer,
                                foregroundColor: layout == currentLayout
                                    ? context.colors.primary
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
                  if (Platform.isAndroid || Platform.isIOS)
                    CustomTile(
                      title: 'Tap Zones',
                      description: 'Customize gestures',
                      icon: Icons.touch_app_rounded,
                      onTap: () {
                        Navigator.pop(context);
                        navigate(() => const TapZoneSettingsScreen());
                      },
                    ),
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
                                        .opaque(0.2)
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer,
                                foregroundColor: direction == currentDirection
                                    ? context.colors.primary
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
                    final currentMode = controller.dualPageMode.value;
                    return CustomTile(
                      title: 'Dual Page Mode',
                      description: switch (currentMode) {
                        DualPageMode.off => 'Standard (Single)',
                        DualPageMode.auto => 'Auto (Laptop/Tab)',
                        DualPageMode.force => 'Force (Dual)',
                      },
                      icon: Iconsax.book_1,
                      postFix: Row(
                        spacing: 4,
                        children: [
                          for (final mode in DualPageMode.values)
                            IconButton.filled(
                              isSelected: mode == currentMode,
                              style: IconButton.styleFrom(
                                backgroundColor: mode == currentMode
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.2)
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer,
                                foregroundColor: mode == currentMode
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).iconTheme.color,
                              ),
                              tooltip: mode.toString(),
                              icon: Icon(switch (mode) {
                                DualPageMode.off => Icons.crop_portrait_sharp,
                                DualPageMode.auto => Icons.devices,
                                DualPageMode.force => Icons.menu_book_rounded,
                              }),
                              onPressed: () =>
                                  controller.toggleDualPageMode(mode),
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
                  Obx(() {
                    return CustomSwitchTile(
                      icon: Iconsax.arrow,
                      title: "Overscroll",
                      description: "To Prev/Next Chapter",
                      switchValue: controller.overscrollToChapter.value,
                      onChanged: (val) =>
                          controller.toggleOverscrollToChapter(),
                    );
                  }),
                  Obx(() {
                    return CustomSwitchTile(
                      icon: Iconsax.eye,
                      title: "Persistent Page Indicator",
                      description: "Always show page indicator",
                      switchValue: controller.showPageIndicator.value,
                      onChanged: (val) => controller.togglePageIndicator(),
                    );
                  }),
                  if (Platform.isAndroid)
                    Obx(() {
                      return CustomSwitchTile(
                        icon: Iconsax.volume_high,
                        title: "Volume Keys Navigation",
                        description: "Use volume keys to change pages",
                        switchValue: controller.volumeKeysEnabled.value,
                        onChanged: (val) => controller.toggleVolumeKeys(),
                      );
                    }),
                  if (Platform.isAndroid)
                    Obx(() {
                      return CustomSwitchTile(
                        icon: Iconsax.arrow_swap_horizontal,
                        title: "Invert Volume Keys",
                        description: "Swap Up/Down actions",
                        switchValue: controller.invertVolumeKeys.value,
                        onChanged: (val) {
                          controller.invertVolumeKeys.value = val;
                          controller.savePreferences();
                        },
                      );
                    }),
                  Obx(() {
                    return CustomSwitchTile(
                      icon: Icons.crop_rounded,
                      title: "Crop Borders",
                      description:
                          "Remove white/black borders to maximize content",
                      switchValue: controller.cropImages.value,
                      onChanged: (val) {
                        controller.toggleCropImages();
                      },
                    );
                  }),
                  Obx(() {
                    return CustomSwitchTile(
                      icon: Icons.play_arrow_rounded,
                      title: "Auto Scroll",
                      description: "Automatically scroll/advance pages",
                      switchValue: controller.autoScrollEnabled.value,
                      onChanged: (val) => controller.toggleAutoScroll(),
                    );
                  }),
                  Obx(() {
                    if (!controller.autoScrollEnabled.value) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: CustomSliderTile(
                        title: 'Auto Scroll Speed',
                        sliderValue: controller.autoScrollSpeed.value,
                        onChanged: (double value) {
                          controller.setAutoScrollSpeed(value);
                        },
                        onChangedEnd: (e) => controller.savePreferences(),
                        description:
                            controller.readingLayout.value ==
                                    MangaPageViewMode.continuous
                                ? 'Seconds to scroll one screen height'
                                : 'Seconds per page turn',
                        icon: Icons.speed,
                        min: 1.0,
                        max: 10.0,
                        label:
                            '${controller.autoScrollSpeed.value.toStringAsFixed(1)}s',
                        divisions: 18,
                      ),
                    );
                  }),
                  Obx(() {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: CustomSliderTile(
                        title: 'Preload Page',
                        sliderValue:
                            controller.preloadPages.value.toDouble(),
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10.0),
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10.0),
                        child: CustomSliderTile(
                          title: 'Scroll Multiplier',
                          sliderValue:
                              controller.scrollSpeedMultiplier.value,
                          onChanged: (double value) {
                            controller.scrollSpeedMultiplier.value = value;
                          },
                          onChangedEnd: (e) => controller.savePreferences(),
                          description: 'Adjust Key & Volume Scrolling Speed',
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
    ).then((_) {
      if (wasVolumeEnabled) {
        controller.resumeVolumeKeys();
      }
    });
  }
}

class TabbedReaderSettings {
  final ReaderController controller;
  TabbedReaderSettings({required this.controller});

  void showSettings(BuildContext context) {
    final wasVolumeEnabled = controller.volumeKeysEnabled.value;
    if (wasVolumeEnabled) controller.pauseVolumeKeys();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TabbedSettingsSheet(controller: controller),
    ).then((_) {
      if (wasVolumeEnabled) controller.resumeVolumeKeys();
    });
  }
}

class _TabbedSettingsSheet extends StatefulWidget {
  final ReaderController controller;
  const _TabbedSettingsSheet({required this.controller});

  @override
  State<_TabbedSettingsSheet> createState() => _TabbedSettingsSheetState();
}

class _TabbedSettingsSheetState extends State<_TabbedSettingsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  ReaderController get c => widget.controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      snap: true,
      snapSizes: const [0.7, 0.95],
      builder: (ctx, sc) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          color: colors.surface,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Reader Settings',
                  style: TextStyle(
                      fontSize: 18, fontFamily: 'Poppins-SemiBold'),
                ),
              ),
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Reading Mode'),
                  Tab(text: 'General'),
                  Tab(text: 'Color Filter'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _ReadingModeTab(controller: c, scrollController: sc),
                    _GeneralTab(controller: c, scrollController: sc),
                    _ColorFilterTab(controller: c, scrollController: sc),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingModeTab extends StatelessWidget {
  final ReaderController controller;
  final ScrollController scrollController;
  const _ReadingModeTab(
      {required this.controller, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Obx(() {
          final currentLayout = c.readingLayout.value;
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
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                          : Theme.of(context).colorScheme.surfaceContainer,
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
                      MangaPageViewMode.paged => const Icon(Iconsax.grid_9),
                    },
                    onPressed: () => c.changeReadingLayout(layout),
                  )
              ],
            ),
          );
        }),
        Obx(() {
          final currentDirection = c.readingDirection.value;
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
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                          : Theme.of(context).colorScheme.surfaceContainer,
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
                    onPressed: () => c.changeReadingDirection(direction),
                  )
              ],
            ),
          );
        }),
        Obx(() {
          final currentMode = c.dualPageMode.value;
          return CustomTile(
            title: 'Dual Page Mode',
            description: switch (currentMode) {
              DualPageMode.off => 'Standard (Single)',
              DualPageMode.auto => 'Auto (Laptop/Tab)',
              DualPageMode.force => 'Force (Dual)',
            },
            icon: Iconsax.book_1,
            postFix: Row(
              spacing: 4,
              children: [
                for (final mode in DualPageMode.values)
                  IconButton.filled(
                    isSelected: mode == currentMode,
                    style: IconButton.styleFrom(
                      backgroundColor: mode == currentMode
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                          : Theme.of(context).colorScheme.surfaceContainer,
                      foregroundColor: mode == currentMode
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).iconTheme.color,
                    ),
                    tooltip: mode.toString(),
                    icon: Icon(switch (mode) {
                      DualPageMode.off => Icons.crop_portrait_sharp,
                      DualPageMode.auto => Icons.devices,
                      DualPageMode.force => Icons.menu_book_rounded,
                    }),
                    onPressed: () => c.toggleDualPageMode(mode),
                  )
              ],
            ),
          );
        }),
        if (Platform.isAndroid || Platform.isIOS)
          CustomTile(
            title: 'Tap Zones',
            description: 'Customize gestures',
            icon: Icons.touch_app_rounded,
            onTap: () {
              Navigator.pop(context);
              navigate(() => const TapZoneSettingsScreen());
            },
          ),
        Obx(() => CustomSwitchTile(
              icon: Iconsax.pharagraphspacing,
              title: "Spaced Pages",
              description: "Continuous Mode only",
              switchValue: c.spacedPages.value,
              onChanged: (val) => c.toggleSpacedPages(),
            )),
        Obx(() => CustomSwitchTile(
              icon: Iconsax.arrow,
              title: "Overscroll",
              description: "To Prev/Next Chapter",
              switchValue: c.overscrollToChapter.value,
              onChanged: (val) => c.toggleOverscrollToChapter(),
            )),
        Obx(() => CustomSwitchTile(
              icon: Icons.auto_fix_high_rounded,
              title: "Auto Webtoon Mode",
              description: "Switch to continuous for long strips (15+ pages)",
              switchValue: c.autoWebtoonMode.value,
              onChanged: (val) => c.toggleAutoWebtoonMode(),
            )),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _GeneralTab extends StatelessWidget {
  final ReaderController controller;
  final ScrollController scrollController;
  const _GeneralTab(
      {required this.controller, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final settings = Get.find<Settings>();
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Obx(() {
          final themeId = settings.readerControlThemeRx.value;
          return CustomTile(
            title: 'Control Theme',
            description: ReaderControlThemeRegistry.resolve(themeId).name,
            icon: Icons.style_rounded,
            onTap: () => showSelectionDialog<String>(
              title: 'Reader Control Theme',
              items:
                  ReaderControlThemeRegistry.themes.map((e) => e.id).toList(),
              selectedItem: settings.readerControlThemeRx,
              getTitle: (id) => ReaderControlThemeRegistry.resolve(id).name,
              onItemSelected: (id) => settings.readerControlTheme = id,
              leadingIcon: Icons.style_rounded,
            ),
          );
        }),
        Obx(() {
          final theme = c.readerTheme.value;
          final labels = ['White', 'Black', 'Gray', 'System'];
          return CustomTile(
            title: 'Background Theme',
            description: labels[theme.clamp(0, 3)],
            icon: Icons.brightness_6_rounded,
            postFix: Row(
              spacing: 4,
              children: [
                for (int i = 0; i < 4; i++)
                  IconButton.filled(
                    isSelected: theme == i,
                    style: IconButton.styleFrom(
                      backgroundColor: theme == i
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                          : Theme.of(context).colorScheme.surfaceContainer,
                      foregroundColor: theme == i
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).iconTheme.color,
                    ),
                    tooltip: labels[i],
                    icon: Icon([
                      Icons.brightness_high,
                      Icons.brightness_2,
                      Icons.brightness_5,
                      Icons.brightness_auto,
                    ][i]),
                    onPressed: () {
                      c.readerTheme.value = i;
                      c.savePreferences();
                    },
                  )
              ],
            ),
          );
        }),
        Obx(() => CustomSwitchTile(
              icon: Iconsax.eye,
              title: "Persistent Page Indicator",
              description: "Always show page indicator",
              switchValue: c.showPageIndicator.value,
              onChanged: (val) => c.togglePageIndicator(),
            )),
        Obx(() => CustomSwitchTile(
              icon: Icons.crop_rounded,
              title: "Crop Borders",
              description: "Remove white/black borders to maximize content",
              switchValue: c.cropImages.value,
              onChanged: (val) => c.toggleCropImages(),
            )),
        Obx(() => CustomSwitchTile(
              icon: Icons.screen_lock_portrait_rounded,
              title: "Keep Screen On",
              description: "Prevent screen from sleeping while reading",
              switchValue: c.keepScreenOn.value,
              onChanged: (val) => c.toggleKeepScreenOn(),
            )),
        Obx(() => CustomSwitchTile(
              icon: Icons.swap_horiz_rounded,
              title: "Always Show Chapter Transition",
              description: "Show chapter boundary card between chapters",
              switchValue: c.alwaysShowChapterTransition.value,
              onChanged: (val) => c.toggleAlwaysShowChapterTransition(),
            )),
        Obx(() => CustomSwitchTile(
              icon: Icons.touch_app_rounded,
              title: "Long Press Page Actions",
              description: "Save/Share/Copy page on long press",
              switchValue: c.longPressPageActionsEnabled.value,
              onChanged: (val) => c.toggleLongPressPageActions(),
            )),
        if (Platform.isAndroid)
          Obx(() => CustomSwitchTile(
                icon: Iconsax.volume_high,
                title: "Volume Keys Navigation",
                description: "Use volume keys to change pages",
                switchValue: c.volumeKeysEnabled.value,
                onChanged: (val) => c.toggleVolumeKeys(),
              )),
        if (Platform.isAndroid)
          Obx(() => CustomSwitchTile(
                icon: Iconsax.arrow_swap_horizontal,
                title: "Invert Volume Keys",
                description: "Swap Up/Down actions",
                switchValue: c.invertVolumeKeys.value,
                onChanged: (val) {
                  c.invertVolumeKeys.value = val;
                  c.savePreferences();
                },
              )),
        Obx(() => CustomSwitchTile(
              icon: Icons.refresh_rounded,
              title: "E-ink Display Refresh",
              description: "Flash screen on page turn for e-ink displays",
              switchValue: c.displayRefreshEnabled.value,
              onChanged: (val) => c.toggleDisplayRefresh(),
            )),
        Obx(() {
          if (!c.displayRefreshEnabled.value) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: CustomSliderTile(
              title: 'Refresh Flash Duration',
              sliderValue: c.displayRefreshDurationMs.value.toDouble(),
              onChanged: (v) => c.displayRefreshDurationMs.value = v.toInt(),
              onChangedEnd: (_) => c.savePreferences(),
              description: 'How long the flash lasts (ms)',
              icon: Icons.timer_rounded,
              min: 50,
              max: 500,
              label: '${c.displayRefreshDurationMs.value}ms',
              divisions: 9,
            ),
          );
        }),
        Obx(() {
          if (!c.displayRefreshEnabled.value) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: CustomSliderTile(
              title: 'Refresh Interval',
              sliderValue: c.displayRefreshInterval.value.toDouble(),
              onChanged: (v) => c.displayRefreshInterval.value = v.toInt(),
              onChangedEnd: (_) => c.savePreferences(),
              description: 'Flash every N page turns (1 = every page)',
              icon: Icons.repeat_rounded,
              min: 1,
              max: 10,
              label: 'Every ${c.displayRefreshInterval.value} pages',
              divisions: 9,
            ),
          );
        }),
        Obx(() => CustomSwitchTile(
              icon: Icons.play_arrow_rounded,
              title: "Auto Scroll",
              description: "Automatically scroll/advance pages",
              switchValue: c.autoScrollEnabled.value,
              onChanged: (val) => c.toggleAutoScroll(),
            )),
        Obx(() {
          if (!c.autoScrollEnabled.value) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: CustomSliderTile(
              title: 'Auto Scroll Speed',
              sliderValue: c.autoScrollSpeed.value,
              onChanged: (v) => c.setAutoScrollSpeed(v),
              onChangedEnd: (_) => c.savePreferences(),
              description: c.readingLayout.value == MangaPageViewMode.continuous
                  ? 'Seconds to scroll one screen height'
                  : 'Seconds per page turn',
              icon: Icons.speed,
              min: 1.0,
              max: 10.0,
              label: '${c.autoScrollSpeed.value.toStringAsFixed(1)}s',
              divisions: 18,
            ),
          );
        }),
        Obx(() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: CustomSliderTile(
                title: 'Preload Pages',
                sliderValue: c.preloadPages.value.toDouble(),
                onChanged: (v) => c.preloadPages.value = v.toInt(),
                onChangedEnd: (_) => c.savePreferences(),
                description:
                    'Preload pages ahead of time (uses more network & RAM)',
                icon: Icons.image_aspect_ratio_rounded,
                min: 1.0,
                max: 15.0,
                label: c.preloadPages.value.toString(),
                divisions: 15,
              ),
            )),
        if (!Platform.isAndroid && !Platform.isIOS)
          Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: CustomSliderTile(
                  title: 'Image Width',
                  sliderValue: c.pageWidthMultiplier.value,
                  onChanged: (v) => c.pageWidthMultiplier.value = v,
                  onChangedEnd: (_) => c.savePreferences(),
                  description: 'Continuous Mode only',
                  icon: Icons.image_aspect_ratio_rounded,
                  min: 1.0,
                  max: 2.5,
                  divisions: 15,
                ),
              )),
        if (!Platform.isAndroid && !Platform.isIOS)
          Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: CustomSliderTile(
                  title: 'Scroll Multiplier',
                  sliderValue: c.scrollSpeedMultiplier.value,
                  onChanged: (v) => c.scrollSpeedMultiplier.value = v,
                  onChangedEnd: (_) => c.savePreferences(),
                  description: 'Adjust Key & Volume Scrolling Speed',
                  icon: Icons.speed,
                  min: 1.0,
                  max: 5.0,
                  divisions: 9,
                ),
              )),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _ColorFilterTab extends StatelessWidget {
  final ReaderController controller;
  final ScrollController scrollController;
  const _ColorFilterTab(
      {required this.controller, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Obx(() => CustomSwitchTile(
              icon: Icons.brightness_6_rounded,
              title: "Custom Brightness",
              description: "Dim or brighten the reader",
              switchValue: c.customBrightnessEnabled.value,
              onChanged: (val) => c.toggleCustomBrightness(),
            )),
        Obx(() {
          if (!c.customBrightnessEnabled.value) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: CustomSliderTile(
              title: 'Brightness',
              sliderValue: c.customBrightnessValue.value,
              onChanged: (v) => c.customBrightnessValue.value = v,
              onChangedEnd: (_) => c.savePreferences(),
              description: 'Negative = dim, positive = brighten',
              icon: Icons.wb_sunny_rounded,
              min: -0.75,
              max: 1.0,
              label:
                  '${(c.customBrightnessValue.value * 100).toStringAsFixed(0)}%',
              divisions: 35,
            ),
          );
        }),
        Obx(() => CustomSwitchTile(
              icon: Icons.color_lens_rounded,
              title: "Color Filter",
              description: "Apply a color tint overlay",
              switchValue: c.colorFilterEnabled.value,
              onChanged: (val) => c.toggleColorFilter(),
            )),
        Obx(() {
          if (!c.colorFilterEnabled.value) return const SizedBox.shrink();
          final argb = c.colorFilterValue.value;
          final a = ((argb >> 24) & 0xFF).toDouble();
          final r = ((argb >> 16) & 0xFF).toDouble();
          final g = ((argb >> 8) & 0xFF).toDouble();
          final b = (argb & 0xFF).toDouble();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: CustomSliderTile(
                  title: 'Alpha (Opacity)',
                  sliderValue: a,
                  onChanged: (v) =>
                      c.setColorFilterChannel('a', v.toInt()),
                  onChangedEnd: (_) => c.savePreferences(),
                  description: 'Filter transparency',
                  icon: Icons.opacity_rounded,
                  min: 0,
                  max: 255,
                  label: a.toInt().toString(),
                  divisions: 255,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: CustomSliderTile(
                  title: 'Red',
                  sliderValue: r,
                  onChanged: (v) =>
                      c.setColorFilterChannel('r', v.toInt()),
                  onChangedEnd: (_) => c.savePreferences(),
                  description: '',
                  icon: Icons.circle,
                  min: 0,
                  max: 255,
                  label: r.toInt().toString(),
                  divisions: 255,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: CustomSliderTile(
                  title: 'Green',
                  sliderValue: g,
                  onChanged: (v) =>
                      c.setColorFilterChannel('g', v.toInt()),
                  onChangedEnd: (_) => c.savePreferences(),
                  description: '',
                  icon: Icons.circle,
                  min: 0,
                  max: 255,
                  label: g.toInt().toString(),
                  divisions: 255,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: CustomSliderTile(
                  title: 'Blue',
                  sliderValue: b,
                  onChanged: (v) =>
                      c.setColorFilterChannel('b', v.toInt()),
                  onChangedEnd: (_) => c.savePreferences(),
                  description: '',
                  icon: Icons.circle,
                  min: 0,
                  max: 255,
                  label: b.toInt().toString(),
                  divisions: 255,
                ),
              ),
              Obx(() {
                final blendModes = BlendMode.values;
                final currentMode = c.colorFilterMode.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Blend Mode',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final mode in [
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
                          ])
                            ChoiceChip(
                              label: Text(mode.name),
                              selected: currentMode == mode,
                              onSelected: (_) {
                                c.colorFilterMode.value = mode;
                                c.savePreferences();
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        }),
        Obx(() => CustomSwitchTile(
              icon: Icons.gradient_rounded,
              title: "Grayscale",
              description: "Convert pages to black & white",
              switchValue: c.grayscaleEnabled.value,
              onChanged: (val) => c.toggleGrayscale(),
            )),
        Obx(() => CustomSwitchTile(
              icon: Icons.invert_colors_rounded,
              title: "Invert Colors",
              description: "Invert all colors (dark mode for pages)",
              switchValue: c.invertColorsEnabled.value,
              onChanged: (val) => c.toggleInvertColors(),
            )),
        const SizedBox(height: 20),
      ],
    );
  }
}
