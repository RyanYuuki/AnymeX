// ignore_for_file: invalid_use_of_protected_member
import 'dart:developer';
import 'dart:io';
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_manga.dart';
import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:anymex/api/Mangayomi/Search/get_detail.dart';
import 'package:anymex/api/Mangayomi/Search/search.dart';
import 'package:anymex/api/Mangayomi/extension_preferences_providers.dart';
import 'package:anymex/api/Mangayomi/get_source_preference.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/models/Offline/Hive/offline_storage.dart';
import 'package:anymex/screens/anime/widgets/anime_stats.dart';
import 'package:anymex/screens/anime/widgets/custom_list_dialog.dart';
import 'package:anymex/screens/anime/widgets/episode_list_builder.dart';
import 'package:anymex/screens/anime/widgets/voice_actor.dart';
import 'package:anymex/screens/anime/widgets/wrongtitle_modal.dart';
import 'package:anymex/screens/extemsions/ExtensionSettings/ExtensionSettings.dart';
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
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
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
  Media? anilistData;
  Rx<AnilistMediaUser?> currentAnime = AnilistMediaUser().obs;
  final anilist = Get.find<AnilistAuth>();
  // Tracker for Avail Anime
  RxBool isListedAnime = false.obs;

  // Offline Storage
  final offlineStorage = Get.find<OfflineStorageController>();

  // Extension Data
  Rx<MManga?> fetchedData = MManga().obs;
  RxList<Episode>? episodeList = <Episode>[].obs;

  // Current Anime
  RxDouble animeScore = 0.0.obs;
  Rx<int> animeProgress = 0.obs;
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
    Future.delayed(const Duration(milliseconds: 300), () {
      _checkAnimePresence();
    });
    _fetchAnilistData();
  }

  void _initListVars() {
    animeProgress.value = currentAnime.value?.episodeCount?.toInt() ?? 0;
    animeScore.value = currentAnime.value?.score?.toDouble() ?? 0.0;
    animeStatus.value = currentAnime.value?.watchingStatus ?? "CURRENT";
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
    _initListVars();
  }

  Future<void> _fetchAnilistData() async {
    final tempData = await AnilistData.fetchAnimeInfo(widget.anilistId);
    setState(() {
      anilistData = tempData;
    });
    mapToAnilist();
  }

  Future<void> mapToAnilist({bool isFirstTime = true, Source? source}) async {
    episodeError.value = false;
    try {
      final finalSource = source ?? sourceController.activeSource.value;

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

      final animeList = searchData!.list;
      final matchedAnime = animeList.firstWhere(
        (an) =>
            an.name == anilistData?.romajiTitle ||
            an.name == anilistData?.title,
        orElse: () => animeList[0],
      );
      await getDetailsFromSource(matchedAnime.link!);
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> getDetailsFromSource(String url) async {
    episodeError.value = false;
    try {
      final episodeFuture = await getDetail(
        url: url,
        source: sourceController.activeSource.value!,
      );

      final episodeData = episodeFuture.chapters!.reversed.toList();
      final convertedEpisodeData = episodeData.map((ep) {
        return mChapterToEpisode(ep, episodeFuture);
      }).toList();

      final renewepisodeData = convertedEpisodeData.first.number.toInt() > 3
          ? convertedEpisodeData.asMap().entries.map((entry) {
              final index = entry.key + 1;
              entry.value.number = index.toString();
              return entry.value;
            }).toList()
          : convertedEpisodeData;

      fetchedData.value = episodeFuture;
      episodeList!.value = renewepisodeData;
      final temp = await AnilistData.fetchEpisodesFromAnify(
          widget.anilistId, episodeList!.value);
      episodeList?.value = temp;
      setState(() {});
    } catch (e) {
      episodeError.value = true;
      snackBar("Ooops! Look like we ran into an Error, Try again please",
          duration: 2000);
    }
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
                  Row(
                    children: [
                      Expanded(
                        child: AnymeXButton(
                          onTap: () {
                            if (anilist.isLoggedIn.value) {
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
                                  color: Theme.of(context).colorScheme.primary,
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
                          borderRadius: BorderRadius.circular(12.multiplyRadius()),
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
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: AnymexText(
                      text: " Found: ${fetchedData.value?.name ?? '??'}",
                      variant: TextVariant.semiBold,
                      size: 16,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showWrongTitleModal(context, anilistData?.title ?? '',
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
              Obx(() => Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
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
                            fillColor: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            labelStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface),
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
                                .installedExtensions.value.isEmpty)
                              const DropdownMenuItem<String>(
                                value: "No Sources Installed",
                                child: Text(
                                  "No Sources Installed",
                                  style:
                                      TextStyle(fontFamily: 'Poppins-SemiBold'),
                                ),
                              ),
                            ...sourceController.installedExtensions.value
                                .map<DropdownMenuItem<String>>((source) {
                              return DropdownMenuItem<String>(
                                value:
                                    '${source.name} (${source.lang?.toUpperCase()})',
                                child: Text(
                                  '${source.name?.toUpperCase()} (${source.lang?.toUpperCase()})',
                                  style: const TextStyle(
                                      fontFamily: 'Poppins-SemiBold'),
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
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer),
                        child: IconButton(
                          onPressed: () async {
                            var sourcePreference = getSourcePreference(
                                    source:
                                        sourceController.activeSource.value!)
                                .map((e) => getSourcePreferenceEntry(e.key!,
                                    sourceController.activeSource.value!.id!))
                                .toList();
                            Get.to(
                              () => SourcePreferenceWidget(
                                source: sourceController.activeSource.value!,
                                sourcePreference: sourcePreference,
                              ),
                            );
                          },
                          icon: const Icon(Iconsax.setting),
                        ),
                      )
                    ],
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
                  if (episodeError.value) {
                    return const SizedBox(
                      height: 300,
                      child: Center(
                        child: AnymexText(
                          text:
                              "Looks like even the episodes are avoiding your taste in shows\n:(",
                          size: 20,
                          textAlign: TextAlign.center,
                          variant: TextVariant.semiBold,
                        ),
                      ),
                    );
                  }

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
                            value: animeStatus.value,
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
                                animeStatus.value = newStatus!;
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
                                    '${animeProgress.value}/${currentAnime.value?.totalEpisodes ?? '??'}',
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
                              initialValue: animeProgress.value.toString(),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (String value) {
                                int? newProgress = int.tryParse(value);
                                if (newProgress != null && newProgress >= 0) {
                                  if (currentAnime.value!.totalEpisodes ==
                                      '?') {
                                    animeProgress.value = newProgress;
                                  } else {
                                    int totalEp = int.parse(
                                        currentAnime.value!.totalEpisodes!);
                                    animeProgress.value = newProgress <= totalEp
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
                                'Score: ${animeScore.value.toStringAsFixed(1)}/10',
                                style: const TextStyle(
                                  fontFamily: 'Poppins-Bold',
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          CustomSlider(
                            value: animeScore.value,
                            min: 0.0,
                            max: 10.0,
                            divisions: 100,
                            label: animeScore.value.toStringAsFixed(1),
                            activeColor: Theme.of(context).colorScheme.primary,
                            inactiveColor: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            onChanged: (double newValue) {
                              setState(() {
                                animeScore.value = newValue;
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
                                  score: animeScore.value,
                                  status: animeStatus.value,
                                  isAnime: true,
                                  progress: animeProgress.value);
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
// Mobile Navigation bar: END
