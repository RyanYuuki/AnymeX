import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

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
            AnymeXTile.toggle(
              icon: Icons.brightness_6_rounded,
              title: 'Custom Brightness',
              subtitle: 'Override system screen brightness',
              value: customBrightness,
              onChanged: (_) => controller.toggleCustomBrightness(),
            ),
            if (customBrightness)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AnymeXTile.slider(
                  title: 'Brightness',
                  icon: Icons.wb_sunny_rounded,
                  subtitle: 'Range: -75 (darkest) to 100',
                  value: controller.customBrightnessValue.value.toDouble(),
                  min: -75,
                  max: 100,
                  divisions: 175,
                  onChanged: (v) =>
                      controller.customBrightnessValue.value = v.toInt(),
                ),
              ),

            const Divider(height: 24),
            
            AnymeXTile.toggle(
              icon: Icons.color_lens_rounded,
              title: 'Color Filter',
              subtitle: 'Apply a color tint over pages',
              value: colorFilter,
              onChanged: (_) => controller.toggleColorFilter(),
            ),
            if (colorFilter) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AnymeXTile.slider(
                  title: 'Red',
                  icon: Icons.circle,
                  subtitle: '0 – 255',
                  value: ((colorValue >> 16) & 0xFF).toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  onChanged: (v) => controller.setColorFilterChannel(
                      'r', v.toInt()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AnymeXTile.slider(
                  title: 'Green',
                  icon: Icons.circle,
                  subtitle: '0 – 255',
                  value: ((colorValue >> 8) & 0xFF).toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  onChanged: (v) => controller.setColorFilterChannel(
                      'g', v.toInt()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AnymeXTile.slider(
                  title: 'Blue',
                  icon: Icons.circle,
                  subtitle: '0 – 255',
                  value: (colorValue & 0xFF).toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  onChanged: (v) => controller.setColorFilterChannel(
                      'b', v.toInt()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AnymeXTile.slider(
                  title: 'Alpha',
                  icon: Icons.opacity,
                  subtitle: '0 – 255',
                  value: ((colorValue >> 24) & 0xFF).toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  onChanged: (v) => controller.setColorFilterChannel(
                      'a', v.toInt()),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymeXText('Blend Mode',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(
                        _blendModeLabels.length,
                        (i) => ChoiceChip(
                          label: AnymeXText(_blendModeLabels[i]),
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
            
            AnymeXTile.toggle(
              icon: Icons.gradient_rounded,
              title: 'Grayscale',
              subtitle: 'Display pages in black & white',
              value: controller.grayscaleEnabled.value,
              onChanged: (_) => controller.toggleGrayscale(),
            ),
            AnymeXTile.toggle(
              icon: Icons.invert_colors_rounded,
              title: 'Invert Colors',
              subtitle: 'Invert all page colors',
              value: controller.invertColorsEnabled.value,
              onChanged: (_) => controller.toggleInvertColors(),
            ),

            const SizedBox(height: 16),
          ],
        ),
      );
    });
  }
}
