import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnymeXSectionBuilder(
              margin: const EdgeInsets.only(bottom: 12),
              children: [
                AnymeXTile.toggle(
                  icon: Icons.brightness_6_rounded,
                  title: context.l10n.customBrightness,
                  subtitle: context.l10n.overrideSystemScreenBrightness,
                  value: customBrightness,
                  onChanged: (_) => controller.toggleCustomBrightness(),
                ),
                if (customBrightness)
                  AnymeXTile.slider(
                    title: context.l10n.brightness,
                    icon: Icons.wb_sunny_rounded,
                    subtitle: context.l10n.range75DarkestTo100,
                    value: controller.customBrightnessValue.value.toDouble(),
                    min: -75,
                    max: 100,
                    divisions: 175,
                    onChanged: (v) =>
                        controller.customBrightnessValue.value = v.toInt(),
                  ),
              ],
            ),
            AnymeXSectionBuilder(
              margin: const EdgeInsets.only(bottom: 12),
              children: [
                AnymeXTile.toggle(
                  icon: Icons.color_lens_rounded,
                  title: context.l10n.colorFilter,
                  subtitle: context.l10n.applyAColorTintOverPages,
                  value: colorFilter,
                  onChanged: (_) => controller.toggleColorFilter(),
                ),
                if (colorFilter) ...[
                  AnymeXTile.slider(
                    title: context.l10n.red,
                    icon: Icons.circle,
                    subtitle: '0 – 255',
                    value: ((colorValue >> 16) & 0xFF).toDouble(),
                    min: 0,
                    max: 255,
                    divisions: 255,
                    onChanged: (v) =>
                        controller.setColorFilterChannel('r', v.toInt()),
                  ),
                  AnymeXTile.slider(
                    title: context.l10n.green,
                    icon: Icons.circle,
                    subtitle: '0 – 255',
                    value: ((colorValue >> 8) & 0xFF).toDouble(),
                    min: 0,
                    max: 255,
                    divisions: 255,
                    onChanged: (v) =>
                        controller.setColorFilterChannel('g', v.toInt()),
                  ),
                  AnymeXTile.slider(
                    title: context.l10n.blue,
                    icon: Icons.circle,
                    subtitle: '0 – 255',
                    value: (colorValue & 0xFF).toDouble(),
                    min: 0,
                    max: 255,
                    divisions: 255,
                    onChanged: (v) =>
                        controller.setColorFilterChannel('b', v.toInt()),
                  ),
                  AnymeXTile.slider(
                    title: context.l10n.alpha,
                    icon: Icons.opacity,
                    subtitle: '0 – 255',
                    value: ((colorValue >> 24) & 0xFF).toDouble(),
                    min: 0,
                    max: 255,
                    divisions: 255,
                    onChanged: (v) =>
                        controller.setColorFilterChannel('a', v.toInt()),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymeXText(
                          'Blend Mode',
                          size: 13,
                          variant: TextVariant.semiBold,
                          color: context.colors.onSurfaceVariant,
                        ),
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
              ],
            ),
            AnymeXSectionBuilder(
              margin: const EdgeInsets.only(bottom: 20),
              children: [
                AnymeXTile.toggle(
                  icon: Icons.gradient_rounded,
                  title: 'Grayscale',
                  subtitle: 'Display pages in black & white',
                  value: controller.grayscaleEnabled.value,
                  onChanged: (_) => controller.toggleGrayscale(),
                ),
                AnymeXTile.toggle(
                  icon: Icons.invert_colors_rounded,
                  title: context.l10n.invertColors,
                  subtitle: context.l10n.invertAllPageColors,
                  value: controller.invertColorsEnabled.value,
                  onChanged: (_) => controller.toggleInvertColors(),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
