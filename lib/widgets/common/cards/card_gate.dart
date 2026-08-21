import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/media_card_registry.dart';
import 'package:anymex/widgets/common/cards/media_cards.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';

double getCardHeight(CardStyle style, bool isDesktop) {
  registerBuiltInMediaCardStyles();
  return MediaCardRegistry.getHeightByIndex(style.index, isDesktop);
}

double getResponsiveGridCardAspectRatio(BuildContext context) {
  final desktop = MediaQuery.sizeOf(context).width > 600;
  final style = CardStyle.values[settingsController.cardStyle];
  
  switch (style) {
    case CardStyle.saikou:
      return desktop ? (150 / 290) : (108 / 230);
    case CardStyle.exotic:
      return desktop ? (160 / 300) : (118 / 240);
    case CardStyle.minimalExotic:
      return desktop ? (160 / 270) : (118 / 210);
    case CardStyle.modern:
      return desktop ? (150 / 230) : (108 / 170);
    case CardStyle.glass:
      return desktop ? (150 / 230) : (108 / 170);
    case CardStyle.simple:
      return desktop ? (150 / 290) : (108 / 230);
  }
}

double getGridCardAspectRatio({
  required BuildContext context,
  required int crossAxisCount,
  required double spacing,
  double padding = 20,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final desktop = screenWidth > 600;
  final style = CardStyle.values[settingsController.cardStyle];
  
  final columnWidth = (screenWidth - padding - (spacing * (crossAxisCount - 1))) / crossAxisCount;
  final extraHeight = MediaCardRegistry.getExtraHeightByIndex(style.index, desktop);
  
  final cellHeight = columnWidth * 1.4 + extraHeight;
  return columnWidth / cellHeight;
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

  Widget getCard(BuildContext context) {
    registerBuiltInMediaCardStyles();

    final data = itemData is CarouselData
        ? itemData
        : convertData(itemData, isManga: !type.isAnime);

    final props = MediaCardProps(
      itemData: data,
      tag: tag,
      variant: variant,
      type: type,
    );

    return MediaCardRegistry.buildByIndex(
      context: context,
      index: cardStyle.index,
      props: props,
    );
  }

  CarouselData convertData(OfflineMedia data, {bool isManga = false}) {
    return CarouselData(
      title: data.displayTitle,
      id: data.id.toString(),
      poster: data.poster,
      extraData: data.rating,
      source: (isManga
              ? data.currentChapter?.number?.toString()
              : data.currentEpisode?.number) ??
          '1',
      releasing: data.status == "RELEASING",
      servicesType: serviceHandler.serviceType.value,
    );
  }
}
