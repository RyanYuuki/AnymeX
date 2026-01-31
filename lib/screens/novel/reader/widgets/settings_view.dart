import 'package:anymex/screens/novel/reader/controller/reader_controller.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

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
            color: context.colors.surface.opaque(0.8),
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
                _buildSettingsContent(context),
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

  Widget _buildSettingsContent(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildFontSettings(context),
          const SizedBox(height: 24),
          _buildSpacingSettings(context),
          const SizedBox(height: 24),
          _buildAlignmentSettings(context),
          const SizedBox(height: 24),
          _buildResetButton(context),
        ],
      ),
    );
  }

  Widget _buildFontSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
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
          max: 2.5,
          divisions: 15,
          label: (value) => value.toStringAsFixed(1),
        ),
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
            text: controller.fontFamily.value),
        onChanged: (value) {
          controller.fontFamily.value = value.value;
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

  Widget _buildSpacingSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spacing',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
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
    );
  }

  Widget _buildAlignmentSettings(BuildContext context) {
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
          controller.textAlign.value = value;
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

  Widget _buildSliderSetting(
    BuildContext context, {
    required String title,
    required RxDouble value,
    required double min,
    required double max,
    int? divisions,
    required String Function(double) label,
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
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
              year2023: false,
              divisions: divisions,
              label: value.value.toStringAsFixed(1),
              onChanged: (newValue) {
                value.value = newValue;
                controller.novelContent.refresh();
              },
              activeColor: context.colors.primary,
              inactiveColor:
                  context.colors.primary.opaque(0.3),
            )),
      ],
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
