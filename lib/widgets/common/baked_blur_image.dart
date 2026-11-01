import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as img;

typedef _BakedRaster = ({int width, int height, Uint8List pixels});

_BakedRaster _processFrostedBackdrop((Uint8List, double, double) task) {
  final (sourceBytes, vibrancy, blurAmount) = task;
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) {
    throw StateError('Unable to decode image bytes');
  }

  final isTall = decoded.height > decoded.width;
  const targetShortSide = 240;
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

  static Future<ui.Image?> load(
    String url, {
    double saturation = 1.0,
    double blurAmount = 20.0,
  }) {
    final cacheKey = '$saturation|$blurAmount|$url';
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
        Uint8List rawBytes;
        if (url.startsWith('http://') || url.startsWith('https://')) {
          final file = await DefaultCacheManager().getSingleFile(url);
          rawBytes = await file.readAsBytes();
        } else if (url.startsWith('file://')) {
          final cleanPath = url.replaceFirst('file://', '');
          rawBytes = await File(cleanPath).readAsBytes();
        } else if (url.startsWith('assets/')) {
          final data = await rootBundle.load(url);
          rawBytes = data.buffer.asUint8List();
        } else {
          final diskFile = File(url);
          if (await diskFile.exists()) {
            rawBytes = await diskFile.readAsBytes();
          } else {
            return null;
          }
        }
        final raster = await compute(
          _processFrostedBackdrop,
          (rawBytes, saturation, blurAmount),
        );
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
        oldWidget.blurAmount != widget.blurAmount) {
      _requestBackdrop();
    }
  }

  void _requestBackdrop() {
    final currentId = ++_activeRunId;
    final cacheKey = '${widget.saturation}|${widget.blurAmount}|${widget.url}';
    final instantHit = BakedBlurImage._cacheStore[cacheKey];
    if (instantHit != null) {
      _renderedImage = instantHit;
      return;
    }

    BakedBlurImage.load(
      widget.url,
      saturation: widget.saturation,
      blurAmount: widget.blurAmount,
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
        );
      }
      if (mounted && currentId == _activeRunId && result != null) {
        setState(() {
          _renderedImage = result;
        });
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
      final fadeDistance = (widget.blurAmount * 2.5).clamp(24.0, 120.0);
      content = ShaderMask(
        shaderCallback: (bounds) {
          final fadeStart =
              ((bounds.height - fadeDistance) / bounds.height).clamp(0.5, 0.95);
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, fadeStart, 1.0],
            colors: const [
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: content,
      );
    }

    return AnimatedOpacity(
      opacity: image == null ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: content,
    );
  }
}
