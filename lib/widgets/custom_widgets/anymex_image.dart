import 'dart:convert';
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

Uint8List base64ToBytes(String base64) {
  final cleaned = base64.contains(',') ? base64.split(',').last : base64;
  return base64Decode(cleaned);
}

class AnymeXImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;
  final Alignment alignment;
  final Color? color;
  final String? errorImage;
  final ValueChanged<Color>? onColorExtracted;

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
  });

  @override
  Widget build(BuildContext context) {
    final isBase64 = isBase64Image(imageUrl);

    if (onColorExtracted != null) {
      _extractDominantColor(isBase64);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: isBase64
          ? Image.memory(
              base64ToBytes(imageUrl),
              width: width,
              height: height,
              fit: fit,
              alignment: alignment,
              color: color,
              colorBlendMode: color != null ? BlendMode.color : null,
              errorBuilder: (_, __, ___) => _fallback(context),
            )
          : CachedNetworkImage(
              cacheManager: AnymeXCacheManager.instance,
              imageUrl: imageUrl,
              width: width,
              height: height,
              fit: fit,
              alignment: alignment,
              color: color,
              colorBlendMode: color != null ? BlendMode.color : null,
              placeholder: (_, __) => _placeholder(context),
              errorWidget: (_, __, ___) {
                if (errorImage != null && errorImage!.isNotEmpty) {
                  return CachedNetworkImage(
                    cacheManager: AnymeXCacheManager.instance,
                    imageUrl: errorImage!,
                    width: width,
                    height: height,
                    fit: fit,
                    placeholder: (_, __) => _placeholder(context),
                    errorWidget: (_, __, ___) => _fallback(context),
                  );
                }
                return _fallback(context);
              },
            ),
    );
  }

  Future<void> _extractDominantColor(bool isBase64) async {
    try {
      ImageProvider imageProvider;

      if (isBase64) {
        imageProvider = MemoryImage(base64ToBytes(imageUrl));
      } else {
        imageProvider = CachedNetworkImageProvider(
          imageUrl,
          cacheManager: AnymeXCacheManager.instance,
        );
      }

      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 10,
      );

      final dominantColor = paletteGenerator.dominantColor?.color ??
          paletteGenerator.vibrantColor?.color ??
          paletteGenerator.mutedColor?.color;

      if (dominantColor != null) {
        onColorExtracted?.call(dominantColor);
      }
    } catch (_) {}
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .opaque(0.2),
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .opaque(0.3),
            context.colors.surfaceContainer.opaque(0.5),
          ],
        ),
      ),
      child: Center(
        child: Text(
          '(╥﹏╥)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .opaque(0.3),
              ),
        ),
      ),
    );
  }
}
