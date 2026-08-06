import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ColorFilterSettingsPage extends StatelessWidget {
  const ColorFilterSettingsPage({super.key, required this.controller});

  final ReaderController controller;

  static const List<String> _blendModeLabels = [
    'Default',
    'Multiply',
    'Screen',
    'Overlay',
    'Darken',
    'Lighten',
    'Color Dodge',
    'Color Burn',
    'Hard Light',
    'Soft Light',
    'Difference',
    'Exclusion',
    'Hue',
    'Saturation',
    'Color',
    'Luminosity',
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final customBrightness = controller.customBrightnessEnabled.value;
      final colorFilter = controller.colorFilterEnabled.value;
      final colorValue = controller.colorFilterValue.value;
      final blendMode = controller.colorFilterMode.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomSwitchTile(
              icon: Icons.brightness_6_rounded,
              title: 'Custom Brightness',
              description: 'Override system screen brightness',
              switchValue: customBrightness,
              onChanged: (_) => controller.toggleCustomBrightness(),
            ),
            if (customBrightness)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: CustomSliderTile(
                  title: 'Brightness',
                  icon: Icons.wb_sunny_rounded,
                  description: 'Range: -75 (darkest) to 100',
                  sliderValue: controller.customBrightnessValue.value.toDouble(),
                  min: -75,
                  max: 100,
                  divisions: 175,
                  label: controller.customBrightnessValue.value.toString(),
                  onChanged: (v) =>
                      controller.customBrightnessValue.value = v.toInt(),
                  onChangedEnd: (_) => controller.savePreferences(),
                ),
              ),

            const Divider(height: 24),
            
            CustomSwitchTile(
              icon: Icons.color_lens_rounded,
              title: 'Color Filter',
              description: 'Apply a color tint over pages',
              switchValue: colorFilter,
              onChanged: (_) => controller.toggleColorFilter(),
            ),
            if (colorFilter) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: CustomSliderTile(
                  title: 'Red',
                  icon: Icons.circle,
                  description: '0 – 255',
                  sliderValue: ((colorValue >> 16) & 0xFF).toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  label: ((colorValue >> 16) & 0xFF).toString(),
                  onChanged: (v) => controller.setColorFilterChannel(
                      'r', v.toInt()),
                  onChangedEnd: (_) => controller.savePreferences(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: CustomSliderTile(
                  title: 'Green',
                  icon: Icons.circle,
                  description: '0 – 255',
                  sliderValue: ((colorValue >> 8) & 0xFF).toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  label: ((colorValue >> 8) & 0xFF).toString(),
                  onChanged: (v) => controller.setColorFilterChannel(
                      'g', v.toInt()),
                  onChangedEnd: (_) => controller.savePreferences(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: CustomSliderTile(
                  title: 'Blue',
                  icon: Icons.circle,
                  description: '0 – 255',
                  sliderValue: (colorValue & 0xFF).toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  label: (colorValue & 0xFF).toString(),
                  onChanged: (v) => controller.setColorFilterChannel(
                      'b', v.toInt()),
                  onChangedEnd: (_) => controller.savePreferences(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: CustomSliderTile(
                  title: 'Alpha',
                  icon: Icons.opacity,
                  description: '0 – 255',
                  sliderValue: ((colorValue >> 24) & 0xFF).toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  label: ((colorValue >> 24) & 0xFF).toString(),
                  onChanged: (v) => controller.setColorFilterChannel(
                      'a', v.toInt()),
                  onChangedEnd: (_) => controller.savePreferences(),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Blend Mode',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(
                        _blendModeLabels.length,
                        (i) => ChoiceChip(
                          label: Text(_blendModeLabels[i]),
                          selected: blendMode == i,
                          onSelected: (_) {
                            controller.colorFilterMode.value = i;
                            controller.savePreferences();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 24),
            
            CustomSwitchTile(
              icon: Icons.gradient_rounded,
              title: 'Grayscale',
              description: 'Display pages in black & white',
              switchValue: controller.grayscaleEnabled.value,
              onChanged: (_) => controller.toggleGrayscale(),
            ),
            CustomSwitchTile(
              icon: Icons.invert_colors_rounded,
              title: 'Invert Colors',
              description: 'Invert all page colors',
              switchValue: controller.invertColorsEnabled.value,
              onChanged: (_) => controller.toggleInvertColors(),
            ),

            const SizedBox(height: 16),
          ],
        ),
      );
    });
  }
}
