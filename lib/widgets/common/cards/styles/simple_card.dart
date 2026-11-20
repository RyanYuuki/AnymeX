import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_components.dart';
import 'package:anymex/widgets/common/cards/media_card_registry.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class DefaultCardStyle implements MediaCardStyle {
  @override
  String get id => 'default';
  @override
  String get displayName => 'Default';
  @override
  String get description =>
      'Container card layout with poster, title, extension info, and progress count.';

  @override
  double getHeight(bool isDesktop) =>
      settingsController.customCardStyle.getCardHeight(0, isDesktop);

  @override
  double getExtraHeight(bool isDesktop) =>
      settingsController.customCardStyle.getExtraHeight(0, isDesktop);

  @override
  double getAspectRatio(bool isDesktop) =>
      settingsController.customCardStyle.getCardAspectRatio(0, isDesktop);

  @override
  Widget buildCard(BuildContext context, MediaCardProps props) {
    return DefaultCard(
      itemData: props.itemData,
      tag: props.tag,
      variant: props.variant,
      type: props.type,
    );
  }
}

class DefaultCard extends CarouselCard {
  final DataVariant variant;
  final ItemType type;

  const DefaultCard({
    super.key,
    required super.itemData,
    required super.tag,
    required this.variant,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final theme = context.colors;
    final config = settingsController.customCardStyle;

    final isLibrary = variant == DataVariant.library;
    final progress = (itemData.source != null && itemData.source!.isNotEmpty)
        ? itemData.source!
        : '1';
    final prefix = type == ItemType.anime ? 'Episode ' : 'Chapter ';
    final badgeText = isLibrary
        ? (progress.toLowerCase().startsWith('ch') ||
                progress.toLowerCase().startsWith('ep')
            ? progress
            : '$prefix$progress')
        : getBadgeText(itemData, variant, type);
    final badgeIcon = isLibrary
        ? (type == ItemType.anime ? Iconsax.play5 : Iconsax.book)
        : getIconForVariant(itemData.extraData ?? '', variant, type);

    final cardW = config.cardWidth(desktop, 0);
    final bottomH = config.getBottomHeight(0, desktop);
    final titleLines = config.titleLines;

    return Container(
      width: cardW,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: theme.surfaceContainer.opaque(0.3, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.outline.opaque(0.15, iReallyMeanIt: true)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: MediaPoster(
                imageUrl: itemData.poster ?? '',
                heroTag: tag,
                radius: 0,
                sourceId: itemData.source,
                isAnime: type == ItemType.anime,
              ),
            ),
          ),
          Container(
            height: bottomH,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: AnymeXText(
                      itemData.title ?? '?',
                      variant: TextVariant.semiBold,
                      size: 13,
                      maxLines: titleLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.primary.opaque(0.1, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        badgeIcon,
                        size: 15,
                        color: theme.primary,
                      ),
                      2.width(),
                      Flexible(
                        child: AnymeXText(
                          badgeText,
                          size: 10,
                          color: theme.primary,
                          variant: TextVariant.semiBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
