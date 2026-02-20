// ignore_for_file: invalid_use_of_protected_member, prefer_const_constructors, unnecessary_null_comparison
import 'dart:async';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/video.dart' as hive;
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/watch/watch_view.dart';
import 'package:anymex/screens/anime/widgets/episode/normal_episode.dart';
import 'package:anymex/screens/anime/widgets/episode_range.dart';
import 'package:anymex/screens/anime/widgets/track_dialog.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_chip.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
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
  bool _initializedChunk = false;
  Worker? _authLoginWorker;
  Worker? _userProgressWorker;
  Worker? _currentMediaWorker;
  VoidCallback? _offlineStorageListener;
  bool _isUpdatingChunk = false;

  @override
  void initState() {
    super.initState();
    _initUserProgress();
    _initEpisodes();
    _updateChunkIndex();

    _authLoginWorker = ever(auth.isLoggedIn, (_) => _initUserProgress());
    _userProgressWorker = ever(userProgress, (_) {
      _initEpisodes();
    });
    _currentMediaWorker = ever(auth.currentMedia, (_) {
      _initUserProgress();
      _initEpisodes();
    });

    _offlineStorageListener = () {
      final savedData = offlineStorage.getAnimeById(widget.anilistData!.id);
      if (savedData?.currentEpisode != null) {
        savedEpisode.value = savedData!.currentEpisode!;
        offlineEpisodes = savedData.episodes ?? [];
        _initEpisodes();
        _updateChunkIndex();
      }
    };
    offlineStorage.addListener(_offlineStorageListener!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateChunkIndex();
    });
  }

  @override
  void didUpdateWidget(covariant EpisodeListBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLen = oldWidget.episodeList.length;
    final newLen = widget.episodeList.length;
    final oldFirst = oldLen > 0 ? oldWidget.episodeList.first.number : null;
    final newFirst = newLen > 0 ? widget.episodeList.first.number : null;
    final oldLast = oldLen > 0 ? oldWidget.episodeList.last.number : null;
    final newLast = newLen > 0 ? widget.episodeList.last.number : null;

    final contentChanged =
        oldLen != newLen || oldFirst != newFirst || oldLast != newLast;

    if (contentChanged) {
      _initializedChunk = false;
      _initEpisodes();
      _updateChunkIndex();
    }
  }

  @override
  void dispose() {
    _authLoginWorker?.dispose();
    _userProgressWorker?.dispose();
    _currentMediaWorker?.dispose();
    if (_offlineStorageListener != null) {
      offlineStorage.removeListener(_offlineStorageListener!);
    }
    super.dispose();
  }

  void _updateChunkIndex() {
    try {
      if (!mounted || _isUpdatingChunk) return;
      _isUpdatingChunk = true;
      try {
        final chunkedEpisodes = chunkEpisodes(
            widget.episodeList, calculateChunkSize(widget.episodeList));

        if (chunkedEpisodes.length > 1) {
          final progress = continueEpisode.value.number.toInt();

          final chunkIndex = findChunkIndexFromProgress(
            progress,
            chunkedEpisodes,
          );
          final maxIndex = chunkedEpisodes.length - 1;
          final nextIndex = maxIndex < 1 ? 0 : chunkIndex.clamp(1, maxIndex);
          if (selectedChunkIndex.value != nextIndex) {
            selectedChunkIndex.value = nextIndex;
          }
          _initializedChunk = true;
        } else {
          if (selectedChunkIndex.value != 0) {
            selectedChunkIndex.value = 0;
          }
        }
      } finally {
        _isUpdatingChunk = false;
      }
    } catch (e) {
      Logger.e(e.toString(), stackTrace: StackTrace.current);
    }
  }

  void _initUserProgress() {
    final isExtensions = auth.serviceType.value == ServicesType.extensions;
    isLogged.value = isExtensions ? false : auth.isLoggedIn.value;

    int? progress;
    if (isLogged.value) {
      final trackedMedia = auth.onlineService.animeList
          .firstWhereOrNull((e) => e.id == widget.anilistData!.id);
      progress = trackedMedia?.episodeCount?.toInt();
    } else {
      final savedAnime = offlineStorage.getAnimeById(widget.anilistData!.id);
      progress = savedAnime?.currentEpisode?.number.toInt();
    }

    final nextProgress = !isLogged.value && progress != null && progress > 1
        ? progress - 1
        : progress ?? 0;
    if (userProgress.value != nextProgress) {
      userProgress.value = nextProgress;
    }
  }

  void _initEpisodes() {
    if (widget.episodeList.isEmpty) {
      final fallback = Episode(number: "1", title: "Episode 1");
      savedEpisode.value = fallback;
      selectedEpisode.value = fallback;
      continueEpisode.value = fallback;
      offlineEpisodes = const [];
      return;
    }

    final savedData = offlineStorage.getAnimeById(widget.anilistData!.id);
    final nextEpisode = widget.episodeList
        .firstWhereOrNull((e) => e.number.toInt() == (userProgress.value + 1));
    final fallbackEP = widget.episodeList
        .firstWhereOrNull((e) => e.number.toInt() == (userProgress.value));
    final saved = savedData?.currentEpisode;
    final nextSaved = saved ?? widget.episodeList[0];
    if (savedEpisode.value.number != nextSaved.number) {
      savedEpisode.value = nextSaved;
    }
    offlineEpisodes = savedData?.watchedEpisodes ?? widget.episodeList;
    final nextSelected = nextEpisode ?? fallbackEP ?? savedEpisode.value;
    if (selectedEpisode.value.number != nextSelected.number) {
      selectedEpisode.value = nextSelected;
    }
    if (continueEpisode.value.number != nextSelected.number) {
      continueEpisode.value = nextSelected;
    }
  }

  void _handleEpisodeSelection(Episode episode) async {
    selectedEpisode.value = episode;
    streamList.clear();
    fetchServers(episode);
  }

  Episode _resolveEpisode(Episode episode) {
    if (widget.episodeList.isEmpty) {
      return Episode(number: "1", title: "Episode 1");
    }
    return widget.episodeList
            .firstWhereOrNull((e) => e.number == episode.number) ??
        widget.episodeList.first;
  }

  Widget _buildContinueButton() {
    final resolvedContinue = _resolveEpisode(continueEpisode.value);
    final resolvedProgress = _resolveEpisode(savedEpisode.value);

    return ContinueEpisodeButton(
      height: getResponsiveSize(context, mobileSize: 80, desktopSize: 100),
      onPressed: () => _handleEpisodeSelection(resolvedContinue),
      backgroundImage: resolvedContinue.thumbnail ??
          resolvedProgress.thumbnail ??
          widget.anilistData!.cover ??
          widget.anilistData!.poster,
      episode: resolvedContinue,
      progressEpisode: resolvedProgress,
      data: widget.anilistData!,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.episodeList.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: ExpressiveLoadingIndicator()),
      );
    }

    final chunkedEpisodes = chunkEpisodes(
        widget.episodeList, calculateChunkSize(widget.episodeList));
    final hasAnifyThumbs = widget.episodeList.isNotEmpty &&
        (widget.episodeList[0].thumbnail?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Obx(() => _buildContinueButton()),
        ),
        if (chunkedEpisodes.isNotEmpty)
          EpisodeChunkSelector(
            chunks: chunkedEpisodes,
            selectedChunkIndex: selectedChunkIndex,
            onChunkSelected: (index) {
              if (index != selectedChunkIndex.value) {
                selectedChunkIndex.value = index;
              }
            },
          ),
        Obx(() {
          final safeChunkIndex = chunkedEpisodes.isEmpty
              ? 0
              : selectedChunkIndex.value.clamp(0, chunkedEpisodes.length - 1);
          final selectedEpisodes =
              chunkedEpisodes.isNotEmpty ? chunkedEpisodes[safeChunkIndex] : [];

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
              mainAxisExtent: hasAnifyThumbs
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
                    layoutType: hasAnifyThumbs
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
          child: FutureBuilder<List<Video>>(
            future: sourceController.activeSource.value!.methods
                .getVideoList(DEpisode(episodeNumber: ep.number, url: ep.link)),
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
            color: Colors.red.opaque(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnymexText(
            text: errorMessage,
            variant: TextVariant.regular,
            size: 14,
            textAlign: TextAlign.center,
            color: Colors.red.opaque(0.8),
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
              onTap: () async {
                Get.back();
                if (General.shouldAskForTrack.get(true) == false) {
                  await navigate(() => WatchScreen(
                        episodeSrc: e,
                        episodeList: widget.episodeList,
                        anilistData: widget.anilistData!,
                        currentEpisode: selectedEpisode.value,
                        episodeTracks: streamList,
                      ));
                  Future.delayed(const Duration(seconds: 1), () {
                    setState(() {});
                  });
                  return;
                }
                final shouldTrack =
                    widget.anilistData?.serviceType == ServicesType.extensions
                        ? false
                        : await showTrackingDialog(context);

                if (shouldTrack != null) {
                  await navigate(() => WatchScreen(
                        episodeSrc: e,
                        episodeList: widget.episodeList,
                        anilistData: widget.anilistData!,
                        currentEpisode: selectedEpisode.value,
                        episodeTracks: streamList,
                        shouldTrack: shouldTrack,
                      ));
                  Future.delayed(const Duration(seconds: 1), () {
                    setState(() {});
                  });
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 3.0, horizontal: 10),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 2.5, horizontal: 10),
                  title: AnymexText(
                    text: e.quality?.toUpperCase() ?? "Unknown",
                    variant: TextVariant.bold,
                    size: 16,
                    color: context.colors.primary,
                  ),
                  tileColor: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .opaque(0.4),
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
        final safeTitle = (episode.title?.trim().isNotEmpty ?? false)
            ? episode.title!.trim()
            : "Episode ${episode.number}";
        final episodeLabel = 'Episode ${episode.number}: $safeTitle';
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
                  child: AnymeXImage(
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
                      Colors.black.opaque(0.5, iReallyMeanIt: true),
                      Colors.black.opaque(0.5, iReallyMeanIt: true),
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
                          episodeLabel.toUpperCase(),
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
                                  color: context.colors.primary,
                                  height: 2,
                                  width: 6 * episodeLabel.length.toDouble(),
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
                      color: context.colors.primary,
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
