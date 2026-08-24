import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/media_card_registry.dart';
import 'package:anymex/widgets/common/cards/media_cards.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';

double getCardHeight(int styleIndex, bool isDesktop) {
  registerBuiltInMediaCardStyles();
  return MediaCardRegistry.getHeightByIndex(styleIndex, isDesktop);
}

double getResponsiveGridCardAspectRatio(BuildContext context) {
  registerBuiltInMediaCardStyles();
  final desktop = MediaQuery.sizeOf(context).width > 600;
  return MediaCardRegistry.getAspectRatioByIndex(settingsController.cardStyle, desktop);
}

double getGridCardAspectRatio({
  required BuildContext context,
  required int crossAxisCount,
  required double spacing,
  double padding = 20,
}) {
  registerBuiltInMediaCardStyles();
  final screenWidth = MediaQuery.sizeOf(context).width;
  final desktop = screenWidth > 600;
  final columnWidth = (screenWidth - padding - (spacing * (crossAxisCount - 1))) / crossAxisCount;
  final extraHeight = MediaCardRegistry.getExtraHeightByIndex(settingsController.cardStyle, desktop);
  final cellHeight = columnWidth * 1.4 + extraHeight;
  return columnWidth / cellHeight;
}

class MediaCardGate extends StatelessWidget {
  final dynamic itemData;
  final String tag;
  final DataVariant variant;
  final ItemType type;
  final int? cardStyleIndex;

  const MediaCardGate({
    super.key,
    required this.itemData,
    required this.tag,
    required this.variant,
    required this.type,
    this.cardStyleIndex,
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
      index: cardStyleIndex ?? settingsController.cardStyle,
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
