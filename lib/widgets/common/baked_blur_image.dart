import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:anymex/utils/mesh_blur_helper.dart';
import 'package:anymex/controllers/services/storage/anymex_cache_manager.dart';

typedef _BakedRaster = ({int width, int height, Uint8List pixels});

_BakedRaster _processLegacyFrostedBackdrop((Uint8List, double, double) task) {
  final (sourceBytes, vibrancy, blurAmount) = task;
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) {
    throw StateError('Unable to decode image bytes');
  }

  final isTall = decoded.height > decoded.width;
  const targetShortSide = 200;
  var scaled = img.copyResize(
    decoded,
    width: isTall ? targetShortSide : null,
    height: isTall ? null : targetShortSide,
    interpolation: img.Interpolation.linear,
  );

  final blurRadius =
      (blurAmount * (targetShortSide / 400.0)).round().clamp(1, 35);
  var blurred = img.gaussianBlur(scaled, radius: blurRadius);

  if (vibrancy != 1.0) {
    blurred = img.adjustColor(blurred, saturation: vibrancy);
  }

  final rgbaImage = blurred.convert(numChannels: 4, alpha: 255);
  return (
    width: rgbaImage.width,
    height: rgbaImage.height,
    pixels: rgbaImage.getBytes(order: img.ChannelOrder.rgba),
  );
}

Future<_BakedRaster> _generateFrostedRaster(
    Uint8List rawBytes, double saturation, double blurAmount) {
  return compute(
    _processLegacyFrostedBackdrop,
    (rawBytes, saturation, blurAmount),
  );
}

Future<ui.Image> _inflateNativeImage(_BakedRaster raster) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    raster.pixels,
    raster.width,
    raster.height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

class BakedBlurImage extends StatefulWidget {
  final String url;
  final String? fallback;
  final double saturation;
  final double blurAmount;
  final double brightness;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Color? color;
  final bool fadeBottom;
  final bool isMesh;

  const BakedBlurImage({
    super.key,
    required this.url,
    this.fallback,
    this.saturation = 1.0,
    this.blurAmount = 20.0,
    this.brightness = 1.0,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.color,
    this.fadeBottom = false,
    this.isMesh = false,
  });

  static final Map<String, ui.Image> _cacheStore = {};
  static final Map<String, Future<ui.Image?>> _pendingRequests = {};
  static const int _cacheCapacity = 24;

  static void _storeInCache(String key, ui.Image image) {
    _cacheStore.remove(key);
    if (_cacheStore.length >= _cacheCapacity) {
      _cacheStore.remove(_cacheStore.keys.first);
    }
    _cacheStore[key] = image;
  }

