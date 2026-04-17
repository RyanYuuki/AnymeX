import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:anymex/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_scaler/image_scaler.dart';
import 'package:image_scaler/types.dart';

/// Maximum number of entries kept in each in-memory cache.
const int _kMaxCacheEntries = 50;

/// A simple size-bounded cache backed by an insertion-ordered [Map].
/// When [_kMaxCacheEntries] is reached the oldest entry is evicted.
class _BoundedCache {
  final Map<String, Uint8List> _map = {};

  Uint8List? operator [](String key) => _map[key];

  bool containsKey(String key) => _map.containsKey(key);

  void operator []=(String key, Uint8List value) {
    // Remove first so that re-inserting refreshes insertion order (update).
    _map.remove(key);
    if (_map.length >= _kMaxCacheEntries) {
      // Evict the oldest entry.
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
  }
}

/// Resizes [bytes] to fit within [maxWidth]×[maxHeight] using Lanczos
/// pre-scaling from `image_scaler`, preserving aspect ratio.
Future<Uint8List> _lanczosResize(Uint8List bytes, int maxWidth, int maxHeight) async {
  ui.Codec? codec;
  ui.Image? source;
  ui.Image? scaled;
  try {
    codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    source = frame.image;

    // Only downscale; upscaling with Lanczos is expensive and unnecessary here.
    if (source.width <= maxWidth && source.height <= maxHeight) return bytes;

    final scaleX = maxWidth / source.width;
    final scaleY = maxHeight / source.height;
    final scaleRatio = scaleX < scaleY ? scaleX : scaleY;
    final targetW = (source.width * scaleRatio).round().clamp(1, maxWidth);
    final targetH = (source.height * scaleRatio).round().clamp(1, maxHeight);

    scaled = await scale(
      image: source,
      newSize: IntSize(targetW, targetH),
      algorithm: ScaleAlgorithm.lanczos,
      areaRadius: 1,
    );
    final png = await scaled.toByteData(format: ui.ImageByteFormat.png);
    return png?.buffer.asUint8List() ?? bytes;
  } catch (e) {
    debugPrint('LanczosResize: failed to process image, returning original bytes: $e');
    return bytes;
  } finally {
    scaled?.dispose();
    source?.dispose();
    codec?.dispose();
  }
}

// ---------------------------------------------------------------------------
// Network variant
// ---------------------------------------------------------------------------

/// Fetches a network image, applies Lanczos downscaling, and renders
/// the result.  Results are kept in a bounded LRU cache
/// (capped at [_kMaxCacheEntries] entries) so that repeated builds are cheap.
class LanczosNetworkImage extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? placeholder;
  final BoxConstraints? constraints;

  const LanczosNetworkImage({
    super.key,
    required this.url,
    this.headers,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.placeholder,
    this.constraints,
  });

  @override
  State<LanczosNetworkImage> createState() => _LanczosNetworkImageState();
}

class _LanczosNetworkImageState extends State<LanczosNetworkImage> {
  static final _BoundedCache _cache = _BoundedCache();

  Future<Uint8List?>? _future;
  // Screen dimensions captured synchronously (in didChangeDependencies)
  // before the async work begins.
  int _maxWidth = 1080;
  int _maxHeight = 1920;
  bool _loaded = false;

  void _updateDimensions() {
    final mq = MediaQuery.of(context);
    _maxWidth =
        (mq.size.width * mq.devicePixelRatio).toInt().clamp(1, 4096);
    _maxHeight =
        (mq.size.height * mq.devicePixelRatio).toInt().clamp(1, 4096);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDimensions();

    if (!_loaded) {
      _loaded = true;
      _future = _load();
    }
  }

  @override
  void didUpdateWidget(LanczosNetworkImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _updateDimensions();
      setState(() {
        _future = _load();
      });
    }
  }

  Future<Uint8List?> _load() async {
    if (_cache.containsKey(widget.url)) return _cache[widget.url];

    try {
      final response = await http
          .get(Uri.parse(widget.url), headers: widget.headers)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        Logger.w(
          'LanczosNetworkImage: HTTP ${response.statusCode} for ${widget.url}',
        );
        return null;
      }

      final processed = await _lanczosResize(
        response.bodyBytes,
        _maxWidth,
        _maxHeight,
      );
      _cache[widget.url] = processed;
      return processed;
    } on SocketException catch (e) {
      Logger.w('LanczosNetworkImage: Network error for ${widget.url}: $e');
      return null;
    } catch (e) {
      Logger.e('LanczosNetworkImage: Failed to load ${widget.url}: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return widget.placeholder ?? const SizedBox.shrink();
        }
        final data = snap.data;
        if (data == null || data.isEmpty) {
          return widget.placeholder ?? const SizedBox.shrink();
        }
        Widget image = Image.memory(
          data,
          fit: widget.fit,
          alignment: widget.alignment,
          gaplessPlayback: true,
        );
        if (widget.constraints != null) {
          image = ConstrainedBox(
            constraints: widget.constraints!,
            child: image,
          );
        }
        return image;
      },
    );
  }
}

// ---------------------------------------------------------------------------
// File variant
// ---------------------------------------------------------------------------

/// Reads a local image file, applies Lanczos downscaling, and renders the
/// result.
class LanczosFileImage extends StatefulWidget {
  final String path;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? placeholder;
  final BoxConstraints? constraints;

  const LanczosFileImage({
    super.key,
    required this.path,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.placeholder,
    this.constraints,
  });

  @override
  State<LanczosFileImage> createState() => _LanczosFileImageState();
}

class _LanczosFileImageState extends State<LanczosFileImage> {
  static final _BoundedCache _cache = _BoundedCache();

  Future<Uint8List?>? _future;
  int _maxWidth = 1080;
  int _maxHeight = 1920;
  bool _loaded = false;

  void _updateDimensions() {
    final mq = MediaQuery.of(context);
    _maxWidth =
        (mq.size.width * mq.devicePixelRatio).toInt().clamp(1, 4096);
    _maxHeight =
        (mq.size.height * mq.devicePixelRatio).toInt().clamp(1, 4096);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDimensions();

    if (!_loaded) {
      _loaded = true;
      _future = _load();
    }
  }

  @override
  void didUpdateWidget(LanczosFileImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) {
      _updateDimensions();
      setState(() {
        _future = _load();
      });
    }
  }

  Future<Uint8List?> _load() async {
    if (_cache.containsKey(widget.path)) return _cache[widget.path];

    try {
      final raw = await File(widget.path).readAsBytes();

      final processed = await _lanczosResize(raw, _maxWidth, _maxHeight);
      _cache[widget.path] = processed;
      return processed;
    } on FileSystemException catch (e) {
      Logger.w('LanczosFileImage: File error for ${widget.path}: $e');
      return null;
    } catch (e) {
      Logger.e('LanczosFileImage: Failed to process ${widget.path}: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return widget.placeholder ?? const SizedBox.shrink();
        }
        final data = snap.data;
        if (data == null || data.isEmpty) {
          return widget.placeholder ?? const SizedBox.shrink();
        }
        Widget image = Image.memory(
          data,
          fit: widget.fit,
          alignment: widget.alignment,
          gaplessPlayback: true,
        );
        if (widget.constraints != null) {
          image = ConstrainedBox(
            constraints: widget.constraints!,
            child: image,
          );
        }
        return image;
      },
    );
  }
}
