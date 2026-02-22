import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/screens/search/widgets/search_filter_selector.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class SearchFilterConstants {
  static Map<String, int> animeStreamingServices = {};
  static Map<String, Map<String, List<int>>> mangaReadableOnServices = {};

  static void updateStreamingServices(List<Map<String, dynamic>> services) {
    final animeServices = <String, int>{};
    final mangaByLang = <String, Map<String, List<int>>>{};

    for (final s in services) {
      final id = s['id'] as int;
      final site = s['site'] as String;
      final lang = s['language'] as String?;

      animeServices[site] = id;

      final langKey = (lang ?? 'GLOBAL').toUpperCase();
      mangaByLang.putIfAbsent(langKey, () => {});
      mangaByLang[langKey]!.putIfAbsent(site, () => []);
      mangaByLang[langKey]![site]!.add(id);
    }

    animeStreamingServices = animeServices;
    mangaReadableOnServices = mangaByLang;
  }

  static String formatSort(String sortBy) {
    switch (sortBy) {
      case 'SCORE_DESC':
        return 'Score ↓';
      case 'SCORE':
        return 'Score ↑';
      case 'POPULARITY_DESC':
        return 'Popularity ↓';
      case 'POPULARITY':
        return 'Popularity ↑';
      case 'TRENDING_DESC':
        return 'Trending ↓';
      case 'TRENDING':
        return 'Trending ↑';
      case 'START_DATE_DESC':
        return 'Newest';
      case 'START_DATE':
        return 'Oldest';
      case 'TITLE_ROMAJI':
        return 'Title A-Z';
      case 'TITLE_ROMAJI_DESC':
        return 'Title Z-A';
      default:
        return sortBy;
    }
  }

  static String formatStatus(String status, {bool isManga = false}) {
    switch (status) {
      case 'FINISHED':
        return 'Finished';
      case 'RELEASING':
        return isManga ? 'Releasing' : 'Airing';
      case 'NOT_YET_RELEASED':
        return isManga ? 'Not Yet Released' : 'Not Yet Aired';
      case 'HIATUS':
        return 'Hiatus';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  static String formatFormat(String format, {bool isManga = false}) {
    if (isManga) {
      switch (format) {
        case 'MANGA':
          return 'Manga';
        case 'NOVEL':
          return 'Light Novel';
        case 'ONE_SHOT':
          return 'One Shot';
        default:
          return format;
      }
    } else {
      switch (format) {
        case 'TV':
          return 'TV Show';
        case 'TV_SHORT':
          return 'TV Short';
        case 'MOVIE':
          return 'Movie';
        case 'SPECIAL':
          return 'Special';
        case 'OVA':
          return 'OVA';
        case 'ONA':
          return 'ONA';
        case 'MUSIC':
          return 'Music';
        default:
          return format;
      }
    }
  }

  static String formatCountry(String country) {
    switch (country) {
      case 'JP':
        return 'Japan';
      case 'KR':
        return 'South Korea';
      case 'CN':
        return 'China';
      case 'TW':
        return 'Taiwan';
      default:
        return country;
    }
  }
}

enum ServiceType { anilist, mal }

class FilterConfig {
  const FilterConfig._(
      {required this.serviceType,
      required this.isManga,
      this.supportsYear = true,
      this.supportsGenres = true,
      this.supportsTags = true,
      this.supportsSeason = true,
      this.supportsCountry = false,
      this.supportsSource = false,
      this.supportsStreaming = false,
      this.supportsRanges = false,
      this.supportsOnList = false,
      this.supportsAdult = false,
      this.supportsExclude = false});

  final ServiceType serviceType;
  final bool isManga;
  final bool supportsYear;
  final bool supportsGenres;
  final bool supportsTags;
  final bool supportsSeason;
  final bool supportsCountry;
  final bool supportsSource;
  final bool supportsStreaming;
  final bool supportsRanges;
  final bool supportsOnList;
  final bool supportsAdult;
  final bool supportsExclude;

  static const anilistAnime = FilterConfig._(
    serviceType: ServiceType.anilist,
    isManga: false,
    supportsCountry: true,
    supportsSource: true,
    supportsStreaming: true,
    supportsRanges: true,
    supportsOnList: true,
    supportsAdult: true,
    supportsExclude: true,
  );

  static const anilistManga = FilterConfig._(
    serviceType: ServiceType.anilist,
    isManga: true,
    supportsSeason: false,
    supportsCountry: true,
    supportsSource: true,
    supportsStreaming: true,
    supportsRanges: true,
    supportsOnList: true,
    supportsAdult: true,
    supportsExclude: true,
  );

  static const malAnime = FilterConfig._(
    serviceType: ServiceType.mal,
    isManga: false,
    supportsYear: true,
    supportsGenres: true,
    supportsTags: false,
  );

  static const malManga = FilterConfig._(
    serviceType: ServiceType.mal,
    isManga: true,
    supportsYear: true,
    supportsGenres: true,
    supportsSeason: false,
    supportsTags: false,
  );
}

void showFilterBottomSheet(
    BuildContext context, Function(dynamic args) onApplyFilter,
    {Map<String, dynamic>? currentFilters,
    String mediaType = 'anime',
    FilterConfig? config}) {
  final resolved = config ??
      (mediaType == 'manga'
          ? FilterConfig.anilistManga
          : FilterConfig.anilistAnime);

  prefetchFilterMeta(mediaType: mediaType, config: resolved);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return FuturisticFilterSheet(
        onApplyFilter: onApplyFilter,
        currentFilters: currentFilters,
        mediaType: mediaType,
        config: resolved,
      );
    },
  );
}

void prefetchFilterMeta({
  String mediaType = 'anime',
  FilterConfig? config,
}) {
  final resolved = config ??
      (mediaType == 'manga'
          ? FilterConfig.anilistManga
          : FilterConfig.anilistAnime);

  if (resolved.serviceType == ServiceType.anilist) {
    AnilistData.fetchFilterData(isManga: resolved.isManga);
  } else {
    AnilistData.fetchMalFilterData(isManga: resolved.isManga);
  }
}

