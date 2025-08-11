import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/custom_widgets/anymex_chip.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

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
                  sampleData: convertData(trendingAnimes)[0]));
        },
      );
    },
  );
}

class CardStyleSelector extends StatefulWidget {
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
  State<CardStyleSelector> createState() => _CardStyleSelectorState();
}

class _CardStyleSelectorState extends State<CardStyleSelector> {
  late CardStyle _selectedStyle;
  final Map<CardStyle, String> styleDescriptions = {
    CardStyle.saikou:
        'A minimalist design focused on efficiency with less visual elements.',
    CardStyle.modern:
        'Clean, contemporary design with balanced proportions and subtle shadows.',
    CardStyle.exotic:
        'Traditional card layout with familiar elements and standard formatting.',
  };

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.initialStyle;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 50,
          child: SuperListView(
            scrollDirection: Axis.horizontal,
            children: CardStyle.values
                .map((style) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildStyleChip(style),
                    ))
                .toList(),
          ),
        ),
        10.height(),
        AnymexCard(
          enableAnimation: true,
          padding: const EdgeInsets.all(10),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: getCardHeight(_selectedStyle, getPlatform(context)),
              child: MediaCardGate(
                key: ValueKey(_selectedStyle),
                cardStyle: _selectedStyle,
                itemData: widget.sampleData,
                tag: '',
                variant: DataVariant.regular,
                type: ItemType.anime,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyleChip(CardStyle style) {
    final bool isSelected = style == _selectedStyle;

    return AnymexChip(
      isSelected: isSelected,
      label: style.name.capitalize!,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedStyle = style;
          });
          widget.onStyleChanged(style);
        }
      },
    );
  }
}
