import 'dart:developer';
import 'dart:ui';
import 'package:anymex/components/android/common/IconWithLabel.dart';
import 'package:anymex/components/platform_builder.dart';
import 'package:anymex/utils/apiHooks/anilist/anime/search_page.dart';
import 'package:anymex/pages/Android/Anime/details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class SearchPage extends StatefulWidget {
  final String searchTerm;
  const SearchPage({super.key, required this.searchTerm});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

const String proxyUrl = '';

class _SearchPageState extends State<SearchPage> {
  final TextEditingController controller = TextEditingController();
  List<dynamic>? _searchData;
  List<String> layoutModes = ['List', 'Box', 'Cover'];
  int currentIndex = 0;

  // Filters
  List<String> sortBy = ['Score', 'Popular', 'Trending', 'A-Z', 'Z-A'];
  List<String> season = ['WINTER', 'SPRING', 'SUMMER', 'FALL'];

  List<String> format = ['TV', 'TV SHORT', 'MOVIE', 'SPECIAL', 'OVA', 'ONA'];

  @override
  void initState() {
    super.initState();
    controller.text = widget.searchTerm;
    fetchSearchedTerm();
  }

  Future<void> fetchSearchedTerm() async {
    _searchData = null;
    final tempData = await fetchAnimeBySearch(query: controller.text);
    setState(() {
      _searchData = tempData;
    });
  }

  void _search(String searchTerm) {
    setState(() {
      controller.text = searchTerm;
    });
    fetchSearchedTerm();
  }

  void _toggleView() {
    setState(() {
      currentIndex = (currentIndex + 1) % layoutModes.length;
    });
  }

  int getResponsiveCrossAxisCount(double screenWidth, {int itemWidth = 150}) {
    return (screenWidth / itemWidth).floor().clamp(1, 10);
  }

