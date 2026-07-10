// ignore_for_file: invalid_use_of_protected_member, prefer_const_constructors, unnecessary_null_comparison
import 'dart:async';
import 'dart:math' as math;
import 'dart:math';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/settings/settings.dart';
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
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anymex/screens/downloads/model/download_models.dart';

class EpisodeListBuilder extends StatefulWidget {
  const EpisodeListBuilder({
    super.key,
    required this.episodeList,
    required this.anilistData,
    this.isSliverMode = false,
  });

  final List<Episode> episodeList;
  final Media? anilistData;
  final bool isSliverMode;

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
    bool isCompleted = false;
    if (isLogged.value) {
      final trackedMedia = auth.onlineService.animeList
          .firstWhereOrNull((e) => e.id == widget.anilistData!.id);
      progress = double.tryParse(trackedMedia?.episodeCount ?? '')?.toInt();
      isCompleted = true;
    } else {
      final savedAnime = offlineStorage.getAnimeById(widget.anilistData!.id);
      final currentEp = savedAnime?.currentEpisode;
      progress = currentEp?.number.toInt();
      if (currentEp != null) {
        final ts = currentEp.timeStampInMilliseconds ?? 0;
        final dur = currentEp.durationInMilliseconds ?? 0;
        if (dur > 0) {
          isCompleted = (ts / dur) * 100 >= settingsController.markAsCompleted;
        }
      }
    }

