import 'package:anymex/utils/fallback/fallback_anime.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/common/carousel/carousel_style_registry.dart';
import 'package:anymex/widgets/common/carousel/carousel_types.dart';
import 'package:anymex/widgets/common/dynamic_style_selector.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showCarouselStyleSelector(BuildContext context) {
  final selectedIndex =
      CarouselStyleRegistry.normalizeIndex(settingsController.carouselStyle).obs;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Obx(
        () => AnymeXDialog(
          title: 'Carousel Style',
          onConfirm: () {
            settingsController.carouselStyle = selectedIndex.value;
          },
          contentWidget: CarouselStyleSelector(
            initialIndex: selectedIndex.value,
            onStyleChanged: (index) {
              selectedIndex.value = index;
            },
          ),
        ),
      );
    },
  );
}

class CarouselStyleSelector extends StatelessWidget {
  final int initialIndex;
  final ValueChanged<int> onStyleChanged;

  const CarouselStyleSelector({
    super.key,
    required this.initialIndex,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final initialStyle = CarouselStyleRegistry.styles[CarouselStyleRegistry.normalizeIndex(initialIndex)];

    return DynamicStyleSelector<CarouselStyleDefinition>(
      values: CarouselStyleRegistry.styles,
      selectedValue: initialStyle,
      getTitle: (style) => style.name,
      getDescription: (style) => style.description,
      buildPreview: (style) => IgnorePointer(
        child: style.builder(
          data: trendingAnimes,
          carouselType: CarouselType.anime,
        ),
      ),
      onValueChanged: (style) {
        final index = CarouselStyleRegistry.styles.indexOf(style);
        onStyleChanged(index);
      },
    );
  }
}
