import 'package:anymex/l10n/l10n_extension.dart';
import 'dart:io';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/color_filter_settings_page.dart';
import 'package:anymex/screens/manga/widgets/reader/upscale_settings_page.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme_registry.dart';
import 'package:anymex/screens/settings/sub_settings/settings_tap_zones.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_badge.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_segmented_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class TabbedReaderSettings {
  final ReaderController controller;

  TabbedReaderSettings({required this.controller});

  void showSettings(BuildContext context) {
    final settings = Get.find<Settings>();
    final wasVolumeEnabled = controller.volumeKeysEnabled.value;
    if (wasVolumeEnabled) controller.pauseVolumeKeys();

    AnymeXSheet.custom(
      _TabbedSettingsSheet(
        controller: controller,
        settings: settings,
      ),
      context,
      showDragHandle: true,
    ).then((_) {
      if (wasVolumeEnabled) controller.resumeVolumeKeys();
    });
  }
}

class _TabbedSettingsSheet extends StatefulWidget {
  final ReaderController controller;
  final Settings settings;

  const _TabbedSettingsSheet({
    required this.controller,
    required this.settings,
  });

  @override
  State<_TabbedSettingsSheet> createState() => _TabbedSettingsSheetState();
}

class _TabbedSettingsSheetState extends State<_TabbedSettingsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedIndex = 0;

  static final _tabs = [
    Tab(text: Get.context!.l10n.readingMode),
    Tab(text: Get.context!.l10n.general),
    Tab(text: Get.context!.l10n.colorFilter),
    Tab(text: Get.context!.l10n.upscale),
  ];

  void _onTabChanged() {
    if (!mounted) return;
    final int newIndex;
    if (_tabController.indexIsChanging) {
      newIndex = _tabController.index;
    } else if (_tabController.animation != null) {
      newIndex = _tabController.animation!.value.round();
    } else {
      newIndex = _tabController.index;
    }
    final clamped = newIndex.clamp(0, _tabs.length - 1);
    if (clamped != _selectedIndex) {
      setState(() => _selectedIndex = clamped);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _tabController.animation?.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.animation?.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.8;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnymeXText(
            context.l10n.readerSettings,
            size: 18,
            variant: TextVariant.bold,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
            child: AnymeXSegmentedButtonGroup<int>(
              selected: _selectedIndex,
              height: 44,
              scrollable: true,
              items: [
                (value: 0, title: context.l10n.readingMode, icon: null),
                (value: 1, title: context.l10n.general, icon: null),
                (value: 2, title: context.l10n.colorFilter, icon: null),
                (value: 3, title: context.l10n.upscale, icon: null),
              ],
              badgeBuilder: (context, index, isSelected) {
                if (index == 2 || index == 3) {
                  return AnymeXBadge.newBadge(context, inverted: isSelected);
                }
                return null;
              },
              onSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                  _tabController.animateTo(index);
                });
              },
            ),
          ),
          Flexible(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_selectedIndex),
                  child: switch (_selectedIndex) {
                    0 => _ReadingModePage(controller: widget.controller),
                    1 => _GeneralPage(
                        controller: widget.controller,
                        settings: widget.settings),
                    2 => ColorFilterSettingsPage(controller: widget.controller),
                    _ => UpscaleSettingsPage(controller: widget.controller),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingModePage extends StatelessWidget {
  const _ReadingModePage({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentLayout = controller.readingLayout.value;
      final currentDirection = controller.readingDirection.value;
      final currentDual = controller.dualPageMode.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Column(
          children: [
            AnymeXSectionBuilder(
              margin: const EdgeInsets.only(bottom: 12),
              children: [
                AnymeXTile(
                  title: context.l10n.layout,
                  subtitle: switch (currentLayout) {
                    MangaPageViewMode.continuous => 'Continuous',
                    MangaPageViewMode.paged => 'Paged',
                  },
                  icon: Iconsax.card,
                  trailing: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.colors.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: MangaPageViewMode.values.map((layout) {
                        final isSelected = layout == currentLayout;
                        return InkWell(
                          onTap: () => controller.changeReadingLayout(layout),
                          borderRadius: BorderRadius.circular(9),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.colors.primary.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              switch (layout) {
                                MangaPageViewMode.continuous =>
                                  Iconsax.slider_vertical,
                                MangaPageViewMode.paged => Iconsax.grid_9,
                              },
                              size: 18,
                              color: isSelected
                                  ? context.colors.primary
                                  : context.colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                AnymeXTile(
                  title: context.l10n.direction,
                  subtitle: switch (currentDirection) {
                    MangaPageViewDirection.down => 'Top-Down',
                    MangaPageViewDirection.right => 'LTR',
                    MangaPageViewDirection.up => 'Bottom-Up',
                    MangaPageViewDirection.left => 'RTL',
                  },
                  icon: Iconsax.direct_right,
                  trailing: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.colors.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: MangaPageViewDirection.values.map((dir) {
                        final isSelected = dir == currentDirection;
                        return InkWell(
                          onTap: () => controller.changeReadingDirection(dir),
                          borderRadius: BorderRadius.circular(9),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.colors.primary.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              switch (dir) {
                                MangaPageViewDirection.down =>
                                  Iconsax.arrow_down,
                                MangaPageViewDirection.right =>
                                  Iconsax.arrow_right_1,
                                MangaPageViewDirection.up => Iconsax.arrow_up_3,
                                MangaPageViewDirection.left =>
                                  Iconsax.arrow_left,
                              },
                              size: 18,
                              color: isSelected
                                  ? context.colors.primary
                                  : context.colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                AnymeXTile(
                  title: context.l10n.dualPageMode,
                  subtitle: switch (currentDual) {
                    DualPageMode.off => 'Standard (Single)',
                    DualPageMode.auto => 'Auto (Landscape)',
                    DualPageMode.force => 'Force (Always)',
                  },
                  icon: Iconsax.book_1,
                  trailing: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.colors.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: DualPageMode.values.map((mode) {
                        final isSelected = mode == currentDual;
                        return InkWell(
                          onTap: () => controller.toggleDualPageMode(mode),
                          borderRadius: BorderRadius.circular(9),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.colors.primary.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              switch (mode) {
                                DualPageMode.off => Icons.crop_portrait_sharp,
                                DualPageMode.auto => Icons.devices,
                                DualPageMode.force => Icons.menu_book_rounded,
                              },
                              size: 18,
                              color: isSelected
                                  ? context.colors.primary
                                  : context.colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
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
              ],
            ),
            AnymeXSectionBuilder(
              margin: const EdgeInsets.only(bottom: 20),
              children: [
                AnymeXTile.toggle(
                  icon: Iconsax.pharagraphspacing,
                  title: context.l10n.spacedPages,
                  subtitle: context.l10n.continuousModeOnly2,
                  value: controller.spacedPages.value,
                  onChanged: (_) => controller.toggleSpacedPages(),
                ),
                AnymeXTile.toggle(
                  icon: Iconsax.arrow,
                  title: context.l10n.overscroll,
                  subtitle: context.l10n.toPrevNextChapter,
                  value: controller.overscrollToChapter.value,
                  onChanged: (_) => controller.toggleOverscrollToChapter(),
                ),
                AnymeXTile.toggle(
                  icon: Icons.smartphone_rounded,
                  title: context.l10n.autoWebtoonMode,
                  subtitle:
                      context.l10n.automaticallySwitchToContinuousModeFor,
                  value: controller.autoWebtoonMode.value,
                  onChanged: (_) => controller.toggleAutoWebtoonMode(),
                ),
                AnymeXTile.toggle(
                  icon: Icons.onetwothree_rounded,
                  title: context.l10n.navigateByNumber,
                  subtitle: context.l10n.alwaysChecksCurrentChapterNumberAnd,
                  value: controller.navigateByNumber.value,
                  onChanged: (_) => controller.toggleNavigateByNumber(),
                ),
                AnymeXTile.toggle(
                  icon: Icons.fullscreen_rounded,
                  title: context.l10n.fitToScreenWidth,
                  subtitle: context.l10n.stretchImagesToFitScreenWidth,
                  value: controller.fitToScreen.value,
                  onChanged: (_) => controller.toggleFitToScreen(),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _GeneralPage extends StatelessWidget {
  const _GeneralPage({required this.controller, required this.settings});
  final ReaderController controller;
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Column(
          children: [
            AnymeXSectionBuilder(
              margin: const EdgeInsets.only(bottom: 12),
              children: [
                AnymeXTile(
                  title: context.l10n.controlTheme,
                  subtitle: ReaderControlThemeRegistry.resolve(
                          settings.readerControlThemeRx.value)
                      .name,
                  icon: Icons.style_rounded,
                  onTap: () => _showThemeDialog(context, settings),
                ),
                AnymeXTile(
                  title: context.l10n.background,
                  subtitle: switch (controller.readerTheme.value) {
                    0 => 'White',
                    1 => 'Black',
                    2 => 'Gray',
                    _ => 'Automatic',
                  },
                  icon: Icons.format_paint_rounded,
                  onTap: () => _showThemePicker(context),
                ),
                AnymeXTile(
                  title: context.l10n.imageFilterQuality,
                  subtitle: switch (controller.imageFilterQuality.value) {
                    0 => 'None (Nearest)',
                    1 => 'Low (Bilinear)',
                    3 => 'High (Bicubic)',
                    4 => 'Lanczos Pre-scale (Best)',
                    _ => 'Medium (Default)',
                  },
                  icon: Icons.image_search_rounded,
                  onTap: () => _showFilterQualityDialog(context),
                ),
              ],
            ),
            AnymeXSectionBuilder(
              margin: const EdgeInsets.only(bottom: 12),
              children: [
                AnymeXTile.toggle(
                  icon: Iconsax.eye,
                  title: context.l10n.persistentPageIndicator,
                  subtitle: context.l10n.alwaysShowPageIndicator,
                  value: controller.showPageIndicator.value,
                  onChanged: (_) => controller.togglePageIndicator(),
                ),
                AnymeXTile.toggle(
                  icon: Icons.crop_rounded,
                  title: context.l10n.cropBorders,
                  subtitle: context.l10n.removeWhiteBlackBorders,
                  value: controller.cropImages.value,
                  onChanged: (_) => controller.toggleCropImages(),
                ),
                AnymeXTile.toggle(
                  icon: Icons.screen_lock_rotation_rounded,
                  title: context.l10n.keepScreenOn,
                  subtitle: context.l10n.preventScreenFromSleepingWhileReading,
                  value: controller.keepScreenOn.value,
                  onChanged: (_) => controller.toggleKeepScreenOn(),
                ),
                AnymeXTile.toggle(
                  icon: Icons.compare_arrows_rounded,
                  title: context.l10n.alwaysShowChapterTransition,
                  subtitle:
                      context.l10n.showTransitionPageEvenWhenChapters,
                  value: controller.alwaysShowChapterTransition.value,
                  onChanged: (_) =>
                      controller.toggleAlwaysShowChapterTransition(),
                ),
                AnymeXTile.toggle(
                  icon: Icons.touch_app_rounded,
                  title: context.l10n.longPressForPageActions,
                  subtitle: context.l10n.longPressAPageToSave,
                  value: controller.longPressPageActionsEnabled.value,
                  onChanged: (_) => controller.toggleLongPressPageActions(),
                ),
              ],
            ),
            AnymeXSectionBuilder(
              margin: const EdgeInsets.only(bottom: 12),
              children: [
                AnymeXTile.toggle(
                  icon: Icons.monitor_rounded,
                  title: context.l10n.eInkDisplayRefresh,
                  subtitle: context.l10n.flashScreenOnPageTurnTo,
                  value: controller.displayRefreshEnabled.value,
                  onChanged: (_) => controller.toggleDisplayRefresh(),
                ),
                if (controller.displayRefreshEnabled.value) ...[
                  AnymeXTile.slider(
                    title: context.l10n.flashDuration,
                    icon: Icons.timer_rounded,
                    subtitle: context.l10n.milliseconds,
                    value: controller.displayRefreshDurationMs.value.toDouble(),
                    min: 50,
                    max: 500,
                    divisions: 18,
                    onChanged: (v) =>
                        controller.displayRefreshDurationMs.value = v.toInt(),
                  ),
                  AnymeXTile.slider(
                    title: context.l10n.flashEveryNPages,
                    icon: Icons.refresh_rounded,
                    subtitle: context.l10n.flashFrequency,
                    value: controller.displayRefreshInterval.value.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (v) =>
                        controller.displayRefreshInterval.value = v.toInt(),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.palette_rounded, size: 20),
                        const SizedBox(width: 10),
                        AnymeXText(context.l10n.flashColor),
                        const Spacer(),
                        ChoiceChip(
                          label: AnymeXText(context.l10n.black),
                          selected:
                              controller.displayRefreshColor.value == 'black',
                          onSelected: (_) {
                            controller.displayRefreshColor.value = 'black';
                            controller.savePreferences();
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: AnymeXText(context.l10n.white),
                          selected:
                              controller.displayRefreshColor.value == 'white',
                          onSelected: (_) {
                            controller.displayRefreshColor.value = 'white';
                            controller.savePreferences();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                if (Platform.isAndroid) ...[
                  AnymeXTile.toggle(
                    icon: Iconsax.volume_high,
                    title: context.l10n.volumeKeysNavigation,
                    subtitle: context.l10n.useVolumeKeysToChangePages,
                    value: controller.volumeKeysEnabled.value,
                    onChanged: (_) => controller.toggleVolumeKeys(),
                  ),
                  AnymeXTile.toggle(
                    icon: Iconsax.arrow_swap_horizontal,
                    title: context.l10n.invertVolumeKeys,
                    subtitle: context.l10n.swapUpDownActions2,
                    value: controller.invertVolumeKeys.value,
                    onChanged: (val) {
                      controller.invertVolumeKeys.value = val;
                      controller.savePreferences();
                    },
                  ),
                ],
                if (controller.readingLayout.value ==
                    MangaPageViewMode.continuous) ...[
                  AnymeXTile.toggle(
                    icon: Icons.play_arrow_rounded,
                    title: context.l10n.autoScroll,
                    subtitle: context.l10n.automaticallyScrollAdvancePages,
                    value: controller.autoScrollEnabled.value,
                    onChanged: (_) => controller.toggleAutoScroll(),
                  ),
                  if (controller.autoScrollEnabled.value)
                    AnymeXTile.slider(
                      title: context.l10n.autoScrollSpeed,
                      icon: Icons.speed,
                      subtitle: context.l10n.secondsPerPageScreen,
                      value: controller.autoScrollSpeed.value,
                      min: 1.0,
                      max: 10.0,
                      divisions: 18,
                      onChanged: controller.setAutoScrollSpeed,
                    ),
                ],
              ],
            ),
            AnymeXSectionBuilder(
              margin: const EdgeInsets.only(bottom: 20),
              children: [
                AnymeXTile.slider(
                  title: context.l10n.preloadPages,
                  icon: Icons.image_aspect_ratio_rounded,
                  subtitle: context.l10n.pagesAheadOfTimeForFaster,
                  value: controller.preloadPages.value.toDouble(),
                  min: 1,
                  max: 15,
                  divisions: 14,
                  onChanged: (v) => controller.preloadPages.value = v.toInt(),
                ),
                if (!Platform.isAndroid && !Platform.isIOS) ...[
                  AnymeXTile.slider(
                    title: context.l10n.imageWidth,
                    icon: Icons.image_aspect_ratio_rounded,
                    subtitle: context.l10n.continuousModeOnly2,
                    value: controller.pageWidthMultiplier.value,
                    min: 1.0,
                    max: 2.5,
                    divisions: 15,
                    onChanged: (v) => controller.pageWidthMultiplier.value = v,
                  ),
                  AnymeXTile.slider(
                    title: context.l10n.scrollMultiplier,
                    icon: Icons.speed,
                    subtitle: context.l10n.keyVolumeScrollingSpeed,
                    value: controller.scrollSpeedMultiplier.value,
                    min: 1.0,
                    max: 5.0,
                    divisions: 9,
                    onChanged: (v) =>
                        controller.scrollSpeedMultiplier.value = v,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }

  void _showThemeDialog(BuildContext context, Settings settings) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: AnymeXText(context.l10n.controlTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReaderControlThemeRegistry.themes
              .map((t) => RadioListTile<String>(
                    title: AnymeXText(t.name),
                    value: t.id,
                    groupValue: settings.readerControlThemeRx.value,
                    onChanged: (id) {
                      if (id != null) settings.readerControlTheme = id;
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: AnymeXText(context.l10n.readerBackground),
        content: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<int>(
                    title: AnymeXText(context.l10n.white),
                    value: 0,
                    groupValue: controller.readerTheme.value,
                    onChanged: _setTheme),
                RadioListTile<int>(
                    title: AnymeXText(context.l10n.black),
                    value: 1,
                    groupValue: controller.readerTheme.value,
                    onChanged: _setTheme),
                RadioListTile<int>(
                    title: AnymeXText(context.l10n.gray),
                    value: 2,
                    groupValue: controller.readerTheme.value,
                    onChanged: _setTheme),
                RadioListTile<int>(
                    title: AnymeXText(context.l10n.automatic),
                    value: 3,
                    groupValue: controller.readerTheme.value,
                    onChanged: _setTheme),
              ],
            )),
      ),
    );
  }

  void _setTheme(int? v) {
    if (v != null) {
      controller.readerTheme.value = v;
      controller.savePreferences();
    }
    Get.back();
  }

  void _showFilterQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: AnymeXText(context.l10n.imageFilterQuality),
        content: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<int>(
                    title: AnymeXText(context.l10n.noneNearestNeighbor),
                    value: 0,
                    groupValue: controller.imageFilterQuality.value,
                    onChanged: _setFilterQuality),
                RadioListTile<int>(
                    title: AnymeXText(context.l10n.lowBilinear),
                    value: 1,
                    groupValue: controller.imageFilterQuality.value,
                    onChanged: _setFilterQuality),
                RadioListTile<int>(
                    title: AnymeXText(context.l10n.mediumDefault),
                    value: 2,
                    groupValue: controller.imageFilterQuality.value,
                    onChanged: _setFilterQuality),
                RadioListTile<int>(
                    title: AnymeXText(context.l10n.highBicubic),
                    value: 3,
                    groupValue: controller.imageFilterQuality.value,
                    onChanged: _setFilterQuality),
                RadioListTile<int>(
                    title: AnymeXText(
                        context.l10n.lanczosPreScaleBestQualitySlower),
                    value: 4,
                    groupValue: controller.imageFilterQuality.value,
                    onChanged: _setFilterQuality),
              ],
            )),
      ),
    );
  }

  void _setFilterQuality(int? v) {
    if (v != null) controller.setImageFilterQuality(v);
    Get.back();
  }
}
