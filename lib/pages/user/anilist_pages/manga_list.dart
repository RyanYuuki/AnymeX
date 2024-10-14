import 'package:aurora/auth/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AnilistMangaList extends StatelessWidget {
  final List<String> tabs = [
    'READING',
    'COMPLETED MANGA',
    'PAUSED',
    'DROPPED',
    'PLANNING',
    'FAVOURITES',
    'ALL',
  ];

  AnilistMangaList({super.key});

  @override
  Widget build(BuildContext context) {
    final mangaList =
        Provider.of<AniListProvider>(context).userData['mangaList'];
    final userName = Provider.of<AniListProvider>(context).userData['name'];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text("$userName's Manga List",
              style: TextStyle(
                  fontSize: 16, color: Theme.of(context).colorScheme.primary)),
          bottom: TabBar(
            tabAlignment: TabAlignment.start,
            isScrollable: true,
            tabs: tabs
                .map((tab) => Tab(
                    child: Text(tab,
                        style:
                            const TextStyle(fontFamily: 'Poppins-SemiBold'))))
                .toList(),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: TabBarView(
          children: tabs
              .map((tab) => MangaListContent(
                    tabType: tab,
                    mangaData: mangaList,
                  ))
              .toList(),
        ),
      ),
    );
  }
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
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, mainAxisExtent: 260, crossAxisSpacing: 10),
        itemCount: filteredMangaList.length,
        itemBuilder: (context, index) {
          final item = filteredMangaList[index]['media'];
          return Column(
            children: [
              ClipRRect(
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
              const SizedBox(height: 7),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item?['title']?['english'] ??
                        item?['title']?['romaji'] ??
                        '?',
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
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      Text(' | ',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary)),
                      Text(
                        item['chapters']?.toString() ?? '?',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  List<dynamic> _filterMangaByStatus(List<dynamic> mangaList, String status) {
    switch (status) {
      case 'READING':
        return mangaList
            .where((manga) => manga['status'] == 'CURRENT')
            .toList();
      case 'COMPLETED MANGA':
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
