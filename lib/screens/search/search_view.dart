// ignore_for_file: deprecated_member_use

import 'package:anymex/utils/logger.dart';

import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/screens/search/widgets/inline_search_history.dart';
import 'package:anymex/screens/search/widgets/search_widgets.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/settings/misc/sauce_finder_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/animation/animations.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/media_items/media_item.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive/hive.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/widgets/common/glow.dart';

enum ViewMode { grid, list }

enum SearchState { initial, loading, success, error, empty }

class SearchPage extends StatefulWidget {
  final String searchTerm;
  final dynamic source;
  final bool isManga;
  final Map<String, dynamic>? initialFilters;

  const SearchPage({
    super.key,
    required this.searchTerm,
    required this.isManga,
    this.source,
    this.initialFilters,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ServiceHandler _serviceHandler = Get.find<ServiceHandler>();
  final RxList<String> _searchedTerms = <String>[].obs;

  List<Media>? _searchResults;
  ViewMode _currentViewMode = ViewMode.grid;
  SearchState _searchState = SearchState.initial;
  String? _errorMessage;
  Map<String, dynamic> _activeFilters = {};
  RxBool isAdult = false.obs;

  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  void _initializeData() {
    _searchController.text = widget.searchTerm;
    _searchedTerms.value = Hive.box('preferences').get(
        '${widget.isManga ? 'manga' : 'anime'}_searched_queries_${serviceHandler.serviceType.value.name}',
        defaultValue: [].cast<String>());

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

  void _saveHistory() {
    Hive.box('preferences').put(
      '${widget.isManga ? 'manga' : 'anime'}_searched_queries_${serviceHandler.serviceType.value.name}',
      _searchedTerms.toList(),
    );
  }

  Future<void> _performSearch({
    String? query,
    Map<String, dynamic>? filters,
  }) async {
    final searchQuery = query ?? _searchController.text.trim();

    if (searchQuery.isEmpty && (filters == null || filters.isEmpty)) {
      setState(() {
        _searchState = SearchState.initial;
        _searchResults = null;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _searchState = SearchState.loading;
      _errorMessage = null;
    });

    try {
      if (filters != null) {
        _activeFilters = Map<String, dynamic>.from(filters);
      }

      final results = (await _serviceHandler.search(SearchParams(
            query: searchQuery,
            isManga: widget.isManga,
            filters: _activeFilters.isNotEmpty ? _activeFilters : null,
            args: isAdult.value,
          ))) ??
          [];

      if (searchQuery.isNotEmpty && !_searchedTerms.contains(searchQuery)) {
        _searchedTerms.add(searchQuery);
        _saveHistory();
      }

      setState(() {
        _searchResults = results;
        _searchState =
            results.isEmpty ? SearchState.empty : SearchState.success;
      });
    } catch (e) {
      setState(() {
        _searchState = SearchState.error;
        _errorMessage = _getErrorMessage(e);
      });
      Logger.i('Search failed: $e');
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildModernSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: _searchFocusNode.hasFocus
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
          fillColor:
              Theme.of(context).colorScheme.surfaceContainer.withOpacity(.5),
          hintText:
              'Search ${serviceHandler.serviceType.value == ServicesType.simkl ? 'movie or series' : widget.isManga ? 'manga' : 'anime'}...',
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
          prefixIcon: Icon(
            Iconsax.search_normal,
            color: _searchFocusNode.hasFocus
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchState = SearchState.initial;
                      _searchResults = null;
                    });
                  },
                  icon: Icon(
                    Iconsax.close_circle,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                )
              : serviceHandler.serviceType.value != ServicesType.anilist
                  ? null
                  : IconButton(
                      onPressed: _showFilterBottomSheet,
                      icon: Icon(
                        Iconsax.setting_4,
                        color: _activeFilters.isNotEmpty
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                      ),
                    ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onSubmitted: (query) => _performSearch(query: query),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildControlsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (serviceHandler.serviceType.value == ServicesType.anilist) ...[
            Obx(() {
              return _buildToggleButton(
                label: 'Adult',
                isActive: isAdult.value,
                onTap: () => isAdult.value = !isAdult.value,
              );
            }),
            const SizedBox(width: 12),
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
        ],
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
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
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
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
                    color: Theme.of(context).colorScheme.surface,
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
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
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
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
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

    _activeFilters.forEach((key, value) {
      if (key == 'genres' && value is List && value.isNotEmpty) {
        for (var genre in value) {
          chips.add(_buildFilterChip(genre, () => _removeFilter(key, genre)));
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
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
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

  Widget _buildInitialState() {
    return Expanded(
      child: InlineSearchHistory(
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
      ),
    );
  }

  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                        .withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.warning_2,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again later',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _performSearch(),
              icon: Icon(Iconsax.refresh,
                  color: Theme.of(context).colorScheme.onPrimary),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.search_normal,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms or filters',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Expanded(
      child: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults == null || _searchResults!.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
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
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
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
                    variant: CardVariant.search),
          ),
        );
      },
    );
  }

  Widget _buildListItem(Media media) {
    return GestureDetector(
      onTap: () => _navigateToDetails(media),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.3),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: media.title,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    width: 60,
                    height: 88,
                    imageUrl: media.poster,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Icon(
                        Iconsax.image,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Icon(
                        Iconsax.warning_2,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      media.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.star5,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            rating,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showFilterBottomSheet(context, (filters) {
      _performSearch(filters: filters);
    }, currentFilters: _activeFilters);
  }

  void _removeFilter(String key, dynamic value) {
    if (_activeFilters.containsKey(key)) {
      setState(() {
        if (key == 'genres' && _activeFilters[key] is List) {
          List<String> genres = List<String>.from(_activeFilters[key]);
          genres.remove(value);
          if (genres.isEmpty) {
            _activeFilters.remove(key);
          } else {
            _activeFilters[key] = genres;
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
      case 'sort':
        return "Sort: ${_formatSortBy(value.toString())}";
      case 'season':
        return "Season: ${value.toString().toLowerCase().capitalize}";
      case 'status':
        return value.toString() != 'All'
            ? "Status: ${_formatStatus(value.toString())}"
            : "";
      case 'format':
        return "Format: $value";
      default:
        return "$key: $value";
    }
  }

  String _formatSortBy(String sortBy) {
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

  String _formatStatus(String status) {
    switch (status) {
      case 'FINISHED':
        return 'Finished';
      case 'NOT_YET_RELEASED':
        return 'Not Released';
      case 'RELEASING':
        return 'Airing';
      case 'CANCELLED':
        return 'Cancelled';
      case 'HIATUS':
        return 'On Hiatus';
      default:
        return status;
    }
  }

  void _navigateToDetails(Media media) {
    if (widget.isManga) {
      navigate(() => MangaDetailsPage(
            media: media,
            tag: media.title,
          ));
    } else {
      navigate(() => AnimeDetailsPage(
            media: media,
            tag: media.title,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: SafeArea(
        child: Scaffold(
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.3),
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Iconsax.arrow_left_2,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(child: _buildModernSearchBar()),
                  ],
                ),
              ),
              _buildControlsSection(),
              const SizedBox(height: 16),
              _buildActiveFilters(),
              if (_searchState == SearchState.success &&
                  _searchResults!.isNotEmpty) ...[
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Search Results',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_searchResults!.length}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (_searchState == SearchState.success) ...[
                        const Spacer(),
                        _buildViewModeToggle(),
                      ],
                    ],
                  ),
                ),
              ],
              _buildMainContent(),
            ],
          ),
        ),
      ),
    );
  }
}
