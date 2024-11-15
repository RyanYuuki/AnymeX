import 'dart:math';
import 'package:aurora/components/anime/details/episode_list.dart';
import 'package:aurora/components/common/IconWithLabel.dart';
import 'package:aurora/pages/Anime/details_page.dart';
import 'package:aurora/pages/Manga/details_page.dart';
import 'package:aurora/pages/Manga/read_page.dart';
import 'package:aurora/pages/Novel/details_page.dart';
import 'package:aurora/utils/sources/anime/handler/sources_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

enum GridLayout { single, double, triple }

enum MediaType { anime, manga, novel }

class MyList extends StatefulWidget {
  const MyList({super.key});

  @override
  State<MyList> createState() => MyListState();
}

class MyListState extends State<MyList> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int currentIndex = 0;
  GridLayout _currentLayout = GridLayout.triple;
  final _scrollController = ScrollController();
  final List<String> _tabTitles = [
    'Anime Favourites',
    'Manga Favourites',
    'Novel Favourites'
  ];
  String _currentTitle = 'Anime Favourites';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        setState(() {
          currentIndex = _tabController.index;
          _currentTitle = _tabTitles[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _getCrossAxisCount() {
    switch (_currentLayout) {
      case GridLayout.single:
        return 1;
      case GridLayout.double:
        return 2;
      case GridLayout.triple:
        return 3;
    }
  }

  double getFontSize() {
    switch (_currentLayout) {
      case GridLayout.single:
        return 16.0;
      case GridLayout.double:
        return 13.0;
      case GridLayout.triple:
        return 11.0;
    }
  }

  Widget _buildMediaGrid(MediaType mediaType, dynamic carouselData) {
    double getCardHeight() {
      switch (_currentLayout) {
        case GridLayout.single:
          return MediaQuery.of(context).size.height * 0.3;
        case GridLayout.double:
          return MediaQuery.of(context).size.height * 0.35;
        case GridLayout.triple:
          return MediaQuery.of(context).size.height * 0.25;
      }
    }

    if (carouselData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mediaType == MediaType.anime
                  ? Icons.sentiment_dissatisfied_rounded
                  : mediaType == MediaType.manga
                      ? Icons.book_outlined
                      : Icons.menu_book_outlined,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              mediaType == MediaType.anime
                  ? "Looks like you're out of Anime to binge! 🥲"
                  : mediaType == MediaType.manga
                      ? "No Manga here! Did you eat them all? 🍜"
                      : "No Novels found... Try writing your own? 📖",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    Map<String, dynamic> mapItemData(dynamic item, MediaType type) {
      switch (type) {
        case MediaType.anime:
          int random = Random().nextInt(100000);
          final tag = '$random-${item['animeId']}';
          return {
            'id': item['animeId'],
            'title': item['animeTitle'],
            'image': item['poster'],
            'description': item['animeDescription'],
            'episodes': item['episodeList'],
            'extra': item['currentEpisode'],
            'currentSource': item['currentSource'],
            'tag': tag,
            'routePage': DetailsPage(
              id: int.parse(item['anilistId']),
              posterUrl: item['poster'],
              tag: tag,
            ),
          };
        case MediaType.manga:
          int random = Random().nextInt(100000);
          final tag = '$random-${item['novelId']}';
          return {
            'id': item['mangaId'],
            'title': item['mangaTitle'],
            'image': item['poster'],
            'description': item['mangaDescription'],
            'chapters': item['chapterList'],
            'currentSource': item['currentSource'],
            'extra': item['currentChapter'],
            'tag': tag,
            'routePage': MangaDetailsPage(
              id: int.parse(item['anilistId']),
              posterUrl: item['poster'],
              tag: tag,
            ),
          };
        case MediaType.novel:
          int random = Random().nextInt(100000);
          final tag = '$random-${item['novelId']}';
          return {
            'id': item['novelId'],
            'title': item['novelTitle'],
            'image': item['novelImage'],
            'chapters': item['chapterList'],
            'description': item['novelDescription'],
            'currentSource': item['currentSource'],
            'extra': item['chapterNumber'],
            'tag': tag,
            'routePage': NovelDetailsPage(
              id: (item['novelId']),
              posterUrl: item['novelImage'],
              tag: tag,
            ),
          };
      }
    }

    return GridView.builder(
        padding: EdgeInsets.all(_currentLayout == GridLayout.single ? 8 : 12),
        itemCount: carouselData?.length ?? 0,
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(),
          mainAxisExtent:
              _currentLayout == GridLayout.single ? 100 : getCardHeight(),
          crossAxisSpacing: _currentLayout == GridLayout.single ? 0 : 12,
          mainAxisSpacing: _currentLayout == GridLayout.single ? 10 : 12,
        ),
        itemBuilder: (context, index) {
          if (carouselData == null || index >= carouselData.length) {
            return _buildPlaceholderCard();
          }

          final itemData = mapItemData(carouselData[index], mediaType);
          const String proxyUrl = '';

          return AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: 1.0,
              child: GestureDetector(
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => itemData['routePage']),
                  // );
                  _showDetailDialog(context, itemData, mediaType);
                },
                child: _currentLayout == GridLayout.single
                    ? _buildHorizontalLayout(context, itemData, mediaType)
                    : _buildVerticalWidget(
                        itemData, proxyUrl, getCardHeight, context),
              ));
        });
  }

  Container _buildHorizontalLayout(
      BuildContext context, dynamic itemData, MediaType type) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: Theme.of(context).colorScheme.surfaceContainer),
      child: Row(
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: itemData['image'],
                fit: BoxFit.cover,
                height: 100,
                width: 65,
              )),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width - 110,
                child: Text(
                  itemData['title'],
                  style: const TextStyle(fontFamily: 'Poppins-SemiBold'),
                ),
              ),
              const SizedBox(height: 6),
              iconWithName(
                backgroundColor: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(7),
                isVertical: false,
                icon: type == MediaType.anime
                    ? Icons.movie_filter_rounded
                    : Iconsax.book,
                name:
                    '${type == MediaType.anime ? 'Episode ' : 'Chapter '} ${itemData['extra']}',
              )
            ],
          )
        ],
      ),
    );
  }

  Column _buildVerticalWidget(Map<String, dynamic> itemData, String proxyUrl,
      double getCardHeight(), BuildContext context) {
    return Column(children: [
      Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Hero(
              tag: itemData['tag'],
              child: CachedNetworkImage(
                imageUrl: proxyUrl + itemData['image'],
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[900]!,
                  highlightColor: Colors.grey[700]!,
                  child: Container(color: Colors.grey[900]),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.error, color: Colors.white),
                ),
                height: (getCardHeight() - 50),
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomRight: Radius.circular(16))),
                child: Text(
                  itemData['extra'],
                  style: TextStyle(
                      fontFamily: 'Poppins-SemiBold',
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.inverseSurface),
                ),
              )),
        ],
      ),
      Padding(
        padding: EdgeInsets.symmetric(
            horizontal: _currentLayout == GridLayout.single ? 8 : 0,
            vertical: 4),
        child: Text(
          itemData['title'] ?? '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: getFontSize(),
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black.withOpacity(0.7),
                offset: const Offset(2, 2),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]);
  }

  Widget _buildPlaceholderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  String stripHtmlTags(String htmlString) {
    final RegExp tagExp = RegExp(r'<[^>]*>');
    return htmlString.replaceAll(tagExp, '').trim();
  }

  void _showDetailDialog(
      BuildContext context, Map<String, dynamic> item, MediaType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Top drag handle
              Container(
                margin: const EdgeInsets.all(8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    // Content Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with image and title
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(
                                  tag: item['tag'],
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 120,
                                      height: 180,
                                      child: Image.network(
                                        item['image'],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.error),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${type == MediaType.anime ? 'Episode ' : 'Chapter '} ${item['extra']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Description Section
                            const Text(
                              'Description',
                              style: TextStyle(
                                  fontSize: 20, fontFamily: 'Poppins-SemiBold'),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              stripHtmlTags(item['description']),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              type == MediaType.anime ? 'Episodes' : 'Chapters',
                              style: const TextStyle(
                                  fontSize: 20, fontFamily: 'Poppins-SemiBold'),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final list = type == MediaType.anime
                              ? item['episodes'] ?? []
                              : item['chapters'] ?? [];
                          if (list.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No ${type == MediaType.anime ? 'episodes' : 'chapters'} available.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            );
                          }
                          final entry = list[index];
                          return Container(
                            decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer,
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                title: Text(
                                  '${type == MediaType.anime ? 'Episode' : 'Chapter'} ${entry['number']}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                subtitle: Text(
                                  entry['title'] ?? 'No title',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              item['routePage']));
                                }),
                          );
                        },
                        childCount: type == MediaType.anime
                            ? (item['episodes']?.length ?? 0)
                            : (item['chapters']?.length ?? 0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) =>
            [
          SliverAppBar(
            leading: const Icon(Icons.arrow_back_ios_new),
            expandedHeight: 150,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _currentTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            actions: [
              PopupMenuButton<GridLayout>(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _currentLayout == GridLayout.single
                        ? Icons.view_agenda_outlined
                        : _currentLayout == GridLayout.double
                            ? Icons.grid_view
                            : Icons.grid_on,
                    key: ValueKey(_currentLayout),
                  ),
                ),
                onSelected: (GridLayout layout) {
                  setState(() {
                    _currentLayout = layout;
                  });
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: GridLayout.single,
                    child: Row(
                      children: [
                        Icon(Icons.view_agenda_outlined),
                        SizedBox(width: 8),
                        Text('List View'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: GridLayout.double,
                    child: Row(
                      children: [
                        Icon(Icons.grid_view),
                        SizedBox(width: 8),
                        Text('Grid 2x2'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: GridLayout.triple,
                    child: Row(
                      children: [
                        Icon(Icons.grid_on),
                        SizedBox(width: 8),
                        Text('Grid 3x3'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
        body: ValueListenableBuilder(
          valueListenable: Hive.box('app-data').listenable(),
          builder: (context, appBox, child) {
            final dynamic readingAnimeList = appBox
                .get('currently-watching', defaultValue: [])
                ?.reversed
                ?.toList();

            final dynamic readingMangaList = appBox
                .get('currently-reading', defaultValue: [])
                ?.reversed
                ?.toList();
            final dynamic readingNovelList = appBox
                .get('currently-noveling', defaultValue: [])
                ?.reversed
                ?.toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildMediaGrid(MediaType.anime, readingAnimeList),
                _buildMediaGrid(MediaType.manga, readingMangaList),
                _buildMediaGrid(MediaType.novel, readingNovelList),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: TabBar(
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.only(bottom: 15),
        controller: _tabController,
        indicatorColor: Theme.of(context).colorScheme.primary,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.movie_outlined,
                ),
                SizedBox(width: 8),
                Text('Anime'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.book,
                ),
                SizedBox(width: 8),
                Text('Manga'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_outlined,
                ),
                SizedBox(width: 8),
                Text('Novel'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
