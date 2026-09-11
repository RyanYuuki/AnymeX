import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

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
        return _buildErrorWidget(context, () {
          final headersKey =
              widget.headers?.entries.map((e) => '${e.key}:${e.value}').join(';') ??
                  '';
          final cacheKey = '${widget.url}#$headersKey#${widget.cropThreshold}';
          _cache.remove(cacheKey);
          setState(() {
            _futureBytes = _loadBytes();
          });
        });
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context, VoidCallback onRetry) {
    final colors = Theme.of(context).colorScheme;
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.error.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.broken_image_rounded,
                color: colors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            const AnymeXText(
              'Failed to load page',
              variant: TextVariant.bold,
              size: 14,
            ),
            const SizedBox(height: 6),
            AnymeXText(
              'Tap retry to attempt loading again',
              size: 12,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: colors.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    AnymeXText(
                      'Retry',
                      variant: TextVariant.bold,
                      size: 13,
                      color: colors.onPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.height != null && widget.width != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: content,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final targetHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : (constraints.hasBoundedWidth
                ? constraints.maxWidth * 1.4
                : screenHeight * 0.7);
        return SizedBox(
          width: constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity,
          height: targetHeight > 0 ? targetHeight : screenHeight * 0.7,
          child: content,
        );
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
