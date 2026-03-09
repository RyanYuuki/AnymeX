// ignore_for_file: prefer_const_constructors

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/anime/themes/anime_theme_view.dart';
import 'package:anymex/screens/anime/widgets/watch_order_page.dart';
import 'package:anymex/models/mangaupdates/news_item.dart';
import 'package:anymex/screens/news/news_page.dart';
import 'package:anymex/screens/anime/widgets/social_section.dart';
import 'package:anymex/utils/anime_adaptation_util.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Extracted common widget for collapsible sections
class CollapsibleBox extends StatefulWidget {
  final Widget header;
  final Widget content;
  final bool isInitiallyExpanded;
  final ColorScheme colorScheme;
  final EdgeInsetsGeometry padding;

  const CollapsibleBox({
    super.key,
    required this.header,
    required this.content,
    required this.colorScheme,
    this.isInitiallyExpanded = false,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  State<CollapsibleBox> createState() => _CollapsibleBoxState();
}

class _CollapsibleBoxState extends State<CollapsibleBox> with SingleTickerProviderStateMixin {
  late bool isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.isInitiallyExpanded;
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    if (isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.colorScheme.outline.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: widget.header),
                RotationTransition(
                  turns: _iconTurns,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: widget.colorScheme.primary,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                children: [
                  const SizedBox(height: 20),
                  widget.content,
                ],
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }
}

// Extracted widget for action cards (like Watch Order, Openings, News)
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
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
                    text: title,
                    variant: TextVariant.bold,
                    size: 14,
                  ),
                  const SizedBox(height: 4),
                  AnymexText(
                    text: subtitle,
                    variant: TextVariant.regular,
                    size: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

// Extracted widget for section headers
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final ColorScheme colorScheme;
  final double iconSize;
  final double titleSize;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.colorScheme,
    this.iconSize = 24,
    this.titleSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(iconSize == 24 ? 8 : 6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(iconSize == 24 ? 12 : 10),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        AnymexText(
          text: title,
          variant: TextVariant.bold,
          size: titleSize,
        ),
      ],
    );
  }
}

class AnimeStats extends StatelessWidget {
  final Media data;
  final String countdown;
  final List<TrackedMedia>? friendsWatching;
  final String? totalEpisodes;

  const AnimeStats({
    super.key,
    required this.data,
    required this.countdown,
    this.friendsWatching,
    this.totalEpisodes,
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
          _buildCollapsibleSectionContainer(
            context,
            icon: Icons.analytics_outlined,
            title: "Statistics",
            child: _buildStatsGrid(context),
            isInitiallyExpanded: true,
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
          _buildCollapsibleInfoCard(
            context,
            icon: Icons.description_outlined,
            title: "Synopsis",
            content: AnymexText(
              text: data.description,
              size: 15,
              color: colorScheme.onSurface.withValues(alpha: 0.9),
              maxLines: 100,
              stripHtml: true,
            ),
            isInitiallyExpanded: true,
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
                  backgroundImage: (index < covers.length) ? covers[index].cover! : data.cover ?? data.poster,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (friendsWatching != null && friendsWatching!.isNotEmpty) ...[
            SocialSection(
              friends: friendsWatching!,
              totalEpisodes: totalEpisodes,
            ),
            const SizedBox(height: 16),
          ],

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
    return _buildCollapsibleSectionContainer(
        context,
        icon: Icons.more,
        title: "Others",
        child: Column(
          children: [
            _ActionCard(
              icon: Icons.music_note_rounded,
              title: "Openings & Endings",
              subtitle: "View opening and ending themes",
              onTap: () {
                navigate(() => AnimeThemePlayerPage(animeDetails: data));
              },
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<NewsItem>>(
              future: MangaAnimeUtil.getAnimeNews(data),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                
                return Column(
                  children: [
                    _ActionCard(
                      icon: Icons.newspaper_rounded,
                      title: "Recent News",
                      subtitle: "Read latest updates about this anime",
                      onTap: () {
                        navigate(() => NewsPage(media: data, news: snapshot.data!));
                      },
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }
            ),
            _ActionCard(
              icon: Icons.playlist_play_rounded,
              title: "Watch Order",
              subtitle: "View the chronological watch order of this anime",
              onTap: () {
                navigate(() => WatchOrderPage(title: data.title));
              },
              colorScheme: colorScheme,
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
                                          cover: relation.cover,
                                          serviceType: ServicesType.anilist),
                                      tag: relation.id.toString()),
                                );
                              },
                              backgroundImage: relation.cover.isNotEmpty
                                  ? relation.cover
                                  : relation.poster,
                          )))
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
                  colorScheme.primaryContainer.withValues(alpha: 0.3),
                  colorScheme.primary.withValues(alpha: 0.15),
                ]
              : [
                  colorScheme.surfaceContainer.withValues(alpha: 0.6),
                  colorScheme.surfaceContainer,
                  colorScheme.surfaceContainer.withValues(alpha: 0.6),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
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
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
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
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: icon,
            title: title,
            colorScheme: colorScheme,
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
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: icon,
            title: title,
            colorScheme: colorScheme,
            iconSize: 18,
            titleSize: 16,
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildCollapsibleInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget content,
    bool isInitiallyExpanded = false,
  }) {
    final colorScheme = context.colors;
    
    return CollapsibleBox(
      isInitiallyExpanded: isInitiallyExpanded,
      header: _SectionHeader(
        icon: icon,
        title: title,
        colorScheme: colorScheme,
        iconSize: 18,
        titleSize: 16,
      ),
      content: content,
      colorScheme: colorScheme,
    );
  }

  Widget _buildCollapsibleSectionContainer(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
    bool isInitiallyExpanded = true,
  }) {
    final colorScheme = context.colors;

    return CollapsibleBox(
      isInitiallyExpanded: isInitiallyExpanded,
      header: _SectionHeader(
        icon: icon,
        title: title,
        colorScheme: colorScheme,
      ),
      content: child,
      colorScheme: colorScheme,
      padding: const EdgeInsets.all(24),
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
            color: colorScheme.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.1),
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
                    color: colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  AnymexText(
                    text: stat['label'].toString(),
                    variant: TextVariant.regular,
                    size: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
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
