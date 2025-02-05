// ignore_for_file: invalid_use_of_protected_member
import 'dart:io';
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
import 'package:anymex/screens/anime/widgets/voice_actor.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/anime/gradient_image.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/minor_widgets/custom_button.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:anymex/widgets/minor_widgets/custom_textspan.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
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
  RxList<Episode>? episodeList = <Episode>[].obs;

  // Current Anime
  RxDouble animeScore = 0.0.obs;
  RxInt animeProgress = 0.obs;
  RxString animeStatus = "CURRENT".obs;

  // Page View Tracker
  RxInt selectedPage = 0.obs;
  RxInt desktopSelectedPage = 1.obs;

  // Error tracker
  RxBool episodeError = false.obs;

  // Tracker's Controller
  PageController controller = PageController();

  // Mangayomi Extensions
  final sourceController = Get.find<SourceController>();

  void _onPageSelected(int index) {
    selectedPage.value = index;
    controller.animateToPage(index,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void _onDesktopPageSelected(int index) {
    desktopSelectedPage.value = index;
    controller.animateToPage(index - 1,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  void initState() {
    super.initState();
    sourceController.initExtensions();
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkAnimePresence();
    });
    _fetchAnilistData();
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
      final tempData = await fetcher.fetchDetails(widget.media.id.toString());
      final isExtensions = fetcher.serviceType.value == ServicesType.extensions;

      setState(() {
        anilistData = tempData
          ..title = widget.media.title
          ..poster = widget.media.poster;
      });

      if (isExtensions) {
        _processExtensionData(tempData);
      } else {
        await _mapToService();
      }
    } catch (e) {
      snackBar(e.toString());
    }
  }

  Future<void> _mapToService() async {
    final mappedData =
        await mapMedia(formatTitles(anilistData!) ?? [], searchedTitle);
    await _fetchSourceDetails(mappedData);
  }

  void _processExtensionData(Media tempData) async {
    final episodes = tempData.mediaContent!.reversed.toList();
    final convertedEpisodes = _convertEpisodes(episodes, tempData.title);

    episodeList!.value = _renewEpisodeData(convertedEpisodes);
    searchedTitle.value = tempData.title;

    final updatedEpisodes = await AnilistData.fetchEpisodesFromAnify(
      widget.media.id.toString(),
      episodeList!.value,
    );
    episodeList?.value = updatedEpisodes;

    setState(() {});
  }

  Future<void> _fetchSourceDetails(Media media) async {
    try {
      episodeError.value = false;
      final episodeFuture = await getDetail(
        url: media.id,
        source: sourceController.activeSource.value!,
      );

      final episodes = _convertEpisodes(
        episodeFuture.chapters!.reversed.toList(),
        episodeFuture.name ?? '',
      );

      episodeList!.value = _renewEpisodeData(episodes);
      searchedTitle.value = media.title;

      final updatedEpisodes = await AnilistData.fetchEpisodesFromAnify(
        widget.media.id.toString(),
        episodeList!.value,
      );
      episodeList?.value = updatedEpisodes;

      setState(() {});
    } catch (e) {
      episodeError.value = true;
      snackBar(e.toString());
    }
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
    if (episodes.first.number.toInt() <= 3) return episodes;

    return episodes.asMap().entries.map((entry) {
      entry.value.number = (entry.key + 1).toString();
      return entry.value;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformBuilder(
      androidBuilder: _buildAndroidLayout(context),
      desktopBuilder: _buildDesktopLayout(context),
    );
  }

  Glow _buildAndroidLayout(BuildContext context) {
    return Glow(
      child: Scaffold(
          extendBody: true,
          bottomNavigationBar: _buildMobiledNav(),
          body: _commonSaikouLayout(context)),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Glow(
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
    final isMobile = Platform.isAndroid || Platform.isIOS;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
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
            ExpandablePageView(
              physics: const BouncingScrollPhysics(),
              controller: controller,
              onPageChanged: (index) {
                if (isMobile) {
                  selectedPage.value = index;
                } else {
                  desktopSelectedPage.value = index + 1;
                }
              },
              children: [
                _buildCommonInfo(context),
                _buildEpisodeSection(context),
              ],
            )
          ] else ...[
            const SizedBox(
              height: 400,
              child: Center(child: CircularProgressIndicator()),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildEpisodeSection(BuildContext context) {
    return EpisodeSection(
      searchedTitle: searchedTitle,
      anilistData: anilistData,
      episodeList: episodeList,
      episodeError: episodeError,
      mapToAnilist: _mapToService,
      getDetailsFromSource: _fetchSourceDetails,
      getSourcePreference: getSourcePreference,
    );
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
              AnimeStats(data: anilistData!),
              const SizedBox(height: 20),
            ],
          ),
        ),
        CharactersCarousel(characters: anilistData!.characters ?? []),
        ReusableCarousel(
          data: anilistData!.recommendations,
          title: "Recommended Animes",
          variant: DataVariant.recommendation,
        ),
        ReusableCarousel(
          data: anilistData!.relations ?? [],
          title: "Relations",
          variant: DataVariant.relation,
        )
      ],
    );
  }
  // Common Info Section

  // Desktop Navigation bar: START
  Widget _buildDesktopNav() {
    return Obx(() => Container(
          margin: const EdgeInsets.all(20),
          width: 85,
          height: 250,
          child: ResponsiveNavBar(
              isDesktop: true,
              currentIndex: desktopSelectedPage.value,
              items: [
                NavItem(
                    onTap: (index) {
                      Get.back();
                    },
                    selectedIcon: Iconsax.back_square,
                    unselectedIcon: Iconsax.back_square,
                    label: "Back"),
                NavItem(
                    onTap: (index) => _onDesktopPageSelected(index),
                    selectedIcon: Iconsax.info_circle5,
                    unselectedIcon: Iconsax.info_circle,
                    label: "Info"),
                NavItem(
                    onTap: (index) => _onDesktopPageSelected(index),
                    selectedIcon: Iconsax.play5,
                    unselectedIcon: Iconsax.play,
                    label: "Watch"),
              ]),
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
            await fetcher.onlineService.updateListEntry(
                listId: id ?? widget.media.id,
                isAnime: true,
                score: score,
                status: status,
                progress: progress);
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
