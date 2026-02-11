import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/mangaupdates/anime_adaptation.dart';
import 'package:anymex/models/mangaupdates/next_release.dart';
import 'package:anymex/models/mangaupdates/news_item.dart';
import 'package:anymex/screens/news/news_page.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/utils/anime_adaptation_util.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart';
import 'package:anymex/utils/fallback/fallback_manga.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';

class MangaStats extends StatefulWidget {
  final Media data;
  const MangaStats({
    super.key,
    required this.data,
  });

  @override
  State<MangaStats> createState() => _MangaStatsState();
}

class _MangaStatsState extends State<MangaStats> {
  late final Future<AnimeAdaptation> _animeAdaptationFuture;
  late final Future<NextRelease> _nextReleaseFuture;
  late final Future<List<NewsItem>> _newsFuture;

  @override
  void initState() {
    super.initState();

    _animeAdaptationFuture = MangaAnimeUtil.getAnimeAdaptation(widget.data);
    _nextReleaseFuture = MangaAnimeUtil.getNextChapterPrediction(widget.data);
    _newsFuture = MangaAnimeUtil.getMangaNovelNews(widget.data);
  }

  @override
  Widget build(BuildContext context) {
    final covers = [...trendingAnimes, ...trendingMangas]
        .where((e) => e.cover != null && (e.cover?.isNotEmpty ?? false))
        .toList();
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final colorScheme = context.colors;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((widget.data.status.toUpperCase()) == 'RELEASING') ...[
            _buildNextChapterPrediction(context),
            const SizedBox(height: 16),
          ],
          _buildSectionContainer(
            context,
            icon: Icons.analytics_outlined,
            title: "Statistics",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(context),
              ],
            ),
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
                    text: widget.data.romajiTitle,
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
            content: Html(
              data: widget.data.description,
              style: {
                "body": Style(
                  fontSize: FontSize(15.0),
                  lineHeight: LineHeight(1.7),
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
                "b": Style(fontWeight: FontWeight.w600),
                "i": Style(fontStyle: FontStyle.italic),
              },
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<AnimeAdaptation>(
            future: _animeAdaptationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: const ExpressiveLoadingIndicator(),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final adaptation = snapshot.data!;
              if (adaptation.error != null || !adaptation.hasAdaptation) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  _buildInfoCard(
                    context,
                    icon: Icons.tv_rounded,
                    title: "Anime Adaptation",
                    content: Column(
                      children: [
                        _buildAdaptationItem(
                          context,
                          label: "Start Chapter",
                          value: adaptation.animeStart ?? 'Unknown',
                        ),
                        const SizedBox(height: 12),
                        _buildAdaptationItem(
                          context,
                          label: "End Chapter",
                          value: adaptation.animeEnd ?? 'Unknown',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
          _buildSectionContainer(
            context,
            icon: Icons.category_rounded,
            title: "Genres",
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 15),
              shrinkWrap: true,
              itemCount: widget.data.genres.length,
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
                final e = widget.data.genres[index];
                return ImageButton(
                  buttonText: e,
                  height: 80,
                  width: 1000,
                  onPressed: () {
                    navigate(() => SearchPage(
                          searchTerm: '',
                          isManga: true,
                          initialFilters: {
                            'genres': [e]
                          },
                        ));
                  },
                  backgroundImage: covers[index].cover!,
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          FutureBuilder<List<NewsItem>>(
            future: _newsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return _buildMangaOthersSection(context, snapshot.data!);
            },
          ),
          const SizedBox(height: 16),
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
        color: colorScheme.surfaceContainer.opaque(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.opaque(0.2, iReallyMeanIt: true),
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
        color: colorScheme.surfaceContainer.opaque(0.35),
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
                autoResize: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildMangaOthersSection(BuildContext context, List<NewsItem> news) {
  final colorScheme = context.colors;
  
  return _buildSectionContainer(
    context, 
    icon: Icons.more,
    title: "Others", 
    child: Column(
      children: [
        GestureDetector(
          onTap: () {
            navigate(() => NewsPage(media: widget.data, news: news));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    color: colorScheme.primary.opaque(0.15, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.newspaper_rounded,
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
                        text: "Recent News",
                        variant: TextVariant.bold,
                        size: 14,
                      ),
                      const SizedBox(height: 4),
                      AnymexText(
                        text: "Read latest updates about this manga",
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
    )
  );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final colorScheme = context.colors;
    final stats = [
      {
        'label': 'Type',
        'value': widget.data.type,
        'icon': Icons.video_library_outlined
      },
      {
        'label': 'Rating',
        'value': '${widget.data.rating}/10',
        'icon': Icons.star_outline_rounded
      },
      {
        'label': 'Format',
        'value': widget.data.format,
        'icon': Icons.style_outlined
      },
      {
        'label': 'Status',
        'value': widget.data.status,
        'icon': Icons.radio_button_checked_outlined
      },
      {
        'label': 'Popularity',
        'value': widget.data.popularity,
        'icon': Icons.trending_up_rounded
      },
      {
        'label': 'Chapters',
        'value': widget.data.totalChapters ?? '??',
        'icon': Icons.menu_book_outlined
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
        mainAxisExtent: 85,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surface.opaque(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.primary.opaque(0.1, iReallyMeanIt: true),
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
                    color: colorScheme.primary.opaque(0.7, iReallyMeanIt: true),
                  ),
                  const SizedBox(width: 6),
                  AnymexText(
                    text: stat['label'].toString(),
                    variant: TextVariant.regular,
                    size: 11,
                    color:
                        colorScheme.onSurface.opaque(0.6, iReallyMeanIt: true),
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

  Widget _buildNextChapterPrediction(BuildContext context) {
    final colorScheme = context.colors;

    return FutureBuilder<NextRelease>(
      future: _nextReleaseFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.nextReleaseDate != null) {
          final pred = snapshot.data!;
          final dateStr =
              DateFormat('d MMMM yyyy').format(pred.nextReleaseDate!);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.opaque(0.3, iReallyMeanIt: true),
                  colorScheme.primary.opaque(0.15, iReallyMeanIt: true),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.primary.opaque(0.3, iReallyMeanIt: true),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymexText(
                        text: "Next Release",
                        variant: TextVariant.regular,
                        size: 11,
                        color: colorScheme.onSurface
                            .opaque(0.6, iReallyMeanIt: true),
                      ),
                      const SizedBox(height: 4),
                      AnymexText(
                        text: "${pred.nextChapter} • $dateStr",
                        variant: TextVariant.bold,
                        size: 14,
                        color: colorScheme.primary,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAdaptationItem(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colorScheme = context.colors;
    List<String> chapters = value
        .replaceAllMapped(RegExp(r'\s*/\s*'), (match) => ' / ')
        .split(' / ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface.opaque(0.3, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.opaque(0.15, iReallyMeanIt: true),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: AnymexText(
              text: label,
              variant: TextVariant.semiBold,
              size: 13,
              color: colorScheme.onSurface.opaque(0.7, iReallyMeanIt: true),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: chapters
                  .map(
                    (chapter) => AnymexText(
                      text: chapter,
                      variant: TextVariant.bold,
                      size: 13,
                      color: colorScheme.primary,
                      textAlign: TextAlign.right,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
