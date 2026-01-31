import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

final Map<String, Color> _colorCache = {};

class ImageColorExtractor {
  static const int _maxCacheSize = 50;

  static Future<Color?> extractColor(
    String imageUrl, {
    bool isBase64 = false,
    int maximumColorCount = 10,
    Size? targetSize,
  }) async {
    if (_colorCache.containsKey(imageUrl)) {
      return _colorCache[imageUrl];
    }

    try {
      ImageProvider imageProvider;

      if (isBase64) {
        imageProvider = MemoryImage(_base64ToBytes(imageUrl));
      } else {
        imageProvider = CachedNetworkImageProvider(imageUrl);
      }

      final size = targetSize ?? const Size(100, 100);

      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: size,
        maximumColorCount: maximumColorCount,
        timeout: const Duration(seconds: 5),
      );

      final dominantColor = paletteGenerator.dominantColor?.color ??
          paletteGenerator.vibrantColor?.color ??
          paletteGenerator.mutedColor?.color;

      if (dominantColor != null) {
        _cacheColor(imageUrl, dominantColor);
        return dominantColor;
      }
    } catch (e) {
      debugPrint('Color extraction failed for $imageUrl: $e');
    }

    return null;
  }

  static Future<Color?> extractColorIsolate(
    String imageUrl, {
    bool isBase64 = false,
  }) async {
    if (_colorCache.containsKey(imageUrl)) {
      return _colorCache[imageUrl];
    }

    try {
      final imageProvider = isBase64
          ? MemoryImage(_base64ToBytes(imageUrl))
          : CachedNetworkImageProvider(imageUrl) as ImageProvider;

      final imageStream = imageProvider.resolve(const ImageConfiguration());
      final completer = Completer<ui.Image>();

      imageStream.addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          completer.complete(info.image);
        }),
      );

      final image = await completer.future.timeout(
        const Duration(seconds: 5),
      );

      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;

      final color = await _extractDominantColorFromBytes(
        byteData,
        image.width,
        image.height,
      );

      return color;
    } catch (e) {
      debugPrint('Color extraction failed for $imageUrl: $e');
      return null;
    }
  }

  static Future<Color> _extractDominantColorFromBytes(
    ByteData byteData,
    int width,
    int height,
  ) async {
    final pixels = byteData.buffer.asUint8List();
    final Map<int, int> colorCount = {};

    final step = 10;

    for (int i = 0; i < pixels.length; i += 4 * step) {
      final r = pixels[i];
      final g = pixels[i + 1];
      final b = pixels[i + 2];
      final a = pixels[i + 3];

      if (a < 128) continue;

      final colorKey = ((r ~/ 32) << 10) | ((g ~/ 32) << 5) | (b ~/ 32);
      colorCount[colorKey] = (colorCount[colorKey] ?? 0) + 1;
    }

    if (colorCount.isEmpty) {
      return Colors.grey;
    }

    final mostCommon = colorCount.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    final r = ((mostCommon.key >> 10) & 0x1F) * 32;
    final g = ((mostCommon.key >> 5) & 0x1F) * 32;
    final b = (mostCommon.key & 0x1F) * 32;

    return Color.fromARGB(255, r, g, b);
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

  static Uint8List _base64ToBytes(String base64String) {
    throw UnimplementedError('Implement base64ToBytes');
  }
}
