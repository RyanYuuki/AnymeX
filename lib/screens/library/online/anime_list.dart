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

class AnimeList extends StatefulWidget {
  final List<TrackedMedia>? data;
  final String? title;
  const AnimeList({super.key, this.data, this.title});

  @override
  State<AnimeList> createState() => _AnimeListState();
}

class _AnimeListState extends State<AnimeList> {
  final anilistAuth = Get.find<ServiceHandler>();
  final List<String> tabs =
      Get.find<ServiceHandler>().serviceType.value != ServicesType.anilist
          ? [
              'WATCHING',
              'COMPLETED',
              'PAUSED',
              'DROPPED',
              'PLANNING',
              'ALL',
            ]
          : [
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
    final animeList = widget.data ?? anilistAuth.animeList.value;
    final userName = anilistAuth.profileData.value.name;
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
            title: Text("$userName's ${widget.title ?? 'Anime'} List",
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary)),
            bottom: TabBar(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              physics: const BouncingScrollPhysics(),
              tabAlignment: TabAlignment.start,
              isScrollable: true,
              unselectedLabelColor: Colors.grey,
              tabs: isReversed
                  ? tabs.reversed.toList().map((tab) {
                      final filteredAnimeList =
                          filterListByStatus(animeList, tab);

                      return Tab(
                          child: AnymexText(
                        text: '$tab (${filteredAnimeList.length})',
                        variant: TextVariant.bold,
                      ));
                    }).toList()
                  : tabs.map((tab) {
                      final filteredAnimeList =
                          filterListByStatus(animeList, tab);
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
      ),
    );
  }
}

class AnimeListContent extends StatelessWidget {
  final String tabType;
  final List<TrackedMedia>? animeData;

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
      return const Center(child: AnymexProgressIndicator());
    }

    final filteredAnimeList = filterListByStatus(animeData!, tabType);

    if (filteredAnimeList.isEmpty) {
      return Center(child: Text('No anime found for $tabType'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: getResponsiveCrossAxisVal(
              MediaQuery.of(context).size.width,
              itemWidth: 108),
          mainAxisExtent: 250,
          crossAxisSpacing: 10),
      itemCount: filteredAnimeList.length,
      itemBuilder: (context, index) {
        final item = filteredAnimeList[index];
        return GridAnimeCard(data: item, isManga: false);
      },
    );
  }
}
