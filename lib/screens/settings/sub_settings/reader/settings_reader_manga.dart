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
      title: 'Reading Layout',
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
      title: 'Reading Direction',
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
      title: 'Dual Page Mode',
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
      title: 'Image Filter Quality',
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
      title: 'Chapter Tile Style',
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
      headerTitle: 'Manga Reader',
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
                title: 'Layout & Direction',
                children: [
                  AnymeXTile(
                    icon: Iconsax.card,
                    title: 'Layout',
                    subtitle: _mangaLayout == 0 ? 'Continuous' : 'Paged',
                    onTap: _showMangaLayoutDialog,
                  ),
                  AnymeXTile(
                    icon: Iconsax.direct_right,
                    title: 'Direction',
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
                    title: 'Dual Page Mode',
                    subtitle: switch (_mangaDualPageMode) {
                      1 => 'Auto (Laptop/Tab)',
                      2 => 'Force (Dual)',
                      _ => 'Standard (Single)',
                    },
                    onTap: _showMangaDualPageDialog,
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.swap_vert_rounded,
                    title: 'Auto Webtoon Mode',
                    subtitle: 'Auto switch to vertical mode for webtoons',
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
                title: 'Image & Display',
                children: [
                  AnymeXTile(
                    icon: Icons.image_search_rounded,
                    title: 'Image Filter Quality',
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
                    title: 'Fit to Screen Width',
                    subtitle: 'Stretch images to fit screen width',
                    value: _mangaFitToScreen,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.fitToScreen,
                      value,
                      () => _mangaFitToScreen = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.crop_rounded,
                    title: 'Crop Borders',
                    subtitle: 'Remove white/black borders',
                    value: _mangaCropBorders,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.cropImages,
                      value,
                      () => _mangaCropBorders = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Iconsax.pharagraphspacing,
                    title: 'Spaced Pages',
                    subtitle: 'Continuous mode only',
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
                title: 'Interface & Session',
                children: [
                  Obx(
                    () => AnymeXTile(
                      icon: Icons.list_alt_rounded,
                      title: 'Chapter Tile Style',
                      subtitle: settings.chapterStyle == 'compact'
                          ? 'Compact'
                          : 'Detailed (Classic)',
                      onTap: _showChapterStyleDialog,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Iconsax.eye,
                    title: 'Persistent Page Indicator',
                    subtitle: 'Always show page indicator',
                    value: _mangaPageIndicator,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.showPageIndicator,
                      value,
                      () => _mangaPageIndicator = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Always Show Chapter Transition',
                    subtitle: 'Show chapter transition even without gaps',
                    value: _mangaChapterTransition,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.alwaysShowChapterTransition,
                      value,
                      () => _mangaChapterTransition = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.lock_clock_rounded,
                    title: 'Keep Screen On',
                    subtitle: 'Prevent screen from sleeping while reading',
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
                title: 'Manga Controls & Gestures',
                children: [
                  AnymeXTile.toggle(
                    icon: Iconsax.arrow,
                    title: 'Overscroll',
                    subtitle: 'Overscroll to previous/next chapter',
                    value: _mangaOverscroll,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.overscrollToChapter,
                      value,
                      () => _mangaOverscroll = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.touch_app_rounded,
                    title: 'Long Press Page Actions',
                    subtitle: 'Enable long press quick actions',
                    value: _mangaLongPressActions,
                    onChanged: (value) => _setReaderBool(
                      ReaderKeys.longPressPageActionsEnabled,
                      value,
                      () => _mangaLongPressActions = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.play_arrow_rounded,
                    title: 'Auto Scroll',
                    subtitle: 'Automatically scroll manga pages',
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
                      title: 'Auto Scroll Speed',
                      subtitle: 'Seconds per screen/page (lower is faster)',
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
                      title: 'Volume Keys Navigation',
                      subtitle: 'Use volume keys to change pages',
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
                      title: 'Invert Volume Keys',
                      subtitle: 'Swap volume up/down actions',
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
