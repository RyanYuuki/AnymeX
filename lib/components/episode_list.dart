import 'package:flutter/material.dart';

class EpisodeGrid extends StatefulWidget {
  final List<dynamic> episodes;
  final bool isList;
  final Function(int) onEpisodeSelected;
  final int currentEpisode;

  const EpisodeGrid({
    super.key,
    required this.episodes,
    this.isList = false,
    required this.currentEpisode,
    required this.onEpisodeSelected,
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
    bool isList = widget.isList;

    return SizedBox(
      height: 250,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isList ? 1 : 5,
          mainAxisExtent: isList ? 50 : 40,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
        ),
        itemCount: filteredEpisodes.length,
        itemBuilder: (context, index) {
          final episode = filteredEpisodes[index];
          final episodeNumber = episode['number'];
          final episodeTitle = episode['title'] ?? 'No Title';
          final isFiller = episode['isFiller'] ?? false;
          final isSelected = widget.currentEpisode == episodeNumber;

          return GestureDetector(
            onTap: () {
              widget.onEpisodeSelected(episodeNumber);
            },
            child: Container(
              width: isList ? double.infinity : null,
              height: 40,
              margin: const EdgeInsets.all(4.0),
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
                        ? const Icon(Icons.play_arrow_rounded, color: Colors.white)
                        : Center(
                            child: Text(
                              isList ? '$episodeNumber.' : episodeNumber.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.inverseSurface,
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
                            color: isSelected ? Colors.white : Theme.of(context).colorScheme.inverseSurface.withOpacity(0.7),
                            fontStyle: FontStyle.italic
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
