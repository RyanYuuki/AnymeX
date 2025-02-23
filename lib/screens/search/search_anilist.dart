import 'package:anymex/screens/anime/widgets/search_widgets.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/media_items/media_item.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';

enum ViewMode { box, list }

class SearchPage extends StatefulWidget {
  final String searchTerm;
  final dynamic source;
  final bool isManga;
  const SearchPage(
      {super.key,
      required this.searchTerm,
      required this.isManga,
      this.source});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ServiceHandler _serviceHandler = Get.find<ServiceHandler>();

  List<Media>? _searchResults;
  ViewMode _currentViewMode = ViewMode.box;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchTerm;
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
      final results = await _serviceHandler.search(searchQuery,
          isManga: widget.isManga, filters: filters);

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      snackBar('Search failed: $e', duration: 2000);
    }
  }

  void _showFilterBottomSheet() {
    showFilterBottomSheet(context, (filters) {
      _performSearch(filters: filters);
    });
  }

  void _toggleViewMode() {
    setState(() {
      _currentViewMode =
          _currentViewMode == ViewMode.box ? ViewMode.list : ViewMode.box;
    });
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Expanded(
                      child: CustomSearchBar(
                        controller: _searchController,
                        onSubmitted: (query) => _performSearch(query: query),
                        disableIcons: _serviceHandler.serviceType.value !=
                            ServicesType.anilist,
                        onSuffixIconPressed: _showFilterBottomSheet,
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
              Expanded(child: _buildSearchResults()),
            ],
          ),
        ),
      ),
    );
  }
}
