// ignore_for_file: invalid_use_of_protected_member, prefer_const_constructors
import 'dart:io';
import 'dart:ui';
import 'package:anymex/api/Mangayomi/Eval/dart/model/video.dart';
import 'package:anymex/api/Mangayomi/Search/getVideo.dart';
import 'package:anymex/controllers/anilist/anilist_auth.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Anilist/anilist_media_full.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/screens/anime/widgets/episode_range.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class EpisodeWatchScreen extends StatefulWidget {
  const EpisodeWatchScreen({
    super.key,
    required this.episodeList,
    required this.anilistData,
    required this.currentEpisode,
    required this.onEpisodeSelected,
  });
  final Function(
          Video episodeSrc, List<Video> streamList, Episode selectedEpisode)
      onEpisodeSelected;
  final Episode currentEpisode;
  final List<Episode> episodeList;
  final AnilistMediaData? anilistData;

  @override
  State<EpisodeWatchScreen> createState() => _EpisodeWatchScreenState();
}

class _EpisodeWatchScreenState extends State<EpisodeWatchScreen> {
  final selectedChunkIndex = 0.obs;
  final RxList<Video> streamList = <Video>[].obs;
  final sourceController = Get.find<SourceController>();
  final Rx<Episode> chosenEpisode = Episode(number: '1').obs;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AnilistAuth>();
    final userProgress = (auth
                .returnAvailAnime(widget.anilistData!.id.toString())
                .episodeCount) ==
            null
        ? widget.currentEpisode.number.toInt()
        : auth
            .returnAvailAnime(widget.anilistData!.id.toString())
            .episodeCount!
            .toInt();

    serverDialog() {
      return showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(10),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Obx(() {
              if (streamList.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return ListView(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    alignment: Alignment.center,
                    child: const AnymexText(
                      text: "Choose Server",
                      size: 18,
                      variant: TextVariant.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...streamList.value.map((e) {
                    return GestureDetector(
                      onTap: () {
                        widget.onEpisodeSelected(
                            e, streamList, chosenEpisode.value);
                        Get.back();
                        if (Platform.isAndroid && Platform.isIOS) {
                          Get.back();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 3.0, horizontal: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 2.5, horizontal: 10),
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
              );
            }),
          );
        },
      );
    }

    Future<void> fetchServers(String url) async {
      serverDialog();
      final videoList = await getVideo(
          source: sourceController.activeSource.value!, url: url);
      streamList.value = videoList;
    }

    return Obx(() {
      final chunkedEpisodes = chunkEpisodes(widget.episodeList ?? [],
          calculateChunkSize(widget.episodeList ?? []));
      final selectedEpisodes = chunkedEpisodes.isNotEmpty
          ? chunkedEpisodes[selectedChunkIndex.value]
          : [];
      final isAnify = widget.episodeList[0].thumbnail != '' &&
          widget.episodeList[0].thumbnail != null;

      return SizedBox(
        width: getResponsiveValue(context,
            mobileValue: MediaQuery.of(context).size.width, desktopValue: null),
        height: getResponsiveValue(context,
            mobileValue: MediaQuery.of(context).size.height * 0.8,
            desktopValue: null),
        child: Glow(
          child: ListView(
            padding: EdgeInsets.symmetric(
                vertical: 20,
                horizontal:
                    getResponsiveSize(context, mobileSize: 20, dektopSize: 10)),
            children: [
              Row(
                children: const [
                  AnymexText(
                      text: "Episodes", size: 20, variant: TextVariant.semiBold)
                ],
              ),
              EpisodeChunkSelector(
                chunks: chunkedEpisodes,
                selectedChunkIndex: selectedChunkIndex,
                onChunkSelected: (index) {
                  selectedChunkIndex.value = index;
                },
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 10),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 15,
                  mainAxisExtent: isAnify ? 200 : 100,
                ),
                itemCount: selectedEpisodes.length,
                itemBuilder: (context, index) {
                  final episode = selectedEpisodes[index] as Episode;
                  final isSelected =
                      widget.currentEpisode.number == episode.number;
                  final watchedEpisode = episode.number.toInt() <= userProgress;
                  return InkWell(
                    onTap: () {
                      if (isSelected) {
                        fetchServers(episode.link!);
                      } else {
                        chosenEpisode.value = episode;
                        streamList.value = [];
                        fetchServers(episode.link!);
                      }
                    },
                    child: Opacity(
                      opacity: watchedEpisode ? 0.5 : 1.0,
                      child: isAnify
                          ? _anifyEpisode(isSelected, context, episode)
                          : _buildNormalEpisode(isSelected, context, episode),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Container _buildNormalEpisode(
      bool isSelected, BuildContext context, Episode episode) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.6)
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: widget.anilistData?.cover ??
                        widget.anilistData?.poster ??
                        '',
                    fit: BoxFit.cover,
                    height: double.infinity,
                  ),
                ),
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
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: AnymexText(
            text: episode.title ?? '?',
            variant: TextVariant.bold,
          ))
        ],
      ),
    );
  }

  Container _anifyEpisode(
      bool isSelected, BuildContext context, Episode episode) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.6)
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(children: [
                NetworkSizedImage(
                  imageUrl: episode.thumbnail ??
                      widget.anilistData?.cover ??
                      widget.anilistData?.poster ??
                      '',
                  radius: 12,
                  width: 170,
                  height: 100,
                ),
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
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
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
          const SizedBox(height: 8),
          AnymexText(
            text: episode.desc ?? 'No Description Available',
            variant: TextVariant.regular,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