  @override
  Widget build(BuildContext context) {
    bool isList = layoutModes[currentIndex] == 'List';
    bool isBox = layoutModes[currentIndex] == 'Box';
    bool isCover = layoutModes[currentIndex] == 'Cover';

    return Scaffold(
      body: Padding(
        padding:
            const EdgeInsets.only(left: 20.0, right: 20, bottom: 16, top: 50),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded)),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: _search,
                    decoration: InputDecoration(
                      hintText: 'Eg.. Attack on Titan',
                      prefixIcon: const Icon(Iconsax.search_normal),
                      suffixIcon: IconButton(
                        onPressed: () {
                          showFilterBottomSheet(context, (args) async {
                            setState(() {
                              _searchData = null;
                            });
                            final tempData = await fetchAnimeBySearch(
                                query: controller.text,
                                sort: args['sort'],
                                season: args['season'],
                                status: args['status'],
                                format: args['format'],
                                genres: args['genres']);
                            setState(() {
                              _searchData = tempData;
                            });
                          });
                        },
                        icon: const Icon(IconlyBold.filter),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Search Results',
                    style: TextStyle(
                        fontSize: 18, fontFamily: 'Poppins-SemiBold')),
                IconButton(
                  onPressed: _toggleView,
                  icon: Icon(
                    isList
                        ? Icons.menu
                        : (isBox
                            ? Icons.grid_view
                            : isCover
                                ? Iconsax.image
                                : Iconsax.grid_5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Builder(
                builder: (context) => _searchData == null
                    ? const Center(child: CircularProgressIndicator())
                    : PlatformBuilder(
                        desktopBuilder: GridView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          gridDelegate: isList
                              ? const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1,
                                  mainAxisExtent: 100,
                                )
                              : (isBox
                                  ? SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          getResponsiveCrossAxisCount(
                                              MediaQuery.of(context)
                                                  .size
                                                  .width),
                                      crossAxisSpacing: 10.0,
                                      mainAxisSpacing: 10.0,
                                      mainAxisExtent: 200)
                                  : const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 1,
                                      mainAxisExtent: 170,
                                    )),
                          itemCount: _searchData!.length,
                          itemBuilder: (context, index) {
                            final anime = _searchData![index];
                            final tag = anime['name'].toString();
                            return isList
                                ? searchItemList(context, anime, tag)
                                : isBox
                                    ? searchItemBox(context, anime, tag)
                                    : searchItemCover(context, anime, tag);
                          },
                        ),
                        androidBuilder: GridView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          gridDelegate: isList
                              ? const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1,
                                  mainAxisExtent: 100,
                                )
                              : (isBox
                                  ? const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 10.0,
                                      mainAxisSpacing: 10.0,
                                      childAspectRatio: 0.7,
                                    )
                                  : const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 1,
                                      mainAxisExtent: 170,
                                    )),
                          itemCount: _searchData!.length,
                          itemBuilder: (context, index) {
                            final anime = _searchData![index];
                            final tag = anime['name'].toString();
                            return isList
                                ? searchItemList(context, anime, tag)
                                : isBox
                                    ? searchItemBox(context, anime, tag)
                                    : searchItemCover(context, anime, tag);
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stack searchItemBox(BuildContext context, anime, tag) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DetailsPage(
                            id: anime['id'],
                            posterUrl: proxyUrl + anime['poster'],
                            tag: tag,
                          )));
            },
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Hero(
                tag: tag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: proxyUrl + anime['poster'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  topRight: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.star5,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 3),
                Text(
                  anime?['rating'] ?? 'PG-13',
                  style: TextStyle(
                    fontFamily: 'Poppins-Bold',
                    color: Theme.of(context).colorScheme.inverseSurface ==
                            Theme.of(context).colorScheme.onPrimaryFixedVariant
                        ? Colors.black
                        : Theme.of(context).colorScheme.onPrimaryFixedVariant ==
                                const Color(0xffe2e2e2)
                            ? Colors.black
                            : Colors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

GestureDetector searchItemList(BuildContext context, anime, tag) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailsPage(
                    id: anime['id'],
                    posterUrl: proxyUrl + anime['poster'],
                    tag: tag,
                  )));
    },
    child: Container(
      height: 110,
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Theme.of(context).colorScheme.surfaceContainer),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          SizedBox(
            height: 90,
            width: 50,
            child: Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: CachedNetworkImage(
                  imageUrl: proxyUrl + anime['poster'],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Text(
                  anime['name'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  iconWithName(
                      isVertical: false,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5)),
                      icon: Icons.closed_caption,
                      backgroundColor: const Color(0xFFb0e3af),
                      name: anime['episodes']?.toString() ?? '?'),
                  const SizedBox(width: 2),
                  iconWithName(
                      isVertical: false,
                      backgroundColor: const Color(0xFFb9e7ff),
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5)),
                      icon: Iconsax.star5,
                      name: anime['rating']?.toString() ?? '?')
                ],
              )
            ],
          )
        ],
      ),
    ),
  );
}

