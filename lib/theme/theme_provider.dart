import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme.dart';

class ThemeProvider extends ChangeNotifier {
  late bool isLightMode;
  late ThemeData _selectedTheme;

  ThemeProvider() {
    var box = Hive.box('login-data');
    isLightMode = box.get('Theme', defaultValue: 'light') == 'light';
    _selectedTheme = isLightMode ? lightMode : darkMode;
  }

  ThemeData get selectedTheme => _selectedTheme;

  void toggleTheme() {
    if (_selectedTheme == lightMode) {
      setDarkMode();
    } else {
      setLightMode();
    }
  }

  void setLightMode() {
    _selectedTheme = lightMode;
    isLightMode = true;
    Hive.box('login-data').put('Theme', 'light');
    notifyListeners();
  }

  void setDarkMode() {
    _selectedTheme = darkMode;
    isLightMode = false;
    Hive.box('login-data').put('Theme', 'dark');
    notifyListeners();
  }
}
