import 'package:anymex/constants/contants.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/common/checkmark_tile.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/custom_icon_wrapper.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';

class SettingsPlayer extends StatefulWidget {
  final bool isModal;
  const SettingsPlayer({super.key, this.isModal = false});

  @override
  State<SettingsPlayer> createState() => _SettingsPlayerState();
}

class _SettingsPlayerState extends State<SettingsPlayer> {
  final settings = Get.find<Settings>();
  RxDouble speed = 0.0.obs;
  RxString resizeMode = "Contain".obs;
  Rx<Color> subtitleColor = Colors.white.obs;
  Rx<Color> backgroundColor = Colors.black.obs;
  Rx<Color> outlineColor = Colors.black.obs;
  final styles = ['Regular', 'Accent', 'Blurred Accent'];
  final selectedStyleIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    speed.value = settings.speed;
    selectedStyleIndex.value = settings.playerStyle;
  }

  String numToPlayerStyle(int i) {
    return (i >= 0 && i < styles.length) ? styles[i] : 'Unknown';
  }

  int styleToNum(String i) {
    return styles.indexOf(i);
  }

  void _showPlaybackSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: getResponsiveValue(context,
                  mobileValue: null, desktopValue: 500.0),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PlayBack Speeds',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: cursedSpeed.length,
                      itemBuilder: (context, index) {
                        double speedd = cursedSpeed[index];

                        return Obx(() => Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              child: ListTileWithCheckMark(
                                leading: const Icon(Icons.speed),
                                color: Theme.of(context).colorScheme.primary,
                                active: speedd == speed.value,
                                title: '${speedd.toStringAsFixed(2)}x',
                                onTap: () {
                                  speed.value = speedd;
                                  settings.speed = speedd;
                                },
                              ),
                            ));
                      },
                    ),
                  ),
                ],
              ),
            ));
      },
    );
  }

  void showPlayerStyleDialog() {
    showSelectionDialog<int>(
        title: "Player Theme",
        items: [0, 1, 2],
        selectedItem: selectedStyleIndex,
        getTitle: (i) => numToPlayerStyle(i),
        onItemSelected: (i) {
          selectedStyleIndex.value = i;
          settings.playerStyle = i;
        });
  }

  void _showResizeModeDialog() {
    showSelectionDialog<String>(
      title: 'Playback Speeds',
      items: resizeModeList,
      selectedItem: resizeMode,
      getTitle: (item) => item,
      onItemSelected: (selected) {
        resizeMode.value = selected;
        settings.resizeMode = selected;
      },
      leadingIcon: Icons.speed,
    );
  }

  void _showColorSelectionDialog(
      String title, Color currentColor, Function(String) onColorSelected) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontFamily: 'Poppins-SemiBold',
                fontSize: 20),
          ),
          content: SizedBox(
            height: 300,
            width: double.maxFinite,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: colorOptions.entries.map((entry) {
                return RadioListTile<Color>(
                  title: Text(entry.key),
                  value: entry.value,
                  groupValue: currentColor,
                  onChanged: (Color? value) {
                    if (value != null) {
                      onColorSelected(entry.key);
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        backgroundColor: widget.isModal
            ? Theme.of(context).colorScheme.surfaceContainer
            : Colors.transparent,
        body: SingleChildScrollView(
          child: Padding(
            padding: getResponsiveValue(context,
                mobileValue: const EdgeInsets.fromLTRB(10.0, 50.0, 10.0, 20.0),
                desktopValue:
                    const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isModal) ...[
                  const Center(
                    child: Text("Player Settings",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                  )
                ] else ...[
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
                      const Text("Player Settings",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                    ],
                  ),
                ],
                const SizedBox(height: 30),
                Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymexExpansionTile(
                            initialExpanded: true,
                            title: 'Common',
                            content: Column(
                              children: [
                                CustomTile(
                                  padding: 10,
                                  descColor:
                                      Theme.of(context).colorScheme.primary,
                                  isDescBold: true,
                                  icon: HugeIcons.strokeRoundedPlaySquare,
                                  onTap: () {
                                    showPlayerStyleDialog();
                                  },
                                  title: "Player Theme",
                                  description:
                                      numToPlayerStyle(settings.playerStyle),
                                ),
                                CustomSwitchTile(
                                    padding: const EdgeInsets.all(10),
                                    icon: Icons.stay_current_portrait,
                                    title: "Default Portrait",
                                    description:
                                        "For psychopath who watch in portrait",
                                    switchValue: settings.defaultPortraitMode,
                                    onChanged: (val) =>
                                        settings.defaultPortraitMode = val),
                                CustomTile(
                                  padding: 10,
                                  isDescBold: true,
                                  icon: Icons.speed,
                                  descColor:
                                      Theme.of(context).colorScheme.primary,
                                  onTap: _showPlaybackSpeedDialog,
                                  title: "Playback Speed",
                                  description:
                                      '${settings.speed.toStringAsFixed(1)}x',
                                ),
                                // Resize Mode
                                CustomTile(
                                  padding: 10,
                                  icon: Icons.aspect_ratio,
                                  title: 'Resize Mode',
                                  isDescBold: true,
                                  description: settings.resizeMode,
                                  descColor:
                                      Theme.of(context).colorScheme.primary,
                                  onTap: () {
                                    _showResizeModeDialog();
                                  },
                                ),
                                CustomSliderTile(
                                  sliderValue: settings.seekDuration.toDouble(),
                                  max: 50,
                                  divisions: 9,
                                  onChanged: (double value) {
                                    setState(() {
                                      settings.seekDuration = value.toInt();
                                    });
                                  },
                                  title: 'DoubleTap to Seek',
                                  description:
                                      'Adjust Double Tap To Seek Duration',
                                  icon: Iconsax.forward5,
                                ),
                                CustomSliderTile(
                                  sliderValue: settings.skipDuration.toDouble(),
                                  max: 120,
                                  divisions: 24,
                                  onChanged: (double value) {
                                    settings.skipDuration = value.toInt();
                                  },
                                  title: 'MegaSkip Duration',
                                  description: 'Adjust MegaSkip Duration',
                                  icon: Iconsax.forward5,
                                ),
                              ],
                            )),
                        // Subtitle Color
                        AnymexExpansionTile(
                            title: 'Subtitles',
                            content: Column(
                              children: [
                                CustomTile(
                                  padding: 10,
                                  description: 'Change subtitle colors',
                                  icon: Icons.palette,
                                  title: 'Subtitle Color',
                                  onTap: () {
                                    _showColorSelectionDialog(
                                        'Select Subtitle Color',
                                        fontColorOptions[
                                            settings.subtitleColor]!, (color) {
                                      settings.subtitleColor = color;
                                    });
                                  },
                                ),
                                // Subtitle Outline Color
                                CustomTile(
                                  padding: 10,
                                  icon: Icons.palette,
                                  title: 'Subtitle Outline Color',
                                  description: 'Change subtitle outline color',
                                  onTap: () {
                                    _showColorSelectionDialog(
                                        'Select Subtitle Outline Color',
                                        colorOptions[settings
                                            .subtitleOutlineColor]!, (color) {
                                      settings.subtitleOutlineColor = color;
                                    });
                                  },
                                ),

                                CustomTile(
                                  padding: 10,
                                  description:
                                      'Change subtitle background color',
                                  icon: Icons.palette,
                                  title: 'Subtitle Background Color',
                                  onTap: () {
                                    _showColorSelectionDialog(
                                        'Select Subtitle Background Color',
                                        colorOptions[
                                            settings.subtitleBackgroundColor]!,
                                        (color) {
                                      settings.subtitleBackgroundColor = color;
                                    });
                                  },
                                ),
                                // Subtitle Preview
                                CustomSliderTile(
                                  sliderValue: settings.subtitleSize.toDouble(),
                                  min: 12.0,
                                  max: 30.0,
                                  divisions: 18,
                                  onChanged: (double value) {
                                    settings.subtitleSize = value.toInt();
                                  },
                                  title: 'Subtitle Size',
                                  description: 'Adjust Sub Size',
                                  icon: Iconsax.subtitle5,
                                ),
                                const SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 17.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Subtitle Preview',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            color: colorOptions[settings
                                                .subtitleBackgroundColor],
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        padding: const EdgeInsets.all(10),
                                        child: Text(
                                          'Subtitle Preview Text',
                                          style: TextStyle(
                                            color: colorOptions[
                                                settings.subtitleColor],
                                            fontSize: settings.subtitleSize
                                                .toDouble(),
                                            shadows: [
                                              Shadow(
                                                offset: const Offset(1.0, 1.0),
                                                blurRadius: 10.0,
                                                color: fontColorOptions[settings
                                                    .subtitleOutlineColor]!,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )),
                      ],
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
