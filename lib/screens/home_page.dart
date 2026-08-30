import 'dart:math' as math;

import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_textspan.dart';
import 'package:anymex/widgets/header/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/history/tap_history_cards.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/media_items/media_item.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ScrollController _scrollController;
  final ValueNotifier<bool> _isAppBarVisibleExternally =
      ValueNotifier<bool>(true);
  final List<Worker> _workers = [];

  Widget _buildRecentlyOpenedSection(CacheController cacheController) {
    return Obx(() {
      final entries = <(Media, int, int)>[];
      final seenIds = <String>{};

      if (serviceHandler.isLoggedIn.value ||
          serviceHandler.animeList.isNotEmpty) {
        for (final item in serviceHandler.animeList) {
          if (item.type?.toUpperCase() == 'MANGA' || item.id == null) continue;
          final watched = int.tryParse(item.episodeCount ?? '') ??
              (item.userProgress ?? 0);
          int latestReleased = 0;
          if (item.releasedEpisodes != null &&
              item.releasedEpisodes!.isNotEmpty) {
            latestReleased = int.tryParse(item.releasedEpisodes!) ?? 0;
          } else if (item.mediaStatus?.toUpperCase() == 'COMPLETED') {
            latestReleased = int.tryParse(item.totalEpisodes ?? '') ?? 0;
          }

          final isWatching = item.watchingStatus?.toUpperCase() == 'CURRENT' ||
              item.watchingStatus?.toUpperCase() == 'WATCHING' ||
              (watched > 0 &&
                  item.watchingStatus?.toUpperCase() != 'COMPLETED');

          if (isWatching && latestReleased > watched) {
            seenIds.add(item.id!);
            final media = CardData.fromTrackedMedia(item).data;
            entries.add((media, watched, latestReleased));
          }
        }
      }

      final storedAnime = cacheController
          .getStoredAnime()
          .where((m) => m.mediaType == ItemType.anime || m.type == 'ANIME');

      for (final m in storedAnime) {
        if (seenIds.contains(m.id)) continue;

        int latestReleased = 0;
        if (m.nextAiringEpisode != null) {
          final airingAt = m.nextAiringEpisode!.airingAt;
          final isAired =
              DateTime.now().millisecondsSinceEpoch ~/ 1000 >= airingAt;
          latestReleased = isAired
              ? m.nextAiringEpisode!.episode
              : (m.nextAiringEpisode!.episode - 1);
        } else if (m.status != null && m.status!.toUpperCase() == 'COMPLETED') {
          latestReleased = int.tryParse(m.totalEpisodes ?? '') ?? 0;
        }

        int watched = 0;
        final offline = Get.isRegistered<OfflineStorageController>()
            ? Get.find<OfflineStorageController>().getAnimeById(m.id)
            : null;
        if (offline != null) {
          if (offline.watchedEpisodes != null &&
              offline.watchedEpisodes!.isNotEmpty) {
            watched = offline.watchedEpisodes!.length;
          } else if (offline.currentEpisode?.number != null) {
            watched = int.tryParse(offline.currentEpisode!.number) ?? 0;
          }
        }

        if (latestReleased > watched && watched > 0) {
          seenIds.add(m.id);
          entries.add((m, watched, latestReleased));
        }
      }

      if (entries.isEmpty && kDebugMode) {
        final recentAnime = cacheController
            .getStoredAnime()
            .where((m) => m.mediaType == ItemType.anime || m.type == 'ANIME')
            .toList();

        for (int i = 0; i < recentAnime.length; i++) {
          final m = recentAnime[i];
          final dummyWatched = (i + 1) * 3;
          final dummyLatest = dummyWatched + (i % 2 == 0 ? 1 : 2);
          entries.add((m, dummyWatched, dummyLatest));
        }
      }

      if (entries.isEmpty) {
        final recentAnime = cacheController
            .getStoredAnime()
            .where((m) => m.mediaType == ItemType.anime || m.type == 'ANIME')
            .toList();

        if (recentAnime.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SizedBox(
                height: 100,
                child: RepaintBoundary(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: recentAnime.length,
                    itemBuilder: (context, i) =>
                        RecentlyOpenedAnimeCard(media: recentAnime[i]),
                  ),
                ),
              ),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SizedBox(
              height: 100,
              child: RepaintBoundary(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: entries.length,
                  itemBuilder: (context, i) => RecentlyOpenedAnimeCard(
                    media: entries[i].$1,
                    watchedEpisode: entries[i].$2,
                    latestReleasedEpisode: entries[i].$3,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  List<Widget> _buildHomeWidgets({
    required BuildContext context,
    required ServiceHandler serviceHandler,
    required CacheController cacheController,
    required OfflineStorageController offlineStorageController,
    required Settings settings,
  }) {
    final baseWidgets = serviceHandler.homeWidgets(context);
    final localSections = <Widget>[
      _buildRecentlyOpenedSection(cacheController),
    ];

    int insertionIndex;
    if (serviceHandler.serviceType.value == ServicesType.simkl) {
      insertionIndex = serviceHandler.isLoggedIn.value ? 3 : 2;
    } else if (!serviceHandler.isLoggedIn.value ||
        serviceHandler.serviceType.value == ServicesType.extensions) {
      insertionIndex = 0;
    } else {
      insertionIndex = 2;
    }
    insertionIndex = math.min(insertionIndex, baseWidgets.length);

    return [
      ...baseWidgets.take(insertionIndex),
      ...localSections,
      ...baseWidgets.skip(insertionIndex),
    ];
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final serviceHandler = Get.find<ServiceHandler>();
    _workers.add(ever(serviceHandler.serviceType, (_) {
      if (mounted) setState(() {});
    }));
    _workers.add(ever(serviceHandler.isLoggedIn, (_) {
      if (mounted) setState(() {});
    }));
  }

  ScrollController get scrollController => _scrollController;

  @override
  void dispose() {
    for (final w in _workers) {
      w.dispose();
    }
    _workers.clear();
    _scrollController.dispose();
    _isAppBarVisibleExternally.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cacheController = Get.find<CacheController>();
    final offlineStorageController = Get.find<OfflineStorageController>();
    final serviceHandler = Get.find<ServiceHandler>();
    final settings = Get.find<Settings>();
    final sourceController = Get.find<SourceController>();
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    const appBarHeight = kToolbarHeight + 20;
    final double bottomNavBarHeight =
        isDesktop ? 20.0 : (MediaQuery.paddingOf(context).bottom + 65.0);

    bool isMobile =
        getResponsiveValue(context, desktopValue: false, mobileValue: true);

    final TextAlign textAlignment =
        isMobile ? TextAlign.center : TextAlign.left;

    final List<dynamic> novelData = [];

    return RefreshIndicator(
      onRefresh: () {
        if (!serviceHandler.isLoggedIn.value) {
          snackBar(
              "W-what are you doing step-bro, login before you do that (●´⌓`●)",
              duration: 1200);
        }
        return serviceHandler.refresh();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: isMobile
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: isDesktop ? 10 : statusBarHeight + appBarHeight,
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: AnymeXTextSpans(
                        fontSize: 27,
                        spans: [
                          const AnymeXTextSpan(
                              text: 'Hey ',
                              size: 30,
                              variant: TextVariant.bold),
                          AnymeXTextSpan(
                              text:
                                  '${serviceHandler.isLoggedIn.value ? serviceHandler.profileData.value.name : 'Guest'}',
                              size: 30,
                              color: context.colors.primary,
                              variant: TextVariant.bold),
                          const AnymeXTextSpan(
                              text: ', what are we doing today?',
                              size: 30,
                              variant: TextVariant.bold),
                        ],
                        textAlign: textAlignment,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: isMobile
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AnymeXText(
                          'Find your favourite anime or manga, manhwa or whatever you like!',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .inverseSurface
                                .withOpacity(0.8),
                          ),
                          textAlign: textAlignment,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Column(
                        children: _buildHomeWidgets(
                          context: context,
                          serviceHandler: serviceHandler,
                          cacheController: cacheController,
                          offlineStorageController: offlineStorageController,
                          settings: settings,
                        ),
                      ),
                      if (novelData.isNotEmpty)
                        ReusableCarousel(
                          title: "Recommended Novels",
                          data: novelData,
                          type: ItemType.novel,
                          source: sourceController.activeNovelSource.value,
                        ),
                    ],
                  ),
                  SizedBox(height: bottomNavBarHeight),
                ],
              ),
            ),
            if (!isDesktop)
              CustomAnimatedAppBar(
                isVisible: _isAppBarVisibleExternally,
                scrollController: _scrollController,
                headerContent: const Header(type: PageType.home),
                visibleStatusBarStyle: SystemUiOverlayStyle(
                  statusBarIconBrightness:
                      Theme.of(context).brightness == Brightness.light
                          ? Brightness.dark
                          : Brightness.light,
                  statusBarBrightness: Theme.of(context).brightness,
                  statusBarColor: Colors.transparent,
                ),
                hiddenStatusBarStyle: SystemUiOverlayStyle(
                  statusBarIconBrightness:
                      Theme.of(context).brightness == Brightness.light
                          ? Brightness.light
                          : Brightness.dark,
                  statusBarBrightness:
                      Theme.of(context).brightness == Brightness.light
                          ? Brightness.dark
                          : Brightness.light,
                  statusBarColor: Colors.transparent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
