import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsReader extends StatefulWidget {
  final bool isModal;
  const SettingsReader({super.key, this.isModal = false});

  @override
  State<SettingsReader> createState() => _SettingsReaderState();
}

class _SettingsReaderState extends State<SettingsReader> {
  final List<String> _readingLayouts = ['Continuous', 'Paged'];
  final List<String> _readingDirections = ['Down', 'Up', 'Right', 'Left'];
  final List<String> _dualPageModes = ['Off', 'Auto (Landscape)', 'Force (Always)'];
  final List<String> _readerThemes = ['White', 'Black', 'Gray'];
  final List<String> _novelFontFamilies = [
    'System',
    'Serif',
    'Roboto',
    'Open Sans',
    'Lato',
    'Merriweather',
    'Crimson Text',
    'Libre Baskerville',
  ];
  final List<String> _novelTextAligns = ['Left', 'Center', 'Justify'];

  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() {});
  }

  T _getNP<T>(String key, T defaultValue) {
    if (_prefs == null) return defaultValue;
    final val = _prefs!.get(key);
    if (val == null) return defaultValue;
    if (val is T) return val;
    if (T == double && val is int) return val.toDouble() as T;
    if (T == int && val is double) return val.toInt() as T;
    return defaultValue;
  }

  Future<void> _setNP<T>(String key, T value) async {
    if (_prefs == null) return;
    if (value is double) {
      await _prefs!.setDouble(key, value);
    } else if (value is int) {
      await _prefs!.setInt(key, value);
    } else if (value is bool) {
      await _prefs!.setBool(key, value);
    } else if (value is String) {
      await _prefs!.setString(key, value);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            if (!widget.isModal) const NestedHeader(title: 'Reader Settings'),
            Expanded(
              child: SingleChildScrollView(
                padding: getResponsiveValue(
                  context,
                  mobileValue: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 50.0),
                  desktopValue: const EdgeInsets.fromLTRB(25.0, 20.0, 25.0, 20.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isModal) ...[
                      const Center(
                        child: Text(
                          'Reader Settings',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                    AnymexExpansionTile(
                      initialExpanded: true,
                      title: 'Manga Reader',
                      content: Column(
                        children: [
                          CustomTile(
                            padding: 10,
                            icon: Icons.view_day_rounded,
                            title: 'Reading Layout',
                            isDescBold: true,
                            descColor: Theme.of(context).colorScheme.primary,
                            description: _readingLayouts[ReaderKeys.readingLayout.get<int>(0)],
                            onTap: () => _showIndexSelectionDialog(
                              title: 'Reading Layout',
                              items: _readingLayouts,
                              selectedIndex: ReaderKeys.readingLayout.get<int>(0),
                              onSelected: (index) {
                                ReaderKeys.readingLayout.set(index);
                                setState(() {});
                              },
                            ),
                          ),
                          CustomTile(
                            padding: 10,
                            icon: Icons.swap_horiz_rounded,
                            title: 'Reading Direction',
                            isDescBold: true,
                            descColor: Theme.of(context).colorScheme.primary,
                            description: _readingDirections[ReaderKeys.readingDirection.get<int>(1)],
                            onTap: () => _showIndexSelectionDialog(
                              title: 'Reading Direction',
                              items: _readingDirections,
                              selectedIndex: ReaderKeys.readingDirection.get<int>(1),
                              onSelected: (index) {
                                ReaderKeys.readingDirection.set(index);
                                setState(() {});
                              },
                            ),
                          ),
                          CustomTile(
                            padding: 10,
                            icon: Icons.auto_awesome_mosaic_rounded,
                            title: 'Dual Page Mode',
                            isDescBold: true,
                            descColor: Theme.of(context).colorScheme.primary,
                            description: _dualPageModes[ReaderKeys.dualPageMode.get<int>(0)],
                            onTap: () => _showIndexSelectionDialog(
                              title: 'Dual Page Mode',
                              items: _dualPageModes,
                              selectedIndex: ReaderKeys.dualPageMode.get<int>(0),
                              onSelected: (index) {
                                ReaderKeys.dualPageMode.set(index);
                                setState(() {});
                              },
                            ),
                          ),
                          CustomTile(
                            padding: 10,
                            icon: Icons.color_lens_rounded,
                            title: 'Reader Theme',
                            isDescBold: true,
                            descColor: Theme.of(context).colorScheme.primary,
                            description: _readerThemes[ReaderKeys.readerTheme.get<int>(1)],
                            onTap: () => _showIndexSelectionDialog(
                              title: 'Reader Theme',
                              items: _readerThemes,
                              selectedIndex: ReaderKeys.readerTheme.get<int>(1),
                              onSelected: (index) {
                                ReaderKeys.readerTheme.set(index);
                                setState(() {});
                              },
                            ),
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.space_bar_rounded,
                            title: 'Spaced Pages',
                            description: 'Add spacing between pages',
                            switchValue: ReaderKeys.spacedPages.get<bool>(false),
                            onChanged: (val) {
                              ReaderKeys.spacedPages.set(val);
                              setState(() {});
                            },
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.crop_rounded,
                            title: 'Crop Images',
                            description: 'Crop whitespace from manga pages',
                            switchValue: ReaderKeys.cropImages.get<bool>(false),
                            onChanged: (val) {
                              ReaderKeys.cropImages.set(val);
                              setState(() {});
                            },
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.skip_next_rounded,
                            title: 'Overscroll to Chapter',
                            description: 'Swipe past last page to go to next chapter',
                            switchValue: ReaderKeys.overscrollToChapter.get<bool>(true),
                            onChanged: (val) {
                              ReaderKeys.overscrollToChapter.set(val);
                              setState(() {});
                            },
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.bookmark_rounded,
                            title: 'Show Page Indicator',
                            description: 'Display current page number',
                            switchValue: ReaderKeys.showPageIndicator.get<bool>(false),
                            onChanged: (val) {
                              ReaderKeys.showPageIndicator.set(val);
                              setState(() {});
                            },
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.screen_lock_landscape_rounded,
                            title: 'Keep Screen On',
                            description: 'Prevent screen from turning off while reading',
                            switchValue: ReaderKeys.keepScreenOn.get<bool>(true),
                            onChanged: (val) {
                              ReaderKeys.keepScreenOn.set(val);
                              setState(() {});
                            },
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.touch_app_rounded,
                            title: 'Long Press Page Actions',
                            description: 'Enable long press for page options',
                            switchValue: ReaderKeys.longPressPageActionsEnabled.get<bool>(true),
                            onChanged: (val) {
                              ReaderKeys.longPressPageActionsEnabled.set(val);
                              setState(() {});
                            },
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.auto_fix_high_rounded,
                            title: 'Auto Webtoon Mode',
                            description: 'Automatically switch to webtoon layout for tall images',
                            switchValue: ReaderKeys.autoWebtoonMode.get<bool>(false),
                            onChanged: (val) {
                              ReaderKeys.autoWebtoonMode.set(val);
                              setState(() {});
                            },
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.menu_book_rounded,
                            title: 'Always Show Chapter Transition',
                            description: 'Show transition screen between every chapter',
                            switchValue: ReaderKeys.alwaysShowChapterTransition.get<bool>(false),
                            onChanged: (val) {
                              ReaderKeys.alwaysShowChapterTransition.set(val);
                              setState(() {});
                            },
                          ),
                          CustomSliderTile(
                            sliderValue: ReaderKeys.imageWidth.get<double>(1.0),
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            label: ReaderKeys.imageWidth.get<double>(1.0).toStringAsFixed(1),
                            onChanged: (val) {
                              ReaderKeys.imageWidth.set(val);
                              setState(() {});
                            },
                            title: 'Image Width',
                            description: 'Adjust the width of manga pages',
                            icon: Icons.width_normal_rounded,
                          ),
                          CustomSliderTile(
                            sliderValue: ReaderKeys.scrollSpeed.get<double>(1.0),
                            min: 0.5,
                            max: 3.0,
                            divisions: 10,
                            label: ReaderKeys.scrollSpeed.get<double>(1.0).toStringAsFixed(1),
                            onChanged: (val) {
                              ReaderKeys.scrollSpeed.set(val);
                              setState(() {});
                            },
                            title: 'Scroll Speed',
                            description: 'Adjust scroll speed multiplier',
                            icon: Icons.speed_rounded,
                          ),
                          CustomSliderTile(
                            sliderValue: ReaderKeys.preloadPages.get<int>(3).toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: ReaderKeys.preloadPages.get<int>(3).toString(),
                            onChanged: (val) {
                              ReaderKeys.preloadPages.set(val.toInt());
                              setState(() {});
                            },
                            title: 'Preload Pages',
                            description: 'Number of pages to preload ahead',
                            icon: Iconsax.layer,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnymexExpansionTile(
                      title: 'Manga Volume Keys',
                      content: Column(
                        children: [
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.volume_up_rounded,
                            title: 'Volume Keys Navigation',
                            description: 'Use volume buttons to navigate pages',
                            switchValue: ReaderKeys.volumeKeysEnabled.get<bool>(false),
                            onChanged: (val) {
                              ReaderKeys.volumeKeysEnabled.set(val);
                              setState(() {});
                            },
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.swap_vert_rounded,
                            title: 'Invert Volume Keys',
                            description: 'Swap volume up/down navigation direction',
                            switchValue: ReaderKeys.invertVolumeKeys.get<bool>(false),
                            onChanged: (val) {
                              ReaderKeys.invertVolumeKeys.set(val);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnymexExpansionTile(
                      title: 'Manga Auto Scroll',
                      content: Column(
                        children: [
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.autorenew_rounded,
                            title: 'Auto Scroll',
                            description: 'Automatically scroll through pages',
                            switchValue: ReaderKeys.autoScrollEnabled.get<bool>(false),
                            onChanged: (val) {
                              ReaderKeys.autoScrollEnabled.set(val);
                              setState(() {});
                            },
                          ),
                          CustomSliderTile(
                            sliderValue: ReaderKeys.autoScrollSpeed.get<double>(3.0),
                            min: 1.0,
                            max: 10.0,
                            divisions: 18,
                            label: ReaderKeys.autoScrollSpeed.get<double>(3.0).toStringAsFixed(1),
                            onChanged: (val) {
                              ReaderKeys.autoScrollSpeed.set(val);
                              setState(() {});
                            },
                            title: 'Auto Scroll Speed',
                            description: 'Adjust automatic scroll speed',
                            icon: Icons.speed_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnymexExpansionTile(
                      title: 'Manga Color Filters',
                      content: Column(
                        children: [
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.brightness_medium_rounded,
                            title: 'Custom Brightness',
                            description: 'Override screen brightness in reader',
                            switchValue: ReaderKeys.customBrightnessEnabled.get<bool>(false),
                            onChanged: (val) {
                              ReaderKeys.customBrightnessEnabled.set(val);
                              setState(() {});
                            },
                          ),
                          if (ReaderKeys.customBrightnessEnabled.get<bool>(false))
                            CustomSliderTile(
                              sliderValue: ReaderKeys.customBrightnessValue.get<int>(0).toDouble(),
                              min: 0,
                              max: 255,
                              divisions: 20,
                              label: ReaderKeys.customBrightnessValue.get<int>(0).toString(),
                              onChanged: (val) {
                                ReaderKeys.customBrightnessValue.set(val.toInt());
                                setState(() {});
                              },
                              title: 'Brightness Value',
                              description: 'Adjust custom brightness level',
                              icon: Icons.brightness_5_rounded,
                            ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.filter_rounded,
                            title: 'Color Filter',
                            description: 'Apply a color filter overlay',
                            switchValue: ReaderKeys.colorFilterEnabled.get<bool>(false),
                            onChanged: (val) {
                              ReaderKeys.colorFilterEnabled.set(val);
                              setState(() {});
                            },
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.filter_b_and_w_rounded,
                            title: 'Grayscale',
                            description: 'Read manga in black and white',
                            switchValue: ReaderKeys.grayscaleEnabled.get<bool>(false),
                            onChanged: (val) {
                              ReaderKeys.grayscaleEnabled.set(val);
                              setState(() {});
                            },
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.invert_colors_rounded,
                            title: 'Invert Colors',
                            description: 'Invert all colors while reading',
                            switchValue: ReaderKeys.invertColorsEnabled.get<bool>(false),
                            onChanged: (val) {
                              ReaderKeys.invertColorsEnabled.set(val);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnymexExpansionTile(
                      title: 'Manga Display Refresh',
                      content: Column(
                        children: [
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.refresh_rounded,
                            title: 'Display Refresh',
                            description: 'Flash display to reduce ghosting on e-ink screens',
                            switchValue: ReaderKeys.displayRefreshEnabled.get<bool>(false),
                            onChanged: (val) {
                              ReaderKeys.displayRefreshEnabled.set(val);
                              setState(() {});
                            },
                          ),
                          if (ReaderKeys.displayRefreshEnabled.get<bool>(false)) ...[
                            CustomSliderTile(
                              sliderValue: ReaderKeys.displayRefreshDurationMs.get<int>(200).toDouble(),
                              min: 50,
                              max: 500,
                              divisions: 9,
                              label: '${ReaderKeys.displayRefreshDurationMs.get<int>(200)}ms',
                              onChanged: (val) {
                                ReaderKeys.displayRefreshDurationMs.set(val.toInt());
                                setState(() {});
                              },
                              title: 'Refresh Duration',
                              description: 'Duration of the display refresh flash in milliseconds',
                              icon: Icons.timelapse_rounded,
                            ),
                            CustomSliderTile(
                              sliderValue: ReaderKeys.displayRefreshInterval.get<int>(1).toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: 'Every ${ReaderKeys.displayRefreshInterval.get<int>(1)} pages',
                              onChanged: (val) {
                                ReaderKeys.displayRefreshInterval.set(val.toInt());
                                setState(() {});
                              },
                              title: 'Refresh Interval',
                              description: 'Trigger refresh after every N pages',
                              icon: Icons.repeat_rounded,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnymexExpansionTile(
                      title: 'Novel Reader',
                      content: Column(
                        children: [
                          CustomTile(
                            padding: 10,
                            icon: Icons.font_download_rounded,
                            title: 'Font Family',
                            isDescBold: true,
                            descColor: Theme.of(context).colorScheme.primary,
                            description: _getNP<String>('novel_font_family', 'System'),
                            onTap: () => _showStringSelectionDialog(
                              title: 'Font Family',
                              items: _novelFontFamilies,
                              selectedItem: _getNP<String>('novel_font_family', 'System'),
                              onSelected: (val) => _setNP('novel_font_family', val),
                            ),
                          ),
                          CustomTile(
                            padding: 10,
                            icon: Icons.format_align_left_rounded,
                            title: 'Text Alignment',
                            isDescBold: true,
                            descColor: Theme.of(context).colorScheme.primary,
                            description: _novelTextAligns[_getNP<int>('novel_text_align', 0)],
                            onTap: () => _showIndexSelectionDialog(
                              title: 'Text Alignment',
                              items: _novelTextAligns,
                              selectedIndex: _getNP<int>('novel_text_align', 0),
                              onSelected: (index) => _setNP('novel_text_align', index),
                            ),
                          ),
                          CustomSliderTile(
                            sliderValue: _getNP<double>('novel_font_size', 16.0),
                            min: 12,
                            max: 24,
                            divisions: 12,
                            label: _getNP<double>('novel_font_size', 16.0).toStringAsFixed(0),
                            onChanged: (val) => _setNP('novel_font_size', val),
                            title: 'Font Size',
                            description: 'Adjust text size',
                            icon: Icons.text_fields_rounded,
                          ),
                          CustomSliderTile(
                            sliderValue: _getNP<double>('novel_line_height', 1.6),
                            min: 1.0,
                            max: 3.0,
                            divisions: 20,
                            label: _getNP<double>('novel_line_height', 1.6).toStringAsFixed(1),
                            onChanged: (val) => _setNP('novel_line_height', val),
                            title: 'Line Height',
                            description: 'Adjust space between lines',
                            icon: Icons.format_line_spacing_rounded,
                          ),
                          CustomSliderTile(
                            sliderValue: _getNP<double>('novel_letter_spacing', 0.0),
                            min: -1.0,
                            max: 2.0,
                            divisions: 30,
                            label: _getNP<double>('novel_letter_spacing', 0.0).toStringAsFixed(1),
                            onChanged: (val) => _setNP('novel_letter_spacing', val),
                            title: 'Letter Spacing',
                            description: 'Adjust space between characters',
                            icon: Icons.abc_rounded,
                          ),
                          CustomSliderTile(
                            sliderValue: _getNP<double>('novel_word_spacing', 0.0),
                            min: 0.0,
                            max: 5.0,
                            divisions: 10,
                            label: _getNP<double>('novel_word_spacing', 0.0).toStringAsFixed(1),
                            onChanged: (val) => _setNP('novel_word_spacing', val),
                            title: 'Word Spacing',
                            description: 'Adjust space between words',
                            icon: Icons.space_bar_rounded,
                          ),
                          CustomSliderTile(
                            sliderValue: _getNP<double>('novel_paragraph_spacing', 16.0),
                            min: 8.0,
                            max: 32.0,
                            divisions: 12,
                            label: _getNP<double>('novel_paragraph_spacing', 16.0).toStringAsFixed(0),
                            onChanged: (val) => _setNP('novel_paragraph_spacing', val),
                            title: 'Paragraph Spacing',
                            description: 'Adjust space between paragraphs',
                            icon: Icons.format_indent_increase_rounded,
                          ),
                          CustomSliderTile(
                            sliderValue: _getNP<double>('novel_padding_horizontal', 16.0),
                            min: 8.0,
                            max: 32.0,
                            divisions: 12,
                            label: _getNP<double>('novel_padding_horizontal', 16.0).toStringAsFixed(0),
                            onChanged: (val) => _setNP('novel_padding_horizontal', val),
                            title: 'Horizontal Padding',
                            description: 'Adjust left and right margins',
                            icon: Icons.padding_rounded,
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.book_rounded,
                            title: 'Page Reader Mode',
                            description: 'Read in pages instead of continuous scroll',
                            switchValue: _getNP<bool>('novel_page_reader', false),
                            onChanged: (val) => _setNP('novel_page_reader', val),
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.screen_lock_portrait_rounded,
                            title: 'Keep Screen On',
                            description: 'Prevent screen from turning off while reading',
                            switchValue: _getNP<bool>('novel_keep_screen_on', true),
                            onChanged: (val) => _setNP('novel_keep_screen_on', val),
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.vertical_split_rounded,
                            title: 'Vertical Seekbar',
                            description: 'Show vertical progress bar on the side',
                            switchValue: _getNP<bool>('novel_vertical_seekbar', true),
                            onChanged: (val) => _setNP('novel_vertical_seekbar', val),
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.swipe_rounded,
                            title: 'Swipe Gestures',
                            description: 'Swipe to navigate between chapters',
                            switchValue: _getNP<bool>('novel_swipe_gestures', true),
                            onChanged: (val) => _setNP('novel_swipe_gestures', val),
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.format_clear_rounded,
                            title: 'Remove Extra Spacing',
                            description: 'Clean up excessive whitespace in text',
                            switchValue: _getNP<bool>('novel_remove_extra_spacing', false),
                            onChanged: (val) => _setNP('novel_remove_extra_spacing', val),
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: HugeIcons.strokeRoundedBold,
                            title: 'Bionic Reading',
                            description: 'Bold the first part of words to guide your eyes',
                            switchValue: _getNP<bool>('novel_bionic_reading', false),
                            onChanged: (val) => _setNP('novel_bionic_reading', val),
                          ),
                          if (_getNP<bool>('novel_bionic_reading', false))
                            CustomSliderTile(
                              sliderValue: _getNP<double>('novel_bionic_intensity', 0.5),
                              min: 0.3,
                              max: 0.7,
                              divisions: 8,
                              label: '${(_getNP<double>('novel_bionic_intensity', 0.5) * 100).toStringAsFixed(0)}%',
                              onChanged: (val) => _setNP('novel_bionic_intensity', val),
                              title: 'Bionic Intensity',
                              description: 'Adjust how much of each word is bolded',
                              icon: HugeIcons.strokeRoundedBold,
                            ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.linear_scale_rounded,
                            title: 'Show Reading Progress',
                            description: 'Display a progress bar at the bottom',
                            switchValue: _getNP<bool>('novel_show_reading_progress', true),
                            onChanged: (val) => _setNP('novel_show_reading_progress', val),
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.battery_5_bar_rounded,
                            title: 'Show Battery & Time',
                            description: 'Display battery level and current time',
                            switchValue: _getNP<bool>('novel_show_battery_time', true),
                            onChanged: (val) => _setNP('novel_show_battery_time', val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnymexExpansionTile(
                      title: 'Novel Auto Scroll',
                      content: Column(
                        children: [
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.autorenew_rounded,
                            title: 'Auto Scroll',
                            description: 'Automatically scroll through the novel',
                            switchValue: _getNP<bool>('novel_auto_scroll', false),
                            onChanged: (val) => _setNP('novel_auto_scroll', val),
                          ),
                          CustomSliderTile(
                            sliderValue: _getNP<double>('novel_auto_scroll_speed', 3.0),
                            min: 1.0,
                            max: 10.0,
                            divisions: 18,
                            label: _getNP<double>('novel_auto_scroll_speed', 3.0).toStringAsFixed(1),
                            onChanged: (val) => _setNP('novel_auto_scroll_speed', val),
                            title: 'Auto Scroll Speed',
                            description: 'Adjust automatic scroll speed',
                            icon: Icons.speed_rounded,
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.volume_up_rounded,
                            title: 'Volume Button Scrolling',
                            description: 'Use volume buttons to scroll the novel',
                            switchValue: _getNP<bool>('novel_volume_scrolling', false),
                            onChanged: (val) => _setNP('novel_volume_scrolling', val),
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.touch_app_rounded,
                            title: 'Tap to Scroll',
                            description: 'Tap top or bottom half of screen to scroll',
                            switchValue: _getNP<bool>('novel_tap_to_scroll', false),
                            onChanged: (val) => _setNP('novel_tap_to_scroll', val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnymexExpansionTile(
                      title: 'Novel Text-to-Speech',
                      content: Column(
                        children: [
                          CustomSliderTile(
                            sliderValue: _getNP<double>('novel_tts_speed', 0.5),
                            min: 0.1,
                            max: 1.0,
                            divisions: 9,
                            label: _getNP<double>('novel_tts_speed', 0.5).toStringAsFixed(1),
                            onChanged: (val) => _setNP('novel_tts_speed', val),
                            title: 'TTS Speed',
                            description: 'Adjust text-to-speech reading speed',
                            icon: Icons.record_voice_over_rounded,
                          ),
                          CustomSliderTile(
                            sliderValue: _getNP<double>('novel_tts_pitch', 1.0),
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            label: _getNP<double>('novel_tts_pitch', 1.0).toStringAsFixed(1),
                            onChanged: (val) => _setNP('novel_tts_pitch', val),
                            title: 'TTS Pitch',
                            description: 'Adjust text-to-speech voice pitch',
                            icon: Icons.graphic_eq_rounded,
                          ),
                          CustomSwitchTile(
                            padding: const EdgeInsets.all(10),
                            icon: Icons.skip_next_rounded,
                            title: 'TTS Auto Advance',
                            description: 'Automatically continue reading next segment',
                            switchValue: _getNP<bool>('novel_tts_auto_advance', true),
                            onChanged: (val) => _setNP('novel_tts_auto_advance', val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIndexSelectionDialog({
    required String title,
    required List<String> items,
    required int selectedIndex,
    required Function(int) onSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          title,
          style: TextStyle(
            color: context.colors.primary,
            fontFamily: 'Poppins-SemiBold',
            fontSize: 20,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) => RadioListTile<int>(
              title: Text(items[index]),
              value: index,
              groupValue: selectedIndex,
              onChanged: (val) {
                if (val != null) {
                  onSelected(val);
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showStringSelectionDialog({
    required String title,
    required List<String> items,
    required String selectedItem,
    required Function(String) onSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          title,
          style: TextStyle(
            color: context.colors.primary,
            fontFamily: 'Poppins-SemiBold',
            fontSize: 20,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) => RadioListTile<String>(
              title: Text(items[index]),
              value: items[index],
              groupValue: selectedItem,
              onChanged: (val) {
                if (val != null) {
                  onSelected(val);
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
