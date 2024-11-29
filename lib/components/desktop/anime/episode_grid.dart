// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DesktopEpisodeGrid extends StatefulWidget {
  final List<dynamic> episodes;
  final int layoutIndex;
  final Function(int) onEpisodeSelected;
  final Function(String, String) onEpisodeDownload;
  final int currentEpisode;
  final String coverImage;
  final int progress;
  final dynamic episodeImages;
  const DesktopEpisodeGrid({
    super.key,
    required this.episodes,
    required this.layoutIndex,
    required this.currentEpisode,
    required this.onEpisodeSelected,
    required this.progress,
    required this.coverImage,
    this.episodeImages,
    required this.onEpisodeDownload,
  });

  @override
  _DesktopEpisodeGridState createState() => _DesktopEpisodeGridState();
}

class _DesktopEpisodeGridState extends State<DesktopEpisodeGrid> {
  late List<dynamic> filteredEpisodes;

  @override
  void initState() {
    super.initState();
    filteredEpisodes = widget.episodes;
  }

  @override
  void didUpdateWidget(DesktopEpisodeGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.episodes != oldWidget.episodes) {
      setState(() {
        filteredEpisodes = widget.episodes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isList = widget.layoutIndex == 1;
    bool isGrid = widget.layoutIndex == 2;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isGrid
            ? 6
            : widget.layoutIndex == 1
                ? 4
                : 3,
        mainAxisExtent: isList
            ? 120
            : isGrid
                ? 60
                : 130,
        crossAxisSpacing: 20,
        mainAxisSpacing: widget.layoutIndex == 2 ? 5 : 10,
      ),
      padding: const EdgeInsets.symmetric(vertical: 5),
      shrinkWrap: true,
      itemCount: filteredEpisodes.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final episode = filteredEpisodes[index];
        final episodeNumber = episode?['number'];
        final episodeTitle = episode?['title'] ?? 'No Title';
        final isFiller = episode?['isFiller'] ?? false;
        final isSelected = widget.currentEpisode == episodeNumber;
        double opacity = episodeNumber <= widget.progress
            ? episodeNumber == widget.progress
                ? 0.8
                : 0.5
            : 1;
        Color color = isSelected
            ? Theme.of(context).colorScheme.secondaryContainer
            : isFiller
                ? Colors.lightGreen.shade700
                : Theme.of(context).colorScheme.surfaceContainer;

        if (widget.layoutIndex == 0) {
          return GestureDetector(
            onTap: () {
              widget.onEpisodeSelected(episodeNumber);
            },
            child: Opacity(
              opacity: opacity,
              child: Container(
                height: 50,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: (widget.episodeImages != null &&
                                      widget.episodeImages!.length > index
                                  ? widget.episodeImages![episodeNumber - 1]
                                          ['image'] ??
                                      widget.coverImage
                                  : widget.coverImage),
                                  width: double.maxFinite,
                                  alignment: Alignment.center,
                              fit: BoxFit.cover,
                              placeholder: (context, url) {
                                return CachedNetworkImage(
                                  imageUrl: widget.coverImage,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              },
                              errorWidget: (context, error, stackTrace) {
                                return CachedNetworkImage(
                                  imageUrl: widget.coverImage,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 10,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                                child: Container(
                                  width: 50,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'EP ${episodeNumber?.toString() ?? index.toString()}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins-Bold',
                                      ),
                                    ),
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
                      flex: 1,
                      child: Text(
                        episodeTitle,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.inverseSurface,
                          fontFamily: 'Poppins-Bold',
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // IconButton(
                    //   onPressed: () => widget.onEpisodeDownload(
                    //       episode['episodeId'], episodeNumber.toString()),
                    //   icon: Icon(Icons.download,
                    //       color: Theme.of(context).colorScheme.inverseSurface),
                    // ),
                  ],
                ),
              ),
            ),
          );
        }

        if (widget.layoutIndex == 1) {
          return GestureDetector(
            onTap: () {
              widget.onEpisodeSelected(episodeNumber);
            },
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: double.maxFinite,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20), color: color),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: (widget.episodeImages != null &&
                              widget.episodeImages!.length > index
                          ? widget.episodeImages![episodeNumber - 1]['image'] ??
                              widget.coverImage
                          : widget.coverImage),
                      fit: BoxFit.cover,
                    ),
                    Container(
                      padding:
                          const EdgeInsets.only(top: 15, left: 10, right: 5),
                      decoration: BoxDecoration(
                        color: isFiller
                            ? Colors.lightGreen.shade700.withOpacity(0.8)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainer
                                .withOpacity(0.6),
                      ),
                      child: Text(
                        episodeTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Poppins-SemiBold'),
                      ),
                    ),
                    Positioned(
                        bottom: 5,
                        right: 20,
                        child: Text(episodeNumber.toString(),
                            style: TextStyle(
                                fontFamily: "Poppins-Bold",
                                fontSize: 24,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface
                                    .withOpacity(0.8)))),
                    // Positioned(
                    //     bottom: 7,
                    //     left: 10,
                    //     child: InkWell(
                    //         onTap: () => widget.onEpisodeDownload(
                    //             episode['episodeId'], episodeNumber.toString()),
                    //         child: Icon(Icons.download,
                    //             color: Theme.of(context)
                    //                 .colorScheme
                    //                 .inverseSurface
                    //                 .withOpacity(0.8))))
                  ],
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            widget.onEpisodeSelected(episodeNumber);
          },
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: isList ? double.infinity : null,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: color,
              ),
              child: Padding(
                padding: EdgeInsets.only(left: isList ? 8.0 : 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    isSelected
                        ? const Icon(Icons.play_arrow_rounded,
                            color: Colors.white)
                        : Center(
                            child: Text(
                              isList
                                  ? '$episodeNumber.'
                                  : episodeNumber.toString(),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    if (isList) const SizedBox(width: 5),
                    if (isList)
                      Expanded(
                        child: Text(
                          episodeTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .inverseSurface
                                    .withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
