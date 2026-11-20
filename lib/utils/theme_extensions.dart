import 'package:flutter/material.dart';
import 'package:get/get.dart';

extension ThemeModeExts on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
}

extension ThemeExtensions on Color {
  Color opaque(double val, {bool iReallyMeanIt = false}) => withValues(alpha: iReallyMeanIt ? val : Get.isDarkMode ? val : 1);
}