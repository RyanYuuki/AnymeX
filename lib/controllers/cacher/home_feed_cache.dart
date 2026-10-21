import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class HomeFeedCache {
  static Directory? _cacheDir;

  static Future<Directory> _getDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/home_feed_cache');
    if (!await dir.exists()) {
      final legacyDir = Directory('${base.path}/feed_cache');
      if (await legacyDir.exists()) {
        try {
          await legacyDir.rename(dir.path);
          _cacheDir = dir;
          return dir;
        } catch (_) {}
      }
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  static Future<Map<String, dynamic>?> read(String key) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/$key.json');
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      if (raw.isEmpty) return null;
      return await compute(_decodeJson, raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String key, Map<String, dynamic> data) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/$key.json');
      final encoded = await compute(_encodeJson, data);
      await file.writeAsString(encoded, flush: true);
    } catch (_) {}
  }
}

Map<String, dynamic> _decodeJson(String source) =>
    jsonDecode(source) as Map<String, dynamic>;

String _encodeJson(Map<String, dynamic> data) => jsonEncode(data);
