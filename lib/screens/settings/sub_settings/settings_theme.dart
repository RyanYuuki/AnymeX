import 'dart:math' show Random;
import 'package:anymex/constants/contants.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/widgets/common/checkmark_tile.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
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
  late bool isGrid = true;
  late int selectedVariantIndex;

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
    themeMode = provider.isSystemMode ? "System" : provider.isLightMode ? "Light" : "Dark";
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
            padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.surfaceContainer),
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
                Text("Appearance",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 10),
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
                  icon: HugeIcons.strokeRoundedBlur,
                  title: "Material You",
                  description: "Take color from your wallpaper (A12+)",
                  switchValue: materialTheme,
                  onChanged: handleMaterialSwitch,
                ),
                const SizedBox(height: 10),
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
                CustomSwitchTile(
                  icon: HugeIcons.strokeRoundedColors,
                  title: "Custom Theme",
                  description: "Choose your favourite color!",
                  switchValue: customTheme,
                  onChanged: handleCustomThemeSwitch,
                ),
                if (customTheme)
                  CustomTile(
                    icon: HugeIcons.strokeRoundedColors,
                    title: "Choose Colors from dialog",
                    description: "Choose your favourite color from dialog!",
                    onTap: () {
                      showColorSelectionDialog(context);
                    },
                  ),
                const SizedBox(height: 10),
                if (customTheme) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Custom Themes",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                          onPressed: () {
                            setState(() {
                              isGrid = !isGrid;
                            });
                          },
                          icon: Icon(
                            isGrid
                                ? Icons.grid_view_rounded
                                : HugeIcons.strokeRoundedGridTable,
                            color: Theme.of(context).colorScheme.primary,
                          ))
                    ],
                  ),
                  const SizedBox(height: 10),
                  isGrid
                      ? SingleChildScrollView(child: _buildColorTemplates())
                      : _buildColorButtons()
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
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: ListView.builder(
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
                          leading:
                              const Icon(HugeIcons.strokeRoundedColorPicker),
                          title: label,
                          onTap: () => handlePaletteChange(index),
                        ),
                      );
                    },
                  ),
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
                                  fontFamily: "LexendDeca",
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

  void showColorSelectionDialog(BuildContext context) {
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
                  'Custom Colors',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: colorList.length,
                    itemBuilder: (context, index) {
                      Color color = colorList[index];
                      bool isSelected = index == selectedColorIndex;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        child: ListTileWithCheckMark(
                          color: color,
                          active: isSelected,
                          leading: CircleAvatar(
                            backgroundColor: color,
                            radius: 12,
                          ),
                          title: colorKeys[index],
                          onTap: () {
                            handleColorSelection(index);
                          },
                        ),
                      );
                    },
                  ),
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
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 14,
                                  fontFamily: "LexendDeca",
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
          return GestureDetector(
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
                      dektopSize: 300),
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

  Widget _buildColorButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colorList.asMap().entries.map((entry) {
        int index = entry.key;
        Color color = entry.value;
        bool isSelected = index == selectedColorIndex;

        return GestureDetector(
          onTap: () {
            handleColorSelection(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(
                                Theme.of(context).brightness == Brightness.dark
                                    ? 0.3
                                    : 0.6),
                        blurRadius: 15.0,
                        spreadRadius: 2.0,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedOpacity(
                    opacity: isSelected ? 1.0 : 0.8,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(
                                HugeIcons.strokeRoundedSparkles,
                                color: Colors.white,
                                size: 20,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    colorKeys[index],
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.surface
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
