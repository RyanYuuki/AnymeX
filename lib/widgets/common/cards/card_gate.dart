import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/media_cards.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:flutter/material.dart';

double getCardHeight(CardStyle style, bool isDesktop) {
  switch (style) {
    case CardStyle.modern:
      return isDesktop ? 230 : 170;
    case CardStyle.exotic:
      return isDesktop ? 300 : 240;
    case CardStyle.saikou:
      return isDesktop ? 290 : 230;
    case CardStyle.minimalExotic:
      return isDesktop ? 270 : 210;
    default:
      return isDesktop ? 230 : 170;
  }
}

class MediaCardGate extends StatelessWidget {
  final dynamic itemData;
  final String tag;
  final DataVariant variant;
  final ItemType type;
  final CardStyle cardStyle;

  const MediaCardGate({
    super.key,
    required this.itemData,
    required this.tag,
    required this.variant,
    required this.cardStyle,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return getCard(context);
  }

  getCard(context) {
    final data = itemData is CarouselData
        ? itemData
        : convertData(itemData, isManga: !type.isAnime);
    switch (cardStyle) {
      case CardStyle.saikou:
        return SaikouCard(
          itemData: data,
          tag: tag,
          variant: variant,
          type: type,
        );
      case CardStyle.exotic:
        return ExoticCard(
          itemData: data,
          tag: tag,
          variant: variant,
          type: type,
        );
      case CardStyle.modern:
        return ModernCard(
          itemData: data,
          tag: tag,
          variant: variant,
          type: type,
        );
      case CardStyle.blur:
        return BlurCard(itemData: data, tag: tag, variant: variant, type: type);
      case CardStyle.minimalExotic:
        return MinimalExoticCard(
            itemData: data, tag: tag, variant: variant, type: type);
    }
  }

  CarouselData convertData(OfflineMedia data, {bool isManga = false}) {
    return CarouselData(
        title: data.name,
        id: data.id.toString(),
        poster: data.poster,
        extraData: data.rating,
        source: (isManga
                ? data.currentChapter?.number?.toString()
                : data.currentEpisode?.number) ??
            '1',
        releasing: data.status == "RELEASING",
        servicesType: serviceHandler.serviceType.value);
  }
}
