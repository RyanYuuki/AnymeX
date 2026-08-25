import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart' show VoidCallback;
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/controllers/services/jikan.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/source/source_mapper.dart';
import 'package:anymex/database/comments/model/comment.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comment_preloader.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as d;
import 'package:get/get.dart';

class MediaDetailsController extends GetxController {
  final Media initialMedia;
  final String tag;
  final d.Source? initialSource;
  final int initialTabIndex;

  MediaDetailsController({
    required this.initialMedia,
    required this.tag,
    this.initialSource,
    this.initialTabIndex = 0,
  });

  late OfflineStorageController offlineStorage;
  late AnilistAuth anilist;

  late Rx<Media> media;
  final Rxn<OfflineMedia> offlineMedia = Rxn<OfflineMedia>();
  final Rxn<TrackedMedia> trackedMedia = Rxn<TrackedMedia>();

  final RxList<Episode> episodeList = <Episode>[].obs;
  final RxList<Episode> rawEpisodes = <Episode>[].obs;
  final RxList<Episode> anifyEpisodes = <Episode>[].obs;
  final RxList<Chapter> chapterList = <Chapter>[].obs;

  final RxBool isLoading = true.obs;
  final RxBool isSyncing = false.obs;
  final RxBool episodeError = false.obs;
  final RxString searchedTitle = ''.obs;
  final RxBool isAnilistLoading = false.obs;
  final RxBool isSecondaryLoading = false.obs;

  final Rxn<d.Source> activeSource = Rxn<d.Source>();
  late RxInt selectedPage;

  final RxDouble mediaScore = 0.0.obs;
  final RxInt mediaProgress = 0.obs;
  final RxString mediaStatus = "".obs;
  final RxBool isListedMedia = false.obs;

  final RxInt timeLeft = 0.obs;
  Timer? countdownTimer;
  VoidCallback? _offlineStorageListener;

  final Rxn<List<Comment>> comments = Rxn();
  final Map<String, bool> fillerEpisodes = {};

  final RxBool isAnify = true.obs;
  final RxBool showAnify = true.obs;
  final RxBool disableAnifyForCurrentSource = false.obs;
  final RxString selectedEpisodeStyle = 'compact'.obs;
  final RxBool isInCustomList = false.obs;

  int _sourceRequestVersion = 0;
  Worker? _activeSourceWorker;
  Worker? _isAnifyWorker;
  bool _isInitialFetchDone = false;

  bool get isAnime => initialMedia.mediaType == d.ItemType.anime;
  bool get isManga => initialMedia.mediaType == d.ItemType.manga;
  bool get isNovel => initialMedia.mediaType == d.ItemType.novel;

  int _beginSourceRequest() {
    SourceMapper.interruptMapping();
    sourceController.cancelInProgress('search');
    sourceController.cancelInProgress('detail');
    sourceController.cancelInProgress('manga_search');
    sourceController.cancelInProgress('manga_detail');
    return ++_sourceRequestVersion;
  }

  bool _isStaleSourceRequest(int reqId) => reqId != _sourceRequestVersion;

  @override
  void onInit() {
    super.onInit();
    offlineStorage = Get.find<OfflineStorageController>();
    anilist = Get.find<AnilistAuth>();

    selectedPage = initialTabIndex.obs;
    final cached = Get.find<CacheController>().getCacheById(initialMedia.id);
    media = Rx<Media>(cached ?? initialMedia);
    isAnilistLoading.value = cached == null;
    isSecondaryLoading.value = cached == null;

    searchedTitle.value = "Searching: ${initialMedia.title}...";
    selectedEpisodeStyle.value =
        PlayerUiKeys.mediaIndicatorTheme.get<String>('compact');

    _restorePreferredSource();
    _initActiveSource();
    _bindSourceWorker();
    _bindAnifyWorker();
    _initOfflineAndTrackedData();
    checkIfInCustomList();

    _offlineStorageListener = () {
      refreshProgress();
    };
    offlineStorage.addListener(_offlineStorageListener!);

    _fetchContentFromSource();
    _fetchFullDetails().then((_) {
      _fetchSecondaryAnilistData();
    });
  }

  @override
  void onClose() {
    countdownTimer?.cancel();
    _activeSourceWorker?.dispose();
    _isAnifyWorker?.dispose();
    SourceMapper.interruptMapping();
    sourceController.cancelInProgress('search');
    sourceController.cancelInProgress('detail');
    sourceController.cancelInProgress('manga_search');
    sourceController.cancelInProgress('manga_detail');
    if (_offlineStorageListener != null) {
      offlineStorage.removeListener(_offlineStorageListener!);
    }
    super.onClose();
  }

