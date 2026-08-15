import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_components.dart';
import 'package:anymex/widgets/common/cards/media_card_registry.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';

class GlassCardStyle implements MediaCardStyle {
  @override
  String get id => 'glass';
  @override
  String get displayName => 'Glassmorphism';
  @override
  String get description => 'A frosted glass container overlay with high contrast borders. (Note: Glassmorphism only works in Liquid Theme)';

  @override
  double getHeight(bool isDesktop) => isDesktop ? 290 : 230;

  @override
  double getExtraHeight(bool isDesktop) => isDesktop ? 50 : 45;

  @override
  Widget buildCard(BuildContext context, MediaCardProps props) {
    return GlassCard(
      itemData: props.itemData,
      tag: props.tag,
      variant: props.variant,
      type: props.type,
    );
  }
}

class GlassCard extends CarouselCard {
  final DataVariant variant;
  final ItemType type;

  const GlassCard({
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
    final multiply = 1.toDouble().multiplyRoundness();
    final borderRad = BorderRadius.circular(12 * multiply);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      constraints: BoxConstraints(maxWidth: desktop ? 150 : 108),
      decoration: BoxDecoration(
        color: theme.surfaceContainer.opaque(0.3),
        borderRadius: borderRad,
        border: Border.all(
          color: theme.outline.opaque(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(11 * multiply),
                  ),
                  child: MediaPoster(
                    imageUrl: itemData.poster ?? '',
                    heroTag: tag,
                    radius: 0,
                    sourceId: itemData.source,
                    isAnime: type == ItemType.anime,
                  ),
                ),
                MediaBadge(
                  itemData: itemData,
                  variant: variant,
                  type: type,
                  position: BadgePosition.topLeft,
                ),
              ],
            ),
          ),
          if (shouldShowTitle()) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: AnymeXText(
                text: itemData.title ?? '?',
                maxLines: 2,
                size: desktop ? 12 : 10.5,
                variant: TextVariant.semiBold,
                overflow: TextOverflow.ellipsis,
                isMarquee: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
