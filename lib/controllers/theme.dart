import 'dart:async';
import 'package:anymex/constants/contants.dart';
import 'package:anymex/constants/themes.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  bool isLightMode;
  bool isSystemMode;
  bool isOled;
  late ThemeData _lightTheme;
  late ThemeData _darkTheme;
  late String currentThemeMode;
  Color _seedColor;
  late int selectedVariantIndex;
  String appFontFamily;
  double fontScale;

  Timer? _debounce;

  List<String> availThemeModes = ["default", "material", "custom"];

  ThemeController()
      : _seedColor = Colors.deepPurple,
        isLightMode = ThemeKeys.isLightMode.get<bool>(false),
        isSystemMode = ThemeKeys.isSystemMode.get<bool>(false),
        isOled = ThemeKeys.isOled.get<bool>(false),
        selectedVariantIndex = ThemeKeys.selectedVariantIndex.get<int>(0),
        currentThemeMode = ThemeKeys.themeMode.get<String>("default"),
        appFontFamily = UISettingsKeys.appFontFamily.get<String>(''),
        fontScale = UISettingsKeys.appFontScale.get<double>(1.0) {
    _determineSeedColor();
    _applyTheme();
  }

  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;

  ThemeMode get themeMode => isSystemMode
      ? ThemeMode.system
      : isLightMode
          ? ThemeMode.light
          : ThemeMode.dark;

  void _determineSeedColor() {
    if (currentThemeMode == "default") {
      _seedColor = Colors.deepPurple;
    } else if (currentThemeMode == "material") {
    } else {
      int colorIndex =
          ThemeKeys.customColorIndex.get<int>(colorKeys.indexOf("DeepPurple"));
      if (colorIndex == -1) {
        final hexStr = ThemeKeys.customHexColor.get<String>("#FFFFFF");
        _seedColor = Color(int.parse(hexStr.replaceFirst('#', '0xff')));
      } else {
        _seedColor = colorList[colorIndex];
      }
    }
  }

  void _applyTheme() {
    final lightSeed = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      dynamicSchemeVariant: dynamicSchemeVariantList[selectedVariantIndex],
    );
    final darkSeed = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      dynamicSchemeVariant: dynamicSchemeVariantList[selectedVariantIndex],
    );

    final hasCustomFont = appFontFamily.isNotEmpty;
    final customFontFamily = appFontFamily == 'System' ? null : appFontFamily;

    _lightTheme = lightMode.copyWith(
      scaffoldBackgroundColor: isOled ? Colors.white : Colors.transparent,
      canvasColor: isOled ? Colors.white : lightSeed.surface,
      colorScheme: lightSeed,
      textTheme: hasCustomFont
          ? (customFontFamily != null
              ? lightMode.textTheme.apply(fontFamily: customFontFamily)
              : lightMode.textTheme)
          : null,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: lightSeed.primary,
        selectionColor: lightSeed.primary.withValues(alpha: 0.35),
        selectionHandleColor: lightSeed.primary,
      ),
    );

    _darkTheme = darkMode.copyWith(
      scaffoldBackgroundColor: isOled ? Colors.black : Colors.transparent,
      canvasColor: isOled ? Colors.black : darkSeed.surface,
      colorScheme: darkSeed,
      textTheme: hasCustomFont
          ? (customFontFamily != null
              ? darkMode.textTheme.apply(fontFamily: customFontFamily)
              : darkMode.textTheme)
          : null,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: darkSeed.primary,
        selectionColor: darkSeed.primary.withValues(alpha: 0.35),
        selectionHandleColor: darkSeed.primary,
      ),
    );

    _syncStatusBar();
  }

  void _updateThemeImmediately() {
    _debounce?.cancel();
    _applyTheme();
    update();
  }

  Future<void> loadDynamicTheme() async {
    currentThemeMode = "material";
    ThemeKeys.themeMode.set("material");
    final corePalette = await DynamicColorPlugin.getCorePalette();
    _seedColor = corePalette != null
        ? Color(corePalette.primary.get(40))
        : Colors.deepPurple;
    _updateThemeImmediately();
  }

  void updateSchemeVariant(int index) {
    ThemeKeys.selectedVariantIndex.set(index);
    selectedVariantIndex = index;
    _updateThemeImmediately();
  }

  void toggleTheme() {
    isLightMode = !isLightMode;
    isSystemMode = false;
    ThemeKeys.isSystemMode.set(isSystemMode);
    ThemeKeys.isLightMode.set(isLightMode);
    _updateThemeImmediately();
  }

  void setSystemMode() {
    isSystemMode = true;
    ThemeKeys.isSystemMode.set(isSystemMode);
    update();
  }

  void setLightMode() {
    isLightMode = true;
    ThemeKeys.isLightMode.set(true);
    _updateThemeImmediately();
  }

  void setDarkMode() {
    isLightMode = false;
    isSystemMode = false;
    ThemeKeys.isSystemMode.set(isSystemMode);
    ThemeKeys.isLightMode.set(false);
    _updateThemeImmediately();
  }

  void setDefaultTheme() {
    currentThemeMode = "default";
    ThemeKeys.themeMode.set("default");
    _seedColor = Colors.deepPurple;
    _updateThemeImmediately();
  }

  void setCustomSeedColor(int index, {Color? customColor}) {
    currentThemeMode = "custom";
    ThemeKeys.themeMode.set("custom");
    ThemeKeys.customColorIndex.set(index);
    if (index == -1) {
      if (customColor != null) {
        final hexStr =
            '#${customColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
        ThemeKeys.customHexColor.set(hexStr);
        _seedColor = customColor;
      } else {
        final hexStr = ThemeKeys.customHexColor.get<String>("#FFFFFF");
        _seedColor = Color(int.parse(hexStr.replaceFirst('#', '0xff')));
      }
    } else {
      _seedColor = colorList[index];
    }
    _updateThemeImmediately();
  }

  void toggleOled(bool value) {
    isOled = value;
    ThemeKeys.isOled.set(value);
    _updateThemeImmediately();
  }

  void _syncStatusBar() {
    final enableImmersive = UISettingsKeys.enableImmersiveMode.get<bool>(false);
    SystemChrome.setEnabledSystemUIMode(
        enableImmersive ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isLightMode ? Brightness.dark : Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarBrightness: isLightMode ? Brightness.dark : Brightness.light,
        statusBarIconBrightness:
            isLightMode ? Brightness.dark : Brightness.light));
  }

  void setFontFamily(String family) {
    appFontFamily = family;
    UISettingsKeys.appFontFamily.set(family);
    _updateThemeImmediately();
  }

  void setFontScale(double scale) {
    fontScale = scale;
    UISettingsKeys.appFontScale.set(scale);
    update();
  }

  void clearCache() {
    ThemeKeys.isLightMode.delete();
    ThemeKeys.isSystemMode.delete();
    ThemeKeys.isOled.delete();
    ThemeKeys.selectedVariantIndex.delete();
    ThemeKeys.themeMode.delete();
    ThemeKeys.customColorIndex.delete();
    UISettingsKeys.appFontFamily.delete();
    UISettingsKeys.appFontScale.delete();
    appFontFamily = '';
    fontScale = 1.0;
    isLightMode = false;
    isSystemMode = false;
    ThemeKeys.isSystemMode.set(isSystemMode);
    isOled = false;
    selectedVariantIndex = 0;
    currentThemeMode = "default";
    _seedColor = Colors.deepPurple;
    _updateThemeImmediately();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
