import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Media/media.dart';
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

  static final List<Media> _sampleData = [
    Media(
      id: '100',
      title: 'Solo Leveling',
      description:
          'A weak hunter rises through a mysterious system and becomes unstoppable.',
      poster:
          'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx151807-OCYov5Nw2g6M.jpg',
      cover:
          'https://s4.anilist.co/file/anilistcdn/media/anime/banner/151807-WQfQY3R7wQvJ.jpg',
      rating: '8.7',
      genres: const ['Action', 'Fantasy'],
      serviceType: ServicesType.anilist,
      aired: '2024',
    ),
    Media(
      id: '101',
      title: 'Frieren: Beyond Journey\'s End',
      description:
          'After the hero\'s journey ends, an elf mage learns what time means to humans.',
      poster:
          'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx154587-pmCnjx6QxK4U.jpg',
      cover:
          'https://s4.anilist.co/file/anilistcdn/media/anime/banner/154587-5F6P3K2f2eKw.jpg',
      rating: '9.2',
      genres: const ['Adventure', 'Drama'],
      serviceType: ServicesType.anilist,
      aired: '2023',
    ),
    Media(
      id: '102',
      title: 'Dandadan',
      description:
          'Two teens with opposite beliefs get pulled into chaotic supernatural battles.',
      poster:
          'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx171018-7R0f0jwuYQ1E.jpg',
      cover:
          'https://s4.anilist.co/file/anilistcdn/media/anime/banner/171018-2hS90sQfTaLr.jpg',
      rating: '8.5',
      genres: const ['Supernatural', 'Comedy'],
      serviceType: ServicesType.anilist,
      aired: '2024',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final initialStyle = CarouselStyleRegistry.styles[CarouselStyleRegistry.normalizeIndex(initialIndex)];

    return DynamicStyleSelector<CarouselStyleDefinition>(
      values: CarouselStyleRegistry.styles,
      selectedValue: initialStyle,
      getTitle: (style) => style.name,
      getDescription: (style) => style.description,
      buildPreview: (style) => style.builder(
        data: _sampleData,
        carouselType: CarouselType.anime,
      ),
      onValueChanged: (style) {
        final index = CarouselStyleRegistry.styles.indexOf(style);
        onStyleChanged(index);
      },
    );
  }
}
