// ignore_for_file: deprecated_member_use

import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/novel/details/details_view.dart';
import 'package:anymex/screens/search/widgets/inline_search_history.dart';
import 'package:anymex/screens/search/widgets/search_widgets.dart';
import 'package:anymex/screens/settings/misc/sauce_finder_view.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/future_reusable_carousel.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/media_items/media_item.dart';
import 'package:anymex/widgets/media_items/media_peek_popup.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

enum ViewMode { grid, list }

enum SearchState { initial, loading, success, error, empty }

class ExtensionSearchItem {
  final Source source;
  final Future<List<dynamic>> future;
  int status;
  String errorMessage;

  ExtensionSearchItem({
    required this.source,
    required this.future,
    this.status = 1,
    this.errorMessage = '',
  });
}

class SearchPage extends StatefulWidget {
  final String searchTerm;
  final dynamic source;
  final bool isManga;
  final ItemType? type;
  final Map<String, dynamic>? initialFilters;

  const SearchPage({
    super.key,
    required this.searchTerm,
    required this.isManga,
    this.type,
    this.source,
    this.initialFilters,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ServiceHandler _serviceHandler = Get.find<ServiceHandler>();
  final SourceController _sourceController = Get.find<SourceController>();
  final RxList<String> _searchedTerms = <String>[].obs;
  final ScrollController _resultsScrollController = ScrollController();

  Source? _selectedSource;
  List<ExtensionSearchItem> _extensionSearchItems = [];

  List<Media>? _searchResults;
  ViewMode _currentViewMode = ViewMode.grid;
  SearchState _searchState = SearchState.initial;
  String? _errorMessage;
  Map<String, dynamic> _activeFilters = {};
  bool isAdult = false;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreResults = false;
  String _lastSearchQuery = '';
  Map<String, dynamic> _lastApiFilters = {};

  final FocusNode _searchFocusNode = FocusNode();

  final Map<String, List<ExtensionSearchItem>> _allSourcesCache = {};
  final Map<String, List<Media>> _singleSourceCache = {};

  ItemType get effectiveType =>
      widget.type ?? (widget.isManga ? ItemType.manga : ItemType.anime);

  bool get isExtensionMode =>
      _serviceHandler.serviceType.value == ServicesType.extensions ||
      _selectedSource != null;

  @override
  void initState() {
    super.initState();
    _selectedSource = widget.source is Source ? widget.source as Source : null;
    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _resultsScrollController.addListener(_onResultsScroll);
  }

  void _initializeData() {
    _searchController.text = widget.searchTerm;
    _searchedTerms.value = DynamicKeys.searchHistory.get<List<String>>(
      '${effectiveType.name}_${serviceHandler.serviceType.value.name}',
      <String>[],
    );

    if (!isExtensionMode) {
      prefetchFilterMeta(
        mediaType: widget.isManga ? 'manga' : 'anime',
        config: _resolvedFilterConfig(),
      );
    }

    if (widget.initialFilters != null) {
      _activeFilters = Map<String, dynamic>.from(widget.initialFilters!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(filters: _activeFilters);
      });
    } else if (widget.searchTerm.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
  }

  FilterConfig _resolvedFilterConfig() {
    if (_serviceHandler.serviceType.value == ServicesType.mal) {
      return widget.isManga ? FilterConfig.malManga : FilterConfig.malAnime;
    }
    return widget.isManga
        ? FilterConfig.anilistManga
        : FilterConfig.anilistAnime;
  }

  void _saveHistory() {
    DynamicKeys.searchHistory.set(
      '${effectiveType.name}_${serviceHandler.serviceType.value.name}',
      _searchedTerms.toList(),
    );
  }

  void _onResultsScroll() {
    if (!_resultsScrollController.hasClients ||
        _searchState != SearchState.success ||
        _searchResults == null ||
        _searchResults!.isEmpty ||
        _isLoadingMore ||
        !_hasMoreResults) {
      return;
    }

    final position = _resultsScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 250) {
      _loadMoreResults();
    }
  }

  String _mediaKey(Media media) {
    final rawId = media.id.toString();
    return '${media.serviceType.name}|$rawId';
  }

  Map<String, dynamic> _buildApiFilters(String searchQuery) {
    final apiFilters = Map<String, dynamic>.from(_activeFilters);
    if (apiFilters['sort'] == null && searchQuery.isEmpty) {
      apiFilters['sort'] = ['POPULARITY_DESC'];
    }
    return apiFilters;
  }

  Future<void> _performSearch({
    String? query,
    Map<String, dynamic>? filters,
  }) async {
    if (filters != null) {
      filters = Map<String, dynamic>.from(filters)
        ..removeWhere((key, value) => value == null);
    }

    final searchQuery = query ?? _searchController.text.trim();

    Map<String, dynamic> currentFilters = filters ?? _activeFilters;
    bool hasActiveContent = currentFilters.isNotEmpty;

    if (searchQuery.isEmpty && !isAdult && !hasActiveContent) {
      setState(() {
        _searchState = SearchState.initial;
        _searchResults = null;
        _activeFilters = {};
        _errorMessage = null;
        _currentPage = 1;
        _isLoadingMore = false;
        _hasMoreResults = false;
        _lastSearchQuery = '';
        _lastApiFilters = {};
        _extensionSearchItems.clear();
        _allSourcesCache.clear();
        _singleSourceCache.clear();
      });
      return;
    }

    setState(() {
      _searchState = SearchState.loading;
      _errorMessage = null;
      _currentPage = 1;
      _isLoadingMore = false;
      _hasMoreResults = true;
      if (filters != null) {
        _activeFilters = Map<String, dynamic>.from(filters);
      }
    });

    if (searchQuery.isNotEmpty && !_searchedTerms.contains(searchQuery)) {
      _searchedTerms.add(searchQuery);
      _saveHistory();
    }

    if (isExtensionMode) {
      if (_selectedSource != null) {
        await _performSingleSourceSearch(searchQuery);
      } else {
        _performAllSourcesSearch(searchQuery);
      }
      return;
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    try {
      final apiFilters = _buildApiFilters(searchQuery);
      final results = (await _serviceHandler.search(SearchParams(
            query: searchQuery,
            isManga: widget.isManga,
            filters: apiFilters.isNotEmpty ? apiFilters : null,
            args: isAdult,
            page: 1,
          ))) ??
          [];
      if (!mounted) return;

      final uniqueResults = <Media>[];
      final seen = <String>{};
      for (final item in results) {
        final key = _mediaKey(item);
        if (seen.add(key)) {
          uniqueResults.add(item);
        }
      }

      setState(() {
        _searchResults = uniqueResults;
        _currentPage = 1;
        _hasMoreResults = uniqueResults.isNotEmpty;
        _lastSearchQuery = searchQuery;
        _lastApiFilters = Map<String, dynamic>.from(apiFilters);
        _searchState =
            uniqueResults.isEmpty ? SearchState.empty : SearchState.success;
      });

      if (_resultsScrollController.hasClients) {
        _resultsScrollController.jumpTo(0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchState = SearchState.error;
        _errorMessage = _getErrorMessage(e);
        _isLoadingMore = false;
        _hasMoreResults = false;
      });
      Logger.i('Search failed: $e');
    }
  }

  Future<void> _performSingleSourceSearch(String searchQuery) async {
    final queryKey = searchQuery.toLowerCase().trim();
    final cacheKey = '${_selectedSource!.id}|$queryKey';

    if (_singleSourceCache.containsKey(cacheKey)) {
      final cachedList = _singleSourceCache[cacheKey]!;
      setState(() {
        _searchResults = List<Media>.from(cachedList);
        _currentPage = 1;
        _hasMoreResults = cachedList.isNotEmpty;
        _lastSearchQuery = searchQuery;
        _searchState =
            cachedList.isEmpty ? SearchState.empty : SearchState.success;
      });
      if (_resultsScrollController.hasClients) {
        _resultsScrollController.jumpTo(0);
      }
      return;
    }

    if (_allSourcesCache.containsKey(queryKey)) {
      final allItems = _allSourcesCache[queryKey]!;
      final match = allItems
          .firstWhereOrNull((e) => e.source.id == _selectedSource!.id);
      if (match != null) {
        try {
          final rawList = await match.future;
          final mediaList = rawList
              .map((e) => Media.froDMedia(e, effectiveType))
              .toList();
          _singleSourceCache[cacheKey] = mediaList;
          setState(() {
            _searchResults = List<Media>.from(mediaList);
            _currentPage = 1;
            _hasMoreResults = mediaList.isNotEmpty;
            _lastSearchQuery = searchQuery;
            _searchState =
                mediaList.isEmpty ? SearchState.empty : SearchState.success;
          });
          if (_resultsScrollController.hasClients) {
            _resultsScrollController.jumpTo(0);
          }
          return;
        } catch (_) {}
      }
    }

    try {
      final res = await _selectedSource!.methods.search(searchQuery, 1, []);
      final rawList = res.list;
      if (!mounted) return;

      final mediaList =
          rawList.map((e) => Media.froDMedia(e, effectiveType)).toList();
      _singleSourceCache[cacheKey] = mediaList;

      setState(() {
        _searchResults = mediaList;
        _currentPage = 1;
        _hasMoreResults = mediaList.isNotEmpty;
        _lastSearchQuery = searchQuery;
        _searchState =
            mediaList.isEmpty ? SearchState.empty : SearchState.success;
      });

      if (_resultsScrollController.hasClients) {
        _resultsScrollController.jumpTo(0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchState = SearchState.error;
        _errorMessage = e.toString();
        _hasMoreResults = false;
      });
    }
  }

  void _performAllSourcesSearch(String searchQuery) {
    final key = searchQuery.toLowerCase().trim();

    if (_allSourcesCache.containsKey(key)) {
      setState(() {
        _extensionSearchItems =
            List<ExtensionSearchItem>.from(_allSourcesCache[key]!);
        _lastSearchQuery = searchQuery;
        _searchState = _allSourcesCache[key]!.isEmpty
            ? SearchState.empty
            : SearchState.success;
      });
      return;
    }

    final installed = effectiveType.extensions;
    final items = installed.map((s) {
      final Future<List<dynamic>> future =
          s.methods.search(searchQuery, 1, []).then<List<dynamic>>((res) {
        return res.list;
      }).catchError((err) {
        return <dynamic>[];
      });

      return ExtensionSearchItem(source: s, future: future);
    }).toList();

    _allSourcesCache[key] = items;
    setState(() {
      _extensionSearchItems = items;
      _lastSearchQuery = searchQuery;
      _searchState = items.isEmpty ? SearchState.empty : SearchState.success;
    });
  }

  Future<void> _loadMoreResults() async {
    if (_isLoadingMore ||
        !_hasMoreResults ||
        _searchResults == null ||
        _searchResults!.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _currentPage + 1;

    try {
      List<Media> results = [];
      if (_selectedSource != null) {
        final res = await _selectedSource!.methods
            .search(_lastSearchQuery, nextPage, []);
        results = res.list
            .map((e) => Media.froDMedia(e, effectiveType))
            .toList();
      } else {
        results = (await _serviceHandler.search(SearchParams(
              query: _lastSearchQuery,
              isManga: widget.isManga,
              filters: _lastApiFilters.isNotEmpty
                  ? Map<String, dynamic>.from(_lastApiFilters)
                  : null,
              args: isAdult,
              page: nextPage,
            ))) ??
            [];
      }

      if (!mounted) return;

      if (results.isEmpty) {
        setState(() {
          _hasMoreResults = false;
        });
        return;
      }

      final existingKeys = _searchResults!.map(_mediaKey).toSet();
      final newItems = <Media>[];

      for (final item in results) {
        final key = _mediaKey(item);
        if (existingKeys.add(key)) {
          newItems.add(item);
        }
      }

      setState(() {
        if (newItems.isEmpty) {
          _hasMoreResults = false;
        } else {
          _searchResults!.addAll(newItems);
          _currentPage = nextPage;
        }
      });
    } catch (e) {
      Logger.i('Failed to load more search results: $e');
      if (!mounted) return;
      setState(() {
        _hasMoreResults = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      return 'Network error. Please check your connection.';
    } else if (error.toString().contains('timeout')) {
      return 'Search timed out. Please try again.';
    } else if (error.toString().contains('404')) {
      return 'Service not available. Please try later.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  @override
  void dispose() {
    _resultsScrollController
      ..removeListener(_onResultsScroll)
      ..dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back_ios_new),
                    ),
                    Expanded(child: _buildModernSearchBar()),
                  ],
                ),
              ),
              _buildControlsSection(),
              _buildActiveFilters(),
              const SizedBox(height: 6),
              Expanded(child: _buildMainContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSearchBar() {
    final hintText = _selectedSource != null
        ? 'Search ${_selectedSource!.name}...'
        : 'Search ${effectiveType.name.capitalizeFirst}...';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: _searchFocusNode.hasFocus
            ? [
                BoxShadow(
                  color: context.colors.primary.opaque(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
        decoration: InputDecoration(
          filled: true,
          fillColor: context.colors.surfaceContainer.opaque(.5),
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.colors.onSurface.opaque(0.5),
              ),
          prefixIcon: Icon(
            Iconsax.search_normal,
            color: _searchFocusNode.hasFocus
                ? context.colors.primary
                : context.colors.onSurface.opaque(0.5),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchState = SearchState.initial;
                      _searchResults = null;
                      _currentPage = 1;
                      _isLoadingMore = false;
                      _hasMoreResults = false;
                      _lastSearchQuery = '';
                      _lastApiFilters = {};
                      _extensionSearchItems.clear();
                    });
                  },
                  icon: Icon(
                    Iconsax.close_circle,
                    color: Theme.of(context).colorScheme.onSurface.opaque(0.7),
                  ),
                )
              : (!isExtensionMode &&
                      serviceHandler.serviceType.value == ServicesType.anilist)
                  ? IconButton(
                      onPressed: _showFilterBottomSheet,
                      icon: Icon(
                        Iconsax.setting_4,
                        color: _activeFilters.isNotEmpty
                            ? context.colors.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .opaque(0.7),
                      ),
                    )
                  : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onSubmitted: (query) => _performSearch(query: query),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildControlsSection() {
    final installedSources = effectiveType.extensions;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (isExtensionMode) ...[
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    _buildSourceChip(
                      label: 'All Sources',
                      isSelected: _selectedSource == null,
                      onTap: () {
                        setState(() {
                          _selectedSource = null;
                        });
                        _performSearch();
                      },
                    ),
                    const SizedBox(width: 8),
                    for (final src in installedSources) ...[
                      _buildSourceChip(
                        label:
                            '${src.name ?? "Src"} (${src.lang?.toUpperCase() ?? "ALL"})',
                        iconUrl: src.iconUrl,
                        isSelected: _selectedSource?.id == src.id,
                        onTap: () {
                          setState(() {
                            _selectedSource = src;
                            _sourceController.setActiveSource(src);
                          });
                          _performSearch();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
            if (_selectedSource != null) ...[
              const SizedBox(width: 12),
              _buildViewModeToggle(),
            ],
          ] else ...[
            if (serviceHandler.serviceType.value == ServicesType.anilist) ...[
              if (!General.hideAdultContent.get(true)) ...[
                _buildToggleButton(
                  label: 'Adult',
                  isActive: isAdult,
                  onTap: () {
                    setState(() {
                      isAdult = !isAdult;
                    });
                    _performSearch();
                  },
                ),
                const SizedBox(width: 12),
              ],
              _buildActionButton(
                icon: Iconsax.setting_4,
                label: 'Filters',
                isActive: _activeFilters.isNotEmpty,
                onTap: _showFilterBottomSheet,
              ),
              if (!widget.isManga &&
                  serviceHandler.serviceType.value == ServicesType.anilist) ...[
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Iconsax.eye,
                  label: 'Image',
                  isActive: false,
                  onTap: () => navigate(() => const SauceFinderView()),
                ),
              ],
            ],
            const Spacer(),
            _buildViewModeToggle(),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceChip({
    required String label,
    String? iconUrl,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.opaque(0.15, iReallyMeanIt: true)
              : theme.colorScheme.surfaceContainerHighest
                  .opaque(0.3, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.opaque(0.4, iReallyMeanIt: true)
                : theme.colorScheme.onSurface
                    .opaque(0.08, iReallyMeanIt: true),
            width: isSelected ? 1.2 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconUrl != null && iconUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AnymeXImage(
                  width: 16,
                  height: 16,
                  imageUrl: iconUrl,
                ),
              ),
              const SizedBox(width: 6),
            ],
            AnymexText.semiBold(
              text: label,
              size: 12,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? context.colors.primary.opaque(0.1)
              : context.colors.surfaceContainer.opaque(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? context.colors.primary
                : context.colors.outline.opaque(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isActive
                        ? context.colors.primary
                        : context.colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 12,
              decoration: BoxDecoration(
                color: isActive
                    ? context.colors.primary
                    : context.colors.outline.opaque(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment:
                    isActive ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? context.colors.primary.opaque(0.1)
              : context.colors.surfaceContainer.opaque(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? context.colors.primary
                : context.colors.outline.opaque(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  isActive ? context.colors.primary : context.colors.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isActive
                        ? context.colors.primary
                        : context.colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface.opaque(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.outline.opaque(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewModeButton(ViewMode.grid, Iconsax.grid_1),
          _buildViewModeButton(ViewMode.list, Iconsax.menu_1),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(ViewMode mode, IconData icon) {
    final isActive = _currentViewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _currentViewMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? context.colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? context.colors.onPrimary : context.colors.onSurface,
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    if (_activeFilters.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _buildFilterChips(),
        ),
      ),
    );
  }

  List<Widget> _buildFilterChips() {
    List<Widget> chips = [];
    final isManga = widget.isManga;

    final Map<dynamic, String> currentServiceMap = {};
    if (isManga) {
      SearchFilterConstants.mangaReadableOnServices.forEach((lang, services) {
        services.forEach((name, idList) {
          for (var id in idList) {
            currentServiceMap[id] = name;
          }
        });
      });
    } else {
      SearchFilterConstants.animeStreamingServices.forEach((name, id) {
        currentServiceMap[id] = name;
      });
    }

    final Set<String> skipKeys = {'isLicensed'};

    void addRangeChip(String baseKey, String label) {
      if (_activeFilters.containsKey('${baseKey}Greater') ||
          _activeFilters.containsKey('${baseKey}Lesser')) {
        skipKeys.add('${baseKey}Greater');
        skipKeys.add('${baseKey}Lesser');

        final greater = _activeFilters['${baseKey}Greater'] ?? 0;
        final lesser = _activeFilters['${baseKey}Lesser'] ?? 'Any';

        String display;
        if (baseKey == 'year') {
          display =
              '$label: ${greater ~/ 10000} - ${lesser is int ? (lesser ~/ 10000) - 1 : lesser}';
        } else {
          display = '$label: $greater - $lesser';
        }

        chips.add(_buildFilterChip(display, () {
          setState(() {
            _activeFilters.remove('${baseKey}Greater');
            _activeFilters.remove('${baseKey}Lesser');
          });
          _performSearch(filters: _activeFilters);
        }));
      }
    }

    addRangeChip('year', 'Year');
    if (isManga) {
      addRangeChip('chapter', 'Chapters');
      addRangeChip('volume', 'Volumes');
    } else {
      addRangeChip('episode', 'Episodes');
      addRangeChip('duration', 'Duration (mins)');
    }

    _activeFilters.forEach((key, value) {
      if (skipKeys.contains(key)) return;
      if ((key == 'genres' || key == 'tags' || key == 'licensedBy') &&
          value is List &&
          value.isNotEmpty) {
        if (key == 'licensedBy') {
          final Map<String, List<int>> groupedPlatforms = {};
          for (var item in value) {
            String name = currentServiceMap[item] ?? 'Unknown Service';
            groupedPlatforms.putIfAbsent(name, () => []).add(item as int);
          }
          groupedPlatforms.forEach((name, ids) {
            chips.add(_buildFilterChip(name, () {
              for (var id in ids) {
                _removeFilter(key, id);
              }
            }));
          });
        } else {
          for (var item in value) {
            chips.add(_buildFilterChip(
                item.toString(), () => _removeFilter(key, item)));
          }
        }
      } else if (value != null && value.toString().isNotEmpty) {
        String displayText = _formatFilterValue(key, value);
        chips.add(
            _buildFilterChip(displayText, () => _removeFilter(key, value)));
      }
    });

    return chips;
  }

  Widget _buildFilterChip(String text, VoidCallback onRemove) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.primary.opaque(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.colors.primary.opaque(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.close,
              size: 16,
              color: context.colors.primary.opaque(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (isExtensionMode && _selectedSource == null) {
      return _buildAllSourcesContent();
    }

    switch (_searchState) {
      case SearchState.initial:
        return _buildInitialState();
      case SearchState.loading:
        return _buildLoadingState();
      case SearchState.success:
        return _buildSuccessState();
      case SearchState.error:
        return _buildErrorState();
      case SearchState.empty:
        return _buildEmptyState();
    }
  }

  Widget _buildAllSourcesContent() {
    if (_extensionSearchItems.isEmpty) {
      return _buildInitialState();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        children: [
          for (final item in _extensionSearchItems)
            Padding(
              key: ObjectKey(item),
              padding: const EdgeInsets.only(bottom: 4.0),
              child: FutureReusableCarousel(
                title: (item.source.lang?.isNotEmpty ?? false)
                    ? '${item.source.name ?? "Unknown"} (${item.source.lang!.toUpperCase()})'
                    : (item.source.name ?? 'Unknown'),
                future: item.future,
                type: effectiveType,
                variant: DataVariant.extension,
                source: item.source,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return InlineSearchHistory(
      searchTerms: _searchedTerms,
      onTermSelected: (term) {
        _searchController.text = term;
        _performSearch(query: term);
      },
      onHistoryUpdated: (updatedTerms) {
        setState(() {
          _searchedTerms.value = updatedTerms;
        });
        _saveHistory();
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.primary.opaque(0.1, iReallyMeanIt: true),
              shape: BoxShape.circle,
            ),
            child: const ExpressiveLoadingIndicator(),
          ),
          const SizedBox(height: 24),
          Text(
            'Searching...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .opaque(0.7, iReallyMeanIt: true),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.error.opaque(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.warning_2,
              size: 48,
              color: context.colors.error,
            ),
          ),
          const SizedBox(height: 24),
          const AnymexText.bold(
            text: 'Oops! Something went wrong',
            size: 18,
          ),
          const SizedBox(height: 8),
          AnymexText.regular(
            text: _errorMessage ?? 'Please try again later',
            textAlign: TextAlign.center,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.opaque(0.7),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _performSearch(),
            icon: Icon(Iconsax.refresh, color: context.colors.onPrimary),
            label: const AnymexText.semiBold(text: 'Try Again', size: 14),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.opaque(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.search_normal,
              size: 48,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          const AnymexText.bold(
            text: 'No results found',
            size: 18,
          ),
          const SizedBox(height: 8),
          AnymexText.regular(
            text: 'Try adjusting your search terms or filters',
            textAlign: TextAlign.center,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.opaque(0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (_searchResults == null || _searchResults!.isEmpty) {
      return const SizedBox.shrink();
    }

    final itemCount = _searchResults!.length + (_isLoadingMore ? 1 : 0);

    return GridView.builder(
      controller: _resultsScrollController,
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: _currentViewMode == ViewMode.list
          ? const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisExtent: 120,
            )
          : SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: getResponsiveValue(context,
                  mobileValue: 3,
                  desktopValue: getResponsiveCrossAxisVal(
                      MediaQuery.of(context).size.width,
                      itemWidth: 108)),
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              mainAxisExtent: 240,
            ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (_isLoadingMore && index == _searchResults!.length) {
          return const Center(child: ExpressiveLoadingIndicator());
        }

        final media = _searchResults![index];
        return AnimationConfiguration.staggeredGrid(
          position: index,
          columnCount: _currentViewMode == ViewMode.list ? 1 : 3,
          child: ScaleAnimation(
            duration: const Duration(milliseconds: 100),
            child: _currentViewMode == ViewMode.list
                ? _buildListItem(media)
                : GridAnimeCard(
                    data: media,
                    isManga: widget.isManga,
                    type: effectiveType,
                    variant: CardVariant.search),
          ),
        );
      },
    );
  }

  Widget _buildListItem(Media media) {
    final heroTag = '${media.id}-search-list';
    return GestureDetector(
      onTap: () => _navigateToDetails(media, heroTag),
      onLongPress: () {
        if (media.userStatus == null || media.userStatus!.isEmpty) {
          MediaPeekPopup.show(context, media, effectiveType, heroTag);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color:
              Theme.of(context).colorScheme.surfaceContainerHighest.opaque(0.3),
          border: Border.all(
            color: context.colors.outline.opaque(0.1, iReallyMeanIt: true),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: heroTag,
                transitionOnUserGestures: true,
                flightShuttleBuilder: AnymeXImage.heroFlightShuttleBuilder,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AnymeXImage(
                    width: 60,
                    height: 88,
                    imageUrl: media.poster,
                    radius: 0,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnymexText(
                      text: media.title,
                      maxLines: 2,
                      size: 16,
                      variant: TextVariant.semiBold,
                      isMarquee: true,
                    ),
                    if (media.rating != "??") ...[
                      const SizedBox(height: 8),
                      _buildRatingChip(media.rating),
                    ],
                  ],
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                color:
                    context.colors.onSurface.opaque(0.5, iReallyMeanIt: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingChip(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.primary.opaque(0.1, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.colors.primary.opaque(0.3, iReallyMeanIt: true),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.star5,
            size: 14,
            color: context.colors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            rating,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(Media media, String heroTag) {
    if (effectiveType == ItemType.novel) {
      final novSource = _selectedSource ??
          _sourceController.activeNovelSource.value ??
          _sourceController.installedNovelExtensions.firstOrNull;
      if (novSource != null) {
        navigateWithAnimation(() => NovelDetailsPage(
              media: media,
              tag: heroTag,
              source: novSource,
            ));
      }
    } else if (effectiveType == ItemType.manga) {
      navigateWithAnimation(() => MangaDetailsPage(
            media: media,
            tag: heroTag,
          ));
    } else {
      navigateWithAnimation(() => AnimeDetailsPage(
            media: media,
            tag: heroTag,
          ));
    }
  }

  void _showFilterBottomSheet() {
    showFilterBottomSheet(context, (filters) {
      _performSearch(filters: filters);
    },
        currentFilters: _activeFilters,
        mediaType: widget.isManga ? 'manga' : 'anime',
        config: _resolvedFilterConfig());
  }

  void _removeFilter(String key, dynamic value) {
    if (_activeFilters.containsKey(key)) {
      setState(() {
        if ((key == 'genres' || key == 'tags' || key == 'licensedBy') &&
            _activeFilters[key] is List) {
          List<dynamic> items = List<dynamic>.from(_activeFilters[key]);
          items.remove(value);
          if (items.isEmpty) {
            _activeFilters.remove(key);
            if (key == 'licensedBy') {
              _activeFilters.remove('isLicensed');
            }
          } else {
            _activeFilters[key] = items;
          }
        } else {
          _activeFilters.remove(key);
        }
      });
      _performSearch(filters: _activeFilters);
    }
  }

  String _formatFilterValue(String key, dynamic value) {
    switch (key) {
      case 'onList':
        if (widget.isManga) {
          return value == true ? "My Manga Only" : "Hide My Manga";
        }
        return value == true ? "My Anime Only" : "Hide My Anime";

      case 'status':
        return value.toString();

      case 'format':
        return value.toString();

      case 'season':
        return value.toString();

      case 'sort':
        if (value is List && value.isNotEmpty) {
          return SearchFilterConstants.formatSort(value.first.toString());
        }
        return SearchFilterConstants.formatSort(value.toString());

      case 'year':
        return "Year: $value";

      case 'episodeGreater':
        return "Min Ep: $value";
      case 'episodeLesser':
        return "Max Ep: $value";
      case 'chapterGreater':
        return "Min Chap: $value";
      case 'chapterLesser':
        return "Max Chap: $value";

      default:
        return value.toString();
    }
  }
}
