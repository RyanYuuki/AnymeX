import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Resizes [bytes] to fit within [maxWidth]×[maxHeight] using Lanczos3
/// interpolation, preserving aspect ratio.  The work is done synchronously so
/// it must be called inside a `compute()` isolate.
Uint8List _lanczosResizeIsolate(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final maxWidth = args['maxWidth'] as int;
  final maxHeight = args['maxHeight'] as int;

  final source = img.decodeImage(bytes);
  if (source == null) return bytes;

  // Only downscale; never upscale with Lanczos (it would be slow and produce
  // ringing artefacts on small images).
  if (source.width <= maxWidth && source.height <= maxHeight) return bytes;

  // Keep aspect ratio inside the requested box.
  final scaleX = maxWidth / source.width;
  final scaleY = maxHeight / source.height;
  final scale = scaleX < scaleY ? scaleX : scaleY;
  final targetW = (source.width * scale).round().clamp(1, maxWidth);
  final targetH = (source.height * scale).round().clamp(1, maxHeight);

  final resized = img.copyResize(
    source,
    width: targetW,
    height: targetH,
    interpolation: img.Interpolation.lanczos3,
  );

  return Uint8List.fromList(img.encodePng(resized));
}

// ---------------------------------------------------------------------------
// Network variant
// ---------------------------------------------------------------------------

/// Fetches a network image, applies Lanczos3 downscaling in a background
/// isolate, and renders the result.  Results are cached in memory for the
/// lifetime of the process so that repeated builds are cheap.
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
  static final Map<String, Uint8List> _cache = {};

  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(LanczosNetworkImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
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
      if (response.statusCode != 200) return null;

      final context = Get.context;
      if (context == null || !context.mounted) return null;

      final mq = MediaQuery.of(context);
      final physicalWidth =
          (mq.size.width * mq.devicePixelRatio).toInt().clamp(1, 4096);
      final physicalHeight =
          (mq.size.height * mq.devicePixelRatio).toInt().clamp(1, 4096);

      final processed = await compute(_lanczosResizeIsolate, {
        'bytes': response.bodyBytes,
        'maxWidth': physicalWidth,
        'maxHeight': physicalHeight,
      });
      _cache[widget.url] = processed;
      return processed;
    } catch (_) {
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

/// Reads a local image file, applies Lanczos3 downscaling in a background
/// isolate, and renders the result.
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
  static final Map<String, Uint8List> _cache = {};

  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(LanczosFileImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) {
      setState(() {
        _future = _load();
      });
    }
  }

  Future<Uint8List?> _load() async {
    if (_cache.containsKey(widget.path)) return _cache[widget.path];

    try {
      final raw = await File(widget.path).readAsBytes();

      final context = Get.context;
      if (context == null || !context.mounted) return null;

      final mq = MediaQuery.of(context);
      final physicalWidth =
          (mq.size.width * mq.devicePixelRatio).toInt().clamp(1, 4096);
      final physicalHeight =
          (mq.size.height * mq.devicePixelRatio).toInt().clamp(1, 4096);

      final processed = await compute(_lanczosResizeIsolate, {
        'bytes': raw,
        'maxWidth': physicalWidth,
        'maxHeight': physicalHeight,
      });
      _cache[widget.path] = processed;
      return processed;
    } catch (_) {
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
