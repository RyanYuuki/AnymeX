import 'dart:async';
import 'dart:math';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/track/track_binding_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/video.dart' as hive;
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/watch/watch_view.dart';
import 'package:anymex/screens/anime/widgets/episode/episode_style_registry.dart';
import 'package:anymex/screens/anime/widgets/episode_range.dart';
import 'package:anymex/screens/anime/widgets/track_dialog.dart';
import 'package:anymex/screens/downloads/controller/download_controller.dart';
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/screens/downloads/widgets/download_server_selector.dart';
import 'package:anymex/screens/downloads/widgets/downloaded_watch_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

typedef _BatchOption = ({
  String title,
  String subtitle,
  IconData icon,
  bool enabled,
  VoidCallback onTap,
});

class EpisodeListBuilder extends StatefulWidget {
  const EpisodeListBuilder({
    super.key,
    required this.episodeList,
    required this.anilistData,
    this.isSliverMode = false,
    this.onSettingsTap,
  });

  final List<Episode> episodeList;
  final Media? anilistData;
  final bool isSliverMode;
  final VoidCallback? onSettingsTap;

  static Future<void> showServerSheet(
    BuildContext context, {
    required Episode episode,
    required List<Episode> episodeList,
    required Media anilistData,
    bool bypassDialog = false,
  }) async {
    await AnymeXSheet.custom(
      ServerSheetContent(
        episode: episode,
        episodeList: episodeList,
        anilistData: anilistData,
        bypassDialog: bypassDialog,
      ),
      context,
      showDragHandle: true,
    );
  }

  @override
  State<EpisodeListBuilder> createState() => _EpisodeListBuilderState();
}

class _EpisodeListBuilderState extends State<EpisodeListBuilder> {
  final selectedChunkIndex = 1.obs;
  final RxMap<String, String> selectedSortValues = <String, String>{}.obs;
  final selectedViewTab = 0.obs;
  final sourceController = Get.find<SourceController>();
  final auth = Get.find<ServiceHandler>();
  final offlineStorage = Get.find<OfflineStorageController>();
  late final DownloadController downloadController;

  final RxBool isLogged = false.obs;
  final RxInt userProgress = 0.obs;

  final Rx<Episode> selectedEpisode = Episode(number: "1").obs;
  final Rx<Episode> continueEpisode = Episode(number: "1").obs;
  final Rx<Episode> savedEpisode = Episode(number: "1").obs;

  List<Episode> offlineWatchedEpisodes = [];
  Worker? _authLoginWorker;
  Worker? _userProgressWorker;
  Worker? _currentMediaWorker;
  VoidCallback? _offlineStorageListener;
  bool _isUpdatingChunk = false;

