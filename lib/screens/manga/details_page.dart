// ignore_for_file: invalid_use_of_protected_member
import 'dart:developer';
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_manga.dart';
import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:anymex/api/Mangayomi/Search/get_detail.dart';
import 'package:anymex/api/Mangayomi/Search/search.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/screens/anime/widgets/custom_list_dialog.dart';
import 'package:anymex/screens/anime/widgets/voice_actor.dart';
import 'package:anymex/screens/anime/widgets/wrongtitle_modal.dart';
import 'package:anymex/screens/manga/widgets/chapter_list_builder.dart';
import 'package:anymex/screens/manga/widgets/manga_stats.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/anime/gradient_image.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/common/no_source.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/minor_widgets/custom_button.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:anymex/widgets/minor_widgets/custom_textspan.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';

class MangaDetailsPage extends StatefulWidget {
  final String anilistId;
  final String posterUrl;
  final String tag;
  const MangaDetailsPage(
      {super.key,
      required this.anilistId,
      required this.posterUrl,
      required this.tag});

  @override
  State<MangaDetailsPage> createState() => _MangaDetailsPageState();
}

class _MangaDetailsPageState extends State<MangaDetailsPage> {
  // AnilistData
  Media? anilistData;
  Rx<AnilistMediaUser?> currentManga = AnilistMediaUser().obs;
  final anilist = Get.find<AnilistAuth>();
  // Tracker for Avail Anime
  RxBool isListedManga = false.obs;

  // Offline Storage
  final offlineStorage = Get.find<OfflineStorageController>();

  // Extension Data
  Rx<MManga?> fetchedData = MManga().obs;
  RxList<Chapter>? chapterList = <Chapter>[].obs;

  // Page View Tracker
  RxInt selectedPage = 0.obs;

