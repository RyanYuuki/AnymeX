import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/l10n/l10n_extension.dart';

class SettingsReaderManga extends StatefulWidget {
  const SettingsReaderManga({super.key});

  @override
  State<SettingsReaderManga> createState() => _SettingsReaderMangaState();
}

class _SettingsReaderMangaState extends State<SettingsReaderManga> {
  final settings = Get.find<Settings>();

  int _mangaLayout = ReaderKeys.readingLayout.get<int>(0);
  int _mangaDirection = ReaderKeys.readingDirection.get<int>(1);
  int _mangaDualPageMode = ReaderKeys.dualPageMode.get<int>(0);
  int _mangaFilterQuality = ReaderKeys.imageFilterQuality.get<int>(2);
  bool _mangaSpacedPages = ReaderKeys.spacedPages.get<bool>(false);
  bool _mangaPageIndicator = ReaderKeys.showPageIndicator.get<bool>(false);
  bool _mangaCropBorders = ReaderKeys.cropImages.get<bool>(false);
  bool _mangaFitToScreen = ReaderKeys.fitToScreen.get<bool>(false);
  bool _mangaKeepScreenOn = ReaderKeys.keepScreenOn.get<bool>(true);
  bool _mangaAutoWebtoon = ReaderKeys.autoWebtoonMode.get<bool>(false);
  bool _mangaChapterTransition =
      ReaderKeys.alwaysShowChapterTransition.get<bool>(false);
  bool _mangaOverscroll = ReaderKeys.overscrollToChapter.get<bool>(true);
  bool _mangaLongPressActions =
      ReaderKeys.longPressPageActionsEnabled.get<bool>(true);
  bool _mangaAutoScroll = ReaderKeys.autoScrollEnabled.get<bool>(false);
  double _mangaAutoScrollSpeed = ReaderKeys.autoScrollSpeed.get<double>(3.0);
  bool _mangaVolumeKeys = ReaderKeys.volumeKeysEnabled.get<bool>(false);
  bool _mangaInvertVolumeKeys = ReaderKeys.invertVolumeKeys.get<bool>(false);

  void _setReaderBool(ReaderKeys key, bool value, void Function() update) {
    setState(() {
      update();
      key.set(value);
    });
  }

  void _showMangaLayoutDialog() {
    showSelectionDialog<int>(
      title: context.l10n.readingLayout,
      items: const [0, 1],
      selectedItem: _mangaLayout.obs,
      getTitle: (value) => value == 0 ? 'Continuous' : 'Paged',
      onItemSelected: (value) {
        setState(() {
          _mangaLayout = value;
          ReaderKeys.readingLayout.set(value);
        });
      },
      leadingIcon: Iconsax.card,
    );
  }

  void _showMangaDirectionDialog() {
    showSelectionDialog<int>(
      title: context.l10n.readingDirection,
      items: const [0, 1, 2, 3],
      selectedItem: _mangaDirection.obs,
      getTitle: (value) => switch (value) {
        0 => 'Bottom-Up',
        1 => 'Top-Down',
        2 => 'RTL',
        _ => 'LTR',
      },
      onItemSelected: (value) {
        setState(() {
          _mangaDirection = value;
          ReaderKeys.readingDirection.set(value);
        });
      },
      leadingIcon: Iconsax.direct_right,
    );
  }

  void _showMangaDualPageDialog() {
    showSelectionDialog<int>(
      title: context.l10n.dualPageMode,
      items: const [0, 1, 2],
      selectedItem: _mangaDualPageMode.obs,
      getTitle: (value) => switch (value) {
        1 => 'Auto (Laptop/Tab)',
        2 => 'Force (Dual)',
        _ => 'Standard (Single)',
      },
      onItemSelected: (value) {
        setState(() {
          _mangaDualPageMode = value;
          ReaderKeys.dualPageMode.set(value);
        });
      },
      leadingIcon: Iconsax.book_1,
    );
  }

