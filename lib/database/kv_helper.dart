import 'dart:convert';

import 'package:anymex/database/isar_models/key_value.dart';
import 'package:anymex/main.dart';
import 'package:isar_community/isar.dart';

extension KvExtensions on Enum {
  T get<T>(T defaultVal) => KvHelper.get<T>(name);

  void set<T>(T value) => KvHelper.set(name, value);

  void delete() => KvHelper.remove(name);
}

class KvHelper {
  static T get<T>(String key, {T? defaultVal}) {
    final col = isar.collection<KeyValue>();
    final result = col.filter().keyEqualTo(key).findFirstSync();

    if (result?.value == null) {
      if (defaultVal != null) return defaultVal as T;
      return Exception('Key $key not found') as T;
    }

    final val = jsonDecode(result!.value!)["val"];

    if (T == double && val is int) {
      return val.toDouble() as T;
    }

    return val as T;
  }

  static void set<T>(String key, T value) {
    final data = KeyValue()
      ..key = key
      ..value = jsonEncode({"val": value});

    isar.writeTxnSync(() {
      isar.collection<KeyValue>().putSync(data);
    });
  }

  static void remove(String key) {
    final col = isar.collection<KeyValue>();
    final data = col.filter().keyEqualTo(key).findFirstSync();

    if (data == null) return;

    isar.writeTxnSync(() {
      col.deleteSync(data.id);
    });
  }
}
