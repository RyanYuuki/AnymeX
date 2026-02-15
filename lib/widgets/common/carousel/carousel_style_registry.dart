import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/common/big_carousel_v2.dart';
import 'package:anymex/widgets/common/carousel/big_carousel_classic.dart';
import 'package:anymex/widgets/common/carousel/carousel_types.dart';
import 'package:flutter/widgets.dart';

typedef CarouselStyleWidgetBuilder = Widget Function({
  Key? key,
  required List<Media> data,
  required CarouselType carouselType,
});

class CarouselStyleDefinition {
  final String id;
  final String name;
  final String description;
  final CarouselStyleWidgetBuilder builder;

  const CarouselStyleDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.builder,
  });
}

class CarouselStyleRegistry {
  static const List<CarouselStyleDefinition> styles = [
    CarouselStyleDefinition(
      id: 'classic',
      name: 'Classic',
      description: 'Full-width hero banner with compact details and quick synopsis.',
      builder: _buildClassic,
    ),
    CarouselStyleDefinition(
      id: 'cinematic',
      name: 'Cinematic',
      description: 'Centered showcase cards with expanded visuals and smoother focus.',
      builder: _buildCinematic,
    ),
  ];

  static int normalizeIndex(int index) {
    if (styles.isEmpty) return 0;
    if (index < 0 || index >= styles.length) return 0;
    return index;
  }

  static CarouselStyleDefinition byIndex(int index) {
    return styles[normalizeIndex(index)];
  }

  static Widget build({
    Key? key,
    required int selectedIndex,
    required List<Media> data,
    required CarouselType carouselType,
  }) {
    final style = byIndex(selectedIndex);
    return style.builder(key: key, data: data, carouselType: carouselType);
  }

  static Widget _buildClassic({
    Key? key,
    required List<Media> data,
    required CarouselType carouselType,
  }) {
    return BigCarouselClassic(key: key, data: data, carouselType: carouselType);
  }

  static Widget _buildCinematic({
    Key? key,
    required List<Media> data,
    required CarouselType carouselType,
  }) {
    return BigCarouselV2(key: key, data: data, carouselType: carouselType);
  }
}