  static Future<Uint8List?> getCachedBytesOnly(String url) async {
    try {
      if (url.isEmpty) return null;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final fileInfo = await AnymeXCacheManager.instance.getFileFromCache(url);
        if (fileInfo != null && await fileInfo.file.exists()) {
          return await fileInfo.file.readAsBytes();
        }
        return null;
      } else if (url.startsWith('file://')) {
        final cleanPath = url.replaceFirst('file://', '');
        final file = File(cleanPath);
        if (await file.exists()) return await file.readAsBytes();
      } else if (url.startsWith('assets/')) {
        final data = await rootBundle.load(url);
        return data.buffer.asUint8List();
      } else {
        final diskFile = File(url);
        if (await diskFile.exists()) {
          return await diskFile.readAsBytes();
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Uint8List?> _getBytesForUrl(String url) async {
    try {
      if (url.isEmpty) return null;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final cache = AnymeXCacheManager.instance;
        final cached = await cache.getFileFromCache(url);
        if (cached != null && await cached.file.exists()) {
          return await cached.file.readAsBytes();
        }
        final file = await cache.getSingleFile(url);
        return await file.readAsBytes();
      } else if (url.startsWith('file://')) {
        final cleanPath = url.replaceFirst('file://', '');
        final file = File(cleanPath);
        if (await file.exists()) return await file.readAsBytes();
      } else if (url.startsWith('assets/')) {
        final data = await rootBundle.load(url);
        return data.buffer.asUint8List();
      } else {
        final diskFile = File(url);
        if (await diskFile.exists()) {
          return await diskFile.readAsBytes();
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<ui.Image?> loadCachedOnly(
    String url, {
    double saturation = 1.0,
    double blurAmount = 20.0,
    bool isMesh = false,
  }) async {
    if (url.isEmpty) return null;
    final cacheKey = '$isMesh|$saturation|$blurAmount|$url';
    final existingImage = _cacheStore[cacheKey];
    if (existingImage != null) {
      return existingImage;
    }

    final rawBytes = await getCachedBytesOnly(url);
    if (rawBytes == null || rawBytes.isEmpty) return null;

    try {
      final raster = isMesh
          ? await compute(
              MeshBlurHelper.processMeshBackdrop,
              (rawBytes, saturation, blurAmount, url.hashCode),
            )
          : await _generateFrostedRaster(rawBytes, saturation, blurAmount);
      final nativeImage = await _inflateNativeImage(raster);
      _storeInCache(cacheKey, nativeImage);
      return nativeImage;
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image?> load(
    String url, {
    double saturation = 1.0,
    double blurAmount = 20.0,
    bool isMesh = false,
  }) {
    if (url.isEmpty) return Future.value(null);
    final cacheKey = '$isMesh|$saturation|$blurAmount|$url';
    final existingImage = _cacheStore[cacheKey];
    if (existingImage != null) {
      return Future.value(existingImage);
    }

    final activeRequest = _pendingRequests[cacheKey];
    if (activeRequest != null) {
      return activeRequest;
    }

    return _pendingRequests[cacheKey] = () async {
      try {
        final rawBytes = await _getBytesForUrl(url);
        if (rawBytes == null || rawBytes.isEmpty) return null;
        final raster = isMesh
            ? await compute(
                MeshBlurHelper.processMeshBackdrop,
                (rawBytes, saturation, blurAmount, url.hashCode),
              )
            : await _generateFrostedRaster(rawBytes, saturation, blurAmount);
        final nativeImage = await _inflateNativeImage(raster);
        _storeInCache(cacheKey, nativeImage);
        return nativeImage;
      } catch (e) {
        return null;
      } finally {
        _pendingRequests.remove(cacheKey);
      }
    }();
  }

  @override
  State<BakedBlurImage> createState() => _BakedBlurImageState();
}

class _BakedBlurImageState extends State<BakedBlurImage> {
  ui.Image? _renderedImage;
  int _activeRunId = 0;

  @override
  void initState() {
    super.initState();
    _requestBackdrop();
  }

  @override
  void didUpdateWidget(BakedBlurImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.fallback != widget.fallback ||
        oldWidget.saturation != widget.saturation ||
        oldWidget.blurAmount != widget.blurAmount ||
        oldWidget.isMesh != widget.isMesh) {
      _requestBackdrop();
    }
  }

  void _requestBackdrop() async {
    final currentId = ++_activeRunId;
    final primaryKey =
        '${widget.isMesh}|${widget.saturation}|${widget.blurAmount}|${widget.url}';
    final instantHit = BakedBlurImage._cacheStore[primaryKey];
    if (instantHit != null) {
      _renderedImage = instantHit;
      return;
    }

    if (widget.fallback != null && widget.fallback!.isNotEmpty) {
      final fallbackKey =
          '${widget.isMesh}|${widget.saturation}|${widget.blurAmount}|${widget.fallback}';
      final fallbackHit = BakedBlurImage._cacheStore[fallbackKey];
      if (fallbackHit != null && _renderedImage == null) {
        _renderedImage = fallbackHit;
      }
    }

    if (_renderedImage == null) {
      final fastPrimary = await BakedBlurImage.loadCachedOnly(
        widget.url,
        saturation: widget.saturation,
        blurAmount: widget.blurAmount,
        isMesh: widget.isMesh,
      );
      if (!mounted || currentId != _activeRunId) return;
      if (fastPrimary != null) {
        setState(() {
          _renderedImage = fastPrimary;
        });
        return;
      }

      if (_renderedImage == null &&
          widget.fallback != null &&
          widget.fallback!.isNotEmpty &&
          widget.fallback != widget.url) {
        final fastFallback = await BakedBlurImage.loadCachedOnly(
          widget.fallback!,
          saturation: widget.saturation,
          blurAmount: widget.blurAmount,
          isMesh: widget.isMesh,
        );
        if (!mounted || currentId != _activeRunId) return;
        if (fastFallback != null) {
          setState(() {
            _renderedImage = fastFallback;
          });
        }
      }
    }

    BakedBlurImage.load(
      widget.url,
      saturation: widget.saturation,
      blurAmount: widget.blurAmount,
      isMesh: widget.isMesh,
    ).then((result) async {
      if (!mounted || currentId != _activeRunId) return;
      if (result == null &&
          widget.fallback != null &&
          widget.fallback != widget.url &&
          widget.fallback!.isNotEmpty) {
        result = await BakedBlurImage.load(
          widget.fallback!,
          saturation: widget.saturation,
          blurAmount: widget.blurAmount,
          isMesh: widget.isMesh,
        );
      }
      if (mounted && currentId == _activeRunId && result != null) {
        if (_renderedImage != result) {
          setState(() {
            _renderedImage = result;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _renderedImage;

    Widget content = image == null
        ? const SizedBox.expand()
        : RawImage(
            image: image,
            fit: widget.fit,
            width: widget.width ?? double.infinity,
            height: widget.height ?? double.infinity,
            filterQuality: FilterQuality.medium,
          );

    if (image != null && widget.isMesh) {
      content = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: content,
      );
    }

    if (image != null && widget.color != null) {
      content = ColorFiltered(
        colorFilter: ColorFilter.mode(widget.color!, BlendMode.color),
        child: content,
      );
    }

    if (image != null && widget.brightness != 1.0) {
      final b = widget.brightness;
      content = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          b, 0, 0, 0, 0,
          0, b, 0, 0, 0,
          0, 0, b, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: content,
      );
    }

    if (image != null && widget.fadeBottom) {
      final fadeDistance = (widget.blurAmount * 2.5).clamp(32.0, 140.0);
      content = ClipRect(
        child: ShaderMask(
            shaderCallback: (bounds) {
              if (bounds.height <= 0) {
                return const LinearGradient(
                  colors: [Colors.transparent, Colors.transparent],
                ).createShader(bounds);
              }
              final fadeStart =
                  ((bounds.height - fadeDistance) / bounds.height).clamp(0.4, 0.85);
              final fadeEnd =
                  ((bounds.height - 12.0) / bounds.height).clamp(fadeStart + 0.02, 0.95);
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, fadeStart, fadeEnd, 1.0],
                colors: const [
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                  Colors.transparent,
                ],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: content,
          ),
        );
      } else {
        content = ClipRect(child: content);
      }

    return AnimatedOpacity(
      opacity: image == null ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: content,
    );
  }
}
