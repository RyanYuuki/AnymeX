import 'dart:convert';

import 'package:anymex/database/isar_models/key_value.dart';
import 'package:anymex/main.dart';
import 'package:anymex/utils/logger.dart';
import 'package:isar_community/isar.dart';

extension KvExtensions on Enum {
  T get<T>([T? defaultValue]) =>
      KvHelper.get<T>(name, defaultVal: defaultValue);

  void set<T>(T value) => KvHelper.set(name, value);

  Future<void> setAsync<T>(T value) => KvHelper.setAsync(name, value);

  void delete() => KvHelper.remove(name);

  Future<void> deleteAsync() => KvHelper.removeAsync(name);
}

class KvHelper {
  static T get<T>(String key, {T? defaultVal}) {
    final col = isar.collection<KeyValue>();
    final result = col.filter().keyEqualTo(key).findFirstSync();

    if (result?.value == null) {
      if (defaultVal != null) return defaultVal;
      Logger.e('Key $key not found');
      return null as T;
    }

    final dynamic val = jsonDecode(result!.value!)['val'];

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
      print(
        'Key $key expected type $T but got ${val.runtimeType}',
      );
      if (defaultVal != null) return defaultVal;
      return null as T;
    }

    return val;
  }

  static void set<T>(String key, T value) {
    final data = KeyValue()
      ..key = key
      ..value = jsonEncode({'val': value});

    try {
      isar.writeTxnSync(() {
        isar.collection<KeyValue>().putSync(data);
      });
    } catch (_) {
      isar.writeTxn(() async {
        await isar.collection<KeyValue>().put(data);
      });
    }
  }

  static Future<void> setAsync<T>(String key, T value) async {
    final data = KeyValue()
      ..key = key
      ..value = jsonEncode({'val': value});

    await isar.writeTxn(() async {
      await isar.collection<KeyValue>().put(data);
    });
  }

  static void remove(String key) {
    final col = isar.collection<KeyValue>();
    final data = col.filter().keyEqualTo(key).findFirstSync();

    if (data == null) return;

    try {
      isar.writeTxnSync(() {
        col.deleteSync(data.id);
      });
    } catch (_) {
      isar.writeTxn(() async {
        await col.delete(data.id);
      });
    }
  }

  static Future<void> removeAsync(String key) async {
    final col = isar.collection<KeyValue>();
    final data = await col.filter().keyEqualTo(key).findFirst();

    if (data == null) return;

    await isar.writeTxn(() async {
      await col.delete(data.id);
    });
  }
}

