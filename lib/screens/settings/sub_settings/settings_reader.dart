import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme_registry.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';

class SettingsReader extends StatefulWidget {
  const SettingsReader({super.key});

  @override
  State<SettingsReader> createState() => _SettingsReaderState();
}

class _SettingsReaderState extends State<SettingsReader> {
  final settings = Get.find<Settings>();

  int _mangaLayout = ReaderKeys.readingLayout.get<int>(0);
  int _mangaDirection = ReaderKeys.readingDirection.get<int>(1);
  int _mangaDualPageMode = ReaderKeys.dualPageMode.get<int>(0);
  bool _mangaSpacedPages = ReaderKeys.spacedPages.get<bool>(false);
  bool _mangaOverscroll = ReaderKeys.overscrollToChapter.get<bool>(true);
  bool _mangaPageIndicator = ReaderKeys.showPageIndicator.get<bool>(false);
  bool _mangaCropBorders = ReaderKeys.cropImages.get<bool>(false);
  bool _mangaFitToScreen = ReaderKeys.fitToScreen.get<bool>(false);
  bool _mangaAutoScroll = ReaderKeys.autoScrollEnabled.get<bool>(false);
  double _mangaAutoScrollSpeed = ReaderKeys.autoScrollSpeed.get<double>(3.0);
  bool _mangaVolumeKeys = ReaderKeys.volumeKeysEnabled.get<bool>(false);
  bool _mangaInvertVolumeKeys = ReaderKeys.invertVolumeKeys.get<bool>(false);
  bool _mangaKeepScreenOn = ReaderKeys.keepScreenOn.get<bool>(true);
  bool _mangaChapterTransition =
      ReaderKeys.alwaysShowChapterTransition.get<bool>(false);
  bool _mangaLongPressActions =
      ReaderKeys.longPressPageActionsEnabled.get<bool>(true);
  bool _mangaAutoWebtoon = ReaderKeys.autoWebtoonMode.get<bool>(false);
  int _mangaFilterQuality = ReaderKeys.imageFilterQuality.get<int>(2);

  int _novelThemeMode = NovelReaderKeys.themeMode.get<int>(3);
  double _novelBackgroundOpacity =
      NovelReaderKeys.backgroundOpacity.get<double>(1.0);
  String _novelFontFamily = NovelReaderKeys.fontFamily.get<String>('System');
  double _novelFontSize = NovelReaderKeys.fontSize.get<double>(16.0);
  double _novelLineHeight = NovelReaderKeys.lineHeight.get<double>(1.6);
  double _novelLetterSpacing = NovelReaderKeys.letterSpacing.get<double>(0.0);
  double _novelWordSpacing = NovelReaderKeys.wordSpacing.get<double>(0.0);
  double _novelParagraphSpacing =
      NovelReaderKeys.paragraphSpacing.get<double>(16.0);
  bool _novelPageReaderMode = NovelReaderKeys.pageReader.get<bool>(false);
  bool _novelAutoScroll = NovelReaderKeys.autoScroll.get<bool>(false);
  double _novelAutoScrollSpeed =
      NovelReaderKeys.autoScrollSpeed.get<double>(3.0);
  bool _novelVolumeScrolling = NovelReaderKeys.volumeScrolling.get<bool>(false);
  bool _novelTapToScroll = NovelReaderKeys.tapToScroll.get<bool>(false);
  bool _novelKeepScreenOn = NovelReaderKeys.keepScreenOn.get<bool>(true);
  bool _novelSwipeGestures = NovelReaderKeys.swipeGestures.get<bool>(true);
  bool _novelReadingProgress =
      NovelReaderKeys.showReadingProgress.get<bool>(true);
  bool _novelBatteryTime = NovelReaderKeys.showBatteryTime.get<bool>(true);
  bool _novelTtsEnabled = NovelReaderKeys.ttsEnabled.get<bool>(false);
  double _novelTtsSpeed = NovelReaderKeys.ttsSpeed.get<double>(0.5);
  double _novelTtsPitch = NovelReaderKeys.ttsPitch.get<double>(1.0);
  bool _novelTtsAutoAdvance = NovelReaderKeys.ttsAutoAdvance.get<bool>(true);

  static const List<String> _novelFonts = [
    'System',
    'Serif',
    'Roboto',
    'Open Sans',
    'Lato',
    'Merriweather',
    'Crimson Text',
    'Libre Baskerville',
  ];

  void _setReaderBool(ReaderKeys key, bool value, void Function() update) {
    setState(() {
      update();
      key.set(value);
    });
  }

