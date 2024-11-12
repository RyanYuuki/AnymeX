import 'dart:math';
import 'package:aurora/pages/Anime/details_page.dart';
import 'package:aurora/pages/Manga/details_page.dart';
import 'package:aurora/pages/Novel/details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

enum GridLayout { single, double, triple }

enum MediaType { anime, manga, novel }

class MediaItem {
  final String title;
  final String imageUrl;
  final double rating;
  final MediaType type;

  MediaItem({
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.type,
  });
}

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => DownloadPageState();
}

class DownloadPageState extends State<DownloadPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int currentIndex = 0;
  GridLayout _currentLayout = GridLayout.double;
  final _scrollController = ScrollController();

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
      }
      setState(() {
        currentIndex = _tabController.index;
      });
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
    Map<String, dynamic> mapItemData(dynamic item, MediaType type) {
      switch (type) {
        case MediaType.anime:
          int random = Random().nextInt(100000);
          final tag = '$random-${item['animeId']}';
          return {
            'id': item['animeId'],
            'title': item['animeTitle'],
            'image': item['poster'],
            'extra': item['currentEpisode'],
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
            'extra': item['currentChapter'],
            'tag': tag,
            'routePage': MangaDetailsPage(
              id: int.parse(item['anilistId']),
              posterUrl: item['mangaImage'],
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
        padding: const EdgeInsets.all(16),
        itemCount: carouselData?.length ?? 0,
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(),
          mainAxisExtent: MediaQuery.of(context).size.height * 0.3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
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
                },
                child: Column(children: [
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
                              child:
                                  const Icon(Icons.error, color: Colors.white),
                            ),
                            height:
                                (MediaQuery.of(context).size.height * 0.3 - 70),
                            width: double.infinity,
                            alignment: Alignment.topCenter,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 12),
                            decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer,
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    bottomRight: Radius.circular(16))),
                            child: Text(
                              itemData['extra'],
                              style: TextStyle(
                                  fontFamily: 'Poppins-SemiBold',
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inverseSurface),
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
                ]),
              ));
        });
  }

  Widget _buildHorizontalLayout(
    Map<String, dynamic> itemData,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
    );
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

  void _showDetailDialog(BuildContext context, Map<String, dynamic> item) {
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                        'Chapter ${item['extra']}',
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
                            Text(
                              'Description',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
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
        appBar: AppBar(
          title: const Text(
            'Downloads',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.movie_outlined,
                      color: currentIndex == 0
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    const Text('Anime'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.book,
                      color: currentIndex == 1
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    const Text('Manga'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      color: currentIndex == 2
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    const Text('Novel'),
                  ],
                ),
              ),
            ],
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
          elevation: 0,
        ),
        body: ValueListenableBuilder(
            valueListenable: Hive.box('app-data').listenable(),
            builder: (context, appBox, child) {
              final dynamic readingMangaList =
                  appBox.get('currently-reading')?.reversed.toList();
              final dynamic readingNovelList =
                  appBox.get('currently-noveling')?.reversed.toList();
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildMediaGrid(MediaType.anime, []),
                  _buildMediaGrid(
                    MediaType.manga,
                    readingMangaList,
                  ),
                  _buildMediaGrid(MediaType.novel, readingNovelList),
                ],
              );
            }));
  }
}
