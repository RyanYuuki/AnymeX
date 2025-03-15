import 'package:anymex/models/Carousel/carousel.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/media_cards.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';

double getCardHeight(CardStyle style, bool isDesktop) {
  switch (style) {
    case CardStyle.modern:
      return isDesktop ? 230 : 170;
    case CardStyle.exotic:
      return isDesktop ? 300 : 240;
    case CardStyle.saikou:
      return isDesktop ? 290 : 230;
    default:
      return isDesktop ? 230 : 170;
  }
}

class MediaCardGate extends StatelessWidget {
  final CarouselData itemData;
  final String tag;
  final DataVariant variant;
  final bool isManga;
  final CardStyle cardStyle;

  const MediaCardGate({
    super.key,
    required this.itemData,
    required this.tag,
    required this.variant,
    required this.isManga,
    required this.cardStyle,
  });

  @override
  Widget build(BuildContext context) {
    return getCard(context);
  }

  getCard(context) {
    final isDesktop =
        getResponsiveValue(context, mobileValue: false, desktopValue: true);
    switch (cardStyle) {
      case CardStyle.saikou:
        return SaikouCard(
          itemData: itemData,
          tag: tag,
          variant: variant,
          isManga: isManga,
        );
      case CardStyle.exotic:
        return ExoticCard(
          itemData: itemData,
          tag: tag,
          variant: variant,
          isManga: isManga,
        );
      case CardStyle.modern:
        return SizedBox(
          height: getCardHeight(CardStyle.modern, isDesktop),
          child: ModernCard(
            itemData: itemData,
            tag: tag,
            variant: variant,
            isManga: isManga,
          ),
        );
      case CardStyle.blur:
        return SizedBox(
          height: getCardHeight(CardStyle.blur, isDesktop),
          child: BlurCard(
              itemData: itemData, tag: tag, variant: variant, isManga: isManga),
        );
    }
  }
}
