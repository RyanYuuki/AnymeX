import 'dart:async';

import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/controllers/services/jikan.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/source/source_mapper.dart';
import 'package:anymex/database/comments/model/comment.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/anime_stats.dart';
import 'package:anymex/screens/anime/widgets/comments/comments_section.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comment_preloader.dart';
import 'package:anymex/screens/anime/widgets/custom_list_dialog.dart';
import 'package:anymex/screens/anime/widgets/episode_section.dart';
import 'package:anymex/screens/anime/widgets/list_editor.dart';
import 'package:anymex/screens/anime/widgets/voice_actor.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/media_share.dart';
import 'package:anymex/utils/media_syncer.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anime/gradient_image.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/controllers/services/community_service.dart';
import 'package:anymex/widgets/non_widgets/recommend_button.dart';

class AnimeDetailsPage extends StatefulWidget {
  final Media media;
  final String tag;
  final int initialTabIndex;
  const AnimeDetailsPage(
      {super.key,
      required this.media,
      required this.tag,
      this.initialTabIndex = 0});

  @override
  State<AnimeDetailsPage> createState() => _AnimeDetailsPageState();
}

class _AnimeDetailsPageState extends State<AnimeDetailsPage> {
  Media? anilistData;
  Rxn<TrackedMedia> currentAnime = Rxn<TrackedMedia>();
  final anilist = Get.find<AnilistAuth>();

  RxBool isListedAnime = false.obs;

  final offlineStorage = Get.find<OfflineStorageController>();

  RxString searchedTitle = ''.obs;
  RxList<Episode> episodeList = <Episode>[].obs;
  RxList<Episode> rawEpisodes = <Episode>[].obs;
  Rx<bool> isAnify = true.obs;
  Rx<bool> showAnify = true.obs;
  RxBool disableAnifyForCurrentSource = false.obs;

  RxDouble animeScore = 0.0.obs;
  RxInt animeProgress = 0.obs;
  RxString animeStatus = "".obs;

  Rxn<List<Comment>> comments = Rxn();

  RxInt selectedPage = 0.obs;

  RxBool episodeError = false.obs;

  Map<String, bool> fillerEpisodes = {};

  late final PageController controller;

  final sourceController = Get.find<SourceController>();

  final RxInt timeLeft = 0.obs;

  String posterColor = '';
  int _sourceRequestVersion = 0;
  Worker? _activeSourceWorker;

  int _beginSourceRequest() => ++_sourceRequestVersion;
  bool _isStaleSourceRequest(int requestId) =>
      requestId != _sourceRequestVersion;

