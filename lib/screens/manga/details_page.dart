// ignore_for_file: invalid_use_of_protected_member, unused_element
import 'dart:developer';

import 'package:anymex/controllers/source/source_mapper.dart';
import 'package:anymex/core/Eval/dart/model/m_chapter.dart';
import 'package:anymex/core/Search/get_detail.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/screens/anime/widgets/custom_list_dialog.dart';
import 'package:anymex/screens/anime/widgets/list_editor.dart';
import 'package:anymex/screens/anime/widgets/voice_actor.dart';
import 'package:anymex/screens/anime/widgets/wrongtitle_modal.dart';
import 'package:anymex/screens/manga/widgets/chapter_section.dart';
import 'package:anymex/screens/manga/widgets/manga_stats.dart';
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
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class MangaDetailsPage extends StatefulWidget {
  final Media media;
  final String tag;
  const MangaDetailsPage({super.key, required this.media, required this.tag});

  @override
  State<MangaDetailsPage> createState() => _MangaDetailsPageState();
}

class _MangaDetailsPageState extends State<MangaDetailsPage> {
  // AnilistData
  Media? anilistData;
  Rx<TrackedMedia?> currentManga = TrackedMedia().obs;
  final anilist = Get.find<AnilistAuth>();
  final fetcher = Get.find<ServiceHandler>();
  // Tracker for Avail Anime
  RxBool isListedManga = false.obs;

  // Offline Storage
  final offlineStorage = Get.find<OfflineStorageController>();

  // Extension Data
  RxString searchedTitle = ''.obs;
  RxList<Chapter>? chapterList = <Chapter>[].obs;

  // Page View Tracker
  RxInt selectedPage = 0.obs;

  // Current Manga
  RxDouble mangaScore = 0.0.obs;
  RxInt mangaProgress = 0.obs;
  RxString mangaStatus = "CURRENT".obs;

  // Tracker's Controller
  PageController controller = PageController();

  // List Editor Vars
  final selectedScore = 0.0.obs;
  final selectedStatus = "CURRENT";

