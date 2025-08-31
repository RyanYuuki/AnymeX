import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/settings/widgets/card_selector.dart';
import 'package:anymex/screens/settings/widgets/history_card_selector.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';

class SettingsUi extends StatefulWidget {
  const SettingsUi({super.key});

  @override
  State<SettingsUi> createState() => _SettingsUiState();
}

class _SettingsUiState extends State<SettingsUi> {
  final settings = Get.find<Settings>();

  void handleSliderChange(String property, double value) {
    switch (property) {
      case 'glowMultiplier':
        settings.glowMultiplier = value;
        break;
      case 'radiusMultiplier':
        settings.radiusMultiplier = value;
        break;
      case 'blurMultiplier':
        settings.blurMultiplier = value;
        break;
      case 'cardRoundness':
        settings.cardRoundness = value;
        break;
      case 'animation':
        settings.animationDuration = value.toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(15.0, 50.0, 15.0, 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainer
                              .withOpacity(0.5),
                        ),
                        onPressed: () {
                          Get.back();
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      const SizedBox(width: 10),
                      const Text("UI",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymexExpansionTile(
                            title: 'Common',
                            initialExpanded: true,
                            content: Column(
                              children: [
                                CustomSwitchTile(
                                    icon: HugeIcons.strokeRoundedBounceRight,
                                    title: "Enable Animation",
                                    description:
                                        "Enable Animation on Carousels, Disable it to get smoother experience",
                                    switchValue: settings.enableAnimation,
                                    onChanged: (val) {
                                      settings.enableAnimation = val;
                                    }),
                                CustomSwitchTile(
                                    icon: Icons.colorize,
                                    title: "Transculent Nav",
                                    description: "Enable transculent tab bar",
                                    switchValue: settings.transculentBar,
                                    onChanged: (val) {
                                      settings.transculentBar = val;
                                    }),
                                CustomTile(
                                  onTap: () => showCardStyleSwitcher(context),
                                  icon: Iconsax.card5,
                                  title: "Card Style",
                                  description: "Change card style",
                                ),
                                CustomTile(
                                  onTap: () =>
                                      showHistoryCardStyleSelector(context),
                                  icon: Iconsax.card5,
                                  title: "History Card Style",
                                  description: "Change history card style",
                                ),
                                10.height(),
                              ],
                            )),
                        AnymexExpansionTile(
                            title: 'Extras',
                            content: Column(
                              children: [
                                CustomSliderTile(
                                  icon: HugeIcons.strokeRoundedLighthouse,
                                  title: "Glow Multiplier",
                                  description:
                                      "Adjust the glow of all the elements",
                                  sliderValue: settings.glowMultiplier,
                                  onChanged: (value) => handleSliderChange(
                                      'glowMultiplier', value),
                                  max: 5.0,
                                ),
                                const SizedBox(height: 20),
                                CustomSliderTile(
                                  icon: HugeIcons.strokeRoundedRadius,
                                  title: "Radius Multiplier",
                                  description:
                                      "Adjust the radius of all the elements",
                                  sliderValue: settings.radiusMultiplier,
                                  onChanged: (value) => handleSliderChange(
                                      'radiusMultiplier', value),
                                  max: 3.0,
                                ),
                                const SizedBox(height: 20),
                                CustomSliderTile(
                                  icon: HugeIcons.strokeRoundedRadius,
                                  title: "Blur Multiplier",
                                  description:
                                      "Adjust the Glow Blur of all the elements",
                                  sliderValue: settings.blurMultiplier,
                                  onChanged: (value) => handleSliderChange(
                                      'blurMultiplier', value),
                                  max: 5.0,
                                ),
                                const SizedBox(height: 20),
                                CustomSliderTile(
                                  icon: HugeIcons.strokeRoundedRadius,
                                  title: "Card Roundness",
                                  description:
                                      "Adjust the Roundness of All Cards",
                                  sliderValue: settings.cardRoundness,
                                  onChanged: (value) => handleSliderChange(
                                      'cardRoundness', value),
                                  max: 5.0,
                                ),
                                const SizedBox(height: 20),
                                CustomSliderTile(
                                  icon: HugeIcons.strokeRoundedRadius,
                                  title: "Card Animation Duration",
                                  description:
                                      "Adjust the Animation of All Cards",
                                  sliderValue:
                                      settings.animationDuration.toDouble(),
                                  onChanged: (value) =>
                                      handleSliderChange('animation', value),
                                  max: 1000,
                                  divisions: 10,
                                ),
                              ],
                            )),
                      ],
                    ),
                  )
                ],
              )),
        ),
      ),
    );
  }
}
