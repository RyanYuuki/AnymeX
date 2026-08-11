import 'dart:io';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/color_filter_settings_page.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme_registry.dart';
import 'package:anymex/screens/settings/sub_settings/settings_tap_zones.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tabbar.dart';
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
    final maxH = MediaQuery.sizeOf(context).height * 0.8;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AnymeXText(
            text: 'Reader Settings',
            size: 18,
            variant: TextVariant.bold,
          ),
          const SizedBox(height: 10),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
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
            AnymeXTile(
              title: 'Layout',
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
              title: 'Direction',
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
            AnymeXTile(
              title: 'Dual Page Mode',
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
                title: 'Tap Zones',
                subtitle: 'Customize gestures',
                icon: Icons.touch_app_rounded,
                onTap: () {
                  Navigator.pop(context);
                  navigate(() => const TapZoneSettingsScreen());
                },
              ),
            AnymeXTile.toggle(
              icon: Iconsax.pharagraphspacing,
              title: 'Spaced Pages',
              subtitle: 'Continuous Mode only',
              value: controller.spacedPages.value,
              onChanged: (_) => controller.toggleSpacedPages(),
            ),
            AnymeXTile.toggle(
              icon: Iconsax.arrow,
              title: 'Overscroll',
              subtitle: 'To Prev/Next Chapter',
              value: controller.overscrollToChapter.value,
              onChanged: (_) => controller.toggleOverscrollToChapter(),
            ),
            AnymeXTile.toggle(
              icon: Icons.smartphone_rounded,
              title: 'Auto Webtoon Mode',
              subtitle:
                  'Automatically switch to continuous mode for long-strip manga',
              value: controller.autoWebtoonMode.value,
              onChanged: (_) => controller.toggleAutoWebtoonMode(),
            ),
            AnymeXTile.toggle(
              icon: Icons.onetwothree_rounded,
              title: 'Navigate by Number',
              subtitle: 'Always checks current chapter number and compares it with next/prev chapter, navigating only when the number is different. Navigate by Chapter will just move to the next item in the list even if there are duplicates.',
              value: controller.navigateByNumber.value,
              onChanged: (_) => controller.toggleNavigateByNumber(),
            ),
            AnymeXTile.toggle(
              icon: Icons.fullscreen_rounded,
              title: 'Fit to Screen Width',
              subtitle: 'Stretch images to fit screen width',
              value: controller.fitToScreen.value,
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
            AnymeXTile(
              title: 'Control Theme',
              subtitle: ReaderControlThemeRegistry.resolve(
                      settings.readerControlThemeRx.value)
                  .name,
              icon: Icons.style_rounded,
              onTap: () => _showThemeDialog(context, settings),
            ),
            AnymeXTile(
              title: 'Background',
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
              title: 'Image Filter Quality',
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
            AnymeXTile.toggle(
              icon: Iconsax.eye,
              title: 'Persistent Page Indicator',
              subtitle: 'Always show page indicator',
              value: controller.showPageIndicator.value,
              onChanged: (_) => controller.togglePageIndicator(),
            ),
            AnymeXTile.toggle(
              icon: Icons.crop_rounded,
              title: 'Crop Borders',
              subtitle: 'Remove white/black borders',
              value: controller.cropImages.value,
              onChanged: (_) => controller.toggleCropImages(),
            ),
            AnymeXTile.toggle(
              icon: Icons.screen_lock_rotation_rounded,
              title: 'Keep Screen On',
              subtitle: 'Prevent screen from sleeping while reading',
              value: controller.keepScreenOn.value,
              onChanged: (_) => controller.toggleKeepScreenOn(),
            ),
            AnymeXTile.toggle(
              icon: Icons.compare_arrows_rounded,
              title: 'Always Show Chapter Transition',
              subtitle:
                  'Show transition page even when chapters are adjacent',
              value: controller.alwaysShowChapterTransition.value,
              onChanged: (_) => controller.toggleAlwaysShowChapterTransition(),
            ),
            AnymeXTile.toggle(
              icon: Icons.touch_app_rounded,
              title: 'Long Press for Page Actions',
              subtitle: 'Long-press a page to save, share, or copy it',
              value: controller.longPressPageActionsEnabled.value,
              onChanged: (_) => controller.toggleLongPressPageActions(),
            ),
            AnymeXTile.toggle(
              icon: Icons.monitor_rounded,
              title: 'E-ink Display Refresh',
              subtitle: 'Flash screen on page turn to clear ghosting',
              value: controller.displayRefreshEnabled.value,
              onChanged: (_) => controller.toggleDisplayRefresh(),
            ),
            if (controller.displayRefreshEnabled.value) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AnymeXTile.slider(
                  title: 'Flash Duration',
                  icon: Icons.timer_rounded,
                  subtitle: 'Milliseconds',
                  value:
                      controller.displayRefreshDurationMs.value.toDouble(),
                  min: 50,
                  max: 500,
                  divisions: 18,
                  onChanged: (v) =>
                      controller.displayRefreshDurationMs.value = v.toInt(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AnymeXTile.slider(
                  title: 'Flash Every N Pages',
                  icon: Icons.refresh_rounded,
                  subtitle: 'Flash frequency',
                  value:
                      controller.displayRefreshInterval.value.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (v) =>
                      controller.displayRefreshInterval.value = v.toInt(),
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
              AnymeXTile.toggle(
                icon: Iconsax.volume_high,
                title: 'Volume Keys Navigation',
                subtitle: 'Use volume keys to change pages',
                value: controller.volumeKeysEnabled.value,
                onChanged: (_) => controller.toggleVolumeKeys(),
              ),
              AnymeXTile.toggle(
                icon: Iconsax.arrow_swap_horizontal,
                title: 'Invert Volume Keys',
                subtitle: 'Swap Up/Down actions',
                value: controller.invertVolumeKeys.value,
                onChanged: (val) {
                  controller.invertVolumeKeys.value = val;
                  controller.savePreferences();
                },
              ),
            ],
            if (controller.readingLayout.value == MangaPageViewMode.continuous) ...[
              AnymeXTile.toggle(
                icon: Icons.play_arrow_rounded,
                title: 'Auto Scroll',
                subtitle: 'Automatically scroll/advance pages',
                value: controller.autoScrollEnabled.value,
                onChanged: (_) => controller.toggleAutoScroll(),
              ),
              if (controller.autoScrollEnabled.value)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: AnymeXTile.slider(
                    title: 'Auto Scroll Speed',
                    icon: Icons.speed,
                    subtitle: 'Seconds per page / screen',
                    value: controller.autoScrollSpeed.value,
                    min: 1.0,
                    max: 10.0,
                    divisions: 18,
                    onChanged: controller.setAutoScrollSpeed,
                  ),
                ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: AnymeXTile.slider(
                title: 'Preload Pages',
                icon: Icons.image_aspect_ratio_rounded,
                subtitle: 'Pages ahead of time for faster loading',
                value: controller.preloadPages.value.toDouble(),
                min: 1,
                max: 15,
                divisions: 14,
                onChanged: (v) => controller.preloadPages.value = v.toInt(),
              ),
            ),
            if (!Platform.isAndroid && !Platform.isIOS) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AnymeXTile.slider(
                  title: 'Image Width',
                  icon: Icons.image_aspect_ratio_rounded,
                  subtitle: 'Continuous Mode only',
                  value: controller.pageWidthMultiplier.value,
                  min: 1.0,
                  max: 2.5,
                  divisions: 15,
                  onChanged: (v) => controller.pageWidthMultiplier.value = v,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AnymeXTile.slider(
                  title: 'Scroll Multiplier',
                  icon: Icons.speed,
                  subtitle: 'Key & Volume Scrolling Speed',
                  value: controller.scrollSpeedMultiplier.value,
                  min: 1.0,
                  max: 5.0,
                  divisions: 9,
                  onChanged: (v) => controller.scrollSpeedMultiplier.value = v,
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
