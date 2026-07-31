import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/cards/media_card_registry.dart';
import 'package:anymex/widgets/common/cards/media_cards.dart';
import 'package:anymex/widgets/common/dynamic_style_selector.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showCardStyleSwitcher(BuildContext context) {
  final selectedStyle = CardStyle.values[settingsController.cardStyle].obs;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Obx(
        () {
          return AnymexDialog(
            title: 'Card Style',
            onConfirm: () {
              settingsController.cardStyle = selectedStyle.value.index;
            },
            contentWidget: CardStyleSelector(
              onStyleChanged: (e) {
                selectedStyle.value = e;
              },
              initialStyle: selectedStyle.value,
              sampleData: convertData(trendingAnimes)[0],
            ),
          );
        },
      );
    },
  );
}

class CardStyleSelector extends StatelessWidget {
  final Function(CardStyle) onStyleChanged;
  final CardStyle initialStyle;
  final CarouselData sampleData;

  const CardStyleSelector({
    super.key,
    required this.onStyleChanged,
    required this.initialStyle,
    required this.sampleData,
  });

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width > 600;
    registerBuiltInMediaCardStyles();

    return DynamicStyleSelector<CardStyle>(
      values: CardStyle.values,
      selectedValue: initialStyle,
      getTitle: (style) => MediaCardRegistry.getByIndex(style.index).displayName,
      getDescription: (style) => MediaCardRegistry.getByIndex(style.index).description,
      buildPreview: (style) => SizedBox(
        height: getCardHeight(style, desktop),
        child: MediaCardGate(
          cardStyle: style,
          itemData: sampleData,
          tag: 'style-preview',
          variant: DataVariant.regular,
          type: ItemType.anime,
        ),
      ),
      onValueChanged: onStyleChanged,
    );
  }
}
