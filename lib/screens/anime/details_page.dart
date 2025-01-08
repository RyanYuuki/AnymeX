// ignore_for_file: invalid_use_of_protected_member
import 'dart:developer';
import 'dart:io';
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_manga.dart';
import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:anymex/api/Mangayomi/Search/get_detail.dart';
import 'package:anymex/api/Mangayomi/Search/search.dart';
import 'package:anymex/controllers/anilist/anilist_auth.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/anilist/anilist_data.dart';
import 'package:anymex/models/Anilist/anilist_media_full.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/screens/anime/widgets/anime_stats.dart';
import 'package:anymex/screens/anime/widgets/episode_list_builder.dart';
import 'package:anymex/screens/anime/widgets/voice_actor.dart';
import 'package:anymex/screens/anime/widgets/wrongtitle_modal.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anime/gradient_image.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/common/no_source.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/minor_widgets/custom_button.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:anymex/widgets/minor_widgets/custom_textspan.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class AnimeDetailsPage extends StatefulWidget {
  final String anilistId;
  final String posterUrl;
  final String tag;
  const AnimeDetailsPage(
      {super.key,
      required this.anilistId,
      required this.posterUrl,
      required this.tag});

  @override
  State<AnimeDetailsPage> createState() => _AnimeDetailsPageState();
}

class _AnimeDetailsPageState extends State<AnimeDetailsPage> {
  // AnilistData
  AnilistMediaData? anilistData;
  Rx<AnilistMediaUser?> currentAnime = AnilistMediaUser().obs;
  final anilist = Get.find<AnilistAuth>();
  // Tracker for Avail Anime
  RxBool isListedAnime = false.obs;

  // Extension Data
  Rx<MManga?> fetchedData = MManga().obs;
  RxList<Episode>? episodeList = <Episode>[].obs;

  // Page View Tracker
  RxInt selectedPage = 0.obs;
  RxInt desktopSelectedPage = 1.obs;

  // Tracker's Controller
  PageController controller = PageController();

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

  // Mangayomi Extensions
  final sourceController = Get.find<SourceController>();

  @override
  void initState() {
    super.initState();
    sourceController.initExtensions();
    _checkAnimePresence();
    _fetchAnilistData();
  }

