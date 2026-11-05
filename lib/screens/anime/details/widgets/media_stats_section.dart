import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/animethemes/anime_theme.dart';
import 'package:anymex/models/mangaupdates/anime_adaptation.dart';
import 'package:anymex/models/mangaupdates/next_release.dart';
import 'package:anymex/models/mangaupdates/news_item.dart';
import 'package:anymex/screens/anime/details/controller/media_details_controller.dart';
import 'package:anymex/screens/anime/details/media_details_page.dart';
import 'package:anymex/screens/anime/studio_details_page.dart';
import 'package:anymex/screens/anime/themes/anime_theme_dialog.dart';
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
          color:
              colors.surfaceContainerHighest.opaque(0.3, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AnymeXText(
              'Synopsis',
              size: 15,
              variant: TextVariant.bold,
              isMarquee: true,
            ),
            const SizedBox(height: 8),
            AnymeXText(
              cleanDesc,
              size: 13,
              maxLines: 9999,
              overflow: TextOverflow.ellipsis,
              isMarquee: false,
            ),
          ],
        ),
      ),
    buildStatsGrid(context, media, controller: controller),
    buildAlternativeTitles(context, media),
    if (media.genres.isNotEmpty)
      _buildSection(
          'Genres',
          [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: media.genres
                  .map((genre) =>
                      buildGenreChip(context, genre, media.mediaType))
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
                  .map((tag) => buildTagChip(context, tag, media.mediaType))
                  .toList(),
            ),
          ],
          colors),
    if (controller.isAnime) buildThemesSection(context, controller),
    if (media.friendsWatching != null && media.friendsWatching!.isNotEmpty)
      SocialSection(
        friends: media.friendsWatching!,
        totalEpisodes: media.totalEpisodes.isNotEmpty
            ? media.totalEpisodes
            : media.totalChapters,
      ),
    buildSeasonsSection(context, media),
    if (controller.isAnime) buildExtrasSection(context, media, controller),
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
                      child: AnymeXText(
                        entry.key,
                        size: 12,
                        color:
                            colors.onSurface.opaque(0.5, iReallyMeanIt: true),
                      ),
                    ),
                    Expanded(
                      child: AnymeXText(
                        entry.value,
                        size: 12,
                        maxLines: null,
                        overflow: TextOverflow.visible,
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
        AnymeXText(
          title,
          size: 14,
          variant: TextVariant.bold,
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}

Widget buildThemesSection(
    BuildContext context, MediaDetailsController controller) {
  final colors = context.colors;
  final media = controller.media.value;

  return Obx(() {
    if (controller.isThemesLoading.value) {
      return _buildSection(
        'Openings & Endings',
        [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              ),
            ),
          ),
        ],
        colors,
      );
    }

    final themes = controller.animeThemes;
    if (themes.isEmpty) return const SizedBox.shrink();

    final ops =
        themes.where((t) => t.type.toUpperCase().startsWith('OP')).toList();
    final eds =
        themes.where((t) => t.type.toUpperCase().startsWith('ED')).toList();
    final other =
        themes.where((t) => !ops.contains(t) && !eds.contains(t)).toList();

    Widget buildThemeTile(AnimeTheme theme, int globalIndex) {
      final isOP = theme.type.toUpperCase().startsWith('OP');
      final badgeText =
          '${theme.type}${theme.sequence != null ? ' ${theme.sequence}' : ''}';

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            AnimeThemePlayerDialog.show(
              context,
              themes: themes.toList(),
              initialIndex: globalIndex,
              animeDetails: media,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isOP ? colors.primary : colors.secondary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (isOP ? colors.primary : colors.secondary)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: AnymeXText(
                    badgeText,
                    size: 11,
                    variant: TextVariant.bold,
                    color: isOP ? colors.primary : colors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXText(
                        theme.title,
                        size: 13,
                        variant: TextVariant.semiBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (theme.artist.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        AnymeXText(
                          theme.artist,
                          size: 11,
                          color: colors.onSurfaceVariant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.play_circle_filled_rounded,
                  color: colors.primary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<Widget> items = [];

    if (ops.isNotEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4, top: 2),
          child: AnymeXText(
            'Openings',
            size: 12.5,
            variant: TextVariant.bold,
            color: colors.primary,
          ),
        ),
      );
      for (final op in ops) {
        final globalIndex = themes.indexOf(op);
        items.add(buildThemeTile(op, globalIndex));
      }
    }

    if (eds.isNotEmpty) {
      if (ops.isNotEmpty) items.add(const SizedBox(height: 8));
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4, top: 4),
          child: AnymeXText(
            'Endings',
            size: 12.5,
            variant: TextVariant.bold,
            color: colors.secondary,
          ),
        ),
      );
      for (final ed in eds) {
        final globalIndex = themes.indexOf(ed);
        items.add(buildThemeTile(ed, globalIndex));
      }
    }

    if (other.isNotEmpty) {
      if (ops.isNotEmpty || eds.isNotEmpty)
        items.add(const SizedBox(height: 8));
      for (final oth in other) {
        final globalIndex = themes.indexOf(oth);
        items.add(buildThemeTile(oth, globalIndex));
      }
    }

    return _buildSection('Openings & Endings', items, colors);
  });
}

