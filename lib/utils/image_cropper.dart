import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// Fetches an image from [url] using optional [headers], crops the white/black
/// margins and returns the cropped bytes.
Future<Uint8List> fetchAndCropImageBytes(
  String url, {
  Map<String, String>? headers,
  Duration? timeout,
  int threshold = 10,
}) async {
  try {
    final uri = Uri.parse(url);
    final effectiveTimeout = timeout ?? const Duration(seconds: 15);
    final response =
        await http.get(uri, headers: headers).timeout(effectiveTimeout);
    if (response.statusCode == 200) {
      final original = response.bodyBytes;
    
      final cropped = await compute(_cropImageIsolate, {
        'bytes': original,
        'threshold': threshold,
      });
      return cropped;
    }
  } catch (_) {
    // Fall through to return empty/failed bytes
  }
  // In case of any issue, fallback to returning an empty byte sequence.
  return Uint8List(0);
}

Uint8List _cropImageIsolate(Map<String, dynamic> data) {
  final bytes = data['bytes'] as Uint8List;
  final threshold = data['threshold'] as int;

  img.Image? image = img.decodeImage(bytes);
  if (image == null) return bytes;

  image = _applyCrop(image, isWhite: true, threshold: threshold);
  image = _applyCrop(image, isWhite: false, threshold: threshold);

  return Uint8List.fromList(img.encodePng(image));
}


class CroppedNetworkImage extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final int cropThreshold;

  const CroppedNetworkImage({
    super.key,
    required this.url,
    this.headers,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.placeholder,
    this.cropThreshold = 10,
  });

  @override
  State<CroppedNetworkImage> createState() => _CroppedNetworkImageState();
}

class _CroppedNetworkImageState extends State<CroppedNetworkImage> {
  static final Map<String, Uint8List> _cache = {};
  late Future<Uint8List> _futureBytes;

  @override
  void initState() {
    super.initState();
    _futureBytes = _loadBytes();
  }
  
  @override
  void didUpdateWidget(CroppedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.cropThreshold != widget.cropThreshold) {
      _futureBytes = _loadBytes();
    }
  }

  Future<Uint8List> _loadBytes() async {
  
    final headersKey =
        widget.headers?.entries.map((e) => '${e.key}:${e.value}').join(';') ??
            '';
    // Cache key now includes threshold so changing slider updates image
    final cacheKey = '${widget.url}#$headersKey#${widget.cropThreshold}';
    
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }
    
    final bytes = await fetchAndCropImageBytes(
      widget.url, 
      headers: widget.headers,
      threshold: widget.cropThreshold
    );
    
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
        return widget.placeholder ?? const SizedBox.shrink();
      },
    );
  }
}

img.Image _applyCrop(img.Image image, {required bool isWhite, required int threshold}) {
  int width = image.width;
  int height = image.height;
  int left = 0;
  int top = 0;
  int right = width - 1;
  int bottom = height - 1;

  final hasPalette = image.hasPalette;
  final palette = image.palette;

// Note, 
  // Dantotsu uses a similar approach with a strict threshold.
  // but i am using sum of RGB channels (max 765).
  // White: Brightness < (255 - threshold)
  // Black: Brightness > threshold
  
  bool isPixelContent(int x, int y) {
    final pixel = image.getPixel(x, y);
    num r, g, b;

    if (hasPalette && palette != null) {
    
      final index = pixel.r.toInt();
     
      if (index >= 0 && index < palette.numColors) {
         r = palette.getRed(index);
         g = palette.getGreen(index);
         b = palette.getBlue(index);
      } else {
         r = g = b = 0; 
      }
    } else {
      r = pixel.r;
      g = pixel.g;
      b = pixel.b;
    }

    final brightness = r + g + b;

    if (isWhite) {
   
      return brightness < (255 - threshold);
    } else {
    
      return brightness > threshold;
    }
  }


  // Top
  for (int y = 0; y < height; y++) {
    bool rowHasContent = false;
    for (int x = 0; x < width; x++) {
      if (isPixelContent(x, y)) {
        rowHasContent = true;
        break;
      }
    }
    if (rowHasContent) {
      top = y;
      break;
    }
  }
  // Bottom
  for (int y = height - 1; y >= top; y--) {
    bool rowHasContent = false;
    for (int x = 0; x < width; x++) {
      if (isPixelContent(x, y)) {
        rowHasContent = true;
        break;
      }
    }
    if (rowHasContent) {
      bottom = y;
      break;
    }
  }

  // Left
  for (int x = 0; x < width; x++) {
    bool colHasContent = false;
    for (int y = 0; y < height; y++) {
      if (isPixelContent(x, y)) {
        colHasContent = true;
        break;
      }
    }
    if (colHasContent) {
      left = x;
      break;
    }
  }

  // Right
  for (int x = width - 1; x >= left; x--) {
    bool colHasContent = false;
    for (int y = 0; y < height; y++) {
      if (isPixelContent(x, y)) {
        colHasContent = true;
        break;
      }
    }
    if (colHasContent) {
      right = x;
      break;
    }
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
