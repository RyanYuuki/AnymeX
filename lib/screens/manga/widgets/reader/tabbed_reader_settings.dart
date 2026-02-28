import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/color_filter_settings_page.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme_registry.dart';
import 'package:anymex/screens/settings/sub_settings/settings_tap_zones.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
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

  static const _tabs = [
    Tab(text: 'Reading Mode'),
    Tab(text: 'General'),
    Tab(text: 'Color Filter'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.82;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        color: context.colors.surface,
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: context.colors.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Reader Settings',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TabBar(
              controller: _tabController,
              tabs: _tabs,
              indicatorColor: context.colors.primary,
              labelColor: context.colors.primary,
              unselectedLabelColor: context.colors.onSurface.withOpacity(0.6),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ReadingModePage(controller: widget.controller),
                  _GeneralPage(
                      controller: widget.controller,
                      settings: widget.settings),
                  ColorFilterSettingsPage(controller: widget.controller),
                ],
              ),
            ),
          ],
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
              postFix: Row(
                spacing: 4,
                children: [
                  for (final layout in MangaPageViewMode.values)
                    IconButton.filled(
                      isSelected: layout == currentLayout,
                      style: _iconBtnStyle(context, layout == currentLayout),
                      tooltip: switch (layout) {
                        MangaPageViewMode.continuous => 'Continuous',
                        MangaPageViewMode.paged => 'Paged',
                      },
                      icon: switch (layout) {
                        MangaPageViewMode.continuous =>
                          const Icon(Iconsax.slider_vertical),
                        MangaPageViewMode.paged => const Icon(Iconsax.grid_9),
                      },
                      onPressed: () =>
                          controller.changeReadingLayout(layout),
                    )
                ],
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
              postFix: Row(
                spacing: 4,
                children: [
                  for (final dir in MangaPageViewDirection.values)
                    IconButton.filled(
                      isSelected: dir == currentDirection,
                      style: _iconBtnStyle(context, dir == currentDirection),
                      tooltip: switch (dir) {
                        MangaPageViewDirection.down => 'Top-Down',
                        MangaPageViewDirection.right => 'LTR',
                        MangaPageViewDirection.up => 'Bottom-Up',
                        MangaPageViewDirection.left => 'RTL',
                      },
                      icon: switch (dir) {
                        MangaPageViewDirection.down =>
                          const Icon(Iconsax.arrow_down),
                        MangaPageViewDirection.right =>
                          const Icon(Iconsax.arrow_right_1),
                        MangaPageViewDirection.up =>
                          const Icon(Iconsax.arrow_up_3),
                        MangaPageViewDirection.left =>
                          const Icon(Iconsax.arrow_left),
                      },
                      onPressed: () =>
                          controller.changeReadingDirection(dir),
                    )
                ],
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
              postFix: Row(
                spacing: 4,
                children: [
                  for (final mode in DualPageMode.values)
                    IconButton.filled(
                      isSelected: mode == currentDual,
                      style: _iconBtnStyle(context, mode == currentDual),
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
              description: 'Automatically switch to continuous mode for long-strip manga',
              switchValue: controller.autoWebtoonMode.value,
              onChanged: (_) => controller.toggleAutoWebtoonMode(),
            ),
          ],
        ),
      );
    });
  }

  ButtonStyle _iconBtnStyle(BuildContext context, bool selected) =>
      IconButton.styleFrom(
        backgroundColor: selected
            ? context.colors.primary.withOpacity(0.2)
            : context.colors.surfaceContainer,
        foregroundColor:
            selected ? context.colors.primary : Theme.of(context).iconTheme.color,
      );
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
              description: 'Show transition page even when chapters are adjacent',
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
            // E-ink display refresh
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
                  label:
                      '${controller.displayRefreshDurationMs.value}ms',
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
              // Flash color
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                onChanged: (v) =>
                    controller.preloadPages.value = v.toInt(),
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
                  onChanged: (v) =>
                      controller.pageWidthMultiplier.value = v,
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
                  onChanged: (v) =>
                      controller.scrollSpeedMultiplier.value = v,
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
}
