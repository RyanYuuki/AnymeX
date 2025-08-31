import 'package:anymex/widgets/animation/page_transition.dart';
import 'package:flutter/material.dart';

const Color seedColor = Colors.red;

ThemeData lightMode = ThemeData(
  useMaterial3: true,
  fontFamily: 'Poppins',
  brightness: Brightness.light,
  scaffoldBackgroundColor:
      ColorScheme.fromSeed(brightness: Brightness.light, seedColor: seedColor)
          .surface,
  colorScheme: ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  ),
  // pageTransitionsTheme: PageTransitionsTheme(
  //   builders: {
  //     for (var platform in TargetPlatform.values)
  //       platform: AnymexPageTransition(
  //           backgroundColor: ColorScheme.fromSeed(
  //                   brightness: Brightness.light, seedColor: seedColor)
  //               .surface),
  //   },
  // ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black),
    titleLarge: TextStyle(
        color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
    bodySmall: TextStyle(color: Colors.white, fontSize: 12),
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
  buttonTheme: const ButtonThemeData(
    buttonColor: seedColor,
    textTheme: ButtonTextTheme.primary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: seedColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
    ),
  ),
  iconTheme: const IconThemeData(
    color: Colors.black,
    size: 24,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: seedColor,
    foregroundColor: Colors.white,
  ),
);

ThemeData darkMode = ThemeData(
  useMaterial3: true,
  fontFamily: 'Poppins',
  brightness: Brightness.dark,
  scaffoldBackgroundColor:
      ColorScheme.fromSeed(brightness: Brightness.dark, seedColor: seedColor)
          .surface,
  colorScheme: ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    bodySmall: TextStyle(
        color: Colors.grey, fontSize: 12), // Updated to a lighter color
  ),
  // pageTransitionsTheme: PageTransitionsTheme(
  //   builders: {
  //     for (var platform in TargetPlatform.values)
  //       platform: AnymexPageTransition(
  //           backgroundColor: ColorScheme.fromSeed(
  //                   brightness: Brightness.dark, seedColor: seedColor)
  //               .surface),
  //   },
  // ),
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
  buttonTheme: const ButtonThemeData(
    buttonColor: seedColor,
    textTheme: ButtonTextTheme.primary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: seedColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
    ),
  ),
  iconTheme: const IconThemeData(
    color: Colors.white,
    size: 24,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: seedColor,
    foregroundColor: Colors.white,
  ),
);
