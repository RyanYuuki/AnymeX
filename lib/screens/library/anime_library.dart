import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/screens/library/widgets/gridview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyAnimeLibrary extends StatefulWidget {
  const MyAnimeLibrary({super.key});

  @override
  State<MyAnimeLibrary> createState() => _MyAnimeLibraryState();
}

class _MyAnimeLibraryState extends State<MyAnimeLibrary> {
  RxList<String> tabs = ["Default"].obs;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Anime Library',
            style: TextStyle(fontSize: 20),
          ),
          bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: List.generate(
                  tabs.length,
                  (int index) => Tab(
                        text: tabs[index],
                      ))),
        ),
        body: TabBarView(
            children:
                List.generate(tabs.length, (int index) => const WatchingTab())),
      ),
    );
  }
}

class WatchingTab extends StatelessWidget {
  const WatchingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final offlineStorage = Get.find<OfflineStorageController>();
    final animeData = offlineStorage.animeLibrary;
    return GridContent(title: 'Watching', data: animeData);
  }
}
