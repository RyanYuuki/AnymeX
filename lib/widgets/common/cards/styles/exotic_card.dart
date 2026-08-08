import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_components.dart';
import 'package:anymex/widgets/common/cards/media_card_registry.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';

class ExoticCardStyle implements MediaCardStyle {
  @override
  String get id => 'exotic';
  @override
  String get displayName => 'Exotic';
  @override
  String get description => 'Bordered card with glowing shadow and vibrant action banner.';

  @override
  double getHeight(bool isDesktop) => isDesktop ? 300 : 240;

  @override
  double getExtraHeight(bool isDesktop) => isDesktop ? 70 : 65;

  @override
  Widget buildCard(BuildContext context, MediaCardProps props) {
    return ExoticCard(
      itemData: props.itemData,
      tag: props.tag,
      variant: props.variant,
      type: props.type,
    );
  }
}

class ExoticCard extends CarouselCard {
  final DataVariant variant;
  final ItemType type;

  const ExoticCard({
    super.key,
    required super.itemData,
    required super.tag,
    required this.variant,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.colors.primary;
    final desktop = isDesktop(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      constraints: BoxConstraints(maxWidth: desktop ? 160 : 118),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.toDouble().multiplyRoundness()),
        boxShadow: [
          BoxShadow(
            color: primaryColor.opaque(0.15, iReallyMeanIt: true),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: MediaPoster(
              imageUrl: itemData.poster ?? '',
              heroTag: tag,
              radius: 12,
              border: Border.all(
                color: primaryColor.opaque(0.3, iReallyMeanIt: true),
                width: 2,
              ),
              sourceId: itemData.source,
              isAnime: type == ItemType.anime,
            ),
          ),
          if (shouldShowTitle()) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnymexText(
                text: itemData.title ?? '?',
                maxLines: 1,
                size: desktop ? 14 : 12,
                variant: TextVariant.semiBold,
                overflow: TextOverflow.ellipsis,
                isMarquee: false,
              ),
            ),
            const SizedBox(height: 10),
            _buildBottomBanner(context),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (variant == DataVariant.library) ...[
            AnymexText(
              text: !type.isAnime ? 'Chapter ' : 'Episode ',
              size: 12,
              color: context.colors.onPrimary,
              variant: TextVariant.bold,
            ),
            const SizedBox(width: 4),
            AnymexText(
              text: itemData.source ?? '',
              color: context.colors.onPrimary,
              size: 12,
              variant: TextVariant.bold,
            ),
          ] else ...[
            Icon(
              getIconForVariant(itemData.extraData ?? '', variant, type),
              size: 16,
              color: context.colors.onPrimary,
            ),
            const SizedBox(width: 4),
            AnymexText(
              text: (itemData.extraData ?? '').replaceAll('_', ' '),
              color: context.colors.onPrimary,
              size: 12,
              variant: TextVariant.bold,
            ),
          ],
        ],
      ),
    );
  }
}
