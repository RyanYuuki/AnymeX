import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/community_service.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/models_convertor/carousel_mapper.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/community/user_recommendations_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/other/media_see_all_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/big_carousel.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/future_reusable_carousel.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/media_items/media_peek_popup.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget buildSection(String title, dynamic data,
    {DataVariant variant = DataVariant.regular,
    bool isLoading = false,
    ItemType type = ItemType.anime,
    Source? source}) {
  if (data is Stream) {
    return StreamBuilder(
      stream: data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildLoader(title);
        }
        return ReusableCarousel(
          data: snapshot.data ?? [],
          title: title,
          type: type,
          variant: variant,
          isLoading: isLoading,
          source: source,
        );
      },
    );
  }
  return ReusableCarousel(
    data: data,
    title: title,
    type: type,
    variant: variant,
    isLoading: isLoading,
    source: source,
  );
}

Widget buildUnderratedSection(String title, List<CommunityMedia> data,
    {ItemType type = ItemType.anime, VoidCallback? onSeeAll}) {
  if (data.isEmpty) return const SizedBox.shrink();
  return _UnderratedCarousel(
    title: title,
    data: data,
    type: type,
    onSeeAll: onSeeAll,
  );
}

Widget buildLoader(String title) {
  return ReusableCarousel(
    data: const [],
    title: title,
    isLoading: true,
  );
}

Container buildChip(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
    decoration: BoxDecoration(
      color: Get.theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(10),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: AnymexText(
        text: label,
        variant: TextVariant.bold,
        color: Get.theme.colorScheme.onPrimary,
        size: 14,
      ),
    ),
  );
}

Widget buildBigCarousel(List<Media> data, bool isManga, {CarouselType? type}) {
  return BigCarousel(
      data: data,
      carouselType:
          type ?? (isManga ? CarouselType.manga : CarouselType.anime));
}

Widget buildMangaSection(String title, List<Media> data,
    {bool isAnilist = false}) {
  return ReusableCarousel(
    data: data,
    title: title,
    type: ItemType.manga,
    variant: isAnilist ? DataVariant.anilist : DataVariant.regular,
  );
}

Widget buildUnderratedMangaSection(String title, List<CommunityMedia> data,
    {VoidCallback? onSeeAll}) {
  if (data.isEmpty) return const SizedBox.shrink();
  return _UnderratedCarousel(
    title: title,
    data: data,
    type: ItemType.manga,
    onSeeAll: onSeeAll,
  );
}

Widget buildMediaSectionWithSeeAll(String title, RxList<Media> data, ItemType type,
    {VoidCallback? onSeeAll, VoidCallback? onRefresh, DataVariant variant = DataVariant.regular}) {
  if (data.isEmpty) return const SizedBox.shrink();
  return _MediaSectionWithSeeAll(
    title: title,
    data: data,
    type: type,
    onSeeAll: onSeeAll,
    onRefresh: onRefresh,
    variant: variant,
  );
}

Widget buildFutureSection(
  String title,
  Future<List<dynamic>> future, {
  DataVariant variant = DataVariant.regular,
  ItemType type = ItemType.anime,
  Source? source,
  Widget? errorWidget,
  Widget? emptyWidget,
}) {
  return FutureReusableCarousel(
    future: future,
    title: title,
    variant: variant,
    type: type,
    source: source,
    errorWidget: errorWidget,
    emptyWidget: emptyWidget,
  );
}

class _MediaSectionWithSeeAll extends StatelessWidget {
  final String title;
  final RxList<Media> data;
  final ItemType type;
  final VoidCallback? onSeeAll;
  final VoidCallback? onRefresh;
  final DataVariant variant;

  const _MediaSectionWithSeeAll({
    required this.title,
    required this.data,
    required this.type,
    this.onSeeAll,
    this.onRefresh,
    this.variant = DataVariant.regular,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardHeight = getCardHeight(
        CardStyle.values[settingsController.cardStyle], getPlatform(context));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: "Poppins-SemiBold",
                    fontSize: 17,
                    color: theme.colorScheme.primary,
                  ),
                ),
                GestureDetector(
                  onTap: onSeeAll ?? () => navigate(() => MediaSeeAllPage(
                    title: title,
                    dataList: [],
                    mediaList: data,
                    type: type,
                    variant: variant,
                    onRefresh: onRefresh,
                  )),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          fontFamily: "Poppins-SemiBold",
                          fontSize: 13,
                          color: theme.colorScheme.primary.withOpacity(0.7),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: theme.colorScheme.primary.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 15, top: 5, bottom: 10),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final media = data[index];
                final carouselData = media.toCarouselData(
                    isManga: type == ItemType.manga);
                final tag = 'ms-${carouselData.id}-${media.hashCode}';

