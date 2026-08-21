import 'dart:io';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:anymex/constants/contants.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/logo_animation_type.dart';
import 'package:anymex/utils/liquid.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/dialogs/logo_animation_preview_dialog.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

import 'package:provider/provider.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

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
    _initializeLogoAnimation();
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
    AnymeXDialog(
      title: 'Logo Animation',
      showCancelButton: false,
      confirmText: 'Close',
      onConfirm: () {},
      contentWidget: LogoAnimationPreviewDialog(
        initialAnimation: selectedLogoAnimation,
        onConfirm: (LogoAnimationType animationType) {
          setState(() {
            selectedLogoAnimation = animationType;
          });
          ThemeKeys.logoAnimationType.set(animationType.index);
        },
      ),
    ).show(context);
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
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Theme',
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding:
              EdgeInsets.fromLTRB(16.0, AnymeXHeaderScope.of(ctx), 16.0, 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThemeTab(),
              const SizedBox(height: 20),
              _buildWallpaperTab(),
              const SizedBox(height: 20),
              _buildExtrasTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModeTemplates(),
        const SizedBox(height: 20),
        AnymeXSectionBuilder(
          title: 'Themes',
          children: [
            AnymeXTile.toggle(
              icon: HugeIcons.strokeRoundedPaintBrush01,
              title: "Default Theme",
              subtitle: "Play around with App theme",
              value: defaultTheme,
              onChanged: handleDefaultSwitch,
            ),
            AnymeXTile.toggle(
              icon: HugeIcons.strokeRoundedImage01,
              title: "Material You",
              subtitle: "Take color from your wallpaper (A12+)",
              value: materialTheme,
              onChanged: handleMaterialSwitch,
            ),
            AnymeXTile.expandableToggle(
              icon: HugeIcons.strokeRoundedColors,
              title: "Custom Theme",
              subtitle: "Choose your favourite color!",
              value: customTheme,
              onChanged: handleCustomThemeSwitch,
              child: _buildColorTemplates(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AnymeXSectionBuilder(
          title: 'Appearance',
          children: [
            Obx(() {
              return AnymeXTile.toggle(
                enabled: !settings.liquidMode,
                icon: HugeIcons.strokeRoundedFlower,
                title: "Bloom",
                subtitle: "Enables a soft, glowing gradient effect.",
                value: !settings.disableGradient,
                onChanged: (val) => settings.disableGradient = !val,
              );
            }),
            AnymeXTile(
              icon: HugeIcons.strokeRoundedPaintBoard,
              title: "Palette",
              subtitle: "Choose your favourite palette!",
              onTap: () {
                showPaletteSelectionDialog(context);
              },
            ),
            Obx(() {
              return AnymeXTile.toggle(
                icon: Icons.texture_rounded,
                title: "Grain Texture Overlay",
                subtitle:
                    "Apply a subtle film grain texture over the interface",
                value: settings.useGrainTexture,
                onChanged: (val) => settings.useGrainTexture = val,
              );
            }),
            Obx(() {
              if (!settings.useGrainTexture) return const SizedBox.shrink();
              final val = settings.grainIntensity;
              final intensities = [0.03, 0.07, 0.15];
              final labels = ['Low', 'Medium', 'High'];
              final current = val <= 0.04
                  ? 0.03
                  : val <= 0.10
                      ? 0.07
                      : 0.15;
              return AnymeXTile.segmented<double>(
                icon: Icons.grain_rounded,
                title: 'Grain Intensity',
                subtitle: 'Amount of film grain applied',
                value: current,
                options: intensities,
                optionLabelTransformer: (v) => labels[intensities.indexOf(v)],
                onChanged: (v) => settings.grainIntensity = v,
              );
            }),
            AnymeXTile.toggle(
              icon: HugeIcons.strokeRoundedMoon,
              title: "Oled Mode",
              subtitle: "Go Super Dark Mode!",
              value: isOled,
              onChanged: handleOledSwitch,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWallpaperTab() {
    return Obx(() {
      return AnymeXSectionBuilder(
        title: 'Wallpaper',
        children: [
          AnymeXTile.toggle(
            icon: HugeIcons.strokeRoundedBlur,
            title: "Liquid Mode",
            subtitle: "Make everything glassy & liquidy...",
            value: settings.liquidMode,
            onChanged: (e) {
              settings.disableGradient = false;
              settings.liquidMode = e;
            },
          ),
          if (settings.liquidMode) ...[
            AnymeXTile(
              icon: HugeIcons.strokeRoundedImageAdd01,
              title: "Liquid Background",
              subtitle: "Choose a custom background for liquid mode.",
              onTap: () async {
                await Liquid.pickLiquidBackground(context);
              },
            ),
            AnymeXTile.toggle(
              value: settings.retainOriginalColor,
              icon: HugeIcons.strokeRoundedImageComposition,
              title: "Retain Original Color",
              subtitle:
                  "Enable this if you want to retain the original color of your wallpaper",
              onChanged: (e) => settings.retainOriginalColor = e,
            ),
            AnymeXTile.toggle(
              value: settings.usePosterColor,
              icon: HugeIcons.strokeRoundedImageDownload,
              title: "Use Poster Color",
              subtitle: "Applies anime/manga poster color on details page",
              onChanged: (e) => settings.usePosterColor = e,
            ),
            AnymeXTile(
              icon: HugeIcons.strokeRoundedRefresh,
              title: "Reset to Default Picture",
              showChevron: false,
              subtitle: "Reset to default wallpaper!",
              onTap: () => settings.liquidBackgroundPath = "",
            ),
          ],
        ],
      );
    });
  }

  Widget _buildExtrasTab() {
    return AnymeXSectionBuilder(
      title: 'Miscellaneous',
      children: [
        AnymeXTile(
          icon: HugeIcons.strokeRoundedPlayCircle,
          title: "Logo Animation",
          subtitle: "Customize your logo animation style",
          onTap: _showLogoAnimationDialog,
        ),
        if (Platform.isAndroid) ...[
          Obx(() {
            final label = settings.getPreferredRefreshRateLabel();
            return AnymeXTile(
              icon: HugeIcons.strokeRoundedRefresh,
              title: "Refresh Rate",
              subtitle: "Current mode: $label",
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
    AnymeXDialog(
      title: 'Palettes',
      showCancelButton: false,
      confirmText: 'Close',
      onConfirm: () {},
      contentWidget: AnymeXTileBuilder<String>(
        items: dynamicSchemeVariantKeys,
        selectedItem: dynamicSchemeVariantKeys[selectedVariantIndex],
        getTitle: (label) => label,
        onItemPressed: (label) {
          final index = dynamicSchemeVariantKeys.indexOf(label);
          setState(() {
            selectedVariantIndex = index;
          });
          handlePaletteChange(index);
        },
      ),
    ).show(context);
  }

  void showRefreshRateDialog(BuildContext context) {
    AnymeXDialog(
      title: 'Select Refresh Rate',
      showCancelButton: false,
      confirmText: 'Close',
      onConfirm: () {},
      contentWidget: FutureBuilder<List<DisplayMode>>(
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
              child: AnymeXText('Error loading refresh rates: ${snapshot.error}'),
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
            final preferredMode =
                settings.preferredDisplayMode.value ?? DisplayMode.auto;
            final activeMode = settings.activeDisplayMode.value;

            final matchedSelected = options.firstWhere(
              (m) =>
                  m.id == preferredMode.id &&
                  m.width == preferredMode.width &&
                  m.height == preferredMode.height &&
                  m.refreshRate == preferredMode.refreshRate,
              orElse: () => DisplayMode.auto,
            );

            return AnymeXTileBuilder<DisplayMode>(
              items: options,
              selectedItem: matchedSelected,
              getTitle: (mode) {
                if (mode == DisplayMode.auto) return 'Auto';
                return '${mode.width}x${mode.height}';
              },
              getSubtitle: (mode) {
                final isActive = activeMode != null &&
                    activeMode.id == mode.id &&
                    activeMode.width == mode.width &&
                    activeMode.height == mode.height &&
                    activeMode.refreshRate == mode.refreshRate;
                if (mode == DisplayMode.auto) {
                  return isActive
                      ? 'System Managed [Active]'
                      : 'System Managed';
                }
                return isActive
                    ? '${mode.refreshRate.toInt()}Hz [Active]'
                    : '${mode.refreshRate.toInt()}Hz';
              },
              onItemPressed: (mode) async {
                await settings.savePreferredDisplayMode(mode);
              },
            );
          });
        },
      ),
    ).show(context);
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
              seedColor: context.colors.primary, brightness: Brightness.light);
          final ColorScheme darkScheme = ColorScheme.fromSeed(
              seedColor: context.colors.primary, brightness: Brightness.dark);
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
                      mobileSize: MediaQuery.sizeOf(context).width / 2,
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
                AnymeXText(
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
    String initialHex = ThemeKeys.customHexColor.get<String>("#FFFFFF");
    final controller = TextEditingController(text: initialHex);

    showDialog(
      context: context,
      builder: (context) {
        Color previewColor =
            Color(int.parse(initialHex.replaceFirst('#', '0xff')));
        HSVColor hsv = HSVColor.fromColor(previewColor);
        double hue = hsv.hue;
        double saturation = hsv.saturation;
        double value = hsv.value;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isValid = true;
            try {
              final hex = controller.text.trim();
              final normalized = hex.startsWith('#')
                  ? hex.replaceFirst('#', '0xff')
                  : '0xff$hex';
              previewColor = Color(int.parse(normalized));
              final newHsv = HSVColor.fromColor(previewColor);
              hue = newHsv.hue;
              saturation = newHsv.saturation;
              value = newHsv.value;
            } catch (_) {
              isValid = false;
            }

            void updateColorFromSliders() {
              previewColor =
                  HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
              final hexStr =
                  '#${previewColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              controller.value = TextEditingValue(
                text: hexStr,
                selection: TextSelection.collapsed(offset: hexStr.length),
              );
              isValid = true;
            }

            return AnymeXDialog(
              title: 'Custom Color Picker',
              confirmText: 'Confirm',
              onConfirm: () {
                if (isValid) {
                  handleCustomColorSelection(previewColor);
                }
              },
              contentWidget: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isValid ? previewColor : Colors.grey,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isValid ? previewColor : Colors.grey)
                                .withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: !isValid
                          ? const Icon(Icons.error_outline,
                              color: Colors.white, size: 30)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const AnymeXText(
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
                  const AnymeXText(
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
                  const AnymeXText(
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
                          HSVColor.fromAHSV(1.0, hue, saturation, 1.0)
                              .toColor(),
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildColorTemplates() {
    final colors = context.colors;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: List.generate(colorMap.length + 1, (index) {
          final Color seedColor;
          final String label;
          final bool isSelected;
          final ColorScheme colorScheme;

          if (index == 0) {
            final hexStr = ThemeKeys.customHexColor.get<String>("#FFFFFF");
            seedColor = Color(int.parse(hexStr.replaceFirst('#', '0xff')));
            label = "Custom";
            isSelected = selectedColorIndex == -1;
            colorScheme = ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Theme.of(context).brightness,
            );
          } else {
            final entry = colorMap.entries.toList()[index - 1];
            seedColor = entry.value;
            label = entry.key;
            isSelected = selectedColorIndex == index - 1;
            colorScheme = ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Theme.of(context).brightness,
            );
          }

          return GestureDetector(
            onTap: () {
              if (index == 0) {
                if (!isSelected) handleColorSelection(-1);
                _showCustomColorPicker();
              } else {
                handleColorSelection(index - 1);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              width: 76,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary.opaque(0.12, iReallyMeanIt: true)
                    : colors.surfaceContainerHighest
                        .opaque(0.3, iReallyMeanIt: true),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  width: isSelected ? 2 : 1,
                  color: isSelected
                      ? colors.primary
                      : colors.onSurface.opaque(0.08, iReallyMeanIt: true),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index == 0)
                    _buildCustomColorSwatch(colorScheme, seedColor, isSelected)
                  else
                    _buildColorSwatch(colorScheme, isSelected),
                  const SizedBox(height: 8),
                  AnymeXText(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? colors.primary
                          : colors.onSurface.opaque(0.7, iReallyMeanIt: true),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildColorSwatch(ColorScheme cs, bool isSelected) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            child: isSelected
                ? Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: cs.onPrimary,
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: cs.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomColorSwatch(
      ColorScheme cs, Color seedColor, bool isSelected) {
    final isDarkSeed =
        ThemeData.estimateBrightnessForColor(seedColor) == Brightness.dark;

    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: SweepGradient(
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
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: seedColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected ? Icons.check_rounded : Icons.colorize_rounded,
                  size: 14,
                  color: isDarkSeed ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