  void _setNovelBool(NovelReaderKeys key, bool value, void Function() update) {
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
      getTitle: (value) {
        switch (value) {
          case 0:
            return 'Bottom-Up';
          case 1:
            return 'Top-Down';
          case 2:
            return 'RTL';
          default:
            return 'LTR';
        }
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
      getTitle: (value) {
        switch (value) {
          case 1:
            return 'Auto (Laptop/Tab)';
          case 2:
            return 'Force (Dual)';
          default:
            return 'Standard (Single)';
        }
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
      getTitle: (value) {
        switch (value) {
          case 0:
            return 'None (Nearest-neighbor)';
          case 1:
            return 'Low (Bilinear)';
          case 3:
            return 'High (Bicubic)';
          case 4:
            return 'Lanczos Pre-scale (Best quality, slower)';
          default:
            return 'Medium (Default)';
        }
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

  void _showNovelThemeDialog() {
    showSelectionDialog<int>(
      title: 'Novel Theme',
      items: const [0, 1, 2, 3],
      selectedItem: _novelThemeMode.obs,
      getTitle: (value) {
        switch (value) {
          case 0:
            return 'Light';
          case 1:
            return 'Dark';
          case 2:
            return 'Sepia';
          default:
            return 'System';
        }
      },
      onItemSelected: (value) {
        setState(() {
          _novelThemeMode = value;
          NovelReaderKeys.themeMode.set(value);
        });
      },
      leadingIcon: Icons.palette_rounded,
    );
  }

  void _showNovelFontDialog() {
    showSelectionDialog<String>(
      title: 'Novel Font Family',
      items: _novelFonts,
      selectedItem: _novelFontFamily.obs,
      getTitle: (value) => value,
      onItemSelected: (value) {
        setState(() {
          _novelFontFamily = value;
          NovelReaderKeys.fontFamily.set(value);
        });
      },
      leadingIcon: HugeIcons.strokeRoundedTextFont,
    );
  }

  void _showReaderControlThemeDialog() {
    showSelectionDialog<String>(
      title: 'Reader Control Theme',
      items: ReaderControlThemeRegistry.themes.map((e) => e.id).toList(),
      selectedItem: settings.readerControlThemeRx,
      getTitle: (id) => ReaderControlThemeRegistry.resolve(id).name,
      onItemSelected: (id) {
        settings.readerControlTheme = id;
        setState(() {});
      },
      leadingIcon: Icons.style_rounded,
    );
  }

  void _resetNovelDefaults() {
    setState(() {
      _novelThemeMode = 3;
      _novelBackgroundOpacity = 1.0;
      _novelFontFamily = 'System';
      _novelFontSize = 16.0;
      _novelLineHeight = 1.6;
      _novelLetterSpacing = 0.0;
      _novelWordSpacing = 0.0;
      _novelParagraphSpacing = 16.0;
      _novelPageReaderMode = false;
      _novelAutoScroll = false;
      _novelAutoScrollSpeed = 3.0;
      _novelVolumeScrolling = false;
      _novelTapToScroll = false;
      _novelKeepScreenOn = true;
      _novelSwipeGestures = true;
      _novelReadingProgress = true;
      _novelBatteryTime = true;
      _novelTtsEnabled = false;
      _novelTtsSpeed = 0.5;
      _novelTtsPitch = 1.0;
      _novelTtsAutoAdvance = true;
    });

    NovelReaderKeys.themeMode.set(_novelThemeMode);
    NovelReaderKeys.backgroundOpacity.set(_novelBackgroundOpacity);
    NovelReaderKeys.fontFamily.set(_novelFontFamily);
    NovelReaderKeys.fontSize.set(_novelFontSize);
    NovelReaderKeys.lineHeight.set(_novelLineHeight);
    NovelReaderKeys.letterSpacing.set(_novelLetterSpacing);
    NovelReaderKeys.wordSpacing.set(_novelWordSpacing);
    NovelReaderKeys.paragraphSpacing.set(_novelParagraphSpacing);
    NovelReaderKeys.pageReader.set(_novelPageReaderMode);
    NovelReaderKeys.autoScroll.set(_novelAutoScroll);
    NovelReaderKeys.autoScrollSpeed.set(_novelAutoScrollSpeed);
    NovelReaderKeys.volumeScrolling.set(_novelVolumeScrolling);
    NovelReaderKeys.tapToScroll.set(_novelTapToScroll);
    NovelReaderKeys.keepScreenOn.set(_novelKeepScreenOn);
    NovelReaderKeys.swipeGestures.set(_novelSwipeGestures);
    NovelReaderKeys.showReadingProgress.set(_novelReadingProgress);
    NovelReaderKeys.showBatteryTime.set(_novelBatteryTime);
    NovelReaderKeys.ttsEnabled.set(_novelTtsEnabled);
    NovelReaderKeys.ttsSpeed.set(_novelTtsSpeed);
    NovelReaderKeys.ttsPitch.set(_novelTtsPitch);
    NovelReaderKeys.ttsAutoAdvance.set(_novelTtsAutoAdvance);
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Reader Settings',
      body: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 30.0),
                  child: Column(
                    children: [
                      AnymeXSectionBuilder(
                        title: 'Manga',
                        children: [
                          AnymeXTile(
                            icon: Icons.style_rounded,
                            title: 'Control Theme',
                            subtitle: ReaderControlThemeRegistry.resolve(
                                    settings.readerControlTheme)
                                .name,
                            onTap: _showReaderControlThemeDialog,
                          ),
                          AnymeXTile(
                            icon: Iconsax.card,
                            title: 'Layout',
                            subtitle:
                                _mangaLayout == 0 ? 'Continuous' : 'Paged',
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
                          AnymeXTile.toggle(
                            icon: Iconsax.arrow,
                            title: 'Overscroll',
                            subtitle: 'Overscroll to prev/next chapter',
                            value: _mangaOverscroll,
                            onChanged: (value) => _setReaderBool(
                              ReaderKeys.overscrollToChapter,
                              value,
                              () => _mangaOverscroll = value,
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
                            icon: Icons.play_arrow_rounded,
                            title: 'Auto Scroll',
                            subtitle: 'Automatically scroll pages',
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
                              subtitle:
                                  'Seconds per screen/page (lower is faster)',
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
                              subtitle: 'Swap up/down actions',
                              value: _mangaInvertVolumeKeys,
                              onChanged: (value) => _setReaderBool(
                                ReaderKeys.invertVolumeKeys,
                                value,
                                () => _mangaInvertVolumeKeys = value,
                              ),
                            ),
                          AnymeXTile.toggle(
                            icon: Icons.lock_clock_rounded,
                            title: 'Keep Screen On',
                            subtitle: 'Prevent screen from sleeping',
                            value: _mangaKeepScreenOn,
                            onChanged: (value) => _setReaderBool(
                              ReaderKeys.keepScreenOn,
                              value,
                              () => _mangaKeepScreenOn = value,
                            ),
                          ),
                          AnymeXTile.toggle(
                            icon: Icons.swap_vert_rounded,
                            title: 'Auto Webtoon Mode',
                            subtitle: 'Auto switch to vertical mode',
                            value: _mangaAutoWebtoon,
                            onChanged: (value) => _setReaderBool(
                              ReaderKeys.autoWebtoonMode,
                              value,
                              () => _mangaAutoWebtoon = value,
                            ),
                          ),
                          AnymeXTile.toggle(
                            icon: Icons.swap_horiz_rounded,
                            title: 'Always Show Chapter Transition',
                            subtitle:
                                'Show chapter transition even without gaps',
                            value: _mangaChapterTransition,
                            onChanged: (value) => _setReaderBool(
                              ReaderKeys.alwaysShowChapterTransition,
                              value,
                              () => _mangaChapterTransition = value,
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
                        ],
                      ),
                      AnymeXSectionBuilder(
                        title: 'Novel',
                        children: [
                          AnymeXTile(
                            icon: Icons.palette_rounded,
                            title: 'Theme',
                            subtitle: switch (_novelThemeMode) {
                              0 => 'Light',
                              1 => 'Dark',
                              2 => 'Sepia',
                              _ => 'System',
                            },
                            onTap: _showNovelThemeDialog,
                          ),
                          AnymeXTile(
                            icon: HugeIcons.strokeRoundedTextFont,
                            title: 'Font Family',
                            subtitle: _novelFontFamily,
                            onTap: _showNovelFontDialog,
                          ),
                          AnymeXTile.slider(
                            icon: Icons.format_size_rounded,
                            title: 'Font Size',
                            subtitle: 'Text size',
                            value: _novelFontSize,
                            min: 12,
                            max: 24,
                            divisions: 12,
                            onChanged: (value) {
                              setState(() => _novelFontSize =
                                  value.clamp(12.0, 24.0).toDouble());
                              NovelReaderKeys.fontSize.set(_novelFontSize);
                            },
                          ),
                          AnymeXTile.slider(
                            icon: Icons.height_rounded,
                            title: 'Line Height',
                            subtitle: 'Distance between lines',
                            value: _novelLineHeight,
                            min: 1.0,
                            max: 3.0,
                            divisions: 20,
                            onChanged: (value) {
                              setState(() => _novelLineHeight =
                                  value.clamp(1.0, 3.0).toDouble());
                              NovelReaderKeys.lineHeight.set(_novelLineHeight);
                            },
                          ),
                          AnymeXTile.slider(
                            icon: Icons.opacity_rounded,
                            title: 'Background Opacity',
                            subtitle: 'Reader background opacity',
                            value: _novelBackgroundOpacity,
                            min: 0.3,
                            max: 1.0,
                            divisions: 7,
                            onChanged: (value) {
                              setState(() => _novelBackgroundOpacity =
                                  value.clamp(0.3, 1.0).toDouble());
                              NovelReaderKeys.backgroundOpacity
                                  .set(_novelBackgroundOpacity);
                            },
                          ),
                          AnymeXTile.slider(
                            icon: Icons.text_fields_rounded,
                            title: 'Letter Spacing',
                            subtitle: 'Space between letters',
                            value: _novelLetterSpacing,
                            min: -1.0,
                            max: 2.0,
                            divisions: 30,
                            onChanged: (value) {
                              setState(() => _novelLetterSpacing =
                                  value.clamp(-1.0, 2.0).toDouble());
                              NovelReaderKeys.letterSpacing
                                  .set(_novelLetterSpacing);
                            },
                          ),
                          AnymeXTile.slider(
                            icon: Icons.text_rotation_none_rounded,
                            title: 'Word Spacing',
                            subtitle: 'Space between words',
                            value: _novelWordSpacing,
                            min: 0.0,
                            max: 5.0,
                            divisions: 25,
                            onChanged: (value) {
                              setState(() => _novelWordSpacing =
                                  value.clamp(0.0, 5.0).toDouble());
                              NovelReaderKeys.wordSpacing
                                  .set(_novelWordSpacing);
                            },
                          ),
                          AnymeXTile.slider(
                            icon: Icons.format_line_spacing_rounded,
                            title: 'Paragraph Spacing',
                            subtitle: 'Space between paragraphs',
                            value: _novelParagraphSpacing,
                            min: 8.0,
                            max: 32.0,
                            divisions: 12,
                            onChanged: (value) {
                              setState(() => _novelParagraphSpacing =
                                  value.clamp(8.0, 32.0).toDouble());
                              NovelReaderKeys.paragraphSpacing
                                  .set(_novelParagraphSpacing);
                            },
                          ),
                          AnymeXTile.toggle(
                            icon: Icons.chrome_reader_mode_rounded,
                            title: 'Page Reader Mode',
                            subtitle: 'Read one page at a time',
                            value: _novelPageReaderMode,
                            onChanged: (value) => _setNovelBool(
                              NovelReaderKeys.pageReader,
                              value,
                              () => _novelPageReaderMode = value,
                            ),
                          ),
                          AnymeXTile.toggle(
                            icon: Icons.play_arrow_rounded,
                            title: 'Auto Scroll',
                            subtitle: 'Automatically scroll content',
                            value: _novelAutoScroll,
                            onChanged: (value) => _setNovelBool(
                              NovelReaderKeys.autoScroll,
                              value,
                              () => _novelAutoScroll = value,
                            ),
                          ),
                          if (_novelAutoScroll)
                            AnymeXTile.slider(
                              icon: Icons.speed_rounded,
                              title: 'Auto Scroll Speed',
                              subtitle:
                                  'Seconds per screen (lower is faster)',
                              value: _novelAutoScrollSpeed,
                              min: 1.0,
                              max: 10.0,
                              divisions: 18,
                              onChanged: (value) {
                                setState(() => _novelAutoScrollSpeed =
                                    value.clamp(1.0, 10.0).toDouble());
                                NovelReaderKeys.autoScrollSpeed
                                    .set(_novelAutoScrollSpeed);
                              },
                            ),
                          if (_novelTtsEnabled)
                            AnymeXTile.toggle(
                              icon: Icons.skip_next_rounded,
                              title: 'TTS Auto Advance',
                              subtitle:
                                  'Automatically move to next text segment',
                              value: _novelTtsAutoAdvance,
                              onChanged: (value) => _setNovelBool(
                                NovelReaderKeys.ttsAutoAdvance,
                                value,
                                () => _novelTtsAutoAdvance = value,
                              ),
                            ),
                          AnymeXTile(
                            icon: Icons.restart_alt_rounded,
                            title: 'Reset Novel Reader Settings',
                            subtitle: 'Restore all novel reader defaults',
                            onTap: _resetNovelDefaults,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
    );
  }
}
