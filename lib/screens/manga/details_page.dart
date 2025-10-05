// ignore_for_file: invalid_use_of_protected_member, unused_element
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/logger.dart';

import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/source/source_mapper.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
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
  late ServicesType mediaService;
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
  RxString mangaStatus = "".obs;

  // Tracker's Controller
  PageController controller = PageController();

  void _onPageSelected(int index) {
    selectedPage.value = index;
    controller.animateToPage(index,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  final sourceController = Get.find<SourceController>();

  String posterColor = '';

  @override
  void initState() {
    super.initState();
    mediaService = widget.media.serviceType;
    Future.delayed(const Duration(milliseconds: 300), () {
      _checkMangaPresence();
    });
    _fetchAnilistData();
  }

  void _checkMangaPresence() {
    if (serviceHandler.serviceType.value == ServicesType.extensions) return;
    mediaService.onlineService
        .setCurrentMedia(widget.media.id.toString(), isManga: true);
    var data = mediaService.onlineService.currentMedia;

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
    Logger.i('[_initListVars] ${currentManga.value?.episodeCount}');
    mangaProgress.value = currentManga.value?.episodeCount?.toInt() ?? 0;
    mangaScore.value = currentManga.value?.score?.toDouble() ?? 0.0;
    mangaStatus.value = currentManga.value?.watchingStatus ?? "";
  }

  Future<void> _fetchAnilistData() async {
    try {
      final tempData = await mediaService.service
          .fetchDetails(FetchDetailsParams(id: widget.media.id.toString()));
      final isExtensions = mediaService == ServicesType.extensions;

      setState(() {
        if (isExtensions) {
          anilistData = tempData
            ..id = widget.media.id
            ..title = widget.media.title
            ..poster = widget.media.poster;
        } else {
          anilistData = tempData;
          posterColor = tempData.color;
        }
      });

      if (isExtensions) {
        Logger.i("Data Loaded for media => ${widget.media.title}");
        _processExtensionData(tempData);
      } else {
        await _mapToService();
      }
    } catch (e, stackTrace) {
      if (e.toString().contains("dynamic")) {
        _fetchAnilistData();
      }
      Logger.i(e.toString());
      Logger.i(stackTrace.toString());
    }
  }

  Future<void> _mapToService() async {
    final key =
        '${sourceController.activeMangaSource.value?.id}-${anilistData?.id}-${mediaService.index}';
    final savedTitle =
        settingsController.preferences.get(key, defaultValue: null);
    final mappedData = await mapMedia(formatTitles(anilistData!), searchedTitle,
        savedTitle: savedTitle);
    if (mappedData != null) {
      await _fetchSourceDetails(mappedData);
    }
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
      final episodeFuture = await sourceController
          .activeMangaSource.value!.methods
          .getDetail(DMedia.withUrl(media.id));

      final episodes = _convertChapters(
        episodeFuture.episodes!.reversed.toList(),
        episodeFuture.title ?? '',
      );
      chapterList?.value = episodes;
      searchedTitle.value = media.title;

      setState(() {});
    } catch (e) {
      if (e.toString().contains("dynamic")) {
        _fetchSourceDetails(media);
      }
      Logger.i(e.toString());
    }
  }

  List<String> formatTitles(Media media) {
    return ['${media.title}*MANGA', media.romajiTitle];
  }

  List<Chapter> _convertChapters(List<DEpisode> chapters, String title) {
    return DEpisodeToChapter(chapters, title);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformBuilder(
      strictMode: true,
      androidBuilder: _buildAndroidLayout(context),
      desktopBuilder: _buildDesktopLayout(context),
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
                  Obx(() {
                    return Row(
                      children: [
                        if (widget.media.serviceType !=
                                ServicesType.extensions &&
                            widget.media.serviceType.onlineService.isLoggedIn
                                .value) ...[
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.2),
                                ),
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer
                                    .withOpacity(0.5),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if (widget.media.serviceType.onlineService
                                        .isLoggedIn.value) {
                                      showListEditorModal(context);
                                    } else {
                                      snackBar("You aren't logged in Genius.",
                                          duration: 1000);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnymexText(
                                        text: convertAniListStatus(
                                            mangaStatus.value,
                                            isManga: true),
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
                          Container(
                            height: 50,
                            width: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.2),
                              ),
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer
                                  .withOpacity(0.5),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                  onTap: () {
                                    showCustomListDialog(
                                        context,
                                        anilistData!,
                                        offlineStorage.mangaCustomLists.value,
                                        ItemType.manga);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: const Icon(
                                      HugeIcons.strokeRoundedLibrary)),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: AnymexButton2(
                              onTap: () {
                                showCustomListDialog(
                                    context,
                                    anilistData!,
                                    offlineStorage.animeCustomLists.value,
                                    ItemType.anime);
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

  Widget _buildProgressContainer(BuildContext context) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
        ),
        child: Row(
          children: [
            Icon(
              Iconsax.book_1,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnymexTextSpans(
                fontSize: 14,
                spans: [
                  AnymexTextSpan(
                    text: "Chapter ",
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                  AnymexTextSpan(
                    text: mangaProgress.value.toString(),
                    variant: TextVariant.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  AnymexTextSpan(
                    text: ' of ',
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                  AnymexTextSpan(
                    text: anilistData?.totalChapters.toString() ??
                        anilistData?.totalChapters.toString() ??
                        '??',
                    variant: TextVariant.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              child: Text(
                '${formatProgress(currentChapter: mangaProgress.value, totalChapters: anilistData?.totalChapters ?? 1, altLength: chapterList?.length ?? 1)}%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
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
          data: anilistData!.relations ?? [],
          title: "Relations",
          variant: DataVariant.relation,
        ),
        ReusableCarousel(
          data: anilistData!.recommendations,
          title: "Recommended Manga",
          variant: DataVariant.recommendation,
          type: ItemType.manga,
        ),
      ],
    );
  }
  // Common Info Section

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
                  borderRadius: BorderRadius.circular(20),
                  items: [
                    NavItem(
                        onTap: (index) => _onPageSelected(index),
                        selectedIcon: Iconsax.info_circle5,
                        unselectedIcon: Iconsax.info_circle,
                        label: "Info"),
                    if (sourceController.shouldShowExtensions.value)
                      NavItem(
                          onTap: (index) => _onPageSelected(index),
                          selectedIcon: Iconsax.book,
                          unselectedIcon: Iconsax.book,
                          label: "Read"),
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
          isManga: true,
          media: anilistData ?? widget.media,
          onUpdate: (id, score, status, progress) async {
            await mediaService.onlineService.updateListEntry(
                UpdateListEntryParams(
                    listId: id,
                    isAnime: false,
                    score: score,
                    status: status,
                    progress: progress));
            setState(() {});
          },
          onDelete: (s) async {
            final id =
                mediaService.onlineService.currentMedia.value.mediaListId;
            await mediaService.onlineService
                .deleteListEntry(id!, isAnime: false);
            setState(() {});
          },
        );
      },
    );
  }
  // List Editor Modal: END
}
