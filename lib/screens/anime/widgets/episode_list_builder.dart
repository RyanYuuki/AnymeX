// ignore_for_file: invalid_use_of_protected_member, prefer_const_constructors, unnecessary_null_comparison
import 'dart:async';
import 'dart:math' as math;
import 'dart:math';

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
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/foundation.dart';
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
  final RxMap<String, String> selectedSortValues = <String, String>{}.obs;
  final RxList<hive.Video> streamList = <hive.Video>[].obs;
  final RxBool isServerStreamLoading = false.obs;
  final sourceController = Get.find<SourceController>();
  final auth = Get.find<ServiceHandler>();
  final offlineStorage = Get.find<OfflineStorageController>();

  final RxBool isLogged = false.obs;
  final RxInt userProgress = 0.obs;
  final Rx<Episode> selectedEpisode = Episode(number: "1").obs;
  final Rx<Episode> continueEpisode = Episode(number: "1").obs;
  final Rx<Episode> savedEpisode = Episode(number: "1").obs;
  List<Episode> offlineEpisodes = [];
  Worker? _authLoginWorker;
  Worker? _userProgressWorker;
  Worker? _currentMediaWorker;
  VoidCallback? _offlineStorageListener;
  bool _isUpdatingChunk = false;

  @override
  void initState() {
    super.initState();
    _initSortGrouping();
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
      _initSortGrouping();
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
        final episodesToChunk = _episodesForSelectedSortKey();
        final chunkedEpisodes =
            chunkEpisodes(episodesToChunk, calculateChunkSize(episodesToChunk));

        if (chunkedEpisodes.length > 1) {
          final progress =
              double.tryParse(continueEpisode.value.number)?.toInt() ?? 0;

          final chunkIndex = findChunkIndexFromProgress(
            progress,
            chunkedEpisodes,
          );
          final maxIndex = chunkedEpisodes.length - 1;
          final nextIndex = maxIndex < 1 ? 0 : chunkIndex.clamp(1, maxIndex);
          if (selectedChunkIndex.value != nextIndex) {
            selectedChunkIndex.value = nextIndex;
          }
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
      progress = double.tryParse(trackedMedia?.episodeCount ?? '')?.toInt();
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

  void _initSortGrouping() {
    final sections = buildEpisodeSortSections(widget.episodeList);
    final nextSelection = <String, String>{};

    for (final section in sections) {
      final availableValues = _availableValuesForKey(
        section.key,
        sections: sections,
        activeSelection: selectedSortValues,
      );
      if (availableValues.isEmpty) {
        continue;
      }

      final currentValue = selectedSortValues[section.key];
      nextSelection[section.key] = availableValues.contains(currentValue)
          ? currentValue!
          : availableValues.first;
    }

    if (selectedSortValues.length != nextSelection.length ||
        nextSelection.entries.any(
          (entry) => selectedSortValues[entry.key] != entry.value,
        )) {
      selectedSortValues.assignAll(nextSelection);
    }
  }

  List<Episode> _episodesForSelectedSortKey() {
    final filteredEpisodes = widget.episodeList.where((episode) {
      final sortMap = episode.sortMap;
      return selectedSortValues.entries.every(
        (entry) => sortMap[entry.key]?.trim() == entry.value,
      );
    }).toList();

    filteredEpisodes.sort(_compareEpisodesByNumber);
    return filteredEpisodes;
  }

  void _handleEpisodeSelection(Episode episode) async {
    selectedEpisode.value = episode;
    streamList.clear();
    isServerStreamLoading.value = false;
    fetchServers(episode);
  }

  Episode _resolveEpisode(Episode episode) {
    if (widget.episodeList.isEmpty) {
      return Episode(number: "1", title: "Episode 1");
    }
    return widget.episodeList.firstWhereOrNull((e) {
          return _areEpisodesEquivalent(e, episode);
        }) ??
        widget.episodeList
            .firstWhereOrNull((e) => e.number == episode.number) ??
        widget.episodeList.first;
  }

  List<String> _availableValuesForKey(
    String key, {
    List<EpisodeSortSection>? sections,
    Map<String, String>? activeSelection,
  }) {
    final effectiveSelection = activeSelection ?? selectedSortValues;
    final values = widget.episodeList
        .where((episode) {
          final sortMap = episode.sortMap;
          return effectiveSelection.entries.every((entry) {
            if (entry.key == key) {
              return true;
            }
            return sortMap[entry.key]?.trim() == entry.value;
          });
        })
        .map((episode) => episode.sortMap[key]?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort(compareEpisodeSortValues);

    if (values.isNotEmpty) {
      return values;
    }

    final fallbackSection =
        (sections ?? buildEpisodeSortSections(widget.episodeList))
            .firstWhereOrNull((section) => section.key == key);
    return fallbackSection?.values ?? const [];
  }

  bool _areEpisodesEquivalent(Episode first, Episode second) {
    if (first.number != second.number) {
      return false;
    }

    final firstSortMap = first.sortMap;
    final secondSortMap = second.sortMap;
    if (firstSortMap.isEmpty || secondSortMap.isEmpty) {
      return true;
    }

    return mapEquals(firstSortMap, secondSortMap);
  }

  int _compareEpisodesByNumber(Episode first, Episode second) {
    final firstNumber = double.tryParse(first.number.trim());
    final secondNumber = double.tryParse(second.number.trim());

    if (firstNumber != null && secondNumber != null) {
      final numberComparison = firstNumber.compareTo(secondNumber);
      if (numberComparison != 0) {
        return numberComparison;
      }
    } else if (firstNumber != null) {
      return -1;
    } else if (secondNumber != null) {
      return 1;
    }

    return first.number.compareTo(second.number);
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

    final sortSections = buildEpisodeSortSections(widget.episodeList);
    final hasAnifyThumbs = widget.episodeList.isNotEmpty &&
        (widget.episodeList[0].thumbnail?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Obx(() => _buildContinueButton()),
        ),
        Obx(() {
          _initSortGrouping();
          final episodesToShow = _episodesForSelectedSortKey();
          final chunkedEpisodes = chunkEpisodes(
            episodesToShow,
            calculateChunkSize(episodesToShow),
          );
          final safeChunkIndex = chunkedEpisodes.isEmpty
              ? 0
              : selectedChunkIndex.value.clamp(0, chunkedEpisodes.length - 1);
          final selectedEpisodes =
              chunkedEpisodes.isNotEmpty ? chunkedEpisodes[safeChunkIndex] : [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...sortSections.map((section) {
                final values = _availableValuesForKey(
                  section.key,
                  sections: sortSections,
                );
                if (values.length <= 1) {
                  return const SizedBox.shrink();
                }

                return EpisodeSortKeySelector(
                  title: section.title,
                  labelPrefix:
                      section.labelPrefix != "Type" ? section.labelPrefix : "",
                  sortKeys: values,
                  selectedSortKey: RxnString(selectedSortValues[section.key]),
                  onSortKeySelected: (sortValue) {
                    if (selectedSortValues[section.key] == sortValue) {
                      return;
                    }

                    selectedSortValues[section.key] = sortValue;
                    _initSortGrouping();
                    selectedChunkIndex.value = 1;
                  },
                );
              }),
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
              GridView.builder(
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
                  mainAxisSpacing: getResponsiveSize(
                    context,
                    mobileSize: 15,
                    desktopSize: 10,
                  ),
                  crossAxisSpacing: 15,
                  mainAxisExtent: hasAnifyThumbs
                      ? 200
                      : getResponsiveSize(
                          context,
                          mobileSize: 100,
                          desktopSize: 130,
                        ),
                ),
                itemCount: selectedEpisodes.length,
                itemBuilder: (context, index) {
                  final episode = selectedEpisodes[index];
                  return Obx(() {
                    final currentEpisode =
                        episode.number.toString().toInt() + 1 ==
                            userProgress.value;
                    final completedEpisode =
                        episode.number.toString().toInt() <= userProgress.value;
                    final isSelected =
                        _areEpisodesEquivalent(selectedEpisode.value, episode);

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
              ),
            ],
          );
        }),
      ],
    );
  }

  Future<void> fetchServers(Episode ep) async {
    streamList.clear();
    isServerStreamLoading.value = true;
    final sourceEpisode = DEpisode(
      episodeNumber: ep.number,
      url: ep.link,
      sortMap: ep.sortMap.isEmpty ? null : ep.sortMap,
    );

    final scrapeToken =
        "scrape_${DateTime.now().millisecondsSinceEpoch}_${ep.number}_${Random().nextInt(10000)}";

    final methods = sourceController.activeSource.value!.methods;
    final videoStream = methods.getVideoListStream(sourceEpisode,
                  parameters: SourceParams(cancelToken: scrapeToken));
    final videoFuture = videoStream == null ? methods.getVideoList(sourceEpisode,
                  parameters: SourceParams(cancelToken: scrapeToken)) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          child: videoStream != null
              ? StreamBuilder(
                  stream: videoStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        streamList.isEmpty) {
                      isServerStreamLoading.value = true;
                      return _buildScrapingLoadingState(true);
                    } else if (snapshot.hasError) {
                      isServerStreamLoading.value = false;
                      return _buildErrorState(snapshot.error.toString());
                    } else if (!snapshot.hasData && streamList.isEmpty) {
                      isServerStreamLoading.value = false;
                      return _buildEmptyState();
                    } else {
                      if (snapshot.data != null) {
                        final nextVideo = hive.Video.fromVideo(snapshot.data!);
                        final alreadyExists = streamList.any((video) =>
                            video.quality == nextVideo.quality &&
                            video.originalUrl == nextVideo.originalUrl);
                        if (!alreadyExists) {
                          streamList.add(nextVideo);
                        }
                      }
                      isServerStreamLoading.value =
                          snapshot.connectionState != ConnectionState.done;

                      if (streamList.isEmpty &&
                          snapshot.connectionState == ConnectionState.done) {
                        return _buildEmptyState();
                      }

                      return _buildServerList(
                        showBottomLoader: isServerStreamLoading.value,
                      );
                    }
                  },
                )
              : FutureBuilder<List<Video>>(
                  future: videoFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      isServerStreamLoading.value = true;
                      return _buildScrapingLoadingState(true);
                    } else if (snapshot.hasError) {
                      isServerStreamLoading.value = false;
                      Logger.e(snapshot.error.toString());
                      return _buildErrorState(snapshot.error.toString());
                    } else if (snapshot.connectionState ==
                                ConnectionState.done &&
                            !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      isServerStreamLoading.value = false;
                      return _buildEmptyState();
                    } else {
                      isServerStreamLoading.value = false;
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
    ).whenComplete(() {
      sourceController.activeSource.value?.cancelRequest(scrapeToken);
    });
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

  Widget _buildServerList({bool showBottomLoader = false}) {
    final tileCount = streamList.length + (showBottomLoader ? 1 : 0);
    final estimatedHeight = 72 + (tileCount * 82.0);
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(10),
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      child: SizedBox(
        height: math.min(estimatedHeight, maxHeight),
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
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 2.5,
                      horizontal: 10,
                    ),
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
            if (showBottomLoader)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .opaque(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 18,
                        width: 18,
                        child: ExpressiveLoadingIndicator(),
                      ),
                      12.width(),
                      const Expanded(
                        child: AnymexText(
                          text: "Fetching more streams...",
                          variant: TextVariant.semiBold,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