  // Current Manga
  RxDouble mangaScore = 0.0.obs;
  Rx<int> mangaProgress = 0.obs;
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
    _checkMangaPresence();
    _fetchAnilistData();
  }

  void _checkMangaPresence() {
    anilist.setCurrentManga(widget.anilistId);
    var data = anilist.currentManga;

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
    mangaProgress.value = currentManga.value?.episodeCount?.toInt() ?? 0;
    mangaScore.value = currentManga.value?.score?.toDouble() ?? 0.0;
    mangaStatus.value = currentManga.value?.watchingStatus ?? "CURRENT";
  }

  Future<void> _fetchAnilistData() async {
    final tempData = await AnilistData.fetchAnimeInfo(widget.anilistId);
    setState(() {
      anilistData = tempData;
    });
    mapToAnilist();
  }

  Future<void> mapToAnilist({bool isFirstTime = true, Source? source}) async {
    try {
      final finalSource = source ?? sourceController.activeMangaSource.value;

      var searchData = await search(
        source: finalSource!,
        query: anilistData!.title,
        page: 1,
        filterList: [],
      );
      if (searchData!.list.isEmpty) {
        searchData = await search(
          source: finalSource,
          query: anilistData?.title.split(' ').first ??
              anilistData!.romajiTitle.split(' ').first,
          page: 1,
          filterList: [],
        );
      }

      if (searchData?.list.isEmpty ?? true) {
        throw Exception("No anime found for the provided query.");
      }

      final mangaList = searchData!.list;
      final matchedManga = mangaList.firstWhere(
        (an) =>
            an.name == anilistData?.romajiTitle ||
            an.name == anilistData?.title,
        orElse: () => mangaList[0],
      );
      await getDetailsFromSource(matchedManga.link!);
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> getDetailsFromSource(String url) async {
    final chapterEpisode = await getDetail(
      url: url,
      source: sourceController.activeMangaSource.value!,
    );

    final episodeData = mChapterToChapter(
        chapterEpisode.chapters!.reversed.toList(),
        anilistData?.title ?? anilistData?.romajiTitle ?? '');
    fetchedData.value = chapterEpisode;
    chapterList!.value = episodeData;
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
            posterUrl: widget.posterUrl,
          ),
          if (anilistData != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 10, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AnymeXButton(
                          onTap: () {
                            showListEditorModal(context);
                          },
                          width: MediaQuery.of(context).size.width,
                          height: 50,
                          borderRadius: BorderRadius.circular(20),
                          variant: ButtonVariant.outline,
                          borderColor:
                              Theme.of(context).colorScheme.surfaceContainer,
                          child: Text(
                              convertAniListStatus(
                                  currentManga.value?.watchingStatus),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontFamily: "Poppins-Bold")),
                        ),
                      ),
                      const SizedBox(width: 7),
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
            ),
            ExpandablePageView(
              physics: const BouncingScrollPhysics(),
              controller: controller,
              onPageChanged: (index) {
                selectedPage.value = index;
              },
              children: [
                _buildCommonInfo(context),
                _buildEpisodeSection(context),
              ],
            ),
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
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 2),
                    width: Get.width * 0.6,
                    child: AnymexTextSpans(
                      spans: [
                        const AnymexTextSpan(
                          text: "Found: ",
                          variant: TextVariant.semiBold,
                          size: 16,
                        ),
                        AnymexTextSpan(
                          text: fetchedData.value?.name ?? '??',
                          variant: TextVariant.semiBold,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showWrongTitleModal(context, anilistData?.title ?? '',
                          (manga) async {
                        chapterList?.value = [];
                        await getDetailsFromSource(manga.link!);
                      }, isManga: true);
                    },
                    child: AnymexText(
                      text: "Wrong Title?",
                      variant: TextVariant.semiBold,
                      size: 16,
                      maxLines: 1,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Obx(() => DropdownButtonFormField<String>(
                    value: sourceController.installedMangaExtensions.isEmpty
                        ? "No Sources Installed"
                        : '${sourceController.activeMangaSource.value?.name} (${sourceController.activeMangaSource.value?.lang?.toUpperCase()})',
                    decoration: InputDecoration(
                      label: TextButton.icon(
                        onPressed: () {},
                        label: const AnymexText(
                          text: "Select Source",
                          variant: TextVariant.bold,
                        ),
                        icon: const Icon(Iconsax.folder5),
                      ),
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.inverseSurface),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryFixedVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    isExpanded: true,
                    items: [
                      if (sourceController
                          .installedMangaExtensions.value.isEmpty)
                        const DropdownMenuItem<String>(
                          value: "No Sources Installed",
                          child: Text(
                            "No Sources Installed",
                            style: TextStyle(fontFamily: 'Poppins-SemiBold'),
                          ),
                        ),
                      ...sourceController.installedMangaExtensions.value
                          .map<DropdownMenuItem<String>>((source) {
                        return DropdownMenuItem<String>(
                          value:
                              '${source.name} (${source.lang?.toUpperCase()})',
                          child: Text(
                            '${source.name?.toUpperCase()} (${source.lang?.toUpperCase()})',
                            style:
                                const TextStyle(fontFamily: 'Poppins-SemiBold'),
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) async {
                      chapterList?.value = [];
                      try {
                        final selectedSource =
                            sourceController.getMangaExtensionByName(value!);
                        await mapToAnilist(source: selectedSource);
                      } catch (e) {
                        log(e.toString());
                      }
                    },
                    dropdownColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    icon: Icon(Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.primary),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  )),
              const SizedBox(height: 20),
              const Row(
                children: [
                  AnymexText(
                    text: "Chapters",
                    variant: TextVariant.bold,
                    size: 18,
                  ),
                ],
              ),
              if (sourceController.activeMangaSource.value == null)
                const NoSourceSelectedWidget()
              else
                ChapterListBuilder(
                    chapters: chapterList?.value ?? [],
                    anilistData: anilistData!)
            ],
          ),
        ));
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
          height: 250,
          child: ResponsiveNavBar(
              isDesktop: true,
              currentIndex: selectedPage.value + 1,
              items: [
                NavItem(
                    onTap: (index) {
                      Get.back();
                    },
                    selectedIcon: Iconsax.back_square,
                    unselectedIcon: Iconsax.back_square,
                    label: "Back"),
                NavItem(
                    onTap: (index) => _onPageSelected(index - 1),
                    selectedIcon: Iconsax.info_circle5,
                    unselectedIcon: Iconsax.info_circle,
                    label: "Info"),
                NavItem(
                    onTap: (index) => _onPageSelected(index - 1),
                    selectedIcon: Iconsax.book,
                    unselectedIcon: Iconsax.book,
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
            margin: const EdgeInsets.symmetric(horizontal: 80, vertical: 30),
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
        return Obx(
          () {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 30.0,
                  right: 30.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 80.0,
                  top: 20.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'List Editor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 55,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,
                          prefixIcon: const Icon(Icons.playlist_add),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 1,
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 1,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          labelText: 'Status',
                          labelStyle: const TextStyle(
                            fontFamily: 'Poppins-Bold',
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: mangaStatus.value,
                            items: [
                              'PLANNING',
                              'CURRENT',
                              'COMPLETED',
                              'REPEATING',
                              'PAUSED',
                              'DROPPED',
                            ].map((String status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (String? newStatus) {
                              setState(() {
                                mangaStatus.value = newStatus!;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 55,
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.add),
                                suffixText:
                                    '${mangaProgress.value}/${currentManga.value?.totalEpisodes}',
                                filled: true,
                                fillColor: Colors.transparent,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    width: 1,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    width: 1,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                labelText: 'Progress',
                                labelStyle: const TextStyle(
                                  fontFamily: 'Poppins-Bold',
                                ),
                              ),
                              initialValue: mangaProgress.value.toString(),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (String value) {
                                int? newProgress = int.tryParse(value);
                                if (newProgress != null && newProgress >= 0) {
                                  if (currentManga.value!.totalEpisodes ==
                                      '?') {
                                    mangaProgress.value = newProgress;
                                  } else {
                                    int totalEp = int.parse(
                                        currentManga.value!.totalEpisodes!);
                                    mangaProgress.value = newProgress <= totalEp
                                        ? newProgress
                                        : totalEp;
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Score: ${mangaScore.value.toStringAsFixed(1)}/10',
                                style: const TextStyle(
                                  fontFamily: 'Poppins-Bold',
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          CustomSlider(
                            value: mangaScore.value,
                            min: 0.0,
                            max: 10.0,
                            divisions: 100,
                            label: mangaScore.value.toStringAsFixed(1),
                            activeColor: Theme.of(context).colorScheme.primary,
                            inactiveColor: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            onChanged: (double newValue) {
                              setState(() {
                                mangaScore.value = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          height: 50,
                          width: 120,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              anilist.deleteMediaFromList(
                                widget.anilistId.toInt(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            child: const Text('Delete'),
                          ),
                        ),
                        SizedBox(
                          height: 50,
                          width: 120,
                          child: ElevatedButton(
                            onPressed: () {
                              Get.back();
                              anilist.updateListEntry(
                                  listId: widget.anilistId.toInt(),
                                  score: mangaScore.value,
                                  status: mangaStatus.value,
                                  isAnime: false,
                                  progress: mangaProgress.value);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  // List Editor Modal: END
}
