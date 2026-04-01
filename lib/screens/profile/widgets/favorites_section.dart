import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/anime/studio_details_page.dart';
import 'package:anymex/screens/anime/widgets/character_staff_sheet.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/profile/widgets/stats_overview_cards.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/marquee_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class FavoritesSection extends StatelessWidget {
  final Profile user;
  final bool needsPadding;

  const FavoritesSection({
    super.key,
    required this.user,
    this.needsPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user.favourites?.anime.isNotEmpty ?? false) ...[
          const SizedBox(height: 20),
          Padding(
            padding: needsPadding
                ? const EdgeInsets.symmetric(horizontal: 20.0)
                : EdgeInsets.zero,
            child: const SectionHeader(
              title: 'Favourite Anime',
              icon: IconlyBold.video,
            ),
          ),
          const SizedBox(height: 10),
          _buildMediaFavCarousel(context, user.favourites!.anime, true),
        ],
        if (user.favourites?.manga.isNotEmpty ?? false) ...[
          const SizedBox(height: 10),
          Padding(
            padding: needsPadding
                ? const EdgeInsets.symmetric(horizontal: 20.0)
                : EdgeInsets.zero,
            child: const SectionHeader(
              title: 'Favourite Manga',
              icon: IconlyBold.document,
            ),
          ),
          const SizedBox(height: 10),
          _buildMediaFavCarousel(context, user.favourites!.manga, false),
        ],
        if (user.favourites?.characters.isNotEmpty ?? false) ...[
          const SizedBox(height: 10),
          Padding(
            padding: needsPadding
                ? const EdgeInsets.symmetric(horizontal: 20.0)
                : EdgeInsets.zero,
            child: const SectionHeader(
              title: 'Favourite Characters',
              icon: IconlyBold.profile,
            ),
          ),
          const SizedBox(height: 10),
          _buildPersonCarousel(
              context,
              <PersonItem>[
                for (final c in user.favourites!.characters)
                  PersonItem(id: c.id, name: c.name, image: c.image),
              ],
              true),
        ],
        if (user.favourites?.staff.isNotEmpty ?? false) ...[
          const SizedBox(height: 10),
          Padding(
            padding: needsPadding
                ? const EdgeInsets.symmetric(horizontal: 20.0)
                : EdgeInsets.zero,
            child: const SectionHeader(
              title: 'Favourite Staff',
              icon: Icons.people_rounded,
            ),
          ),
          const SizedBox(height: 10),
          _buildPersonCarousel(
              context,
              <PersonItem>[
                for (final s in user.favourites!.staff)
                  PersonItem(id: s.id, name: s.name, image: s.image),
              ],
              false),
        ],
        if (user.favourites?.studios.isNotEmpty ?? false) ...[
          const SizedBox(height: 10),
          Padding(
            padding: needsPadding
                ? const EdgeInsets.symmetric(horizontal: 20.0)
                : EdgeInsets.zero,
            child: const SectionHeader(
              title: 'Favourite Studios',
              icon: Icons.business_rounded,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: needsPadding
                ? const EdgeInsets.symmetric(horizontal: 20.0)
                : EdgeInsets.zero,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.favourites!.studios
                  .map(
                    (studio) => GestureDetector(
                      onTap: () {
                        if (studio.id != null) {
                          showStudioDetailsSheet(
                            context,
                            int.parse(studio.id!),
                            studio.name ?? '',
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: context.theme.colorScheme.outlineVariant
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          studio.name ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
            // Find the count from the fetched statuses, default to 0

  Widget _buildMediaFavCarousel(
    BuildContext context,
    List<FavouriteMedia> items,
    bool isAnime,
  ) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildMediaCard(context, item, isAnime);
        },
      ),
    );
  }

  Widget _buildMediaCard(
    BuildContext context,
    FavouriteMedia item,
    bool isAnime,
  ) {
    return GestureDetector(
      onTap: () {
        if (item.id != null) {
          final media = Media(
            id: item.id!,
            title: item.title ?? '?',
            poster: item.cover ?? '',
            serviceType: ServicesType.anilist,
          );
          final tag = item.title ?? 'fav-${item.id}';
          if (isAnime) {
            navigate(() => AnimeDetailsPage(media: media, tag: tag));
          } else {
            navigate(() => MangaDetailsPage(media: media, tag: tag));
          }
        }
      },
      child: Container(
        width: 112,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: item.title ?? 'fav-${item.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.cover != null
                    ? CachedNetworkImage(
                        imageUrl: item.cover!,
                        width: 112,
                        height: 150,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 112,
                          height: 150,
                          color: context.theme.colorScheme.surfaceContainer,
                        ),
                      )
                    : Container(
                        width: 112,
                        height: 150,
                        color: context.theme.colorScheme.surfaceContainer,
                      ),
              ),
            ),
            const SizedBox(height: 5),
            MarqueeText(
              item.title ?? '',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: context.theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonCarousel(
    BuildContext context,
    List<PersonItem> items,
    bool isCharacter,
  ) {
    return SizedBox(
      height: 128,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildPersonCard(
            context,
            item.id,
            item.image,
            item.name,
            isCharacter,
          );
        },
      ),
    );
  }

  Widget _buildPersonCard(
    BuildContext context,
    String? id,
    String? imageUrl,
    String? name,
    bool isCharacter,
  ) {
    final tag = 'profile_fav_${isCharacter ? "char" : "staff"}_$id';
    return Container(
      width: 78,
      margin: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          if (id != null) {
            showCharacterStaffSheet(
              context,
              item: PersonItem(id: id, name: name, image: imageUrl),
              isCharacter: isCharacter,
              heroTag: tag,
            );
          }
        },
        child: Column(
          children: [
            Hero(
              tag: tag,
              child: ClipOval(
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.theme.colorScheme.surfaceContainer,
                          ),
                          child: const Icon(Icons.person),
                        ),
                      )
                    : Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.theme.colorScheme.surfaceContainer,
                        ),
                        child: const Icon(Icons.person),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            MarqueeText(
              name ?? '',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: context.theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class PersonItem {
  final String? id;
  final String? name;
  final String? image;
  const PersonItem({this.id, this.name, this.image});
}
