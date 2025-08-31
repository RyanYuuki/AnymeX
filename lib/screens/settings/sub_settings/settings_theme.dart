import 'package:anymex/constants/contants.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/liquid.dart';
import 'package:anymex/widgets/common/checkmark_tile.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import 'package:provider/provider.dart';

class SettingsTheme extends StatefulWidget {
  const SettingsTheme({super.key});

  @override
  State<SettingsTheme> createState() => _SettingsThemeState();
}

class _SettingsThemeState extends State<SettingsTheme> {
  late bool defaultTheme;
  late bool materialTheme;
  late bool customTheme;
  late int selectedColorIndex;
  late bool isOled;
  late int selectedVariantIndex;
  final settings = Get.find<Settings>();

  final List<Map<String, dynamic>> themeModes = [
    {"label": "Light", "color": Colors.white},
    {"label": "Dark", "color": Colors.black},
    {"label": "System", "color": Colors.black}
  ];
  String themeMode = "Light";
  late List<Map<String, dynamic>> customColorMap;

  @override
  void initState() {
    super.initState();
    _initializeDbVars();
  }

  void handleThemeMode(String theme) {
    final provider = Provider.of<ThemeProvider>(context, listen: false);

    switch (theme) {
      case "Light":
        provider.setLightMode();
        break;

      case "Dark":
        provider.setDarkMode();
        break;

      case "System":
        provider.setSystemMode();
        break;

      default:
        provider.setLightMode();
    }
    customColorMap = colorMap.entries.map((entry) {
      return {
        "label": entry.key,
        "color": entry.value,
      };
    }).toList();
    setState(() {
      themeMode = theme;
    });
  }

  void _initializeDbVars() {
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    final box = Hive.box("themeData");
    defaultTheme = provider.currentThemeMode == "default";
    materialTheme = provider.currentThemeMode == "material";
    customTheme = provider.currentThemeMode == "custom";
    selectedColorIndex = box.get("customColorIndex", defaultValue: 0);
    isOled = provider.isOled;
    themeMode = provider.isSystemMode
        ? "System"
        : provider.isLightMode
            ? "Light"
            : "Dark";
    selectedVariantIndex = provider.selectedVariantIndex;
  }

  void handleDefaultSwitch(bool value) {
    if (value) {
      setState(() {
        defaultTheme = true;
        materialTheme = false;
        customTheme = false;
      });
      Provider.of<ThemeProvider>(context, listen: false).setDefaultTheme();
    }
  }

  void handleMaterialSwitch(bool value) {
    if (value) {
      setState(() {
        materialTheme = true;
        defaultTheme = false;
        customTheme = false;
      });
      Provider.of<ThemeProvider>(context, listen: false).loadDynamicTheme();
    }
  }

  void handleCustomThemeSwitch(bool value) {
    if (value) {
      setState(() {
        customTheme = true;
        defaultTheme = false;
        materialTheme = false;
      });
      Provider.of<ThemeProvider>(context, listen: false)
          .setCustomSeedColor(selectedColorIndex);
    }
  }

  void handlePaletteChange(int index) {
    setState(() {
      selectedVariantIndex = index;
    });
    Provider.of<ThemeProvider>(context, listen: false)
        .updateSchemeVariant(selectedVariantIndex);
  }

  void handleOledSwitch(bool value) {
    setState(() {
      isOled = value;
    });
    Provider.of<ThemeProvider>(context, listen: false).toggleOled(value);
  }

