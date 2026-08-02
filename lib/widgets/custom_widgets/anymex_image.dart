import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anymex/controllers/services/storage/anymex_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex_extension_runtime_bridge/Services/Aniyomi/Models/Source.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:get/get.dart';

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
  final String? sourceId;
  final bool? isAnime;
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
    this.sourceId,
    this.isAnime,
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
    final hero =
        flightDirection == HeroFlightDirection.push ? fromHero : toHero;

    return Material(
      type: MaterialType.transparency,
      child: hero.child,
    );
  }

  @override
  State<AnymeXImage> createState() => _AnymeXImageState();
}

class _AnymeXImageState extends State<AnymeXImage> {
  static final Map<String, bool> _isAniyomiCache = {};
  Uint8List? _cachedBytes;
  Color? _extractedColor;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _handleImageChange();
    _resolveHeaders();
  }

  @override
  void didUpdateWidget(AnymeXImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _handleImageChange();
    }
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.sourceId != widget.sourceId ||
        oldWidget.isAnime != widget.isAnime) {
      _resolveHeaders();
    }
  }

  bool _isAniyomiSource(String? sourceId) {
    if (sourceId == null || sourceId.isEmpty || sourceId == 'N/A') return false;
    if (_isAniyomiCache.containsKey(sourceId)) {
      return _isAniyomiCache[sourceId]!;
    }
    if (Get.isRegistered<SourceController>()) {
      final sourceController = Get.find<SourceController>();
      Source? source;
      for (final type in ItemType.values) {
        source = sourceController.findSourceById(sourceId, type);
        if (source != null) break;
      }
      final isAniyomi = source is ASource;
      _isAniyomiCache[sourceId] = isAniyomi;
      return isAniyomi;
    }
    return false;
  }

  Future<void> _resolveHeaders() async {
    if (!Platform.isAndroid) return;
    final sourceId = widget.sourceId;
    if (_isAniyomiSource(sourceId)) {
      if (mounted) {
        setState(() {
          _loadFailed = false;
        });
      }
      final bytes = await AnymeXRuntimeBridge.getImageBytes(
        sourceId!,
        widget.isAnime ?? true,
        widget.imageUrl,
      );
      if (mounted) {
        setState(() {
          if (bytes != null) {
            _cachedBytes = bytes;
          } else {
            _loadFailed = true;
          }
        });
      }
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
    _loadFailed = false;

    if (widget.onColorExtracted != null) {
      _extractDominantColor(isBase64);
    }
  }

  Widget _errorWidget() {
    if (widget.errorImage != null && widget.errorImage!.isNotEmpty) {
      return _errorImage(widget.errorImage!);
    }
    return _fallback(context);
  }

  @override
  Widget build(BuildContext context) {
    final isBase64 = _cachedBytes != null;
    final isNetworkImage = isNetworkImageUrl(widget.imageUrl);
    final isAniyomi = Platform.isAndroid && _isAniyomiSource(widget.sourceId);

    Widget imageContent;

    if (isAniyomi) {
      if (isBase64) {
        imageContent = Image.memory(
          _cachedBytes!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          color: widget.color,
          colorBlendMode: widget.color != null ? BlendMode.color : null,
          errorBuilder: (_, __, ___) => _errorWidget(),
        );
      } else if (_loadFailed) {
        imageContent = isNetworkImage
            ? _networkImage(widget.imageUrl)
            : _errorWidget();
      } else {
        imageContent = _placeholder(context);
      }
    } else {
      if (isBase64) {
        imageContent = Image.memory(
          _cachedBytes!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          color: widget.color,
          colorBlendMode: widget.color != null ? BlendMode.color : null,
          errorBuilder: (_, __, ___) => _fallback(context),
        );
      } else if (isNetworkImage) {
        imageContent = _networkImage(widget.imageUrl);
      } else {
        imageContent = _fileImage(widget.imageUrl);
      }
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: imageContent,
      ),
    );
  }

    Widget _networkImage(String imageUrl) {
    final url = Uri.tryParse(imageUrl);
    Map<String, String> headers = url != null ? {
      "Referer": "${url.origin}/",
      "Origin": url.origin,
    } : {};
    return CachedNetworkImage(
      cacheManager: AnymeXCacheManager.instance,
      imageUrl: imageUrl,
      httpHeaders: widget.headers ?? headers,
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

      if (_cachedBytes != null) {
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
