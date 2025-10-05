// ignore_for_file: invalid_use_of_protected_member, prefer_const_constructors, unnecessary_null_comparison
import 'dart:async';
import 'dart:ui';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Offline/Hive/video.dart' as hive;
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/screens/anime/watch/watch_view.dart';
import 'package:anymex/screens/anime/watch_page.dart';
import 'package:anymex/screens/anime/widgets/episode/normal_episode.dart';
import 'package:anymex/screens/anime/widgets/episode_range.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_chip.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class EpisodeListBuilder extends StatefulWidget {
  const EpisodeListBuilder({
    super.key,
    required this.episodeList,
    required this.anilistData,
  });

  final List<Episode> episodeList;
  final Media? anilistData;

  @override
  State<EpisodeListBuilder> createState() => _EpisodeListBuilderState();
}

class _EpisodeListBuilderState extends State<EpisodeListBuilder> {
  final selectedChunkIndex = 1.obs;
  final RxList<hive.Video> streamList = <hive.Video>[].obs;
  final sourceController = Get.find<SourceController>();
  final auth = Get.find<ServiceHandler>();
  final offlineStorage = Get.find<OfflineStorageController>();

  final RxBool isLogged = false.obs;
  final RxInt userProgress = 0.obs;
  final Rx<Episode> selectedEpisode = Episode(number: "1").obs;
  final Rx<Episode> continueEpisode = Episode(number: "1").obs;
  final Rx<Episode> savedEpisode = Episode(number: "1").obs;
  List<Episode> offlineEpisodes = [];

  @override
  void initState() {
    super.initState();
    _initEpisodes();
    Future.delayed(Duration(milliseconds: 300), () {
      _initUserProgress();
    });
    _initEpisodes();

    ever(auth.isLoggedIn, (_) => _initUserProgress());
    ever(userProgress, (_) => _initEpisodes());
    ever(auth.currentMedia, (_) => {_initUserProgress(), _initEpisodes()});

    offlineStorage.addListener(() {
      final savedData = offlineStorage.getAnimeById(widget.anilistData!.id);
      if (savedData?.currentEpisode != null) {
        savedEpisode.value = savedData!.currentEpisode!;
        offlineEpisodes = savedData.episodes ?? [];
        _initEpisodes();
      }
    });
  }

  void _initUserProgress() {
    final isExtensions = auth.serviceType.value == ServicesType.extensions;
    isLogged.value = isExtensions ? false : auth.isLoggedIn.value;
    final progress = isLogged.value
        ? auth.currentMedia.value.episodeCount?.toInt()
        : offlineStorage
            .getAnimeById(widget.anilistData!.id)
            ?.currentEpisode
            ?.number
            .toInt();

    userProgress.value = !isLogged.value && progress != null && progress > 1
        ? progress - 1
        : progress ?? 0;
  }

  void _initEpisodes() {
    final savedData = offlineStorage.getAnimeById(widget.anilistData!.id);
    final nextEpisode = widget.episodeList
        .firstWhereOrNull((e) => e.number.toInt() == (userProgress.value + 1));
    final fallbackEP = widget.episodeList
        .firstWhereOrNull((e) => e.number.toInt() == (userProgress.value));
    final saved = savedData?.currentEpisode;
    savedEpisode.value = saved ?? widget.episodeList[0];
    offlineEpisodes = savedData?.watchedEpisodes ?? widget.episodeList;
    selectedEpisode.value = nextEpisode ?? fallbackEP ?? savedEpisode.value;
    continueEpisode.value = nextEpisode ?? fallbackEP ?? savedEpisode.value;
  }

  void _handleEpisodeSelection(Episode episode) {
    selectedEpisode.value = episode;
    streamList.clear();
    fetchServers(episode);
  }

