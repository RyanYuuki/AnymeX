import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:anymex/controllers/services/storage/anymex_cache_manager.dart';
import 'package:flutter/material.dart';

final Map<String, Color> _colorCache = {};

class ImageColorExtractor {
  static const int _maxCacheSize = 60;

  static Future<Color?> extractColor(
    String imageUrl, {
    bool isBase64 = false,
    int maximumColorCount = 10,
    Size? targetSize,
  }) async {
    if (imageUrl.isEmpty) return null;

    if (_colorCache.containsKey(imageUrl)) {
      return _colorCache[imageUrl];
    }

    try {
      Uint8List? bytes;

      if (isBase64) {
        bytes = base64Decode(imageUrl);
      } else if (imageUrl.startsWith('http://') ||
          imageUrl.startsWith('https://')) {
        final fileInfo =
            await AnymeXCacheManager.instance.getFileFromCache(imageUrl);
        if (fileInfo != null) {
          bytes = await fileInfo.file.readAsBytes();
        } else {
          final file = await AnymeXCacheManager.instance
              .getSingleFile(imageUrl)
              .timeout(const Duration(seconds: 4));
          bytes = await file.readAsBytes();
        }
      } else {
        final file = File(imageUrl);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) return null;

      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      buffer.dispose();

      final codec = await descriptor.instantiateCodec(
        targetWidth: 32,
        targetHeight: 32,
      );
      descriptor.dispose();

      final frame = await codec.getNextFrame();
      codec.dispose();

      final image = frame.image;
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();

      if (byteData == null) return null;

      final rawBytes = byteData.buffer.asUint8List();

      final colorInt = await Isolate.run(() => _findDominantColorInt(rawBytes));
      if (colorInt != null) {
        final dominantColor = Color(colorInt);
        _cacheColor(imageUrl, dominantColor);
        return dominantColor;
      }
    } catch (_) {}

    return null;
  }

  static int? _findDominantColorInt(Uint8List pixels) {
    if (pixels.isEmpty) return null;
    final Map<int, int> counts = {};

    for (int i = 0; i < pixels.length; i += 4) {
      final a = pixels[i + 3];
      if (a < 128) continue;
      final r = pixels[i];
      final g = pixels[i + 1];
      final b = pixels[i + 2];
      final key = ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3);
      counts[key] = (counts[key] ?? 0) + 1;
    }

    if (counts.isEmpty) return null;

    int bestKey = counts.keys.first;
    double bestScore = -1.0;
    int maxPop = 0;
    int mostCommonKey = bestKey;

    for (final entry in counts.entries) {
      final key = entry.key;
      final count = entry.value;

      if (count > maxPop) {
        maxPop = count;
        mostCommonKey = key;
      }

      final r = ((key >> 10) & 0x1F) * 8;
      final g = ((key >> 5) & 0x1F) * 8;
      final b = (key & 0x1F) * 8;

      final maxC = (r > g ? (r > b ? r : b) : (g > b ? g : b)) / 255.0;
      final minC = (r < g ? (r < b ? r : b) : (g < b ? g : b)) / 255.0;
      final l = (maxC + minC) / 2.0;
      final delta = maxC - minC;
      final s = delta == 0 ? 0.0 : delta / (1.0 - (2.0 * l - 1.0).abs());

      if (l < 0.12 || l > 0.90 || s < 0.10) {
        continue;
      }

      final score = count * (1.0 + s * 1.5) * (1.0 - (l - 0.5).abs());
      if (score > bestScore) {
        bestScore = score;
        bestKey = key;
      }
    }

    final chosenKey = bestScore > 0 ? bestKey : mostCommonKey;
    final r = (((chosenKey >> 10) & 0x1F) * 8 + 4).clamp(0, 255);
    final g = (((chosenKey >> 5) & 0x1F) * 8 + 4).clamp(0, 255);
    final b = ((chosenKey & 0x1F) * 8 + 4).clamp(0, 255);

    return (255 << 24) | (r << 16) | (g << 8) | b;
  }

  static Color? getCachedColor(String imageUrl) {
    return _colorCache[imageUrl];
  }

  static void precacheColor(String imageUrl, {bool isBase64 = false}) {
    if (!_colorCache.containsKey(imageUrl)) {
      extractColor(imageUrl, isBase64: isBase64);
    }
  }

  static void _cacheColor(String imageUrl, Color color) {
    if (_colorCache.length >= _maxCacheSize) {
      final firstKey = _colorCache.keys.first;
      _colorCache.remove(firstKey);
    }
    _colorCache[imageUrl] = color;
  }

  static void clearCache() {
    _colorCache.clear();
  }

  static void clearCachedColor(String imageUrl) {
    _colorCache.remove(imageUrl);
  }
}
