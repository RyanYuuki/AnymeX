import 'package:anymex/controllers/Settings/settings.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class SettingsUi extends StatefulWidget {
  const SettingsUi({super.key});

  @override
  State<SettingsUi> createState() => _SettingsUiState();
}

class _SettingsUiState extends State<SettingsUi> {
  final settings = Get.find<Settings>();

  void handleSliderChange(String property, double value) {
    setState(() {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const SizedBox(width: 10),
                  const Text("UI",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              const SizedBox(height: 30),
              Text("Common",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 10),
              Column(
                children: [
                  CustomSliderTile(
                    icon: HugeIcons.strokeRoundedLighthouse,
                    title: "Glow Multiplier",
                    description: "Adjust the glow of all the elements",
                    sliderValue: settings.glowMultiplier,
                    onChanged: (value) =>
                        handleSliderChange('glowMultiplier', value),
                    max: 5.0,
                  ),
                  const SizedBox(height: 20),
                  CustomSliderTile(
                    icon: HugeIcons.strokeRoundedRadius,
                    title: "Radius Multiplier",
                    description: "Adjust the radius of all the elements",
                    sliderValue: settings.radiusMultiplier,
                    onChanged: (value) =>
                        handleSliderChange('radiusMultiplier', value),
                    max: 3.0,
                  ),
                  const SizedBox(height: 20),
                  CustomSliderTile(
                    icon: HugeIcons.strokeRoundedRadius,
                    title: "Blur Multiplier",
                    description: "Adjust the Glow Blur of all the elements",
                    sliderValue: settings.blurMultiplier,
                    onChanged: (value) =>
                        handleSliderChange('blurMultiplier', value),
                    max: 5.0,
                  ),
                  const SizedBox(height: 20),
                  CustomSliderTile(
                    icon: HugeIcons.strokeRoundedRadius,
                    title: "Card Roundness",
                    description: "Adjust the Roundness of All Cards",
                    sliderValue: settings.cardRoundness,
                    onChanged: (value) =>
                        handleSliderChange('cardRoundness', value),
                    max: 5.0,
                  ),
                  const SizedBox(height: 20),
                  CustomSliderTile(
                    icon: HugeIcons.strokeRoundedRadius,
                    title: "Card Animation Duration",
                    description: "Adjust the Animation of All Cards",
                    sliderValue: settings.animationDuration.toDouble(),
                    onChanged: (value) =>
                        handleSliderChange('animation', value),
                    max: 1000,
                    divisions: 10,
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
