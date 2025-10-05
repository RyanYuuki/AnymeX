import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/novel/details/details_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/animation/slide_scale.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/hover_wrapper.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class ReusableCarousel extends StatefulWidget {
  final List<dynamic> data;
  final String title;
  final ItemType type;
  final DataVariant variant;
  final bool isLoading;
  final Source? source;
  final CardStyle? cardStyle;

  const ReusableCarousel({
    super.key,
    required this.data,
    required this.title,
    this.type = ItemType.anime,
    this.variant = DataVariant.regular,
    this.isLoading = false,
    this.source,
    this.cardStyle,
  });

  @override
  State<ReusableCarousel> createState() => _ReusableCarouselState();
}

class _ReusableCarouselState extends State<ReusableCarousel> {
  @override
  Widget build(BuildContext context) {
    if (_isEmptyOrOffline) {
      return _buildOfflinePlaceholder();
    }

    if (widget.data.isEmpty && !widget.isLoading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderTitle(),
          const SizedBox(height: 10),
          widget.isLoading
              ? const Center(child: AnymexProgressIndicator())
              : _buildCarouselList(),
        ],
      ),
    );
  }

  // Computed properties
  bool get _isEmptyOrOffline =>
      widget.data.isEmpty && widget.variant == DataVariant.offline;

  // Header title section
  Widget _buildHeaderTitle() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: Text(
        widget.title,
        style: TextStyle(
          fontFamily: "Poppins-SemiBold",
          fontSize: 17,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // Offline placeholder display
  Widget _buildOfflinePlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildHeaderTitle(),
        const SizedBox(height: 15, width: double.infinity),
        SizedBox(
          height: 280,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(widget.type != ItemType.anime
                  ? Iconsax.book
                  : Icons.movie_filter_rounded),
              const SizedBox(height: 10, width: double.infinity),
              AnymexText(
                text: widget.type != ItemType.anime
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
  Widget _buildCarouselList() {
    final List<CarouselData> processedData =
        convertData(widget.data, variant: widget.variant);

    return Obx(() {
      return SizedBox(
        height: getCardHeight(CardStyle.values[settingsController.cardStyle],
            getPlatform(context)),
        child: SuperListView.builder(
          itemCount: processedData.length,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 15, top: 5, bottom: 10),
          itemBuilder: (context, index) =>
              _buildCarouselItem(processedData[index], index),
        ),
      );
    });
  }

  Widget _buildCarouselItem(CarouselData itemData, int index) {
    final tag = '${itemData.hashCode}-${itemData.id}';

    return Obx(() {
      final child = AnymexOnTap(
        onTap: () => _navigateToDetailsPage(itemData, tag),
        child: settingsController.enableAnimation
            ? SlideAndScaleAnimation(child: _buildCard(itemData, tag))
            : _buildCard(itemData, tag),
      );
      return child;
    });
  }

  MediaCardGate _buildCard(CarouselData itemData, String tag) {
    return MediaCardGate(
        itemData: itemData,
        tag: tag,
        variant: widget.variant,
        type: widget.type,
        cardStyle: CardStyle.values[settingsController.cardStyle]);
  }

  void _navigateToDetailsPage(CarouselData itemData, String tag) {
    final controller = Get.find<SourceController>();
    bool isMediaManga = _determineIfManga(itemData);
    if (widget.variant == DataVariant.recommendation) {
      isMediaManga = widget.type == ItemType.manga;
    }
    final ItemType mediaType = isMediaManga ? ItemType.manga : ItemType.anime;
    final media = Media.fromCarouselData(itemData, mediaType);

    final Widget page = isMediaManga
        ? MangaDetailsPage(
            media: media,
            tag: tag,
          )
        : widget.type == ItemType.anime
            ? AnimeDetailsPage(
                media: media,
                tag: tag,
              )
            : NovelDetailsPage(media: media, tag: tag, source: widget.source!);
    _setActiveSource(controller, itemData);
    navigate(() => page);
  }

  bool _determineIfManga(CarouselData itemData) {
    return (widget.variant == DataVariant.relation &&
            itemData.source == "MANGA") ||
        (widget.source?.itemType == ItemType.manga) ||
        widget.type == ItemType.manga;
  }

  void _setActiveSource(SourceController controller, CarouselData itemData) {
    if (widget.source != null) {
      controller.setActiveSource(widget.source!);
    } else if (itemData.source != null) {
      if (widget.type == ItemType.manga) {
        controller.getMangaExtensionByName(itemData.source!);
      } else {
        controller.getExtensionByName(itemData.source!);
      }
    }
  }
}
