// ignore_for_file: deprecated_member_use
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/screens/search/widgets/inline_search_history.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/widgets/common/glow.dart';

enum SearchState { initial, loading, success, error, empty }

class ExtensionSearchResult {
  final Source source;
  final List<DMedia>? data;
  final bool isLoading;
  final String? error;

  ExtensionSearchResult({
    required this.source,
    this.data,
    this.isLoading = true,
    this.error,
  });

  ExtensionSearchResult copyWith({
    Source? source,
    List<DMedia>? data,
    bool? isLoading,
    String? error,
  }) {
    return ExtensionSearchResult(
      source: source ?? this.source,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class NovelSearchPage extends StatefulWidget {
  const NovelSearchPage({
    super.key,
  });

  @override
  State<NovelSearchPage> createState() => _NovelSearchPageState();
}

class _NovelSearchPageState extends State<NovelSearchPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final RxList<String> _searchedTerms = <String>[].obs;

  List<ExtensionSearchResult> _extensionResults = [];
  SearchState _searchState = SearchState.initial;
  String? _errorMessage;

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
    _searchController.text = '';
    _searchedTerms.value = Hive.box('preferences')
        .get('novel_searched_queries', defaultValue: <String>[]);

    // Set initial state - don't perform search automatically
    setState(() {
      _searchState = SearchState.initial;
      _extensionResults = [];
      _errorMessage = null;
    });
  }

  void _saveHistory() {
    Hive.box('preferences').put(
      'novel_searched_queries',
      _searchedTerms.toList(),
    );
  }

  Future<void> _performSearch({
    String? query,
    Map<String, dynamic>? filters,
  }) async {
    final searchQuery = query ?? _searchController.text.trim();

    // Only proceed if there's actually something to search for
    if (searchQuery.isEmpty && (filters == null || filters.isEmpty)) {
      setState(() {
        _searchState = SearchState.initial;
        _extensionResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _searchState = SearchState.loading;
      _errorMessage = null;
    });

    try {
      final novelExtensions = sourceController.installedNovelExtensions.value;

      if (novelExtensions.isEmpty) {
        setState(() {
          _searchState = SearchState.empty;
          _errorMessage = 'No extensions installed';
        });
        return;
      }

      // Initialize extension results with loading state
      _extensionResults = novelExtensions
          .map((extension) => ExtensionSearchResult(
                source: extension,
                isLoading: true,
              ))
          .toList();

      setState(() {
        _searchState = SearchState.success;
      });

      if (searchQuery.isNotEmpty && !_searchedTerms.contains(searchQuery)) {
        _searchedTerms.add(searchQuery);
        _saveHistory();
      }
      for (int i = 0; i < novelExtensions.length; i++) {
        _searchExtension(i, novelExtensions[i], searchQuery);
      }
    } catch (e) {
      setState(() {
        _searchState = SearchState.error;
        _errorMessage = _getErrorMessage(e);
      });
      Logger.i('Search failed: $e');
    }
  }

  Future<void> _searchExtension(
      int index, Source extension, String query) async {
    try {
      final results = await extension.methods.search(query, 1, []);

      setState(() {
        _extensionResults[index] = _extensionResults[index].copyWith(
          data: results.list,
          isLoading: false,
        );
      });
    } catch (e) {
      setState(() {
        _extensionResults[index] = _extensionResults[index].copyWith(
          isLoading: false,
          error: '${extension.name}: ${_getErrorMessage(e)}',
        );
      });
      Logger.i('Search failed for ${extension.name}: $e');
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
          hintText: 'Search Novel...',
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
                      _extensionResults = [];
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
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onSubmitted: (query) => _performSearch(query: query),
        onChanged: (value) => setState(() {}),
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
    // Show "Search to get started" if no history, otherwise show history
    if (_searchedTerms.isEmpty) {
      return _buildSearchToGetStartedState();
    } else {
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
  }

  Widget _buildSearchToGetStartedState() {
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
              'Search to get started',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a novel title to start searching',
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
    if (_extensionResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: _extensionResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final result = _extensionResults[index];

        return ReusableCarousel(
          data: result.data ?? [],
          title: result.source.name ?? '??',
          type: ItemType.novel,
          variant: DataVariant.extension,
          isLoading: result.isLoading,
          source: result.source,
        );
      },
    );
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
              if (_searchState == SearchState.success &&
                  _extensionResults.isNotEmpty) ...[
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
                          '${_extensionResults.length} sources',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (_extensionResults
                          .where((r) => !r.isLoading)
                          .isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .error
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_extensionResults.where((r) => !r.isLoading && (r.data?.isEmpty ?? true)).length} failed',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ]
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
