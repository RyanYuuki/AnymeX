import 'dart:math' as math;

import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anime/continue_watching_cards.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_textspan.dart';
import 'package:anymex/widgets/header/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/history/tap_history_cards.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
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
  bool _snapAll = false;
  late final Stream<List<OfflineMedia>> _animeLibraryStream;
  final List<Worker> _workers = [];

  Widget _buildRecentlyOpenedSection(CacheController cacheController) {
    return Obx(() {
      final data = cacheController.getStoredAnime();
      if (data.isEmpty) {
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
                  itemCount: data.length,
                  itemBuilder: (context, i) =>
                      RecentlyOpenedAnimeCard(media: data[i]),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildContinueWatchingSection(
      OfflineStorageController offlineStorageController, Settings settings) {
    return Obx(() {
      if (!settings.showContinueWatchingCard) {
        return const SizedBox.shrink();
      }
      return StreamBuilder<List<OfflineMedia>>(
        initialData: offlineStorageController.getAnimeLibrarySync(),
        stream: _animeLibraryStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const SizedBox.shrink();
          }
          final historyData = (snapshot.data ?? const <OfflineMedia>[])
              .where((e) => e.currentEpisode?.currentTrack != null)
              .toList()
            ..sort((a, b) => (b.currentEpisode?.lastWatchedTime ?? 0)
                .compareTo(a.currentEpisode?.lastWatchedTime ?? 0));
          final visibleHistory = historyData.take(20).toList(growable: false);

          if (visibleHistory.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnymeXText(
                      "Local History",
                      style: TextStyle(
                        fontFamily: "Poppins-SemiBold",
                        fontSize: 17,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showClearAllHistoryDialog(
                          context, offlineStorageController, visibleHistory),
                      child: AnymeXText(
                        "Clear All",
                        style: TextStyle(
                          fontFamily: "Poppins-SemiBold",
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 228,
                child: RepaintBoundary(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    scrollDirection: Axis.horizontal,
                    itemCount: visibleHistory.length,
                    itemBuilder: (context, i) => _RemovableHistoryCard(
                      key: ValueKey(visibleHistory[i].mediaId),
                      media: HistoryModel.fromOfflineMedia(
                          visibleHistory[i], ItemType.anime),
                      snapAll: _snapAll,
                      onRemoved: () {
                        offlineStorageController.clearMediaHistory(
                          visibleHistory[i].mediaId ?? '',
                          mediaType: ItemType.anime,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  void _showClearAllHistoryDialog(BuildContext context,
      OfflineStorageController controller, List<OfflineMedia> items) {
    showDialog(
      context: context,
      builder: (context) => AnymeXDialog(
        title: 'Clear All History',
        contentWidget: const AnymeXText(
          'Are you sure you want to clear all local watch history? This action cannot be undone.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
        ),
        confirmText: 'Clear All',
        onConfirm: () {
          HapticFeedback.mediumImpact();
          setState(() => _snapAll = true);
          Future.delayed(const Duration(milliseconds: 1500), () {
            controller.clearMediaHistoryBulk(
              items.map((e) => e.mediaId ?? ''),
              mediaType: ItemType.anime,
            );
            if (mounted) setState(() => _snapAll = false);
          });
        },
      ),
    );
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
      _buildContinueWatchingSection(offlineStorageController, settings),
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
    _animeLibraryStream = Get.find<OfflineStorageController>().watchAnimeLibrary().asBroadcastStream();
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
    final double bottomNavBarHeight = isDesktop ? 20.0 : (MediaQuery.paddingOf(context).bottom + 65.0);

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

class _RemovableHistoryCard extends StatefulWidget {
  final HistoryModel media;
  final VoidCallback onRemoved;
  final bool snapAll;

  const _RemovableHistoryCard({
    super.key,
    required this.media,
    required this.onRemoved,
    this.snapAll = false,
  });

  @override
  State<_RemovableHistoryCard> createState() => _RemovableHistoryCardState();
}

class _RemovableHistoryCardState extends State<_RemovableHistoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );
  late final Animation<double> _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
  );

  @override
  void didUpdateWidget(covariant _RemovableHistoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snapAll && !oldWidget.snapAll) {
      _controller.forward(from: 0);
    }
  }

  void _triggerRemoval() {
    HapticFeedback.lightImpact();
    _controller.forward(from: 0).then((_) => widget.onRemoved());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value,
            child: SizedBox(
              width: 300,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: child,
              ),
            ),
          ),
        );
      },
      child: ContinueWatchingCard(
        media: widget.media,
        onRemove: _triggerRemoval,
      ),
    );
  }
}
