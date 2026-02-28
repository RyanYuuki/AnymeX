import 'package:anymex/screens/novel/reader/controller/reader_controller.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_tts/flutter_tts.dart';

class NovelSettingsPanel extends StatelessWidget {
  final NovelReaderController controller;

  const NovelSettingsPanel({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final animatedWidth = MediaQuery.of(context).size.width * 0.85;
    return Obx(() {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        top: 0,
        bottom: 0,
        right: controller.showSettings.value ? 0 : -animatedWidth,
        width: animatedWidth,
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surface.opaque(0.95),
            boxShadow: [
              BoxShadow(
                color: Colors.black.opaque(0.2),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildSettingsHeader(context),
                Expanded(
                  child: DefaultTabController(
                    length: 5,
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: true,
                          tabs: const [
                            Tab(icon: Icon(Icons.format_size), text: 'Display'),
                            Tab(icon: Icon(Icons.palette), text: 'Theme'),
                            Tab(icon: Icon(Icons.gesture), text: 'Navigation'),
                            Tab(icon: Icon(Icons.accessibility), text: 'Access'),
                            Tab(icon: Icon(Icons.record_voice_over), text: 'TTS'),
                          ],
                          labelColor: context.colors.primary,
                          unselectedLabelColor: context.colors.onSurface.opaque(0.6),
                          indicatorColor: context.colors.primary,
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildDisplayTab(context),
                              _buildThemeTab(context),
                              _buildNavigationTab(context),
                              _buildAccessibilityTab(context),
                              _buildTtsTab(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSettingsHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colors.outline.opaque(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Reading Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.colors.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              controller.toggleSettings();
            },
            icon: Icon(
              Icons.close_rounded,
              color: context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // Display Tab
  Widget _buildDisplayTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'Font Settings',
            children: [
              _buildFontFamilySelector(context),
              const SizedBox(height: 16),
              _buildSliderSetting(
                context,
                title: 'Font Size',
                value: controller.fontSize,
                min: 12,
                max: 24,
                divisions: 12,
                label: (value) => '${value.toInt()}pt',
              ),
              const SizedBox(height: 16),
              _buildSliderSetting(
                context,
                title: 'Line Height',
                value: controller.lineHeight,
                min: 1.0,
                max: 3.0,
                divisions: 20,
                label: (value) => value.toStringAsFixed(1),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Spacing',
            children: [
              _buildSliderSetting(
                context,
                title: 'Letter Spacing',
                value: controller.letterSpacing,
                min: -1.0,
                max: 2.0,
                divisions: 30,
                label: (value) => value.toStringAsFixed(1),
              ),
              const SizedBox(height: 16),
              _buildSliderSetting(
                context,
                title: 'Word Spacing',
                value: controller.wordSpacing,
                min: 0.0,
                max: 5.0,
                divisions: 25,
                label: (value) => value.toStringAsFixed(1),
              ),
              const SizedBox(height: 16),
              _buildSliderSetting(
                context,
                title: 'Paragraph Spacing',
                value: controller.paragraphSpacing,
                min: 8.0,
                max: 32.0,
                divisions: 12,
                label: (value) => '${value.toInt()}px',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Padding',
            children: [
              _buildSliderSetting(
                context,
                title: 'Horizontal Padding',
                value: controller.paddingHorizontal,
                min: 8.0,
                max: 32.0,
                divisions: 12,
                label: (value) => '${value.toInt()}px',
              ),
              const SizedBox(height: 16),
              _buildSliderSetting(
                context,
                title: 'Vertical Padding',
                value: controller.paddingVertical,
                min: 4.0,
                max: 24.0,
                divisions: 10,
                label: (value) => '${value.toInt()}px',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextAlignment(context),
        ],
      ),
    );
  }

  // Theme Tab
  Widget _buildThemeTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'Theme Mode',
            children: [
              _buildThemeOption(context, 'Light', 0, Icons.light_mode),
              const SizedBox(height: 8),
              _buildThemeOption(context, 'Dark', 1, Icons.dark_mode),
              const SizedBox(height: 8),
              _buildThemeOption(context, 'Sepia', 2, Icons.brightness_4),
              const SizedBox(height: 8),
              _buildThemeOption(context, 'System', 3, Icons.settings),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Background Opacity',
            children: [
              _buildSliderSetting(
                context,
                title: 'Opacity',
                value: controller.backgroundOpacity,
                min: 0.3,
                max: 1.0,
                divisions: 7,
                label: (value) => '${(value * 100).toInt()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Navigation Tab
  Widget _buildNavigationTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'Reading Mode',
            children: [
              _buildSwitchSetting(
                context,
                title: 'Page Reader Mode',
                subtitle: 'Read one page at a time',
                value: controller.pageReaderMode,
                onChanged: (value) => controller.togglePageReaderMode(),
              ),
              const SizedBox(height: 12),
              _buildSwitchSetting(
                context,
                title: 'Vertical Seekbar',
                subtitle: 'Show vertical progress bar',
                value: controller.verticalSeekbar,
                onChanged: (value) => controller.toggleVerticalSeekbar(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Auto Scroll',
            children: [
              _buildSwitchSetting(
                context,
                title: 'Auto Scroll',
                value: controller.autoScrollEnabled,
                onChanged: (value) => controller.toggleAutoScroll(),
              ),
              if (controller.autoScrollEnabled.value) ...[
                const SizedBox(height: 16),
                _buildSliderSetting(
                  context,
                  title: 'Scroll Speed',
                  value: controller.autoScrollSpeed,
                  min: 1.0,
                  max: 10.0,
                  divisions: 18,
                  label: (value) => '${value.toStringAsFixed(1)}s/screen',
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Controls',
            children: [
              _buildSwitchSetting(
                context,
                title: 'Volume Button Scrolling',
                subtitle: 'Use volume buttons to scroll',
                value: controller.volumeButtonScrolling,
                onChanged: (value) => controller.toggleVolumeScrolling(),
              ),
              const SizedBox(height: 12),
              _buildSwitchSetting(
                context,
                title: 'Tap to Scroll',
                subtitle: 'Tap top/bottom to scroll',
                value: controller.tapToScroll,
                onChanged: (value) => controller.toggleTapToScroll(),
              ),
              if (controller.tapToScroll.value) ...[
                const SizedBox(height: 16),
                _buildSliderSetting(
                  context,
                  title: 'Tap Scroll Amount',
                  value: controller.tapScrollAmount,
                  min: 10.0,
                  max: 50.0,
                  divisions: 8,
                  label: (value) => '${value.toInt()}px',
                ),
              ],
              const SizedBox(height: 12),
              _buildSwitchSetting(
                context,
                title: 'Swipe Between Chapters',
                value: controller.swipeGestures,
                onChanged: (value) => controller.toggleSwipeGestures(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Accessibility Tab
  Widget _buildAccessibilityTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'Reading Features',
            children: [
              _buildSwitchSetting(
                context,
                title: 'Bionic Reading',
                subtitle: 'Bold first half of words for faster reading',
                value: controller.bionicReading,
                onChanged: (value) => controller.toggleBionicReading(),
              ),
              if (controller.bionicReading.value) ...[
                const SizedBox(height: 16),
                _buildSliderSetting(
                  context,
                  title: 'Bionic Intensity',
                  value: controller.bionicIntensity,
                  min: 0.3,
                  max: 0.7,
                  divisions: 4,
                  label: (value) => '${(value * 100).toInt()}%',
                ),
              ],
              const SizedBox(height: 12),
              _buildSwitchSetting(
                context,
                title: 'Remove Extra Spacing',
                subtitle: 'Remove unnecessary line breaks',
                value: controller.removeExtraSpacing,
                onChanged: (value) => controller.toggleRemoveExtraSpacing(),
              ),
              const SizedBox(height: 12),
              _buildSwitchSetting(
                context,
                title: 'Keep Screen On',
                value: controller.keepScreenOn,
                onChanged: (value) => controller.toggleKeepScreenOn(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Display',
            children: [
              _buildSwitchSetting(
                context,
                title: 'Show Reading Progress',
                value: controller.showReadingProgress,
                onChanged: (value) => controller.toggleShowReadingProgress(),
              ),
              const SizedBox(height: 12),
              _buildSwitchSetting(
                context,
                title: 'Show Battery & Time',
                value: controller.showBatteryAndTime,
                onChanged: (value) => controller.toggleShowBatteryAndTime(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildResetButton(context),
        ],
      ),
    );
  }

  // TTS Tab
  Widget _buildTtsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'Text-to-Speech',
            children: [
              _buildSwitchSetting(
                context,
                title: 'Enable TTS',
                subtitle: 'Read text aloud',
                value: controller.ttsEnabled,
                onChanged: (value) => controller.toggleTts(),
              ),
              if (controller.ttsEnabled.value) ...[
                const SizedBox(height: 16),
                _buildTtsVoiceSelector(context),
                const SizedBox(height: 16),
                _buildSliderSetting(
                  context,
                  title: 'Speech Speed',
                  value: controller.ttsSpeed,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: (value) => '${value.toStringAsFixed(1)}x',
                  onChanged: (value) => controller.setTtsSpeed(value),
                ),
                const SizedBox(height: 16),
                _buildSliderSetting(
                  context,
                  title: 'Pitch',
                  value: controller.ttsPitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: (value) => '${value.toStringAsFixed(1)}x',
                  onChanged: (value) => controller.setTtsPitch(value),
                ),
                const SizedBox(height: 16),
                _buildSwitchSetting(
                  context,
                  title: 'Auto Advance',
                  subtitle: 'Automatically move to next text',
                  value: controller.ttsAutoAdvance,
                  onChanged: (value) => controller.toggleTtsAutoAdvance(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: controller.ttsPrevious,
                      color: context.colors.onSurface,
                    ),
                    IconButton(
                      icon: Obx(() => Icon(
                        controller.ttsPlaying.value
                            ? Icons.pause
                            : Icons.play_arrow,
                      )),
                      onPressed: controller.toggleTts,
                      color: context.colors.primary,
                      iconSize: 48,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: controller.ttsNext,
                      color: context.colors.onSurface,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Get.theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildFontFamilySelector(BuildContext context) {
    return Obx(() {
      return AnymexDropdown(
        icon: HugeIcons.strokeRoundedTextFont,
        label: 'Font Family',
        selectedItem: DropdownItem(
          value: controller.fontFamily.value,
          text: controller.fontFamily.value,
        ),
        onChanged: (value) {
          controller.setFontFamily(value.value);
        },
        items: controller.availableFonts
            .map((font) => DropdownItem(
                  value: font,
                  text: font,
                ))
            .toList(),
      );
    });
  }

  Widget _buildTtsVoiceSelector(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: FlutterTts().getVoices,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        List<String> voices = snapshot.data!
            .map<String>((voice) => voice['name'] ?? '')
            .where((name) => name.isNotEmpty)
            .toList();

        return Obx(() {
          return AnymexDropdown(
            icon: Icons.record_voice_over,
            label: 'Voice',
            selectedItem: DropdownItem(
              value: controller.ttsVoice.value,
              text: controller.ttsVoice.value.isEmpty
                  ? 'Default'
                  : controller.ttsVoice.value,
            ),
            onChanged: (value) {
              controller.setTtsVoice(value.value);
            },
            items: [
              const DropdownItem(value: '', text: 'Default'),
              ...voices.map((voice) => DropdownItem(
                    value: voice,
                    text: voice,
                  )),
            ],
          );
        });
      },
    );
  }

  Widget _buildThemeOption(BuildContext context, String label, int value, IconData icon) {
    return Obx(() {
      final isSelected = controller.themeMode.value == value;
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          controller.themeMode.value = value;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.primary.opaque(0.1)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? context.colors.primary
                  : context.colors.outline.opaque(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? context.colors.primary
                    : context.colors.onSurface,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSwitchSetting(
    BuildContext context, {
    required String title,
    String? subtitle,
    required RxBool value,
    required Function(bool) onChanged,
  }) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: value.value
              ? context.colors.primary.opaque(0.1)
              : Colors.transparent,
          border: Border.all(
            color: value.value
                ? context.colors.primary
                : context.colors.outline.opaque(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: value.value
                          ? context.colors.primary
                          : context.colors.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSurface.opaque(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value.value,
              onChanged: onChanged,
              activeColor: context.colors.primary,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSliderSetting(
    BuildContext context, {
    required String title,
    required RxDouble value,
    required double min,
    required double max,
    int? divisions,
    required String Function(double) label,
    Function(double)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: context.colors.onSurface,
              ),
            ),
            Obx(() => Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label(value.value),
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )),
          ],
        ),
        Obx(() => Slider(
              value: value.value,
              min: min,
              max: max,
              divisions: divisions,
              label: value.value.toStringAsFixed(1),
              onChanged: onChanged ?? (newValue) => value.value = newValue,
              activeColor: context.colors.primary,
              inactiveColor: context.colors.primary.opaque(0.3),
            )),
      ],
    );
  }

  Widget _buildTextAlignment(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text Alignment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Obx(() => Row(
              children: [
                _buildAlignmentButton(
                  context,
                  Icons.format_align_left,
                  'Left',
                  0,
                ),
                const SizedBox(width: 12),
                _buildAlignmentButton(
                  context,
                  Icons.format_align_center,
                  'Center',
                  1,
                ),
                const SizedBox(width: 12),
                _buildAlignmentButton(
                  context,
                  Icons.format_align_justify,
                  'Justify',
                  2,
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildAlignmentButton(
    BuildContext context,
    IconData icon,
    String label,
    int value,
  ) {
    final isSelected = controller.textAlign.value == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          controller.setTextAlign(value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.primary.opaque(0.1)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? context.colors.primary
                  : context.colors.outline.opaque(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? context.colors.primary
                    : context.colors.onSurface,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          controller.resetSettings();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.primary,
          foregroundColor: context.colors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Reset to Default',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
