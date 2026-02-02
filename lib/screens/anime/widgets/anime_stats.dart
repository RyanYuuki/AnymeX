// ignore_for_file: prefer_const_constructors

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/anime/themes/anime_theme_view.dart';
import 'package:anymex/screens/anime/widgets/watch_order_page.dart';
import 'package:anymex/screens/anime/misc/anime_visuals_page.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnimeStats extends StatelessWidget {
  final Media data;
  final String countdown;
  const AnimeStats({
    super.key,
    required this.data,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();
    final isSimkl = serviceHandler.serviceType.value == ServicesType.simkl;
    final covers = (isSimkl
            ? [
                ...serviceHandler.simklService.trendingMovies,
                ...serviceHandler.simklService.trendingSeries
              ]
            : [
                ...serviceHandler.anilistService.trendingAnimes,
                ...serviceHandler.anilistService.trendingMangas,
              ])
        .where((e) => e.cover != null && (e.cover?.isNotEmpty ?? false))
        .toList();
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final colorScheme = context.colors;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (countdown != '0') ...[
            _buildCountdownCard(context),
            const SizedBox(height: 16),
          ],
          _buildSectionContainer(
            context,
            icon: Icons.analytics_outlined,
            title: "Statistics",
            child: _buildStatsGrid(context),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInfoCard(
                  context,
                  icon: Icons.language_rounded,
                  title: "Romaji Title",
                  content: AnymexText(
                    text: data.romajiTitle,
                    variant: TextVariant.semiBold,
                    size: 15,
                    maxLines: 3,
                    autoResize: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            icon: Icons.description_outlined,
            title: "Synopsis",
            content: AnymexText(
              text: data.description,
              size: 15,
              color: colorScheme.onSurface.opaque(0.9),
              maxLines: 100,
              stripHtml: true,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionContainer(
            context,
            icon: Icons.category_rounded,
            title: "Genres",
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 15),
              shrinkWrap: true,
              itemCount: data.genres.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                childAspectRatio: 1,
                crossAxisCount: getResponsiveCrossAxisCount(
                  context,
                  baseColumns: 2,
                  maxColumns: 4,
                ),
                mainAxisSpacing: 10,
                mainAxisExtent: isDesktop ? 80 : 60,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final e = data.genres[index];
                return ImageButton(
                  buttonText: e,
                  height: 80,
                  width: 1000,
                  onPressed: () {
                    if (serviceHandler.serviceType.value ==
                        ServicesType.anilist) {
                      navigate(() => SearchPage(
                            searchTerm: '',
                            isManga: false,
                            initialFilters: {
                              'genres': [e]
                            },
                          ));
                    }
                  },
                  backgroundImage: covers[index].cover!,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildSeasons(context),
          const SizedBox(height: 16),
          _buildOthersSection(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOthersSection(BuildContext context) {
    final colorScheme = context.colors;
    return _buildSectionContainer(context,
        icon: Icons.more,
        title: "Others",
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                navigate(() => AnimeThemePlayerPage(animeDetails: data));
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.opaque(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outline.opaque(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary
                            .opaque(0.15, iReallyMeanIt: true),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 22,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymexText(
                            text: "Openings & Endings",
                            variant: TextVariant.bold,
                            size: 14,
                          ),
                          const SizedBox(height: 4),
                          AnymexText(
                            text: "View opening and ending themes",
                            variant: TextVariant.regular,
                            size: 13,
                            color: colorScheme.onSurface.opaque(0.6),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: colorScheme.primary.opaque(0.7),
                    ),
                  ],
                ),
              ),
            ),
            10.height(),
            GestureDetector(
              onTap: () {
                navigate(() => AnimeVisualsPage(
                  animeTitle: data.title,
                  malId: data.idMal,
                ));
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .opaque(0.4, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outline.opaque(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary
                            .opaque(0.15, iReallyMeanIt: true),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image_rounded,
                        size: 22,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymexText(
                            text: "Visuals",
                            variant: TextVariant.bold,
                            size: 14,
                          ),
                          const SizedBox(height: 4),
                          AnymexText(
                            text:
                                "Official posters and key visuals",
                            variant: TextVariant.regular,
                            size: 13,
                            color: colorScheme.onSurface.opaque(0.6),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: colorScheme.primary.opaque(0.7),
                    ),
                  ],
                ),
              ),
            ),
            10.height(),
            GestureDetector(
              onTap: () {
                navigate(() => WatchOrderPage(title: data.title));
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .opaque(0.4, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outline.opaque(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary
                            .opaque(0.15, iReallyMeanIt: true),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.playlist_play_rounded,
                        size: 22,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymexText(
                            text: "Watch Order",
                            variant: TextVariant.bold,
                            size: 14,
                          ),
                          const SizedBox(height: 4),
                          AnymexText(
                            text:
                                "View the chronological watch order of this anime",
                            variant: TextVariant.regular,
                            size: 13,
                            color: colorScheme.onSurface.opaque(0.6),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: colorScheme.primary.opaque(0.7),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  Widget _buildSeasons(BuildContext context) {
    final filteredRelations = data.relations
            ?.where((element) =>
                element.relationType == 'SEQUEL' ||
                element.relationType == 'PREQUEL')
            .take(2)
            .toList() ??
        [];

    return filteredRelations.isEmpty
        ? const SizedBox.shrink()
        : _buildSectionContainer(context,
            icon: Icons.tv_rounded,
            title: "Seasons",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 5,
                  mainAxisAlignment: getResponsiveValue(context,
                      mobileValue: MainAxisAlignment.spaceBetween,
                      desktopValue: MainAxisAlignment.center),
                  children: filteredRelations
                      .map((relation) => Expanded(
                            child: ImageButton(
                              height: getResponsiveSize(context,
                                  mobileSize: 60, desktopSize: 80),
                              buttonText: relation.relationType,
                              onPressed: () {
                                navigate(
                                  () => AnimeDetailsPage(
                                      media: Media(
                                          id: relation.id.toString(),
                                          title: relation.title,
                                          poster: relation.poster,
                                          serviceType: ServicesType.anilist),
                                      tag: relation.id.toString()),
                                );
                              },
                              backgroundImage: relation.cover.isNotEmpty
                                  ? relation.cover
                                  : relation.poster,
                            ),
                          ))
                      .toList(),
                ),
              ],
            ));
  }

  Widget _buildCountdownCard(BuildContext context) {
    final colorScheme = context.colors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Get.isDarkMode
              ? [
                  colorScheme.primaryContainer.opaque(0.3),
                  colorScheme.primary.opaque(0.15),
                ]
              : [
                  colorScheme.surfaceContainer.opaque(0.6, iReallyMeanIt: true),
                  colorScheme.surfaceContainer,
                  colorScheme.surfaceContainer.opaque(0.6, iReallyMeanIt: true),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.opaque(0.3, iReallyMeanIt: true),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AnymexText(
                  text:
                      "EPISODE ${data.nextAiringEpisode?.episode} RELEASES IN",
                  variant: TextVariant.bold,
                  size: 13,
                  color: colorScheme.onSurface.opaque(0.7),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnymexText(
            text: countdown,
            size: getResponsiveSize(context, mobileSize: 18, desktopSize: 22),
            variant: TextVariant.bold,
            color: colorScheme.primary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final colorScheme = context.colors;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.opaque(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.opaque(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.opaque(0.15, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              AnymexText(
                text: title,
                variant: TextVariant.bold,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    final colorScheme = context.colors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.opaque(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outline.opaque(0.15, iReallyMeanIt: true),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.opaque(0.15, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              AnymexText(
                text: title,
                variant: TextVariant.bold,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final colorScheme = context.colors;
    final stats = [
      {
        'label': 'Type',
        'value': data.type,
        'icon': Icons.video_library_outlined
      },
      {
        'label': 'Rating',
        'value': '${data.rating}/10',
        'icon': Icons.star_outline_rounded
      },
      {'label': 'Format', 'value': data.format, 'icon': Icons.style_outlined},
      {
        'label': 'Status',
        'value': data.status,
        'icon': Icons.radio_button_checked_outlined
      },
      {
        'label': 'Popularity',
        'value': data.popularity,
        'icon': Icons.trending_up_rounded
      },
      {
        'label': 'Episodes',
        'value': data.totalEpisodes,
        'icon': Icons.movie_outlined
      },
      {
        'label': 'Season',
        'value': data.season,
        'icon': Icons.calendar_today_outlined
      },
      {
        'label': 'Duration',
        'value': data.duration,
        'icon': Icons.timer_outlined
      },
      {
        'label': 'Premiered',
        'value': data.premiered,
        'icon': Icons.event_outlined
      },
      if (data.studios?.isNotEmpty ?? false)
        {
          'label': 'Studio',
          'value': data.studios?.first ?? '',
          'icon': Icons.business_outlined
        },
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 75,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surface.opaque(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.primary.opaque(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    stat['icon'] as IconData,
                    size: 16,
                    color: colorScheme.primary.opaque(0.7),
                  ),
                  const SizedBox(width: 6),
                  AnymexText(
                    text: stat['label'].toString(),
                    variant: TextVariant.regular,
                    size: 11,
                    color: colorScheme.onSurface.opaque(0.6),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AnymexText(
                text: stat['value'].toString(),
                variant: TextVariant.bold,
                size: 15,
                color: colorScheme.primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
