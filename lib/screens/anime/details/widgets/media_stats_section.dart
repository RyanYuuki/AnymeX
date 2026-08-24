import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/mangaupdates/anime_adaptation.dart';
import 'package:anymex/models/mangaupdates/next_release.dart';
import 'package:anymex/models/mangaupdates/news_item.dart';
import 'package:anymex/screens/anime/details/controller/media_details_controller.dart';
import 'package:anymex/screens/anime/details/media_details_page.dart';
import 'package:anymex/screens/anime/themes/anime_theme_view.dart';
import 'package:anymex/screens/anime/widgets/watch_order_page.dart';
import 'package:anymex/screens/anime/widgets/social_section.dart';
import 'package:anymex/screens/news/news_page.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/utils/anime_adaptation_util.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image_button.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_linear_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget buildMediaStatsSection(
    BuildContext context, MediaDetailsController controller) {
  final media = controller.media.value;
  final colors = context.colors;
  final rawDesc = media.description;
  final cleanDesc = _cleanHtml(rawDesc);

  final List<Widget> sections = [
    buildProgressContainer(context, controller),
    if (controller.isAnime && media.nextAiringEpisode != null)
      buildAiringCountdownCard(context, controller),
    if (cleanDesc.isNotEmpty)
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest
              .opaque(0.3, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AnymeXText('Synopsis',
              size: 15,
              variant: TextVariant.bold,
              isMarquee: true,
            ),
            const SizedBox(height: 8),
            AnymeXText(cleanDesc,
              size: 13,
              maxLines: 9999,
              overflow: TextOverflow.ellipsis,
              isMarquee: false,
            ),
          ],
        ),
      ),
    buildStatsGrid(context, media),
    buildAlternativeTitles(context, media),
    if (media.genres.isNotEmpty)
      _buildSection(
          'Genres',
          [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: media.genres
                  .map((genre) => buildGenreChip(context, genre))
                  .toList(),
            )
          ],
          colors),
    if (media.tags.isNotEmpty)
      _buildSection(
          'Tags',
          [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: media.tags
                  .map((tag) => buildTagChip(context, tag))
                  .toList(),
            ),
          ],
          colors),
    if (media.friendsWatching != null &&
        media.friendsWatching!.isNotEmpty)
      SocialSection(
        friends: media.friendsWatching!,
        totalEpisodes: media.totalEpisodes.isNotEmpty
            ? media.totalEpisodes
            : media.totalChapters,
      ),
    buildSeasonsSection(context, media),
    if (controller.isAnime)
      buildExtrasSection(context, media),
  ];

  final List<Widget> visibleSections = [];
  for (final section in sections) {
    if (section is SizedBox &&
        section.child == null &&
        section.width == 0 &&
        section.height == 0) {
      continue;
    }
    visibleSections.add(section);
  }

  final List<Widget> childrenWithSpacers = [];
  for (int i = 0; i < visibleSections.length; i++) {
    childrenWithSpacers.add(visibleSections[i]);
    if (i < visibleSections.length - 1) {
      childrenWithSpacers.add(const SizedBox(height: 12));
    }
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: childrenWithSpacers,
    ),
  );
}

Widget buildAlternativeTitles(BuildContext context, Media media) {
  final colors = context.colors;
  final titles = [
    if (media.title.isNotEmpty) MapEntry('Main Title', media.title),
    if (media.romajiTitle.isNotEmpty && media.romajiTitle != '?')
      MapEntry('Romaji', media.romajiTitle),
    if (media.synonyms.isNotEmpty)
      MapEntry('Synonyms', media.synonyms.join(', ')),
  ];
  if (titles.isEmpty) return const SizedBox.shrink();
  return _buildSection(
      'Alternative Titles',
      titles
          .map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: AnymeXText(entry.key,
                        size: 12,
                        color:
                            colors.onSurface.opaque(0.5, iReallyMeanIt: true),
                      ),
                    ),
                    Expanded(
                      child: AnymeXText(entry.value,
                        size: 12,
                        variant: TextVariant.semiBold,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
      colors);
}

Widget _buildSection(String title, List<Widget> children, ColorScheme colors) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: colors.surfaceContainerHighest.opaque(0.3, iReallyMeanIt: true),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnymeXText(title,
          size: 14,
          variant: TextVariant.bold,
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}

Widget buildSeasonsSection(BuildContext context, Media mediaData) {
  final prequels = mediaData.relations?.where((element) => element.relationType == 'PREQUEL').toList() ?? [];
  final sequels = mediaData.relations?.where((element) => element.relationType == 'SEQUEL').toList() ?? [];
  final filteredRelations = [
    if (prequels.isNotEmpty) prequels.first,
    if (sequels.isNotEmpty) sequels.first,
  ];

  if (filteredRelations.isEmpty) return const SizedBox.shrink();

  final colors = context.colors;

  return _buildSection(
      'Seasons',
      [
        Row(
          children: filteredRelations.map((relation) {
            final isMangaRelation = relation.type == 'MANGA';
            final media = Media(
              id: relation.id.toString(),
              title: relation.title,
              poster: relation.poster,
              cover: relation.cover,
              type: relation.type,
              mediaType: isMangaRelation ? ItemType.manga : ItemType.anime,
              serviceType: ServicesType.anilist,
            );

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ImageButton(
                  buttonText: relation.relationType,
                  backgroundImage: relation.cover.isNotEmpty ? relation.cover : relation.poster,
                  width: double.infinity,
                  height: 70,
                  borderRadius: 12,
                  onPressed: () {
                    navigate(() => MediaDetailsPage(
                          media: media,
                          tag: relation.id.toString(),
                        ));
                  },
                  imageProportion: 0.5,
                ),
              ),
            );
          }).toList(),
        )
      ],
      colors);
}