  void _onPageSelected(int index) {
    selectedPage.value = index;
    controller.animateToPage(index,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  // Mangayomi Extensions
  final sourceController = Get.find<SourceController>();

  @override
  void initState() {
    super.initState();
    sourceController.initExtensions();
    Future.delayed(const Duration(milliseconds: 300), () {
      _checkMangaPresence();
    });
    _fetchAnilistData();
  }

  void _checkMangaPresence() {
    fetcher.onlineService
        .setCurrentMedia(widget.media.id.toString(), isManga: true);
    var data = fetcher.onlineService.currentMedia;

    if (data.value.id != null || data.value.id != '') {
      isListedManga.value = true;
      currentManga = data;
    } else {
      isListedManga.value = false;
      currentManga.value = null;
    }
    _initListVars();
  }

  void _initListVars() {
    log(currentManga.value?.episodeCount.toString() ?? 'null');
    mangaProgress.value = currentManga.value?.episodeCount?.toInt() ?? 0;
    mangaScore.value = currentManga.value?.score?.toDouble() ?? 0.0;
    mangaStatus.value = currentManga.value?.watchingStatus ?? "CURRENT";
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
      if (e.toString().contains("dynamic")) {
        _fetchAnilistData();
      }
      log(e.toString());
      snackBar("Retrying!, $e", duration: 2000);
    }
  }

  Future<void> _mapToService() async {
    final mappedData =
        await mapMedia(formatTitles(anilistData!) ?? [], searchedTitle);
    await _fetchSourceDetails(mappedData);
  }

  void _processExtensionData(Media tempData) async {
    final chapters = tempData.mediaContent!.reversed.toList();
    final convertedEpisodes = _convertChapters(chapters, tempData.title);

    chapterList?.value = convertedEpisodes;
    searchedTitle.value = tempData.title;
    setState(() {});
  }

  Future<void> _fetchSourceDetails(Media media) async {
    try {
      final episodeFuture = await getDetail(
        url: media.id,
        source: sourceController.activeMangaSource.value!,
      );

      final episodes = _convertChapters(
        episodeFuture.chapters!.reversed.toList(),
        episodeFuture.name ?? '',
      );
      chapterList?.value = episodes;
      searchedTitle.value = media.title;

      setState(() {});
    } catch (e) {
      if (e.toString().contains("dynamic")) {
        _fetchSourceDetails(media);
      }
      snackBar("Retrying!, $e", duration: 2000);
    }
  }

  List<String> formatTitles(Media media) {
    return ['${media.title}*MANGA', media.romajiTitle];
  }

  List<Chapter> _convertChapters(List<MChapter> chapters, String title) {
    return mChapterToChapter(chapters, title);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformBuilder(
      androidBuilder: _buildAndroidLayout(context),
      desktopBuilder: _buildDesktopLayout(context),
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
                          ServicesType.extensions) ...[
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
                            width: MediaQuery.of(context).size.width,
                            height: 50,
                            borderRadius: BorderRadius.circular(20),
                            variant: ButtonVariant.outline,
                            borderColor:
                                Theme.of(context).colorScheme.surfaceContainer,
                            child: Text(
                                convertAniListStatus(
                                    currentManga.value?.watchingStatus,
                                    isManga: true),
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontFamily: "Poppins-Bold")),
                          ),
                        ),
                        const SizedBox(width: 7),
                      ],
                      AnymeXButton(
                          onTap: () {
                            showCustomListDialog(context, anilistData!,
                                offlineStorage.mangaCustomLists, true);
                          },
                          height: 50,
                          borderRadius:
                              BorderRadius.circular(10.multiplyRadius()),
                          variant: ButtonVariant.outline,
                          borderColor:
                              Theme.of(context).colorScheme.surfaceContainer,
                          child: const Icon(HugeIcons.strokeRoundedLibrary))
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
                            const AnymexTextSpan(text: "Read "),
                            AnymexTextSpan(
                                text: currentManga.value?.episodeCount ?? '?',
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
                          onPressed: () {}, icon: const Icon(Iconsax.heart)),
                      IconButton(
                          onPressed: () {}, icon: const Icon(Icons.share)),
                    ],
                  ),
                ],
              ),
            )
          ] else ...[
            const SizedBox(
              height: 400,
              child: Center(child: CircularProgressIndicator()),
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
              _buildChapterSection(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChapterSection(BuildContext context) {
    return ChapterSection(
      searchedTitle: searchedTitle,
      anilistData: anilistData ?? widget.media,
      chapterList: chapterList!,
      sourceController: sourceController,
      mapToAnilist: _mapToService,
      getDetailsFromSource: _fetchSourceDetails,
      showWrongTitleModal: showWrongTitleModal,
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
              MangaStats(data: anilistData!),
              const SizedBox(height: 20),
            ],
          ),
        ),
        CharactersCarousel(
            characters: anilistData!.characters ?? [], isManga: true),
        ReusableCarousel(
          data: anilistData!.recommendations,
          title: "Recommended Manga",
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

  Glow _buildAndroidLayout(BuildContext context) {
    return Glow(
      child: Scaffold(
          extendBody: true,
          bottomNavigationBar: _buildMobiledNav(),
          body: _commonSaikouLayout(context)),
    );
  }

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
                        onTap: (index) => _onPageSelected(index),
                        selectedIcon: Iconsax.info_circle5,
                        unselectedIcon: Iconsax.info_circle,
                        label: "Info"),
                    NavItem(
                        onTap: (index) => _onPageSelected(index),
                        selectedIcon: Iconsax.book,
                        unselectedIcon: Iconsax.book,
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
                  selectedIcon: Iconsax.book,
                  unselectedIcon: Iconsax.book,
                  label: "Watch"),
            ]));
  }
  // Mobile Navigation bar: END

  // List Editor Modal: START
  void showListEditorModal(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return ListEditorModal(
          animeStatus: mangaStatus,
          animeScore: mangaScore,
          animeProgress: mangaProgress,
          currentAnime: currentManga,
          media: anilistData ?? widget.media,
          onUpdate: (id, score, status, progress) async {
            await fetcher.onlineService.updateListEntry(
                listId: id,
                isAnime: false,
                score: score,
                status: status,
                progress: progress);
            setState(() {});
          },
          onDelete: (s) async {
            final id = fetcher.onlineService.currentMedia.value.mediaListId;
            await fetcher.onlineService.deleteListEntry(id!, isAnime: false);
            setState(() {});
          },
        );
      },
    );
  }
  // List Editor Modal: END
}
