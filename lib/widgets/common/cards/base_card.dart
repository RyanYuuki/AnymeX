import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

enum CardStyle { saikou, exotic, minimalExotic, modern, blur }

abstract class CarouselCard extends StatelessWidget {
  final CarouselData itemData;
  final String tag;

  const CarouselCard({
    super.key,
    required this.itemData,
    required this.tag,
  });

  bool isDesktop(context) => MediaQuery.of(context).size.width > 600;

  bool shouldShowTitle() {
    return itemData.title != null &&
        itemData.title!.isNotEmpty &&
        itemData.title != '?';
  }

  Widget buildCardTitle(bool isDesktop) {
    return SizedBox(
      height: 50,
      child: AnymexText(
        text: itemData.title ?? '?',
        maxLines: 2,
        size: isDesktop ? 14 : 12,
        variant: TextVariant.semiBold,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget buildCardBadgeV2(
      BuildContext context, DataVariant variant, ItemType type) {
    final theme = Theme.of(context);

    return Positioned(
      top: 6,
      left: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              getIconForVariant(itemData.extraData ?? '', variant, type),
              size: 15,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(width: 4),
            AnymexText(
              text: itemData.extraData ?? '',
              color: theme.colorScheme.onPrimary,
              size: 11,
              variant: TextVariant.bold,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCardBadge(
      BuildContext context, DataVariant variant, ItemType type) {
    final theme = Theme.of(context);

    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              getIconForVariant(itemData.extraData ?? '', variant, type),
              size: 16,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(width: 4),
            AnymexText(
              text: itemData.extraData ?? '',
              color: theme.colorScheme.onPrimary,
              size: 12,
              variant: TextVariant.bold,
            ),
          ],
        ),
      ),
    );
  }

  IconData getIconForVariant(
      String extraData, DataVariant variant, ItemType type) {
    switch (variant) {
      case DataVariant.anilist:
      case DataVariant.offline:
        return type == ItemType.manga ? Iconsax.book : Iconsax.play5;
      case DataVariant.library:
        return Iconsax.star5;
      case DataVariant.relation:
        if (extraData == "MANGA" || extraData == "ANIME") {
          return extraData == "MANGA" ? Iconsax.book : Iconsax.play5;
        }
        return type == ItemType.manga ? Iconsax.book5 : Iconsax.play5;
      case DataVariant.extension:
        return Iconsax.status;
      default:
        return Iconsax.star5;
    }
  }
}
