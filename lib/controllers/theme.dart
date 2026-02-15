import 'package:anymex/constants/contants.dart';
import 'package:anymex/constants/themes.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';

class ThemeProvider extends ChangeNotifier {
  bool isLightMode;
  bool isSystemMode;
  bool isOled;
  late ThemeData _lightTheme;
  late ThemeData _darkTheme;
  late String currentThemeMode;
  Color _seedColor;
  late int selectedVariantIndex;

  List<String> availThemeModes = ["default", "material", "custom"];

  ThemeProvider()
      : _seedColor = Colors.indigo,
        isLightMode = ThemeKeys.isLightMode.get<bool>(false),
        isSystemMode = ThemeKeys.isSystemMode.get<bool>(false),
        isOled = ThemeKeys.isOled.get<bool>(false),
        selectedVariantIndex =
            ThemeKeys.selectedVariantIndex.get<int>(4),
        currentThemeMode =
            ThemeKeys.themeMode.get<String>("default") {
    _determineSeedColor();
    _updateTheme();
  }

  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;

  void _determineSeedColor() {
    if (currentThemeMode == "default") {
      _seedColor = Colors.indigo;
    } else if (currentThemeMode == "material") {
      loadDynamicTheme();
    } else {
      int colorIndex = ThemeKeys.customColorIndex.get<int>(0);
      _seedColor = colorList[colorIndex];
    }
  }

  Future<void> loadDynamicTheme() async {
    currentThemeMode = "material";
    ThemeKeys.themeMode.set("material");
    final corePalette = await DynamicColorPlugin.getCorePalette();
    _seedColor = corePalette != null
        ? Color(corePalette.primary.get(40))
        : Colors.indigo;
    _updateTheme();
  }

  void updateSchemeVariant(int index) {
    ThemeKeys.selectedVariantIndex.set(index);
    selectedVariantIndex = index;
    _updateTheme();
  }

  void toggleTheme() {
    isLightMode = !isLightMode;
    isSystemMode = false;
    ThemeKeys.isSystemMode.set(isSystemMode);
    ThemeKeys.isLightMode.set(isLightMode);
    _updateTheme();
  }

  void setSystemMode() {
    isSystemMode = true;
    ThemeKeys.isSystemMode.set(isSystemMode);
    notifyListeners();
  }

  void setLightMode() {
    isLightMode = true;
    ThemeKeys.isLightMode.set(true);
    _updateTheme();
  }

  void setDarkMode() {
    isLightMode = false;
    isSystemMode = false;
    ThemeKeys.isSystemMode.set(isSystemMode);
    ThemeKeys.isLightMode.set(false);
    _updateTheme();
  }

  void setDefaultTheme() {
    currentThemeMode = "default";
    ThemeKeys.themeMode.set("default");
    _seedColor = Colors.indigo;
    _updateTheme();
  }

  void setCustomSeedColor(int index) {
    currentThemeMode = "custom";
    ThemeKeys.themeMode.set("custom");
    ThemeKeys.customColorIndex.set(index);
    _seedColor = colorList[index];
    _updateTheme();
  }

  void toggleOled(bool value) {
    isOled = value;
    ThemeKeys.isOled.set(value);
    _updateTheme();
  }

  void syncStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        statusBarBrightness: isLightMode ? Brightness.dark : Brightness.light,
        statusBarIconBrightness:
            isLightMode ? Brightness.dark : Brightness.light));
  }

  void clearCache() {
    ThemeKeys.isLightMode.delete();
    ThemeKeys.isSystemMode.delete();
    ThemeKeys.isOled.delete();
    ThemeKeys.selectedVariantIndex.delete();
    ThemeKeys.themeMode.delete();
    ThemeKeys.customColorIndex.delete();
    isLightMode = false;
    isSystemMode = false;
    ThemeKeys.isSystemMode.set(isSystemMode);
    isOled = false;
    selectedVariantIndex = 0;
    currentThemeMode = "default";
    _seedColor = Colors.indigo;

    _updateTheme();
    notifyListeners();
  }

  void _updateTheme() {
    _lightTheme = lightMode.copyWith(
      scaffoldBackgroundColor: isOled ? Colors.white : Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
          dynamicSchemeVariant: dynamicSchemeVariantList[selectedVariantIndex]),
    );
    _darkTheme = darkMode.copyWith(
      scaffoldBackgroundColor: isOled ? Colors.black : Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
          dynamicSchemeVariant: dynamicSchemeVariantList[selectedVariantIndex]),
    );
    syncStatusBar();
    notifyListeners();
  }
}
