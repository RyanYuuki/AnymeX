import 'dart:developer';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/manga/reading_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/exceptions/empty_library.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class MyMangaLibrary extends StatefulWidget {
  const MyMangaLibrary({super.key});

  @override
  State<MyMangaLibrary> createState() => _MyMangaLibraryState();
}

class _MyMangaLibraryState extends State<MyMangaLibrary>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController controller = TextEditingController();
  final offlineStorage = Get.find<OfflineStorageController>();
  RxList<OfflineMedia> mangaLibrary = <OfflineMedia>[].obs;
  RxList<CustomListData> customListData = <CustomListData>[].obs;
  RxList<OfflineMedia> filteredData = <OfflineMedia>[].obs;
  RxList<OfflineMedia> historyData = <OfflineMedia>[].obs;

  RxString searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    mangaLibrary.value = offlineStorage.mangaLibrary;
    customListData.value = offlineStorage.mangaCustomListData;
    historyData.value = offlineStorage.mangaLibrary
        .where((e) => e.currentChapter?.pageNumber != null)
        .toList();
    _tabController = TabController(
        length: offlineStorage.mangaCustomListData.length, vsync: this);
  }

  void _search(String val) {
    searchQuery.value = val;
    final currentTabIndex = _tabController.index;
    final initialData = customListData[currentTabIndex].listData;
    filteredData.value = initialData
        .where(
            (e) => e.name?.toLowerCase().contains(val.toLowerCase()) ?? false)
        .toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(top: 30.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Search Bar
                    CustomSearchBar(
                      onSubmitted: (val) {},
                      onChanged: _search,
                      controller: controller,
                      disableIcons: true,
                      suffixWidget: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AnymexText(
                            text: "MANGA",
                            variant: TextVariant.bold,
                            color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Colors.grey[400],
                      labelStyle: const TextStyle(fontFamily: "Poppins-Bold"),
                      tabs: List.generate(
                          offlineStorage.mangaCustomLists.length, (index) {
                        final tabName =
                            offlineStorage.mangaCustomLists[index].listName;
                        return Tab(text: tabName);
                      }),
                    ),

                    // Tab Content
                    Obx(
                      () => Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: List.generate(
                            customListData.length,
                            (index) => (customListData[index].listData).isEmpty
                                ? const EmptyLibrary()
                                : GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 130),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          getResponsiveCrossAxisCount(context,
                                              baseColumns: 2,
                                              maxColumns: 5,
                                              mobileItemWidth: 300,
                                              tabletItemWidth: 300,
                                              desktopItemWidth: 300),
                                      mainAxisExtent: 260,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                    itemBuilder: (context, i) {
                                      final data = searchQuery.isNotEmpty &&
                                              index == _tabController.index
                                          ? filteredData[i]
                                          : customListData[index].listData[i];
                                      return _MangaCard(
                                        data: data,
                                      );
                                    },
                                    itemCount: searchQuery.isNotEmpty &&
                                            index == _tabController.index
                                        ? filteredData.length
                                        : customListData[index].listData.length,
                                  ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              getResponsiveValue(
                context,
                mobileValue: const SizedBox.shrink(),
                desktopValue: Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  padding: const EdgeInsets.only(top: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'History',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Expanded(
                        child: historyData.isEmpty
                            ? const EmptyLibrary(
                                isHistory: true,
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: historyData.length,
                                itemBuilder: (context, index) =>
                                    MangaHistoryCard(
                                  data: historyData[index],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MangaCard extends StatelessWidget {
  final OfflineMedia data;

  const _MangaCard({required this.data});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => MangaDetailsPage(
            anilistId: data.id.toString(),
            posterUrl: data.poster!,
            tag: '${data.id!}${UniqueKey().toString()}'));
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  NetworkSizedImage(
                    imageUrl: data.poster ?? '',
                    radius: 12.multiplyRadius(),
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 4, 5, 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(12.multiplyRadius()),
                        ),
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.star5,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          AnymexText(
                            text: data.rating ?? '0.0',
                            variant: TextVariant.bold,
                          ),
                          const SizedBox(width: 3),
                        ],
                      ),
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
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.book,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          AnymexText(
                            text:
                                data.currentChapter?.number.toString() ?? '??',
                            variant: TextVariant.bold,
                          ),
                          const SizedBox(width: 3),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              child: Text(
                data.name ?? '??',
                style: const TextStyle(
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MangaHistoryCard extends StatelessWidget {
  final OfflineMedia data;

  const MangaHistoryCard({super.key, required this.data});

  String _formatEpisodeNumber() {
    final episode = data.currentChapter;
    if (episode == null) return 'Chapter ??';
    return 'Chapter ${episode.number}';
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      Theme.of(context).colorScheme.surface.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
    ];

    return GestureDetector(
      onTap: () {
        log(data.currentChapter?.sourceName ?? 'N.');
        Get.find<SourceController>()
            .getMangaExtensionByName(data.currentChapter!.sourceName!);
        Get.to(() => ReadingPage(
              anilistData: convertOfflineToMedia(data),
              chapterList: data.chapters!,
              currentChapter: data.currentChapter!,
            ));
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border(
              right: BorderSide(
                  width: 2, color: Theme.of(context).colorScheme.primary)),
          borderRadius: BorderRadius.circular(12.multiplyRadius()),
          color: Theme.of(context).colorScheme.surface.withAlpha(144),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.multiplyRadius()),
          child: Stack(children: [
            // Background image
            Positioned.fill(
              child: NetworkSizedImage(
                imageUrl: data.cover ?? data.poster!,
                radius: 0,
                width: double.infinity,
              ),
            ),
            Positioned.fill(
              child: Blur(
                blur: 4,
                blurColor: Colors.transparent,
                child: Container(),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: gradientColors)),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NetworkSizedImage(
                  width: getResponsiveSize(context,
                      mobileSize: 120, dektopSize: 130),
                  height: getResponsiveSize(context,
                      mobileSize: 150, dektopSize: 180),
                  radius: 0,
                  imageUrl: data.poster!,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: getResponsiveSize(context,
                                mobileSize: 20, dektopSize: 30)),
                        AnymexText(
                          text: _formatEpisodeNumber().toUpperCase(),
                          size: getResponsiveSize(context,
                              mobileSize: 18, dektopSize: 20),
                          variant: TextVariant.bold,
                          maxLines: 1,
                          color: Theme.of(context).colorScheme.primary,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        AnymexText(
                          text: data.currentChapter?.title ?? '??',
                          size: 14,
                          maxLines: 2,
                          variant: TextVariant.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular((8.multiplyRadius())),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: AnymexText(
                      text:
                          formatTimeAgo(data.currentChapter?.lastReadTime ?? 0),
                      size: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      variant: TextVariant.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular((8.multiplyRadius())),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: AnymexText(
                      text:
                          'PAGE ${data.currentChapter?.pageNumber} / ${data.currentChapter?.totalPages}',
                      size: 12,
                      color: Theme.of(context).colorScheme.onPrimary,
                      variant: TextVariant.bold,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
