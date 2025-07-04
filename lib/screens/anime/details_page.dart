// ignore_for_file: invalid_use_of_protected_member
import 'dart:async';
import 'dart:developer';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/source/source_mapper.dart';
import 'package:anymex/core/Eval/dart/model/m_manga.dart';
import 'package:anymex/core/Search/get_detail.dart';
import 'package:anymex/core/get_source_preference.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/screens/anime/widgets/anime_stats.dart';
import 'package:anymex/screens/anime/widgets/custom_list_dialog.dart';
import 'package:anymex/screens/anime/widgets/episode_section.dart';
import 'package:anymex/screens/anime/widgets/list_editor.dart';
import 'package:anymex/screens/anime/widgets/seasons_buttons.dart';
import 'package:anymex/screens/anime/widgets/voice_actor.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/media_mapper.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/anime/gradient_image.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/custom_widgets/custom_button.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class AnimeDetailsPage extends StatefulWidget {
  final Media media;
  final String tag;
  const AnimeDetailsPage({super.key, required this.media, required this.tag});

  @override
  State<AnimeDetailsPage> createState() => _AnimeDetailsPageState();
}

class _AnimeDetailsPageState extends State<AnimeDetailsPage> {
  // AnilistData
  Media? anilistData;
  Rx<TrackedMedia?> currentAnime = TrackedMedia().obs;
  final anilist = Get.find<AnilistAuth>();
  final fetcher = Get.find<ServiceHandler>();
  // Tracker for Avail Anime
  RxBool isListedAnime = false.obs;

  // Offline Storage
  final offlineStorage = Get.find<OfflineStorageController>();

  // Extension Data
  RxString searchedTitle = ''.obs;
  RxList<Episode> episodeList = <Episode>[].obs;
  RxList<Episode> rawEpisodes = <Episode>[].obs;
  Rx<bool> isAnify = true.obs;
  Rx<bool> showAnify = true.obs;

  // Current Anime
  RxDouble animeScore = 0.0.obs;
  RxInt animeProgress = 0.obs;
  RxString animeStatus = "CURRENT".obs;

  // Page View Tracker
  RxInt selectedPage = 0.obs;

  // Error tracker
  RxBool episodeError = false.obs;

  // Tracker's Controller
  PageController controller = PageController();

  // Extensions Controller
  final sourceController = Get.find<SourceController>();

  // Episode Countdown
  final RxInt timeLeft = 0.obs;

  String posterColor = '';

