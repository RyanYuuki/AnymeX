import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AnymeXDecoratedAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? decorationUrl;
  final double size;
  final double decorationScale;
  final VoidCallback? onTap;
  final BoxBorder? customBorder;

  const AnymeXDecoratedAvatar({
    super.key,
    this.avatarUrl,
    this.decorationUrl,
    this.size = 40,
    this.decorationScale = 1.2,
    this.onTap,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final iconSize = size <= 28 ? 14.0 : 18.0;
    final hasDecoration = decorationUrl != null && decorationUrl!.trim().isNotEmpty;

    Widget avatarCore = AnymeXContainer(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainer,
        border: customBorder ??
            Border.all(
              color: colorScheme.outline.opaque(0.1, iReallyMeanIt: true),
              width: 1,
            ),
        boxShadow: size > 28
            ? [
                BoxShadow(
                  color: colorScheme.shadow.opaque(0.08, iReallyMeanIt: true),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: avatarUrl?.isNotEmpty == true
            ? AnymeXImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                radius: 0,
              )
            : Icon(
                Icons.person_rounded,
                color: colorScheme.onSurfaceVariant,
                size: iconSize,
              ),
      ),
    );

    Widget content;
    if (hasDecoration) {
      final decoSize = size * decorationScale;
      content = SizedBox(
        width: decoSize,
        height: decoSize,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            avatarCore,
            Positioned(
              width: decoSize,
              height: decoSize,
              child: IgnorePointer(
                child: CachedNetworkImage(
                  imageUrl: decorationUrl!,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox.shrink(),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      content = avatarCore;
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
