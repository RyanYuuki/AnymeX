import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_components.dart';
import 'package:anymex/widgets/common/cards/media_card_registry.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';

class DefaultCardStyle implements MediaCardStyle {
  @override
  String get id => 'default';
  @override
  String get displayName => 'Default';
  @override
  String get description =>
      'Container card layout with poster, title, extension info, and progress count.';

  @override
  double getHeight(bool isDesktop) => isDesktop ? 300 : 240;

  @override
  double getExtraHeight(bool isDesktop) => 25;

  @override
  double getAspectRatio(bool isDesktop) =>
      isDesktop ? (150 / getHeight(isDesktop)) : (108 / getHeight(isDesktop));

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

    final badgeText = getBadgeText(itemData, variant, type);
    final badgeIcon =
        getIconForVariant(itemData.extraData ?? '', variant, type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: theme.surfaceContainer.opaque(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.outline.opaque(0.15)),
      ),
      constraints: BoxConstraints(maxWidth: desktop ? 160 : 130),
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
            height: 62,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymeXText(
                  itemData.title ?? '?',
                  variant: TextVariant.semiBold,
                  size: 13,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.primary.opaque(0.1),
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
                      AnymeXText(
                        badgeText,
                        size: 10,
                        color: theme.primary,
                        variant: TextVariant.semiBold,
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
