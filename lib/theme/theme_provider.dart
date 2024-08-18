import 'package:flutter/material.dart';
import 'theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _selectedTheme = darkMode;
  ThemeData get selectedTheme => _selectedTheme;

  void toggleTheme() {
    if (_selectedTheme == lightMode) {
      _selectedTheme = darkMode;
    } else {
      _selectedTheme = lightMode;
    }
    notifyListeners();
  }

  void setLightMode() {
    _selectedTheme = lightMode;
    notifyListeners();
  }

  void setDarkMode() {
    _selectedTheme = darkMode;
    notifyListeners();
  }
}