  void setEpisodeStyle(String styleId) {
    selectedEpisodeStyle.value = styleId;
    PlayerUiKeys.mediaIndicatorTheme.set(styleId);
  }

  void _restorePreferredSource() {
    final titleId = media.value.id.toString();
    final savedSourceId = sourceController.getPreferredSource(titleId);
    if (savedSourceId != null) {
      final savedSource =
          sourceController.getSavedSource(titleId, media.value.mediaType);
      if (savedSource != null) {
        sourceController.setActiveSource(savedSource, mediaId: titleId);
        activeSource.value = savedSource;
      }
    }
  }

  void _initActiveSource() {
    if (initialSource != null) {
      activeSource.value = initialSource;
      return;
    }

    if (activeSource.value != null) return;

    if (isAnime) {
      if (sourceController.activeSource.value == null &&
          sourceController.installedExtensions.isNotEmpty) {
        sourceController.setActiveSource(sourceController.installedExtensions.first);
      }
      activeSource.value = sourceController.activeSource.value ??
          (sourceController.installedExtensions.isNotEmpty
              ? sourceController.installedExtensions.first
              : null);
    } else if (isManga) {
      if (sourceController.activeMangaSource.value == null &&
          sourceController.installedMangaExtensions.isNotEmpty) {
        sourceController.setActiveSource(sourceController.installedMangaExtensions.first);
      }
      activeSource.value = sourceController.activeMangaSource.value ??
          (sourceController.installedMangaExtensions.isNotEmpty
              ? sourceController.installedMangaExtensions.first
              : null);
    } else {
      activeSource.value = sourceController.activeNovelSource.value ??
          (sourceController.installedNovelExtensions.isNotEmpty
              ? sourceController.installedNovelExtensions.first
              : null);
    }
  }

  void _bindSourceWorker() {
    final targetRx = isAnime
        ? sourceController.activeSource
        : (isManga
            ? sourceController.activeMangaSource
            : sourceController.activeNovelSource);

    _activeSourceWorker = ever<d.Source?>(targetRx, (newSource) {
      if (newSource != null &&
          newSource.id != activeSource.value?.id &&
          _isInitialFetchDone) {
        switchSource(newSource);
      }
    });
  }

  void _bindAnifyWorker() {
    _isAnifyWorker = ever<bool>(isAnify, (useAnify) {
      if (!isAnime || rawEpisodes.isEmpty) return;

      if (useAnify) {
        if (anifyEpisodes.isNotEmpty) {
          episodeList
              .assignAll(_renewEpisodeData(List<Episode>.from(anifyEpisodes)));
          _fetchFillerInfo();
        } else {
          _applyAnifyCovers(reqId: _sourceRequestVersion);
        }
      } else {
        episodeList
            .assignAll(_renewEpisodeData(List<Episode>.from(rawEpisodes)));
        _fetchFillerInfo();
      }
    });
  }

  void _initOfflineAndTrackedData() {
    if (isAnime) {
      offlineMedia.value = offlineStorage.getAnimeById(initialMedia.id);
    } else if (isManga) {
      offlineMedia.value = offlineStorage.getMangaById(initialMedia.id);
    } else {
      offlineMedia.value = offlineStorage.getNovelById(initialMedia.id);
    }

    int trackerProgress = 0;
    if (serviceHandler.isLoggedIn.value &&
        serviceHandler.serviceType.value != ServicesType.extensions) {
      final list = isAnime
          ? serviceHandler.onlineService.animeList
          : serviceHandler.onlineService.mangaList;
      final found = list.firstWhereOrNull((e) => e.id == initialMedia.id);
      if (found != null) {
        trackedMedia.value = found;
        isListedMedia.value = true;
        mediaScore.value = double.tryParse(found.score ?? '0') ?? 0.0;
        trackerProgress =
            double.tryParse(found.episodeCount ?? '0')?.toInt() ?? 0;
        mediaStatus.value = found.watchingStatus ?? '';
      }
    }

    int localProgress = 0;
    final offline = offlineMedia.value;
    if (offline != null) {
      if (isAnime) {
        final currentEp = offline.currentEpisode;
        if (currentEp != null) {
          final epNum = double.tryParse(currentEp.number.toString())?.toInt() ?? 0;
          final ts = currentEp.timeStampInMilliseconds ?? 0;
          final dur = currentEp.durationInMilliseconds ?? 0;
          final markAsCompleted = Get.isRegistered<Settings>()
              ? Get.find<Settings>().markAsCompleted
              : 85.0;
          if (dur > 0 && (ts / dur) * 100 >= markAsCompleted) {
            localProgress = epNum;
          } else {
            localProgress = max(0, epNum - 1);
          }
        }
      } else {
        final currentCh = offline.currentChapter;
        if (currentCh != null) {
          final chNum = double.tryParse(currentCh.number.toString())?.toInt() ?? 0;
          final page = currentCh.pageNumber;
          final total = currentCh.totalPages;
          final isComplete = page != null &&
              total != null &&
              total > 0 &&
              (page >= total || page >= total - 1 || (page / total) >= 0.95);
          if (isComplete) {
            localProgress = chNum;
          } else {
            localProgress = max(0, chNum - 1);
          }
        }
      }
    }

    mediaProgress.value =
        trackerProgress > localProgress ? trackerProgress : localProgress;
  }

