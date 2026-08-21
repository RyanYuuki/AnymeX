import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

IconData getIconForVariant(String extraData, DataVariant variant, ItemType type) {
  switch (variant) {
    case DataVariant.anilist:
    case DataVariant.offline:
      return type == ItemType.manga ? Iconsax.book : Iconsax.play5;
    case DataVariant.library:
      return Iconsax.star5;
    case DataVariant.relation:
      if (extraData == "MANGA" || extraData == "ANIME") {
        return extraData == "MANGA" ? Iconsax.book : Iconsax.play5;
      }
      return type == ItemType.manga ? Iconsax.book5 : Iconsax.play5;
    case DataVariant.extension:
      return Iconsax.status;
    default:
      return Iconsax.star5;
  }
}

String getBadgeText(CarouselData itemData, DataVariant variant, ItemType type) {
  final text = itemData.extraData ?? '';
  final icon = getIconForVariant(text, variant, type);
  if (icon == Iconsax.star5) {
    final parsed = double.tryParse(text);
    if (parsed != null && parsed > 0) {
      final auth = Get.find<AnilistAuth>();
      return auth.formatScore(parsed);
    }
  }
  return text.replaceAll('_', ' ');
}

class MediaPoster extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final double radius;
  final BoxBorder? border;
  final String? sourceId;
  final bool? isAnime;

  const MediaPoster({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.radius = 12,
    this.border,
    this.sourceId,
    this.isAnime,
  });

  @override
  Widget build(BuildContext context) {
    Widget innerImage = AnymeXImage(
      imageUrl: imageUrl,
      radius: radius,
      height: double.infinity,
      width: double.infinity,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      sourceId: sourceId,
      isAnime: isAnime,
    );

    Widget clipWidget;
    if (border != null) {
      clipWidget = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius.multiplyRoundness()),
          border: border,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular((radius - 2).clamp(0, double.infinity).toDouble().multiplyRoundness()),
          child: innerImage,
        ),
      );
    } else {
      clipWidget = ClipRRect(
        borderRadius: BorderRadius.circular(radius.multiplyRoundness()),
        child: innerImage,
      );
    }

    return Hero(
      tag: heroTag,
      transitionOnUserGestures: true,
      flightShuttleBuilder: AnymeXImage.heroFlightShuttleBuilder,
      child: clipWidget,
    );
  }
}

enum BadgePosition { bottomRight, topLeft }

class MediaBadge extends StatelessWidget {
  final CarouselData itemData;
  final DataVariant variant;
  final ItemType type;
  final BadgePosition position;
  final bool isBlurred;

  const MediaBadge({
    super.key,
    required this.itemData,
    required this.variant,
    required this.type,
    this.position = BadgePosition.bottomRight,
    this.isBlurred = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeText = getBadgeText(itemData, variant, type);
    final badgeIcon = getIconForVariant(itemData.extraData ?? '', variant, type);

    if (position == BadgePosition.bottomRight) {
      return Positioned(
        right: 0,
        bottom: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(badgeIcon, size: 16, color: theme.colorScheme.onPrimary),
              const SizedBox(width: 4),
              AnymeXText(badgeText,
                color: theme.colorScheme.onPrimary,
                size: 12,
                variant: TextVariant.bold,
              ),
            ],
          ),
        ),
      );
    } else {
      return Positioned(
        top: 6,
        left: 6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isBlurred
                ? context.colors.surfaceContainer.withOpacity(0.6)
                : theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                badgeIcon,
                size: 15,
                color: isBlurred ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
              ),
              const SizedBox(width: 4),
              AnymeXText(badgeText,
                color: isBlurred ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
                size: 11,
                variant: TextVariant.bold,
              ),
            ],
          ),
        ),
      );
    }
  }
}

class MediaTitle extends StatelessWidget {
  final String title;
  final bool isDesktop;
  final int maxLines;
  final bool overlay;

  const MediaTitle({
    super.key,
    required this.title,
    required this.isDesktop,
    this.maxLines = 2,
    this.overlay = false,
  });

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty || title == '?') {
      return const SizedBox.shrink();
    }

    if (overlay) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.opaque(0.5, iReallyMeanIt: true),
              Colors.black.opaque(0.7, iReallyMeanIt: true),
            ],
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: AnymeXText(title,
          maxLines: maxLines,
          size: isDesktop ? 14 : 12,
          variant: TextVariant.semiBold,
          overflow: TextOverflow.ellipsis,
          color: Colors.white,
          isMarquee: false,
        ),
      );
    }

    return SizedBox(
      height: 50,
      child: AnymeXText(title,
        maxLines: maxLines,
        size: isDesktop ? 14 : 12,
        variant: TextVariant.semiBold,
        overflow: TextOverflow.ellipsis,
        isMarquee: false,
      ),
    );
  }
}

class MediaProgress extends StatelessWidget {
  final String progressText;

  const MediaProgress({
    super.key,
    required this.progressText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.play5,
              size: 16,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(width: 4),
            AnymeXText(progressText,
              color: theme.colorScheme.onPrimary,
              size: 12,
              variant: TextVariant.bold,
            ),
          ],
        ),
      ),
    );
  }
}