  void _onPageSelected(int index) {
    selectedPage.value = index;
    controller.animateToPage(index,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  Future<void> _showShareOptions() async {
    await MediaShare.showOptions(
      context: context,
      baseMedia: widget.media,
      hydratedMedia: anilistData,
      isManga: false,
    );
  }

  Widget _buildActionIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 50,
      width: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.opaque(0.2),
        ),
        color: Theme.of(context).colorScheme.surfaceContainer.opaque(0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Icon(icon),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final initialPage = widget.initialTabIndex.clamp(0, 2).toInt();
    selectedPage.value = initialPage;
    controller = PageController(initialPage: initialPage);
    _updateAnifyAvailabilityForSource();
    _activeSourceWorker = ever<Source?>(sourceController.activeSource, (_) {
      _updateAnifyAvailabilityForSource();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkAnimePresence();
    });

    _fetchAnilistData();
  }

  Future<void> _syncMediaIds() async {
    try {
      final id = await MediaSyncer.mapMediaId(widget.media.id);
      if (id != null) {
        setState(() {
          anilistData?.idMal = id;
        });
      }
    } catch (e) {
      Logger.i("Media Syncer Failed => $e");
    }
  }

  Future<void> _fetchFillerInfo() async {
    final malId = anilistData?.idMal ?? widget.media.idMal;

    try {
      final data = await JikanService.getFillerEpisodes(malId.toString());
      if (data.isNotEmpty) {
        fillerEpisodes = data;
        _applyFillerInfo();
      }
    } catch (_) {}
  }

  void _applyFillerInfo() {
    if (fillerEpisodes.isEmpty ||
        (episodeList.isEmpty && rawEpisodes.isEmpty)) {
      return;
    }

    bool updated = false;

    void markFillers(List<Episode> episodes) {
      for (final ep in episodes) {
        if (fillerEpisodes.containsKey(ep.number) && ep.filler != true) {
          ep.filler = true;
          updated = true;
        }
      }
    }

    markFillers(episodeList);
    markFillers(rawEpisodes);

    if (updated && mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();
    _activeSourceWorker?.dispose();

    CommentPreloader.to.removePreloadedController(widget.media.id.toString());
    DiscordRPCController.instance.updateBrowsingPresence();
    super.dispose();
  }

  void _updateAnifyAvailabilityForSource() {
    final shouldDisable =
        sourceController.activeSource.value is CloudStreamSource;
    disableAnifyForCurrentSource.value = shouldDisable;

    if (widget.media.serviceType == ServicesType.extensions ||
        sourceController.installedExtensions.isEmpty ||
        shouldDisable) {
      showAnify.value = false;
      isAnify.value = false;
    }
  }

  void _initListVars() {
    animeProgress.value = currentAnime.value?.episodeCount?.toInt() ?? 0;
    animeScore.value = currentAnime.value?.score?.toDouble() ?? 0.0;
    animeStatus.value = currentAnime.value?.watchingStatus ?? "";
    setState(() {});
  }

  void _checkAnimePresence() {
    final service = widget.media.serviceType.onlineService;
    service.setCurrentMedia(widget.media.id.toString());
    var data = service.currentMedia;

    if ((data.value.id ?? '').isNotEmpty) {
      isListedAnime.value = true;
      currentAnime.value = data.value;
      currentAnime.refresh();
    } else {
      isListedAnime.value = false;
      currentAnime.value = null;
    }
    _initListVars();
  }

  Future<void> _fetchAnilistData() async {
    try {
      Logger.i("Fetch Initiated for Media => ${widget.media.id}");

      final service = widget.media.serviceType.service;

      final tempData = await service
          .fetchDetails(FetchDetailsParams(id: widget.media.id.toString()));

      final isExtensions = widget.media.serviceType == ServicesType.extensions;

      setState(() {
        if (isExtensions) {
          anilistData = tempData
            ..title = widget.media.title
            ..poster = widget.media.poster
            ..id = widget.media.id;
        } else {
          anilistData = tempData;
          posterColor = tempData.color;
        }
      });
      DiscordRPCController.instance
          .updateMediaPresence(media: anilistData ?? widget.media);
      CommentPreloader.to.preloadComments(anilistData!);
      timeLeft.value = tempData.nextAiringEpisode?.airingAt ?? 0;
      if (timeLeft.value != 0) {
        startCountdown(tempData.nextAiringEpisode!.airingAt);
      }
      _updateAnifyAvailabilityForSource();
      Logger.i("Data Loaded for media => ${widget.media.title}");

      if (isExtensions) {
        _processExtensionData(tempData);
      } else {
        _fetchSecondaryData(tempData);
        await _restorePreferredSource();
        Future.wait([_mapToService(), _syncMediaIds(), _fetchFillerInfo()]);
      }
    } catch (e) {
      if (e.toString().contains('author')) {
        Logger.i("Hianime Error Handling");
        await _mapToService();
      }
      Logger.i("Media Details Fetch Failed => $e");
    } finally {}
  }

  Future<void> _fetchSecondaryData(Media tempData) async {
    try {
      if (widget.media.serviceType.service is AnilistData) {
        final anilistService = widget.media.serviceType.service as AnilistData;
        await anilistService.fetchSecondaryDetails(
            widget.media.id.toString(), tempData);
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      Logger.i("Secondary Data Fetch Failed => $e");
    }
  }

  Future<void> _restorePreferredSource() async {
    final titleId = widget.media.id.toString();
    final savedSourceId = sourceController.getPreferredSource(titleId);
    if (savedSourceId != null) {
      final savedSource =
          sourceController.getSavedSource(titleId, ItemType.anime);
      if (savedSource != null) {
        sourceController.setActiveSource(savedSource, mediaId: titleId);
      }
    }
  }

  Future<void> _mapToService({int? requestId}) async {
    final activeRequestId = requestId ?? _beginSourceRequest();
    episodeList.clear();
    rawEpisodes.clear();
    episodeError.value = false;
    final key =
        '${sourceController.activeSource.value?.id}-${anilistData?.id}-${anilistData?.serviceType.index}';
    final savedTitle = DynamicKeys.mappedMediaTitle.get<String?>(key, null);
    final mappedData = await SourceMapper.mapMedia(
        formatTitles(anilistData ?? widget.media) ?? [], searchedTitle,
        mediaId: widget.media.id.toString(),
        type: ItemType.anime,
        savedTitle: savedTitle,
        synonyms: anilistData?.synonyms ?? []);
    if (_isStaleSourceRequest(activeRequestId) || !mounted) {
      return;
    }
    if (mappedData != null && mappedData.id.toString().isNotEmpty) {
      await _fetchSourceDetails(mappedData, requestId: activeRequestId);
    }
  }

  List<String>? formatTitles(Media media) {
    String sanitize(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == '?' || trimmed == '??') return '';
      return trimmed;
    }

    final englishCandidates = [
      sanitize(anilistData?.title ?? ''),
      sanitize(media.title),
      sanitize(widget.media.title),
    ];
    final romajiCandidates = [
      sanitize(anilistData?.romajiTitle ?? ''),
      sanitize(media.romajiTitle),
      sanitize(widget.media.romajiTitle),
    ];

    final englishTitle =
        englishCandidates.firstWhere((title) => title.isNotEmpty, orElse: () {
      return romajiCandidates.firstWhere((title) => title.isNotEmpty,
          orElse: () => 'Unknown Title');
    });

    final romajiTitle =
        romajiCandidates.firstWhere((title) => title.isNotEmpty, orElse: () {
      return englishTitle;
    });

    return ['$englishTitle*ANIME', romajiTitle];
  }

  void _processExtensionData(Media tempData) async {
    final episodes = tempData.mediaContent!.reversed.toList();
    final convertedEpisodes = _convertEpisodes(episodes, tempData.title);
    rawEpisodes.assignAll(_cloneEpisodes(convertedEpisodes));
    episodeList.assignAll(_renewEpisodeData(_cloneEpisodes(convertedEpisodes)));
    searchedTitle.value = "Found: ${tempData.title}";
    setState(() {});
  }

  Future<void> _fetchSourceDetails(Media media, {int? requestId}) async {
    final activeRequestId = requestId ?? _beginSourceRequest();
    try {
      episodeError.value = false;
      episodeList.clear();
      rawEpisodes.clear();
      final episodeFuture = await sourceController.activeSource.value!.methods
          .getDetail(DMedia.withUrl(media.id));
      if (_isStaleSourceRequest(activeRequestId) || !mounted) {
        return;
      }

      final episodes = _convertEpisodes(
        episodeFuture.episodes!.reversed.toList(),
        episodeFuture.title ?? '',
      );

      rawEpisodes.assignAll(_cloneEpisodes(episodes));
      episodeList.assignAll(_renewEpisodeData(_cloneEpisodes(episodes)));
      searchedTitle.value = "Found: ${media.title}";
      _applyFillerInfo();
      if (mounted) {
        setState(() {});
      }
      _updateAnifyAvailabilityForSource();
      if (disableAnifyForCurrentSource.value) {
        return;
      }
      await applyAnifyCovers(requestId: activeRequestId);
    } catch (e) {
      if (_isStaleSourceRequest(activeRequestId) || !mounted) {
        return;
      }
      episodeError.value = true;
      Logger.i(e.toString());
    }
  }

  Future<void> applyAnifyCovers({int? requestId}) async {
    final activeRequestId = requestId ?? _sourceRequestVersion;
    final baseEpisodes = List<Episode>.from(episodeList);
    final newEps = await AnilistData.fetchEpisodesFromAnify(
      widget.media.id.toString(),
      baseEpisodes,
    );
    if (_isStaleSourceRequest(activeRequestId) || !mounted) {
      return;
    }
    if (newEps.isNotEmpty &&
        newEps.first.thumbnail == null &&
        (newEps.first.thumbnail?.isEmpty ?? true)) {
      showAnify.value = false;
    }
    episodeList.assignAll(newEps);
    _applyFillerInfo();
    if (mounted) {
      setState(() {});
    }
  }

  List<Episode> _cloneEpisodes(List<Episode> episodes) {
    return episodes
        .map((episode) => Episode.fromJson(episode.toJson()))
        .toList();
  }

  List<Episode> _convertEpisodes(List<dynamic> episodes, String title) {
    final data = episodes.map((ep) => DEpisodeToEpisode(ep)).toList();

    if (data.isEmpty) return data;

    if (data.first.sortMap.isNotEmpty && data.first.sortMap['season'] != null) {
      data.sort((a, b) {
        final seasonA = int.tryParse(a.sortMap['season'] ?? '0') ?? 0;
        final seasonB = int.tryParse(b.sortMap['season'] ?? '0') ?? 0;

        if (seasonA != seasonB) {
          return seasonA.compareTo(seasonB);
        }

        return _compareEpisodeNumberStrings(a.number, b.number);
      });
    }

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

  int _compareEpisodeNumberStrings(String first, String second) {
    final firstNumber = double.tryParse(first.trim());
    final secondNumber = double.tryParse(second.trim());

    if (firstNumber != null && secondNumber != null) {
      return firstNumber.compareTo(secondNumber);
    }
    if (firstNumber != null) return -1;
    if (secondNumber != null) return 1;
    return first.compareTo(second);
  }

  void startCountdown(int arrivingAt) {
    int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int difference = arrivingAt - currentTime;
    timeLeft.value = difference;

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft.value > 0) {
        timeLeft.value--;
      } else {
        timer.cancel();
      }
    });
  }

