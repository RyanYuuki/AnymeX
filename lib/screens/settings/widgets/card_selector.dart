import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/cards/media_card_registry.dart';
import 'package:anymex/widgets/common/cards/media_cards.dart';
import 'package:anymex/widgets/common/dynamic_style_selector.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showCardStyleSwitcher(BuildContext context) {
  registerBuiltInMediaCardStyles();
  final selectedIndex = settingsController.cardStyle.obs;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Obx(
        () {
          return AnymeXDialog(
            title: 'Card Style',
            onConfirm: () {
              settingsController.cardStyle = selectedIndex.value;
            },
            contentWidget: CardStyleSelector(
              onIndexChanged: (i) {
                selectedIndex.value = i;
              },
              initialIndex: selectedIndex.value,
              sampleData: convertData(trendingAnimes)[0],
            ),
          );
        },
      );
    },
  );
}

class CardStyleSelector extends StatelessWidget {
  final Function(int) onIndexChanged;
  final int initialIndex;
  final CarouselData sampleData;

  const CardStyleSelector({
    super.key,
    required this.onIndexChanged,
    required this.initialIndex,
    required this.sampleData,
  });

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width > 600;
    registerBuiltInMediaCardStyles();
    final styles = MediaCardRegistry.styles;

    return DynamicStyleSelector<int>(
      values: List.generate(styles.length, (i) => i),
      selectedValue: initialIndex,
      getTitle: (i) => styles[i].displayName,
      getDescription: (i) => styles[i].description,
      buildPreview: (i) => SizedBox(
        height: getCardHeight(i, desktop),
        child: MediaCardGate(
          cardStyleIndex: i,
          itemData: sampleData,
          tag: 'style-preview',
          variant: DataVariant.regular,
          type: ItemType.anime,
        ),
      ),
      onValueChanged: onIndexChanged,
    );
  }
}