  void handleColorSelection(int index) {
    setState(() {
      selectedColorIndex = index;
    });
    Provider.of<ThemeProvider>(context, listen: false)
        .setCustomSeedColor(selectedColorIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 50.0, 10.0, 20.0),
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
                                .withOpacity(0.5)),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded)),
                    const SizedBox(width: 10),
                    const Text("Theme",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 30),
                AnymexExpansionTile(
                  title: 'Appearance',
                  content: Column(
                    children: [
                      _buildModeTemplates(),
                      const SizedBox(height: 30),
                      CustomSwitchTile(
                        icon: HugeIcons.strokeRoundedPaintBrush01,
                        title: "Default Theme",
                        description: "Play around with App theme",
                        switchValue: defaultTheme,
                        onChanged: handleDefaultSwitch,
                      ),
                      const SizedBox(height: 10),
                      CustomSwitchTile(
                        icon: HugeIcons.strokeRoundedImage01,
                        title: "Material You",
                        description: "Take color from your wallpaper (A12+)",
                        switchValue: materialTheme,
                        onChanged: handleMaterialSwitch,
                      ),
                      const SizedBox(height: 10),
                      Obx(() {
                        return Column(
                          children: [
                            CustomSwitchTile(
                              icon: HugeIcons.strokeRoundedBlur,
                              title: "Liquid Mode",
                              description:
                                  "Make everything glassy & liquidy...",
                              switchValue: settings.liquidMode,
                              onChanged: (e) {
                                settings.disableGradient = false;
                                settings.liquidMode = e;
                              },
                            ),
                            settings.liquidMode
                                ? Column(
                                    children: [
                                      const SizedBox(height: 10),
                                      CustomTile(
                                        icon: HugeIcons.strokeRoundedImageAdd01,
                                        title: "Liquid Background",
                                        description:
                                            "Choose a custom background for liquid mode.",
                                        onTap: () async {
                                          await Liquid.pickLiquidBackground(
                                              context);
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      CustomSwitchTile(
                                        switchValue:
                                            settings.retainOriginalColor,
                                        icon: HugeIcons
                                            .strokeRoundedImageComposition,
                                        title: "Retain Original Color",
                                        description:
                                            "Enable this if you want to retain the original color of your wallpaper",
                                        onChanged: (e) =>
                                            settings.retainOriginalColor = e,
                                      ),
                                      const SizedBox(height: 10),
                                      CustomSwitchTile(
                                        switchValue: settings.usePosterColor,
                                        icon: HugeIcons
                                            .strokeRoundedImageDownload,
                                        title: "Use Poster Color",
                                        description:
                                            "Applies anime/manga poster color on details page",
                                        onChanged: (e) =>
                                            settings.usePosterColor = e,
                                      ),
                                      const SizedBox(height: 10),
                                      CustomTile(
                                        icon: HugeIcons.strokeRoundedRefresh,
                                        title: "Reset to Default Picture",
                                        postFix: 0.width(),
                                        description:
                                            "Reset to default wallpaper!",
                                        onTap: () =>
                                            settings.liquidBackgroundPath = "",
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ],
                        );
                      }),
                    ],
                  ),
                  initialExpanded: true,
                ),
                const SizedBox(height: 10),
                AnymexExpansionTile(
                    initialExpanded: true,
                    title: 'Extras',
                    content: Column(
                      children: [
                        Obx(() {
                          return CustomSwitchTile(
                              disabled: settings.liquidMode,
                              icon: HugeIcons.strokeRoundedFlower,
                              title: "Bloom",
                              description:
                                  "Enables a soft, glowing gradient effect.",
                              switchValue: !settings.disableGradient,
                              onChanged: (val) =>
                                  settings.disableGradient = !val);
                        }),
                        CustomTile(
                          icon: HugeIcons.strokeRoundedPaintBoard,
                          title: "Palette",
                          description: "Choose your favourite palette!",
                          onTap: () {
                            showPaletteSelectionDialog(context);
                          },
                        ),
                        const SizedBox(height: 10),
                        CustomSwitchTile(
                          icon: HugeIcons.strokeRoundedMoon,
                          title: "Oled Mode",
                          description: "Go Super Dark Mode!",
                          switchValue: isOled,
                          onChanged: handleOledSwitch,
                        ),
                        const SizedBox(height: 10),
                        // ExpansionTile(title: AnymexText(text: "Custom Theme")),
                        CustomSwitchTile(
                          icon: HugeIcons.strokeRoundedColors,
                          title: "Custom Theme",
                          description: "Choose your favourite color!",
                          switchValue: customTheme,
                          onChanged: handleCustomThemeSwitch,
                        ),
                      ],
                    )),
                const SizedBox(height: 10),
                if (customTheme) ...[
                  AnymexCard(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymexText(
                          text: "Custom Themes",
                          size: 16,
                          variant: TextVariant.semiBold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(child: _buildColorTemplates())
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showPaletteSelectionDialog(BuildContext context) {
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
                  'Palettes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SuperListView.builder(
                  shrinkWrap: true,
                  itemCount: dynamicSchemeVariantKeys.length,
                  itemBuilder: (context, index) {
                    String label = dynamicSchemeVariantKeys[index];
                    bool isSelected = index == selectedVariantIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 7),
                      child: ListTileWithCheckMark(
                        color: Theme.of(context).colorScheme.primary,
                        active: isSelected,
                        leading: const Icon(HugeIcons.strokeRoundedColorPicker),
                        title: label,
                        onTap: () => handlePaletteChange(index),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            backgroundColor:
                                Theme.of(context).colorScheme.surfaceContainer,
                          ),
                          child: Text('Cancel',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryFixed,
                          ),
                          child: const Text('Confirm',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: "LexendDeca",
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeTemplates() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: themeModes.map<Widget>((theme) {
          final ColorScheme colorScheme = ColorScheme.fromSeed(
              seedColor: Theme.of(context).colorScheme.primary,
              brightness: theme['label'] == "Dark"
                  ? Brightness.dark
                  : Brightness.light);
          final ColorScheme lightScheme = ColorScheme.fromSeed(
              seedColor: Theme.of(context).colorScheme.primary,
              brightness: Brightness.light);
          final ColorScheme darkScheme = ColorScheme.fromSeed(
              seedColor: Theme.of(context).colorScheme.primary,
              brightness: Brightness.dark);
          bool isSelected = themeMode == theme['label'];
          bool isSystem = theme['label'] == "System";
          return AnymexOnTap(
            onTap: () {
              handleThemeMode(theme['label']);
            },
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  height: 150,
                  width: getResponsiveSize(context,
                      mobileSize: MediaQuery.of(context).size.width / 2,
                      desktopSize: 300),
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 3,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                    ),
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Positioned(
                          child: Container(
                              clipBehavior: Clip.antiAlias,
                              height: 150,
                              width: 300,
                              padding: const EdgeInsets.only(left: 10, top: 5),
                              decoration: BoxDecoration(
                                color: isSystem ? null : colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                gradient: isSystem
                                    ? LinearGradient(colors: [
                                        lightScheme.surface,
                                        darkScheme.surface
                                      ], stops: const [
                                        0.5,
                                        0.5
                                      ])
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                height: 50,
                                width: 100,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSystem
                                      ? null
                                      : colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: isSystem
                                      ? LinearGradient(colors: [
                                          lightScheme.surfaceContainer,
                                          darkScheme.surfaceContainer
                                        ], stops: const [
                                          0.5,
                                          0.5
                                        ])
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 10,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: isSystem
                                                  ? lightScheme.primary
                                                  : colorScheme.primary),
                                        ),
                                        Container(
                                          width: 20,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: isSystem
                                                ? null
                                                : colorScheme.secondary,
                                            gradient: isSystem
                                                ? LinearGradient(colors: [
                                                    lightScheme.secondary,
                                                    darkScheme.secondary
                                                  ], stops: const [
                                                    0.5,
                                                    0.5
                                                  ])
                                                : null,
                                          ),
                                        ),
                                        Container(
                                          width: 20,
                                          height: 10,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: isSystem
                                                  ? darkScheme
                                                      .secondaryContainer
                                                  : colorScheme
                                                      .secondaryContainer),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 10,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: isSystem
                                                  ? lightScheme.onPrimary
                                                  : colorScheme.onPrimary),
                                        ),
                                        Container(
                                          width: 20,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: isSystem
                                                ? null
                                                : colorScheme.tertiary,
                                            gradient: isSystem
                                                ? LinearGradient(colors: [
                                                    lightScheme.tertiary,
                                                    darkScheme.tertiary
                                                  ], stops: const [
                                                    0.5,
                                                    0.5
                                                  ])
                                                : null,
                                          ),
                                        ),
                                        Container(
                                          width: 20,
                                          height: 10,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: isSystem
                                                  ? darkScheme.primaryFixedDim
                                                  : colorScheme
                                                      .primaryFixedDim),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )),
                        ),
                        Positioned(
                            top: 10,
                            left: 10,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(50)),
                                ),
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.yellow,
                                      borderRadius: BorderRadius.circular(50)),
                                ),
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(50)),
                                ),
                              ],
                            )),
                        AnimatedPositioned(
                          bottom: 0,
                          right: 5,
                          duration: const Duration(milliseconds: 300),
                          child: AnimatedOpacity(
                            opacity: isSelected ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: Icon(
                                IconlyBold.tick_square,
                                size: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryFixedVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  theme['label'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorTemplates() {
    return GridView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: colorMap.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: getResponsiveCrossAxisCount(context),
          mainAxisExtent: 150,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10),
      itemBuilder: (context, index) {
        final theme = colorMap.entries.toList()[index];
        bool isSelected = selectedColorIndex == index;
        final ColorScheme colorScheme = ColorScheme.fromSeed(
            seedColor: theme.value, brightness: Theme.of(context).brightness);

        return GestureDetector(
          onTap: () {
            handleColorSelection(index);
          },
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 10),
                height: 120,
                width: MediaQuery.of(context).size.width / 2,
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 3,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? 0.3
                                    : 0.4),
                            blurRadius: 20,
                            spreadRadius: 4.0,
                            offset: const Offset(-2.0, 0),
                          ),
                        ]
                      : [],
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Positioned(
                        child: Container(
                            clipBehavior: Clip.antiAlias,
                            height: 150,
                            width: 300,
                            padding: const EdgeInsets.only(left: 10, top: 5),
                            decoration: BoxDecoration(
                              color: theme.value.withAlpha(140),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              height: 45,
                              width: 70,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(5)),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                        width: 15,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: colorScheme.primary),
                                      ),
                                      Container(
                                        width: 15,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: colorScheme.secondary),
                                      ),
                                      Container(
                                        width: 15,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: colorScheme.secondaryFixed),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                        width: 15,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: colorScheme.onPrimary),
                                      ),
                                      Container(
                                        width: 15,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: colorScheme.tertiary),
                                      ),
                                      Container(
                                        width: 15,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: colorScheme.primaryFixedDim),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )),
                      ),
                      Positioned(
                          top: 10,
                          left: 10,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(50)),
                              ),
                              Container(
                                width: 10,
                                height: 10,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                    color: Colors.yellow,
                                    borderRadius: BorderRadius.circular(50)),
                              ),
                              Container(
                                width: 10,
                                height: 10,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(50)),
                              ),
                            ],
                          )),
                      AnimatedPositioned(
                        bottom: 0,
                        right: 0,
                        duration: const Duration(milliseconds: 300),
                        child: AnimatedOpacity(
                          opacity: isSelected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: Icon(
                              IconlyBold.tick_square,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryFixedVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                theme.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}
