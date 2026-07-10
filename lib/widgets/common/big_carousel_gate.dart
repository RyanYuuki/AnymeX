import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/common/carousel/carousel_style_registry.dart';
import 'package:anymex/widgets/common/carousel/carousel_types.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

export 'package:anymex/widgets/common/carousel/carousel_types.dart';

class BigCarousel extends StatelessWidget {
  final List<Media> data;
  final CarouselType carouselType;

  const BigCarousel({
    super.key,
    required this.data,
    this.carouselType = CarouselType.anime,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return CarouselStyleRegistry.build(
        key: key,
        selectedIndex: CarouselStyleRegistry.normalizeIndex(
            settingsController.carouselStyle),
        data: data,
        carouselType: carouselType,
      );
    });
  }
}
