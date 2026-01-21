import 'dart:async';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// Fetches an image from [url] using optional [headers], crops the white
/// margins and returns the cropped bytes.
Future<Uint8List> fetchAndCropImageBytes(
  String url, {
  Map<String, String>? headers,
  Duration? timeout,
}) async {
  try {
    final uri = Uri.parse(url);
    final effectiveTimeout = timeout ?? const Duration(seconds: 15);
    final response =
        await http.get(uri, headers: headers).timeout(effectiveTimeout);
    if (response.statusCode == 200) {
      final original = response.bodyBytes;
      // Reuse the existing cropper to trim any white/black borders.
      final cropped = await cropImageBorders(original);
      return cropped;
    }
  } catch (_) {
    // Fall through to return empty/failed bytes
  }
  // In case of any issue, fallback to returning an empty byte sequence.
  return Uint8List(0);
}

/// Simple in-memory cropping image widget for network images.
/// When cropping is used, this widget will fetch the image, crop it using
/// [fetchAndCropImageBytes], and render it from memory. If cropping fails,
/// it falls back to a regular network load by the caller.
class CroppedNetworkImage extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final Widget? placeholder;

  const CroppedNetworkImage({
    Key? key,
    required this.url,
    this.headers,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.placeholder,
  }) : super(key: key);

  @override
  _CroppedNetworkImageState createState() => _CroppedNetworkImageState();
}

class _CroppedNetworkImageState extends State<CroppedNetworkImage> {
  static final Map<String, Uint8List> _cache = {};
  late Future<Uint8List> _futureBytes;

  @override
  void initState() {
    super.initState();
    _futureBytes = _loadBytes();
  }

  Future<Uint8List> _loadBytes() async {
    // Include headers in the cache key to support different header sets per request
    final headersKey =
        widget.headers?.entries.map((e) => '${e.key}:${e.value}').join(';') ??
            '';
    final cacheKey = '${widget.url}#$headersKey';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }
    final bytes =
        await fetchAndCropImageBytes(widget.url, headers: widget.headers);
    if (bytes.isNotEmpty) {
      _cache[cacheKey] = bytes;
    }
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _futureBytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder ?? const SizedBox.shrink();
        }
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty) {
          return Image.memory(
            snapshot.data!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            alignment: widget.alignment,
          );
        }
        // Fallback: show nothing or a placeholder
        return widget.placeholder ?? const SizedBox.shrink();
      },
    );
  }
}

/// Crops the white borders from an image. Kept here to be used by fetcher.
Future<Uint8List> cropImageBorders(Uint8List imageBytes) async {
  return await tryCrop(imageBytes);
}

Future<Uint8List> tryCrop(Uint8List bytes) async {
  final cmd = img.Command();
  cmd.decodeImage(bytes);
  cmd.executeThread();

  img.Image? image = await cmd.getImage();
  if (image == null) return bytes;

  image = _applyCrop(image, isWhite: true);

  image = _applyCrop(image, isWhite: false);

  return img.encodePng(image);
}

img.Image _applyCrop(img.Image image, {required bool isWhite}) {
  int width = image.width;
  int height = image.height;
  int left = 0;
  int top = 0;
  int right = width - 1;
  int bottom = height - 1;
  int threshold = 10;

  bool isPixelContent(int x, int y) {
    var pixel = image.getPixel(x, y);
    num r = pixel.r;
    num g = pixel.g;
    num b = pixel.b;
    num brightness = r + g + b;

    if (isWhite) {
      return brightness < (765 - (threshold * 3));
    } else {
      return brightness > (threshold * 3);
    }
  }

  for (int x = 0; x < width; x++) {
    bool stop = false;
    for (int y = 0; y < height; y++) {
      if (isPixelContent(x, y)) {
        left = x;
        stop = true;
        break;
      }
    }
    if (stop) break;
  }

  for (int x = width - 1; x >= left; x--) {
    bool stop = false;
    for (int y = 0; y < height; y++) {
      if (isPixelContent(x, y)) {
        right = x;
        stop = true;
        break;
      }
    }
    if (stop) break;
  }

  for (int y = 0; y < height; y++) {
    bool stop = false;
    for (int x = left; x <= right; x++) {
      if (isPixelContent(x, y)) {
        top = y;
        stop = true;
        break;
      }
    }
    if (stop) break;
  }

  for (int y = height - 1; y >= top; y--) {
    bool stop = false;
    for (int x = left; x <= right; x++) {
      if (isPixelContent(x, y)) {
        bottom = y;
        stop = true;
        break;
      }
    }
    if (stop) break;
  }

  if (left > 0 || top > 0 || right < width - 1 || bottom < height - 1) {
    int w = right - left + 1;
    int h = bottom - top + 1;
    if (w > 0 && h > 0) {
      return img.copyCrop(image, x: left, y: top, width: w, height: h);
    }
  }

  return image;
}
