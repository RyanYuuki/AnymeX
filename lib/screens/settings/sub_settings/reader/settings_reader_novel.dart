import 'dart:io';

import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/l10n/l10n_extension.dart';

class SettingsReaderNovel extends StatefulWidget {
  const SettingsReaderNovel({super.key});

  @override
  State<SettingsReaderNovel> createState() => _SettingsReaderNovelState();
}

class _SettingsReaderNovelState extends State<SettingsReaderNovel> {
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
  bool _novelKeepScreenOn = NovelReaderKeys.keepScreenOn.get<bool>(true);
  bool _novelReadingProgress =
      NovelReaderKeys.showReadingProgress.get<bool>(true);
  bool _novelBatteryTime = NovelReaderKeys.showBatteryTime.get<bool>(true);
  bool _novelTtsEnabled = NovelReaderKeys.ttsEnabled.get<bool>(false);
  double _novelTtsSpeed = NovelReaderKeys.ttsSpeed.get<double>(0.5);
  double _novelTtsPitch = NovelReaderKeys.ttsPitch.get<double>(1.0);
  bool _novelTtsAutoAdvance = NovelReaderKeys.ttsAutoAdvance.get<bool>(true);
  bool _novelTapToScroll = NovelReaderKeys.tapToScroll.get<bool>(false);
  bool _novelSwipeGestures = NovelReaderKeys.swipeGestures.get<bool>(true);
  bool _novelVolumeScrolling = NovelReaderKeys.volumeScrolling.get<bool>(false);
  bool _novelAutoScroll = NovelReaderKeys.autoScroll.get<bool>(false);
  double _novelAutoScrollSpeed =
      NovelReaderKeys.autoScrollSpeed.get<double>(3.0);

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

  void _setNovelBool(NovelReaderKeys key, bool value, void Function() update) {
    setState(() {
      update();
      key.set(value);
    });
  }

