import 'package:anymex/l10n/l10n_extension.dart';
import 'dart:io';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme_registry.dart';
import 'package:anymex/screens/settings/sub_settings/settings_tap_zones.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

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
        title: context.l10n.readerControlTheme,
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
                      child: AnymeXText(
                        'Reader Settings',
                        style: TextStyle(
                            fontSize: 18, fontFamily: 'Linotte'),
                      ),
                    ),
                  ),
                  Obx(() {
                    final themeId = settings.readerControlThemeRx.value;
                    return AnymeXTile(
                      title: context.l10n.controlTheme,
                      subtitle:
                          ReaderControlThemeRegistry.resolve(themeId).name,
                      icon: Icons.style_rounded,
                      onTap: showReaderControlThemeDialog,
                    );
                  }),
                  Obx(() {
                    final currentLayout = controller.readingLayout.value;
                    return AnymeXTile(
                      title: context.l10n.layout,
                      subtitle: switch (currentLayout) {
                        MangaPageViewMode.continuous => 'Continuous',
                        MangaPageViewMode.paged => 'Paged',
                      },
                      icon: Iconsax.card,
                      trailing: Row(
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
                    AnymeXTile(
                      title: context.l10n.tapZones,
                      subtitle: context.l10n.customizeGestures,
                      icon: Icons.touch_app_rounded,
                      onTap: () {
                        Navigator.pop(context);
                        navigate(() => const TapZoneSettingsScreen());
                      },
                    ),
                  Obx(() {
                    final currentDirection = controller.readingDirection.value;
                    return AnymeXTile(
                      title: context.l10n.direction,
                      subtitle: switch (currentDirection) {
                        MangaPageViewDirection.down => "Top-Down",
                        MangaPageViewDirection.right => "LTR",
                        MangaPageViewDirection.up => "Bottom-Up",
                        MangaPageViewDirection.left => "RTL",
                      },
                      icon: Iconsax.direct_right,
                      trailing: Row(
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
                    return AnymeXTile(
                      title: context.l10n.dualPageMode,
                      subtitle: switch (currentMode) {
                        DualPageMode.off => 'Standard (Single)',
                        DualPageMode.auto => 'Auto (Laptop/Tab)',
                        DualPageMode.force => 'Force (Dual)',
                      },
                      icon: Iconsax.book_1,
                      trailing: Row(
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
                    return AnymeXTile.toggle(
                      icon: Iconsax.pharagraphspacing,
                      title: context.l10n.spacedPages,
                      subtitle: context.l10n.continuousModeOnly2,
                      value: controller.spacedPages.value,
                      onChanged: (val) => controller.toggleSpacedPages(),
                    );
                  }),
                  Obx(() {
                    return AnymeXTile.toggle(
                      icon: Iconsax.arrow,
                      title: context.l10n.overscroll,
                      subtitle: context.l10n.toPrevNextChapter,
                      value: controller.overscrollToChapter.value,
                      onChanged: (val) =>
                          controller.toggleOverscrollToChapter(),
                    );
                  }),
                  Obx(() {
                    return AnymeXTile.toggle(
                      icon: Iconsax.eye,
                      title: context.l10n.persistentPageIndicator,
                      subtitle: context.l10n.alwaysShowPageIndicator,
                      value: controller.showPageIndicator.value,
                      onChanged: (val) => controller.togglePageIndicator(),
                    );
                  }),
                  if (Platform.isAndroid)
                    Obx(() {
                      return AnymeXTile.toggle(
                        icon: Iconsax.volume_high,
                        title: context.l10n.volumeKeysNavigation,
                        subtitle: context.l10n.useVolumeKeysToChangePages,
                        value: controller.volumeKeysEnabled.value,
                        onChanged: (val) => controller.toggleVolumeKeys(),
                      );
                    }),
                  if (Platform.isAndroid)
                    Obx(() {
                      return AnymeXTile.toggle(
                        icon: Iconsax.arrow_swap_horizontal,
                        title: context.l10n.invertVolumeKeys,
                        subtitle: context.l10n.swapUpDownActions2,
                        value: controller.invertVolumeKeys.value,
                        onChanged: (val) {
                          controller.invertVolumeKeys.value = val;
                          controller.savePreferences();
                        },
                      );
                    }),
                  Obx(() {
                    return AnymeXTile.toggle(
                      icon: Icons.crop_rounded,
                      title: context.l10n.cropBorders,
                      subtitle:
                          context.l10n.removeWhiteBlackBordersToMaximize,
                      value: controller.cropImages.value,
                      onChanged: (val) {
                        controller.toggleCropImages();
                      },
                    );
                  }),
                  Obx(() {
                    return AnymeXTile.toggle(
                      icon: Icons.fullscreen_rounded,
                      title: context.l10n.fitToScreenWidth,
                      subtitle:
                          context.l10n.stretchImagesToFitScreenWidthOn,
                      value: controller.fitToScreen.value,
                      onChanged: (val) {
                        controller.toggleFitToScreen();
                      },
                    );
                  }),
                  Obx(() {
                    if (controller.readingLayout.value == MangaPageViewMode.paged) {
                      return const SizedBox.shrink();
                    }
                    return AnymeXTile.toggle(
                      icon: Icons.play_arrow_rounded,
                      title: context.l10n.autoScroll,
                      subtitle: context.l10n.automaticallyScrollAdvancePages,
                      value: controller.autoScrollEnabled.value,
                      onChanged: (val) => controller.toggleAutoScroll(),
                    );
                  }),
                  Obx(() {
                    if (controller.readingLayout.value == MangaPageViewMode.paged ||
                        !controller.autoScrollEnabled.value) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: AnymeXTile.slider(
                        title: context.l10n.autoScrollSpeed,
                        value: controller.autoScrollSpeed.value,
                        onChanged: (double value) {
                          controller.setAutoScrollSpeed(value);
                        },
                        subtitle:
                            controller.readingLayout.value ==
                                    MangaPageViewMode.continuous
                                ? 'Seconds to scroll one screen height'
                                : 'Seconds per page turn',
                        icon: Icons.speed,
                        min: 1.0,
                        max: 10.0,
                        divisions: 18,
                      ),
                    );
                  }),
                  Obx(() {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: AnymeXTile.slider(
                        title: context.l10n.preloadPage,
                        value:
                            controller.preloadPages.value.toDouble(),
                        onChanged: (double value) {
                          controller.preloadPages.value = value.toInt();
                        },
                        subtitle:
                            context.l10n.preloadPagesAheadOfTimeFor,
                        icon: Icons.image_aspect_ratio_rounded,
                        min: 1.0,
                        max: 15.0,
                        divisions: 15,
                      ),
                    );
                  }),
                  if (!Platform.isAndroid && !Platform.isIOS)
                    Obx(() {
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10.0),
                        child: AnymeXTile.slider(
                          title: context.l10n.imageWidth,
                          value: controller.pageWidthMultiplier.value,
                          onChanged: (double value) {
                            controller.pageWidthMultiplier.value = value;
                          },
                          subtitle: context.l10n.continuousModeOnly2,
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
                        child: AnymeXTile.slider(
                          title: context.l10n.scrollMultiplier,
                          value:
                              controller.scrollSpeedMultiplier.value,
                          onChanged: (double value) {
                            controller.scrollSpeedMultiplier.value = value;
                          },
                          subtitle: context.l10n.adjustKeyVolumeScrollingSpeed,
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
