import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_components.dart';
import 'package:anymex/widgets/common/cards/media_card_registry.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';

class SaikouCardStyle implements MediaCardStyle {
  @override
  String get id => 'saikou';
  @override
  String get displayName => 'Saikou';
  @override
  String get description => 'Clean vertical poster card with bottom-right badge rating.';

  @override
  double getHeight(bool isDesktop) => isDesktop ? 290 : 230;

  @override
  double getExtraHeight(bool isDesktop) => isDesktop ? 50 : 45;

  @override
  double getAspectRatio(bool isDesktop) => isDesktop ? (150 / 290) : (108 / 230);

  @override
  Widget buildCard(BuildContext context, MediaCardProps props) {
    return SaikouCard(
      itemData: props.itemData,
      tag: props.tag,
      variant: props.variant,
      type: props.type,
    );
  }
}

class SaikouCard extends CarouselCard {
  final DataVariant variant;
  final ItemType type;

  const SaikouCard({
    super.key,
    required super.itemData,
    required super.tag,
    required this.variant,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      constraints: BoxConstraints(maxWidth: desktop ? 150 : 108),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                MediaPoster(
                  imageUrl: itemData.poster ?? '',
                  heroTag: tag,
                  radius: 12,
                  sourceId: itemData.source,
                  isAnime: type == ItemType.anime,
                ),
                buildCardBadge(context, variant, type),
                if (variant == DataVariant.library)
                  MediaProgress(progressText: itemData.source ?? ''),
              ],
            ),
          ),
          if (shouldShowTitle()) ...[
            const SizedBox(height: 10),
            buildCardTitle(desktop),
          ],
        ],
      ),
    );
  }
}
