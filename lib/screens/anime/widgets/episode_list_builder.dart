// ignore_for_file: invalid_use_of_protected_member, prefer_const_constructors

import 'dart:developer';
import 'dart:ui';
import 'package:anymex/api/Mangayomi/Eval/dart/model/video.dart';
import 'package:anymex/api/Mangayomi/Search/getVideo.dart';
import 'package:anymex/controllers/source_controller.dart';
import 'package:anymex/models/Anilist/anilist_media_full.dart';
import 'package:anymex/models/Episode/episode.dart';
import 'package:anymex/screens/anime/watch_page.dart';
import 'package:anymex/screens/anime/widgets/episode_range.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class EpisodeListBuilder extends StatefulWidget {
  const EpisodeListBuilder({
    super.key,
    required this.episodeList,
    required this.anilistData,
    required this.isDesktop,
  });

  final bool isDesktop;
  final List<Episode>? episodeList;
  final AnilistMediaData? anilistData;

  @override
  State<EpisodeListBuilder> createState() => _EpisodeListBuilderState();
}

class _EpisodeListBuilderState extends State<EpisodeListBuilder> {
  final selectedChunkIndex = 0.obs;
  Rx<Episode> selectedEpisode = Episode(number: "1").obs;
  final RxList<Video> streamList = <Video>[].obs;
  final sourceController = Get.find<SourceController>();

  @override
  Widget build(BuildContext context) {
    if (widget.episodeList == null) {
      return const SizedBox(
          height: 500, child: Center(child: CircularProgressIndicator()));
    } else if (widget.episodeList?.isEmpty ?? true) {
      return const SizedBox(
          height: 500,
          child: Center(
            child: Text("No Episodes Available"),
          ));
    }

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
                        Get.to(() => WatchPage(
                              episodeSrc: e,
                              episodeList: widget.episodeList ?? [],
                              anilistData: widget.anilistData!,
                              currentEpisode: selectedEpisode.value,
                              episodeTracks: streamList,
                            ));
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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EpisodeChunkSelector(
            episodes: widget.episodeList ?? [],
            selectedChunkIndex: selectedChunkIndex,
            onChunkSelected: (index) {
              selectedChunkIndex.value = index;
            },
          ),
          GridView.builder(
            padding: const EdgeInsets.only(top: 15),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.isDesktop ? 3 : 1,
              mainAxisSpacing: widget.isDesktop ? 15 : 10,
              crossAxisSpacing: 15,
              mainAxisExtent: widget.isDesktop ? 130 : 100,
            ),
            itemCount: selectedEpisodes.length,
            itemBuilder: (context, index) {
              final episode = selectedEpisodes[index];
              final isSelected = selectedEpisode.value.number == episode.number;
              return InkWell(
                onTap: () {
                  if (isSelected) {
                    fetchServers(episode.link!);
                  } else {
                    setState(() {
                      selectedEpisode.value = episode;
                    });
                    streamList.value = [];
                    fetchServers(episode.link!);
                  }
                },
                child: Container(
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
                                  filter: ImageFilter.blur(
                                      sigmaX: 5.0, sigmaY: 5.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.black.withOpacity(0.2),
                                      border: Border.all(
                                          width: 2,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
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
                ),
              );
            },
          ),
        ],
      );
    });
  }
}
