import 'package:flutter/material.dart';

class EpisodeGrid extends StatefulWidget {
  final List<dynamic> episodes;
  final int layoutIndex;
  final Function(int) onEpisodeSelected;
  final int currentEpisode;
  final String coverImage;
  final int progress;
  const EpisodeGrid({
    super.key,
    required this.episodes,
    required this.layoutIndex,
    required this.currentEpisode,
    required this.onEpisodeSelected,
    required this.progress,
    required this.coverImage,
  });

  @override
  _EpisodeGridState createState() => _EpisodeGridState();
}

class _EpisodeGridState extends State<EpisodeGrid> {
  late List<dynamic> filteredEpisodes;

  @override
  void initState() {
    super.initState();
    filteredEpisodes = widget.episodes;
  }

  @override
  void didUpdateWidget(EpisodeGrid oldWidget) {
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
        crossAxisCount: isGrid ? 5 : 1,
        mainAxisExtent: isList
            ? 50
            : isGrid
                ? 40
                : 120,
        crossAxisSpacing: 5,
        mainAxisSpacing: widget.layoutIndex == 0 ? 20 : 5,
      ),
      padding: const EdgeInsets.symmetric(vertical: 5),
      shrinkWrap: true,
      itemCount: filteredEpisodes.length,
      itemBuilder: (context, index) {
        final episode = filteredEpisodes[index];
        final episodeNumber = episode?['number'];
        final episodeTitle = episode?['title'] ?? 'No Title';
        final isFiller = episode?['isFiller'] ?? false;
        final isSelected = widget.currentEpisode == episodeNumber;

        if (widget.layoutIndex == 0) {
          return GestureDetector(
            onTap: () {
              widget.onEpisodeSelected(episodeNumber);
            },
            child: Opacity(
              opacity: episodeNumber < widget.progress ? 0.7 : 1,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryFixedVariant
                      : Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                child: Stack(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.coverImage,
                              width: 50,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
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
                                  : Theme.of(context)
                                      .colorScheme
                                      .inverseSurface,
                              fontFamily: 'Poppins-SemiBold',
                              fontSize: 12,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: 45,
                          height: 35,
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12))),
                          child: Center(
                            child: Text(
                              episodeNumber?.toString() ?? index.toString(),
                              style: const TextStyle(
                                  fontFamily: 'Poppins-Bold',
                                  color: Colors.black),
                            ),
                          ),
                        )),
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
            opacity: episodeNumber < widget.progress ? 0.7 : 1,
            child: Container(
              width: isList ? double.infinity : null,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryFixedVariant
                    : isFiller
                        ? Colors.lightGreen.shade700
                        : Theme.of(context).colorScheme.surfaceContainer,
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
