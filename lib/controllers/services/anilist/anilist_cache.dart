import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class _AnilistCacheEntry {
  final Map<String, dynamic> data;
  final DateTime expiresAt;

  _AnilistCacheEntry({
    required this.data,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class AnilistCache {
  static final AnilistCache instance = AnilistCache._();
  AnilistCache._();

  final Map<String, _AnilistCacheEntry> _memoryCache = {};
  Directory? _cacheDir;

  Future<Directory> _getDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/anilist_query_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  Map<String, dynamic>? getMemory(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _memoryCache.remove(key);
      return null;
    }
    return entry.data;
  }

  Future<Map<String, dynamic>?> get(String key) async {
    final fromMem = getMemory(key);
    if (fromMem != null) return fromMem;

    try {
      final safeKey = _sanitizeKey(key);
      final dir = await _getDir();
      final file = File('${dir.path}/$safeKey.json');
      if (!await file.exists()) return null;

      final raw = await file.readAsString();
      if (raw.isEmpty) return null;

      final decoded = await compute(_decodeJson, raw);
      final expiresAtMs = decoded['expiresAt'] as int?;
      if (expiresAtMs != null) {
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMs);
        if (DateTime.now().isAfter(expiresAt)) {
          file.delete().ignore();
          return null;
        }
        final data = decoded['data'] as Map<String, dynamic>?;
        if (data != null) {
          _memoryCache[key] = _AnilistCacheEntry(
            data: data,
            expiresAt: expiresAt,
          );
          return data;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    Duration ttl = const Duration(minutes: 15),
    bool persist = false,
  }) async {
    final expiresAt = DateTime.now().add(ttl);
    _memoryCache[key] = _AnilistCacheEntry(
      data: data,
      expiresAt: expiresAt,
    );

    if (persist) {
      try {
        final safeKey = _sanitizeKey(key);
        final dir = await _getDir();
        final file = File('${dir.path}/$safeKey.json');
        final payload = {
          'expiresAt': expiresAt.millisecondsSinceEpoch,
          'data': data,
        };
        final encoded = await compute(_encodeJson, payload);
        await file.writeAsString(encoded, flush: true);
      } catch (_) {}
    }
  }

  void invalidate(String key) {
    _memoryCache.remove(key);
    _deleteDiskFile(key).ignore();
  }

  void invalidatePrefix(String prefix) {
    _memoryCache.removeWhere((k, _) => k.startsWith(prefix));
    _deleteMatchingDiskFiles(prefix).ignore();
  }

  Future<void> _deleteDiskFile(String key) async {
    try {
      final safeKey = _sanitizeKey(key);
      final dir = await _getDir();
      final file = File('${dir.path}/$safeKey.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> _deleteMatchingDiskFiles(String prefix) async {
    try {
      final safePrefix = _sanitizeKey(prefix);
      final dir = await _getDir();
      if (!await dir.exists()) return;
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File) {
          final filename = entity.uri.pathSegments.last;
          if (filename.startsWith(safePrefix)) {
            await entity.delete();
          }
        }
      }
    } catch (_) {}
  }

  void clear() {
    _memoryCache.clear();
    _clearDisk().ignore();
  }

  Future<void> _clearDisk() async {
    try {
      final dir = await _getDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        _cacheDir = null;
      }
    } catch (_) {}
  }
}

Map<String, dynamic> _decodeJson(String source) =>
    jsonDecode(source) as Map<String, dynamic>;

String _encodeJson(Map<String, dynamic> data) => jsonEncode(data);