  @override
  void initState() {
    super.initState();
    downloadController = Get.isRegistered<DownloadController>()
        ? Get.find<DownloadController>()
        : Get.put(DownloadController());
    final mediaTitle = widget.anilistData?.title ??
        (widget.episodeList.isNotEmpty ? widget.episodeList.first.title ?? '' : '');
    final extName = sourceController.activeSource.value?.name ?? '';
    if (extName.isNotEmpty && mediaTitle.isNotEmpty) {
      downloadController.ensureMediaMetaLoaded(extName, mediaTitle);
    }
    _initSortGrouping();
    _initUserProgress();
    _initEpisodes();
    _updateChunkIndex();

    _authLoginWorker = ever(auth.isLoggedIn, (_) => _initUserProgress());
    _userProgressWorker = ever(userProgress, (_) => _initEpisodes());
    _currentMediaWorker = ever(auth.currentMedia, (_) {
      _initUserProgress();
      _initEpisodes();
    });

    _offlineStorageListener = () {
      final savedData =
          offlineStorage.getAnimeById(widget.anilistData?.id ?? '');
      if (savedData?.currentEpisode != null) {
        savedEpisode.value = savedData!.currentEpisode!;
        offlineWatchedEpisodes = savedData.watchedEpisodes ?? [];
        _initUserProgress();
        _initEpisodes();
        _updateChunkIndex();
        if (mounted) setState(() {});
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

    if (oldLen != newLen || oldFirst != newFirst || oldLast != newLast) {
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
          final chunkIndex =
              findChunkIndexFromProgress(progress, chunkedEpisodes);
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

    int trackerProgress = 0;
    if (isLogged.value && widget.anilistData != null) {
      final trackedMedia = auth.onlineService.animeList
          .firstWhereOrNull((e) => e.id == widget.anilistData!.id);
      trackerProgress =
          double.tryParse(trackedMedia?.episodeCount ?? '')?.toInt() ?? 0;
    }

    final savedAnime =
        offlineStorage.getAnimeById(widget.anilistData?.id ?? '');
    offlineWatchedEpisodes = savedAnime?.watchedEpisodes ?? [];

    int localProgress = 0;
    final currentEp = savedAnime?.currentEpisode;
    if (currentEp != null) {
      final epNum = currentEp.number.toInt();
      final ts = currentEp.timeStampInMilliseconds ?? 0;
      final dur = currentEp.durationInMilliseconds ?? 0;
      if (dur > 0 && (ts / dur) * 100 >= settingsController.markAsCompleted) {
        localProgress = epNum;
      } else {
        localProgress = max(0, epNum - 1);
      }
    }

    final combinedProgress = max(trackerProgress, localProgress);
    if (userProgress.value != combinedProgress) {
      userProgress.value = combinedProgress;
    }
  }

  void _initEpisodes() {
    if (widget.episodeList.isEmpty) {
      final fallback = Episode(number: "1", title: "Episode 1");
      savedEpisode.value = fallback;
      selectedEpisode.value = fallback;
      continueEpisode.value = fallback;
      return;
    }

    final savedData = offlineStorage.getAnimeById(widget.anilistData?.id ?? '');
    final nextEpisode = widget.episodeList
        .firstWhereOrNull((e) => e.number.toInt() == (userProgress.value + 1));
    final fallbackEP = widget.episodeList
        .firstWhereOrNull((e) => e.number.toInt() == userProgress.value);
    final saved = savedData?.currentEpisode;
    final nextSaved = saved ?? widget.episodeList[0];

    if (!savedEpisode.value.isSameEpisode(nextSaved)) {
      savedEpisode.value = nextSaved;
    }

    Episode nextSelected;
    if (saved != null) {
      final idx = widget.episodeList.indexWhere((e) => e.isSameEpisode(saved));
      if (idx != -1) {
        final ts = saved.timeStampInMilliseconds ?? 0;
        final dur = saved.durationInMilliseconds ?? 0;
        final isComplete =
            dur > 0 && (ts / dur) * 100 >= settingsController.markAsCompleted;
        if (isComplete && idx + 1 < widget.episodeList.length) {
          nextSelected = widget.episodeList[idx + 1];
        } else {
          nextSelected = widget.episodeList[idx];
        }
      } else {
        nextSelected = saved;
      }
    } else {
      nextSelected = nextEpisode ?? fallbackEP ?? savedEpisode.value;
    }

    if (!selectedEpisode.value.isSameEpisode(nextSelected)) {
      selectedEpisode.value = nextSelected;
    }
    if (!continueEpisode.value.isSameEpisode(nextSelected)) {
      continueEpisode.value = nextSelected;
    }
  }

  bool _isEpisodeWatched(Episode episode) {
    final inOfflineWatched =
        offlineWatchedEpisodes.any((e) => e.isSameEpisode(episode));
    if (inOfflineWatched) return true;

    final ts = episode.timeStampInMilliseconds ?? 0;
    final dur = episode.durationInMilliseconds ?? 0;
    if (dur > 0 && (ts / dur) * 100 >= settingsController.markAsCompleted) {
      return true;
    }

    final hasSortSections = widget.episodeList.any((e) =>
        e.sortMap.isNotEmpty || (e.sortKeys != null && e.sortKeys!.isNotEmpty));
    if (!hasSortSections) {
      final epNum = episode.number.toInt();
      if (epNum > 0 && epNum <= userProgress.value) return true;
    }

    return false;
  }

  double _calculateEpisodeProgress(Episode episode) {
    final savedEP = offlineWatchedEpisodes.cast<Episode?>().firstWhere(
          (e) => e?.isSameEpisode(episode) ?? false,
          orElse: () => null,
        );

    final target = savedEP ??
        (savedEpisode.value.isSameEpisode(episode)
            ? savedEpisode.value
            : null);
    if (target?.timeStampInMilliseconds != null &&
        target?.durationInMilliseconds != null &&
        target!.durationInMilliseconds! > 0) {
      return target.timeStampInMilliseconds! / target.durationInMilliseconds!;
    }

    return 0.0;
  }

  void _initSortGrouping() {
    final savedData =
        offlineStorage.getAnimeById(widget.anilistData?.id ?? '');
    final savedSortMap = savedData?.currentEpisode?.sortMap ?? {};
    final sections = buildEpisodeSortSections(widget.episodeList);
    final nextSelection = <String, String>{};

    for (final section in sections) {
      final availableValues = _availableValuesForKey(
        section.key,
        sections: sections,
        activeSelection: selectedSortValues,
      );
      if (availableValues.isEmpty) continue;

      final currentValue =
          selectedSortValues[section.key] ?? savedSortMap[section.key];
      nextSelection[section.key] =
          (currentValue != null && availableValues.contains(currentValue))
              ? currentValue
              : availableValues.first;
    }

    if (selectedSortValues.length != nextSelection.length ||
        nextSelection.entries
            .any((e) => selectedSortValues[e.key] != e.value)) {
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

  void _handleEpisodeSelection(Episode episode) {
    selectedEpisode.value = episode;
    fetchServers(episode);
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
            if (entry.key == key) return true;
            return sortMap[entry.key]?.trim() == entry.value;
          });
        })
        .map((episode) => episode.sortMap[key]?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort(compareEpisodeSortValues);

    if (values.isNotEmpty) return values;

    final fallbackSection =
        (sections ?? buildEpisodeSortSections(widget.episodeList))
            .firstWhereOrNull((section) => section.key == key);
    return fallbackSection?.values ?? const [];
  }

  bool _areEpisodesEquivalent(Episode first, Episode second) {
    return first.isSameEpisode(second);
  }

  int _compareEpisodesByNumber(Episode first, Episode second) {
    final firstNumber = double.tryParse(first.number.trim());
    final secondNumber = double.tryParse(second.number.trim());

    if (firstNumber != null && secondNumber != null) {
      final numberComparison = firstNumber.compareTo(secondNumber);
      if (numberComparison != 0) return numberComparison;
    } else if (firstNumber != null) {
      return -1;
    } else if (secondNumber != null) {
      return 1;
    }

    return first.number.compareTo(second.number);
  }

  Future<void> fetchServers(Episode ep, {bool bypassDialog = false}) async {
    final mediaData =
        widget.anilistData ?? Media(serviceType: ServicesType.extensions);
    await EpisodeListBuilder.showServerSheet(
      context,
      episode: ep,
      episodeList: widget.episodeList,
      anilistData: mediaData,
      bypassDialog: bypassDialog,
    );
    _initUserProgress();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.episodeList.isEmpty) {
      if (widget.isSliverMode) {
        return const SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final sortSections = buildEpisodeSortSections(widget.episodeList);

    return Obx(() {
      _initSortGrouping();
      final currentStyle = EpisodeStyleRegistry.activeStyle;
      final mediaTitle = widget.anilistData?.title ??
          (widget.episodeList.isNotEmpty ? widget.episodeList.first.title ?? '' : '');
      final extName = sourceController.activeSource.value?.name ?? '';
      final downloadedEpisodes =
          downloadController.getDownloadedEpisodes(extName, mediaTitle);
      final isDownloadedTab = selectedViewTab.value == 1;

      final episodesToShow = _episodesForSelectedSortKey();
      final chunkedEpisodes =
          chunkEpisodes(episodesToShow, calculateChunkSize(episodesToShow));
      final safeChunkIndex = chunkedEpisodes.isEmpty
          ? 0
          : selectedChunkIndex.value.clamp(0, chunkedEpisodes.length - 1);
      final selectedEpisodes = chunkedEpisodes.isNotEmpty
          ? chunkedEpisodes[safeChunkIndex]
          : <Episode>[];

      if (widget.isSliverMode) {
        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeaderCard(
                context,
                sortSections: sortSections,
                chunkedEpisodes: chunkedEpisodes,
                downloadedCount: downloadedEpisodes.length,
                isDownloadedTab: isDownloadedTab,
                extName: extName,
                mediaTitle: mediaTitle,
              ),
            ),
            if (isDownloadedTab)
              if (downloadedEpisodes.isEmpty)
                SliverToBoxAdapter(
                  child: _buildDownloadedEmptyState(context),
                )
              else if (currentStyle.isGrid)
                SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: getResponsiveCrossAxisCount(
                      context,
                      baseColumns: 1,
                      maxColumns: 3,
                      mobileItemWidth: 400,
                      tabletItemWidth: 400,
                      desktopItemWidth: 200,
                    ),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: currentStyle.id == 'minimal' ? 65 : 100,
                  ),
                  itemCount: downloadedEpisodes.length,
                  itemBuilder: (context, index) {
                    final item = downloadedEpisodes[index];
                    final episode = item.episode;
                    final isSelected =
                        _areEpisodesEquivalent(selectedEpisode.value, episode);
                    final isWatched = _isEpisodeWatched(episode);
                    final prog = _calculateEpisodeProgress(episode);

                    return currentStyle.builder(
                      context,
                      episode,
                      isSelected,
                      isWatched,
                      prog,
                      widget.anilistData,
                      () => _playDownloadedEpisode(
                          item, downloadedEpisodes, extName, mediaTitle),
                      () => _playDownloadedEpisode(
                          item, downloadedEpisodes, extName, mediaTitle),
                      downloadButton: IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: context.colors.error,
                          size: 20,
                        ),
                        onPressed: () => _confirmDeleteEpisode(
                            context, item, extName, mediaTitle),
                      ),
                    );
                  },
                )
              else
                SliverList.builder(
                  itemCount: downloadedEpisodes.length,
                  itemBuilder: (context, index) {
                    final item = downloadedEpisodes[index];
                    final episode = item.episode;
                    final isSelected =
                        _areEpisodesEquivalent(selectedEpisode.value, episode);
                    final isWatched = _isEpisodeWatched(episode);
                    final prog = _calculateEpisodeProgress(episode);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: currentStyle.builder(
                        context,
                        episode,
                        isSelected,
                        isWatched,
                        prog,
                        widget.anilistData,
                        () => _playDownloadedEpisode(
                            item, downloadedEpisodes, extName, mediaTitle),
                        () => _playDownloadedEpisode(
                            item, downloadedEpisodes, extName, mediaTitle),
                        downloadButton: IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: context.colors.error,
                            size: 20,
                          ),
                          onPressed: () => _confirmDeleteEpisode(
                              context, item, extName, mediaTitle),
                        ),
                      ),
                    );
                  },
                )
            else if (currentStyle.isGrid)
              SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: getResponsiveCrossAxisCount(
                    context,
                    baseColumns: 1,
                    maxColumns: 3,
                    mobileItemWidth: 400,
                    tabletItemWidth: 400,
                    desktopItemWidth: 200,
                  ),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: currentStyle.id == 'minimal' ? 65 : 100,
                ),
                itemCount: selectedEpisodes.length,
                itemBuilder: (context, index) {
                  final episode = selectedEpisodes[index];
                  final isSelected =
                      _areEpisodesEquivalent(selectedEpisode.value, episode);
                  final isWatched = _isEpisodeWatched(episode);
                  final prog = _calculateEpisodeProgress(episode);

                  return currentStyle.builder(
                    context,
                    episode,
                    isSelected,
                    isWatched,
                    prog,
                    widget.anilistData,
                    () => _handleEpisodeSelection(episode),
                    () {
                      selectedEpisode.value = episode;
                      fetchServers(episode, bypassDialog: true);
                    },
                    downloadButton: _buildEpisodeDownloadButton(
                      context,
                      episode,
                      extName,
                      mediaTitle,
                    ),
                  );
                },
              )
            else
              SliverList.builder(
                itemCount: selectedEpisodes.length,
                itemBuilder: (context, index) {
                  final episode = selectedEpisodes[index];
                  final isSelected =
                      _areEpisodesEquivalent(selectedEpisode.value, episode);
                  final isWatched = _isEpisodeWatched(episode);
                  final prog = _calculateEpisodeProgress(episode);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: currentStyle.builder(
                      context,
                      episode,
                      isSelected,
                      isWatched,
                      prog,
                      widget.anilistData,
                      () => _handleEpisodeSelection(episode),
                      () {
                        selectedEpisode.value = episode;
                        fetchServers(episode, bypassDialog: true);
                      },
                      downloadButton: _buildEpisodeDownloadButton(
                        context,
                        episode,
                        extName,
                        mediaTitle,
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(
            context,
            sortSections: sortSections,
            chunkedEpisodes: chunkedEpisodes,
            downloadedCount: downloadedEpisodes.length,
            isDownloadedTab: isDownloadedTab,
            extName: extName,
            mediaTitle: mediaTitle,
          ),
          if (isDownloadedTab)
            if (downloadedEpisodes.isEmpty)
              _buildDownloadedEmptyState(context)
            else
              ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: downloadedEpisodes.length,
                itemBuilder: (context, index) {
                  final item = downloadedEpisodes[index];
                  final episode = item.episode;
                  final isSelected =
                      _areEpisodesEquivalent(selectedEpisode.value, episode);
                  final isWatched = _isEpisodeWatched(episode);
                  final prog = _calculateEpisodeProgress(episode);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: currentStyle.builder(
                      context,
                      episode,
                      isSelected,
                      isWatched,
                      prog,
                      widget.anilistData,
                      () => _playDownloadedEpisode(
                          item, downloadedEpisodes, extName, mediaTitle),
                      () => _playDownloadedEpisode(
                          item, downloadedEpisodes, extName, mediaTitle),
                      downloadButton: IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: context.colors.error,
                          size: 20,
                        ),
                        onPressed: () => _confirmDeleteEpisode(
                            context, item, extName, mediaTitle),
                      ),
                    ),
                  );
                },
              )
          else
            ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedEpisodes.length,
              itemBuilder: (context, index) {
                final episode = selectedEpisodes[index];
                final isSelected =
                    _areEpisodesEquivalent(selectedEpisode.value, episode);
                final isWatched = _isEpisodeWatched(episode);
                final prog = _calculateEpisodeProgress(episode);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: currentStyle.builder(
                    context,
                    episode,
                    isSelected,
                    isWatched,
                    prog,
                    widget.anilistData,
                    () => _handleEpisodeSelection(episode),
                    () {
                      selectedEpisode.value = episode;
                      fetchServers(episode, bypassDialog: true);
                    },
                    downloadButton: _buildEpisodeDownloadButton(
                      context,
                      episode,
                      extName,
                      mediaTitle,
                    ),
                  ),
                );
              },
            ),
        ],
      );
    });
  }

  Widget _buildHeaderCard(
    BuildContext context, {
    required List<EpisodeSortSection> sortSections,
    required List<List<Episode>> chunkedEpisodes,
    required int downloadedCount,
    required bool isDownloadedTab,
    required String extName,
    required String mediaTitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest
            .opaque(0.2, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.onSurface.opaque(0.08, iReallyMeanIt: true),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AnymeXPills(
                  scrollPadding: EdgeInsets.zero,
                  items: [
                    PillItem(
                      label: 'Online',
                      count: widget.episodeList.length,
                      isSelected: selectedViewTab.value == 0,
                      onTap: () => selectedViewTab.value = 0,
                    ),
                    PillItem(
                      label: 'Downloaded',
                      count: downloadedCount,
                      isSelected: selectedViewTab.value == 1,
                      onTap: () => selectedViewTab.value = 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      _showBatchDownloadSheet(context, extName, mediaTitle),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerHighest
                          .opaque(0.35, iReallyMeanIt: true),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: context.colors.outline
                            .opaque(0.15, iReallyMeanIt: true),
                      ),
                    ),
                    child: Icon(
                      Icons.file_download_outlined,
                      size: 16,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ),
              if (widget.onSettingsTap != null) ...[
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onSettingsTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest
                            .opaque(0.35, iReallyMeanIt: true),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: context.colors.outline
                              .opaque(0.15, iReallyMeanIt: true),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.settings_outlined,
                            size: 16,
                            color: context.colors.primary,
                          ),
                          const SizedBox(width: 8),
                          AnymeXText(
                            'Settings',
                            size: 12,
                            color: context.colors.primary,
                            variant: TextVariant.bold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!isDownloadedTab) ...[
            ...sortSections.map((section) {
              final values = _availableValuesForKey(section.key,
                  sections: sortSections);
              if (values.length <= 1) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: EpisodeSortKeySelector(
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
                ),
              );
            }),
            if (chunkedEpisodes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
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
          ],
        ],
      ),
    );
  }

  Widget _buildDownloadedEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_download_outlined,
              size: 48,
              color: context.colors.onSurface.opaque(0.4),
            ),
            const SizedBox(height: 12),
            AnymeXText(
              'No downloaded episodes found for this anime',
              size: 14,
              variant: TextVariant.semiBold,
              color: context.colors.onSurface.opaque(0.7),
            ),
            const SizedBox(height: 16),
            AnymeXContainerButton(
              onTap: () => selectedViewTab.value = 0,
              radius: 12,
              color: context.colors.primary,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: AnymeXText(
                  'Switch to Online',
                  color: context.colors.onPrimary,
                  variant: TextVariant.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OfflineMedia _getOfflineMedia(String mediaTitle) {
    return widget.anilistData?.toOfflineMedia() ??
        OfflineMedia(mediaId: mediaTitle, name: mediaTitle, poster: null);
  }

  Widget _buildEpisodeDownloadButton(
    BuildContext context,
    Episode episode,
    String extName,
    String mediaTitle,
  ) {
    if (extName.isEmpty || mediaTitle.isEmpty) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      final state = downloadController.getEpisodeState(
        extName,
        mediaTitle,
        episode.number,
        episode.sortMap,
      );
      final colors = context.colors;

      switch (state.status) {
        case DownloadItemStatus.downloaded:
          return Tooltip(
            message: 'Downloaded',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  snackBar('Episode ${episode.number} is downloaded');
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary.opaque(0.15, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.primary.opaque(0.35, iReallyMeanIt: true),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: colors.primary,
                    size: 16,
                  ),
                ),
              ),
            ),
          );
        case DownloadItemStatus.downloading:
          return Tooltip(
            message: 'Downloading (${(state.progress * 100).toInt()}%)',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  if (state.taskId != null) {
                    downloadController.pauseDownload(state.taskId!);
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary.opaque(0.1, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.primary.opaque(0.25, iReallyMeanIt: true),
                      width: 0.8,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          value: state.progress > 0 ? state.progress : null,
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      ),
                      Icon(
                        Icons.pause_rounded,
                        size: 12,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        case DownloadItemStatus.queued:
          return Tooltip(
            message: 'Queued for download',
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest
                    .opaque(0.3, iReallyMeanIt: true),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.outline.opaque(0.12, iReallyMeanIt: true),
                  width: 0.8,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: colors.primary.opaque(0.6),
                    ),
                  ),
                  Icon(
                    Icons.access_time_rounded,
                    size: 11,
                    color: colors.primary.opaque(0.6),
                  ),
                ],
              ),
            ),
          );
        case DownloadItemStatus.failed:
          return Tooltip(
            message: 'Download failed. Tap to retry.',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  final activeSrc = sourceController.activeSource.value;
                  if (activeSrc != null) {
                    DownloadServerSelector.show(
                      context,
                      episodes: [episode],
                      source: activeSrc,
                      media: _getOfflineMedia(mediaTitle),
                    );
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.error.opaque(0.15, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.error.opaque(0.35, iReallyMeanIt: true),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: colors.error,
                    size: 16,
                  ),
                ),
              ),
            ),
          );
        case DownloadItemStatus.notDownloaded:
          return Tooltip(
            message: 'Download Episode',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  final activeSrc = sourceController.activeSource.value;
                  if (activeSrc != null) {
                    DownloadServerSelector.show(
                      context,
                      episodes: [episode],
                      source: activeSrc,
                      media: _getOfflineMedia(mediaTitle),
                    );
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest
                        .opaque(0.3, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.outline.opaque(0.12, iReallyMeanIt: true),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.download_rounded,
                    color: colors.onSurface.opaque(0.7),
                    size: 16,
                  ),
                ),
              ),
            ),
          );
      }
    });
  }

  Future<void> _playDownloadedEpisode(
    DownloadedEpisodeMeta item,
    List<DownloadedEpisodeMeta> downloadedEpisodes,
    String extName,
    String mediaTitle,
  ) async {
    final meta = await downloadController.ensureMediaMetaLoaded(extName, mediaTitle) ??
        await downloadController.getMediaMeta(extName, mediaTitle) ??
        DownloadedMediaMeta(
          episodes: downloadedEpisodes,
          media: widget.anilistData?.toOfflineMedia(),
        );
    final summary = downloadController.downloadedMedia.firstWhereOrNull(
          (s) =>
              s.extensionName.toLowerCase() == extName.toLowerCase() &&
              (s.folderName.toLowerCase() == mediaTitle.toLowerCase() ||
                  s.title.toLowerCase() == mediaTitle.toLowerCase()),
        ) ??
        DownloadedMediaSummary(
          title: (widget.anilistData?.title.isNotEmpty == true)
              ? widget.anilistData!.title
              : mediaTitle,
          poster: (widget.anilistData?.poster.isNotEmpty == true)
              ? widget.anilistData!.poster
              : widget.anilistData?.cover,
          extensionName: extName,
          folderName: mediaTitle,
          mediaType: 'Anime',
        );
    await navigate(() => DownloadedWatchPage(
          episode: item,
          allEpisodes: downloadedEpisodes,
          meta: meta,
          summary: summary,
        ));
    _initUserProgress();
    if (mounted) setState(() {});
  }

  Future<void> _confirmDeleteEpisode(
    BuildContext context,
    DownloadedEpisodeMeta epMeta,
    String extName,
    String mediaTitle,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const AnymeXText('Delete Episode', variant: TextVariant.bold),
        content: AnymeXText(
            'Are you sure you want to delete Episode ${epMeta.episode.number}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const AnymeXText('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: AnymeXText('Delete', color: ctx.colors.error),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await downloadController.deleteEpisode(
        extName,
        mediaTitle,
        epMeta.episode.number,
        epMeta.episode.sortMap,
      );
    }
  }

  void _showBatchDownloadSheet(
    BuildContext context,
    String extName,
    String mediaTitle,
  ) {
    final activeSrc = sourceController.activeSource.value;
    if (activeSrc == null) {
      snackBar('No active source selected');
      return;
    }
    final episodesToShow = _episodesForSelectedSortKey();
    final chunkedEpisodes =
        chunkEpisodes(episodesToShow, calculateChunkSize(episodesToShow));
    final safeChunkIndex = chunkedEpisodes.isEmpty
        ? 0
        : selectedChunkIndex.value.clamp(0, chunkedEpisodes.length - 1);
    final currentChunk = chunkedEpisodes.isNotEmpty
        ? chunkedEpisodes[safeChunkIndex]
        : <Episode>[];

    final unwatched = widget.episodeList.where((e) {
      final isWatched = _isEpisodeWatched(e);
      final isDownloaded = downloadController.isEpisodeDownloaded(
          extName, mediaTitle, e.number, e.sortMap);
      return !isWatched && !isDownloaded;
    }).toList();

    final chunkNotDownloaded = currentChunk.where((e) {
      return !downloadController.isEpisodeDownloaded(
          extName, mediaTitle, e.number, e.sortMap);
    }).toList();

    final allNotDownloaded = widget.episodeList.where((e) {
      return !downloadController.isEpisodeDownloaded(
          extName, mediaTitle, e.number, e.sortMap);
    }).toList();

    final options = <_BatchOption>[
      (
        title: 'Download Unwatched Episodes',
        subtitle: '${unwatched.length} episodes',
        icon: Icons.playlist_play_rounded,
        enabled: unwatched.isNotEmpty,
        onTap: () {
          DownloadServerSelector.show(
            context,
            episodes: unwatched,
            source: activeSrc,
            media: _getOfflineMedia(mediaTitle),
          );
        },
      ),
      (
        title: 'Download Current Section',
        subtitle: '${chunkNotDownloaded.length} episodes',
        icon: Icons.view_carousel_outlined,
        enabled: chunkNotDownloaded.isNotEmpty,
        onTap: () {
          DownloadServerSelector.show(
            context,
            episodes: chunkNotDownloaded,
            source: activeSrc,
            media: _getOfflineMedia(mediaTitle),
          );
        },
      ),
      (
        title: 'Download All Episodes',
        subtitle: '${allNotDownloaded.length} episodes',
        icon: Icons.file_download_outlined,
        enabled: allNotDownloaded.isNotEmpty,
        onTap: () {
          DownloadServerSelector.show(
            context,
            episodes: allNotDownloaded,
            source: activeSrc,
            media: _getOfflineMedia(mediaTitle),
          );
        },
      ),
    ];

    AnymeXSheet(
      title: 'Batch Download',
      message: mediaTitle,
      showDragHandle: true,
      contentWidget: AnymeXTileBuilder<_BatchOption>(
        items: options,
        isSelection: false,
        isEnabled: (item) => item.enabled,
        getTitle: (item) => item.title,
        getSubtitle: (item) => item.subtitle,
        getIcon: (item) => item.icon,
        showChevron: (item) => item.enabled,
        onItemPressed: (item) {
          if (item.enabled) {
            Navigator.pop(context);
            item.onTap();
          }
        },
      ),
    ).show(context);
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
        final rawTitle = episode.title?.trim();
        final isGenericMovie = rawTitle == null ||
            rawTitle.isEmpty ||
            rawTitle.toLowerCase() == 'movie' ||
            rawTitle.toLowerCase() == 'full movie';
        final isMovieMedia =
            data.id.endsWith('*MOVIE') || data.mediaType == ItemType.anime;
        final resolvedTitle = (isGenericMovie || isMovieMedia)
            ? (data.title.isNotEmpty ? data.title : "Episode ${episode.number}")
            : rawTitle;
        final episodeLabel = 'Episode ${episode.number}: $resolvedTitle';
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
                    color: Colors.black.opaque(0.5, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onTap: onPressed,
                  child: Center(
                    child: SizedBox(
                      width: getResponsiveValue(context,
                          mobileValue: (Get.width * 0.8), desktopValue: null),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnymeXText(
                            episodeLabel.toUpperCase(),
                            variant: TextVariant.semiBold,
                            color: textColor,
                            textAlign: TextAlign.center,
                            isMarquee: true,
                          ),
                          PlatformBuilder(
                            androidBuilder: const SizedBox.shrink(),
                            desktopBuilder: Column(
                              children: [
                                const SizedBox(height: 3),
                                Container(
                                  color: context.colors.primary,
                                  height: 2,
                                  width: 6 * episodeLabel.length.toDouble(),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (progressPercentage > 0)
                Positioned(
                  height: 3,
                  bottom: 0,
                  left: 0,
                  child: Container(
                    height: 3,
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

class ServerSheetContent extends StatefulWidget {
  final Episode episode;
  final List<Episode> episodeList;
  final Media anilistData;
  final bool bypassDialog;

  const ServerSheetContent({
    super.key,
    required this.episode,
    required this.episodeList,
    required this.anilistData,
    this.bypassDialog = false,
  });

  @override
  State<ServerSheetContent> createState() => _ServerSheetContentState();
}

class _ServerSheetContentState extends State<ServerSheetContent> {
  final RxList<hive.Video> streamList = <hive.Video>[].obs;
  final RxBool isServerStreamLoading = false.obs;
  final sourceController = Get.find<SourceController>();
  final RxnString streamError = RxnString();
  late final RxBool rememberServer;
  StreamSubscription? streamSubscription;
  String? scrapeToken;
  bool _hasAutoSelected = false;

  @override
  void initState() {
    super.initState();
    final savedSticky =
        DynamicKeys.stickyServer.get<String?>(widget.anilistData.id.toString());
    rememberServer = (savedSticky != null && savedSticky.isNotEmpty).obs;
    fetchServers();
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    if (scrapeToken != null) {
      sourceController.activeSource.value?.cancelRequest(scrapeToken!);
    }
    super.dispose();
  }

  void _checkAndAutoSelect({required bool isStreamCompleted}) {
    if (_hasAutoSelected || !mounted) return;

    final mediaId = widget.anilistData.id.toString();
    final savedSticky = DynamicKeys.stickyServer.get<String?>(mediaId);

    final offlineStorage = Get.find<OfflineStorageController>();
    final savedAnime = offlineStorage.getAnimeById(mediaId);
    final prevTrack = savedAnime?.currentEpisode?.currentTrack ??
        savedAnime?.watchedEpisodes?.lastOrNull?.currentTrack;
    final wasDub = hive.isDubTrack(prevTrack) ||
        (savedSticky != null && hive.isDubLabel(savedSticky));

    if (savedSticky != null && savedSticky.isNotEmpty) {
      final matched = streamList.firstWhereOrNull((video) {
        if (wasDub && !video.isDub) return false;
        final q = video.quality?.toUpperCase();
        final saved = savedSticky.toUpperCase();
        return q == saved || video.originalUrl == savedSticky;
      });
      if (matched != null) {
        _hasAutoSelected = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handleServerSelected(matched);
          }
        });
        return;
      }
    }

    if (isStreamCompleted) {
      if (streamList.length == 1) {
        _hasAutoSelected = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handleServerSelected(streamList.first);
          }
        });
      }
    }
  }

  Future<void> fetchServers() async {
    streamList.clear();
    isServerStreamLoading.value = true;
    final ep = widget.episode;
    final sourceEpisode = DEpisode(
      episodeNumber: ep.number,
      url: ep.link,
      sortMap: ep.sortMap.isEmpty ? null : ep.sortMap,
    );

    scrapeToken =
        "scrape_${DateTime.now().millisecondsSinceEpoch}_${ep.number}_${Random().nextInt(10000)}";

    final activeSource = sourceController.activeSource.value;
    if (activeSource == null) {
      errorSnackBar('No active source selected');
      return;
    }

    final methods = activeSource.methods;
    final videoStream = methods.getVideoListStream(
      sourceEpisode,
      parameters: SourceParams(cancelToken: scrapeToken),
    );
    final videoFuture = videoStream == null
        ? methods.getVideoList(
            sourceEpisode,
            parameters: SourceParams(cancelToken: scrapeToken),
          )
        : null;

    if (videoStream != null) {
      streamSubscription = videoStream.listen(
        (data) {
          final nextVideo = hive.Video.fromVideo(data);
          final alreadyExists = streamList.any((video) =>
              video.quality == nextVideo.quality &&
              video.originalUrl == nextVideo.originalUrl);
          if (!alreadyExists) {
            streamList.add(nextVideo);
            _checkAndAutoSelect(isStreamCompleted: false);
          }
        },
        onError: (e) {
          streamError.value = e.toString();
          isServerStreamLoading.value = false;
        },
        onDone: () {
          isServerStreamLoading.value = false;
          _checkAndAutoSelect(isStreamCompleted: true);
        },
      );
    } else if (videoFuture != null) {
      videoFuture.then((vids) {
        isServerStreamLoading.value = false;
        streamList.value = vids.map((e) => hive.Video.fromVideo(e)).toList();
        _checkAndAutoSelect(isStreamCompleted: true);
      }).catchError((e) {
        isServerStreamLoading.value = false;
        streamError.value = e.toString();
      });
    }
  }

  Future<void> _handleServerSelected(hive.Video video) async {
    final mediaId = widget.anilistData.id.toString();
    if (rememberServer.value) {
      DynamicKeys.stickyServer
          .set(mediaId, video.quality ?? video.originalUrl ?? '');
    }
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    final mediaData = widget.anilistData;
    final dbId =
        '${mediaData.id}_${mediaData.serviceType.name}_${mediaData.type}';

    final auth = Get.find<ServiceHandler>();
    final isLoggedInOnline = auth.isLoggedIn.value &&
        auth.serviceType.value != ServicesType.extensions;

    if (!isLoggedInOnline) {
      await navigate(() => WatchScreen(
            episodeSrc: video,
            episodeList: widget.episodeList,
            anilistData: mediaData,
            currentEpisode: widget.episode,
            episodeTracks: streamList,
            shouldTrack: false,
          ));
      return;
    }

    final savedTracking = DynamicKeys.trackingPermission.get<bool?>(dbId);

    if (savedTracking != null && !widget.bypassDialog) {
      await navigate(() => WatchScreen(
            episodeSrc: video,
            episodeList: widget.episodeList,
            anilistData: mediaData,
            currentEpisode: widget.episode,
            episodeTracks: streamList,
            shouldTrack: savedTracking,
          ));
      return;
    }

    if (General.shouldAskForTrack.get(true) == false) {
      await navigate(() => WatchScreen(
            episodeSrc: video,
            episodeList: widget.episodeList,
            anilistData: mediaData,
            currentEpisode: widget.episode,
            episodeTracks: streamList,
          ));
      return;
    }

    final isExtension = mediaData.serviceType == ServicesType.extensions;
    final hasTrackBinding = Get.isRegistered<TrackBindingController>() &&
        Get.find<TrackBindingController>().hasAnyBinding(mediaData.id);

    bool? shouldTrack;
    if (isExtension) {
      shouldTrack = hasTrackBinding;
    } else {
      shouldTrack = await showTrackingDialog(context, dbId: dbId);
    }

    if (shouldTrack != null) {
      await navigate(() => WatchScreen(
            episodeSrc: video,
            episodeList: widget.episodeList,
            anilistData: mediaData,
            currentEpisode: widget.episode,
            episodeTracks: streamList,
            shouldTrack: shouldTrack!,
          ));
    }
  }

  Widget _buildSheetHeader(ColorScheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryContainer.opaque(0.3, iReallyMeanIt: true),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.play_arrow_rounded, size: 20, color: theme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymeXText(
                  'Episode ${widget.episode.number}',
                  variant: TextVariant.bold,
                  maxLines: 1,
                  size: 16,
                ),
                AnymeXText(
                  (widget.episode.title != null &&
                          widget.episode.title!.isNotEmpty)
                      ? widget.episode.title!
                      : 'Select streaming server quality to watch',
                  size: 12,
                  maxLines: 1,
                  color: theme.onSurface.opaque(0.5, iReallyMeanIt: true),
                ),
              ],
            ),
          ),
          AnymexOnTap(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.close_rounded,
                color: theme.onSurface.opaque(0.5, iReallyMeanIt: true)),
          ),
        ],
      ),
    );
  }

  Widget _buildScrapingLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExpressiveLoadingIndicator(),
          SizedBox(height: 16),
          AnymeXText(
            'Scanning for video streams...',
            size: 16,
            variant: TextVariant.semiBold,
          ),
          SizedBox(height: 8),
          AnymeXText(
            'This may take a few seconds',
            size: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        const AnymeXText(
          "Error Occurred",
          variant: TextVariant.bold,
          size: 18,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.opaque(0.1, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnymeXText(
            errorMessage,
            variant: TextVariant.regular,
            size: 14,
            textAlign: TextAlign.center,
            color: Colors.red.opaque(0.8, iReallyMeanIt: true),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const SizedBox(
      height: 200,
      child: Center(
        child: AnymeXText(
          "No servers available",
          variant: TextVariant.bold,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildServerList(Media mediaData, {bool showBottomLoader = false}) {
    final theme = context.colors;
    final mediaId = widget.anilistData.id.toString();
    final savedSticky = DynamicKeys.stickyServer.get<String?>(mediaId);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: AnymeXTileBuilder<hive.Video>(
          lazy: true,
          items: streamList,
          isSelection: false,
          getTitle: (video) => video.quality?.toUpperCase() ?? "UNKNOWN",
          getSubtitleWidget: (video) {
            final subsCount = video.subtitles?.length ?? 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: theme.secondary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.closed_caption_rounded,
                    color: theme.onSecondary,
                    size: 16,
                  ),
                  2.width(),
                  AnymeXText(
                    subsCount.toString(),
                    size: 10,
                    variant: TextVariant.semiBold,
                    color: theme.onSecondary,
                  ),
                ],
              ),
            );
          },
          maxLines: 9999,
          getLeading: (video) => Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.primaryContainer.opaque(0.3, iReallyMeanIt: true),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              size: 20,
              color: theme.primary,
            ),
          ),
          getTrailing: (video) {
            final quality = video.quality?.toUpperCase() ?? "UNKNOWN";
            final isSaved = savedSticky != null &&
                savedSticky.isNotEmpty &&
                (quality == savedSticky.toUpperCase() ||
                    video.originalUrl == savedSticky);

            if (isSaved) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primary.opaque(0.15, iReallyMeanIt: true),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const AnymeXText(
                      'Default',
                      size: 11,
                      variant: TextVariant.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.onSurface.opaque(0.4, iReallyMeanIt: true),
                  ),
                ],
              );
            }
            return Icon(
              Icons.chevron_right_rounded,
              color: theme.onSurface.opaque(0.4, iReallyMeanIt: true),
            );
          },
          headerChildren: [
            Obx(
              () => AnymeXTile.checkbox(
                icon: Icons.bookmark_outline_rounded,
                title: 'Remember Server',
                subtitle: 'Auto-select this server quality for this anime',
                value: rememberServer.value,
                onChanged: (val) {
                  rememberServer.value = val;
                  if (!val) {
                    DynamicKeys.stickyServer.set(mediaId, '');
                  }
                },
              ),
            ),
          ],
          onItemPressed: (video) => _handleServerSelected(video),
          footerChildren: [
            if (showBottomLoader)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: ExpressiveLoadingIndicator(),
                    ),
                    const SizedBox(width: 8),
                    AnymeXText(
                      'Scanning for more servers...',
                      size: 12,
                      color: theme.onSurface.opaque(0.5, iReallyMeanIt: true),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSheetHeader(context.colors),
        Flexible(
          child: Obx(() {
            if (isServerStreamLoading.value && streamList.isEmpty) {
              return _buildScrapingLoadingState();
            } else if (streamError.value != null) {
              return _buildErrorState(streamError.value!);
            } else if (streamList.isEmpty && !isServerStreamLoading.value) {
              return _buildEmptyState();
            } else {
              return _buildServerList(
                widget.anilistData,
                showBottomLoader: isServerStreamLoading.value,
              );
            }
          }),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
