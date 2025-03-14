import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/media_items/media_item.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

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
    'ALL',
  ];

  bool isReversed = false;
  bool isItemsReversed = false;

  @override
  Widget build(BuildContext context) {
    final anilistAuth = Get.find<ServiceHandler>();
    final userName = anilistAuth.profileData.value.name;
    final mangaList = anilistAuth.mangaList.value;
    return Glow(
      child: DefaultTabController(
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
                  icon: Icon(isItemsReversed
                      ? Iconsax.arrow_up
                      : Iconsax.arrow_bottom)),
            ],
            leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Theme.of(context).colorScheme.primary,
                )),
            title: Text("$userName's Manga List",
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary)),
            bottom: TabBar(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              unselectedLabelColor: Colors.grey,
              physics: const BouncingScrollPhysics(),
              tabAlignment: TabAlignment.start,
              isScrollable: true,
              tabs: isReversed
                  ? tabs.reversed.toList().map((tab) {
                      final filteredAnimeList =
                          filterListByStatus(mangaList, tab);

                      return Tab(
                          child: AnymexText(
                        text: '$tab (${filteredAnimeList.length})',
                        variant: TextVariant.bold,
                      ));
                    }).toList()
                  : tabs.map((tab) {
                      final filteredAnimeList =
                          filterListByStatus(mangaList, tab);
                      return Tab(
                          child: AnymexText(
                        text: '$tab (${filteredAnimeList.length})',
                        variant: TextVariant.bold,
                      ));
                    }).toList(),
            ),
          ),
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
      ),
    );
  }
}

int getResponsiveCrossAxisCount(double screenWidth, {int itemWidth = 150}) {
  return (screenWidth / itemWidth).floor().clamp(1, 10);
}

class MangaListContent extends StatelessWidget {
  final String tabType;
  final List<TrackedMedia>? mangaData;

  const MangaListContent({
    super.key,
    required this.tabType,
    required this.mangaData,
  });

  @override
  Widget build(BuildContext context) {
    if (mangaData == null) {
      return const Center(child: AnymexProgressIndicator());
    }

    final filteredAnimeList = _filterMangaByStatus(mangaData!, tabType);

    if (filteredAnimeList.isEmpty) {
      return Center(child: Text('No Manga found for $tabType'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: getResponsiveCrossAxisVal(
              MediaQuery.of(context).size.width,
              itemWidth: 108),
          mainAxisExtent: 250,
          crossAxisSpacing: 15),
      itemCount: filteredAnimeList.length,
      itemBuilder: (context, index) {
        final item = filteredAnimeList[index] as TrackedMedia;
        return GridAnimeCard(
          data: item,
          isManga: true,
        );
      },
    );
  }

  List<dynamic> _filterMangaByStatus(
      List<TrackedMedia> mangaList, String status) {
    switch (status) {
      case 'READING':
        return mangaList
            .where((manga) => manga.watchingStatus == 'CURRENT')
            .toList();
      case 'COMPLETED':
        return mangaList
            .where((manga) => manga.watchingStatus == 'COMPLETED')
            .toList();
      case 'PAUSED':
        return mangaList
            .where((manga) => manga.watchingStatus == 'PAUSED')
            .toList();
      case 'DROPPED':
        return mangaList
            .where((manga) => manga.watchingStatus == 'DROPPED')
            .toList();
      case 'PLANNING':
        return mangaList
            .where((manga) => manga.watchingStatus == 'PLANNING')
            .toList();
      case 'ALL':
        return mangaList;
      default:
        return [];
    }
  }
}
