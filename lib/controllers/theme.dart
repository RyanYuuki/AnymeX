import 'package:anymex/constants/contants.dart';
import 'package:anymex/constants/themes.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

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
        isLightMode =
            Hive.box("themeData").get("isLightMode", defaultValue: false),
        isSystemMode =
            Hive.box("themeData").get("isSystemMode", defaultValue: false),
        isOled = Hive.box("themeData").get("isOled", defaultValue: false),
        selectedVariantIndex =
            Hive.box("themeData").get("selectedVariantIndex", defaultValue: 4),
        currentThemeMode =
            Hive.box("themeData").get("themeMode", defaultValue: "default") {
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
      final box = Hive.box("themeData");
      int colorIndex = box.get("customColorIndex", defaultValue: 0);
      _seedColor = colorList[colorIndex];
    }
  }

  Future<void> loadDynamicTheme() async {
    currentThemeMode = "material";
    Hive.box("themeData").put("themeMode", "material");
    final corePalette = await DynamicColorPlugin.getCorePalette();
    _seedColor = corePalette != null
        ? Color(corePalette.primary.get(40))
        : Colors.indigo;
    _updateTheme();
  }

  void updateSchemeVariant(int index) {
    Hive.box("themeData").put("selectedVariantIndex", index);
    selectedVariantIndex = index;
    _updateTheme();
  }

  void toggleTheme() {
    isLightMode = !isLightMode;
    isSystemMode = false;
    Hive.box("themeData").put("isSystemMode", isSystemMode);
    Hive.box("themeData").put("isLightMode", isLightMode);
    _updateTheme();
  }

  void setSystemMode() {
    isSystemMode = true;
    Hive.box("themeData").put("isSystemMode", isSystemMode);
    notifyListeners();
  }

  void setLightMode() {
    isLightMode = true;
    Hive.box("themeData").put("isLightMode", true);
    _updateTheme();
  }

  void setDarkMode() {
    isLightMode = false;
    isSystemMode = false;
    Hive.box("themeData").put("isSystemMode", isSystemMode);
    Hive.box("themeData").put("isLightMode", false);
    _updateTheme();
  }

  void setDefaultTheme() {
    currentThemeMode = "default";
    Hive.box("themeData").put("themeMode", "default");
    _seedColor = Colors.indigo;
    _updateTheme();
  }

  void setCustomSeedColor(int index) {
    currentThemeMode = "custom";
    Hive.box("themeData")
      ..put("themeMode", "custom")
      ..put("customColorIndex", index);
    _seedColor = colorList[index];
    _updateTheme();
  }

  void toggleOled(bool value) {
    isOled = value;
    Hive.box("themeData").put("isOled", value);
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
    final box = Hive.box("themeData");
    box.clear();
    isLightMode = false;
    isSystemMode = false;
    Hive.box("themeData").put("isSystemMode", isSystemMode);
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
