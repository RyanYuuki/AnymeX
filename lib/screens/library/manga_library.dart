import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/screens/library/widgets/gridview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyMangaLibrary extends StatefulWidget {
  const MyMangaLibrary({super.key});

  @override
  State<MyMangaLibrary> createState() => _MyMangaLibraryState();
}

class _MyMangaLibraryState extends State<MyMangaLibrary> {
  RxList<String> tabs = ["Default"].obs;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Manga Library',
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
    final mangaData = offlineStorage.mangaLibrary;
    return GridContent(
      title: 'Reading',
      data: mangaData,
      isAnime: false,
    );
  }
}
