import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/library/anime_library.dart';
import 'package:anymex/screens/library/manga_library.dart';
import 'package:anymex/widgets/animation/slide_scale.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<String> tabs = ["Anime", "Manga"];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'History',
            style: TextStyle(fontSize: 20),
          ),
          bottom: TabBar(
              indicatorColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey[400],
              labelStyle: const TextStyle(fontFamily: "Poppins-Bold"),
              tabs: List.generate(
                  tabs.length,
                  (int index) => Tab(
                        text: tabs[index],
                      ))),
        ),
        body: TabBarView(
            children: List.generate(
                tabs.length, (int index) => WatchingTab(index: index))),
      ),
    );
  }
}

class WatchingTab extends StatelessWidget {
  const WatchingTab({
    super.key,
    required this.index,
  });

  final int index;

  @override
  Widget build(BuildContext context) {
    final offlineStorage = Get.find<OfflineStorageController>();
    final animeData =
        index == 1 ? offlineStorage.mangaLibrary : offlineStorage.animeLibrary;
    return animeData.isEmpty
        ? const Center(
            child: Text("So Empty..."),
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            itemCount: animeData.length,
            itemBuilder: (context, i) {
              return index == 0
                  ? AnimeHistoryCard(data: animeData[i])
                  : MangaHistoryCard(data: animeData[i]);
            });
  }
}

class GridContent extends StatelessWidget {
  final String title;
  final List<OfflineMedia> data;

  const GridContent({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              getResponsiveValue(context, mobileValue: 1, desktopValue: 2),
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 30.0,
          mainAxisExtent:
              getResponsiveSize(context, mobileSize: 100, dektopSize: 280)),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final isAnime = item.type == "ANIME";

        return SlideAndScaleAnimation(
          initialScale: 0.0,
          finalScale: 1.0,
          initialOffset: const Offset(1.0, 0.0),
          duration: Duration(milliseconds: getAnimationDuration()),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.multiplyRoundness())),
            margin: const EdgeInsets.only(right: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  fit: StackFit.loose,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (isAnime) {
                          Get.to(() => AnimeDetailsPage(
                              anilistId: item.id.toString(),
                              posterUrl: item.cover!,
                              tag: ''));
                        }
                      },
                      child: NetworkSizedImage(
                        imageUrl: item.currentEpisode?.thumbnail ?? item.cover!,
                        radius: 16.multiplyRoundness(),
                        width: 170,
                        height: getResponsiveSize(context,
                            mobileSize: 100, dektopSize: 200),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 4, 5, 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12.multiplyRadius()),
                            bottomRight: Radius.circular(12.multiplyRadius()),
                          ),
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              isAnime ? Iconsax.play5 : Iconsax.book,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isAnime
                                  ? (item.currentEpisode?.number != null
                                      ? 'Episode ${item.currentEpisode?.number}'
                                      : '?')
                                  : (item.currentChapter?.number != null
                                      ? 'Chapter ${item.currentChapter?.number}'
                                      : '?'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: "Poppins-Bold",
                              ),
                            ),
                            const SizedBox(width: 3),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        (isAnime
                                ? item.currentEpisode?.title
                                : item.currentChapter?.title) ??
                            '?',
                        maxLines: 2,
                        style: const TextStyle(
                            fontSize: 14, fontFamily: "Poppins-SemiBold"),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color:
                                Theme.of(context).colorScheme.primaryContainer),
                        child: AnymexText(
                          text: item.name ?? '?',
                          maxLines: 2,
                          size: 11,
                          variant: TextVariant.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
