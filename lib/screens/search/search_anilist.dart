import 'dart:developer';

import 'package:anymex/screens/search/widgets/inline_search_history.dart';
import 'package:anymex/screens/search/widgets/search_widgets.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/settings/settings.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/media_items/media_item.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive/hive.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';

enum ViewMode { box, list }

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

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ServiceHandler _serviceHandler = Get.find<ServiceHandler>();
  final RxList<String> _searchedTerms = <String>[].obs;
  List<Media>? _searchResults;
  ViewMode _currentViewMode = ViewMode.box;
  bool _isLoading = false;
  Map<String, dynamic> _activeFilters = {};
  RxBool isAdult = false.obs;
  final Map<String, dynamic> _defaultFilters = {
    'season': 'WINTER',
    'sort': 'SCORE',
    'format': 'TV',
    'genres': [],
    'status': 'FINISHED',
  };

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchTerm;
    _searchedTerms.value = Hive.box('preferences').get(
        '${widget.isManga ? 'manga' : 'anime'}_searched_queries_${serviceHandler.serviceType.value.name}',
        defaultValue: [].cast<String>());
    if (widget.initialFilters != null) {
      _activeFilters = Map<String, dynamic>.from(widget.initialFilters!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(filters: _activeFilters);
      });
    } else {
      if (widget.searchTerm != '') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _performSearch();
        });
      }
    }
  }

  Future<void> _performSearch({
    String? query,
    Map<String, dynamic>? filters,
  }) async {
    setState(() {
      _isLoading = true;
      _searchResults = null;
    });

    try {
      final searchQuery = query ?? _searchController.text;
      if (filters != null) {
        _activeFilters = Map<String, dynamic>.from(filters);
      }

      final results = await _serviceHandler.search(searchQuery,
          isManga: widget.isManga,
          filters: _activeFilters.isNotEmpty ? _activeFilters : null,
          args: isAdult.value);

      if (query != null && query.isNotEmpty) {
        _searchedTerms.add(query);
        Hive.box('preferences').put(
            '${widget.isManga ? 'manga' : 'anime'}_searched_queries_${serviceHandler.serviceType.value.name}',
            _searchedTerms);
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      log('Search failed: $e');
      snackBar('Search failed: $e', duration: 2000);
    }
  }

  void _showFilterBottomSheet() {
    showFilterBottomSheet(context, (filters) {
      _performSearch(filters: filters);
    }, currentFilters: _activeFilters);
  }

  void _toggleViewMode() {
    setState(() {
      _currentViewMode =
          _currentViewMode == ViewMode.box ? ViewMode.list : ViewMode.box;
    });
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

  Widget _buildFilterChips() {
    if (_activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    List<Widget> chips = [];

    _activeFilters.forEach((key, value) {
      if (key == 'genres' && value is List && value.isNotEmpty) {
        for (var genre in value) {
          chips.add(
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                label: AnymexText(
                  text: genre,
                  variant: TextVariant.semiBold,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                deleteIcon: Icon(
                  Icons.close,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                onDeleted: () => _removeFilter(key, genre),
              ),
            ),
          );
        }
      } else if (value != null && value.toString().isNotEmpty) {
        String displayText = "$key: $value";
        if (key == 'sort') {
          displayText = "Sort: ${_formatSortBy(value.toString())}";
        } else if (key == 'season') {
          displayText = "Season: ${value.toString().toLowerCase().capitalize}";
        } else if (key == 'status' && value.toString() != 'All') {
          displayText = "Status: ${_formatStatus(value.toString())}";
        } else if (key == 'format') {
          displayText = "Format: $value";
        }

        chips.add(
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              label: AnymexText(
                text: displayText,
                variant: TextVariant.semiBold,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              deleteIcon: Icon(
                Icons.close,
                size: 16,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              onDeleted: () => _removeFilter(key, value),
            ),
          ),
        );
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      ),
    );
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

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults == null || _searchResults!.isEmpty) {
      if (_searchController.text.isEmpty) {
        return const Center(child: Text('Search Something!'));
      } else {
        return const Center(child: Text('No results found'));
      }
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: _currentViewMode == ViewMode.list
          ? const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisExtent: 110,
            )
          : SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: getResponsiveValue(context,
                  mobileValue: 3,
                  desktopValue: getResponsiveCrossAxisVal(
                      MediaQuery.of(context).size.width,
                      itemWidth: 108)),
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              mainAxisExtent: 230,
            ),
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        final media = _searchResults![index];
        return _currentViewMode == ViewMode.list
            ? _buildListItem(media)
            : GridAnimeCard(
                data: media,
                isManga: widget.isManga,
                variant: CardVariant.search);
      },
    );
  }

  Widget _buildListItem(Media media) {
    return TVWrapper(
      onTap: () => _navigateToDetails(media),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Hero(
              tag: media.title,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: CachedNetworkImage(
                  width: 60,
                  height: 90,
                  imageUrl: media.poster,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    media.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  if (media.rating != "??") _buildEpisodeChip(media),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeChip(Media media) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.star5,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(width: 4),
          AnymexText(
            text: media.rating,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 12,
            variant: TextVariant.bold,
          ),
        ],
      ),
    );
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
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 10, 10, 0),
                child: Row(
                  children: [
                    const CustomBackButton(),
                    Expanded(
                      child: CustomSearchBar(
                        controller: _searchController,
                        onSubmitted: (query) => _performSearch(query: query),
                        disableIcons: true,
                        onSuffixIconPressed: _showFilterBottomSheet,
                        suffixIconWidget: _searchController.text.isEmpty
                            ? const SizedBox.shrink()
                            : IconButton(
                                onPressed: () {
                                  setState(() {
                                    _searchController.text = '';
                                    _searchResults = [];
                                  });
                                },
                                icon: const Icon(Iconsax.close_circle)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AnymexText(
                          text: 'Adult',
                          variant: TextVariant.semiBold,
                        ),
                        const SizedBox(width: 10),
                        Obx(() {
                          return Switch(
                              value: isAdult.value,
                              onChanged: (v) => isAdult.value = v);
                        }),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        _showFilterBottomSheet();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5),
                        child: Row(children: [
                          AnymexText(
                            text: 'Filter',
                            color: Theme.of(context).colorScheme.primary,
                            variant: TextVariant.semiBold,
                            size: 16,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Icon(Icons.filter_alt,
                              color: Theme.of(context).colorScheme.primary)
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if ((_searchResults?.isNotEmpty ?? false) && !_isLoading) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Search Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Poppins-SemiBold',
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleViewMode,
                        icon: Icon(
                          _currentViewMode == ViewMode.box
                              ? Icons.grid_view
                              : Icons.menu,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_activeFilters.isNotEmpty &&
                    _activeFilters.toString() != _defaultFilters.toString())
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: _buildFilterChips(),
                  ),
                Expanded(child: _buildSearchResults()),
              ] else if (_isLoading) ...[
                const Center(
                  child: CircularProgressIndicator(),
                )
              ] else ...[
                Expanded(
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
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
