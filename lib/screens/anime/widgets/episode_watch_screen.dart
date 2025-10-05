// ignore_for_file: invalid_use_of_protected_member, prefer_const_constructors
import 'dart:ui';
import 'package:anymex/models/Offline/Hive/video.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/screens/anime/widgets/episode_range.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_chip.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart' as d;
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

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
  final Media? anilistData;

  @override
  State<EpisodeWatchScreen> createState() => _EpisodeWatchScreenState();
}

class _EpisodeWatchScreenState extends State<EpisodeWatchScreen> {
  final selectedChunkIndex = 1.obs;
  final RxList<Video> streamList = <Video>[].obs;
  final sourceController = Get.find<SourceController>();
  final Rx<Episode> chosenEpisode = Episode(number: '1').obs;

  // Cache for expensive calculations
  List<List<Episode>>? _cachedChunkedEpisodes;
  int? _lastEpisodeListLength;
  int? _cachedUserProgress;
  bool? _cachedIsAnify;

  @override
  void initState() {
    super.initState();
    _precomputeValues();
  }

  // 2. PERFORMANCE: Precompute expensive values
  void _precomputeValues() {
    final auth = Get.find<AnilistAuth>();
    _cachedUserProgress =
        auth.returnAvailAnime(widget.anilistData!.id.toString()).episodeCount ==
                null
            ? widget.currentEpisode.number.toInt()
            : auth
                .returnAvailAnime(widget.anilistData!.id.toString())
                .episodeCount!
                .toInt();

    _cachedIsAnify = widget.episodeList.isNotEmpty &&
        widget.episodeList[0].thumbnail != null &&
        widget.episodeList[0].thumbnail!.isNotEmpty;

    _computeChunkedEpisodes();
  }

  void _computeChunkedEpisodes() {
    if (_lastEpisodeListLength != widget.episodeList.length) {
      _cachedChunkedEpisodes = chunkEpisodes(
          widget.episodeList, calculateChunkSize(widget.episodeList));
      _lastEpisodeListLength = widget.episodeList.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _computeChunkedEpisodes(); // Only recompute if needed

      final chunkedEpisodes = _cachedChunkedEpisodes ?? [];
      final selectedEpisodes = chunkedEpisodes.isNotEmpty
          ? chunkedEpisodes[selectedChunkIndex.value]
          : <Episode>[];

      return SizedBox(
        width: getResponsiveValue(context,
            mobileValue: MediaQuery.of(context).size.width, desktopValue: null),
        height: getResponsiveValue(context,
            mobileValue: MediaQuery.of(context).size.height * 0.8,
            desktopValue: null),
        child: Glow(
          child: Column(
            // Changed from SuperListView to Column for better performance
            children: [
              // Header section
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: getResponsiveSize(context,
                        mobileSize: 20, desktopSize: 10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        AnymexText(
                            text: "Episodes",
                            size: 20,
                            variant: TextVariant.semiBold)
                      ],
                    ),
                    EpisodeChunkSelector(
                      chunks: chunkedEpisodes,
                      selectedChunkIndex: selectedChunkIndex,
                      onChunkSelected: (index) {
                        selectedChunkIndex.value = index;
                      },
                    ),
                  ],
                ),
              ),
              // 3. LAZY LOADING: Use ListView.builder instead of GridView with shrinkWrap
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                      horizontal: getResponsiveSize(context,
                          mobileSize: 20, desktopSize: 10)),
                  itemCount: selectedEpisodes.length,
                  itemBuilder: (context, index) {
                    final episode = selectedEpisodes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildEpisodeItem(episode, context),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // 4. EXTRACT AND OPTIMIZE EPISODE ITEM BUILDING
  Widget _buildEpisodeItem(Episode episode, BuildContext context) {
    final isSelected = widget.currentEpisode.number == episode.number;
    final watchedEpisode = episode.number.toInt() <= (_cachedUserProgress ?? 0);

    return RepaintBoundary(
      // Prevents unnecessary repaints
      child: AnymexOnTap(
        onTap: () => _handleEpisodeTap(episode, isSelected),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: watchedEpisode ? 0.5 : 1.0,
          child: _cachedIsAnify == true
              ? _buildAnifyEpisode(isSelected, context, episode)
              : _buildNormalEpisode(isSelected, context, episode),
        ),
      ),
    );
  }

  // 5. OPTIMIZE TAP HANDLING
  void _handleEpisodeTap(Episode episode, bool isSelected) {
    if (isSelected) {
      _fetchServers(episode);
    } else {
      chosenEpisode.value = episode;
      streamList.clear(); // More efficient than setting to empty list
      _fetchServers(episode);
    }
  }

  Future<void> _fetchServers(Episode ep) async {
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
            future: sourceController.activeSource.value!.methods.getVideoList(
                    d.DEpisode(episodeNumber: ep.number, url: ep.link))
                as Future<List<Video>>?,
            // future: getVideo(
            // source: sourceController.activeSource.value!, url: url),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildScrapingLoadingState(true);
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

  Widget _buildScrapingLoadingState(bool fromSrc) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExpressiveLoadingIndicator(),
          SizedBox(height: 16),
          Text(
            'Scanning for video streams...',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'This may take up to 30 seconds',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          10.height(),
          if (!fromSrc)
            AnymexChip(
              showCheck: false,
              isSelected: true,
              label: 'Using Universal Scrapper',
              onSelected: (v) {},
            ),
        ],
      ),
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
      child: SuperListView(
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
                widget.onEpisodeSelected(e, streamList, chosenEpisode.value);
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

  // 9. OPTIMIZE NORMAL EPISODE WIDGET
  Widget _buildNormalEpisode(
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
                    width: double.infinity,
                    memCacheWidth: 200, // Optimize memory usage
                    memCacheHeight: 100,
                    errorWidget: (context, url, error) => Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: _buildEpisodeNumberBadge(episode.number, context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: AnymexText(
                text: episode.title ?? 'Episode ${episode.number}',
                variant: TextVariant.bold,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 10. OPTIMIZE ANIFY EPISODE WIDGET
  Widget _buildAnifyEpisode(
      bool isSelected, BuildContext context, Episode episode) {
    return Container(
      height: 200,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: episode.thumbnail ??
                          widget.anilistData?.cover ??
                          widget.anilistData?.poster ??
                          '',
                      width: 170,
                      height: 100,
                      fit: BoxFit.cover,
                      memCacheWidth: 170, // Optimize memory
                      memCacheHeight: 100,
                      errorWidget: (context, url, error) => Container(
                        width: 170,
                        height: 100,
                        color: Theme.of(context).colorScheme.surface,
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _buildEpisodeNumberBadge(episode.number, context),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 100,
                  child: AnymexText(
                    text: episode.title ?? 'Episode ${episode.number}',
                    variant: TextVariant.bold,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnymexText(
              text: (episode.desc?.isEmpty ?? true)
                  ? 'No Description Available'
                  : episode.desc!,
              variant: TextVariant.regular,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 11. EXTRACT REUSABLE BADGE WIDGET
  Widget _buildEpisodeNumberBadge(String episodeNumber, BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            text: "EP $episodeNumber",
            variant: TextVariant.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up if needed
    super.dispose();
  }
}
