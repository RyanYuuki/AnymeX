import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme.dart';

class ThemeProvider extends ChangeNotifier {
  late bool isLightMode;
  late ThemeData _selectedTheme;
  Color? _seedColor;

  ThemeProvider() {
    var box = Hive.box('login-data');
    isLightMode = box.get('Theme', defaultValue: 'dark') == 'light';
    _selectedTheme = isLightMode ? lightMode : darkMode;
    loadDynamicTheme();
  }

  ThemeData get selectedTheme => _selectedTheme;

  Future<void> loadDynamicTheme() async {
    final corePalette = await DynamicColorPlugin.getCorePalette();

    if (corePalette != null) {
      _seedColor = Color(corePalette.primary.get(40));
      _selectedTheme = isLightMode
          ? lightMode.copyWith(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: _seedColor!,
                brightness: Brightness.light,
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
              buttonTheme: ButtonThemeData(
                buttonColor: _seedColor,
                textTheme: ButtonTextTheme.primary,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _seedColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              iconTheme: const IconThemeData(
                color: Colors.black,
                size: 24,
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: _seedColor,
                foregroundColor: Colors.white,
              ),
            )
          : darkMode.copyWith(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: _seedColor!,
                brightness: Brightness.dark,
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
              buttonTheme: ButtonThemeData(
                buttonColor: _seedColor,
                textTheme: ButtonTextTheme.primary,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _seedColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              iconTheme: const IconThemeData(
                color: Colors.white,
                size: 24,
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: _seedColor,
                foregroundColor: Colors.white,
              ),
            );
    } else {
      _selectedTheme = isLightMode ? lightMode : darkMode;
    }

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
    _selectedTheme = _seedColor != null
        ? lightMode.copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _seedColor!,
              brightness: Brightness.light,
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
        : lightMode;
    Hive.box('login-data').put('Theme', 'light');
    notifyListeners();
  }

  void setDarkMode() {
    isLightMode = false;
    _selectedTheme = _seedColor != null
        ? darkMode.copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _seedColor!,
              brightness: Brightness.dark,
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
          )
        : darkMode;
    Hive.box('login-data').put('Theme', 'dark');
    notifyListeners();
  }
}