Widget buildExtrasSection(BuildContext context, Media mediaData) {
  final isAnime = mediaData.mediaType == ItemType.anime;

  return _buildSection(
      "Extras",
      [
        AnymeXSectionBuilder(
          margin: EdgeInsets.zero,
          children: [
            if (isAnime) ...[
              AnymeXTile(
                icon: Icons.music_note_rounded,
                title: "Openings & Endings",
                subtitle: "View opening and ending themes",
                onTap: () {
                  navigate(
                      () => AnimeThemePlayerPage(animeDetails: mediaData));
                },
              ),
              AnymeXTile(
                icon: Icons.playlist_play_rounded,
                title: "Watch Order",
                subtitle: "View the chronological watch order of this anime",
                onTap: () {
                  navigate(() => WatchOrderPage(title: mediaData.title));
                },
              ),
              FutureBuilder<List<NewsItem>>(
                future: MangaAnimeUtil.getAnimeNews(mediaData),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return AnymeXTile(
                    icon: Icons.newspaper_rounded,
                    title: "Recent News",
                    subtitle: "Read latest updates about this anime",
                    onTap: () {
                      navigate(() =>
                          NewsPage(media: mediaData, news: snapshot.data!));
                    },
                  );
                },
              ),
            ] else ...[
              FutureBuilder<List<NewsItem>>(
                future: MangaAnimeUtil.getMangaNovelNews(mediaData),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return AnymeXTile(
                    icon: Icons.newspaper_rounded,
                    title: "Recent News",
                    subtitle: "Read latest updates about this manga",
                    onTap: () {
                      navigate(() =>
                          NewsPage(media: mediaData, news: snapshot.data!));
                    },
                  );
                },
              ),
              FutureBuilder<AnimeAdaptation>(
                future: MangaAnimeUtil.getAnimeAdaptation(mediaData),
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.error != null ||
                      !snapshot.data!.hasAdaptation) {
                    return const SizedBox.shrink();
                  }
                  final start = snapshot.data!.animeStart ?? 'Unknown';
                  final end = snapshot.data!.animeEnd ?? 'Unknown';
                  return AnymeXTile(
                    icon: Icons.tv_rounded,
                    title: "Anime Adaptation",
                    subtitle: "Adapted from Chapter $start to $end",
                    onTap: () {},
                    showChevron: false,
                  );
                },
              ),
              FutureBuilder<NextRelease>(
                future: MangaAnimeUtil.getNextChapterPrediction(mediaData),
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.error != null ||
                      snapshot.data!.nextChapter == null) {
                    return const SizedBox.shrink();
                  }
                  final nextCh = snapshot.data!.nextChapter!;
                  final releaseDate = snapshot.data!.nextReleaseDate != null
                      ? snapshot.data!.nextReleaseDate!
                          .toString()
                          .split(' ')
                          .first
                      : 'Unknown';
                  return AnymeXTile(
                    icon: Icons.calendar_month_rounded,
                    title: "Next Release Prediction",
                    subtitle: "$nextCh predicted on $releaseDate",
                    onTap: () {},
                    showChevron: false,
                  );
                },
              ),
            ],
          ],
        )
      ],
      context.colors);
}

String _cleanHtml(String? text) {
  if (text == null || text.isEmpty) return '';
  return text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}