  void refreshProgress() {
    _initOfflineAndTrackedData();
  }

  Future<void> _fetchFullDetails() async {
    isAnilistLoading.value = true;
    try {
      if (initialMedia.serviceType == ServicesType.extensions) {
        return;
      }
      final fullMedia = await initialMedia.serviceType.service.fetchDetails(
        FetchDetailsParams(
          id: initialMedia.id.toString(),
          type: initialMedia.mediaType,
        ),
      );
      final prevAlt = media.value.altMediaContent;
      final prevStaff = media.value.staff;
      final prevFriends = media.value.friendsWatching;
      media.value = fullMedia;
      if (prevAlt != null && media.value.altMediaContent == null) {
        media.value.altMediaContent = prevAlt;
      }
      if (prevStaff != null && media.value.staff == null) {
        media.value.staff = prevStaff;
      }
      if (prevFriends != null && media.value.friendsWatching == null) {
        media.value.friendsWatching = prevFriends;
      }
      if (fullMedia.nextAiringEpisode != null) {
        startCountdown(fullMedia.nextAiringEpisode!.airingAt);
      }
    } catch (e) {
      Logger.e('Error fetching full media details: $e');
    } finally {
      isAnilistLoading.value = false;
    }
  }

  Future<void> _fetchSecondaryAnilistData() async {
    if (initialMedia.serviceType != ServicesType.anilist) {
      isSecondaryLoading.value = false;
      return;
    }
    isSecondaryLoading.value = true;
    try {
      final parsedId = int.tryParse(initialMedia.id);
      if (parsedId != null) {
        await Get.find<AnilistData>()
            .fetchSecondaryDetails(initialMedia.id, media.value);
        media.refresh();
      }
    } catch (e) {
      Logger.e('Error fetching secondary AniList details: $e');
    } finally {
      isSecondaryLoading.value = false;
    }
  }

  List<String> _formatTitles(Media media) {
    String sanitize(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == '?' || trimmed == '??') return '';
      return trimmed;
    }

    final englishTitle = sanitize(media.title);
    final romajiTitle = sanitize(media.romajiTitle);

    final first = englishTitle.isNotEmpty
        ? englishTitle
        : (romajiTitle.isNotEmpty ? romajiTitle : 'Unknown Title');
    final second = romajiTitle.isNotEmpty ? romajiTitle : first;