  void _showMangaFilterQualityDialog() {
    showSelectionDialog<int>(
      title: context.l10n.imageFilterQuality,
      items: const [0, 1, 2, 3, 4],
      selectedItem: _mangaFilterQuality.obs,
      getTitle: (value) => switch (value) {
        0 => 'None (Nearest-neighbor)',
        1 => 'Low (Bilinear)',
        3 => 'High (Bicubic)',
        4 => 'Lanczos Pre-scale (Best quality, slower)',
        _ => 'Medium (Default)',
      },
      onItemSelected: (value) {
        setState(() {
          _mangaFilterQuality = value;
          ReaderKeys.imageFilterQuality.set(value);
        });
      },
      leadingIcon: Icons.image_search_rounded,
    );
  }

  void _showChapterStyleDialog() {
    showSelectionDialog<String>(
      title: context.l10n.chapterTileStyle,
      items: const ['compact', 'detailed'],
      selectedItem: settings.chapterStyleRx,
      getTitle: (value) =>
          value == 'compact' ? 'Compact' : 'Detailed (Classic)',
      onItemSelected: (value) {
        setState(() {
          settings.chapterStyle = value;
        });
      },
      leadingIcon: Icons.list_alt_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: context.l10n.mangaReader,
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16.0,
            AnymeXHeaderScope.of(ctx),
            16.0,
            30.0,
          ),
          child: Column(
            children: [
              AnymeXSectionBuilder(
                title: context.l10n.layoutDirection,
                children: [
                  AnymeXTile(
                    icon: Iconsax.card,
                    title: context.l10n.layout,
                    subtitle: _mangaLayout == 0 ? 'Continuous' : 'Paged',
                    onTap: _showMangaLayoutDialog,
                  ),
                  AnymeXTile(
                    icon: Iconsax.direct_right,
                    title: context.l10n.direction,
                    subtitle: switch (_mangaDirection) {
                      0 => 'Bottom-Up',
                      1 => 'Top-Down',
                      2 => 'RTL',
                      _ => 'LTR',
                    },
                    onTap: _showMangaDirectionDialog,
                  ),
                  AnymeXTile(
                    icon: Iconsax.book_1,
                    title: context.l10n.dualPageMode,
                    subtitle: switch (_mangaDualPageMode) {
                      1 => 'Auto (Laptop/Tab)',
                      2 => 'Force (Dual)',
                      _ => 'Standard (Single)',
                    },
                    onTap: _showMangaDualPageDialog,
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.swap_vert_rounded,
                    title: context.l10n.autoWebtoonMode,
                    subtitle: context.l10n.autoSwitchToVerticalModeFor,
                    value: _mangaAutoWebtoon,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.autoWebtoonMode,
                      value,
                      () => _mangaAutoWebtoon = value,
                    ),
                  ),
                ],
              ),
              AnymeXSectionBuilder(
                title: context.l10n.imageDisplay,
                children: [
                  AnymeXTile(
                    icon: Icons.image_search_rounded,
                    title: context.l10n.imageFilterQuality,
                    subtitle: switch (_mangaFilterQuality) {
                      0 => 'None (Nearest)',
                      1 => 'Low (Bilinear)',
                      3 => 'High (Bicubic)',
                      4 => 'Lanczos Pre-scale (Best)',
                      _ => 'Medium (Default)',
                    },
                    onTap: _showMangaFilterQualityDialog,
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.fullscreen_rounded,
                    title: context.l10n.fitToScreenWidth,
                    subtitle: context.l10n.stretchImagesToFitScreenWidth,
                    value: _mangaFitToScreen,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.fitToScreen,
                      value,
                      () => _mangaFitToScreen = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.crop_rounded,
                    title: context.l10n.cropBorders,
                    subtitle: context.l10n.removeWhiteBlackBorders,
                    value: _mangaCropBorders,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.cropImages,
                      value,
                      () => _mangaCropBorders = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Iconsax.pharagraphspacing,
                    title: context.l10n.spacedPages,
                    subtitle: context.l10n.continuousModeOnly,
                    value: _mangaSpacedPages,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.spacedPages,
                      value,
                      () => _mangaSpacedPages = value,
                    ),
                  ),
                ],
              ),
              AnymeXSectionBuilder(
                title: context.l10n.interfaceSession,
                children: [
                  Obx(
                    () => AnymeXTile(
                      icon: Icons.list_alt_rounded,
                      title: context.l10n.chapterTileStyle,
                      subtitle: settings.chapterStyle == 'compact'
                          ? 'Compact'
                          : 'Detailed (Classic)',
                      onTap: _showChapterStyleDialog,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Iconsax.eye,
                    title: context.l10n.persistentPageIndicator,
                    subtitle: context.l10n.alwaysShowPageIndicator,
                    value: _mangaPageIndicator,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.showPageIndicator,
                      value,
                      () => _mangaPageIndicator = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.swap_horiz_rounded,
                    title: context.l10n.alwaysShowChapterTransition,
                    subtitle: context.l10n.showChapterTransitionEvenWithoutGaps,
                    value: _mangaChapterTransition,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.alwaysShowChapterTransition,
                      value,
                      () => _mangaChapterTransition = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.lock_clock_rounded,
                    title: context.l10n.keepScreenOn,
                    subtitle: context.l10n.preventScreenFromSleepingWhileReading,
                    value: _mangaKeepScreenOn,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.keepScreenOn,
                      value,
                      () => _mangaKeepScreenOn = value,
                    ),
                  ),
                ],
              ),
              AnymeXSectionBuilder(
                title: context.l10n.mangaControlsGestures,
                children: [
                  AnymeXTile.toggle(
                    icon: Iconsax.arrow,
                    title: context.l10n.overscroll,
                    subtitle: context.l10n.overscrollToPreviousNextChapter,
                    value: _mangaOverscroll,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.overscrollToChapter,
                      value,
                      () => _mangaOverscroll = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.touch_app_rounded,
                    title: context.l10n.longPressPageActions,
                    subtitle: context.l10n.enableLongPressQuickActions,
                    value: _mangaLongPressActions,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.longPressPageActionsEnabled,
                      value,
                      () => _mangaLongPressActions = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.play_arrow_rounded,
                    title: context.l10n.autoScroll,
                    subtitle: context.l10n.automaticallyScrollMangaPages,
                    value: _mangaAutoScroll,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.autoScrollEnabled,
                      value,
                      () => _mangaAutoScroll = value,
                    ),
                  ),
                  if (_mangaAutoScroll)
                    AnymeXTile.slider(
                      icon: Icons.speed_rounded,
                      title: context.l10n.autoScrollSpeed,
                      subtitle: context.l10n.secondsPerScreenPageLowerIs,
                      value: _mangaAutoScrollSpeed,
                      min: 1.0,
                      max: 10.0,
                      divisions: 18,
                      onChanged: (value) {
                        setState(() => _mangaAutoScrollSpeed = value);
                        ReaderKeys.autoScrollSpeed.set(value);
                      },
                    ),
                  if (Platform.isAndroid)
                    AnymeXTile.toggle(
                      icon: Iconsax.volume_high,
                      title: context.l10n.volumeKeysNavigation,
                      subtitle: context.l10n.useVolumeKeysToChangePages,
                      value: _mangaVolumeKeys,
                      onChanged: (value) => _setReaderBool(
                        ReaderKeys.volumeKeysEnabled,
                        value,
                        () => _mangaVolumeKeys = value,
                      ),
                    ),
                  if (Platform.isAndroid)
                    AnymeXTile.toggle(
                      icon: Iconsax.arrow_swap_horizontal,
                      title: context.l10n.invertVolumeKeys,
                      subtitle: context.l10n.swapVolumeUpDownActions,
                      value: _mangaInvertVolumeKeys,
                      onChanged: (value) => _setReaderBool(
                        ReaderKeys.invertVolumeKeys,
                        value,
                        () => _mangaInvertVolumeKeys = value,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