Widget buildAiringCountdownCard(
    BuildContext context, MediaDetailsController controller) {
  final colors = context.colors;
  final airing = controller.media.value.nextAiringEpisode;
  if (airing == null) return const SizedBox.shrink();

  return Obx(() {
    final formattedTime =
        controller.formatCountdownTime(controller.timeLeft.value);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primary.opaque(0.12, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.primary.opaque(0.3, iReallyMeanIt: true),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: colors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymeXText('Episode ${airing.episode} Airing In',
                  size: 11,
                  color: colors.onSurface.opaque(0.6, iReallyMeanIt: true),
                ),
                AnymeXText(formattedTime,
                  size: 14,
                  variant: TextVariant.bold,
                  color: colors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  });
}

Widget buildProgressContainer(
    BuildContext context, MediaDetailsController controller) {
  final colors = context.colors;
  final media = controller.media.value;

  final totalCount = int.tryParse(media.totalEpisodes) ??
      int.tryParse(media.totalChapters ?? '') ??
      0;
  final currentProgress = controller.mediaProgress.value;
  final pct =
      totalCount > 0 ? (currentProgress / totalCount).clamp(0.0, 1.0) : 0.0;

  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: colors.surfaceContainerHighest.opaque(0.3, iReallyMeanIt: true),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnymeXText(controller.isAnime ? 'Watching Progress' : 'Reading Progress',
              size: 12,
              color: colors.onSurface.opaque(0.6, iReallyMeanIt: true),
            ),
            AnymeXText('$currentProgress / ${totalCount > 0 ? totalCount : "?"}',
              size: 13,
              variant: TextVariant.bold,
              color: colors.primary,
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnymeXLinearIndicator(
          value: pct,
          minHeight: 9,
          backgroundColor: colors.onSurface.opaque(0.1, iReallyMeanIt: true),
          color: colors.primary,
        ),
      ],
    ),
  );
}

Widget buildGenreChip(BuildContext context, String genre) {
  final colors = context.colors;

  return GestureDetector(
    onTap: () {
      navigate(() => SearchPage(
            searchTerm: '',
            initialFilters: {
              'genres': [genre]
            },
          ));
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.opaque(0.4, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
        ),
      ),
      child: AnymeXText(genre,
        size: 11,
        variant: TextVariant.semiBold,
      ),
    ),
  );
}

Widget buildTagChip(BuildContext context, MediaTag tag) {
  final colors = context.colors;
  final labelText = tag.rank > 0 ? '${tag.name} ${tag.rank}%' : tag.name;

  return GestureDetector(
    onTap: () {
      navigate(() => SearchPage(
            searchTerm: '',
            initialFilters: {
              'tags': [tag.name]
            },
          ));
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primary.opaque(0.12, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.primary.opaque(0.25, iReallyMeanIt: true),
        ),
      ),
      child: AnymeXText(labelText,
        size: 11,
        variant: TextVariant.semiBold,
        color: colors.primary,
      ),
    ),
  );
}

Widget buildStatsGrid(BuildContext context, Media media) {
  final colors = context.colors;
  final isAnime = media.mediaType == ItemType.anime;
  final yearStr = media.seasonYear?.toString() ?? '';

  final seasonText = [
    if (media.season.isNotEmpty && media.season != '?') media.season,
    if (yearStr.isNotEmpty) yearStr,
  ].join(' ');

  final stats = [
    if ((media.studios ?? []).isNotEmpty)
      MapEntry('Studio', (media.studios ?? []).join(', ')),
    if (isAnime && media.totalEpisodes.isNotEmpty && media.totalEpisodes != '0' && media.totalEpisodes != '?')
      MapEntry('Episodes', media.totalEpisodes),
    if (!isAnime &&
        (media.totalChapters ?? '').isNotEmpty &&
        media.totalChapters != '0' &&
        media.totalChapters != '?')
      MapEntry('Chapters', media.totalChapters!),
    if (isAnime && media.duration.isNotEmpty && media.duration != '?') MapEntry('Duration', media.duration),
    if (seasonText.trim().isNotEmpty) MapEntry('Season', seasonText.trim()),
    if (media.status.isNotEmpty && media.status != '?') MapEntry('Status', media.status),
    if (media.format.isNotEmpty && media.format != '?') MapEntry('Format', media.format),
    if (media.sourceMaterial != null && media.sourceMaterial!.isNotEmpty && media.sourceMaterial != '?')
      MapEntry('Source', formatSourceMaterial(media.sourceMaterial)),
    if (media.rating.isNotEmpty && media.rating != '?') MapEntry('Score', '★ ${media.rating}'),
    if (media.popularity.isNotEmpty && media.popularity != '?') MapEntry('Popularity', media.popularity),
  ];

  if (stats.isEmpty) return const SizedBox.shrink();

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: colors.surfaceContainerHighest.opaque(0.3, iReallyMeanIt: true),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
      ),
    ),
    child: Wrap(
      spacing: 20,
      runSpacing: 12,
      children: stats
          .map((entry) => buildStatCard(context, entry.key, entry.value))
          .toList(),
    ),
  );
}

Widget buildStatCard(BuildContext context, String label, String value) {
  final colors = context.colors;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      AnymeXText(label,
        size: 11,
        color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
      ),
      const SizedBox(height: 2),
      AnymeXText(value,
        size: 13,
        variant: TextVariant.semiBold,
      ),
    ],
  );
}
