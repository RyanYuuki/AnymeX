import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/novel/details/details_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/animation/slide_scale.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/media_items/media_peek_popup.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

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
              ? const Center(child: AnymeXProgressIndicator())
              : _buildCarouselList(),
        ],
      ),
    );
  }

  bool get _isEmptyOrOffline =>
      widget.data.isEmpty && widget.variant == DataVariant.offline;

  Widget _buildHeaderTitle() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: AnymeXText(
        text: widget.title,
        variant: TextVariant.semiBold,
        size: 17,
        color: context.colors.primary,
        isMarquee: true,
      ),
    );
  }

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
              AnymeXText(
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

  Widget _buildCarouselList() {
    return Obx(() {
      final List<CarouselData> processedData =
          convertData(widget.data, variant: widget.variant);
      final enableAnimation = settingsController.enableAnimation;
      final cardStyleIndex = settingsController.cardStyle;

      return SizedBox(
        height: getCardHeight(CardStyle.values[cardStyleIndex],
            getPlatform(context)),
        child: ListView.builder(
          key: ValueKey('${widget.title}-${processedData.length}-${widget.data.hashCode}'),
          itemCount: processedData.length,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 15, top: 5, bottom: 10),
          itemBuilder: (context, index) =>
              _buildCarouselItem(processedData[index], enableAnimation, cardStyleIndex, index),
        ),
      );
    });
  }

  Widget _buildCarouselItem(CarouselData itemData, bool enableAnimation, int cardStyleIndex, int index) {
    final tag = '${widget.title}-${itemData.id}-$index-${DateTime.now().microsecondsSinceEpoch}';

    final card = enableAnimation
        ? SlideAndScaleAnimation(child: _buildCard(itemData, tag, cardStyleIndex))
        : _buildCard(itemData, tag, cardStyleIndex);

    final child = AnymexOnTap(
      onTap: () => _navigateToDetailsPage(itemData, tag),
      child: GestureDetector(
        onLongPress: () => widget.type == ItemType.novel ? {} : _showPeekPopup(context, itemData, tag),
        child: card,
      ),
    );
    return child;
  }

  void _showPeekPopup(BuildContext context, CarouselData itemData, String tag) {
    final bool isMediaManga = _determineIfManga(itemData);
    final ItemType mediaType = isMediaManga ? ItemType.manga : ItemType.anime;
    final media = Media.fromCarouselData(itemData, mediaType);
    if (media.userStatus != null && media.userStatus!.isNotEmpty) return;
    MediaPeekPopup.show(context, media, mediaType, tag);
  }

  MediaCardGate _buildCard(CarouselData itemData, String tag, int cardStyleIndex) {
    return MediaCardGate(
        itemData: itemData,
        tag: tag,
        variant: widget.variant,
        type: widget.type,
        cardStyle: CardStyle.values[cardStyleIndex]);
  }

  void _navigateToDetailsPage(CarouselData itemData, String tag) {
    final controller = Get.find<SourceController>();
    bool isMediaManga = _determineIfManga(itemData);
    if (widget.variant == DataVariant.recommendation) {
      isMediaManga = widget.type == ItemType.manga;
    }
    final ItemType mediaType = isMediaManga ? ItemType.manga : ItemType.anime;
    final media = Media.fromCarouselData(itemData, mediaType);

    void onTapHandler() {
      if (mediaType == ItemType.novel || widget.type == ItemType.novel) {
        final source =
            widget.source ?? sourceController.installedNovelExtensions.first;
        navigateWithAnimation(() => NovelDetailsPage(
              media: media,
              tag: tag,
              source: source,
            ));
      } else if (mediaType == ItemType.manga) {
        navigateWithAnimation(() => MangaDetailsPage(
              media: media,
              tag: tag,
            ));
      } else {
        navigateWithAnimation(() => AnimeDetailsPage(
              media: media,
              tag: tag,
            ));
      }
    }

    _setActiveSource(controller, itemData);
    onTapHandler();
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
        controller.getExtensionByValue(itemData.source!);
      }
    }
  }
}
