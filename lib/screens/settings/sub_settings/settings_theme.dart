import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:anymex/constants/contants.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/logo_animation_type.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/liquid.dart';
import 'package:anymex/widgets/common/checkmark_tile.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/dialogs/logo_animation_preview_dialog.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/widgets/custom_widgets/anymex_tabbar.dart';

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
  late LogoAnimationType selectedLogoAnimation;
  static int _selectedTabIndex = 0;

  final List<Map<String, dynamic>> themeModes = [
    {"label": "Light", "color": Colors.white},
    {"label": "Dark", "color": Colors.black},
    {"label": "System", "color": Colors.black}
  ];
  String themeMode = "Light";
  late List<Map<String, dynamic>> customColorMap;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedTabIndex);
    _initializeDbVars();
    _initializeLogoAnimation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    defaultTheme = provider.currentThemeMode == "default";
    materialTheme = provider.currentThemeMode == "material";
    customTheme = provider.currentThemeMode == "custom";
    selectedColorIndex = ThemeKeys.customColorIndex.get<int>(0);
    isOled = provider.isOled;
    themeMode = provider.isSystemMode
        ? "System"
        : provider.isLightMode
            ? "Light"
            : "Dark";
    selectedVariantIndex = provider.selectedVariantIndex;
  }

  void _initializeLogoAnimation() {
    final animationIndex = ThemeKeys.logoAnimationType.get<int>(0);
    selectedLogoAnimation = LogoAnimationType.fromIndex(animationIndex);
  }

  void _showLogoAnimationDialog() {
    showDialog(
      context: context,
      builder: (context) => LogoAnimationPreviewDialog(
        initialAnimation: selectedLogoAnimation,
        onConfirm: (LogoAnimationType animationType) {
          setState(() {
            selectedLogoAnimation = animationType;
          });
          ThemeKeys.logoAnimationType.set(animationType.index);
        },
      ),
    );
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
        body: Column(children: [
          const NestedHeader(title: 'Theme'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: AnymeXTabBar(
              selectTabs: const ["Theme", "Wallpaper", "Extras"],
              selectedIndex: _selectedTabIndex,
              onTabSelected: (index) {
                final current = _selectedTabIndex;
                setState(() {
                  _selectedTabIndex = index;
                });
                if (_pageController.hasClients) {
                  if ((index - current).abs() > 1) {
                    final adjacent = index > current ? index - 1 : index + 1;
                    _pageController.jumpToPage(adjacent);
                  }
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: PageView(
                  key: const PageStorageKey('settings_theme_page_view'),
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildThemeTab(),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildWallpaperTab(),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildExtrasTab(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildThemeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        CustomSwitchTile(
          icon: HugeIcons.strokeRoundedColors,
          title: "Custom Theme",
          description: "Choose your favourite color!",
          switchValue: customTheme,
          onChanged: handleCustomThemeSwitch,
        ),
        if (customTheme) ...[
          const SizedBox(height: 20),
          AnymexCard(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymexText(
                  text: "Custom Themes",
                  size: 16,
                  variant: TextVariant.semiBold,
                  color: context.colors.primary,
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(child: _buildColorTemplates())
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        Obx(() {
          return CustomSwitchTile(
            disabled: settings.liquidMode,
            icon: HugeIcons.strokeRoundedFlower,
            title: "Bloom",
            description: "Enables a soft, glowing gradient effect.",
            switchValue: !settings.disableGradient,
            onChanged: (val) => settings.disableGradient = !val,
          );
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
        Obx(() {
          return CustomSwitchTile(
            icon: Icons.texture_rounded,
            title: "Grain Texture Overlay",
            description: "Apply a subtle film grain texture over the interface",
            switchValue: settings.useGrainTexture,
            onChanged: (val) => settings.useGrainTexture = val,
          );
        }),
        Obx(() {
          if (!settings.useGrainTexture) return const SizedBox.shrink();
          final val = settings.grainIntensity;
          int selectedIndex = 0;
          if (val <= 0.04) {
            selectedIndex = 0;
          } else if (val <= 0.10) {
            selectedIndex = 1;
          } else {
            selectedIndex = 2;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Grain Intensity",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                AnymeXTabBar(
                  selectTabs: const ["Low", "Medium", "High"],
                  selectedIndex: selectedIndex,
                  onTabSelected: (index) {
                    if (index == 0) {
                      settings.grainIntensity = 0.03;
                    } else if (index == 1) {
                      settings.grainIntensity = 0.07;
                    } else {
                      settings.grainIntensity = 0.15;
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
        CustomSwitchTile(
          icon: HugeIcons.strokeRoundedMoon,
          title: "Oled Mode",
          description: "Go Super Dark Mode!",
          switchValue: isOled,
          onChanged: handleOledSwitch,
        ),
      ],
    );
  }

  Widget _buildWallpaperTab() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomSwitchTile(
            icon: HugeIcons.strokeRoundedBlur,
            title: "Liquid Mode",
            description: "Make everything glassy & liquidy...",
            switchValue: settings.liquidMode,
            onChanged: (e) {
              settings.disableGradient = false;
              settings.liquidMode = e;
            },
          ),
          if (settings.liquidMode) ...[
            const SizedBox(height: 10),
            CustomTile(
              icon: HugeIcons.strokeRoundedImageAdd01,
              title: "Liquid Background",
              description: "Choose a custom background for liquid mode.",
              onTap: () async {
                await Liquid.pickLiquidBackground(context);
              },
            ),
            const SizedBox(height: 10),
            CustomSwitchTile(
              switchValue: settings.retainOriginalColor,
              icon: HugeIcons.strokeRoundedImageComposition,
              title: "Retain Original Color",
              description: "Enable this if you want to retain the original color of your wallpaper",
              onChanged: (e) => settings.retainOriginalColor = e,
            ),
            const SizedBox(height: 10),
            CustomSwitchTile(
              switchValue: settings.usePosterColor,
              icon: HugeIcons.strokeRoundedImageDownload,
              title: "Use Poster Color",
              description: "Applies anime/manga poster color on details page",
              onChanged: (e) => settings.usePosterColor = e,
            ),
            const SizedBox(height: 10),
            CustomTile(
              icon: HugeIcons.strokeRoundedRefresh,
              title: "Reset to Default Picture",
              postFix: 0.width(),
              description: "Reset to default wallpaper!",
              onTap: () => settings.liquidBackgroundPath = "",
            ),
          ],
        ],
      );
    });
  }

  Widget _buildExtrasTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTile(
          icon: HugeIcons.strokeRoundedPlayCircle,
          title: "Logo Animation",
          description: "Customize your logo animation style",
          onTap: _showLogoAnimationDialog,
        ),
        if (Platform.isAndroid) ...[
          const SizedBox(height: 10),
          Obx(() {
            final label = settings.getPreferredRefreshRateLabel();
            return CustomTile(
              icon: HugeIcons.strokeRoundedRefresh,
              title: "Refresh Rate",
              description: "Current mode: $label",
              onTap: () {
                showRefreshRateDialog(context);
              },
            );
          }),
        ],
      ],
    );
  }

  void showPaletteSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: context.colors.surface,
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
                        color: context.colors.primary,
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
                                context.colors.surfaceContainer,
                          ),
                          child: Text('Cancel',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: context.colors.primary,
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
                                context.colors.primaryFixed,
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

  void showRefreshRateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: context.colors.surface,
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
                  'Select Refresh Rate',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: FutureBuilder<List<DisplayMode>>(
                    future: FlutterDisplayMode.supported,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error loading refresh rates: ${snapshot.error}'),
                        );
                      }

                      final modes = (snapshot.data ?? [])
                          .where((m) =>
                              m != DisplayMode.auto &&
                              m.id != 0 &&
                              m.width != 0 &&
                              m.height != 0)
                          .toList();
                      final List<DisplayMode> options = [
                        DisplayMode.auto,
                        ...modes,
                      ];

                      return Obx(() {
                        final preferredMode = settings.preferredDisplayMode.value;
                        final activeMode = settings.activeDisplayMode.value;

                        return SuperListView.builder(
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final mode = options[index];
                            final isSelected = (preferredMode ?? DisplayMode.auto).id == mode.id &&
                                (preferredMode ?? DisplayMode.auto).width == mode.width &&
                                (preferredMode ?? DisplayMode.auto).height == mode.height &&
                                (preferredMode ?? DisplayMode.auto).refreshRate == mode.refreshRate;
                            final isActive = activeMode != null &&
                                activeMode.id == mode.id &&
                                activeMode.width == mode.width &&
                                activeMode.height == mode.height &&
                                activeMode.refreshRate == mode.refreshRate;

                            final String title;
                            final String subtitle;
                            if (mode == DisplayMode.auto) {
                              title = 'Auto';
                              subtitle = isActive ? 'System Managed [Active]' : 'System Managed';
                            } else {
                              title = '${mode.width}x${mode.height}';
                              subtitle = isActive ? '${mode.refreshRate.toInt()}Hz [Active]' : '${mode.refreshRate.toInt()}Hz';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              child: ListTileWithCheckMark(
                                color: context.colors.primary,
                                active: isSelected,
                                leading: const Icon(Icons.speed_rounded),
                                title: title,
                                subtitle: subtitle,
                                onTap: () async {
                                  await settings.savePreferredDisplayMode(mode);
                                },
                              ),
                            );
                          },
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      backgroundColor: context.colors.primaryFixed,
                    ),
                    child: const Text('Close',
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
              seedColor: context.colors.primary,
              brightness: theme['label'] == "Dark"
                  ? Brightness.dark
                  : Brightness.light);
          final ColorScheme lightScheme = ColorScheme.fromSeed(
              seedColor: context.colors.primary,
              brightness: Brightness.light);
          final ColorScheme darkScheme = ColorScheme.fromSeed(
              seedColor: context.colors.primary,
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
                          ? context.colors.primary
                          : Colors.transparent,
                    ),
                    color:
                        context.colors.surfaceContainerHighest,
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
                                IconlyBold.tickSquare,
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

  void handleCustomColorSelection(Color color) {
    setState(() {
      selectedColorIndex = -1;
    });
    Provider.of<ThemeProvider>(context, listen: false)
        .setCustomSeedColor(-1, customColor: color);
  }

  void _showCustomColorPicker() {
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    String initialHex = ThemeKeys.customHexColor.get<String>("#FFFFFF");
    final controller = TextEditingController(text: initialHex);

    showDialog(
      context: context,
      builder: (context) {
        Color previewColor = Color(int.parse(initialHex.replaceFirst('#', '0xff')));
        HSVColor hsv = HSVColor.fromColor(previewColor);
        double hue = hsv.hue;
        double saturation = hsv.saturation;
        double value = hsv.value;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isValid = true;
            try {
              final hex = controller.text.trim();
              final normalized = hex.startsWith('#') ? hex.replaceFirst('#', '0xff') : '0xff$hex';
              previewColor = Color(int.parse(normalized));
              final newHsv = HSVColor.fromColor(previewColor);
              hue = newHsv.hue;
              saturation = newHsv.saturation;
              value = newHsv.value;
            } catch (_) {
              isValid = false;
            }

            void updateColorFromSliders() {
              previewColor = HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
              final hexStr = '#${previewColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              controller.value = TextEditingValue(
                text: hexStr,
                selection: TextSelection.collapsed(offset: hexStr.length),
              );
              isValid = true;
            }

            return Dialog(
              backgroundColor: context.colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: getResponsiveValue(context, mobileValue: null, desktopValue: 400.0),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Custom Color Picker',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isValid ? previewColor : Colors.grey,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isValid ? previewColor : Colors.grey).withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: !isValid
                            ? const Icon(Icons.error_outline, color: Colors.white, size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Hue',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.red,
                            Colors.yellow,
                            Colors.green,
                            Colors.cyan,
                            Colors.blue,
                            Colors.purple,
                            Colors.red,
                          ],
                        ),
                      ),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          trackHeight: 12,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: hue,
                          min: 0.0,
                          max: 360.0,
                          onChanged: (val) {
                            setDialogState(() {
                              hue = val;
                              updateColorFromSliders();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Saturation',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
                          ],
                        ),
                      ),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          trackHeight: 12,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: saturation,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (val) {
                            setDialogState(() {
                              saturation = val;
                              updateColorFromSliders();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Lightness',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black,
                            HSVColor.fromAHSV(1.0, hue, saturation, 1.0).toColor(),
                          ],
                        ),
                      ),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          trackHeight: 12,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: value,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (val) {
                            setDialogState(() {
                              value = val;
                              updateColorFromSliders();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Hex Color Code',
                        hintText: '#3F51B5 or 3F51B5',
                        errorText: isValid ? null : 'Invalid Hex color code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isValid
                              ? () {
                                  Navigator.of(context).pop();
                                  handleCustomColorSelection(previewColor);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.primary,
                            foregroundColor: context.colors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildColorTemplates() {
    return GridView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: colorMap.length + 1,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: getResponsiveCrossAxisCount(context),
          mainAxisExtent: 150,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10),
      itemBuilder: (context, index) {
        final Color customColor;
        final String label;
        final bool isSelected;
        final ColorScheme colorScheme;

        if (index == 0) {
          final hexStr = ThemeKeys.customHexColor.get<String>("#FFFFFF");
          customColor = Color(int.parse(hexStr.replaceFirst('#', '0xff')));
          label = "Custom";
          isSelected = selectedColorIndex == -1;
          colorScheme = ColorScheme.fromSeed(
              seedColor: customColor, brightness: Theme.of(context).brightness);
        } else {
          final themeIndex = index - 1;
          final theme = colorMap.entries.toList()[themeIndex];
          customColor = theme.value;
          label = theme.key;
          isSelected = selectedColorIndex == themeIndex;
          colorScheme = ColorScheme.fromSeed(
              seedColor: customColor, brightness: Theme.of(context).brightness);
        }

        return GestureDetector(
          onTap: () {
            if (index == 0) {
              if (!isSelected) {
                handleColorSelection(-1);
              }
              _showCustomColorPicker();
            } else {
              handleColorSelection(index - 1);
            }
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
                        ? context.colors.primary
                        : Colors.transparent,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .opaque(Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? 0.3
                                    : 0.4),
                            blurRadius: 20,
                            spreadRadius: 4.0,
                            offset: const Offset(-2.0, 0),
                          ),
                        ]
                      : [],
                  color: context.colors.surfaceContainerHighest,
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
                              color: customColor,
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
                          child: index == 0
                              ? Icon(
                                  Icons.color_lens_outlined,
                                  size: 14,
                                  color: context.colors.onSurface,
                                )
                              : Row(
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
                              IconlyBold.tickSquare,
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
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}
