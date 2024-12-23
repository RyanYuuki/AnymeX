import 'dart:io';

import 'package:anymex/Preferences/HiveDataClasses/Selected/Selected.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'HiveDataClasses/MalToken/MalToken.dart';
import 'HiveDataClasses/ShowResponse/ShowResponse.dart';

class Pref<T> {
  final Location location;
  final String key;
  final T defaultValue;

  const Pref(this.location, this.key, this.defaultValue);
}

enum Location {
  General,
  UI,
  Player,
  Reader,
  Irrelevant,
  Protected,
}

class PrefManager {
  static Box? _generalPreferences;
  static Box? _uiPreferences;
  static Box? _playerPreferences;
  static Box? _readerPreferences;
  static Box? _irrelevantPreferences;
  static Box? _protectedPreferences;

  // Call this method at the start of the app
  static Future<void> init() async {
    HiveAdapters();
    if (_generalPreferences != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/Dantotsu/preferences';
    await Directory(path).create(recursive: true);
    await Hive.initFlutter(path);
    _generalPreferences = await Hive.openBox('generalPreferences');
    _uiPreferences = await Hive.openBox('uiPreferences');
    _playerPreferences = await Hive.openBox('playerPreferences');
    _readerPreferences = await Hive.openBox('readerPreferences');
    _irrelevantPreferences = await Hive.openBox('irrelevantPreferences');
    _protectedPreferences = await Hive.openBox('protectedPreferences');
  }

  static void HiveAdapters() {
    Hive.registerAdapter(ShowResponseAdapter());
    Hive.registerAdapter(SelectedAdapter());
    Hive.registerAdapter(ResponseTokenAdapter());
  }

  static void setVal<T>(Pref<T> pref, T value) {
    _checkInitialization();
    final box = _getPrefBox(pref.location);
    box.put(pref.key, value);
  }

  static T getVal<T>(Pref<T> pref) {
    _checkInitialization();
    final box = _getPrefBox(pref.location);
    final value = box.get(pref.key, defaultValue: pref.defaultValue);
    if (value is T) {
      return value;
    } else if (value is Map) {
      if (T == Map<String, bool>) {
        return Map<String, bool>.from(value) as T;
      }
    }
    return pref.defaultValue;
  }

  static void setCustomVal<T>(String key, T value) {
    _checkInitialization();
    final box = _getPrefBox(Location.Irrelevant);
    box.put(key, value);
  }

  static T? getCustomVal<T>(String key) {
    _checkInitialization();
    final box = _getPrefBox(Location.Irrelevant);
    return box.get(key) as T?;
  }

  static void removeVal(Pref<dynamic> pref) {
    _checkInitialization();
    final box = _getPrefBox(pref.location);
    box.delete(pref.key);
  }

  // Helper method to check initialization
  static void _checkInitialization() {
    if (_generalPreferences == null) {
      throw Exception('Hive not initialized. Call PrefManager.init() first.');
    }
  }

  static Box _getPrefBox(Location location) {
    switch (location.name) {
      case 'General':
        return _generalPreferences!;
      case 'UI':
        return _uiPreferences!;
      case 'Player':
        return _playerPreferences!;
      case 'Reader':
        return _readerPreferences!;
      case 'Irrelevant':
        return _irrelevantPreferences!;
      case 'Protected':
        return _protectedPreferences!;
      default:
        throw Exception("Invalid box name");
    }
  }
}
