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
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// This will be your future enum for different card styles
// enum CardStyle { compact, expanded, grid, list }

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
    if (isEmptyOrOffline()) {
      return _buildOfflinePlaceholder(context);
    }

    if (data.isEmpty && !isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderTitle(context),
        const SizedBox(height: 10),
        isLoading
            ? const Center(child: AnymexProgressIndicator())
            : _buildCarouselList(context),
      ],
    );
  }

  // Simple utility methods
  bool isEmptyOrOffline() => data.isEmpty && variant == DataVariant.offline;

  bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 600;

  // Header title section
  Widget _buildHeaderTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: "Poppins-SemiBold",
          fontSize: 17,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // Offline placeholder display
  Widget _buildOfflinePlaceholder(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildHeaderTitle(context),
        const SizedBox(height: 15, width: double.infinity),
        SizedBox(
          height: 280,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(isManga ? Iconsax.book : Icons.movie_filter_rounded),
              const SizedBox(height: 10, width: double.infinity),
              AnymexText(
                text: isManga
                    ? "For real, why aren't you reading yet? 📚"
                    : "Lowkey time for a binge sesh 🎬",
                variant: TextVariant.semiBold,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Main carousel list builder
  Widget _buildCarouselList(BuildContext context) {
    final bool desktop = isDesktop(context);
    final List<dynamic> processedData = convertData(data, variant: variant);
    final Settings settings = Get.find<Settings>();

    return SizedBox(
      height: desktop ? 290 : 230,
      child: ListView.builder(
        itemCount: processedData.length,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 15, top: 5, bottom: 10),
        itemBuilder: (context, index) => _buildCarouselItemWrapper(
            context, processedData[index], index, desktop, settings),
      ),
    );
  }

  Widget _buildCarouselItemWrapper(BuildContext context, CarouselData itemData,
      int index, bool desktop, Settings settings) {
    final String tag = generateTag('${itemData.id}-$index');

    return Obx(() => TVWrapper(
          onTap: () => _navigateToDetailsPage(itemData, tag),
          child: settings.enableAnimation
              ? SlideAndScaleAnimation(
                  child: _buildCarouselCard(context, itemData, tag, desktop))
              : _buildCarouselCard(context, itemData, tag, desktop),
        ));
  }

  Widget _buildCarouselCard(
      BuildContext context, CarouselData itemData, String tag, bool desktop) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      constraints: BoxConstraints(maxWidth: desktop ? 150 : 108),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardImage(context, itemData, tag, desktop),
          if (_shouldShowTitle(itemData)) ...[
            const SizedBox(height: 10),
            _buildCardTitle(itemData, desktop),
          ],
        ],
      ),
    );
  }

  Widget _buildCardImage(
      BuildContext context, CarouselData itemData, String tag, bool desktop) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.multiplyRoundness()),
      child: Stack(
        children: [
          Hero(
            tag: tag,
            child: NetworkSizedImage(
              imageUrl: itemData.poster!,
              radius: 12,
              height: desktop ? 210 : 160,
              width: double.infinity,
            ),
          ),
          _buildCardBadge(context, itemData),
        ],
      ),
    );
  }

  // Badge overlay for showing extra data
  Widget _buildCardBadge(BuildContext context, CarouselData itemData) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForVariant(itemData.extraData ?? ''),
              size: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 4),
            AnymexText(
              text: itemData.extraData ?? '',
              color: Theme.of(context).colorScheme.onPrimary,
              size: 12,
              variant: TextVariant.bold,
            ),
          ],
        ),
      ),
    );
  }

  // Card title text widget
  Widget _buildCardTitle(CarouselData itemData, bool desktop) {
    return AnymexText(
      text: itemData.title ?? '?',
      maxLines: 2,
      size: desktop ? 14 : 12,
      variant: TextVariant.semiBold,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _navigateToDetailsPage(CarouselData itemData, String tag) {
    final controller = Get.find<SourceController>();
    final bool isMediaManga = _determineIfManga(itemData);

    final MediaType mediaType =
        isMediaManga ? MediaType.manga : MediaType.anime;

    // Create appropriate page
    final Widget page = isMediaManga
        ? MangaDetailsPage(
            media: Media.fromCarouselData(itemData, mediaType),
            tag: tag,
          )
        : AnimeDetailsPage(
            media: Media.fromCarouselData(itemData, mediaType),
            tag: tag,
          );

    _setActiveSource(controller, itemData);

    navigate(() => page);
  }

  bool _determineIfManga(CarouselData itemData) {
    return (variant == DataVariant.relation && itemData.extraData == "MANGA") ||
        (source?.isManga ?? false) ||
        isManga;
  }

  void _setActiveSource(SourceController controller, CarouselData itemData) {
    if (source != null) {
      controller.setActiveSource(source!);
    } else if (itemData.source != null) {
      if (isManga) {
        controller.getMangaExtensionByName(itemData.source!);
      } else {
        controller.getExtensionByName(itemData.source!);
      }
    }
  }

  bool _shouldShowTitle(CarouselData itemData) {
    return itemData.title != null &&
        itemData.title!.isNotEmpty &&
        itemData.title != '?';
  }

  IconData _getIconForVariant(String extraData) {
    switch (variant) {
      case DataVariant.anilist:
      case DataVariant.offline:
        return isManga ? Iconsax.book : Iconsax.play5;
      case DataVariant.relation:
        return extraData == "MANGA" ? Iconsax.book : Iconsax.play5;
      case DataVariant.extension:
        return Iconsax.status;
      default:
        return Iconsax.star5;
    }
  }
}

// Utility function for tag generation
String generateTag(String url) {
  final randomNum = Random().nextInt(10000);
  return '$url-$randomNum';
}
