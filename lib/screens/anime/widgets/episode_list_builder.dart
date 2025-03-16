// ignore_for_file: invalid_use_of_protected_member, prefer_const_constructors, unnecessary_null_comparison
import 'dart:ui';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Offline/Hive/video.dart';
import 'package:anymex/core/Search/getVideo.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/screens/anime/watch_page.dart';
import 'package:anymex/screens/anime/widgets/episode_range.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class EpisodeListBuilder extends StatefulWidget {
  const EpisodeListBuilder({
    super.key,
    required this.episodeList,
    required this.anilistData,
  });

  final List<Episode> episodeList;
  final Media? anilistData;

  @override
  State<EpisodeListBuilder> createState() => _EpisodeListBuilderState();
}

class _EpisodeListBuilderState extends State<EpisodeListBuilder> {
  final selectedChunkIndex = 1.obs;
  final RxList<Video> streamList = <Video>[].obs;
  final sourceController = Get.find<SourceController>();
  final auth = Get.find<ServiceHandler>();
  final offlineStorage = Get.find<OfflineStorageController>();

  final RxBool isLogged = false.obs;
  final RxInt userProgress = 0.obs;
  final Rx<Episode> selectedEpisode = Episode(number: "1").obs;
  final Rx<Episode> continueEpisode = Episode(number: "1").obs;
  final Rx<Episode> savedEpisode = Episode(number: "1").obs;
  List<Episode> offlineEpisodes = [];

  @override
  void initState() {
    super.initState();
    _initEpisodes();
    Future.delayed(Duration(milliseconds: 300), () {
      _initUserProgress();
    });
    _initEpisodes();

    ever(auth.isLoggedIn, (_) => _initUserProgress());
    ever(userProgress, (_) => _initEpisodes());
    ever(auth.currentMedia, (_) => {_initUserProgress(), _initEpisodes()});

    offlineStorage.addListener(() {
      final savedData = offlineStorage.getAnimeById(widget.anilistData!.id);
      if (savedData?.currentEpisode != null) {
        savedEpisode.value = savedData!.currentEpisode!;
        offlineEpisodes = savedData.episodes ?? [];
        _initEpisodes();
      }
    });
  }

  void _initUserProgress() {
    final isExtensions = auth.serviceType.value == ServicesType.extensions;
    isLogged.value = isExtensions ? false : auth.isLoggedIn.value;
    final progress = isLogged.value
        ? auth.currentMedia.value.episodeCount?.toInt()
        : offlineStorage
            .getAnimeById(widget.anilistData!.id)
            ?.currentEpisode
            ?.number
            .toInt();

    userProgress.value = !isLogged.value && progress != null && progress > 1
        ? progress - 1
        : progress ?? 0;
  }

  void _initEpisodes() {
    final savedData = offlineStorage.getAnimeById(widget.anilistData!.id);
    final nextEpisode = widget.episodeList
        .firstWhereOrNull((e) => e.number.toInt() == (userProgress.value + 1));
    final fallbackEP = widget.episodeList
        .firstWhereOrNull((e) => e.number.toInt() == (userProgress.value));
    final saved = savedData?.currentEpisode;
    savedEpisode.value = saved ?? widget.episodeList[0];
    offlineEpisodes = savedData?.watchedEpisodes ?? widget.episodeList;
    selectedEpisode.value = nextEpisode ?? fallbackEP ?? savedEpisode.value;
    continueEpisode.value = nextEpisode ?? fallbackEP ?? savedEpisode.value;
  }

  void _handleEpisodeSelection(Episode episode) {
    selectedEpisode.value = episode;
    streamList.clear();
    fetchServers(episode.link!);
  }

