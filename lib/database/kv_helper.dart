import 'dart:convert';

import 'package:anymex/database/isar_models/key_value.dart';
import 'package:anymex/main.dart';
import 'package:anymex/utils/logger.dart';
import 'package:isar_community/isar.dart';

extension KvExtensions on Enum {
  String get _storageKey {
    if (runtimeType.toString() == 'NovelReaderKeys' && name == 'themeMode') {
      return 'novel_themeMode';
    }
    return name;
  }

  T get<T>([T? defaultValue]) =>
      KvHelper.get<T>(_storageKey, defaultVal: defaultValue);

  void set<T>(T value) => KvHelper.set(_storageKey, value);

  Future<void> setAsync<T>(T value) => KvHelper.setAsync(_storageKey, value);

  void delete() => KvHelper.remove(_storageKey);

  Future<void> deleteAsync() => KvHelper.removeAsync(_storageKey);
}

class KvHelper {
  static final Map<String, dynamic> _cache = {};
  static final Set<String> _missingKeys = {};

  static T get<T>(String key, {T? defaultVal}) {
    if (_cache.containsKey(key)) {
      final dynamic cached = _cache[key];
      if (cached is num) {
        if (T == double) {
          return cached.toDouble() as T;
        }
        if (T == int) {
          return cached.toInt() as T;
        }
      }
      if (cached is List && cached.every((e) => e is String)) {
        return cached.cast<String>() as T;
      }
      if (cached is Map) {
        return Map<String, dynamic>.from(cached) as T;
      }
      if (cached is T) {
        return cached;
      }
      if (valMatches<T>(cached)) {
        return cached as T;
      }
    }

    if (_missingKeys.contains(key)) {
      if (defaultVal != null) return defaultVal;
      return null as T;
    }

    final col = isar.collection<KeyValue>();
    final result = col.filter().keyEqualTo(key).findFirstSync();

    if (result?.value == null) {
      _missingKeys.add(key);
      if (defaultVal != null) return defaultVal;
      Logger.e('Key $key not found');
      return null as T;
    }

    final dynamic val = jsonDecode(result!.value!)['val'];
    _cache[key] = val;

    if (val is num) {
      if (T == double) {
        return val.toDouble() as T;
      }
      if (T == int) {
        return val.toInt() as T;
      }
    }

    if (val is List && val.every((e) => e is String)) {
      return val.cast<String>() as T;
    }

    if (val is Map) {
      return Map<String, dynamic>.from(val) as T;
    }

    if (val is! T) {
      if (T == int && val is String) {
        final parsed = int.tryParse(val);
        if (parsed != null) return parsed as T;
      }
      if (T == double && val is String) {
        final parsed = double.tryParse(val);
        if (parsed != null) return parsed as T;
      }
      if (T == String && val != null) {
        return val.toString() as T;
      }
      if (defaultVal != null) return defaultVal;
      return null as T;
    }

    return val;
  }

  static bool valMatches<T>(dynamic val) {
    return val is T;
  }

  static void set<T>(String key, T value) {
    _missingKeys.remove(key);
    _cache[key] = value;

    final data = KeyValue()
      ..key = key
      ..value = jsonEncode({'val': value});

    isar.writeTxn(() async {
      await isar.collection<KeyValue>().put(data);
    });
  }

  static Future<void> setAsync<T>(String key, T value) async {
    _missingKeys.remove(key);
    _cache[key] = value;

    final data = KeyValue()
      ..key = key
      ..value = jsonEncode({'val': value});

    await isar.writeTxn(() async {
      await isar.collection<KeyValue>().put(data);
    });
  }

  static void remove(String key) {
    _cache.remove(key);
    _missingKeys.add(key);

    isar.writeTxn(() async {
      final col = isar.collection<KeyValue>();
      final data = await col.filter().keyEqualTo(key).findFirst();
      if (data != null) {
        await col.delete(data.id);
      }
    });
  }

  static Future<void> removeAsync(String key) async {
    _cache.remove(key);
    _missingKeys.add(key);

    final col = isar.collection<KeyValue>();
    final data = await col.filter().keyEqualTo(key).findFirst();

    if (data == null) return;

    await isar.writeTxn(() async {
      await col.delete(data.id);
    });
  }
}

