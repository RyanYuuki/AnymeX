import 'dart:math';
import 'package:anymex/controllers/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/screens/library/online/widgets/items.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class AnimeList extends StatefulWidget {
  const AnimeList({super.key});

  @override
  State<AnimeList> createState() => _AnimeListState();
}

class _AnimeListState extends State<AnimeList> {
  final List<String> tabs = [
    'WATCHING',
    'COMPLETED TV',
    'COMPLETED MOVIE',
    'COMPLETED OVA',
    'COMPLETED SPECIAL',
    'PAUSED',
    'DROPPED',
    'PLANNING',
    "REWATCHING",
    'ALL',
  ];
  bool isReversed = false;
  bool isItemsReversed = false;

  @override
  Widget build(BuildContext context) {
    final anilistAuth = Get.find<AnilistAuth>();
    final animeList = anilistAuth.animeList;
    final userName = anilistAuth.profileData.value!.name;
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
          title: Text("$userName's Anime List",
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
                  .map((tab) => AnimeListContent(
                        tabType: tab,
                        animeData: isItemsReversed
                            ? animeList.reversed.toList()
                            : animeList,
                      ))
                  .toList()
              : tabs
                  .map((tab) => AnimeListContent(
                        tabType: tab,
                        animeData: isItemsReversed
                            ? animeList.reversed.toList()
                            : animeList,
                      ))
                  .toList(),
        ),
      ),
    );
  }
}

class AnimeListContent extends StatelessWidget {
  final String tabType;
  final List<AnilistMediaUser>? animeData;

  const AnimeListContent({
    super.key,
    required this.tabType,
    required this.animeData,
  });

  int getResponsiveCrossAxisCount(double screenWidth, {int itemWidth = 150}) {
    return (screenWidth / itemWidth).floor().clamp(1, 10);
  }

  @override
  Widget build(BuildContext context) {
    if (animeData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredAnimeList = filterListByStatus(animeData!, tabType);

    if (filteredAnimeList.isEmpty) {
      return Center(child: Text('No anime found for $tabType'));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: PlatformBuilder(
        androidBuilder: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisExtent: 260, crossAxisSpacing: 10),
          itemCount: filteredAnimeList.length,
          itemBuilder: (context, index) {
            final item = filteredAnimeList[index];
            final tag = '${Random().nextInt(100000)}$index';
            final posterUrl = item.poster ??
                'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx16498-73IhOXpJZiMF.jpg';
            return listItem(
                context, item, tag, posterUrl, filteredAnimeList, index);
          },
        ),
        desktopBuilder: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: getResponsiveCrossAxisCount(
                  MediaQuery.of(context).size.width),
              mainAxisExtent: 270,
              crossAxisSpacing: 10),
          itemCount: filteredAnimeList.length,
          itemBuilder: (context, index) {
            final item = filteredAnimeList[index];
            final tag = '${Random().nextInt(100000)}$index';
            final posterUrl = item.poster ??
                'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx16498-73IhOXpJZiMF.jpg';
            return listItemDesktop(
                context, item, tag, posterUrl, filteredAnimeList, index);
          },
        ),
      ),
    );
  }
}
