import 'package:anymex/auth/auth_provider.dart';
import 'package:anymex/components/platform_builder.dart';
import 'package:anymex/pages/Android/Manga/details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class AnilistMangaList extends StatefulWidget {
  const AnilistMangaList({super.key});

  @override
  State<AnilistMangaList> createState() => _AnilistMangaListState();
}

class _AnilistMangaListState extends State<AnilistMangaList> {
  final List<String> tabs = [
    'READING',
    'COMPLETED',
    'PAUSED',
    'DROPPED',
    'PLANNING',
    'FAVOURITES',
    'ALL',
  ];

  bool isReversed = false;
  bool isItemsReversed = false;

  @override
  Widget build(BuildContext context) {
    final mangaList =
        Provider.of<AniListProvider>(context).userData['mangaList'];
    final userName =
        Provider.of<AniListProvider>(context).userData['user']['name'];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: isReversed
                        ? Theme.of(context).colorScheme.surfaceContainer
                        : Colors.transparent),
                onPressed: () {
                  setState(() {
                    isReversed = !isReversed;
                  });
                },
                icon: const Icon(Iconsax.arrow_swap_horizontal)),
            IconButton(
                onPressed: () {
                  setState(() {
                    isItemsReversed = !isItemsReversed;
                  });
                },
                icon: Icon(
                    isItemsReversed ? Iconsax.arrow_up : Iconsax.arrow_bottom)),
          ],
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new)),
          title: Text("$userName's Manga List",
              style: TextStyle(
                  fontSize: 16, color: Theme.of(context).colorScheme.primary)),
          bottom: TabBar(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            physics: const BouncingScrollPhysics(),
            tabAlignment: TabAlignment.start,
            isScrollable: true,
            tabs: isReversed
                ? tabs.reversed
                    .toList()
                    .map((tab) => Tab(
                        child: Text(tab,
                            style: const TextStyle(
                                fontFamily: 'Poppins-SemiBold'))))
                    .toList()
                : tabs
                    .map((tab) => Tab(
                        child: Text(tab,
                            style: const TextStyle(
                                fontFamily: 'Poppins-SemiBold'))))
                    .toList(),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: TabBarView(
          children: isReversed
              ? tabs.reversed
                  .toList()
                  .map((tab) => MangaListContent(
                        tabType: tab,
                        mangaData: isItemsReversed
                            ? mangaList.reversed.toList()
                            : mangaList,
                      ))
                  .toList()
              : tabs
                  .map((tab) => MangaListContent(
                        tabType: tab,
                        mangaData: isItemsReversed
                            ? mangaList.reversed.toList()
                            : mangaList,
                      ))
                  .toList(),
        ),
      ),
    );
  }
}

int getResponsiveCrossAxisCount(double screenWidth, {int itemWidth = 150}) {
  return (screenWidth / itemWidth).floor().clamp(1, 10);
}

class MangaListContent extends StatelessWidget {
  final String tabType;
  final dynamic mangaData;

  const MangaListContent(
      {super.key, required this.tabType, required this.mangaData});

  @override
  Widget build(BuildContext context) {
    if (mangaData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredMangaList = _filterMangaByStatus(mangaData, tabType);

    if (filteredMangaList.isEmpty) {
      return Center(child: Text('No manga found for $tabType'));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: PlatformBuilder(
        androidBuilder: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisExtent: 260, crossAxisSpacing: 10),
          itemCount: filteredMangaList.length,
          itemBuilder: (context, index) {
            final item = filteredMangaList[index]['media'];
            return mangaItem(context, item, index);
          },
        ),
        desktopBuilder: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: getResponsiveCrossAxisCount(
                  MediaQuery.of(context).size.width),
              mainAxisExtent: 270,
              crossAxisSpacing: 10),
          itemCount: filteredMangaList.length,
          itemBuilder: (context, index) {
            final item = filteredMangaList[index]['media'];
            return mangaItemDesktop(context, item, index);
          },
        ),
      ),
    );
  }

  GestureDetector mangaItem(BuildContext context, item, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MangaDetailsPage(
                      id: (item['id']),
                      posterUrl: item['coverImage']['large'],
                      tag: item['id'].toString(),
                    )));
      },
      child: Column(
        children: [
          Hero(
            tag: item['id'],
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CachedNetworkImage(
                height: 170,
                fit: BoxFit.cover,
                imageUrl: item?['coverImage']?['large'] ??
                    'https://s4.anilist.co/file/anilistcdn/media/manga/cover/large/default.jpg',
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item?['title']?['english'] ?? item?['title']?['romaji'] ?? '?',
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mangaData?[index]?['progress']?.toString() ?? '?',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                  Text(' | ',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary)),
                  Text(
                    item['chapters']?.toString() ?? '?',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  GestureDetector mangaItemDesktop(BuildContext context, item, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MangaDetailsPage(
                      id: (item['id']),
                      posterUrl: item['coverImage']['large'],
                      tag: item['id'].toString(),
                    )));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: Hero(
              tag: item['id'],
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CachedNetworkImage(
                  width: double.maxFinite,
                  fit: BoxFit.cover,
                  imageUrl: item?['coverImage']?['large'] ??
                      'https://s4.anilist.co/file/anilistcdn/media/manga/cover/large/default.jpg',
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            item?['title']?['english'] ?? item?['title']?['romaji'] ?? '?',
            maxLines: 2,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mangaData?[index]?['progress']?.toString() ?? '?',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              Text(' | ',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary)),
              Text(
                item['chapters']?.toString() ?? '?',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          )
        ],
      ),
    );
  }

  List<dynamic> _filterMangaByStatus(List<dynamic> mangaList, String status) {
    switch (status) {
      case 'READING':
        return mangaList
            .where((manga) => manga['status'] == 'CURRENT')
            .toList();
      case 'COMPLETED':
        return mangaList
            .where((manga) => manga['status'] == 'COMPLETED')
            .toList();
      case 'PAUSED':
        return mangaList.where((manga) => manga['status'] == 'PAUSED').toList();
      case 'DROPPED':
        return mangaList
            .where((manga) => manga['status'] == 'DROPPED')
            .toList();
      case 'PLANNING':
        return mangaList
            .where((manga) => manga['status'] == 'PLANNING')
            .toList();
      case 'FAVOURITES':
        return mangaList
            .where((manga) => manga['isFavourite'] == true)
            .toList();
      case 'ALL':
        return mangaList;
      default:
        return [];
    }
  }
}