  void _showNovelThemeDialog() {
    showSelectionDialog<int>(
      title: context.l10n.novelTheme,
      items: const [0, 1, 2, 3],
      selectedItem: _novelThemeMode.obs,
      getTitle: (value) => switch (value) {
        0 => 'Light',
        1 => 'Dark',
        2 => 'Sepia',
        _ => 'System',
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
      title: context.l10n.novelFontFamily,
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
      _novelKeepScreenOn = true;
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
    NovelReaderKeys.autoScroll.set(false);
    NovelReaderKeys.autoScrollSpeed.set(3.0);
    NovelReaderKeys.volumeScrolling.set(false);
    NovelReaderKeys.tapToScroll.set(false);
    NovelReaderKeys.keepScreenOn.set(_novelKeepScreenOn);
    NovelReaderKeys.swipeGestures.set(true);
    NovelReaderKeys.showReadingProgress.set(_novelReadingProgress);
    NovelReaderKeys.showBatteryTime.set(_novelBatteryTime);
    NovelReaderKeys.ttsEnabled.set(_novelTtsEnabled);
    NovelReaderKeys.ttsSpeed.set(_novelTtsSpeed);
    NovelReaderKeys.ttsPitch.set(_novelTtsPitch);
    NovelReaderKeys.ttsAutoAdvance.set(_novelTtsAutoAdvance);
  }

  Widget _buildNovelPreviewCard() {
    final colors = context.colors;
    final Color bgColor;
    final Color fgColor;
    switch (_novelThemeMode) {
      case 0:
        bgColor = Colors.white;
        fgColor = const Color(0xFF1B1B1F);
        break;
      case 1:
        bgColor = const Color(0xFF121318);
        fgColor = const Color(0xFFE6E1E5);
        break;
      case 2:
        bgColor = const Color(0xFFF4ECD8);
        fgColor = const Color(0xFF3E3021);
        break;
      default:
        bgColor = colors.surface;
        fgColor = colors.onSurface;
        break;
    }

    final resolvedFontFamily = switch (_novelFontFamily) {
      'System' => null,
      'Serif' => 'serif',
      _ => _novelFontFamily,
    };

    return AnymeXContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      color: colors.surfaceContainer.opaque(0.45),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: colors.outline.opaque(0.16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnymeXText(context.l10n.liveNovelPreview,
                variant: TextVariant.bold,
                size: 14,
              ),
              const Spacer(),
              AnymeXText(
                context.l10n.ptDetails(_novelFontFamily, (_novelFontSize.toInt()).toString()),
                size: 11,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: _novelBackgroundOpacity),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outline.opaque(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The wind swept quietly across the lantern-lit courtyard as the final bell echoed through the valley.',
                  style: TextStyle(
                    fontFamily: resolvedFontFamily,
                    fontSize: _novelFontSize,
                    height: _novelLineHeight,
                    letterSpacing: _novelLetterSpacing,
                    wordSpacing: _novelWordSpacing,
                    color: fgColor,
                  ),
                ),
                SizedBox(height: _novelParagraphSpacing.clamp(4.0, 24.0)),
                Text(
                  'He adjusted his coat and stepped forward into the mist.',
                  style: TextStyle(
                    fontFamily: resolvedFontFamily,
                    fontSize: _novelFontSize,
                    height: _novelLineHeight,
                    letterSpacing: _novelLetterSpacing,
                    wordSpacing: _novelWordSpacing,
                    color: fgColor.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: context.l10n.novelReader,
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
              _buildNovelPreviewCard(),
              AnymeXSectionBuilder(
                title: context.l10n.themeDisplay,
                children: [
                  AnymeXTile(
                    icon: Icons.palette_rounded,
                    title: context.l10n.labelTheme,
                    subtitle: switch (_novelThemeMode) {
                      0 => 'Light',
                      1 => 'Dark',
                      2 => 'Sepia',
                      _ => 'System',
                    },
                    onTap: _showNovelThemeDialog,
                  ),
                  AnymeXTile.slider(
                    icon: Icons.opacity_rounded,
                    title: context.l10n.backgroundOpacity,
                    subtitle: context.l10n.readerBackgroundOpacity,
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
                  AnymeXTile.toggle(
                    icon: Icons.chrome_reader_mode_rounded,
                    title: context.l10n.pageReaderMode,
                    subtitle: context.l10n.readOnePageAtATime,
                    value: _novelPageReaderMode,
                    onChanged: (value) => _setNovelBool(
                      NovelReaderKeys.pageReader,
                      value,
                      () => _novelPageReaderMode = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.percent_rounded,
                    title: context.l10n.showReadingProgress,
                    subtitle: context.l10n.displayChapterPercentageWhileReading,
                    value: _novelReadingProgress,
                    onChanged: (value) => _setNovelBool(
                      NovelReaderKeys.showReadingProgress,
                      value,
                      () => _novelReadingProgress = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.battery_std_rounded,
                    title: context.l10n.showBatteryTime,
                    subtitle: context.l10n.displayStatusInfoInTheNovel,
                    value: _novelBatteryTime,
                    onChanged: (value) => _setNovelBool(
                      NovelReaderKeys.showBatteryTime,
                      value,
                      () => _novelBatteryTime = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.lock_clock_rounded,
                    title: context.l10n.keepScreenOn,
                    subtitle: context.l10n.preventScreenFromSleepingWhileReading,
                    value: _novelKeepScreenOn,
                    onChanged: (value) => _setNovelBool(
                      NovelReaderKeys.keepScreenOn,
                      value,
                      () => _novelKeepScreenOn = value,
                    ),
                  ),
                ],
              ),
              AnymeXSectionBuilder(
                title: context.l10n.typographySpacing,
                children: [
                  AnymeXTile(
                    icon: HugeIcons.strokeRoundedTextFont,
                    title: context.l10n.fontFamily,
                    subtitle: _novelFontFamily,
                    onTap: _showNovelFontDialog,
                  ),
                  AnymeXTile.slider(
                    icon: Icons.format_size_rounded,
                    title: context.l10n.fontSize,
                    subtitle: context.l10n.textSize,
                    value: _novelFontSize,
                    min: 12,
                    max: 24,
                    divisions: 12,
                    onChanged: (value) {
                      setState(() =>
                          _novelFontSize = value.clamp(12.0, 24.0).toDouble());
                      NovelReaderKeys.fontSize.set(_novelFontSize);
                    },
                  ),
                  AnymeXTile.slider(
                    icon: Icons.height_rounded,
                    title: context.l10n.lineHeight,
                    subtitle: context.l10n.distanceBetweenLines,
                    value: _novelLineHeight,
                    min: 1.0,
                    max: 3.0,
                    divisions: 20,
                    onChanged: (value) {
                      setState(() =>
                          _novelLineHeight = value.clamp(1.0, 3.0).toDouble());
                      NovelReaderKeys.lineHeight.set(_novelLineHeight);
                    },
                  ),
                  AnymeXTile.slider(
                    icon: Icons.text_fields_rounded,
                    title: context.l10n.letterSpacing,
                    subtitle: context.l10n.spaceBetweenLetters,
                    value: _novelLetterSpacing,
                    min: -1.0,
                    max: 2.0,
                    divisions: 30,
                    onChanged: (value) {
                      setState(() => _novelLetterSpacing =
                          value.clamp(-1.0, 2.0).toDouble());
                      NovelReaderKeys.letterSpacing.set(_novelLetterSpacing);
                    },
                  ),
                  AnymeXTile.slider(
                    icon: Icons.text_rotation_none_rounded,
                    title: context.l10n.wordSpacing,
                    subtitle: context.l10n.spaceBetweenWords,
                    value: _novelWordSpacing,
                    min: 0.0,
                    max: 5.0,
                    divisions: 25,
                    onChanged: (value) {
                      setState(() =>
                          _novelWordSpacing = value.clamp(0.0, 5.0).toDouble());
                      NovelReaderKeys.wordSpacing.set(_novelWordSpacing);
                    },
                  ),
                  AnymeXTile.slider(
                    icon: Icons.format_line_spacing_rounded,
                    title: context.l10n.paragraphSpacing,
                    subtitle: context.l10n.spaceBetweenParagraphs,
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
                ],
              ),
              AnymeXSectionBuilder(
                title: context.l10n.novelControlsGestures,
                children: [
                  AnymeXTile.toggle(
                    icon: Icons.touch_app_rounded,
                    title: context.l10n.tapToScroll,
                    subtitle: context.l10n.tapScreenEdgesToScrollNovel,
                    value: _novelTapToScroll,
                    onChanged: (value) => _setNovelBool(
                      NovelReaderKeys.tapToScroll,
                      value,
                      () => _novelTapToScroll = value,
                    ),
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.swipe_rounded,
                    title: context.l10n.swipeGestures,
                    subtitle:
                        context.l10n.enableHorizontalSwipeNavigationIn,
                    value: _novelSwipeGestures,
                    onChanged: (value) => _setNovelBool(
                      NovelReaderKeys.swipeGestures,
                      value,
                      () => _novelSwipeGestures = value,
                    ),
                  ),
                  if (Platform.isAndroid)
                    AnymeXTile.toggle(
                      icon: Iconsax.volume_high,
                      title: context.l10n.volumeKeyScrolling,
                      subtitle: context.l10n.useHardwareVolumeButtonsToScroll,
                      value: _novelVolumeScrolling,
                      onChanged: (value) => _setNovelBool(
                        NovelReaderKeys.volumeScrolling,
                        value,
                        () => _novelVolumeScrolling = value,
                      ),
                    ),
                  AnymeXTile.toggle(
                    icon: Icons.play_arrow_rounded,
                    title: context.l10n.autoScroll,
                    subtitle: context.l10n.automaticallyScrollNovelContent,
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
                      title: context.l10n.autoScrollSpeed,
                      subtitle: context.l10n.secondsPerScreenLowerIsFaster,
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
                ],
              ),
              AnymeXSectionBuilder(
                title: context.l10n.textToSpeechTts,
                children: [
                  AnymeXTile.toggle(
                    icon: Icons.record_voice_over_rounded,
                    title: context.l10n.enableTts,
                    subtitle: context.l10n.readNovelChaptersAloud,
                    value: _novelTtsEnabled,
                    onChanged: (value) => _setNovelBool(
                      NovelReaderKeys.ttsEnabled,
                      value,
                      () => _novelTtsEnabled = value,
                    ),
                  ),
                  if (_novelTtsEnabled) ...[
                    AnymeXTile.slider(
                      icon: Icons.speed_rounded,
                      title: context.l10n.ttsSpeed,
                      subtitle: context.l10n.speechRate,
                      value: _novelTtsSpeed,
                      min: 0.1,
                      max: 1.5,
                      divisions: 14,
                      onChanged: (value) {
                        setState(() => _novelTtsSpeed = value);
                        NovelReaderKeys.ttsSpeed.set(value);
                      },
                    ),
                    AnymeXTile.slider(
                      icon: Icons.graphic_eq_rounded,
                      title: context.l10n.ttsPitch,
                      subtitle: context.l10n.voicePitch,
                      value: _novelTtsPitch,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      onChanged: (value) {
                        setState(() => _novelTtsPitch = value);
                        NovelReaderKeys.ttsPitch.set(value);
                      },
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.skip_next_rounded,
                      title: context.l10n.ttsAutoAdvance,
                      subtitle: context.l10n.automaticallyMoveToNextTextSegment,
                      value: _novelTtsAutoAdvance,
                      onChanged: (value) => _setNovelBool(
                        NovelReaderKeys.ttsAutoAdvance,
                        value,
                        () => _novelTtsAutoAdvance = value,
                      ),
                    ),
                  ],
                ],
              ),
              AnymeXSectionBuilder(
                title: context.l10n.actionReset,
                children: [
                  AnymeXTile(
                    icon: Icons.restart_alt_rounded,
                    title: context.l10n.resetNovelReaderSettings,
                    subtitle: context.l10n.restoreAllNovelReaderDefaults,
                    onTap: _resetNovelDefaults,
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