    final nextProgress = isCompleted
        ? (progress ?? 0)
        : (progress != null && progress > 0 ? progress - 1 : 0);
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
      if (widget.isSliverMode) {
        return const SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: Center(child: ExpressiveLoadingIndicator()),
          ),
        );
      }
      return const SizedBox(
        height: 200,
        child: Center(child: ExpressiveLoadingIndicator()),
      );
    }

    final sortSections = buildEpisodeSortSections(widget.episodeList);
    final hasAnifyThumbs = widget.episodeList.isNotEmpty &&
        (widget.episodeList[0].thumbnail?.isNotEmpty ?? false);

    if (widget.isSliverMode) {
      return _buildAsSliver(context, sortSections, hasAnifyThumbs);
    }

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
                        onLongPress: () {
                          selectedEpisode.value = episode;
                          streamList.clear();
                          isServerStreamLoading.value = false;
                          fetchServers(episode, bypassDialog: true);
                        },
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

  Widget _buildAsSliver(
    BuildContext context,
    List<EpisodeSortSection> sortSections,
    bool hasAnifyThumbs,
  ) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Obx(() => _buildContinueButton()),
          ),
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
          final selectedEpisodes = chunkedEpisodes.isNotEmpty
              ? chunkedEpisodes[safeChunkIndex]
              : <Episode>[];

          return SliverMainAxisGroup(
            slivers: [
              ...sortSections.map((section) {
                final values = _availableValuesForKey(
                  section.key,
                  sections: sortSections,
                );
                if (values.length <= 1) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: EpisodeSortKeySelector(
                    title: section.title,
                    labelPrefix: section.labelPrefix != "Type"
                        ? section.labelPrefix
                        : "",
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
                  ),
                );
              }),
              if (chunkedEpisodes.isNotEmpty)
                SliverToBoxAdapter(
                  child: EpisodeChunkSelector(
                    chunks: chunkedEpisodes,
                    selectedChunkIndex: selectedChunkIndex,
                    onChunkSelected: (index) {
                      if (index != selectedChunkIndex.value) {
                        selectedChunkIndex.value = index;
                      }
                    },
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 15),
                sliver: SliverGrid.builder(
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
                          episode.number.toString().toInt() <=
                              userProgress.value;
                      final isSelected = _areEpisodesEquivalent(
                          selectedEpisode.value, episode);

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
                          onLongPress: () {
                            selectedEpisode.value = episode;
                            streamList.clear();
                            isServerStreamLoading.value = false;
                            fetchServers(episode, bypassDialog: true);
                          },
                        ),
                      );
                    });
                  },
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Future<void> fetchServers(Episode ep, {bool bypassDialog = false}) async {
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
    final videoFuture = videoStream == null
        ? methods.getVideoList(sourceEpisode,
            parameters: SourceParams(cancelToken: scrapeToken))
        : null;

    final RxnString streamError = RxnString();
    StreamSubscription? streamSubscription;

    if (videoStream != null) {
      streamSubscription = videoStream.listen(
        (data) {
          final nextVideo = hive.Video.fromVideo(data);
          final alreadyExists = streamList.any((video) =>
              video.quality == nextVideo.quality &&
              video.originalUrl == nextVideo.originalUrl);
          if (!alreadyExists) {
            streamList.add(nextVideo);
          }
        },
        onError: (e) {
          streamError.value = e.toString();
          isServerStreamLoading.value = false;
        },
        onDone: () {
          isServerStreamLoading.value = false;
        },
      );
    } else if (videoFuture != null) {
      videoFuture.then((vids) {
        isServerStreamLoading.value = false;
        streamList.value = vids.map((e) => hive.Video.fromVideo(e)).toList();
      }).catchError((e) {
        isServerStreamLoading.value = false;
        streamError.value = e.toString();
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = context.colors;
        return Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(theme),
              _buildHeader(theme),
              const Divider(height: 1, thickness: 0.5),
              Flexible(
                child: Obx(() {
                  if (isServerStreamLoading.value && streamList.isEmpty) {
                    return _buildScrapingLoadingState(videoStream != null);
                  } else if (streamError.value != null) {
                    return _buildErrorState(streamError.value!);
                  } else if (streamList.isEmpty &&
                      !isServerStreamLoading.value) {
                    return _buildEmptyState();
                  } else {
                    return _buildServerList(
                      bypassDialog,
                      showBottomLoader: isServerStreamLoading.value,
                    );
                  }
                }),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    ).whenComplete(() {
      streamSubscription?.cancel();
      sourceController.activeSource.value?.cancelRequest(scrapeToken);
    });

    final dbId =
        '${widget.anilistData!.id}_${widget.anilistData!.serviceType.name}_${widget.anilistData!.type}';
    final savedTracking = DynamicKeys.trackingPermission.get<bool?>(dbId);
    if (savedTracking != null && !bypassDialog) {
      snackBar("Long press an episode if you wanna reset the tracker.",
          title: "Tracking Preference Applied");
    }
  }

  Widget _buildHandle(ColorScheme theme) => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        decoration: BoxDecoration(
          color: theme.onSurface.opaque(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
      );

  Widget _buildHeader(ColorScheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryContainer.opaque(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(HugeIcons.strokeRoundedPlay,
                size: 20, color: theme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AnymexText(
                    text: 'Choose Quality',
                    variant: TextVariant.bold,
                    size: 16),
                AnymexText(
                  text: 'Select streaming server quality to watch',
                  size: 12,
                  color: theme.onSurface.opaque(0.5),
                ),
              ],
            ),
          ),
          AnymexOnTap(
            onTap: () => Navigator.pop(context),
            child:
                Icon(Icons.close_rounded, color: theme.onSurface.opaque(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildScrapingLoadingState(bool fromSrc) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
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

  Widget _buildServerList(bool bypassDialog, {bool showBottomLoader = false}) {
    final theme = context.colors;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        shrinkWrap: true,
        itemCount: streamList.length + (showBottomLoader ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == streamList.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: ExpressiveLoadingIndicator()),
                  const SizedBox(width: 8),
                  AnymexText(
                      text: 'Scanning for more servers...',
                      size: 12,
                      color: theme.onSurface.opaque(0.5)),
                ],
              ),
            );
          }

          final video = streamList[index];
          final quality = video.quality?.toUpperCase() ?? "UNKNOWN";
          final linkType = detectLinkType(video.url ?? video.originalUrl ?? '');
          final isHls = linkType == VideoLinkType.hls;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AnymexOnTap(
              onTap: () async {
                Navigator.pop(context);
                final dbId =
                    '${widget.anilistData!.id}_${widget.anilistData!.serviceType.name}_${widget.anilistData!.type}';
                final savedTracking =
                    DynamicKeys.trackingPermission.get<bool?>(dbId);

                if (savedTracking != null && !bypassDialog) {
                  await navigate(() => WatchScreen(
                        episodeSrc: video,
                        episodeList: widget.episodeList,
                        anilistData: widget.anilistData!,
                        currentEpisode: selectedEpisode.value,
                        episodeTracks: streamList,
                        shouldTrack: savedTracking,
                      ));
                  Future.delayed(const Duration(seconds: 1), () {
                    if (mounted) setState(() {});
                  });
                  return;
                }

                if (General.shouldAskForTrack.get(true) == false) {
                  await navigate(() => WatchScreen(
                        episodeSrc: video,
                        episodeList: widget.episodeList,
                        anilistData: widget.anilistData!,
                        currentEpisode: selectedEpisode.value,
                        episodeTracks: streamList,
                      ));
                  Future.delayed(const Duration(seconds: 1), () {
                    if (mounted) setState(() {});
                  });
                  return;
                }
                final shouldTrack =
                    widget.anilistData?.serviceType == ServicesType.extensions
                        ? false
                        : await showTrackingDialog(context, dbId: dbId);

                if (shouldTrack != null) {
                  await navigate(() => WatchScreen(
                        episodeSrc: video,
                        episodeList: widget.episodeList,
                        anilistData: widget.anilistData!,
                        currentEpisode: selectedEpisode.value,
                        episodeTracks: streamList,
                        shouldTrack: shouldTrack,
                      ));
                  Future.delayed(const Duration(seconds: 1), () {
                    if (mounted) setState(() {});
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.surfaceContainer.opaque(0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.outline.opaque(0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryContainer.opaque(0.3),
                      ),
                      child: Icon(Icons.play_arrow_rounded,
                          size: 16, color: theme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymexText(
                            text: quality,
                            variant: TextVariant.bold,
                            size: 14,
                            maxLines: 10,
                          ),
                          const SizedBox(height: 2),
                          AnymexText(
                            text: sourceController.activeSource.value!.name!
                                .toUpperCase(),
                            variant: TextVariant.semiBold,
                            size: 11,
                            color: theme.onSurface.opaque(0.6),
                          ),
                        ],
                      ),
                    ),
                    if (isHls)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: const Text('HLS',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Text('Direct',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
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
                  child: Center(
                    child: SizedBox(
                      width: getResponsiveValue(context,
                          mobileValue: (Get.width * 0.8), desktopValue: null),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnymexText(
                            text: episodeLabel.toUpperCase(),
                            variant: TextVariant.semiBold,
                            color: textColor,
                            textAlign: TextAlign.center,
                            isMarquee: true,
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
