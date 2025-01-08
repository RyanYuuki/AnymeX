import 'package:flutter/material.dart';

Map<String, Color> colorMap = {
  "Green": Colors.green,
  "Red": Colors.red,
  "Pink": Colors.pink,
  "Purple": Colors.purple,
  "DeepPurple": Colors.deepPurple,
  "Indigo": Colors.indigo,
  "Blue": Colors.blue,
  "LightBlue": Colors.lightBlue,
  "Cyan": Colors.cyan,
  "Teal": Colors.teal,
  "LightGreen": Colors.lightGreen,
  "Lime": Colors.lime,
  "Yellow": Colors.yellow,
  "Amber": Colors.amber,
  "Orange": Colors.orange,
  "DeepOrange": Colors.deepOrange,
  "Brown": Colors.brown,
};
List<Color> colorList = colorMap.values.toList();
List<String> colorKeys = colorMap.keys.toList();

Map<String, BoxFit> resizeModes = {
  "Cover": BoxFit.cover,
  "Contain": BoxFit.contain,
  "Fill": BoxFit.fill,
};
List<String> resizeModeList = resizeModes.keys.toList();

Map<String, DynamicSchemeVariant> dynamicSchemeVariantMap = {
  for (var variant in DynamicSchemeVariant.values)
    capitalize(variant.name): variant,
};

List<DynamicSchemeVariant> dynamicSchemeVariantList =
    dynamicSchemeVariantMap.values.toList();
List<String> dynamicSchemeVariantKeys = dynamicSchemeVariantMap.keys.toList();

String capitalize(String word) {
  String firstLetter = (word[0]).toUpperCase();
  String truncatedWord = firstLetter + word.substring(1, word.length);
  return truncatedWord;
}

const maxMobileWidth = 600;

final Map<String, Color> colorOptions = {
  'Default': Colors.transparent,
  'White': Colors.white,
  'Black': Colors.black,
  'Red': Colors.red,
  'Green': Colors.green,
  'Blue': Colors.blue,
  'Yellow': Colors.yellow,
  'Cyan': Colors.cyan,
};

final Map<String, Color> fontColorOptions = {
  'Default': Colors.white70,
  'White': Colors.white,
  'Black': Colors.black,
  'Red': Colors.red,
  'Green': Colors.green,
  'Blue': Colors.blue,
  'Yellow': Colors.yellow,
  'Cyan': Colors.cyan,
};

final cursedSpeed = [
  ...List.generate(19, (i) => (i + 1) * 0.1),
  ...List.generate(8, (i) => (i + 3) * 0.5),
  ...List.generate(15, (i) => (i + 7) * 1.0),
  ...[25.0, 50.0, 75.0, 100.0],
];