  void _checkAnimePresence() {
    anilist.setCurrentAnime(widget.anilistId);
    var data = anilist.currentAnime;

    if (data.value.id != null || data.value.id != '') {
      isListedAnime.value = true;
      currentAnime = data;
    } else {
      isListedAnime.value = false;
      currentAnime.value = null;
    }
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
      final finalSource = source ?? sourceController.activeSource.value;

      var searchData = await search(
        source: finalSource!,
        query: anilistData!.name,
        page: 1,
        filterList: [],
      );
      if (searchData!.list.isEmpty) {
        searchData = await search(
          source: finalSource,
          query: anilistData?.name.split(' ').first ??
              anilistData!.jname.split(' ').first,
          page: 1,
          filterList: [],
        );
      }

      if (searchData?.list.isEmpty ?? true) {
        throw Exception("No anime found for the provided query.");
      }

      final animeList = searchData!.list;
      final matchedAnime = animeList.firstWhere(
        (an) => an.name == anilistData?.jname || an.name == anilistData?.name,
        orElse: () => animeList[0],
      );
      await getDetailsFromSource(matchedAnime.link!);
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> getDetailsFromSource(String url) async {
    final episodeFuture = await getDetail(
      url: url,
      source: sourceController.activeSource.value!,
    );

    final episodeData = episodeFuture.chapters!.reversed.toList();
    final firstEpisodeNum =
        ChapterRecognition.parseChapterNumber("", episodeData.first.name ?? '');
    final renewepisodeData = episodeData.map((ep) {
      if (firstEpisodeNum > 3) {
        final index = episodeData.indexOf(ep) + 1;
        ep.name = "Episode $index";
        return mChapterToEpisode(ep, episodeFuture);
      } else {
        return mChapterToEpisode(ep, episodeFuture);
      }
    }).toList();

    fetchedData.value = episodeFuture;
    episodeList!.value = renewepisodeData;
    episodeList?.value = await AnilistData.fetchEpisodesFromAnify(
        widget.anilistId, episodeList!.value);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformBuilder(
      androidBuilder: _buildAndroidLayout(context),
      desktopBuilder: _buildDesktopLayout(context),
      strictMode: true,
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
            posterUrl: widget.posterUrl,
          ),
          if (anilistData != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 10, 20, 0),
              child: Column(
                children: [
                  AnymeXButton(
                    onTap: () {},
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                    borderRadius: BorderRadius.circular(20),
                    variant: ButtonVariant.outline,
                    borderColor: Theme.of(context).colorScheme.surfaceContainer,
                    child: Text(
                        convertAniListStatus(
                            currentAnime.value?.watchingStatus),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontFamily: "Poppins-Bold")),
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
                          onPressed: () {}, icon: const Icon(Iconsax.heart)),
                      IconButton(
                          onPressed: () {}, icon: const Icon(Icons.share)),
                    ],
                  ),
                ],
              ),
            ),
            if (isMobile)
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
              )
            else
              ExpandablePageView(
                physics: const BouncingScrollPhysics(),
                controller: controller,
                onPageChanged: (index) {
                  desktopSelectedPage.value = index + 1;
                },
                children: [
                  _buildCommonInfo(context),
                  _buildEpisodeSection(context),
                ],
              ),
          ],
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
                  AnymexText(
                    text: " Found: ${fetchedData.value?.name ?? '??'}",
                    variant: TextVariant.semiBold,
                    size: 16,
                  ),
                  GestureDetector(
                    onTap: () {
                      showWrongTitleModal(context, anilistData?.name ?? '',
                          (manga) async {
                        episodeList?.value = [];
                        await getDetailsFromSource(manga.link!);
                      });
                    },
                    child: AnymexText(
                      text: "Wrong Title?",
                      variant: TextVariant.semiBold,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Obx(() => DropdownButtonFormField<String>(
                    value: sourceController.installedExtensions.isEmpty
                        ? "No Sources Installed"
                        : '${sourceController.activeSource.value?.name} (${sourceController.activeSource.value?.lang?.toUpperCase()})',
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
                      if (sourceController.installedExtensions.value.isEmpty)
                        const DropdownMenuItem<String>(
                          value: "No Sources Installed",
                          child: Text(
                            "No Sources Installed",
                            style: TextStyle(fontFamily: 'Poppins-SemiBold'),
                          ),
                        ),
                      ...sourceController.installedExtensions.value
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
                      episodeList?.value = [];
                      try {
                        final selectedSource =
                            sourceController.getExtensionByName(value!);
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
                    text: "Episodes",
                    variant: TextVariant.bold,
                    size: 18,
                  ),
                ],
              ),
              if (sourceController.activeSource.value == null)
                const NoSourceSelectedWidget()
              else
                Obx(() {
                  if (episodeList!.value.isEmpty || episodeList == null) {
                    return const SizedBox(
                        height: 500,
                        child: Center(child: CircularProgressIndicator()));
                  }

                  return PlatformBuilder(
                    androidBuilder: EpisodeListBuilder(
                      episodeList: episodeList!.value,
                      anilistData: anilistData,
                      isDesktop: false,
                    ),
                    desktopBuilder: EpisodeListBuilder(
                      episodeList: episodeList!.value,
                      anilistData: anilistData,
                      isDesktop: true,
                    ),
                  );
                })
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
              AnimeStats(data: anilistData!),
              const SizedBox(height: 20),
            ],
          ),
        ),
        CharactersCarousel(characters: anilistData!.characters),
        ReusableCarousel(
          data: anilistData!.recommendations,
          title: "Recommended Animes",
          variant: DataVariant.recommendation,
        ),
        ReusableCarousel(
          data: anilistData!.relations,
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
            margin: const EdgeInsets.symmetric(horizontal: 80, vertical: 30),
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
}
// Mobile Navigation bar: END