  Widget _buildContinueButton() {
    return ContinueEpisodeButton(
      height: getResponsiveSize(context, mobileSize: 80, desktopSize: 100),
      onPressed: () => _handleEpisodeSelection(continueEpisode.value),
      backgroundImage: continueEpisode.value.thumbnail ??
          savedEpisode.value.thumbnail ??
          widget.anilistData!.cover ??
          widget.anilistData!.poster,
      episode: continueEpisode.value,
      progressEpisode: savedEpisode.value,
      data: widget.anilistData!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chunkedEpisodes = chunkEpisodes(
        widget.episodeList, calculateChunkSize(widget.episodeList));

    final isAnify = (widget.episodeList[0].thumbnail?.isNotEmpty ?? false).obs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Obx(_buildContinueButton),
        ),
        EpisodeChunkSelector(
          chunks: chunkedEpisodes,
          selectedChunkIndex: selectedChunkIndex,
          onChunkSelected: (index) => setState(() {}),
        ),
        Obx(() {
          final selectedEpisodes = chunkedEpisodes.isNotEmpty
              ? chunkedEpisodes[selectedChunkIndex.value]
              : [];

          return GridView.builder(
            padding: const EdgeInsets.only(top: 15),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: getResponsiveCrossAxisCount(
                context,
                baseColumns: 1,
                maxColumns: 3,
                mobileItemWidth: 400,
                tabletItemWidth: 400,
                desktopItemWidth: 200,
              ),
              mainAxisSpacing:
                  getResponsiveSize(context, mobileSize: 15, desktopSize: 10),
              crossAxisSpacing: 15,
              mainAxisExtent: isAnify.value
                  ? 200
                  : getResponsiveSize(context,
                      mobileSize: 100, desktopSize: 130),
            ),
            itemCount: selectedEpisodes.length,
            itemBuilder: (context, index) {
              final episode = selectedEpisodes[index] as Episode;
              return Obx(() {
                final currentEpisode =
                    episode.number.toInt() + 1 == userProgress.value;
                final completedEpisode =
                    episode.number.toInt() <= userProgress.value;
                final isSelected =
                    selectedEpisode.value.number == episode.number;

                return Opacity(
                  opacity: completedEpisode
                      ? 0.5
                      : currentEpisode
                          ? 0.8
                          : 1,
                  child: BetterEpisode(
                    episode: episode,
                    isSelected: isSelected,
                    layoutType: isAnify.value
                        ? EpisodeLayoutType.detailed
                        : EpisodeLayoutType.compact,
                    fallbackImageUrl:
                        episode.thumbnail ?? widget.anilistData!.poster,
                    offlineEpisodes: offlineEpisodes,
                    onTap: () => _handleEpisodeSelection(episode),
                  ),
                );
              });
            },
          );
        }),
      ],
    );
  }

  HeadlessInAppWebView? headlessWebView;
  Timer? scrapingTimer;

  Future<void> fetchServers(Episode ep) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          child: settingsController.preferences
                  .get('universal_scrapper', defaultValue: false)
              ? _buildUniversalScraper(ep.link!)
              : FutureBuilder<List<Video>>(
                  future: sourceController.activeSource.value!.methods
                      .getVideoList(
                          DEpisode(episodeNumber: ep.number, url: ep.link)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildScrapingLoadingState(true);
                    } else if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    } else {
                      streamList.value = snapshot.data
                              ?.map((e) => hive.Video.fromVideo(e))
                              .toList() ??
                          [];
                      return _buildServerList();
                    }
                  },
                ),
        );
      },
    );
  }

  Widget _buildUniversalScraper(String url) {
    return FutureBuilder<List<Video>>(
      future: _scrapeVideoStreams(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildScrapingLoadingState(false);
        } else if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        } else {
          streamList.value = streamList.value =
              snapshot.data?.map((e) => hive.Video.fromVideo(e)).toList() ?? [];
          return _buildServerList();
        }
      },
    );
  }

  Future<List<Video>> _scrapeVideoStreams(String url) async {
    final completer = Completer<List<Video>>();
    final foundVideos = <Video>[];
    debugPrint('Calling => $url');

    await headlessWebView?.dispose();

    scrapingTimer = Timer(Duration(seconds: 30), () {
      headlessWebView?.dispose();
      if (!completer.isCompleted) {
        completer.complete(foundVideos);
      }
    });

    try {
      headlessWebView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        initialSettings: InAppWebViewSettings(
          userAgent:
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
          javaScriptEnabled: true,
        ),
        onLoadStop: (controller, loadedUrl) async {
          await Future.delayed(Duration(seconds: 8));

          try {
            await controller.evaluateJavascript(source: """
          const playButtons = document.querySelectorAll('button[class*="play"], .play-button, [aria-label*="play"], [title*="play"]');
          playButtons.forEach(btn => btn.click());
          
          const videos = document.querySelectorAll('video');
          videos.forEach(video => {
            video.play().catch(e => {});
            video.click();
          });
          
          const containers = document.querySelectorAll('.video-container, .player-container, .video-player, .player');
          containers.forEach(container => container.click());
        """);
          } catch (e) {
            print('JavaScript execution error: $e');
          }

          await Future.delayed(Duration(seconds: 5));

          if (!completer.isCompleted) {
            completer.complete(foundVideos);
          }
        },
        shouldInterceptRequest: (controller, request) async {
          final requestUrl = request.url.toString();
          final headers = request.headers ?? {};
          print('Intercepted request: $requestUrl');

          if (_isVideoStream(requestUrl)) {
            final video = Video(
              requestUrl,
              _extractQuality(requestUrl),
              url,
              headers:
                  headers.isNotEmpty ? Map<String, String>.from(headers) : null,
            );

            final baseUrl = requestUrl.split('?')[0];
            if (!foundVideos.any((v) => v.url.split('?')[0] == baseUrl)) {
              foundVideos.add(video);
              print(
                  'Added video stream: $requestUrl (Quality: ${video.quality})');
            } else {
              print('Skipped duplicate stream: $requestUrl');
            }
          }

          return null;
        },
        onReceivedServerTrustAuthRequest: (controller, challenge) async {
          return ServerTrustAuthResponse(
              action: ServerTrustAuthResponseAction.PROCEED);
        },
      );

      await headlessWebView?.run();
    } catch (e) {
      print('Headless WebView error: $e');
      if (!completer.isCompleted) {
        completer.complete(foundVideos);
      }
    }

    final result = await completer.future;
    scrapingTimer?.cancel();
    await headlessWebView?.dispose();

    print('Final video count: ${result.length}');
    return result;
  }

  bool _isVideoStream(String url) {
    final lowercaseUrl = url.toLowerCase();
    return lowercaseUrl.contains('m3u8') ||
        lowercaseUrl.contains('.mp4') ||
        lowercaseUrl.contains('manifest') ||
        (lowercaseUrl.contains('video') &&
            (lowercaseUrl.contains('stream') ||
                lowercaseUrl.contains('play'))) ||
        lowercaseUrl.contains('playlist') ||
        lowercaseUrl.contains('.mpd');
  }

  String _extractQuality(String url) {
    final lowercaseUrl = url.toLowerCase();
    final filename = url.split('/').last.toLowerCase();

    if (filename.contains('master.m3u8')) return 'Auto';
    if (filename.contains('playlist.m3u8')) return 'Auto';

    final qualityPatterns = [
      RegExp(r'\b2160p\b', caseSensitive: false), // 4K
      RegExp(r'\b1080p\b', caseSensitive: false),
      RegExp(r'\b720p\b', caseSensitive: false),
      RegExp(r'\b480p\b', caseSensitive: false),
      RegExp(r'\b360p\b', caseSensitive: false),
      RegExp(r'\b240p\b', caseSensitive: false),
    ];

    final qualityLabels = ['4K', '1080p', '720p', '480p', '360p', '240p'];

    for (int i = 0; i < qualityPatterns.length; i++) {
      if (qualityPatterns[i].hasMatch(url)) {
        return qualityLabels[i];
      }
    }

    if (lowercaseUrl.contains('4k') || lowercaseUrl.contains('uhd')) {
      return '4K';
    }

    if (lowercaseUrl.contains('hd')) return 'HD';

    return url.split('/').last;
  }

  Widget _buildScrapingLoadingState(bool fromSrc) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExpressiveLoadingIndicator(),
          SizedBox(height: 16),
          Text(
            'Scanning for video streams...',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'This may take up to 30 seconds',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          10.height(),
          if (!fromSrc)
            AnymexChip(
              showCheck: false,
              isSelected: true,
              label: 'Using Universal Scrapper',
              onSelected: (v) {},
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    scrapingTimer?.cancel();
    headlessWebView?.dispose();
    super.dispose();
  }

  Widget _buildErrorState(String errorMessage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        10.height(),
        AnymexText(
          text: "Error Occured",
          variant: TextVariant.bold,
          size: 18,
        ),
        20.height(),
        AnymexText(
          text: "Server-chan is taking a nap!",
          variant: TextVariant.semiBold,
          size: 18,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnymexText(
            text: errorMessage,
            variant: TextVariant.regular,
            size: 14,
            textAlign: TextAlign.center,
            color: Colors.red.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const SizedBox(
      height: 200,
      child: Center(
        child: AnymexText(
          text: "No servers available",
          variant: TextVariant.bold,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildServerList() {
    return Container(
      padding: const EdgeInsets.all(10),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: SuperListView(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            alignment: Alignment.center,
            child: const AnymexText(
              text: "Choose Server",
              size: 18,
              variant: TextVariant.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...streamList.map((e) {
            return InkWell(
              onTap: () {
                Get.back();
                navigate(() => settingsController.preferences
                        .get('useOldPlayer', defaultValue: false)
                    ? WatchPage(
                        episodeSrc: e,
                        episodeList: widget.episodeList,
                        anilistData: widget.anilistData!,
                        currentEpisode: selectedEpisode.value,
                        episodeTracks: streamList,
                      )
                    : WatchScreen(
                        episodeSrc: e,
                        episodeList: widget.episodeList,
                        anilistData: widget.anilistData!,
                        currentEpisode: selectedEpisode.value,
                        episodeTracks: streamList,
                      ));
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 3.0, horizontal: 10),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 2.5, horizontal: 10),
                  title: AnymexText(
                    text: e.quality.toUpperCase(),
                    variant: TextVariant.bold,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tileColor: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  trailing: const Icon(Iconsax.play5),
                  subtitle: AnymexText(
                    text: sourceController.activeSource.value!.name!
                        .toUpperCase(),
                    variant: TextVariant.semiBold,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class ContinueEpisodeButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String backgroundImage;
  final double height;
  final double borderRadius;
  final Color textColor;
  final TextStyle? textStyle;
  final Episode episode;
  final Episode progressEpisode;
  final Media data;

  const ContinueEpisodeButton({
    super.key,
    required this.onPressed,
    required this.backgroundImage,
    this.height = 60,
    this.borderRadius = 18,
    this.textColor = Colors.white,
    this.textStyle,
    required this.episode,
    required this.progressEpisode,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double progressPercentage;
        if (progressEpisode.number != episode.number ||
            progressEpisode.timeStampInMilliseconds == null ||
            progressEpisode.durationInMilliseconds == null ||
            progressEpisode.durationInMilliseconds! <= 0 ||
            progressEpisode.timeStampInMilliseconds! <= 0) {
          progressPercentage = 0.0;
        } else {
          progressPercentage = (progressEpisode.timeStampInMilliseconds! /
                  progressEpisode.durationInMilliseconds!)
              .clamp(0.0, 0.99);
        }

        return Container(
          width: double.infinity,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: NetworkSizedImage(
                    height: height,
                    width: double.infinity,
                    imageUrl: backgroundImage,
                    alignment: Alignment.topCenter,
                    radius: 0,
                    errorImage: data.cover ?? data.poster,
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.5),
                    ]),
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ),
              Positioned.fill(
                child: AnymexButton(
                  onTap: onPressed,
                  padding: EdgeInsets.zero,
                  border: BorderSide(color: Colors.transparent),
                  color: Colors.transparent,
                  radius: borderRadius,
                  child: SizedBox(
                    width: getResponsiveValue(context,
                        mobileValue: (Get.width * 0.8), desktopValue: null),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Episode ${episode.number}: ${episode.title}'
                              .toUpperCase(),
                          style: textStyle ??
                              TextStyle(
                                color: textColor,
                                fontFamily: 'Poppins-SemiBold',
                              ),
                          textAlign: TextAlign.center,
                        ),
                        PlatformBuilder(
                            androidBuilder: SizedBox.shrink(),
                            desktopBuilder: Column(
                              children: [
                                const SizedBox(height: 3),
                                Container(
                                  color: Theme.of(context).colorScheme.primary,
                                  height: 2,
                                  width: 6 *
                                      'Episode ${episode.number}: ${episode.title}'
                                          .length
                                          .toDouble(),
                                )
                              ],
                            ))
                      ],
                    ),
                  ),
                ),
              ),
              if (progressPercentage > 0)
                Positioned(
                  height: 2,
                  bottom: 0,
                  left: 0,
                  child: Container(
                    height: 4,
                    width: constraints.maxWidth * progressPercentage,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
