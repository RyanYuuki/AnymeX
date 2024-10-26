import 'dart:math';
import 'package:aurora/auth/auth_provider.dart';
import 'package:aurora/pages/Anime/details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class AnimeList extends StatelessWidget {
  final List<String> tabs = [
    'WATCHING',
    'COMPLETED TV',
    'COMPLETED MOVIE',
    'COMPLETED OVA',
    'COMPLETED SPECIAL',
    'PAUSED',
    'DROPPED',
    'PLANNING',
    'FAVOURITES',
    'ALL',
  ];

  AnimeList({super.key});

  @override
  Widget build(BuildContext context) {
    final animeList =
        Provider.of<AniListProvider>(context).userData['animeList'];
    final userName =
        Provider.of<AniListProvider>(context).userData['user']['name'];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text("$userName's Anime List",
              style: TextStyle(
                  fontSize: 16, color: Theme.of(context).colorScheme.primary)),
          bottom: TabBar(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            physics: const BouncingScrollPhysics(),
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
              .map((tab) => AnimeListContent(
                    tabType: tab,
                    animeData: animeList,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class AnimeListContent extends StatelessWidget {
  final String tabType;
  final dynamic animeData;

  const AnimeListContent(
      {super.key, required this.tabType, required this.animeData});

  @override
  Widget build(BuildContext context) {
    if (animeData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredAnimeList = _filterAnimeByStatus(animeData, tabType);

    if (filteredAnimeList.isEmpty) {
      return Center(child: Text('No anime found for $tabType'));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, mainAxisExtent: 260, crossAxisSpacing: 10),
        itemCount: filteredAnimeList.length,
        itemBuilder: (context, index) {
          final item = filteredAnimeList[index]['media'];
          final tag = '${Random().nextInt(100000)}$index';
          final posterUrl = item?['coverImage']?['large'] ??
              'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx16498-73IhOXpJZiMF.jpg';
          return GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DetailsPage(
                            id: item['id'],
                            tag: tag,
                            posterUrl: posterUrl,
                          )));
            },
            child: Column(
              children: [
                Stack(children: [
                  Hero(
                    tag: tag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CachedNetworkImage(
                        height: 170,
                        fit: BoxFit.cover,
                        imageUrl: posterUrl,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  ),
                  Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomRight: Radius.circular(16))),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.star5,
                              size: 11,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              (item?['averageScore'] / 10)?.toString() ?? '0.0',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                              .colorScheme
                                              .inverseSurface ==
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
                      )),
                ]),
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
                          filteredAnimeList[index]?['progress']?.toString() ??
                              '?',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer),
                        ),
                        Text(' | ',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface
                                    .withOpacity(0.5))),
                        Text(
                          item['episodes']?.toString() ?? '?',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .inverseSurface
                                  .withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  List<dynamic> _filterAnimeByStatus(List<dynamic> animeList, String status) {
    switch (status) {
      case 'WATCHING':
        return animeList
            .where((anime) => anime['status'] == 'CURRENT')
            .toList();
      case 'COMPLETED TV':
        return animeList
            .where((anime) =>
                anime['status'] == 'COMPLETED' &&
                anime['media']['format'] == 'TV')
            .toList();
      case 'COMPLETED MOVIE':
        return animeList
            .where((anime) =>
                anime['status'] == 'COMPLETED' &&
                anime['media']['format'] == 'MOVIE')
            .toList();
      case 'COMPLETED OVA':
        return animeList
            .where((anime) =>
                anime['status'] == 'COMPLETED' &&
                anime['media']['format'] == 'OVA')
            .toList();
      case 'COMPLETED SPECIAL':
        return animeList
            .where((anime) =>
                anime['status'] == 'COMPLETED' &&
                anime['media']['format'] == 'SPECIAL')
            .toList();
      case 'PAUSED':
        return animeList.where((anime) => anime['status'] == 'PAUSED').toList();
      case 'DROPPED':
        return animeList
            .where((anime) => anime['status'] == 'DROPPED')
            .toList();
      case 'PLANNING':
        return animeList
            .where((anime) => anime['status'] == 'PLANNING')
            .toList();
      case 'FAVOURITES':
        return animeList
            .where((anime) => anime['isFavourite'] == true)
            .toList();
      case 'ALL':
        return animeList;
      default:
        return [];
    }
  }
}
