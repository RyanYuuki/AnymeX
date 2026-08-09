import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/card_components.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';

enum CardStyle { saikou, exotic, minimalExotic, modern, glass }

abstract class CarouselCard extends StatelessWidget {
  final CarouselData itemData;
  final String tag;

  const CarouselCard({
    super.key,
    required this.itemData,
    required this.tag,
  });

  bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width > 600;

  bool shouldShowTitle() {
    return itemData.title != null &&
        itemData.title!.isNotEmpty &&
        itemData.title != '?';
  }

  Widget buildCardTitle(bool isDesktop) {
    return MediaTitle(
      title: itemData.title ?? '?',
      isDesktop: isDesktop,
    );
  }

  String getBadgeText(DataVariant variant, ItemType type) {
    return getBadgeTextHelper(itemData, variant, type);
  }

  Widget buildCardBadgeV2(
      BuildContext context, DataVariant variant, ItemType type) {
    return MediaBadge(
      itemData: itemData,
      variant: variant,
      type: type,
      position: BadgePosition.topLeft,
    );
  }

  Widget buildCardBadge(
      BuildContext context, DataVariant variant, ItemType type) {
    return MediaBadge(
      itemData: itemData,
      variant: variant,
      type: type,
      position: BadgePosition.bottomRight,
    );
  }

  IconData getIconForVariant(
      String extraData, DataVariant variant, ItemType type) {
    return getIconForVariantHelper(extraData, variant, type);
  }
}

String getBadgeTextHelper(CarouselData itemData, DataVariant variant, ItemType type) =>
    getBadgeText(itemData, variant, type);

IconData getIconForVariantHelper(String extraData, DataVariant variant, ItemType type) =>
    getIconForVariant(extraData, variant, type);
