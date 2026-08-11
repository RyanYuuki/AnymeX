import 'dart:ui' as ui;
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_components.dart';
import 'package:anymex/widgets/common/cards/media_card_registry.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';

class GlassCardStyle implements MediaCardStyle {
  @override
  String get id => 'glass';
  @override
  String get displayName => 'Glassmorphism';
  @override
  String get description => 'A frosted glass container overlay with high contrast borders.';

  @override
  double getHeight(bool isDesktop) => isDesktop ? 230 : 170;

  @override
  double getExtraHeight(bool isDesktop) => 0;

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      constraints: BoxConstraints(maxWidth: desktop ? 150 : 108),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.toDouble().multiplyRoundness()),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11.toDouble().multiplyRoundness()),
        child: Stack(
          children: [
            MediaPoster(
              imageUrl: itemData.poster ?? '',
              heroTag: tag,
              radius: 11,
              sourceId: itemData.source,
              isAnime: type == ItemType.anime,
            ),
            if (shouldShowTitle()) ...[
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.15),
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: AnymeXText(
                        text: itemData.title ?? '?',
                        maxLines: 2,
                        size: desktop ? 13 : 11,
                        variant: TextVariant.semiBold,
                        overflow: TextOverflow.ellipsis,
                        color: Colors.white.withOpacity(0.95),
                        isMarquee: false,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            MediaBadge(
              itemData: itemData,
              variant: variant,
              type: type,
              position: BadgePosition.topLeft,
              isBlurred: true,
            ),
          ],
        ),
      ),
    );
  }
}