  String formatTime(int seconds) {
    if (seconds == 0) {
      return '0';
    } else {
      int days = seconds ~/ (24 * 3600);
      seconds %= 24 * 3600;
      int hours = seconds ~/ 3600;
      seconds %= 3600;
      int minutes = seconds ~/ 60;
      seconds %= 60;

      List<String> parts = [];
      if (days > 0) parts.add("$days DAYS");
      if (hours > 0) parts.add("$hours HRS");
      if (minutes > 0) parts.add("$minutes MINS");
      if (seconds > 0 || parts.isEmpty) parts.add("$seconds SECS");

      return parts.join(" ");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformBuilder(
      strictMode: !kDebugMode,
      androidBuilder: _buildAndroidLayout(context),
      desktopBuilder: _buildDesktopLayout(context),
    );
  }

  Glow _buildAndroidLayout(BuildContext context) {
    return Glow(
      color: posterColor,
      child: Scaffold(
          extendBody: true,
          bottomNavigationBar: sourceController.shouldShowExtensions.value
              ? _buildMobiledNav()
              : null,
          body: _commonSaikouLayout(context)),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Glow(
      color: posterColor,
      child: Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesktopNav(),
            Expanded(
              child: _commonSaikouLayout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _commonSaikouLayout(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Column(
              children: [
                GradientPoster(
                  data: anilistData,
                  tag: widget.tag,
                  posterUrl: widget.media.poster,
                ),
                if (anilistData != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: Column(
                      children: [
                        Obx(() {
                          widget
                              .media.serviceType.onlineService.animeList.value;
                          return Row(
                            children: [
                              if (widget.media.serviceType !=
                                      ServicesType.extensions &&
                                  widget.media.serviceType.onlineService
                                      .isLoggedIn.value) ...[
                                Expanded(
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .opaque(0.2),
                                      ),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer
                                          .opaque(0.5),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          if (widget.media.serviceType
                                              .onlineService.isLoggedIn.value) {
                                            showListEditorModal(context);
                                          } else {
                                            snackBar(
                                                "You aren't logged in Genius.",
                                                duration: 1000);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            AnymexText(
                                              text: convertAniListStatus(
                                                  animeStatus.value),
                                              variant: TextVariant.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                _buildActionIconButton(
                                  context: context,
                                  icon: Icons.share_rounded,
                                  onTap: _showShareOptions,
                                ),
                                const SizedBox(width: 7),
                                if (CommunityService.votingEnabled)
                                  RecommendIconButton(
                                    media: anilistData!,
                                    mediaItemType: ItemType.anime,
                                    buttonBuilder: (onTap, icon) =>
                                        _buildActionIconButton(
                                      context: context,
                                      icon: Icons.recommend_rounded,
                                      onTap: onTap,
                                    ),
                                  ),
                                if (CommunityService.votingEnabled)
                                  const SizedBox(width: 7),
                                _buildActionIconButton(
                                  context: context,
                                  icon: HugeIcons.strokeRoundedLibrary,
                                  onTap: () {
                                    showCustomListDialog(context, anilistData!);
                                  },
                                ),
                              ] else ...[
                                _buildActionIconButton(
                                  context: context,
                                  icon: Icons.share_rounded,
                                  onTap: _showShareOptions,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: AnymexButton2(
                                    onTap: () {
                                      showCustomListDialog(
                                          context, anilistData!);
                                    },
                                    label: 'Add to Library',
                                    icon: HugeIcons.strokeRoundedLibrary,
                                  ),
                                )
                              ]
                            ],
                          );
                        }),
                        const SizedBox(height: 10),
                        _buildProgressContainer(context)
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(
                    height: 400,
                    child: Center(child: AnymexProgressIndicator()),
                  )
                ],
              ],
            ),
          ),
        ];
      },
      body: PageView(
        physics: const BouncingScrollPhysics(),
        controller: controller,
        onPageChanged: (index) {
          selectedPage.value = index;
        },
        children: [
          _buildInfoPageBody(context),
          _buildEpisodePageBody(context),
          _buildCommentsPageBody(context),
        ],
      ),
    );
  }

  Widget _buildInfoPageBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: anilistData != null
          ? _buildCommonInfo(context)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildEpisodePageBody(BuildContext context) {
    return CustomScrollView(
      slivers: [
        EpisodeSection(
          searchedTitle: searchedTitle,
          anilistData: anilistData ?? widget.media,
          episodeList: episodeList,
          episodeError: episodeError,
          mapToAnilist: () => _mapToService(),
          getDetailsFromSource: (media) => _fetchSourceDetails(media),
          isAnify: isAnify,
          showAnify: showAnify,
          disableAnifyForCurrentSource: disableAnifyForCurrentSource,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildCommentsPageBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: _buildCommentsSection(context),
    );
  }

  String formatProgress({
    required dynamic currentChapter,
    required dynamic totalChapters,
    required dynamic altLength,
  }) {
    num parseNum(dynamic value) {
      if (value == null) return 1;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 1;
      return 1;
    }

    final num current = parseNum(currentChapter);
    final num total = parseNum(totalChapters) != 1
        ? parseNum(totalChapters)
        : parseNum(altLength);

    final num safeTotal = total.clamp(1, double.infinity);
    if (safeTotal < current) return '??';
    final progress = (current / safeTotal) * 100;
    return progress.toStringAsFixed(2);
  }

  String _formatWatchTime(int totalMinutes) {
    if (totalMinutes <= 0) return '—';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '${m}m';
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  Widget _buildTimeStat(BuildContext context,
      {required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: context.colors.surfaceContainer.opaque(0.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: context.colors.onSurface.opaque(0.5))),
            const SizedBox(height: 2),
            AnymexText(
                text: value,
                size: 14,
                variant: TextVariant.semiBold,
                color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressContainer(BuildContext context) {
    final int totalEps =
        int.tryParse(anilistData?.totalEpisodes?.toString() ?? '0') ?? 0;
    final int airedEps = (anilistData?.nextAiringEpisode?.episode ?? 1) - 1;
    final int displayTotal = totalEps > 0 ? totalEps : airedEps;
    final int watchedEps =
        int.tryParse(currentAnime.value?.episodeCount?.toString() ?? '0') ?? 0;
    final int remainingEps = (displayTotal - watchedEps).clamp(0, displayTotal);
    final int? epDuration = int.tryParse(
        (anilistData?.duration?.toString() ?? '')
            .replaceAll(RegExp(r'[^0-9]'), ''));
    final int totalMins = displayTotal * (epDuration ?? 0);
    final int watchedMins = watchedEps * (epDuration ?? 0);
    final int remainingMins = remainingEps * (epDuration ?? 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: context.colors.surfaceContainer.opaque(0.3),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.movie_filter_rounded,
                color: context.colors.onSurface.opaque(0.7),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnymexTextSpans(
                  fontSize: 14,
                  spans: [
                    AnymexTextSpan(
                      text: "Episode ",
                      color: context.colors.onSurface.opaque(0.7),
                    ),
                    AnymexTextSpan(
                      text: currentAnime.value?.episodeCount?.toString() ?? '0',
                      variant: TextVariant.bold,
                      color: context.colors.primary,
                    ),
                    AnymexTextSpan(
                      text: ' of ',
                      color: context.colors.onSurface.opaque(0.7),
                    ),
                    AnymexTextSpan(
                      text: anilistData?.totalEpisodes?.toString() ?? '??',
                      variant: TextVariant.bold,
                      color: context.colors.primary,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color:
                      context.colors.primary.opaque(0.1, iReallyMeanIt: true),
                ),
                child: Text(
                  '${formatProgress(currentChapter: currentAnime.value?.episodeCount ?? 0, totalChapters: anilistData?.totalEpisodes ?? 0, altLength: 0)}%',
                  style: TextStyle(
                    color: context.colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (displayTotal > 0 && epDuration != null && epDuration > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _buildTimeStat(context,
                    label: 'Total',
                    value: _formatWatchTime(totalMins),
                    color: context.colors.onSurface),
                const SizedBox(width: 8),
                _buildTimeStat(context,
                    label: 'Watched',
                    value: _formatWatchTime(watchedMins),
                    color: context.colors.primary),
                const SizedBox(width: 8),
                _buildTimeStat(context,
                    label: 'Remaining',
                    value: _formatWatchTime(remainingMins),
                    color: context.colors.error),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEpisodeSection(BuildContext context) {
    return Obx(() {
      return EpisodeSection(
        searchedTitle: searchedTitle,
        anilistData: anilistData ?? widget.media,
        episodeList: (!disableAnifyForCurrentSource.value && isAnify.value)
            ? episodeList
            : rawEpisodes,
        episodeError: episodeError,
        mapToAnilist: () => _mapToService(),
        getDetailsFromSource: (media) => _fetchSourceDetails(media),
        isAnify: isAnify,
        showAnify: showAnify,
        disableAnifyForCurrentSource: disableAnifyForCurrentSource,
      );
    });
  }

  Widget _buildCommentsSection(BuildContext context) {
    return CommentSection(
      media: anilistData ?? widget.media,
    );
  }

  Column _buildCommonInfo(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Obx(
                () => AnimeStats(
                  data: anilistData!,
                  countdown: formatTime(timeLeft.value),
                  friendsWatching: anilistData?.friendsWatching,
                  totalEpisodes: anilistData?.totalEpisodes,
                  serviceType: widget.media.serviceType,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        ReusableCarousel(
          data: anilistData!.relations ?? [],
          title: "Relations",
          variant: DataVariant.relation,
        ),
        CharactersCarousel(characters: anilistData!.characters ?? []),
        if (anilistData?.staff != null && anilistData!.staff!.isNotEmpty)
          StaffCarousel(staff: anilistData!.staff!),
        ReusableCarousel(
          data: anilistData!.recommendations,
          title: widget.media.serviceType == ServicesType.simkl
              ? (anilistData!.id.endsWith('*MOVIE')
                  ? 'Recommended Movies'
                  : 'Recommended Shows')
              : 'Recommended Animes',
          variant: DataVariant.recommendation,
        ),
      ],
    );
  }

  Widget _buildDesktopNav() {
    return Obx(() => Container(
          margin: const EdgeInsets.all(20),
          width: 85,
          height: 300,
          child: Column(
            children: [
              Container(
                width: 70,
                height: 65,
                padding: const EdgeInsets.all(0),
                margin: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 0,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color:
                          Theme.of(context).colorScheme.onSurface.opaque(0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(
                      20.multiplyRadius(),
                    )),
                child: NavBarItem(
                  isSelected: false,
                  isVertical: true,
                  onTap: () {
                    Get.back();
                  },
                  selectedIcon: Iconsax.back_square,
                  unselectedIcon: IconlyBold.arrow_left,
                ),
              ),
              const SizedBox(height: 10),
              ResponsiveNavBar(
                  isDesktop: true,
                  currentIndex: selectedPage.value,
                  borderRadius: BorderRadius.circular(20),
                  items: [
                    NavItem(
                        onTap: _onPageSelected,
                        selectedIcon: Iconsax.info_circle5,
                        unselectedIcon: Iconsax.info_circle,
                        label: "Info"),
                    if (sourceController.shouldShowExtensions.value)
                      NavItem(
                          onTap: _onPageSelected,
                          selectedIcon: Iconsax.play5,
                          unselectedIcon: Iconsax.play,
                          label: "Watch"),
                    NavItem(
                        onTap: _onPageSelected,
                        selectedIcon: HugeIcons.strokeRoundedComment01,
                        unselectedIcon: HugeIcons.strokeRoundedComment02,
                        label: "Comments"),
                  ]),
            ],
          ),
        ));
  }

  Widget _buildMobiledNav() {
    return Obx(() => ResponsiveNavBar(
            isDesktop: false,
            currentIndex: selectedPage.value,
            margin: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
            items: [
              NavItem(
                  onTap: _onPageSelected,
                  selectedIcon: Iconsax.info_circle5,
                  unselectedIcon: Iconsax.info_circle,
                  label: "Info"),
              NavItem(
                  onTap: _onPageSelected,
                  selectedIcon: Iconsax.play5,
                  unselectedIcon: Iconsax.play,
                  label: "Watch"),
              NavItem(
                  onTap: _onPageSelected,
                  selectedIcon: HugeIcons.strokeRoundedComment01,
                  unselectedIcon: HugeIcons.strokeRoundedComment02,
                  label: "Comments"),
            ]));
  }

  void showListEditorModal(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (BuildContext context) {
        return ListEditorModal(
          animeStatus: animeStatus,
          isManga: false,
          animeScore: animeScore,
          animeProgress: animeProgress,
          currentAnime: currentAnime,
          media: anilistData ?? widget.media,
          onUpdate: (id, score, status, progress, season, startedAt,
              completedAt, isPrivate) async {
            final fetcher = widget.media.serviceType;
            final id = fetcher.onlineService.currentMedia.value.id;
            await fetcher.onlineService.updateListEntry(UpdateListEntryParams(
                listId: id ?? widget.media.id,
                syncIds: anilistData?.idMal != null ? [anilistData!.idMal] : [],
                isAnime: true,
                score: score,
                status: status,
                progress: progress,
                season: season,
                startedAt: startedAt,
                completedAt: completedAt,
                isPrivate: isPrivate));
            currentAnime.value?.score = score.toString();
            currentAnime.value?.watchingStatus = status;
            currentAnime.value?.episodeCount = progress.toString();
            currentAnime.value?.startedAt = startedAt;
            currentAnime.value?.completedAt = completedAt;
            currentAnime.value?.isPrivate = isPrivate;
            setState(() {});
          },
          onDelete: (s) async {
            final fetcher = widget.media.serviceType;
            final id = fetcher.onlineService.currentMedia.value.mediaListId ??
                widget.media.id;
            await fetcher.onlineService.deleteListEntry(id, isAnime: true);
            _checkAnimePresence();
          },
        );
      },
    );
  }
}
