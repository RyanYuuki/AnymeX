import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anymex/controllers/services/storage/anymex_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import 'package:anymex/utils/theme_extensions.dart';

bool isBase64Image(String value) {
  if (value.isEmpty) return false;

  if (value.startsWith('data:image')) return true;

  return RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(value);
}

bool isNetworkImageUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

Uint8List base64ToBytes(String base64) {
  final cleaned = base64.contains(',') ? base64.split(',').last : base64;
  return base64Decode(cleaned);
}

class AnymeXImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;
  final Alignment alignment;
  final Color? color;
  final String? errorImage;
  final ValueChanged<Color>? onColorExtracted;
  final Map<String, String>? headers;
  final Duration? fadeInDuration;
  final Duration? fadeOutDuration;

  const AnymeXImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.radius = 8,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.color,
    this.errorImage,
    this.onColorExtracted,
    this.headers,
    this.fadeInDuration,
    this.fadeOutDuration,
  });

  static Widget heroFlightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final fromHero = fromHeroContext.widget as Hero;
    final toHero = toHeroContext.widget as Hero;
    final heroContext = flightDirection == HeroFlightDirection.push
        ? fromHeroContext
        : toHeroContext;
    final hero =
        flightDirection == HeroFlightDirection.push ? fromHero : toHero;

    return InheritedTheme.captureAll(
      heroContext,
      Material(
        type: MaterialType.transparency,
        child: hero.child,
      ),
    );
  }

  @override
  State<AnymeXImage> createState() => _AnymeXImageState();
}

class _AnymeXImageState extends State<AnymeXImage> {
  Uint8List? _cachedBytes;
  Color? _extractedColor;

  @override
  void initState() {
    super.initState();
    _handleImageChange();
  }

  @override
  void didUpdateWidget(AnymeXImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _handleImageChange();
    }
  }

  void _handleImageChange() {
    final isBase64 = isBase64Image(widget.imageUrl);
    if (isBase64) {
      _cachedBytes = base64ToBytes(widget.imageUrl);
    } else {
      _cachedBytes = null;
    }
    _extractedColor = null;

    if (widget.onColorExtracted != null) {
      _extractDominantColor(isBase64);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBase64 = _cachedBytes != null;
    final isNetworkImage = isNetworkImageUrl(widget.imageUrl);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: isBase64
            ? Image.memory(
                _cachedBytes!,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                alignment: widget.alignment,
                color: widget.color,
                colorBlendMode: widget.color != null ? BlendMode.color : null,
                errorBuilder: (_, __, ___) => _fallback(context),
              )
            : isNetworkImage
                ? _networkImage(widget.imageUrl)
                : _fileImage(widget.imageUrl),
      ),
    );
  }

  Widget _networkImage(String imageUrl) {
    return CachedNetworkImage(
      cacheManager: AnymeXCacheManager.instance,
      imageUrl: imageUrl,
      httpHeaders: widget.headers,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      color: widget.color,
      colorBlendMode: widget.color != null ? BlendMode.color : null,
      placeholder: (_, __) => _placeholder(context),
      fadeInDuration:
          widget.fadeInDuration ?? const Duration(milliseconds: 500),
      fadeOutDuration:
          widget.fadeOutDuration ?? const Duration(milliseconds: 300),
      errorWidget: (_, __, ___) {
        if (widget.errorImage != null && widget.errorImage!.isNotEmpty) {
          return _errorImage(widget.errorImage!);
        }
        return _fallback(context);
      },
    );
  }

  Widget _fileImage(String imagePath) {
    return Image.file(
      _fileFromPath(imagePath),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      color: widget.color,
      colorBlendMode: widget.color != null ? BlendMode.color : null,
      errorBuilder: (_, __, ___) {
        if (widget.errorImage != null && widget.errorImage!.isNotEmpty) {
          return _errorImage(widget.errorImage!);
        }
        return _fallback(context);
      },
    );
  }

  Widget _errorImage(String imageUrl) {
    if (isBase64Image(imageUrl)) {
      return Image.memory(
        base64ToBytes(imageUrl),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    if (isNetworkImageUrl(imageUrl)) {
      return CachedNetworkImage(
        cacheManager: AnymeXCacheManager.instance,
        imageUrl: imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (_, __) => _placeholder(context),
        fadeInDuration:
            widget.fadeInDuration ?? const Duration(milliseconds: 500),
        fadeOutDuration:
            widget.fadeOutDuration ?? const Duration(milliseconds: 300),
        errorWidget: (_, __, ___) => _fallback(context),
      );
    }

    return Image.file(
      _fileFromPath(imageUrl),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      errorBuilder: (_, __, ___) => _fallback(context),
    );
  }

  File _fileFromPath(String path) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.scheme == 'file') {
      return File.fromUri(uri);
    }
    return File(path);
  }

  Future<void> _extractDominantColor(bool isBase64) async {
    if (_extractedColor != null) return;
    try {
      ImageProvider imageProvider;

      if (isBase64) {
        imageProvider = MemoryImage(_cachedBytes!);
      } else if (isNetworkImageUrl(widget.imageUrl)) {
        imageProvider = CachedNetworkImageProvider(
          widget.imageUrl,
          cacheManager: AnymeXCacheManager.instance,
        );
      } else {
        imageProvider = FileImage(_fileFromPath(widget.imageUrl));
      }

      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 10,
      );

      final dominantColor = paletteGenerator.dominantColor?.color ??
          paletteGenerator.vibrantColor?.color ??
          paletteGenerator.mutedColor?.color;

      if (dominantColor != null && mounted) {
        _extractedColor = dominantColor;
        widget.onColorExtracted?.call(dominantColor);
      }
    } catch (_) {}
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.opaque(0.2),
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest.opaque(0.3),
            context.colors.surfaceContainer.opaque(0.5),
          ],
        ),
      ),
      child: Center(
        child: Text(
          '(╥﹏╥)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurfaceVariant.opaque(0.3),
              ),
        ),
      ),
    );
  }
}