                return GestureDetector(
                  onTap: () {
                    final detailTag = 'ms-${media.id}';
                    if (type == ItemType.manga) {
                      navigate(() => MangaDetailsPage(media: media, tag: detailTag));
                    } else {
                      navigate(() => AnimeDetailsPage(media: media, tag: detailTag));
                    }
                  },
                  onLongPress: () {
                    MediaPeekPopup.show(context, media, type, 'ms-${media.id}');
                  },
                  child: SizedBox(
                    width: getPlatform(context) ? 160.0 : 118.0,
                    child: MediaCardGate(
                      itemData: carouselData,
                      tag: tag,
                      variant: DataVariant.regular,
                      cardStyle: CardStyle.values[settingsController.cardStyle],
                      type: type,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UnderratedCarousel extends StatelessWidget {
  final String title;
  final List<CommunityMedia> data;
  final ItemType type;
  final VoidCallback? onSeeAll;

  const _UnderratedCarousel({
    required this.title,
    required this.data,
    required this.type,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardHeight = getCardHeight(
        CardStyle.values[settingsController.cardStyle], getPlatform(context));

    if (data.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: "Poppins-SemiBold",
                    fontSize: 17,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (onSeeAll != null)
                  GestureDetector(
                    onTap: onSeeAll,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See All',
                          style: TextStyle(
                            fontFamily: "Poppins-SemiBold",
                            fontSize: 13,
                            color: theme.colorScheme.primary.withOpacity(0.7),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: theme.colorScheme.primary.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 15, top: 5, bottom: 10),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return _UnderratedCard(
                  item: item,
                  type: type,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UnderratedCard extends StatelessWidget {
  final CommunityMedia item;
  final ItemType type;

  const _UnderratedCard({
    required this.item,
    required this.type,
  });

  String get _mediaType {
    final id = item.media.id;
    if (id.endsWith('*MOVIE')) return 'movie';
    if (id.endsWith('*SERIES')) return 'show';
    return type == ItemType.manga ? 'manga' : 'anime';
  }

  String get _mediaId {
    final id = item.media.id;
    if (id.contains('*')) return id.split('*').first;
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final cardWidth = isDesktop ? 160.0 : 118.0;
    final carouselData = item.toCarouselData(isManga: type == ItemType.manga);
    final tag = 'underrated-${carouselData.id}-${item.media.hashCode}';

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      onLongPress: () => _showPeekPopup(context),
      child: SizedBox(
        width: cardWidth,
        child: Stack(
          children: [
            MediaCardGate(
              itemData: carouselData,
              tag: tag,
              variant: DataVariant.underrated,
              cardStyle: CardStyle.values[settingsController.cardStyle],
              type: type,
            ),
            if (item.author != null && item.author!.isNotEmpty)
              Positioned(
                top: 6,
                left: 6,
                child: _buildAuthorBadge(context, theme),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorBadge(BuildContext context, ThemeData theme) {
    final serviceHandler = Get.find<ServiceHandler>();
    final serviceType = serviceHandler.serviceType.value;
    final isAnilist = serviceType == ServicesType.anilist;
    final author = item.usernameFor(serviceType);
    final avatarUrl = item.avatarFor(serviceType);
    final hasAuthor = author != null && author.isNotEmpty;
    final isAdmin = item.isFirstReasonAdmin;

    final badge = Container(
      constraints: BoxConstraints(maxWidth: isAdmin ? 115 : 100),
      padding: const EdgeInsets.only(
        left: 3,
        right: 10,
        top: 3,
        bottom: 3,
      ),
      margin: const EdgeInsets.only(left: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.85),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: _AuthorAvatar(
              avatarUrl: avatarUrl,
              fallbackLabel: author,
              size: 24,
            ),
          ),
          const SizedBox(width: 3),
          Flexible(
            child: AutoSizeText(
              author ?? 'Unknown',
              maxLines: 1,
              minFontSize: 6,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'Poppins-SemiBold',
                color: theme.colorScheme.onSecondaryContainer,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Icon(Icons.verified_rounded,
                  size: 11, color: theme.colorScheme.onSecondaryContainer),
            ),
        ],
      ),
    );

    if (!hasAuthor) return badge;

    final hasValidProfile = item.firstReason?.user != null;

    return GestureDetector(
      onTap: () => _navigateToAuthorProfile(context, isAnilist),
      onLongPress: hasValidProfile ? _navigateToUserRecs : null,
      behavior: HitTestBehavior.opaque,
      child: badge,
    );
  }

  Future<void> _navigateToAuthorProfile(
      BuildContext context, bool isAnilist) async {
    navigateToAuthorProfile(item);
  }

  void _navigateToUserRecs() {
    final user = item.firstReason?.user;
    if (user != null) {
      navigate(() => UserRecommendationsPage(user: user));
    }
  }

  void _showPeekPopup(BuildContext context) {
    final serviceType = Get.find<ServiceHandler>().serviceType.value;
    MediaPeekPopup.show(
      context,
      item.media,
      type,
      'underrated-${item.media.id}',
      author: item.usernameFor(serviceType),
      avatarUrl: item.avatarFor(serviceType),
      reason: item.reason,
      anilistUserId: item.anilistUserId,
      malUserId: item.malUserId,
      anilistUsername: item.anilistUsername,
      malUsername: item.malUsername,
      simklUserId: item.simklUserId,
      simklUsername: item.simklUsername,
      voteMediaType: _mediaType,
      voteMediaId: _mediaId,
      reasons: item.reasons,
      rawJson: item.rawJson,
    );
  }

  void _navigateToDetails(BuildContext context) {
    final media = item.media;
    final tag = 'underrated-${media.id}';
    if (type == ItemType.manga) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MangaDetailsPage(media: media, tag: tag),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimeDetailsPage(media: media, tag: tag),
        ),
      );
    }
  }
}

class _AuthorAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? fallbackLabel;
  final double size;

  const _AuthorAvatar({
    required this.avatarUrl,
    required this.fallbackLabel,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? AnymeXImage(
              imageUrl: avatarUrl!,
              width: size,
              height: size,
              radius: size / 2,
            )
          : Center(
              child: Text(
                (fallbackLabel?.trim().isNotEmpty == true
                        ? fallbackLabel!.trim()[0]
                        : '?')
                    .toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.52,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
    );
  }
}
