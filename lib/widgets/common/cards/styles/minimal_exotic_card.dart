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

class MinimalExoticCardStyle implements MediaCardStyle {
  @override
  String get id => 'minimalExotic';
  @override
  String get displayName => 'Minimal Exotic';
  @override
  String get description => 'Bordered card with bottom gradient title and action banner.';

  @override
  double getHeight(bool isDesktop) => isDesktop ? 270 : 210;

  @override
  double getExtraHeight(bool isDesktop) => isDesktop ? 40 : 35;

  @override
  Widget buildCard(BuildContext context, MediaCardProps props) {
    return MinimalExoticCard(
      itemData: props.itemData,
      tag: props.tag,
      variant: props.variant,
      type: props.type,
    );
  }
}

class MinimalExoticCard extends CarouselCard {
  final DataVariant variant;
  final ItemType type;

  const MinimalExoticCard({
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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.toDouble().multiplyRoundness()),
                border: Border.all(
                  color: primaryColor.opaque(0.3, iReallyMeanIt: true),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.toDouble().multiplyRoundness()),
                child: Stack(
                  children: [
                    MediaPoster(
                      imageUrl: itemData.poster ?? '',
                      heroTag: tag,
                      radius: 10,
                    ),
                    if (variant == DataVariant.library)
                      buildCardBadgeV2(context, variant, type),
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
                  ],
                ),
              ),
            ),
          ),
          if (shouldShowTitle()) ...[
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
              getIconForVariant(
                  variant == DataVariant.relation
                      ? itemData.args ?? ''
                      : itemData.extraData ?? '',
                  variant,
                  type),
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