  Widget _buildContinueButton() {
    return ContinueEpisodeButton(
      height: getResponsiveSize(context, mobileSize: 80, dektopSize: 100),
      onPressed: () => _handleEpisodeSelection(continueEpisode.value),
      backgroundImage: continueEpisode.value.thumbnail ??
          savedEpisode.value.thumbnail ??
          widget.anilistData!.cover ??
          widget.anilistData!.poster,
      episode: continueEpisode.value,
      progressEpisode: savedEpisode.value,
      data: widget.anilistData!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chunkedEpisodes = chunkEpisodes(
        widget.episodeList, calculateChunkSize(widget.episodeList));

    final isAnify = (widget.episodeList[0].thumbnail?.isNotEmpty ?? false).obs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Obx(_buildContinueButton),
        ),
        EpisodeChunkSelector(
          chunks: chunkedEpisodes,
          selectedChunkIndex: selectedChunkIndex,
          onChunkSelected: (index) => setState(() {}),
        ),
        Obx(() {
          final selectedEpisodes = chunkedEpisodes.isNotEmpty
              ? chunkedEpisodes[selectedChunkIndex.value]
              : [];

          return GridView.builder(
            padding: const EdgeInsets.only(top: 15),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: getResponsiveCrossAxisCount(
                context,
                baseColumns: 1,
                maxColumns: 3,
                mobileItemWidth: 400,
                tabletItemWidth: 400,
                desktopItemWidth: 200,
              ),
              mainAxisSpacing:
                  getResponsiveSize(context, mobileSize: 15, dektopSize: 10),
              crossAxisSpacing: 15,
              mainAxisExtent: isAnify.value
                  ? 200
                  : getResponsiveSize(context,
                      mobileSize: 100, dektopSize: 130),
            ),
            itemCount: selectedEpisodes.length,
            itemBuilder: (context, index) {
              final episode = selectedEpisodes[index] as Episode;
              return Obx(() {
                final currentEpisode =
                    episode.number.toInt() + 1 == userProgress.value;
                final completedEpisode =
                    episode.number.toInt() <= userProgress.value;
                final isSelected =
                    selectedEpisode.value.number == episode.number;

                return Opacity(
                  opacity: completedEpisode
                      ? 0.5
                      : currentEpisode
                          ? 0.8
                          : 1,
                  child: AnymexOnTap(
                    onTap: () => _handleEpisodeSelection(episode),
                    child: isAnify.value
                        ? _anifyEpisode(isSelected, context, episode)
                        : _normalEpisode(isSelected, context, episode),
                  ),
                );
              });
            },
          );
        }),
      ],
    );
  }

  Future<void> fetchServers(String url) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          child: FutureBuilder<List<Video>>(
            future: getVideo(
                source: sourceController.activeSource.value!, url: url),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              } else if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              } else {
                streamList.value = snapshot.data ?? [];
                return _buildServerList();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 200,
      child: Center(child: AnymexProgressIndicator()),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        10.height(),
        AnymexText(
          text: "Error Occured",
          variant: TextVariant.bold,
          size: 18,
        ),
        20.height(),
        AnymexText(
          text: "Server-chan is taking a nap!",
          variant: TextVariant.semiBold,
          size: 18,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnymexText(
            text: errorMessage,
            variant: TextVariant.regular,
            size: 14,
            textAlign: TextAlign.center,
            color: Colors.red.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const SizedBox(
      height: 200,
      child: Center(
        child: AnymexText(
          text: "No servers available",
          variant: TextVariant.bold,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildServerList() {
    return Container(
      padding: const EdgeInsets.all(10),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            alignment: Alignment.center,
            child: const AnymexText(
              text: "Choose Server",
              size: 18,
              variant: TextVariant.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...streamList.map((e) {
            return InkWell(
              onTap: () {
                Get.back();
                navigate(() => WatchPage(
                      episodeSrc: e,
                      episodeList: widget.episodeList,
                      anilistData: widget.anilistData!,
                      currentEpisode: selectedEpisode.value,
                      episodeTracks: streamList,
                    ));
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 3.0, horizontal: 10),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 2.5, horizontal: 10),
                  title: AnymexText(
                    text: e.quality.toUpperCase(),
                    variant: TextVariant.bold,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tileColor: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  trailing: const Icon(Iconsax.play5),
                  subtitle: AnymexText(
                    text: sourceController.activeSource.value!.name!
                        .toUpperCase(),
                    variant: TextVariant.semiBold,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _normalEpisode(
      bool isSelected, BuildContext context, Episode episode) {
    final savedEP =
        offlineEpisodes.firstWhereOrNull((e) => e.number == episode.number);
    final progress = savedEP?.timeStampInMilliseconds != null &&
            savedEP?.durationInMilliseconds != null &&
            savedEP!.durationInMilliseconds! > 0
        ? (savedEP.timeStampInMilliseconds! / savedEP.durationInMilliseconds!)
        : 0.0;
    final isFiller = episode.filler ?? false;

    return Container(
      clipBehavior: Clip.antiAlias,
      height: 100,
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.6)
            : isFiller
                ? Colors.orange
                : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, constrainst) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.multiplyRadius()),
                    child: NetworkSizedImage(
                      height: double.infinity,
                      width: constrainst.maxWidth,
                      imageUrl: episode.thumbnail ??
                          widget.anilistData?.cover ??
                          widget.anilistData?.poster ??
                          '',
                      radius: 0,
                      errorImage: widget.anilistData?.cover ??
                          widget.anilistData?.poster,
                    ),
                  ),
                  if (progress > 0.0 && progress <= 1.0) ...[
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius:
                              BorderRadius.circular(12.multiplyRadius()),
                        ),
                        height: 4,
                        width: constrainst.maxWidth * progress,
                      ),
                    ),
                    Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context).colorScheme.primary),
                            child: Icon(
                              Icons.remove_red_eye,
                              color: Theme.of(context).colorScheme.onPrimary,
                            )))
                  ],
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black.withOpacity(0.2),
                            border: Border.all(
                                width: 2,
                                color: Theme.of(context).colorScheme.primary),
                            boxShadow: [glowingShadow(context)],
                          ),
                          child: AnymexText(
                            text: "EP ${episode.number}",
                            variant: TextVariant.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnymexText(
              text: episode.title ?? '?',
              variant: TextVariant.bold,
            ),
          ),
        ],
      ),
    );
  }

  Container _anifyEpisode(
      bool isSelected, BuildContext context, Episode episode) {
    final savedEP =
        offlineEpisodes.firstWhereOrNull((e) => e.number == episode.number);
    final progress = savedEP?.timeStampInMilliseconds != null &&
            savedEP?.durationInMilliseconds != null &&
            savedEP!.durationInMilliseconds! > 0
        ? (savedEP.timeStampInMilliseconds! / savedEP.durationInMilliseconds!)
        : 0.0;
    final isFiller = episode.filler ?? false;

    return Container(
      padding: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.6)
            : isFiller
                ? Colors.orangeAccent.withAlpha(120)
                : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 170,
                height: 100,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: NetworkSizedImage(
                        imageUrl: episode.thumbnail ??
                            widget.anilistData?.cover ??
                            widget.anilistData?.poster ??
                            '',
                        radius: 12,
                        width: double.infinity,
                        height: double.infinity,
                        errorImage: widget.anilistData?.cover ??
                            widget.anilistData?.poster,
                      ),
                    ),
                    if (progress > 0.0 && progress <= 1.0) ...[
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius:
                                BorderRadius.circular(12.multiplyRadius()),
                          ),
                          height: 2,
                          width: 170 * progress,
                        ),
                      ),
                      Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Theme.of(context).colorScheme.primary),
                              child: Icon(
                                Icons.remove_red_eye,
                                color: Theme.of(context).colorScheme.onPrimary,
                              )))
                    ],
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.black.withOpacity(0.2),
                              border: Border.all(
                                width: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              boxShadow: [glowingShadow(context)],
                            ),
                            child: AnymexText(
                              text: "EP ${episode.number}",
                              variant: TextVariant.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnymexText(
                  text: episode.title ?? 'Unknown Title',
                  variant: TextVariant.bold,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          AnymexText(
            text: (episode.desc?.isEmpty ?? true)
                ? 'No Description Available'
                : episode.desc ?? 'No Description Available',
            variant: TextVariant.regular,
            maxLines: 3,
            fontStyle: FontStyle.italic,
            color:
                Theme.of(context).colorScheme.inverseSurface.withOpacity(0.90),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
                  child: NetworkSizedImage(
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
                    gradient: LinearGradient(colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.5),
                    ]),
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ),
              Positioned.fill(
                child: AnymexButton(
                  onTap: onPressed,
                  padding: EdgeInsets.zero,
                  border: BorderSide(color: Colors.transparent),
                  color: Colors.transparent,
                  radius: borderRadius,
                  child: SizedBox(
                    width: getResponsiveValue(context,
                        mobileValue: (Get.width * 0.8), desktopValue: null),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Episode ${episode.number}: ${episode.title}'
                              .toUpperCase(),
                          style: textStyle ??
                              TextStyle(
                                color: textColor,
                                fontFamily: 'Poppins-SemiBold',
                              ),
                          textAlign: TextAlign.center,
                        ),
                        PlatformBuilder(
                            androidBuilder: SizedBox.shrink(),
                            desktopBuilder: Column(
                              children: [
                                const SizedBox(height: 3),
                                Container(
                                  color: Theme.of(context).colorScheme.primary,
                                  height: 2,
                                  width: 6 *
                                      'Episode ${episode.number}: ${episode.title}'
                                          .length
                                          .toDouble(),
                                )
                              ],
                            ))
                      ],
                    ),
                  ),
                ),
              ),
              if (progressPercentage > 0)
                Positioned(
                  height: 2,
                  bottom: 0,
                  left: 0,
                  child: Container(
                    height: 4,
                    width: constraints.maxWidth * progressPercentage,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
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
