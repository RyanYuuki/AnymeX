import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/anime/watch_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/exceptions/empty_library.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class MyAnimeLibrary extends StatefulWidget {
  const MyAnimeLibrary({super.key});

  @override
  State<MyAnimeLibrary> createState() => _MyAnimeLibraryState();
}

class _MyAnimeLibraryState extends State<MyAnimeLibrary>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController controller = TextEditingController();
  final offlineStorage = Get.find<OfflineStorageController>();

  RxList<CustomListData> customListData = <CustomListData>[].obs;
  RxList<OfflineMedia> filteredData = <OfflineMedia>[].obs;
  RxList<OfflineMedia> historyData = <OfflineMedia>[].obs;

  RxString searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    final handler = Get.find<ServiceHandler>();
    customListData.value = offlineStorage.animeCustomListData
        .map((e) => CustomListData(
              listName: e.listName,
              listData: e.listData
                  .where((item) =>
                      item.serviceIndex == handler.serviceType.value.index)
                  .toList(),
            ))
        .toList();

    historyData.value = offlineStorage.animeLibrary
        .where((e) =>
            e.currentEpisode?.currentTrack != null &&
            e.serviceIndex == handler.serviceType.value.index)
        .toList();
    _tabController = TabController(
        length: offlineStorage.animeCustomListData.length, vsync: this);
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
    final isSimkl =
        Get.find<ServiceHandler>().serviceType.value == ServicesType.simkl;
    return Obx(() => Glow(
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
                                text: isSimkl ? "SERIES" : "MANGA",
                                variant: TextVariant.bold,
                                color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),

                        // Tab Bar
                        Obx(() => TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              indicatorColor:
                                  Theme.of(context).colorScheme.primary,
                              unselectedLabelColor: Colors.grey[400],
                              labelStyle:
                                  const TextStyle(fontFamily: "Poppins-Bold"),
                              tabs: List.generate(
                                  offlineStorage.animeCustomLists.length,
                                  (index) {
                                final tabName = offlineStorage
                                    .animeCustomLists[index].listName;
                                return Tab(text: tabName);
                              }),
                            )),

                        // Tab Content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: List.generate(
                              customListData.length,
                              (index) => (customListData[index].listData)
                                      .isEmpty
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
                                                tabletItemWidth: 230,
                                                desktopItemWidth: 300),
                                        childAspectRatio: 2 / 3,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                      itemBuilder: (context, i) {
                                        final data = searchQuery.isNotEmpty &&
                                                index == _tabController.index
                                            ? filteredData[i]
                                            : customListData[index].listData[i];
                                        return _AnimeCard(
                                          data: data,
                                        );
                                      },
                                      itemCount: searchQuery.isNotEmpty &&
                                              index == _tabController.index
                                          ? filteredData.length
                                          : customListData[index]
                                              .listData
                                              .length,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  getResponsiveValueWithTablet(
                    context,
                    tabletValue: const SizedBox.shrink(),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    itemCount: historyData.length,
                                    itemBuilder: (context, index) =>
                                        AnimeHistoryCard(
                                      data: historyData[index],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}

class _AnimeCard extends StatelessWidget {
  final OfflineMedia data;

  const _AnimeCard({required this.data});
  @override
  Widget build(BuildContext context) {
    return TVWrapper(
      margin: 0,
      scale: 1,
      onTap: () {
        Get.to(() => AnimeDetailsPage(
            media: Media.fromOfflineMedia(data, MediaType.anime),
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
                            Iconsax.play5,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          AnymexText(
                            text: data.currentEpisode?.number ?? '??',
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

class AnimeHistoryCard extends StatelessWidget {
  final OfflineMedia data;

  const AnimeHistoryCard({super.key, required this.data});

  String _formatEpisodeNumber() {
    final episode = data.currentEpisode;
    if (episode == null) return 'Episode ??';
    return 'Episode ${episode.number}';
  }

  String _formatTime() {
    if (data.currentEpisode?.durationInMilliseconds == null ||
        data.currentEpisode?.timeStampInMilliseconds == null) {
      return '--:-- / --:--';
    }

    final duration = Duration(
        milliseconds: data.currentEpisode!.durationInMilliseconds ?? 0);
    final timestamp = Duration(
        milliseconds: data.currentEpisode!.timeStampInMilliseconds ?? 0);

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    String formatDuration(Duration duration) {
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return '$minutes:$seconds';
    }

    return '${formatDuration(timestamp)} / ${formatDuration(duration)}';
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      Theme.of(context).colorScheme.surface.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(
            right: BorderSide(
                width: 2, color: Theme.of(context).colorScheme.primary)),
        borderRadius: BorderRadius.circular(12.multiplyRadius()),
        color: Theme.of(context).colorScheme.surface.withAlpha(144),
      ),
      child: TVWrapper(
        onTap: () {
          if (data.currentEpisode == null ||
              data.currentEpisode?.currentTrack == null ||
              data.episodes == null ||
              data.currentEpisode?.videoTracks == null) {
            snackBar(
                "Error: Missing required data. It seems you closed the app directly after watching the episode!",
                duration: 2000,
                maxLines: 3,
                maxWidth: Get.width * 0.6);
          } else {
            if (data.currentEpisode?.source == null) {
              snackBar("Cant Play since user closed the app abruptly");
            }
            final source = Get.find<SourceController>()
                .getExtensionByName(data.currentEpisode!.source!);
            if (source == null) {
              snackBar(
                  "Install ${data.currentEpisode?.source} First, Then Click");
            } else {
              Get.to(() => WatchPage(
                    episodeSrc: data.currentEpisode!.currentTrack!,
                    episodeList: data.episodes!,
                    anilistData: convertOfflineToMedia(data),
                    currentEpisode: data.currentEpisode!,
                    episodeTracks: data.currentEpisode!.videoTracks!,
                  ));
            }
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.multiplyRadius()),
          child: Stack(children: [
            // Background image
            Positioned.fill(
              child: NetworkSizedImage(
                imageUrl: data.currentEpisode?.thumbnail ??
                    data.cover ??
                    data.poster!,
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
                          text: data.currentEpisode?.title ?? '??',
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
                      text: formatTimeAgo(
                          data.currentEpisode?.lastWatchedTime ?? 0),
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
                      text: _formatTime(),
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