    return ['$first*ANIME', second];
  }

  void _updateAnifyAvailabilityForSource() {
    final src = activeSource.value;
    final shouldDisable = src is d.CloudStreamSource;
    disableAnifyForCurrentSource.value = shouldDisable;

    if (shouldDisable) {
      showAnify.value = false;
      isAnify.value = false;
    }
  }

  Future<void> _fetchContentFromSource({int? requestId}) async {
    final reqId = requestId ?? _beginSourceRequest();
    episodeError.value = false;
    isLoading.value = true;
    episodeList.clear();
    rawEpisodes.clear();
    anifyEpisodes.clear();
    chapterList.clear();

    final source = activeSource.value;
    if (source == null) {
      isLoading.value = false;
      searchedTitle.value = "No Source Selected";
      _isInitialFetchDone = true;
      return;
    }

    _updateAnifyAvailabilityForSource();

    final key =
        '${source.id}-${media.value.id}-${media.value.serviceType.index}';
    final savedTitle = DynamicKeys.mappedMediaTitle.get<String?>(key, null);

    final mappedData = await SourceMapper.mapMedia(
      _formatTitles(media.value),
      searchedTitle,
      mediaId: media.value.id.toString(),
      type: media.value.mediaType,
      savedTitle: savedTitle,
      synonyms: media.value.synonyms,
    );

    if (_isStaleSourceRequest(reqId)) return;

    if (mappedData != null && mappedData.id.isNotEmpty) {
      try {
        final detailToken =
            "detail_${DateTime.now().millisecondsSinceEpoch}_$reqId";
        sourceController.updateToken(
            isManga ? 'manga_detail' : 'detail', detailToken);

        final data = await source.methods.getDetail(
          d.DMedia.withUrl(mappedData.id),
          parameters: d.SourceParams(cancelToken: detailToken),
        );

        if (_isStaleSourceRequest(reqId)) return;

        if (isAnime) {
          final foundTitle = (data.title != null && data.title!.isNotEmpty)
              ? data.title!
              : mappedData.title;
          final converted = _convertEpisodes(
            (data.episodes ?? []).reversed.toList(),
            foundTitle,
          );
          rawEpisodes.assignAll(converted);
          episodeList.assignAll(_renewEpisodeData(converted));
          searchedTitle.value = "Found: $foundTitle";
          isLoading.value = false;
          _isInitialFetchDone = true;

          _fetchFillerInfo();
          if (isAnify.value && !disableAnifyForCurrentSource.value) {
            _applyAnifyCovers(reqId: reqId);
          }
        } else {
          final fetched = Media.fromDManga(data, media.value.mediaType);
          chapterList.assignAll(fetched.altMediaContent ?? []);
          final foundTitle = (data.title != null && data.title!.isNotEmpty)
              ? data.title!
              : mappedData.title;
          searchedTitle.value = "Found: $foundTitle";
          isLoading.value = false;
          _isInitialFetchDone = true;
        }
        CommentPreloader.to.preloadComments(media.value);
      } catch (e) {
        if (_isStaleSourceRequest(reqId)) return;
        Logger.e('Failed to fetch details from mapped media: $e');
        episodeError.value = true;
        isLoading.value = false;
        _isInitialFetchDone = true;
      }
    } else {
      if (_isStaleSourceRequest(reqId)) return;
      episodeError.value = true;
      searchedTitle.value = "No Match Found";
      isLoading.value = false;
      _isInitialFetchDone = true;
    }
  }

  Future<void> fetchSourceDetailsFromMedia(Media mappedMedia) async {
    final reqId = _beginSourceRequest();
    episodeError.value = false;
    isLoading.value = true;
    searchedTitle.value = "Searching: ${mappedMedia.title}...";

    try {
      final source = activeSource.value;
      if (source == null) {
        isLoading.value = false;
        searchedTitle.value = "No Source Selected";
        return;
      }

      final detailToken =
          "detail_${DateTime.now().millisecondsSinceEpoch}_$reqId";
      sourceController.updateToken(
          isManga ? 'manga_detail' : 'detail', detailToken);

      final data = await source.methods.getDetail(
        d.DMedia.withUrl(mappedMedia.id),
        parameters: d.SourceParams(cancelToken: detailToken),
      );

      if (_isStaleSourceRequest(reqId)) return;

      if (isAnime) {
        final converted = _convertEpisodes(
          (data.episodes ?? []).reversed.toList(),
          mappedMedia.title,
        );
        rawEpisodes.assignAll(converted);
        episodeList.assignAll(_renewEpisodeData(converted));
        searchedTitle.value = "Found: ${mappedMedia.title}";
        isLoading.value = false;

        _fetchFillerInfo();
        if (isAnify.value && !disableAnifyForCurrentSource.value) {
          _applyAnifyCovers(reqId: reqId);
        }
      } else {
        final fetched = Media.fromDManga(data, media.value.mediaType);
        chapterList.assignAll(fetched.altMediaContent ?? []);
        searchedTitle.value = "Found: ${mappedMedia.title}";
        isLoading.value = false;
      }

      final mappingKey =
          '${source.id}-${media.value.id}-${media.value.serviceType.index}';
      DynamicKeys.mappedMediaTitle.set(mappingKey, mappedMedia.title);
    } catch (e) {
      if (_isStaleSourceRequest(reqId)) return;
      Logger.e('Failed to fetch source details from mapped media: $e');
      episodeError.value = true;
      searchedTitle.value = "No Match Found";
      isLoading.value = false;
    }
  }

  List<Episode> _convertEpisodes(List<dynamic> episodes, String title) {
    final data = episodes.map((ep) => DEpisodeToEpisode(ep)).toList();
    if (data.isEmpty) return data;
    return data;
  }

  List<Episode> _renewEpisodeData(List<Episode> episodes) {
    if (episodes.any((episode) => episode.sortMap.isNotEmpty)) {
      return episodes;
    }
    if (episodes.length >= 3 &&
        (int.tryParse(episodes[0].number) ?? 0) > 3 &&
        (int.tryParse(episodes[1].number) ?? 0) > 3 &&
        (int.tryParse(episodes[2].number) ?? 0) > 3) {
      for (int i = 0; i < episodes.length; i++) {
        episodes[i].number = (i + 1).toString();
      }
      return episodes;
    }
    Set<String> seenNumbers = {};
    return episodes.map((episode) {
      if (seenNumbers.contains(episode.number)) {
        episode.number = (seenNumbers.length + 1).toString();
      }
      seenNumbers.add(episode.number);
      return episode;
    }).toList();
  }

  Future<void> _applyAnifyCovers({int? reqId}) async {
    if (rawEpisodes.isEmpty ||
        !isAnify.value ||
        disableAnifyForCurrentSource.value) {
      return;
    }
    try {
      final baseList = rawEpisodes.map((e) => e.clone()).toList();
      final newEps = await AnilistData.fetchEpisodesFromAnify(
        media.value.id,
        baseList,
      );
      if (reqId != null && _isStaleSourceRequest(reqId)) return;
      if (newEps.isNotEmpty) {
        anifyEpisodes.assignAll(newEps);
        if (isAnify.value) {
          episodeList.assignAll(_renewEpisodeData(newEps));
          _fetchFillerInfo();
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchFillerInfo() async {
    if (!isAnime || episodeList.isEmpty) return;
    final malId = media.value.idMal;
    if (malId.isEmpty) return;

    try {
      final fillerMap = await JikanService.getFillerEpisodes(malId);
      if (fillerMap.isNotEmpty) {
        for (var ep in episodeList) {
          if (fillerMap.containsKey(ep.number)) {
            ep.filler = true;
          }
        }
        episodeList.refresh();
      }
    } catch (_) {}
  }

  void startCountdown(int arrivingAt) {
    countdownTimer?.cancel();
    int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int difference = arrivingAt - currentTime;
    timeLeft.value = difference > 0 ? difference : 0;

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft.value > 0) {
        timeLeft.value--;
      } else {
        timer.cancel();
      }
    });
  }

  String formatCountdownTime(int seconds) {
    if (seconds <= 0) return '0';
    int days = seconds ~/ (24 * 3600);
    seconds %= 24 * 3600;
    int hours = seconds ~/ 3600;
    seconds %= 3600;
    int minutes = seconds ~/ 60;
    return '${days}d ${hours}h ${minutes}m';
  }

  Future<void> switchSource(d.Source newSource) async {
    final reqId = _beginSourceRequest();
    activeSource.value = newSource;
    sourceController.setActiveSource(newSource,
        mediaId: media.value.id.toString());
    await _fetchContentFromSource(requestId: reqId);
  }

  Future<void> syncDetails() async {
    isSyncing.value = true;
    try {
      await _fetchFullDetails();
    } catch (e) {
      errorSnackBar('Sync failed');
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> updateListEntry({
    required String status,
    required int progress,
    required double score,
    int? season,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? isPrivate,
  }) async {
    if (!serviceHandler.isLoggedIn.value) return;
    try {
      final malId = (media.value.idMal.isNotEmpty && media.value.idMal != '0')
          ? media.value.idMal
          : trackedMedia.value?.idMal;
      await serviceHandler.onlineService.updateListEntry(
        UpdateListEntryParams(
          listId: media.value.id,
          syncIds: malId != null && malId.isNotEmpty ? [malId] : null,
          status: status,
          progress: progress,
          score: score,
          isAnime: isAnime,
          season: season,
          startedAt: startedAt,
          completedAt: completedAt,
          isPrivate: isPrivate,
        ),
      );
      mediaStatus.value = status;
      mediaProgress.value = progress;
      mediaScore.value = score;
      isListedMedia.value = true;
      snackBar('List entry updated successfully!');
    } catch (e) {
      errorSnackBar('Failed to update list entry');
    }
  }

  Future<void> deleteListEntry() async {
    if (!serviceHandler.isLoggedIn.value) return;
    try {
      final listId = trackedMedia.value?.mediaListId ??
          trackedMedia.value?.id ??
          media.value.id;
      if (listId.isEmpty) return;
      await serviceHandler.onlineService.deleteListEntry(
        listId,
        isAnime: isAnime,
      );
      mediaStatus.value = '';
      mediaProgress.value = 0;
      mediaScore.value = 0.0;
      isListedMedia.value = false;
      trackedMedia.value = null;
    } catch (e) {
      errorSnackBar('Failed to delete list entry');
    }
  }

  Episode? getContinueEpisode() {
    if (episodeList.isEmpty) return null;
    final progress = mediaProgress.value;
    final nextNumber = progress + 1;
    final nextEp = episodeList.firstWhereOrNull((e) =>
        int.tryParse(e.number) == nextNumber ||
        e.number == nextNumber.toString());
    if (nextEp != null) return nextEp;
    final currEp = episodeList.firstWhereOrNull((e) =>
        int.tryParse(e.number) == progress || e.number == progress.toString());
    if (currEp != null) return currEp;
    return episodeList.first;
  }

  Chapter? getContinueChapter() {
    if (chapterList.isEmpty) return null;

    final offline = offlineMedia.value;
    final currentCh = offline?.currentChapter;

    if (currentCh != null) {
      final index = chapterList.indexWhere((c) =>
          (c.link != null && c.link == currentCh.link) ||
          (c.number != null && c.number == currentCh.number));

      if (index != -1) {
        final page = currentCh.pageNumber;
        final total = currentCh.totalPages;
        final isComplete = page != null &&
            total != null &&
            total > 0 &&
            (page >= total || page >= total - 1 || (page / total) >= 0.95);

        if (isComplete) {
          final sortedChapters = List<Chapter>.from(chapterList)
            ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));
          
          final sortedIndex = sortedChapters.indexWhere((c) =>
              (c.link != null && c.link == currentCh.link) ||
              (c.number != null && c.number == currentCh.number));
              
          if (sortedIndex != -1 && sortedIndex + 1 < sortedChapters.length) {
            final nextCh = sortedChapters[sortedIndex + 1];
            return chapterList.firstWhereOrNull((c) =>
                (c.link != null && c.link == nextCh.link) ||
                (c.number != null && c.number == nextCh.number)) ?? nextCh;
          }
        }
        return chapterList[index];
      }
    }

    final progress = mediaProgress.value;
    final nextNumber = progress + 1;
    final nextCh =
        chapterList.firstWhereOrNull((c) => c.number?.toInt() == nextNumber);
    if (nextCh != null) return nextCh;
    final currCh =
        chapterList.firstWhereOrNull((c) => c.number?.toInt() == progress);
    if (currCh != null) return currCh;
    return chapterList.first;
  }

  double getEpisodeProgress(Episode episode) {
    final offline = offlineMedia.value;
    if (offline == null) return 0.0;
    final savedEP = (offline.watchedEpisodes ?? [])
        .firstWhereOrNull((e) => e.number == episode.number);
    if (savedEP != null &&
        savedEP.timeStampInMilliseconds != null &&
        savedEP.durationInMilliseconds != null &&
        savedEP.durationInMilliseconds! > 0) {
      return savedEP.timeStampInMilliseconds! / savedEP.durationInMilliseconds!;
    }
    final currentEP = offline.currentEpisode;
    if (currentEP != null &&
        currentEP.number == episode.number &&
        currentEP.timeStampInMilliseconds != null &&
        currentEP.durationInMilliseconds != null &&
        currentEP.durationInMilliseconds! > 0) {
      return currentEP.timeStampInMilliseconds! /
          currentEP.durationInMilliseconds!;
    }
    return 0.0;
  }

  double getChapterProgress(Chapter chapter) {
    final offline = offlineMedia.value;
    if (offline == null) return 0.0;
    final readChaptersList = offline.readChapters ?? <Chapter>[];
    final savedChap =
        readChaptersList.firstWhereOrNull((c) => c.number == chapter.number) ??
            chapter;
    final totalPages = savedChap.totalPages ?? 0;
    final currentPage = savedChap.pageNumber ?? 0;
    return totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;
  }

  Future<void> checkIfInCustomList() async {
    final type = initialMedia.mediaType;
    final idStr = media.value.id.toString();
    final lists = await offlineStorage.getCustomListsFromType(type);
    isInCustomList.value =
        lists.any((list) => list.mediaIds?.contains(idStr) ?? false);
  }
}
