import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/screens/library/widgets/anime_card.dart';
import 'package:anymex/screens/library/widgets/manga_card.dart';
import 'package:anymex/widgets/exceptions/empty_library.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    bool isSimkl =
        Get.find<ServiceHandler>().serviceType.value == ServicesType.simkl;
    List<String> tabs = isSimkl ? ["Movies", "Series"] : ["Anime", "Manga"];
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
    final currentService = Get.find<ServiceHandler>().serviceType.value.index;

    final animeData = (index == 1
            ? offlineStorage.mangaLibrary.where((e) =>
                e.currentChapter?.pageNumber != null &&
                e.serviceIndex == currentService)
            : offlineStorage.animeLibrary.where((e) =>
                e.currentEpisode?.currentTrack != null &&
                e.serviceIndex == currentService))
        .toList();
    return animeData.isEmpty
        ? const EmptyLibrary(
            isHistory: true,
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