class FuturisticFilterSheet extends StatefulWidget {
  const FuturisticFilterSheet({
    super.key,
    required this.onApplyFilter,
    this.currentFilters,
    this.mediaType = 'anime',
    required this.config,
  });

  final Function(dynamic args) onApplyFilter;
  final Map<String, dynamic>? currentFilters;
  final String mediaType;
  final FilterConfig config;

  @override
  State<FuturisticFilterSheet> createState() => _FuturisticFilterSheetState();
}

class _FuturisticFilterSheetState extends State<FuturisticFilterSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isGenreGrid = false;
  bool _isFilterDataLoaded = false;

  Map<String, Map<String, String>> sortOptions = {};

  List<String> seasons = [];
  List<String> animeStatuses = [];
  List<String> mangaStatuses = [];
  List<String> animeFormats = [];
  List<String> mangaFormats = [];
  List<String> animeSources = [];
  List<String> mangaSources = [];
  List<String> countries = [];

  static String _enumToLabel(String value) => value
      .split('_')
      .map((p) => p[0] + p.substring(1).toLowerCase())
      .join(' ');

  
  static const _sortAllowlist = {
    'TITLE_ROMAJI',
    'POPULARITY',
    'TRENDING',
    'SCORE',
    'START_DATE',
  };

 
  static const _sortLabelOverrides = {
    'TITLE_ROMAJI': 'Title',
    'POPULARITY': 'Popularity',
    'TRENDING': 'Trending',
    'SCORE': 'Score',
    'START_DATE': 'Start Date',
  };

  static Map<String, Map<String, String>> _buildSortOptions(
      List<String> rawSorts) {
    final pairs = <String, Map<String, String>>{};
    for (final base in _sortAllowlist) {
      final hasAsc = rawSorts.contains(base);
      final hasDesc = rawSorts.contains('${base}_DESC');
      if (!hasAsc && !hasDesc) continue;
      final desc = hasDesc ? '${base}_DESC' : base;
      final asc = hasAsc ? base : desc;
      final label = _sortLabelOverrides[base] ?? _enumToLabel(base);
      pairs[label] = {'desc': desc, 'asc': asc, 'label': base};
    }
    return pairs;
  }

  final Map<String, String> animeStatusLabels = {
    'FINISHED': 'Finished',
    'RELEASING': 'Airing',
    'NOT_YET_RELEASED': 'Not Yet Aired',
    'CANCELLED': 'Cancelled',
    'HIATUS': 'Hiatus',
  };
  final Map<String, String> mangaStatusLabels = {
    'FINISHED': 'Finished',
    'RELEASING': 'Releasing',
    'NOT_YET_RELEASED': 'Not Yet Released',
    'HIATUS': 'Hiatus',
    'CANCELLED': 'Cancelled',
  };
  final Map<String, String> animeFormatLabels = {
    'TV': 'TV Show',
    'TV_SHORT': 'TV Short',
    'MOVIE': 'Movie',
    'SPECIAL': 'Special',
    'OVA': 'OVA',
    'ONA': 'ONA',
    'MUSIC': 'Music',
  };
  final Map<String, String> mangaFormatLabels = {
    'MANGA': 'Manga',
    'NOVEL': 'Light Novel',
    'ONE_SHOT': 'One Shot',
  };
  final Map<String, String> animeSourceLabels = {
    'ORIGINAL': 'Original',
    'MANGA': 'Manga',
    'LIGHT_NOVEL': 'Light Novel',
    'VISUAL_NOVEL': 'Visual Novel',
    'VIDEO_GAME': 'Video Game',
    'NOVEL': 'Novel',
    'DOUJINSHI': 'Doujinshi',
    'ANIME': 'Anime',
    'WEB_NOVEL': 'Web Novel',
    'LIVE_ACTION': 'Live Action',
    'GAME': 'Game',
    'COMIC': 'Comic',
    'MULTIMEDIA_PROJECT': 'Multimedia Project',
    'PICTURE_BOOK': 'Picture Book',
    'OTHER': 'Other',
  };
  final Map<String, String> mangaSourceLabels = {
    'ORIGINAL': 'Original',
    'MANGA': 'Manga',
    'LIGHT_NOVEL': 'Light Novel',
    'VISUAL_NOVEL': 'Visual Novel',
    'VIDEO_GAME': 'Video Game',
    'NOVEL': 'Novel',
    'DOUJINSHI': 'Doujinshi',
    'WEB_NOVEL': 'Web Novel',
    'LIVE_ACTION': 'Live Action',
    'GAME': 'Game',
    'COMIC': 'Comic',
    'MULTIMEDIA_PROJECT': 'Multimedia Project',
    'PICTURE_BOOK': 'Picture Book',
    'OTHER': 'Other',
  };
  static const Map<String, String> _countryLabels = {
    'JP': 'Japan',
    'KR': 'South Korea',
    'CN': 'China',
    'TW': 'Taiwan',
  };

  List<String> genres = [];
  List<String> allTags = [];

  String? selectedSortBy;
  String? selectedSortType;
  String? selectedSeason;
  String? selectedStatus;
  String? selectedFormat;
  List<String> selectedGenres = [];
  List<String> selectedTags = [];
  String? selectedCountry;
  List<int> selectedStreamingOn = [];
  int? selectedYear;
  RangeValues yearRange = const RangeValues(1940, 2027);
  bool useYearRange = false;
  RangeValues episodeRange = const RangeValues(0, 150);
  bool useEpisodeRange = false;
  RangeValues durationRange = const RangeValues(0, 170);
  bool useDurationRange = false;
  RangeValues chaptersRange = const RangeValues(0, 500);
  bool useChaptersRange = false;
  RangeValues volumesRange = const RangeValues(0, 50);
  bool useVolumesRange = false;
  String? selectedSource;
  bool onlyShowMine = false;
  bool hideMine = false;
  String? _pendingSortRestore;

  int _minYear = 1940;
  double _maxEpisodes = 150;
  double _maxDuration = 170;
  double _maxChapters = 500;
  double _maxVolumes = 50;

  List<String> get formats =>
      widget.mediaType == 'manga' ? mangaFormats : animeFormats;
  Map<String, String> get formatLabels =>
      widget.mediaType == 'manga' ? mangaFormatLabels : animeFormatLabels;
  List<String> get statuses =>
      widget.mediaType == 'manga' ? mangaStatuses : animeStatuses;
  Map<String, String> get statusLabels =>
      widget.mediaType == 'manga' ? mangaStatusLabels : animeStatusLabels;
  bool get isManga => widget.mediaType == 'manga';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentFilters();
    _fetchFilterData();
  }

  FilterConfig get cfg => widget.config;

  Future<void> _fetchFilterData() async {
    if (cfg.serviceType == ServiceType.anilist) {
      final data = await AnilistData.fetchFilterData(isManga: isManga);
      if (mounted) {
        setState(() {
          genres = (data['genres'] as List<String>?) ?? [];
          allTags = (data['tags'] as List<String>?) ?? [];

          final allFormats = (data['formats'] as List<String>?) ?? [];
          animeFormats = allFormats
              .where((f) => !['MANGA', 'NOVEL', 'ONE_SHOT'].contains(f))
              .toList();
          mangaFormats = allFormats
              .where((f) => ['MANGA', 'NOVEL', 'ONE_SHOT'].contains(f))
              .toList();

          final allStatuses = (data['statuses'] as List<String>?) ?? [];
          animeStatuses =
              allStatuses.where((s) => s != 'HIATUS').toList();
          mangaStatuses = allStatuses;

          final allSources = (data['sources'] as List<String>?) ?? [];
          final sourceSet = allSources.toSet();
          
          animeSources = [
            ...animeSourceLabels.keys.where((s) => sourceSet.contains(s)),
            ...allSources.where((s) => !animeSourceLabels.containsKey(s)),
          ];
          mangaSources = animeSources
              .where((s) => s != 'ANIME')
              .toList();

          seasons = (data['seasons'] as List<String>?) ?? [];

          final rawSorts = (data['sortOptions'] as List<String>?) ?? [];
          sortOptions = _buildSortOptions(rawSorts);
          _restoreSortFromRawValue();

          countries = (data['countries'] as List<String>?) ?? [];

          _minYear = (data['minYear'] as int?) ?? 1940;
          _maxEpisodes = (data['maxEpisodes'] as double?) ?? 150;
          _maxDuration = (data['maxDuration'] as double?) ?? 170;
          _maxChapters = (data['maxChapters'] as double?) ?? 500;
          _maxVolumes = (data['maxVolumes'] as double?) ?? 50;

          if (!useYearRange && selectedYear == null) {
            yearRange =
                RangeValues(_minYear.toDouble(), DateTime.now().year + 1.0);
          }
          if (!useEpisodeRange) {
            episodeRange = RangeValues(0, _maxEpisodes);
          }
          if (!useDurationRange) {
            durationRange = RangeValues(0, _maxDuration);
          }
          if (!useChaptersRange) {
            chaptersRange = RangeValues(0, _maxChapters);
          }
          if (!useVolumesRange) {
            volumesRange = RangeValues(0, _maxVolumes);
          }

          final services =
              (data['streamingServices'] as List<Map<String, dynamic>>?) ?? [];
          SearchFilterConstants.updateStreamingServices(services);

          _isFilterDataLoaded = true;
        });
      }
    } else {
      final data = await AnilistData.fetchMalFilterData(isManga: isManga);
      if (mounted) {
        setState(() {
          genres = (data['genres'] as List<String>?) ?? [];
          _isFilterDataLoaded = true;
        });
      }
    }
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideController.forward();
    _fadeController.forward();
  }

  void _loadCurrentFilters() {
    if (widget.currentFilters != null) {
      final filters = widget.currentFilters!;

      String? currentSort;
      if (filters['sort'] is List && (filters['sort'] as List).isNotEmpty) {
        currentSort = (filters['sort'] as List).first.toString();
      } else if (filters['sort'] is String) {
        currentSort = filters['sort'];
      }
      if (currentSort != null) {
        _pendingSortRestore = currentSort;
        _restoreSortFromRawValue();
      }

      selectedSeason = filters['season'];
      selectedStatus = filters['status'];
      selectedCountry = filters['countryOfOrigin'];
      onlyShowMine = filters['onList'] ?? false;
      hideMine = filters['onList'] == false ? true : false;

      if (filters['source'] is String) {
        selectedSource = filters['source'];
      }

      if (filters['format'] is List) {
        selectedFormat = (filters['format'] as List).first?.toString();
      } else if (filters['format'] is String) {
        selectedFormat = filters['format'];
      }
      if (filters['genres'] != null && filters['genres'] is List) {
        selectedGenres = List<String>.from(filters['genres']);
      }
      if (filters['tags'] is List) {
        selectedTags = List<String>.from(filters['tags']);
      }
      if (filters['licensedBy'] is List) {
        selectedStreamingOn = List<int>.from(filters['licensedBy']);
      }

      final yearVal = filters['year'];
      if (yearVal is String && yearVal.endsWith('%')) {
        selectedYear = int.tryParse(yearVal.replaceAll('%', ''));
      } else if (yearVal is int) {
        selectedYear = yearVal;
      }

      final yg = filters['yearGreater'];
      final yl = filters['yearLesser'];
      if (yg != null && yl != null) {
        final startYear = (yg as int) ~/ 10000;
        final endYear = ((yl as int) ~/ 10000) - 1;
        yearRange = RangeValues(startYear.toDouble(), endYear.toDouble());
        useYearRange = true;
      }

      final eg = filters['episodeGreater'];
      final el = filters['episodeLesser'];
      if (eg != null && el != null) {
        episodeRange =
            RangeValues((eg as int).toDouble(), (el as int).toDouble());
        useEpisodeRange = true;
      }

      final dg = filters['durationGreater'];
      final dl = filters['durationLesser'];
      if (dg != null && dl != null) {
        durationRange =
            RangeValues((dg as int).toDouble(), (dl as int).toDouble());
        useDurationRange = true;
      }

      final cg = filters['chapterGreater'];
      final cl = filters['chapterLesser'];
      if (cg != null && cl != null) {
        chaptersRange =
            RangeValues((cg as int).toDouble(), (cl as int).toDouble());
        useChaptersRange = true;
      }

      final vg = filters['volumeGreater'];
      final vl = filters['volumeLesser'];
      if (vg != null && vl != null) {
        volumesRange =
            RangeValues((vg as int).toDouble(), (vl as int).toDouble());
        useVolumesRange = true;
      }
    }
  }

  void _restoreSortFromRawValue() {
    if (_pendingSortRestore == null || sortOptions.isEmpty) return;
    for (final sortKey in sortOptions.keys) {
      if (sortOptions[sortKey]!['desc'] == _pendingSortRestore) {
        selectedSortBy = sortKey;
        selectedSortType = 'desc';
        _pendingSortRestore = null;
        return;
      } else if (sortOptions[sortKey]!['asc'] == _pendingSortRestore) {
        selectedSortBy = sortKey;
        selectedSortType = 'asc';
        _pendingSortRestore = null;
        return;
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              snap: true,
              snapSizes: const [0.5],
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(
                      color:
                          colorScheme.primary.opaque(0.2, iReallyMeanIt: true),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: _buildHeader(),
                      ),
                      Expanded(
                        child: _isFilterDataLoaded
                            ? SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (sortOptions.isNotEmpty) ...[
                                      _buildSortSection(),
                                      const SizedBox(height: 24),
                                    ],
                                    _buildFiltersSection(),
                                    const SizedBox(height: 24),
                                    if (cfg.supportsYear) ...[
                                      _buildYearSection(),
                                      const SizedBox(height: 24),
                                    ],
                                    if (cfg.supportsRanges && !isManga)
                                      _buildAnimeRangeSection(),
                                    if (cfg.supportsRanges && isManga)
                                      _buildMangaRangeSection(),
                                    if (cfg.supportsRanges)
                                      const SizedBox(height: 24),
                                    if (cfg.supportsGenres) ...[
                                      _buildGenresSection(),
                                      const SizedBox(height: 24),
                                    ],
                                    if (cfg.supportsTags) ...[
                                      _buildTagsSection(),
                                      const SizedBox(height: 24),
                                    ],
                                    if (cfg.supportsStreaming) ...[
                                      _buildStreamingSection(),
                                      const SizedBox(height: 24),
                                    ],
                                    if (cfg.supportsAdult ||
                                        cfg.supportsOnList) ...[
                                      _buildTogglesSection(),
                                      const SizedBox(height: 20),
                                    ],
                                  ],
                                ),
                              )
                            : const Center(child: CircularProgressIndicator()),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: _buildActionButtons(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> get _flatServiceMap {
    if (!isManga) return SearchFilterConstants.animeStreamingServices;
    final flat = <String, List<int>>{};
    for (var group in SearchFilterConstants.mangaReadableOnServices.values) {
      flat.addAll(group);
    }
    return flat;
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (selectedSortBy != null) count++;
    if (selectedFormat != null) count++;
    if (selectedSeason != null) count++;
    if (selectedStatus != null) count++;
    if (selectedCountry != null) count++;
    if (selectedYear != null || useYearRange) count++;
    if (useEpisodeRange) count++;
    if (useDurationRange) count++;
    if (useChaptersRange) count++;
    if (useVolumesRange) count++;
    if (selectedSource != null) count++;
    if (onlyShowMine || hideMine) count++;
    count += selectedGenres.length;
    count += selectedTags.length;
    count += selectedStreamingOn.length;
    return count;
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.primary.opaque(0.1, iReallyMeanIt: true),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'FILTERS',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              if (_getActiveFilterCount() > 0) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${_getActiveFilterCount()}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, [Widget? trailing]) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.opaque(0.1, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('SORT', Icons.sort_rounded),
        Row(
          children: [
            Expanded(flex: 3, child: _buildSortSelector()),
            const SizedBox(width: 12),
            _buildSortDirectionToggle(),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('FILTERS', Icons.filter_list_rounded),
        if (cfg.supportsSeason) ...[
          _buildNeonSelector(
            hint: 'Season',
            value: selectedSeason,
            options: seasons,
            optionLabels: {
              'WINTER': '❄️ Winter',
              'SPRING': '🌸 Spring',
              'SUMMER': '☀️ Summer',
              'FALL': '🍂 Fall',
            },
            onChanged: (value) => setState(() => selectedSeason = value),
            icon: Icons.calendar_today_rounded,
          ),
          const SizedBox(height: 12),
        ],
        _buildNeonSelector(
          hint: isManga ? 'Publishing Status' : 'Airing Status',
          value: selectedStatus,
          options: statuses,
          optionLabels: statusLabels,
          onChanged: (value) => setState(() => selectedStatus = value),
          icon: Icons.info_outline_rounded,
        ),
        if (cfg.supportsCountry) ...[
          const SizedBox(height: 12),
          _buildNeonSelector(
            hint: 'Country of Origin',
            value: selectedCountry,
            options: countries,
            optionLabels: _countryLabels,
            onChanged: (value) => setState(() => selectedCountry = value),
            icon: Icons.flag_rounded,
          ),
        ],
        const SizedBox(height: 12),
        _buildNeonSelector(
          hint: 'Format',
          value: selectedFormat,
          options: formats,
          optionLabels: formatLabels,
          onChanged: (value) => setState(() => selectedFormat = value),
          icon: isManga ? Icons.menu_book_rounded : Icons.video_library_rounded,
        ),
        if (cfg.supportsSource) ...[
          const SizedBox(height: 12),
          _buildNeonSelector(
            hint: 'Source',
            value: selectedSource,
            options: isManga ? mangaSources : animeSources,
            optionLabels: isManga ? mangaSourceLabels : animeSourceLabels,
            onChanged: (value) => setState(() => selectedSource = value),
            icon: Icons.source_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildYearSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('YEAR', Icons.date_range_rounded),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Use Year Range',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Switch(
              value: useYearRange,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (v) => setState(() {
                useYearRange = v;
                if (v) selectedYear = null;
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!useYearRange)
          _buildNeonSelector(
            hint: 'Year',
            value: selectedYear?.toString(),
            options: List.generate(DateTime.now().year + 1 - _minYear + 1,
                (i) => (_minYear + i).toString()).reversed.toList(),
            optionLabels: {},
            onChanged: (v) =>
                setState(() => selectedYear = v != null ? int.parse(v) : null),
            icon: Icons.calendar_month_rounded,
          )
        else
          _buildRangeSlider(
            label:
                '${yearRange.start.toInt()} – ${yearRange.end.toInt() >= DateTime.now().year + 1 ? "${DateTime.now().year + 1}+" : yearRange.end.toInt()}',
            values: yearRange,
            min: _minYear.toDouble(),
            max: DateTime.now().year + 1.0,
            divisions: DateTime.now().year + 1 - _minYear,
            onChanged: (v) => setState(() => yearRange = v),
          ),
      ],
    );
  }

  Widget _buildAnimeRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            'EPISODES & DURATION', Icons.play_circle_outline_rounded),
        _buildSwitchRow(
          label: 'Filter by Episode Count',
          value: useEpisodeRange,
          onChanged: (v) => setState(() => useEpisodeRange = v),
        ),
        if (useEpisodeRange) ...[
          const SizedBox(height: 8),
          _buildRangeSlider(
            label:
                '${episodeRange.start.toInt()} – ${episodeRange.end.toInt() >= _maxEpisodes.toInt() ? "${_maxEpisodes.toInt()}+" : episodeRange.end.toInt()} eps',
            values: episodeRange,
            min: 0,
            max: _maxEpisodes,
            divisions: _maxEpisodes.clamp(1, 200).toInt(),
            onChanged: (v) => setState(() => episodeRange = v),
          ),
        ],
        const SizedBox(height: 12),
        _buildSwitchRow(
          label: 'Filter by Duration (min)',
          value: useDurationRange,
          onChanged: (v) => setState(() => useDurationRange = v),
        ),
        if (useDurationRange) ...[
          const SizedBox(height: 8),
          _buildRangeSlider(
            label:
                '${durationRange.start.toInt()} – ${durationRange.end.toInt() >= _maxDuration.toInt() ? "${_maxDuration.toInt()}+" : durationRange.end.toInt()} min',
            values: durationRange,
            min: 0,
            max: _maxDuration,
            divisions: _maxDuration.clamp(1, 200).toInt(),
            onChanged: (v) => setState(() => durationRange = v),
          ),
        ],
      ],
    );
  }

  Widget _buildMangaRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('CHAPTERS & VOLUMES', Icons.menu_book_rounded),
        _buildSwitchRow(
          label: 'Filter by Chapter Count',
          value: useChaptersRange,
          onChanged: (v) => setState(() => useChaptersRange = v),
        ),
        if (useChaptersRange) ...[
          const SizedBox(height: 8),
          _buildRangeSlider(
            label:
                '${chaptersRange.start.toInt()} – ${chaptersRange.end.toInt() >= _maxChapters.toInt() ? "${_maxChapters.toInt()}+" : chaptersRange.end.toInt()} chapters',
            values: chaptersRange,
            min: 0,
            max: _maxChapters,
            divisions: _maxChapters.clamp(1, 200).toInt(),
            onChanged: (v) => setState(() => chaptersRange = v),
          ),
        ],
        const SizedBox(height: 12),
        _buildSwitchRow(
          label: 'Filter by Volume Count',
          value: useVolumesRange,
          onChanged: (v) => setState(() => useVolumesRange = v),
        ),
        if (useVolumesRange) ...[
          const SizedBox(height: 8),
          _buildRangeSlider(
            label:
                '${volumesRange.start.toInt()} – ${volumesRange.end.toInt() >= _maxVolumes.toInt() ? "${_maxVolumes.toInt()}+" : volumesRange.end.toInt()} volumes',
            values: volumesRange,
            min: 0,
            max: _maxVolumes,
            divisions: _maxVolumes.clamp(1, 200).toInt(),
            onChanged: (v) => setState(() => volumesRange = v),
          ),
        ],
      ],
    );
  }

  Widget _buildGenresSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'GENRES',
          Icons.category_rounded,
          IconButton(
            onPressed: () => setState(() => _isGenreGrid = !_isGenreGrid),
            icon: Icon(
              _isGenreGrid
                  ? Icons.view_stream_rounded
                  : Icons.grid_view_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        if (_isGenreGrid)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.opaque(0.3, iReallyMeanIt: true),
                width: 1,
              ),
              color: colorScheme.surface.opaque(0.5, iReallyMeanIt: true),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: genres.map((genre) => _buildGenreChip(genre)).toList(),
            ),
          )
        else
          Container(
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.opaque(0.3, iReallyMeanIt: true),
                width: 1,
              ),
              color: colorScheme.surface.opaque(0.5, iReallyMeanIt: true),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SuperListView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                children:
                    genres.map((genre) => _buildGenreChip(genre)).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGenreChip(String genre) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = selectedGenres.contains(genre);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(
          genre,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
        selected: isSelected,
        checkmarkColor: colorScheme.onPrimary,
        selectedColor: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.opaque(0.3),
          width: 1,
        ),
        onSelected: (selected) {
          setState(() {
            selected ? selectedGenres.add(genre) : selectedGenres.remove(genre);
          });
        },
      ),
    );
  }

  Widget _buildTagsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasSelected = selectedTags.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('TAGS', Icons.label_rounded),
        if (hasSelected) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: selectedTags
                .map((t) => Chip(
                      label: Text(t,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600)),
                      backgroundColor: colorScheme.primary,
                      deleteIconColor: colorScheme.onPrimary,
                      onDeleted: () => setState(() => selectedTags.remove(t)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: _buildTappableBox(
            isActive: hasSelected,
            onTap: _showTagsSheet,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded,
                    size: 20,
                    color: hasSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface
                            .opaque(0.7, iReallyMeanIt: true)),
                const SizedBox(width: 8),
                Text(
                  hasSelected
                      ? 'Edit Tags (${selectedTags.length})'
                      : 'Add Tags',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasSelected
                        ? colorScheme.onSurface
                        : colorScheme.onSurface
                            .opaque(0.5, iReallyMeanIt: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreamingSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasSelected = selectedStreamingOn.isNotEmpty;
    final currentServiceMap = _flatServiceMap;

    final selectedNames = currentServiceMap.entries
        .where((e) =>
            selectedStreamingOn.contains(e.value) ||
            (e.value is List &&
                selectedStreamingOn.contains((e.value as List).first)))
        .map((e) => e.key)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            isManga ? 'READABLE ON' : 'STREAMING ON', Icons.live_tv_rounded),
        if (hasSelected) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: selectedNames
                .map((name) => Chip(
                      label: Text(name,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600)),
                      backgroundColor: colorScheme.primary,
                      deleteIconColor: colorScheme.onPrimary,
                      onDeleted: () => setState(() {
                        final ids = currentServiceMap[name];
                        if (ids is List) {
                          for (var id in ids) {
                            selectedStreamingOn.remove(id);
                          }
                        } else {
                          selectedStreamingOn.remove(ids);
                        }
                      }),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: _buildTappableBox(
            isActive: hasSelected,
            onTap: _showStreamingSheet,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded,
                    size: 20,
                    color: hasSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface
                            .opaque(0.7, iReallyMeanIt: true)),
                const SizedBox(width: 8),
                Text(
                  hasSelected
                      ? (isManga
                          ? 'Edit Platforms (${selectedStreamingOn.length})'
                          : 'Edit Services (${selectedStreamingOn.length})')
                      : (isManga
                          ? 'Select Reading Platform'
                          : 'Select Streaming Service'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasSelected
                        ? colorScheme.onSurface
                        : colorScheme.onSurface
                            .opaque(0.5, iReallyMeanIt: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTogglesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('OPTIONS', Icons.toggle_on_rounded),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildToggleChip(
                label: isManga ? '📖 My Manga Only' : '📺 My Anime Only',
                value: onlyShowMine,
                onTap: () => setState(() {
                      onlyShowMine = !onlyShowMine;
                      if (onlyShowMine) hideMine = false;
                    })),
            _buildToggleChip(
                label: isManga ? '🚫 Hide My Manga' : '🚫 Hide My Anime',
                value: hideMine,
                onTap: () => setState(() {
                      hideMine = !hideMine;
                      if (hideMine) onlyShowMine = false;
                    })),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? colorScheme.primary
                : colorScheme.outline.opaque(0.3, iReallyMeanIt: true),
            width: value ? 2 : 1,
          ),
          color: value
              ? colorScheme.primary.opaque(0.1, iReallyMeanIt: true)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.check_circle_rounded,
                    size: 16, color: colorScheme.primary),
              ),
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: value
                        ? colorScheme.primary
                        : colorScheme.onSurface
                            .opaque(0.7, iReallyMeanIt: true))),
          ],
        ),
      ),
    );
  }

  Widget _buildTappableBox({
    required bool isActive,
    required Widget child,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? colorScheme.primary.opaque(0.6, iReallyMeanIt: true)
              : colorScheme.outline.opaque(0.3, iReallyMeanIt: true),
          width: isActive ? 2 : 1,
        ),
        color: isActive
            ? colorScheme.primary.opaque(0.05, iReallyMeanIt: true)
            : colorScheme.surface.opaque(0.5, iReallyMeanIt: true),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  Widget _buildRangeSlider({
    required String label,
    required RangeValues values,
    required double min,
    required double max,
    required int divisions,
    required Function(RangeValues) onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary, fontWeight: FontWeight.w700)),
        ),
        RangeSlider(
          values: values,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: colorScheme.primary,
          inactiveColor: colorScheme.primary.opaque(0.2, iReallyMeanIt: true),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        Switch(
            value: value,
            activeColor: colorScheme.primary,
            onChanged: onChanged),
      ],
    );
  }

  Widget _buildNeonSelector({
    required String hint,
    required String? value,
    required List<String> options,
    required Map<String, String> optionLabels,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasValue = value != null;
    final displayLabel =
        hasValue ? (optionLabels[value] ?? value) : 'Select $hint';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasValue
              ? colorScheme.primary.opaque(0.6, iReallyMeanIt: true)
              : colorScheme.outline.opaque(0.3, iReallyMeanIt: true),
          width: hasValue ? 2 : 1,
        ),
        color: hasValue
            ? colorScheme.primary.opaque(0.05, iReallyMeanIt: true)
            : colorScheme.surface.opaque(0.5, iReallyMeanIt: true),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showNeonBottomSheet(
            title: hint,
            options: options,
            optionLabels: optionLabels,
            selectedValue: value,
            onSelected: onChanged,
            icon: icon,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: hasValue
                      ? colorScheme.primary
                      : colorScheme.onSurface.opaque(0.7, iReallyMeanIt: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hint.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface
                              .opaque(0.7, iReallyMeanIt: true),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: hasValue
                              ? colorScheme.onSurface
                              : colorScheme.onSurface
                                  .opaque(0.5, iReallyMeanIt: true),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.onSurface.opaque(0.6, iReallyMeanIt: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasValue = selectedSortBy != null;
    final displayText = hasValue ? selectedSortBy! : 'Select Sort';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasValue
              ? colorScheme.primary.opaque(0.6, iReallyMeanIt: true)
              : colorScheme.outline.opaque(0.3, iReallyMeanIt: true),
          width: hasValue ? 2 : 1,
        ),
        color: hasValue
            ? colorScheme.primary.opaque(0.05, iReallyMeanIt: true)
            : colorScheme.surface.opaque(0.5, iReallyMeanIt: true),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _showSortBottomSheet,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.sort_rounded,
                  size: 20,
                  color: hasValue
                      ? colorScheme.primary
                      : colorScheme.onSurface.opaque(0.7, iReallyMeanIt: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SORT BY',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.opaque(0.7),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: hasValue
                              ? colorScheme.onSurface
                              : colorScheme.onSurface
                                  .opaque(0.5, iReallyMeanIt: true),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.onSurface.opaque(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortDirectionToggle() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDescending = selectedSortType == 'desc';
    final isActive = selectedSortBy != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? colorScheme.primary.opaque(0.6, iReallyMeanIt: true)
              : colorScheme.outline.opaque(0.3, iReallyMeanIt: true),
          width: isActive ? 2 : 1,
        ),
        color: isActive
            ? colorScheme.primary.opaque(0.05, iReallyMeanIt: true)
            : colorScheme.surface.opaque(0.5, iReallyMeanIt: true),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isActive
              ? () => setState(
                  () => selectedSortType = isDescending ? 'asc' : 'desc')
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'ORDER',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        colorScheme.onSurface.opaque(0.7, iReallyMeanIt: true),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDescending
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 16,
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurface
                              .opaque(0.5, iReallyMeanIt: true),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getOrderLabel(isDescending),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? colorScheme.onSurface
                            : colorScheme.onSurface
                                .opaque(0.5, iReallyMeanIt: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getOrderLabel(bool isDescending) {
    switch (selectedSortBy) {
      case 'Title':
        return isDescending ? 'Z→A' : 'A→Z';
      case 'Score':
      case 'Popularity':
      case 'Trending':
        return isDescending ? 'High' : 'Low';
      case 'Start Date':
        return isDescending ? 'New' : 'Old';
      default:
        return isDescending ? 'DESC' : 'ASC';
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildNeonButton(
            text: 'RESET',
            icon: Icons.refresh_rounded,
            isPrimary: false,
            onTap: _resetFilters,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildNeonButton(
            text: _getActiveFilterCount() > 0
                ? 'APPLY FILTERS (${_getActiveFilterCount()})'
                : 'APPLY FILTERS',
            icon: Icons.check_rounded,
            isPrimary: true,
            onTap: _applyFilters,
          ),
        ),
      ],
    );
  }

  Widget _buildNeonButton({
    required String text,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary
              ? colorScheme.primary
              : colorScheme.outline.opaque(0.5, iReallyMeanIt: true),
          width: 2,
        ),
        color: isPrimary ? colorScheme.primary : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color:
                      isPrimary ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isPrimary
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    _showNeonBottomSheet(
      title: 'Sort By',
      options: sortOptions.keys.toList(),
      optionLabels: {},
      selectedValue: selectedSortBy,
      onSelected: (value) {
        setState(() {
          selectedSortBy = value;
          selectedSortType ??= 'desc';
        });
      },
      icon: Icons.sort_rounded,
    );
  }

  void _showTagsSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TextEditingController searchCtrl = TextEditingController();
    List<String> filtered = List.from(allTags);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          snap: true,
          snapSizes: const [0.5],
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                  color: colorScheme.primary.opaque(0.3, iReallyMeanIt: true),
                  width: 1),
            ),
            child: Column(
              children: [
                SingleChildScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(3)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.label_rounded,
                                color: colorScheme.primary, size: 24),
                            const SizedBox(width: 8),
                            Text('SELECT TAGS',
                                style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    color: colorScheme.onSurface)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: searchCtrl,
                          onChanged: (q) => setModalState(() {
                            filtered = allTags
                                .where((t) =>
                                    t.toLowerCase().contains(q.toLowerCase()))
                                .toList();
                          }),
                          decoration: InputDecoration(
                            hintText: 'Search tags...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final tag = filtered[i];
                      final isSelected = selectedTags.contains(tag);
                      return CheckboxListTile(
                        title: Text(tag,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500)),
                        value: isSelected,
                        activeColor: colorScheme.primary,
                        onChanged: (v) => setModalState(() => setState(() =>
                            v == true
                                ? selectedTags.add(tag)
                                : selectedTags.remove(tag))),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildNeonButton(
                    text: 'DONE (${selectedTags.length} selected)',
                    icon: Icons.check_rounded,
                    isPrimary: true,
                    onTap: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxTile(MapEntry<String, dynamic> entry, ThemeData theme,
      ColorScheme colorScheme, StateSetter setModalState) {
    return CheckboxListTile(
      title: Text(entry.key,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500)),
      value: selectedStreamingOn.contains(entry.value) ||
          (entry.value is List &&
              selectedStreamingOn.contains((entry.value as List).first)),
      activeColor: colorScheme.primary,
      onChanged: (v) => setModalState(() => setState(() {
            if (v == true) {
              if (entry.value is List) {
                selectedStreamingOn.addAll(entry.value);
              } else {
                selectedStreamingOn.add(entry.value);
              }
            } else {
              if (entry.value is List) {
                for (final id in (entry.value as List)) {
                  selectedStreamingOn.remove(id);
                }
              } else {
                selectedStreamingOn.remove(entry.value);
              }
            }
          })),
    );
  }

  List<Widget> _buildMangaStreamingList(
      ThemeData theme, ColorScheme colorScheme, StateSetter setModalState) {
    List<Widget> list = [];
    for (var langEntry
        in SearchFilterConstants.mangaReadableOnServices.entries) {
      list.add(Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8, left: 16),
        child: Text(
          langEntry.key,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ));
      for (var entry in langEntry.value.entries) {
        list.add(_buildCheckboxTile(entry, theme, colorScheme, setModalState));
      }
    }
    return list;
  }

  void _showStreamingSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          snap: true,
          snapSizes: const [0.6],
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                  color: colorScheme.primary.opaque(0.3, iReallyMeanIt: true),
                  width: 1),
            ),
            child: Column(
              children: [
                SingleChildScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(3)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.live_tv_rounded,
                                color: colorScheme.primary, size: 24),
                            const SizedBox(width: 8),
                            Text(isManga ? 'READABLE ON' : 'STREAMING ON',
                                style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    color: colorScheme.onSurface)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    children: isManga
                        ? _buildMangaStreamingList(
                            theme, colorScheme, setModalState)
                        : SearchFilterConstants.animeStreamingServices.entries
                            .map((entry) => _buildCheckboxTile(
                                entry, theme, colorScheme, setModalState))
                            .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildNeonButton(
                    text: 'DONE',
                    icon: Icons.check_rounded,
                    isPrimary: true,
                    onTap: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNeonBottomSheet({
    required String title,
    required List<String> options,
    required Map<String, String> optionLabels,
    required String? selectedValue,
    required Function(String?) onSelected,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: colorScheme.primary.opaque(0.3, iReallyMeanIt: true),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.opaque(0.1, iReallyMeanIt: true),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.primary
                            .opaque(0.2, iReallyMeanIt: true),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary
                                  .opaque(0.5, iReallyMeanIt: true),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary
                                  .opaque(0.1, iReallyMeanIt: true),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.primary
                                    .opaque(0.3, iReallyMeanIt: true),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            title.toUpperCase(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final label = optionLabels[option] ?? option;
                    final isSelected = selectedValue == option;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FutureisticOptionTile(
                        option: label,
                        isSelected: isSelected,
                        onTap: () {
                          onSelected(option);
                          Navigator.pop(context);
                        },
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _resetFilters() {
    setState(() {
      selectedSortBy = null;
      selectedSortType = null;
      selectedSeason = null;
      selectedStatus = null;
      selectedCountry = null;
      selectedYear = null;
      selectedFormat = null;
      selectedGenres.clear();
      selectedTags.clear();
      selectedStreamingOn.clear();
      useYearRange = false;
      yearRange = RangeValues(_minYear.toDouble(), DateTime.now().year + 1.0);
      useEpisodeRange = false;
      episodeRange = RangeValues(0, _maxEpisodes);
      useDurationRange = false;
      durationRange = RangeValues(0, _maxDuration);
      useChaptersRange = false;
      chaptersRange = RangeValues(0, _maxChapters);
      useVolumesRange = false;
      volumesRange = RangeValues(0, _maxVolumes);
      selectedSource = null;
      onlyShowMine = false;
      hideMine = false;
    });

    _applyFilters(closeSheet: false);
  }

  void _applyFilters({bool closeSheet = true}) {
    List<String>? finalSort;
    if (selectedSortBy != null && selectedSortType != null) {
      final s = sortOptions[selectedSortBy!]![selectedSortType!];
      if (s != null) finalSort = [s];
    }

    final Map<String, dynamic> result = {
      'season': isManga ? null : selectedSeason,
      'sort': finalSort,
      'format': selectedFormat,
      'genres': selectedGenres.isEmpty ? null : selectedGenres,
      'tags': selectedTags.isEmpty ? null : selectedTags,
      'status': selectedStatus,
      'countryOfOrigin': selectedCountry,
      'licensedBy':
          selectedStreamingOn.isEmpty ? null : selectedStreamingOn.toList(),
      'isLicensed': selectedStreamingOn.isNotEmpty ? true : null,
      'onList': onlyShowMine
          ? true
          : hideMine
              ? false
              : null,
      'source': selectedSource,
    };

    if (!useYearRange && selectedYear != null) {
      result['year'] = '$selectedYear%';
    }

    if (useYearRange) {
      result['yearGreater'] = yearRange.start.toInt() * 10000;
      if (yearRange.end < DateTime.now().year + 1) {
        result['yearLesser'] = (yearRange.end.toInt() + 1) * 10000;
      }
    }

    if (!isManga) {
      if (useEpisodeRange) {
        result['episodeGreater'] = episodeRange.start.toInt();
        if (episodeRange.end < _maxEpisodes) {
          result['episodeLesser'] = episodeRange.end.toInt();
        }
      }
      if (useDurationRange) {
        result['durationGreater'] = durationRange.start.toInt();
        if (durationRange.end < _maxDuration) {
          result['durationLesser'] = durationRange.end.toInt();
        }
      }
    } else {
      if (useChaptersRange) {
        result['chapterGreater'] = chaptersRange.start.toInt();
        if (chaptersRange.end < _maxChapters) {
          result['chapterLesser'] = chaptersRange.end.toInt();
        }
      }
      if (useVolumesRange) {
        result['volumeGreater'] = volumesRange.start.toInt();
        if (volumesRange.end < _maxVolumes) {
          result['volumeLesser'] = volumesRange.end.toInt();
        }
      }
    }

    widget.onApplyFilter(result);
    if (closeSheet) {
      Navigator.pop(context);
    }
  }
}
