import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/subtitles/model/imdb_item.dart';
import 'package:anymex/screens/anime/watch/subtitles/model/online_subtitle.dart';
import 'package:anymex/screens/anime/watch/subtitles/repository/imdb_repo.dart';
import 'package:anymex/screens/anime/watch/subtitles/repository/subtitle_repo.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/custom_widgets/anymex_chip.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum SubtitleSearchView { search, seasons, episodes, subtitles }

class SubtitleSearchBottomSheet extends StatefulWidget {
  final PlayerController controller;

  const SubtitleSearchBottomSheet({
    super.key,
    required this.controller,
  });

  @override
  State<SubtitleSearchBottomSheet> createState() =>
      _SubtitleSearchBottomSheetState();
}

class _SubtitleSearchBottomSheetState extends State<SubtitleSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  final RxList<ImdbItem> _searchResults = <ImdbItem>[].obs;
  final RxList<OnlineSubtitle> _subtitles = <OnlineSubtitle>[].obs;
  final RxList<ImdbEpisode> _episodes = <ImdbEpisode>[].obs;
  final RxList<int> _seasons = <int>[].obs;

  final RxBool _isLoadingSearch = false.obs;
  final RxBool _isLoadingSubtitles = false.obs;
  final RxBool _isLoadingEpisodes = false.obs;

  final Rx<ImdbItem?> _selectedItem = Rx<ImdbItem?>(null);
  final RxInt _selectedSeason = 0.obs;
  final Rx<ImdbEpisode?> _selectedEpisode = Rx<ImdbEpisode?>(null);
  final RxString _selectedFilter = 'All'.obs;

  final Rx<SubtitleSearchView> _currentView = SubtitleSearchView.search.obs;

  final List<String> _filterOptions = [
    'All',
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'SRT',
    'VTT',
    'ASS'
  ];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch({String? query}) async {
    _isLoadingSearch.value = true;
    _searchResults.clear();

    try {
      final results = await ImdbRepo.searchTitles(
          query ?? widget.controller.anilistData.title);
      _searchResults.assignAll(results);
    } catch (e) {
      Logger.e('Search error: ${e.toString()}');
      _showError('Search failed: ${e.toString()}');
    } finally {
      _isLoadingSearch.value = false;
    }
  }

  Future<void> _loadEpisodes(String imdbId) async {
    _isLoadingEpisodes.value = true;
    _episodes.clear();
    _seasons.clear();

    try {
      final episodes = await ImdbRepo.getEpisodes(imdbId);
      if (episodes == null) {
        _currentView.value = SubtitleSearchView.subtitles;
        await _searchSubtitles(imdbId);
      } else {
        _episodes.assignAll(episodes);
        final seasonNumbers = episodes
            .where((ep) => ep.season != null)
            .map((ep) => ep.season!)
            .toSet()
            .toList()
          ..sort();
        _seasons.assignAll(seasonNumbers);
        _currentView.value = SubtitleSearchView.seasons;
      }
    } catch (e) {
      Logger.e('Episodes loading error: ${e.toString()}');
      _showError('Failed to load episodes: ${e.toString()}');
    } finally {
      _isLoadingEpisodes.value = false;
    }
  }

  Future<void> _searchSubtitles(String imdbId) async {
    _isLoadingSubtitles.value = true;
    _subtitles.clear();

    try {
      final data = await SubtitleRepo.searchById(imdbId);
      _subtitles.assignAll(data);
    } catch (e) {
      Logger.e('Subtitle search error: ${e.toString()}');
      _showError('Failed to load subtitles: ${e.toString()}');
    } finally {
      _isLoadingSubtitles.value = false;
    }
  }

  Future<void> _searchEpisodeSubtitles(
      String imdbId, int season, int episode) async {
    _isLoadingSubtitles.value = true;
    _subtitles.clear();

    try {
      final data = await SubtitleRepo.searchByEpisode(
        imdbId,
        season: season,
        episode: episode,
      );
      _subtitles.assignAll(data);
      _currentView.value = SubtitleSearchView.subtitles;
    } catch (e) {
      Logger.e('Episode subtitle search error: ${e.toString()}');
      _showError('Failed to load episode subtitles: ${e.toString()}');
    } finally {
      _isLoadingSubtitles.value = false;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  List<OnlineSubtitle> get _filteredSubtitles {
    final links =
        widget.controller.externalSubs.value.map((e) => e.file).toList();
    var subs = _subtitles.where((e) => !links.contains(e.url)).toList();

    if (_selectedFilter.value == 'All') return subs;

    return subs.where((subtitle) {
      final filter = _selectedFilter.value.toLowerCase();
      switch (filter) {
        case 'english':
          return subtitle.language == 'en';
        case 'spanish':
          return subtitle.language == 'es';
        case 'french':
          return subtitle.language == 'fr';
        case 'german':
          return subtitle.language == 'de';
        case 'italian':
          return subtitle.language == 'it';
        case 'srt':
        case 'vtt':
        case 'ass':
          return subtitle.format.toLowerCase() == filter;
        default:
          return true;
      }
    }).toList();
  }

  void _closeSheet() {
    widget.controller.isSubtitlePaneOpened.value = false;
  }

  void _goBack() {
    switch (_currentView.value) {
      case SubtitleSearchView.seasons:
        _currentView.value = SubtitleSearchView.search;
        _selectedItem.value = null;
        _episodes.clear();
        _seasons.clear();
        break;
      case SubtitleSearchView.episodes:
        _currentView.value = SubtitleSearchView.seasons;
        _selectedSeason.value = 0;
        break;
      case SubtitleSearchView.subtitles:
        if (_selectedEpisode.value != null) {
          _currentView.value = SubtitleSearchView.episodes;
          _selectedEpisode.value = null;
          _subtitles.clear();
          _selectedFilter.value = 'All';
        } else {
          _currentView.value = SubtitleSearchView.search;
          _selectedItem.value = null;
          _subtitles.clear();
          _selectedFilter.value = 'All';
        }
        break;
      case SubtitleSearchView.search:
        break;
    }
  }

  List<ImdbEpisode> get _episodesForSeason {
    return _episodes.where((ep) => ep.season == _selectedSeason.value).toList()
      ..sort((a, b) => (a.episodeNumber ?? 0).compareTo(b.episodeNumber ?? 0));
  }

  bool get _isLoading {
    return _isLoadingSearch.value ||
        _isLoadingSubtitles.value ||
        _isLoadingEpisodes.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      return EpisodeSidePane(
        isVisible: widget.controller.isSubtitlePaneOpened.value,
        onOverlayTap: _closeSheet,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(theme, colorScheme),
              Expanded(
                child: Stack(
                  children: [
                    _buildContent(theme, colorScheme),
                    if (_isLoading)
                      Container(
                        color: colorScheme.surface.withOpacity(0.8),
                        child: _buildFullScreenLoader(theme, colorScheme),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFullScreenLoader(ThemeData theme, ColorScheme colorScheme) {
    String message;
    if (_isLoadingSearch.value) {
      message = 'Searching...';
    } else if (_isLoadingEpisodes.value) {
      message = 'Loading episodes...';
    } else if (_isLoadingSubtitles.value) {
      message = 'Loading subtitles...';
    } else {
      message = 'Loading...';
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExpressiveLoadingIndicator(
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentView.value != SubtitleSearchView.search)
                IconButton(
                  onPressed: _isLoading ? null : _goBack,
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceVariant,
                  ),
                ),
              if (_currentView.value != SubtitleSearchView.search)
                const SizedBox(width: 8),
              Icon(Icons.subtitles_outlined, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getHeaderTitle(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : _closeSheet,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceVariant,
                ),
              ),
            ],
          ),
          if (_currentView.value == SubtitleSearchView.search) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onSubmitted: (query) => _performSearch(query: query),
              enabled: !_isLoadingSearch.value,
              decoration: InputDecoration(
                hintText: 'Search movies or TV shows...',
                prefixIcon: _isLoadingSearch.value
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: ExpressiveLoadingIndicator(
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                    : Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
          if (_currentView.value == SubtitleSearchView.subtitles &&
              _subtitles.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Obx(() => AnymexChip(
                          label: filter,
                          isSelected: filter == _selectedFilter.value,
                          onSelected: _isLoading
                              ? (_) {}
                              : (_) => _selectedFilter.value = filter,
                        )),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    switch (_currentView.value) {
      case SubtitleSearchView.search:
        return 'Online Subtitles';
      case SubtitleSearchView.seasons:
        return _selectedItem.value?.title ?? 'Seasons';
      case SubtitleSearchView.episodes:
        return 'Season ${_selectedSeason.value}';
      case SubtitleSearchView.subtitles:
        if (_selectedEpisode.value != null) {
          return 'S${_selectedSeason.value}E${_selectedEpisode.value!.episodeNumber}';
        }
        return _selectedItem.value?.title ?? 'Subtitles';
    }
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    return Obx(() {
      switch (_currentView.value) {
        case SubtitleSearchView.search:
          return _buildMovieList(theme, colorScheme);
        case SubtitleSearchView.seasons:
          return _buildSeasonsList(theme, colorScheme);
        case SubtitleSearchView.episodes:
          return _buildEpisodesList(theme, colorScheme);
        case SubtitleSearchView.subtitles:
          return _buildSubtitleList(theme, colorScheme);
      }
    });
  }

  Widget _buildMovieList(ThemeData theme, ColorScheme colorScheme) {
    return Obx(() {
      if (_searchResults.isEmpty && !_isLoadingSearch.value) {
        return _buildEmptyState(
          Icons.search_off,
          'No results found',
          'Try searching with different keywords',
          theme,
          colorScheme,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final item = _searchResults[index];
          return _buildMovieCard(item, theme, colorScheme);
        },
      );
    });
  }

  Widget _buildSeasonsList(ThemeData theme, ColorScheme colorScheme) {
    return Obx(() {
      if (_seasons.isEmpty && !_isLoadingEpisodes.value) {
        return _buildEmptyState(
          Icons.tv_off,
          'No seasons found',
          'This might be a movie or data is unavailable',
          theme,
          colorScheme,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _seasons.length,
        itemBuilder: (context, index) {
          final seasonNumber = _seasons[index];
          final seasonEpisodes =
              _episodes.where((ep) => ep.season == seasonNumber).length;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            ),
            child: InkWell(
              onTap: _isLoading
                  ? null
                  : () {
                      _selectedSeason.value = seasonNumber;
                      _currentView.value = SubtitleSearchView.episodes;
                    },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'S$seasonNumber',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Season $seasonNumber',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$seasonEpisodes episodes',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: ExpressiveLoadingIndicator(),
                      )
                    else
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildEpisodesList(ThemeData theme, ColorScheme colorScheme) {
    final episodesForSeason = _episodesForSeason;

    if (episodesForSeason.isEmpty) {
      return _buildEmptyState(
        Icons.tv_off,
        'No episodes found',
        'No episodes available for this season',
        theme,
        colorScheme,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: episodesForSeason.length,
      itemBuilder: (context, index) {
        final episode = episodesForSeason[index];
        return _buildEpisodeCard(episode, theme, colorScheme);
      },
    );
  }

  Widget _buildEpisodeCard(
      ImdbEpisode episode, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: _isLoading
            ? null
            : () {
                _selectedEpisode.value = episode;
                _searchEpisodeSubtitles(
                  _selectedItem.value!.id,
                  episode.season!,
                  episode.episodeNumber!,
                );
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildEpisodeImage(episode, colorScheme, width: 80, height: 45),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'E${episode.episodeNumber ?? '?'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (episode.aggregateRating != null) ...[
                          Icon(Icons.star,
                              size: 12, color: colorScheme.primary),
                          const SizedBox(width: 2),
                          Text(
                            episode.aggregateRating!.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      episode.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (episode.plot != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        episode.plot!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (_isLoading && _selectedEpisode.value == episode)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: ExpressiveLoadingIndicator(),
                )
              else
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleList(ThemeData theme, ColorScheme colorScheme) {
    return Obx(() {
      if (_subtitles.isEmpty && !_isLoadingSubtitles.value) {
        return _buildEmptyState(
          Icons.subtitles_off,
          'No subtitles found',
          'Try searching for a different movie or TV show',
          theme,
          colorScheme,
        );
      }

      final filteredSubs = _filteredSubtitles;
      if (filteredSubs.isEmpty && !_isLoadingSubtitles.value) {
        return _buildEmptyState(
          Icons.filter_list_off,
          'No subtitles match your filter',
          'Try selecting a different filter',
          theme,
          colorScheme,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filteredSubs.length,
        itemBuilder: (context, index) {
          final subtitle = filteredSubs[index];
          return _buildSubtitleCard(subtitle, theme, colorScheme);
        },
      );
    });
  }

  Widget _buildMovieCard(
      ImdbItem item, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: _isLoading
            ? null
            : () {
                _selectedItem.value = item;
                _loadEpisodes(item.id);
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildPosterImage(item, colorScheme, width: 50, height: 75),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.startYear ?? 'N/A'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading && _selectedItem.value == item)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: ExpressiveLoadingIndicator(),
                )
              else
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleCard(
      OnlineSubtitle subtitle, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: _isLoading
            ? null
            : () {
                widget.controller.addOnlineSub(subtitle);
                _subtitles.remove(subtitle);
                setState(() {});
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: subtitle.flagUrl,
                      width: 24,
                      height: 18,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 24,
                        height: 18,
                        color: colorScheme.surfaceVariant,
                        child: Icon(Icons.flag,
                            size: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subtitle.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subtitle.format,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.source,
                      size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    subtitle.source,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPosterImage(ImdbItem item, ColorScheme colorScheme,
      {required double width, required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: height,
        color: colorScheme.surfaceVariant,
        child: item.image != null
            ? CachedNetworkImage(
                imageUrl: item.image!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Icon(Icons.movie, color: colorScheme.onSurfaceVariant),
              )
            : Icon(Icons.movie, color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildEpisodeImage(ImdbEpisode episode, ColorScheme colorScheme,
      {required double width, required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: height,
        color: colorScheme.surfaceVariant,
        child: episode.image != null
            ? CachedNetworkImage(
                imageUrl: episode.image!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Icon(Icons.tv, color: colorScheme.onSurfaceVariant),
              )
            : Icon(Icons.tv, color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildEmptyState(
    IconData icon,
    String title,
    String subtitle,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
