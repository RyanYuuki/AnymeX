import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme.dart';

class ThemeProvider extends ChangeNotifier {
  late bool isLightMode;
  late ThemeData _selectedTheme;
  Color? _seedColor;
  late bool isOled;
  ThemeProvider() {
    var box = Hive.box('login-data');
    isLightMode = box.get('Theme', defaultValue: 'dark') == 'light';
    _selectedTheme = isLightMode ? lightMode : darkMode;
    isOled = box.get('isOled', defaultValue: false);
    if (box.get('PaletteMode', defaultValue: 'Material') == 'Material') {
      loadDynamicTheme();
    } else if (box.get('PaletteMode', defaultValue: 'Material') == 'Banner') {
      adaptBannerColor(Colors.indigo);
    } else {
      int colorValue = box.get('SeedColor', defaultValue: Colors.indigo.value);
      MaterialColor newSeedColor =
          MaterialColor(colorValue, getMaterialColorSwatch(colorValue));
      changeSeedColor(newSeedColor);
    }
  }

  void updateStatusBarColor() {
    SystemChrome.setSystemUIOverlayStyle(
      isLightMode
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent),
    );
  }

  ThemeData get selectedTheme => _selectedTheme;

  Future<void> loadDynamicTheme() async {
    var box = Hive.box('login-data');
    final corePalette = await DynamicColorPlugin.getCorePalette();
    if (corePalette != null) {
      _seedColor = Color(corePalette.primary.get(40));
      updateTheme();
    } else {
      _seedColor = Colors.indigo;
      _selectedTheme = isLightMode ? lightMode : darkMode;
    }
    box.put('PaletteMode', 'Material');
    notifyListeners();
  }

  void updateTheme() {
    var box = Hive.box('login-data');
    String dynamicSchemeKey = box.get('DynamicPalette', defaultValue: 'tonal');
    DynamicSchemeVariant schemeVariant = getSchemeVariant(dynamicSchemeKey);

    _selectedTheme = isLightMode
        ? lightMode.copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _seedColor!,
              brightness: Brightness.light,
              dynamicSchemeVariant: schemeVariant,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey.shade300,
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIconColor: Colors.grey.shade700,
              suffixIconColor: Colors.grey.shade700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          )
        : darkMode.copyWith(
            colorScheme: ColorScheme.fromSeed(
              surface: isOled
                  ? Colors.black
                  : ColorScheme.fromSeed(
                          dynamicSchemeVariant: schemeVariant,
                          brightness: Brightness.dark,
                          seedColor: _seedColor!)
                      .surface,
              seedColor: _seedColor!,
              brightness: Brightness.dark,
              dynamicSchemeVariant: schemeVariant,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey.shade900,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIconColor: Colors.grey.shade500,
              suffixIconColor: Colors.grey.shade500,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          );
    updateStatusBarColor();
  }

  void setOledTheme(bool mode) {
    isOled = mode;
    updateTheme();
    notifyListeners();
  }

  DynamicSchemeVariant getSchemeVariant(String key) {
    switch (key) {
      case 'monochrome':
        return DynamicSchemeVariant.monochrome;
      case 'neutral':
        return DynamicSchemeVariant.neutral;
      case 'vibrant':
        return DynamicSchemeVariant.vibrant;
      case 'tonalspot':
        return DynamicSchemeVariant.tonalSpot;
      case 'content':
        return DynamicSchemeVariant.content;
      case 'expressive':
        return DynamicSchemeVariant.expressive;
      case 'fidelity':
        return DynamicSchemeVariant.fidelity;
      case 'fruitsalad':
        return DynamicSchemeVariant.fruitSalad;
      case 'rainbow':
        return DynamicSchemeVariant.rainbow;
      default:
        return DynamicSchemeVariant.tonalSpot;
    }
  }

  void changeSeedColor(MaterialColor newColor) {
    _seedColor = newColor;
    updateTheme();
    Hive.box('login-data').put('SeedColor', newColor.value);
    Hive.box('login-data').put('PaletteMode', 'Custom');
    notifyListeners();
  }

  void adaptBannerColor(Color newColor) {
    _seedColor = newColor;
    updateTheme();
    Hive.box('login-data').put('PaletteMode', 'Banner');
    notifyListeners();
  }

  void toggleTheme() {
    if (isLightMode) {
      setDarkMode();
    } else {
      setLightMode();
    }
  }

  void setLightMode() {
    isLightMode = true;
    updateTheme();
    Hive.box('login-data').put('Theme', 'light');
    notifyListeners();
  }

  void setDarkMode() {
    isLightMode = false;
    updateTheme();
    Hive.box('login-data').put('Theme', 'dark');
    notifyListeners();
  }

  void setLightModeWithoutDB() {
    isLightMode = true;
    updateTheme();
    notifyListeners();
  }

  void setDarkModeWithoutDB() {
    isLightMode = false;
    updateTheme();
    notifyListeners();
  }

  Map<int, Color> getMaterialColorSwatch(int colorValue) {
    Color color = Color(colorValue);
    return {
      50: color.withOpacity(.1),
      100: color.withOpacity(.2),
      200: color.withOpacity(.3),
      300: color.withOpacity(.4),
      400: color.withOpacity(.5),
      500: color.withOpacity(.6),
      600: color.withOpacity(.7),
      700: color.withOpacity(.8),
      800: color.withOpacity(.9),
      900: color.withOpacity(1),
    };
  }

  void checkAndApplyPaletteMode() {
    var box = Hive.box('login-data');
    String paletteMode = box.get('PaletteMode', defaultValue: 'Material');

    if (paletteMode == 'Material') {
      loadDynamicTheme();
    } else {
      int colorValue = box.get('SeedColor', defaultValue: Colors.indigo.value);
      MaterialColor newSeedColor =
          MaterialColor(colorValue, getMaterialColorSwatch(colorValue));
      changeSeedColor(newSeedColor);
    }
    updateTheme();
  }
}
