import 'dart:math' as math;

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

  Widget _buildNewEpisodesSection() {
    final serviceHandler = Get.find<ServiceHandler>();
    return Obx(() {
      final entries = <(Media, int, int, DateTime?)>[];

      if (serviceHandler.isLoggedIn.value ||
          serviceHandler.animeList.isNotEmpty) {
        final now = DateTime.now();
        for (final item in serviceHandler.animeList) {
          if (item.type?.toUpperCase() == 'MANGA' || item.id == null) continue;
          final watched = item.effectiveProgress;
          int latestReleased = 0;
          if (item.releasedEpisodes != null &&
              item.releasedEpisodes!.isNotEmpty) {
            latestReleased = int.tryParse(item.releasedEpisodes!) ?? 0;
          } else if (item.mediaStatus?.toUpperCase() == 'COMPLETED' ||
              item.mediaStatus?.toUpperCase() == 'FINISHED') {
            latestReleased = int.tryParse(item.totalEpisodes ?? '') ?? 0;
          }

          final status = item.watchingStatus?.toUpperCase();
          final isWatching = status == 'CURRENT' ||
              status == 'WATCHING' ||
              status == 'REPEATING' ||
              status == 'REWATCHING';

          if (!isWatching || latestReleased <= watched) {
            continue;
          }

          final media = CardData.fromTrackedMedia(item).data;
          final releaseDate = NewEpisodeReleaseCard.calculateReleaseDate(
            media: media,
            latestReleasedEpisode: latestReleased,
            itemEndDate: item.endDate,
            mediaStatus: item.mediaStatus,
          );

          final mediaStatus = item.mediaStatus?.toUpperCase();
          final isStillAiring = mediaStatus == 'RELEASING' ||
              mediaStatus == 'AIRING' ||
              item.nextAiringEpisode != null;

          if (!isStillAiring) {
            if (releaseDate == null ||
                now.isAfter(releaseDate.add(const Duration(days: 7)))) {
              continue;
            }
          }

          entries.add((media, watched, latestReleased, releaseDate));
        }

        entries.sort((a, b) {
          final dateA = a.$4;
          final dateB = b.$4;
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });
      }

      if (entries.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: SizedBox(
          height: 110,
          child: RepaintBoundary(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              itemBuilder: (context, i) => NewEpisodeReleaseCard(
                media: entries[i].$1,
                watchedEpisode: entries[i].$2,
                latestReleasedEpisode: entries[i].$3,
                releaseDate: entries[i].$4,
              ),
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildHomeWidgets({
    required BuildContext context,
    required ServiceHandler serviceHandler,
    required OfflineStorageController offlineStorageController,
    required Settings settings,
  }) {
    final baseWidgets = serviceHandler.homeWidgets(context);
    final localSections = <Widget>[
      _buildNewEpisodesSection(),
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
                  SizedBox(height: bottomNavBarHeight + 150),
                ],
              ),
            ),
            if (!isDesktop)
              CustomAnimatedAppBar(
                isVisible: _isAppBarVisibleExternally,
                scrollController: _scrollController,
                headerContent: Header(
                  leading: const HeaderLogoButton(),
                  title: 'AnymeX',
                  titleColor: Theme.of(context).colorScheme.primary,
                  subtitleWidget: const HeaderGreetingSubtitle(),
                  actions: const [HeaderProfileAvatar()],
                ),
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
