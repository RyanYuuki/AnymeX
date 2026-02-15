import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/carousel/carousel_style_registry.dart';
import 'package:anymex/widgets/common/carousel/carousel_types.dart';
import 'package:anymex/widgets/custom_widgets/anymex_chip.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

void showCarouselStyleSelector(BuildContext context) {
  final selectedIndex =
      CarouselStyleRegistry.normalizeIndex(settingsController.carouselStyle).obs;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Obx(
        () => AnymexDialog(
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

class CarouselStyleSelector extends StatefulWidget {
  final int initialIndex;
  final ValueChanged<int> onStyleChanged;

  const CarouselStyleSelector({
    super.key,
    required this.initialIndex,
    required this.onStyleChanged,
  });

  @override
  State<CarouselStyleSelector> createState() => _CarouselStyleSelectorState();
}

class _CarouselStyleSelectorState extends State<CarouselStyleSelector> {
  late int _selectedIndex;

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
  void initState() {
    super.initState();
    _selectedIndex = CarouselStyleRegistry.normalizeIndex(widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    final style = CarouselStyleRegistry.byIndex(_selectedIndex);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 560),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 50,
            child: SuperListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(
                CarouselStyleRegistry.styles.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildStyleChip(index),
                ),
              ),
            ),
          ),
          10.height(),
          Text(
            style.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          12.height(),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: CarouselStyleRegistry.build(
                  selectedIndex: _selectedIndex,
                  data: _sampleData,
                  carouselType: CarouselType.anime,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleChip(int index) {
    final style = CarouselStyleRegistry.byIndex(index);
    final isSelected = index == _selectedIndex;

    return AnymexChip(
      isSelected: isSelected,
      label: style.name,
      onSelected: (selected) {
        if (!selected) return;
        setState(() {
          _selectedIndex = index;
        });
        widget.onStyleChanged(index);
      },
    );
  }
}
