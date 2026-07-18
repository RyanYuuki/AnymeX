import 'dart:io';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/color_filter_settings_page.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme_registry.dart';
import 'package:anymex/screens/settings/sub_settings/settings_tap_zones.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/custom_widgets/anymex_tabbar.dart';
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TabbedSettingsSheet(
        controller: controller,
        settings: settings,
      ),
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

  static const _tabs = [
    Tab(text: 'Reading Mode'),
    Tab(text: 'General'),
    Tab(text: 'Color Filter'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _selectedIndex) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.82;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 16 + bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxH),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 3.5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                'Reader Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: AnymeXTabBar(
                  selectTabs: const ['Reading Mode', 'General', 'Color Filter'],
                  selectedIndex: _selectedIndex,
                  onTabSelected: (index) {
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
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
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
                        _ =>
                          ColorFilterSettingsPage(controller: widget.controller),
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            CustomTile(
              title: 'Layout',
              description: switch (currentLayout) {
                MangaPageViewMode.continuous => 'Continuous',
                MangaPageViewMode.paged => 'Paged',
              },
              icon: Iconsax.card,
              postFix: Container(
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
            CustomTile(
              title: 'Direction',
              description: switch (currentDirection) {
                MangaPageViewDirection.down => 'Top-Down',
                MangaPageViewDirection.right => 'LTR',
                MangaPageViewDirection.up => 'Bottom-Up',
                MangaPageViewDirection.left => 'RTL',
              },
              icon: Iconsax.direct_right,
              postFix: Container(
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
                            MangaPageViewDirection.down => Iconsax.arrow_down,
                            MangaPageViewDirection.right =>
                              Iconsax.arrow_right_1,
                            MangaPageViewDirection.up => Iconsax.arrow_up_3,
                            MangaPageViewDirection.left => Iconsax.arrow_left,
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
            CustomTile(
              title: 'Dual Page Mode',
              description: switch (currentDual) {
                DualPageMode.off => 'Standard (Single)',
                DualPageMode.auto => 'Auto (Landscape)',
                DualPageMode.force => 'Force (Always)',
              },
              icon: Iconsax.book_1,
              postFix: Container(
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
              CustomTile(
                title: 'Tap Zones',
                description: 'Customize gestures',
                icon: Icons.touch_app_rounded,
                onTap: () {
                  Navigator.pop(context);
                  navigate(() => const TapZoneSettingsScreen());
                },
              ),
            CustomSwitchTile(
              icon: Iconsax.pharagraphspacing,
              title: 'Spaced Pages',
              description: 'Continuous Mode only',
              switchValue: controller.spacedPages.value,
              onChanged: (_) => controller.toggleSpacedPages(),
            ),
            CustomSwitchTile(
              icon: Iconsax.arrow,
              title: 'Overscroll',
              description: 'To Prev/Next Chapter',
              switchValue: controller.overscrollToChapter.value,
              onChanged: (_) => controller.toggleOverscrollToChapter(),
            ),
            CustomSwitchTile(
              icon: Icons.smartphone_rounded,
              title: 'Auto Webtoon Mode',
              description:
                  'Automatically switch to continuous mode for long-strip manga',
              switchValue: controller.autoWebtoonMode.value,
              onChanged: (_) => controller.toggleAutoWebtoonMode(),
            ),
            CustomSwitchTile(
              icon: Icons.onetwothree_rounded,
              title: 'Navigate by Number',
              description: 'Always checks current chapter number and compares it with next/prev chapter, navigating only when the number is different. Navigate by Chapter will just move to the next item in the list even if there are duplicates.',
              switchValue: controller.navigateByNumber.value,
              onChanged: (_) => controller.toggleNavigateByNumber(),
            ),
            CustomSwitchTile(
              icon: Icons.fullscreen_rounded,
              title: 'Fit to Screen Width',
              description: 'Stretch images to fit screen width',
              switchValue: controller.fitToScreen.value,
              onChanged: (_) => controller.toggleFitToScreen(),
            ),
            20.height()
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            CustomTile(
              title: 'Control Theme',
              description: ReaderControlThemeRegistry.resolve(
                      settings.readerControlThemeRx.value)
                  .name,
              icon: Icons.style_rounded,
              onTap: () => _showThemeDialog(context, settings),
            ),
            CustomTile(
              title: 'Background',
              description: switch (controller.readerTheme.value) {
                0 => 'White',
                1 => 'Black',
                2 => 'Gray',
                _ => 'Automatic',
              },
              icon: Icons.format_paint_rounded,
              onTap: () => _showThemePicker(context),
            ),
            CustomTile(
              title: 'Image Filter Quality',
              description: switch (controller.imageFilterQuality.value) {
                0 => 'None (Nearest)',
                1 => 'Low (Bilinear)',
                3 => 'High (Bicubic)',
                4 => 'Lanczos Pre-scale (Best)',
                _ => 'Medium (Default)',
              },
              icon: Icons.image_search_rounded,
              onTap: () => _showFilterQualityDialog(context),
            ),
            CustomSwitchTile(
              icon: Iconsax.eye,
              title: 'Persistent Page Indicator',
              description: 'Always show page indicator',
              switchValue: controller.showPageIndicator.value,
              onChanged: (_) => controller.togglePageIndicator(),
            ),
            CustomSwitchTile(
              icon: Icons.crop_rounded,
              title: 'Crop Borders',
              description: 'Remove white/black borders',
              switchValue: controller.cropImages.value,
              onChanged: (_) => controller.toggleCropImages(),
            ),
            CustomSwitchTile(
              icon: Icons.screen_lock_rotation_rounded,
              title: 'Keep Screen On',
              description: 'Prevent screen from sleeping while reading',
              switchValue: controller.keepScreenOn.value,
              onChanged: (_) => controller.toggleKeepScreenOn(),
            ),
            CustomSwitchTile(
              icon: Icons.compare_arrows_rounded,
              title: 'Always Show Chapter Transition',
              description:
                  'Show transition page even when chapters are adjacent',
              switchValue: controller.alwaysShowChapterTransition.value,
              onChanged: (_) => controller.toggleAlwaysShowChapterTransition(),
            ),
            CustomSwitchTile(
              icon: Icons.touch_app_rounded,
              title: 'Long Press for Page Actions',
              description: 'Long-press a page to save, share, or copy it',
              switchValue: controller.longPressPageActionsEnabled.value,
              onChanged: (_) => controller.toggleLongPressPageActions(),
            ),
            CustomSwitchTile(
              icon: Icons.monitor_rounded,
              title: 'E-ink Display Refresh',
              description: 'Flash screen on page turn to clear ghosting',
              switchValue: controller.displayRefreshEnabled.value,
              onChanged: (_) => controller.toggleDisplayRefresh(),
            ),
            if (controller.displayRefreshEnabled.value) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: CustomSliderTile(
                  title: 'Flash Duration',
                  icon: Icons.timer_rounded,
                  description: 'Milliseconds',
                  sliderValue:
                      controller.displayRefreshDurationMs.value.toDouble(),
                  min: 50,
                  max: 500,
                  divisions: 18,
                  label: '${controller.displayRefreshDurationMs.value}ms',
                  onChanged: (v) =>
                      controller.displayRefreshDurationMs.value = v.toInt(),
                  onChangedEnd: (_) => controller.savePreferences(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: CustomSliderTile(
                  title: 'Flash Every N Pages',
                  icon: Icons.refresh_rounded,
                  description: 'Flash frequency',
                  sliderValue:
                      controller.displayRefreshInterval.value.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: controller.displayRefreshInterval.value.toString(),
                  onChanged: (v) =>
                      controller.displayRefreshInterval.value = v.toInt(),
                  onChangedEnd: (_) => controller.savePreferences(),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.palette_rounded, size: 20),
                    const SizedBox(width: 10),
                    const Text('Flash Color'),
                    const Spacer(),
                    ChoiceChip(
                      label: const Text('Black'),
                      selected: controller.displayRefreshColor.value == 'black',
                      onSelected: (_) {
                        controller.displayRefreshColor.value = 'black';
                        controller.savePreferences();
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('White'),
                      selected: controller.displayRefreshColor.value == 'white',
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
              CustomSwitchTile(
                icon: Iconsax.volume_high,
                title: 'Volume Keys Navigation',
                description: 'Use volume keys to change pages',
                switchValue: controller.volumeKeysEnabled.value,
                onChanged: (_) => controller.toggleVolumeKeys(),
              ),
              CustomSwitchTile(
                icon: Iconsax.arrow_swap_horizontal,
                title: 'Invert Volume Keys',
                description: 'Swap Up/Down actions',
                switchValue: controller.invertVolumeKeys.value,
                onChanged: (val) {
                  controller.invertVolumeKeys.value = val;
                  controller.savePreferences();
                },
              ),
            ],
            if (controller.readingLayout.value == MangaPageViewMode.continuous) ...[
              CustomSwitchTile(
                icon: Icons.play_arrow_rounded,
                title: 'Auto Scroll',
                description: 'Automatically scroll/advance pages',
                switchValue: controller.autoScrollEnabled.value,
                onChanged: (_) => controller.toggleAutoScroll(),
              ),
              if (controller.autoScrollEnabled.value)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: CustomSliderTile(
                    title: 'Auto Scroll Speed',
                    icon: Icons.speed,
                    description: 'Seconds per page / screen',
                    sliderValue: controller.autoScrollSpeed.value,
                    min: 1.0,
                    max: 10.0,
                    label:
                        '${controller.autoScrollSpeed.value.toStringAsFixed(1)}s',
                    divisions: 18,
                    onChanged: controller.setAutoScrollSpeed,
                    onChangedEnd: (_) => controller.savePreferences(),
                  ),
                ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CustomSliderTile(
                title: 'Preload Pages',
                icon: Icons.image_aspect_ratio_rounded,
                description: 'Pages ahead of time for faster loading',
                sliderValue: controller.preloadPages.value.toDouble(),
                min: 1,
                max: 15,
                label: controller.preloadPages.value.toString(),
                divisions: 14,
                onChanged: (v) => controller.preloadPages.value = v.toInt(),
                onChangedEnd: (_) => controller.savePreferences(),
              ),
            ),
            if (!Platform.isAndroid && !Platform.isIOS) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: CustomSliderTile(
                  title: 'Image Width',
                  icon: Icons.image_aspect_ratio_rounded,
                  description: 'Continuous Mode only',
                  sliderValue: controller.pageWidthMultiplier.value,
                  min: 1.0,
                  max: 2.5,
                  divisions: 15,
                  onChanged: (v) => controller.pageWidthMultiplier.value = v,
                  onChangedEnd: (_) => controller.savePreferences(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: CustomSliderTile(
                  title: 'Scroll Multiplier',
                  icon: Icons.speed,
                  description: 'Key & Volume Scrolling Speed',
                  sliderValue: controller.scrollSpeedMultiplier.value,
                  min: 1.0,
                  max: 5.0,
                  divisions: 9,
                  onChanged: (v) => controller.scrollSpeedMultiplier.value = v,
                  onChangedEnd: (_) => controller.savePreferences(),
                ),
              ),
            ],
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
        title: const Text('Control Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReaderControlThemeRegistry.themes
              .map((t) => RadioListTile<String>(
                    title: Text(t.name),
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
        title: const Text('Reader Background'),
        content: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<int>(
                    title: const Text('White'),
                    value: 0,
                    groupValue: controller.readerTheme.value,
                    onChanged: _setTheme),
                RadioListTile<int>(
                    title: const Text('Black'),
                    value: 1,
                    groupValue: controller.readerTheme.value,
                    onChanged: _setTheme),
                RadioListTile<int>(
                    title: const Text('Gray'),
                    value: 2,
                    groupValue: controller.readerTheme.value,
                    onChanged: _setTheme),
                RadioListTile<int>(
                    title: const Text('Automatic'),
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
        title: const Text('Image Filter Quality'),
        content: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<int>(
                    title: const Text('None (Nearest-neighbor)'),
                    value: 0,
                    groupValue: controller.imageFilterQuality.value,
                    onChanged: _setFilterQuality),
                RadioListTile<int>(
                    title: const Text('Low (Bilinear)'),
                    value: 1,
                    groupValue: controller.imageFilterQuality.value,
                    onChanged: _setFilterQuality),
                RadioListTile<int>(
                    title: const Text('Medium (Default)'),
                    value: 2,
                    groupValue: controller.imageFilterQuality.value,
                    onChanged: _setFilterQuality),
                RadioListTile<int>(
                    title: const Text('High (Bicubic)'),
                    value: 3,
                    groupValue: controller.imageFilterQuality.value,
                    onChanged: _setFilterQuality),
                RadioListTile<int>(
                    title:
                        const Text('Lanczos Pre-scale (Best quality, slower)'),
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
