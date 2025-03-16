import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Carousel/carousel.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_chip.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
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
              padding: const EdgeInsets.fromLTRB(15.0, 50.0, 15.0, 20.0),
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
                                  onTap: showCardStyleSwitcher,
                                  icon: Iconsax.card5,
                                  title: "Card Style",
                                  description: "Change card style",
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

  void showCardStyleSwitcher() {
    final selectedStyle = CardStyle.values[settingsController.cardStyle].obs;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Obx(
          () {
            return AnymexDialog(
                title: 'Card Style',
                onConfirm: () {
                  settingsController.cardStyle = selectedStyle.value.index;
                },
                contentWidget: CardStyleSelector(
                    onStyleChanged: (e) {
                      selectedStyle.value = e;
                    },
                    initialStyle: selectedStyle.value,
                    sampleData: convertData(trendingAnimes)[0]));
          },
        );
      },
    );
  }
}

class CardStyleSelector extends StatefulWidget {
  final Function(CardStyle) onStyleChanged;
  final CardStyle initialStyle;
  final CarouselData sampleData;

  const CardStyleSelector({
    super.key,
    required this.onStyleChanged,
    required this.initialStyle,
    required this.sampleData,
  });

  @override
  State<CardStyleSelector> createState() => _CardStyleSelectorState();
}

class _CardStyleSelectorState extends State<CardStyleSelector> {
  late CardStyle _selectedStyle;
  final Map<CardStyle, String> styleDescriptions = {
    CardStyle.saikou:
        'A minimalist design focused on efficiency with less visual elements.',
    CardStyle.modern:
        'Clean, contemporary design with balanced proportions and subtle shadows.',
    CardStyle.exotic:
        'Traditional card layout with familiar elements and standard formatting.',
  };

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.initialStyle;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: CardStyle.values
                .map((style) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildStyleChip(style),
                    ))
                .toList(),
          ),
        ),
        10.height(),
        AnymexCard(
          enableAnimation: true,
          padding: const EdgeInsets.all(10),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: getCardHeight(_selectedStyle, getPlatform(context)),
              child: MediaCardGate(
                key: ValueKey(_selectedStyle),
                cardStyle: _selectedStyle,
                itemData: widget.sampleData,
                tag: '',
                variant: DataVariant.regular,
                isManga: false,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyleChip(CardStyle style) {
    final bool isSelected = style == _selectedStyle;

    return AnymexChip(
      isSelected: isSelected,
      label: style.name.capitalize!,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedStyle = style;
          });
          widget.onStyleChanged(style);
        }
      },
    );
  }
}
