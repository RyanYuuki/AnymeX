import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_components.dart';
import 'package:anymex/widgets/common/cards/media_card_registry.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';

class SimpleCardStyle implements MediaCardStyle {
  @override
  String get id => 'simple';
  @override
  String get displayName => 'Simple';
  @override
  String get description => 'Minimalist style with only the poster and title underneath.';

  @override
  double getHeight(bool isDesktop) => isDesktop ? 290 : 230;

  @override
  double getExtraHeight(bool isDesktop) => isDesktop ? 50 : 45;

  @override
  Widget buildCard(BuildContext context, MediaCardProps props) {
    return SimpleCard(
      itemData: props.itemData,
      tag: props.tag,
      variant: props.variant,
      type: props.type,
    );
  }
}

class SimpleCard extends CarouselCard {
  final DataVariant variant;
  final ItemType type;

  const SimpleCard({
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
            child: MediaPoster(
              imageUrl: itemData.poster ?? '',
              heroTag: tag,
              radius: 12,
              sourceId: itemData.source,
              isAnime: type == ItemType.anime,
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
