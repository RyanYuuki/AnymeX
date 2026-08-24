import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_components.dart';
import 'package:anymex/widgets/common/cards/media_card_registry.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';

class ModernCardStyle implements MediaCardStyle {
  @override
  String get id => 'modern';
  @override
  String get displayName => 'Modern';
  @override
  String get description => 'Full cover card with dark gradient title overlay at the bottom.';

  @override
  double getHeight(bool isDesktop) => isDesktop ? 230 : 170;

  @override
  double getExtraHeight(bool isDesktop) => 0;

  @override
  double getAspectRatio(bool isDesktop) => isDesktop ? (150 / 230) : (108 / 170);

  @override
  Widget buildCard(BuildContext context, MediaCardProps props) {
    return ModernCard(
      itemData: props.itemData,
      tag: props.tag,
      variant: props.variant,
      type: props.type,
    );
  }
}

class ModernCard extends CarouselCard {
  final DataVariant variant;
  final ItemType type;

  const ModernCard({
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.toDouble().multiplyRoundness()),
        child: Stack(
          children: [
            MediaPoster(
              imageUrl: itemData.poster ?? '',
              heroTag: tag,
              radius: 12,
              sourceId: itemData.source,
              isAnime: type == ItemType.anime,
            ),
            if (shouldShowTitle())
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MediaTitle(
                  title: itemData.title ?? '?',
                  isDesktop: desktop,
                  overlay: true,
                ),
              ),
            buildCardBadgeV2(context, variant, type),
          ],
        ),
      ),
    );
  }
}