Widget buildSeasonsSection(BuildContext context, Media mediaData) {
  final prequels = mediaData.relations
          ?.where((element) => element.relationType == 'PREQUEL')
          .toList() ??
      [];
  final sequels = mediaData.relations
          ?.where((element) => element.relationType == 'SEQUEL')
          .toList() ??
      [];
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
                  backgroundImage: relation.cover.isNotEmpty
                      ? relation.cover
                      : relation.poster,
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

Widget buildExtrasSection(
    BuildContext context, Media mediaData, MediaDetailsController controller) {
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
                  if (controller.animeThemes.isNotEmpty) {
                    AnimeThemePlayerDialog.show(
                      context,
                      themes: controller.animeThemes.toList(),
                      initialIndex: 0,
                      animeDetails: mediaData,
                    );
                  } else {
                    navigate(
                        () => AnimeThemePlayerPage(animeDetails: mediaData));
                  }
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
                AnymeXText(
                  'Episode ${airing.episode} Airing In',
                  size: 11,
                  color: colors.onSurface.opaque(0.6, iReallyMeanIt: true),
                ),
                AnymeXText(
                  formattedTime,
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
  return Obx(() {
    final colors = context.colors;
    final media = controller.media.value;

    final totalFromMedia = int.tryParse(media.totalEpisodes) ??
        int.tryParse(media.totalChapters ?? '') ??
        0;
    final totalCount = totalFromMedia > 0
        ? totalFromMedia
        : (controller.chapterList.isNotEmpty
            ? controller.chapterList.length
            : 0);
    final currentProgress = controller.mediaProgress.value;
    final pct =
        totalCount > 0 ? (currentProgress / totalCount).clamp(0.0, 1.0) : 0.0;

    final relEp = controller.isAnime
        ? (media.nextAiringEpisode != null
            ? media.nextAiringEpisode!.episode - 1
            : (int.tryParse(
                    controller.trackedMedia.value?.releasedEpisodes ?? '') ??
                0))
        : 0;

    final progressText = (controller.isAnime &&
            relEp > 0 &&
            totalCount > 0 &&
            relEp != totalCount)
        ? '$currentProgress / $relEp / $totalCount'
        : '$currentProgress / ${totalCount > 0 ? totalCount : "?"}';

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
              AnymeXText(
                controller.isAnime ? 'Watching Progress' : 'Reading Progress',
                size: 12,
                color: colors.onSurface.opaque(0.6, iReallyMeanIt: true),
              ),
              AnymeXText(
                progressText,
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
  });
}

Widget buildGenreChip(BuildContext context, String genre, ItemType type) {
  final colors = context.colors;

  return GestureDetector(
    onTap: () {
      navigate(() => SearchPage(
            searchTerm: '',
            type: type,
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
      child: AnymeXText(
        genre,
        size: 11,
        variant: TextVariant.semiBold,
      ),
    ),
  );
}

Widget buildTagChip(BuildContext context, MediaTag tag, ItemType type) {
  final colors = context.colors;
  final labelText = tag.rank > 0 ? '${tag.name} ${tag.rank}%' : tag.name;

  return GestureDetector(
    onTap: () {
      navigate(() => SearchPage(
            searchTerm: '',
            type: type,
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
      child: AnymeXText(
        labelText,
        size: 11,
        variant: TextVariant.semiBold,
        color: colors.primary,
      ),
    ),
  );
}

Widget buildStatsGrid(BuildContext context, Media media,
    {MediaDetailsController? controller}) {
  final colors = context.colors;
  final isAnime = media.mediaType == ItemType.anime;
  final yearStr = media.seasonYear?.toString() ?? '';

  final seasonText = [
    if (media.season.isNotEmpty && media.season != '?') media.season,
    if (yearStr.isNotEmpty) yearStr,
  ].join(' ');

  final totalChaptersStr = (media.totalChapters ?? '').isNotEmpty &&
          media.totalChapters != '0' &&
          media.totalChapters != '?'
      ? media.totalChapters!
      : ((controller != null && controller.chapterList.isNotEmpty)
          ? controller.chapterList.length.toString()
          : '');

  final stats = [
    if ((media.studios ?? []).isNotEmpty)
      MapEntry('Studio', (media.studios ?? []).join(', ')),
    if (isAnime &&
        media.totalEpisodes.isNotEmpty &&
        media.totalEpisodes != '0' &&
        media.totalEpisodes != '?')
      MapEntry('Episodes', media.totalEpisodes),
    if (!isAnime && totalChaptersStr.isNotEmpty)
      MapEntry('Chapters', totalChaptersStr),
    if (isAnime && media.duration.isNotEmpty && media.duration != '?')
      MapEntry('Duration', media.duration),
    if (seasonText.trim().isNotEmpty) MapEntry('Season', seasonText.trim()),
    if (media.status.isNotEmpty && media.status != '?')
      MapEntry('Status', media.status),
    if (media.format.isNotEmpty && media.format != '?')
      MapEntry('Format', media.format),
    if (media.sourceMaterial != null &&
        media.sourceMaterial!.isNotEmpty &&
        media.sourceMaterial != '?')
      MapEntry('Source', formatSourceMaterial(media.sourceMaterial)),
    if (media.rating.isNotEmpty && media.rating != '?')
      MapEntry('Score', '★ ${media.rating}'),
    if (media.popularity.isNotEmpty && media.popularity != '?')
      MapEntry('Popularity', media.popularity),
  ];

  if (stats.isEmpty) return const SizedBox.shrink();

  return LayoutBuilder(
    builder: (context, constraints) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              colors.surfaceContainerHighest.opaque(0.3, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
          ),
        ),
        child: Wrap(
          spacing: 20,
          runSpacing: 12,
          children: stats.map((entry) {
            VoidCallback? onTap;
            if (entry.key == 'Studio' && (media.studios ?? []).isNotEmpty) {
              final studioName = media.studios!.first;
              onTap = () async {
                final studioId =
                    await AnilistData.fetchStudioIdByName(studioName);
                if (studioId != null && context.mounted) {
                  showStudioDetailsSheet(
                    context,
                    studioId,
                    studioName,
                  );
                }
              };
            }
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth - 28),
              child:
                  buildStatCard(context, entry.key, entry.value, onTap: onTap),
            );
          }).toList(),
        ),
      );
    },
  );
}

Widget buildStatCard(BuildContext context, String label, String value,
    {VoidCallback? onTap}) {
  final colors = context.colors;

  final card = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      AnymeXText(
        label,
        size: 11,
        color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
      ),
      const SizedBox(height: 2),
      AnymeXText(
        value,
        size: 13,
        maxLines: null,
        overflow: TextOverflow.visible,
        variant: TextVariant.semiBold,
      ),
    ],
  );

  if (onTap != null) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
  return card;
}