  void _onPageSelected(int index) {
    selectedPage.value = index;
    controller.animateToPage(index,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  void initState() {
    super.initState();
    if (sourceController.installedExtensions.isEmpty) {
      showAnify.value = false;
    }
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
      log("Media Syncer Failed => $e");
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _initListVars() {
    animeProgress.value = currentAnime.value?.episodeCount?.toInt() ?? 0;
    animeScore.value = currentAnime.value?.score?.toDouble() ?? 0.0;
    animeStatus.value = currentAnime.value?.watchingStatus ?? "CURRENT";
    setState(() {});
  }

  void _checkAnimePresence() {
    fetcher.onlineService.setCurrentMedia(widget.media.id.toString());
    var data = fetcher.onlineService.currentMedia;

    if (data.value.id != null || data.value.id != '') {
      isListedAnime.value = true;
      currentAnime = data;
    } else {
      isListedAnime.value = false;
      currentAnime.value = null;
    }
    _initListVars();
  }

  Future<void> _fetchAnilistData() async {
    try {
      log("Fetch Initiated for Media => ${widget.media.id}");

      final tempData = await fetcher
          .fetchDetails(FetchDetailsParams(id: widget.media.id.toString()));
      final isExtensions = fetcher.serviceType.value == ServicesType.extensions;

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
      timeLeft.value = tempData.nextAiringEpisode?.airingAt ?? 0;
      if (timeLeft.value != 0) {
        startCountdown(tempData.nextAiringEpisode!.airingAt);
      }
      if (isExtensions) {
        showAnify.value = false;
      }
      log("Data Loaded for media => ${widget.media.title}");

      if (isExtensions) {
        _processExtensionData(tempData);
      } else {
        Future.wait([_mapToService(), _syncMediaIds()]);
      }
    } catch (e) {
      if (e.toString().contains('author')) {
        log("Hianime Error Handling");
        await _mapToService();
      }
      log("Media Details Fetch Failed => $e");
    }
  }

  Future<void> _mapToService() async {
    final mappedData =
        await mapMedia(formatTitles(anilistData!) ?? [], searchedTitle);
    if (mappedData != null) {
      await _fetchSourceDetails(mappedData);
    }
  }

  void _processExtensionData(Media tempData) async {
    final episodes = tempData.mediaContent!.reversed.toList();
    final convertedEpisodes = _convertEpisodes(episodes, tempData.title);
    rawEpisodes.value = _createRawEpisodes(convertedEpisodes);
    episodeList.value = _renewEpisodeData(convertedEpisodes);
    setState(() {});
  }

  Future<void> _fetchSourceDetails(Media media) async {
    try {
      episodeError.value = false;
      final episodeFuture = await getDetail(
        url: media.id,
        source: sourceController.activeSource.value!,
      );

      if (episodeFuture == null) {
        episodeError.value = true;
        return;
      }

      final episodes = _convertEpisodes(
        episodeFuture.chapters!.reversed.toList(),
        episodeFuture.name ?? '',
      );

      rawEpisodes.value = _createRawEpisodes(episodes);
      episodeList.value = _renewEpisodeData(episodes);
      searchedTitle.value = media.title;
      if (mounted) {
        setState(() {});
      }
      applyAnifyCovers();
    } catch (e) {
      episodeError.value = true;
      log(e.toString());
    }
  }

  Future<void> applyAnifyCovers() async {
    final newEps = await AnilistData.fetchEpisodesFromAnify(
      widget.media.id.toString(),
      episodeList.value,
    );
    if (newEps.isNotEmpty &&
        newEps.first.thumbnail == null &&
        (newEps.first.thumbnail?.isEmpty ?? true)) {
      showAnify.value = false;
    }
    episodeList.value = newEps;
    if (mounted) {
      setState(() {});
    }
  }

  List<Episode> _createRawEpisodes(List<Episode> eps) {
    final newEps = eps
        .map((e) => Episode(title: e.title, number: e.number, link: e.link))
        .toList();
    return newEps;
  }

  List<String>? formatTitles(Media media) {
    return ['${media.title}*ANIME', media.romajiTitle];
  }

  List<Episode> _convertEpisodes(List<dynamic> episodes, String title) {
    return episodes
        .map((ep) => mChapterToEpisode(ep, MManga(name: title)))
        .toList();
  }

  List<Episode> _renewEpisodeData(List<Episode> episodes) {
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
      strictMode: true,
      androidBuilder: _buildAndroidLayout(context),
      desktopBuilder: _buildDesktopLayout(context),
    );
  }

  Glow _buildAndroidLayout(BuildContext context) {
    return Glow(
      color: posterColor,
      child: Scaffold(
          extendBody: true,
          bottomNavigationBar: _buildMobiledNav(),
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

  SingleChildScrollView _commonSaikouLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        children: [
          GradientPoster(
            data: anilistData,
            tag: widget.tag,
            posterUrl: widget.media.poster,
          ),
          if (anilistData != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 10, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (fetcher.serviceType.value !=
                              ServicesType.extensions &&
                          fetcher.isLoggedIn.value) ...[
                        Expanded(
                          child: AnymeXButton(
                            onTap: () {
                              if (fetcher.isLoggedIn.value) {
                                showListEditorModal(context);
                              } else {
                                snackBar("You aren't logged in Genius.",
                                    duration: 1000);
                              }
                            },
                            height: 50,
                            width: double.infinity,
                            borderRadius: BorderRadius.circular(20),
                            variant: ButtonVariant.outline,
                            borderColor:
                                Theme.of(context).colorScheme.surfaceContainer,
                            child: Text(
                                convertAniListStatus(
                                    currentAnime.value?.watchingStatus),
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontFamily: "Poppins-Bold")),
                          ),
                        ),
                        const SizedBox(width: 7),
                        AnymeXButton(
                            onTap: () {
                              showCustomListDialog(context, anilistData!,
                                  offlineStorage.animeCustomLists, false);
                            },
                            height: 50,
                            borderRadius:
                                BorderRadius.circular(12.multiplyRadius()),
                            variant: ButtonVariant.outline,
                            borderColor:
                                Theme.of(context).colorScheme.surfaceContainer,
                            child: const Icon(HugeIcons.strokeRoundedLibrary))
                      ] else ...[
                        Expanded(
                          child: AnymeXButton(
                              onTap: () {
                                showCustomListDialog(context, anilistData!,
                                    offlineStorage.animeCustomLists, false);
                              },
                              height: 50,
                              width: double.infinity,
                              borderRadius:
                                  BorderRadius.circular(12.multiplyRadius()),
                              variant: ButtonVariant.outline,
                              borderColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                              child:
                                  const Icon(HugeIcons.strokeRoundedLibrary)),
                        )
                      ]
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      Obx(() {
                        return AnymexTextSpans(
                          fontSize: 16,
                          spans: [
                            const AnymexTextSpan(text: "Watched "),
                            AnymexTextSpan(
                                text: currentAnime.value?.episodeCount ?? '?',
                                variant: TextVariant.bold,
                                color: Theme.of(context).colorScheme.primary),
                            const AnymexTextSpan(text: ' Out of '),
                            if (anilistData?.nextAiringEpisode?.episode != null)
                              AnymexTextSpan(
                                  text:
                                      '${anilistData!.nextAiringEpisode!.episode - 1} | ',
                                  variant: TextVariant.bold,
                                  color: Theme.of(context).colorScheme.primary),
                            AnymexTextSpan(
                                text: anilistData?.totalEpisodes ?? '?',
                                variant: TextVariant.bold,
                                color: Theme.of(context).colorScheme.primary),
                          ],
                        );
                      }),
                      const Spacer(),
                      IconButton(
                          onPressed: () {
                            snackBar("dont know what to do with it WIP");
                          },
                          icon: const Icon(Iconsax.heart)),
                      IconButton(
                          onPressed: () {
                            snackBar("dont know what to do with it WIP");
                          },
                          icon: const Icon(Icons.share)),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(
              height: 400,
              child: Center(child: AnymexProgressIndicator()),
            )
          ],
          ExpandablePageView(
            physics: const BouncingScrollPhysics(),
            controller: controller,
            onPageChanged: (index) {
              selectedPage.value = index;
            },
            children: [
              if (anilistData != null)
                _buildCommonInfo(context)
              else
                const SizedBox.shrink(),
              _buildEpisodeSection(context),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEpisodeSection(BuildContext context) {
    return Obx(() {
      return EpisodeSection(
        searchedTitle: searchedTitle,
        anilistData: anilistData ?? widget.media,
        episodeList: (isAnify.value) ? episodeList : rawEpisodes,
        episodeError: episodeError,
        mapToAnilist: _mapToService,
        getDetailsFromSource: _fetchSourceDetails,
        getSourcePreference: getSourcePreference,
        isAnify: isAnify,
        showAnify: showAnify,
      );
    });
  }

  // Common Info Section
  Column _buildCommonInfo(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Obx(
                () => AnimeStats(
                  data: anilistData!,
                  countdown: formatTime(timeLeft.value),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        SeasonsGrid(relations: anilistData!.relations ?? []),
        ReusableCarousel(
          data: anilistData!.relations ?? [],
          title: "Relations",
          variant: DataVariant.relation,
        ),
        CharactersCarousel(characters: anilistData!.characters ?? []),
        ReusableCarousel(
          data: anilistData!.recommendations,
          title: "Recommended Animes",
          variant: DataVariant.recommendation,
        ),
      ],
    );
  }
  // Common Info Section

  // Desktop Navigation bar: START
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.2),
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
                    label: "Back"),
              ),
              const SizedBox(height: 10),
              ResponsiveNavBar(
                  isDesktop: true,
                  currentIndex: selectedPage.value,
                  fit: true,
                  borderRadius: BorderRadius.circular(20),
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
                  ]),
            ],
          ),
        ));
  }
  // Desktop Navigation bar: END

// Mobile Navigation bar: START
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
            ]));
  }

  void showListEditorModal(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return ListEditorModal(
          animeStatus: animeStatus,
          animeScore: animeScore,
          animeProgress: animeProgress,
          currentAnime: currentAnime,
          media: anilistData ?? widget.media,
          onUpdate: (id, score, status, progress) async {
            final id = fetcher.onlineService.currentMedia.value.id;
            await fetcher.onlineService.updateListEntry(UpdateListEntryParams(
                listId: id ?? widget.media.id,
                syncIds: anilistData?.idMal != null ? [anilistData!.idMal] : [],
                isAnime: true,
                score: score,
                status: status,
                progress: progress));
            setState(() {});
          },
          onDelete: (s) async {
            final id = fetcher.onlineService.currentMedia.value.mediaListId ??
                widget.media.id;
            await fetcher.onlineService.deleteListEntry(id, isAnime: true);
            setState(() {});
          },
        );
      },
    );
  }
}
// Mobile Navigation bar: END
