import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

class NotificationImageHelper {
  static const int _maxCacheAgeHours = 48;
  static const int _maxCacheBytes = 25 * 1024 * 1024;

  static Future<String?> getCachedImagePath(String? imageUrl) async {
    if (imageUrl == null || imageUrl.trim().isEmpty) return null;

    final trimmed = imageUrl.trim();

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      final localFile = File(trimmed);
      if (await localFile.exists()) {
        return localFile.path;
      }
      return null;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/notification_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final hash = sha256.convert(utf8.encode(trimmed)).toString().substring(0, 24);
      final ext = _resolveExtension(trimmed);
      final targetFile = File('${cacheDir.path}/notif_$hash$ext');

      if (await targetFile.exists()) {
        final length = await targetFile.length();
        if (length > 0) {
          return targetFile.path;
        }
      }

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse(trimmed));
      final response = await request.close().timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
        }
        client.close();
        if (bytes.isNotEmpty) {
          await targetFile.writeAsBytes(bytes);
          _sweepCacheInBackground(cacheDir);
          return targetFile.path;
        }
      } else {
        client.close();
      }
    } catch (_) {}

    return null;
  }

  static String _resolveExtension(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.png')) return '.png';
    if (lower.contains('.webp')) return '.webp';
    if (lower.contains('.jpeg')) return '.jpeg';
    return '.jpg';
  }

  static void _sweepCacheInBackground(Directory cacheDir) {
    Future.microtask(() async {
      try {
        if (!await cacheDir.exists()) return;

        final now = DateTime.now();
        final entities = await cacheDir.list().toList();
        final List<File> files = [];
        int totalSize = 0;

        for (final entity in entities) {
          if (entity is File) {
            final stat = await entity.stat();
            final age = now.difference(stat.modified);
            if (age.inHours > _maxCacheAgeHours) {
              await entity.delete();
            } else {
              files.add(entity);
              totalSize += stat.size;
            }
          }
        }

        if (totalSize > _maxCacheBytes) {
          files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
          for (final f in files) {
            if (totalSize <= _maxCacheBytes) break;
            try {
              final size = await f.length();
              await f.delete();
              totalSize -= size;
            } catch (_) {}
          }
        }
      } catch (_) {}
    });
  }
}