GestureDetector searchItemCover(
    BuildContext context, Map<String, dynamic> anime, String tag) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailsPage(
                    id: anime['id'],
                    posterUrl: proxyUrl + anime['poster'],
                    tag: tag,
                  )));
    },
    child: Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: proxyUrl + anime['poster'],
                  fit: BoxFit.cover,
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                  child: Container(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Theme.of(context).colorScheme.surface.withOpacity(0.7),
                    ],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 70,
                  child: Hero(
                    tag: tag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: CachedNetworkImage(
                        imageUrl: proxyUrl + anime['poster'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anime['name'].length > 28
                            ? '${anime['name'].substring(0, 28)}...'
                            : anime['name'],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inverseSurface ==
                                  Theme.of(context)
                                      .colorScheme
                                      .onPrimaryFixedVariant
                              ? Colors.black
                              : Theme.of(context)
                                          .colorScheme
                                          .onPrimaryFixedVariant ==
                                      const Color(0xffe2e2e2)
                                  ? Colors.black
                                  : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${anime['episodes'] ?? '?'} Episodes',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.inverseSurface ==
                                        Theme.of(context)
                                            .colorScheme
                                            .onPrimaryFixedVariant
                                    ? Colors.black
                                    : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryFixedVariant ==
                                            const Color(0xffe2e2e2)
                                        ? Colors.black
                                        : Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void showFilterBottomSheet(
    BuildContext context, Function(dynamic args) onApplyFilter) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (BuildContext context) {
      return FilterOptionsContent(
        onApplyFilter: (args) {
          log(args.toString());
          onApplyFilter(args);
        },
      );
    },
  );
}

class FilterOptionsContent extends StatefulWidget {
  const FilterOptionsContent({
    super.key,
    required this.onApplyFilter,
  });
  final Function(dynamic args) onApplyFilter;
  @override
  _FilterOptionsContentState createState() => _FilterOptionsContentState();
}

class _FilterOptionsContentState extends State<FilterOptionsContent> {
  List<String> sortBy = [
    'SCORE_DESC',
    'SCORE',
    'POPULARITY_DESC',
    'POPULARITY',
    'TRENDING_DESC',
    'TRENDING',
    'START_DATE_DESC',
    'START_DATE',
    'TITLE_ROMAJI',
    'TITLE_ROMAJI_DESC'
  ];
  List<String> season = ['WINTER', 'SPRING', 'SUMMER', 'FALL'];
  List<String> status = [
    'All',
    'FINISHED',
    'NOT_YET_RELEASED',
    'RELEASING',
    'CANCELLED',
    'HIATUS'
  ];
  List<String> format = ['TV', 'TV SHORT', 'MOVIE', 'SPECIAL', 'OVA', 'ONA'];
  List<String> genres = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Fantasy',
    'Horror',
    'Mecha',
    'Music',
    'Mystery',
    'Psychological',
    'Romance',
    'Sci-Fi',
    'Slice of Life',
    'Sports',
    'Supernatural',
  ];

  String? selectedSortBy = 'SCORE';
  String? selectedSeason = 'WINTER';
  String? selectedStatus = 'FINISHED';
  String? selectedFormat = 'TV';
  List<String> selectedGenres = [];
  dynamic args = {
    'genres': [],
    'season': '',
    'format': '',
    'status': '',
    'sort': '',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Filter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    fillColor: Colors.transparent,
                    hintText: 'Sort By',
                    labelText: 'Sort By',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18)),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedSortBy,
                      isExpanded: true,
                      items: sortBy
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins-SemiBold',
                                      fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSortBy = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    fillColor: Colors.transparent,
                    labelText: 'Season',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedSeason,
                      isExpanded: true,
                      items: season
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins-SemiBold',
                                      fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSeason = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    fillColor: Colors.transparent,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    labelText: 'Status',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      items: status
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins-SemiBold',
                                      fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    fillColor: Colors.transparent,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    labelText: 'Format',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedFormat,
                      isExpanded: true,
                      items: format
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins-SemiBold',
                                      fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedFormat = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Select Genres',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: genres
                  .map((genre) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: ChoiceChip(
                          label: Text(genre),
                          selected: selectedGenres.contains(genre),
                          onSelected: (selected) {
                            setState(() {
                              selected
                                  ? selectedGenres.add(genre)
                                  : selectedGenres.remove(genre);
                            });
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                            width: 1,
                            color: Theme.of(context).colorScheme.primary),
                        borderRadius: BorderRadius.circular(20),
                      )),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins-SemiBold',
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                            width: 1,
                            color: Theme.of(context).colorScheme.primary),
                        borderRadius: BorderRadius.circular(20),
                      )),
                  onPressed: () {
                    widget.onApplyFilter({
                      'season': selectedSeason,
                      'sort': selectedSortBy,
                      'format': selectedFormat,
                      'genres': selectedGenres,
                      'status': selectedStatus
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Apply',
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins-SemiBold',
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
