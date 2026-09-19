import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnymeXDecoratedAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? decorationUrl;
  final double size;
  final double decorationScale;
  final VoidCallback? onTap;
  final BoxBorder? customBorder;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final String? heroTag;

  const AnymeXDecoratedAvatar({
    super.key,
    this.avatarUrl,
    this.decorationUrl,
    this.size = 40,
    this.decorationScale = 1.2,
    this.onTap,
    this.customBorder,
    this.borderRadius,
    this.shape = BoxShape.circle,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final iconSize = size <= 28 ? 14.0 : 18.0;
    final _decoTrimmed = decorationUrl?.trim() ?? '';
    final hasDecoration = _decoTrimmed.isNotEmpty && _decoTrimmed != 'null';
    final isCircle = shape == BoxShape.circle && borderRadius == null;

    Widget avatarCore = AnymeXContainer(
      width: size,
      height: size,
      // Outer clip must match the shape — previously only `decoration:`
      // carried the radius while the outer ClipRRect stayed square (0),
      // so rectangle avatars painted square corners.
      borderRadius:
          isCircle ? null : (borderRadius ?? BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius:
            isCircle ? null : (borderRadius ?? BorderRadius.circular(12)),
        // When a frame is equipped the frame itself is the border —
        // painting our own 1px ring + bg underneath is what peeked
        // through as a "second border".
        color:
            hasDecoration ? Colors.transparent : colorScheme.surfaceContainer,
        border: customBorder ??
            (hasDecoration
                ? null
                : Border.all(
                    color: colorScheme.outline.opaque(0.1, iReallyMeanIt: true),
                    width: 1,
                  )),
        boxShadow: (!hasDecoration && size > 28)
            ? [
                BoxShadow(
                  color: colorScheme.shadow.opaque(0.08, iReallyMeanIt: true),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: isCircle
          ? ClipOval(
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
            )
          : ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
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

    if (heroTag != null) {
      avatarCore = Hero(
        tag: heroTag!,
        child: avatarCore,
      );
    }

    Widget content;
    if (hasDecoration) {
      final decoSize = size * decorationScale;
      // Original layout: box is decoSize so the frame always has room
      // and never gets clipped by headers/lists (first implementation).
      Widget frame = CachedNetworkImage(
        imageUrl: decorationUrl!.trim(),
        fit: BoxFit.contain,
        placeholder: (context, url) => const SizedBox.shrink(),
        errorWidget: (context, url, error) => const SizedBox.shrink(),
      );
      // Rectangle avatars (profile headers): the frame PNG is square, so
      // clip it to the avatar's rounding — otherwise its sharp corners
      // stick out past the rounded avatar. Circle frames stay unclipped.
      if (!isCircle) {
        frame = ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: frame,
        );
      }
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
              child: IgnorePointer(child: frame),
            ),
          ],
        ),
      );
    } else {
      content = avatarCore;
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}

/// Avatar that resolves its Commentum frame by [userId].
///
/// Reads the decoration cache synchronously (zero cost when a list screen
/// prefetched via [CommentumService.prefetchCustomizations]); on a cache
/// miss it fetches that single user once and rebuilds. Falls back to a
/// plain avatar when logged out or the id is missing.
class CommentumAvatar extends StatefulWidget {
  final String? userId;
  final String? avatarUrl;
  final double size;
  final double decorationScale;
  final VoidCallback? onTap;
  final String? clientType;

  const CommentumAvatar({
    super.key,
    this.userId,
    this.avatarUrl,
    this.size = 40,
    this.decorationScale = 1.2,
    this.onTap,
    this.clientType,
  });

  @override
  State<CommentumAvatar> createState() => _CommentumAvatarState();
}

class _CommentumAvatarState extends State<CommentumAvatar> {
  String? _decoration;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _decoration = _cached();
    if (_decoration == null) _fetchOnce();
  }

  @override
  void didUpdateWidget(covariant CommentumAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.clientType != widget.clientType) {
      _decoration = _cached();
      _fetching = false;
      if (_decoration == null) _fetchOnce();
    }
  }

  String? _cached() {
    final id = widget.userId?.trim() ?? '';
    if (id.isEmpty || !Get.isRegistered<CommentumService>()) return null;
    return Get.find<CommentumService>().getCachedDecoration(
      id,
      clientType: widget.clientType ?? 'anilist',
    );
  }

  Future<void> _fetchOnce() async {
    if (_fetching) return;
    final id = widget.userId?.trim() ?? '';
    if (id.isEmpty || !Get.isRegistered<CommentumService>()) return;
    _fetching = true;
    try {
      final profile = await Get.find<CommentumService>().fetchUserProfile(id);
      if (!mounted) return;
      setState(() {
        final raw = profile?['avatar_decoration']?.toString() ?? '';
        _decoration = (raw.isEmpty || raw == 'null') ? null : raw;
      });
    } catch (_) {
      // Stay decoration-less rather than breaking the row.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXDecoratedAvatar(
      avatarUrl: widget.avatarUrl,
      decorationUrl: _decoration,
      size: widget.size,
      decorationScale: widget.decorationScale,
      onTap: widget.onTap,
    );
  }
}
