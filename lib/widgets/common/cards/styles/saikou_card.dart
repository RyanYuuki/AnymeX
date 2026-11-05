import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
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
  double getHeight(bool isDesktop) =>
      settingsController.customCardStyle.getCardHeight(1, isDesktop);

  @override
  double getExtraHeight(bool isDesktop) =>
      settingsController.customCardStyle.getExtraHeight(1, isDesktop);

  @override
  double getAspectRatio(bool isDesktop) =>
      settingsController.customCardStyle.getCardAspectRatio(1, isDesktop);

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
    final config = settingsController.customCardStyle;
    final cardW = config.cardWidth(desktop, 1);
    final bottomH = config.getBottomHeight(1, desktop);
    final titleLines = config.titleLines;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      constraints: BoxConstraints(maxWidth: cardW),
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
            const SizedBox(height: 8),
            SizedBox(
              height: (bottomH - 8).clamp(20.0, 100.0),
              child: AnymeXText(
                itemData.title ?? '?',
                maxLines: titleLines,
                size: desktop ? 14 : 12,
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
