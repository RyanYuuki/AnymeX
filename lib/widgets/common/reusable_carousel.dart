import 'dart:math' show Random;
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/core/Model/Source.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Carousel/carousel.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/animation/slide_scale.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class ReusableCarousel extends StatelessWidget {
  final List<dynamic> data;
  final String title;
  final bool isManga;
  final DataVariant variant;
  final bool isLoading;
  final Source? source;

  const ReusableCarousel({
    super.key,
    required this.data,
    required this.title,
    this.isManga = false,
    this.variant = DataVariant.regular,
    this.isLoading = false,
    this.source,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final newData = convertData(data, variant: variant);

    if (isEmptyOrOffline()) {
      return _buildOfflinePlaceholder(context);
    }

    if (data.isEmpty && !isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(context),
        const SizedBox(height: 15),
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildCarousel(context, newData, isDesktop),
      ],
    );
  }

  bool isEmptyOrOffline() => data.isEmpty && variant == DataVariant.offline;

  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: "Poppins-SemiBold",
          fontSize: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildOfflinePlaceholder(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildTitle(context),
        const SizedBox(
          height: 15,
          width: double.infinity,
        ),
        SizedBox(
          height: 280,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(isManga ? Iconsax.book : Icons.movie_filter_rounded),
              const SizedBox(
                height: 10,
                width: double.infinity,
              ),
              AnymexText(
                text: isManga
                    ? "For real, why aren’t you reading yet? 📚"
                    : "Lowkey time for a binge sesh 🎬",
                variant: TextVariant.semiBold,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarousel(
      BuildContext context, List<dynamic> newData, bool isDesktop) {
    final settings = Get.find<Settings>();
    return SizedBox(
      height: isDesktop ? 280 : 220,
      child: ListView.builder(
        itemCount: newData.length,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemBuilder: (BuildContext context, int index) {
          final itemData = newData[index];
          final tag = generateTag('${itemData.id}-$index');

          return Obx(() => InkWell(
              onTap: () => _navigateToDetailsPage(itemData, tag),
              child: settings.enableAnimation
                  ? SlideAndScaleAnimation(
                      initialScale: 0.0,
                      finalScale: 1.0,
                      initialOffset: const Offset(1.0, 0.0),
                      duration: Duration(milliseconds: getAnimationDuration()),
                      child:
                          _buildCarouselItem(context, itemData, tag, isDesktop),
                    )
                  : _buildCarouselItem(context, itemData, tag, isDesktop)));
        },
      ),
    );
  }

  Widget _buildCarouselItem(
      BuildContext context, CarouselData itemData, String tag, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.multiplyRoundness()),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(right: 10),
      constraints: BoxConstraints(maxWidth: isDesktop ? 150 : 105),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.multiplyRoundness()),
            child: Stack(
              children: [
                Hero(
                  tag: tag,
                  child: NetworkSizedImage(
                    imageUrl: itemData.poster!,
                    radius: 0,
                    height: isDesktop ? 210 : 160,
                    width: double.infinity,
                  ),
                ),
                _buildExtraData(context, itemData),
              ],
            ),
          ),
          if (itemData.title != null &&
              itemData.title!.isNotEmpty &&
              itemData.title != '?') ...[
            const SizedBox(height: 10),
            Text(
              itemData.title ?? '?',
              maxLines: 2,
              style: TextStyle(
                fontSize: isDesktop ? 14 : 12,
                fontFamily: "Poppins-SemiBold",
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToDetailsPage(CarouselData itemData, String tag) {
    final isMangaPage =
        (variant == DataVariant.relation && itemData.extraData == "MANGA") ||
            (source?.isManga ?? false) ||
            isManga;

    final page = isMangaPage
        ? MangaDetailsPage(
            key: ValueKey(itemData.id),
            media: Media.fromCarouselData(itemData, MediaType.manga),
            tag: tag,
          )
        : AnimeDetailsPage(
            media: Media.fromCarouselData(itemData, MediaType.anime),
            tag: tag,
          );

    if (source != null) {
      final controller = Get.find<SourceController>();
      controller.setActiveSource(source!);
    }

    Get.to(() => page, preventDuplicates: false);
  }

  Positioned _buildExtraData(BuildContext context, CarouselData itemData) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 4, 5, 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.multiplyRoundness()),
          ),
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              getIcon(variant, itemData.extraData ?? ''),
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 3),
            Text(
              itemData.extraData.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontFamily: "Poppins-Bold",
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData getIcon(DataVariant variant, String extraData) {
    switch (variant) {
      case DataVariant.anilist || DataVariant.offline:
        final icon = isManga ? Iconsax.book : Iconsax.play5;
        return icon;
      case DataVariant.relation:
        final icon = extraData == "MANGA" ? Iconsax.book : Iconsax.play5;
        return icon;
      case DataVariant.extension:
        return Iconsax.status;
      default:
        return Iconsax.star5;
    }
  }
}

String generateTag(String url) {
  final randomNum = Random().nextInt(10000);
  return '$url-$randomNum';
}
