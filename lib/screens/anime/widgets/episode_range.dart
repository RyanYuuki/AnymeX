import 'package:anymex/models/Episode/episode.dart';
import 'package:anymex/utils/function.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EpisodeChunkSelector extends StatelessWidget {
  final List<Episode> episodes;
  final RxInt selectedChunkIndex;
  final ValueChanged<int> onChunkSelected;

  final RxList<List<Episode>> chunks = <List<Episode>>[].obs;

  EpisodeChunkSelector({
    super.key,
    required this.episodes,
    required this.selectedChunkIndex,
    required this.onChunkSelected,
  }) {
    _initializeChunks();
  }

  void _initializeChunks() {
    final chunkSize = calculateChunkSize(episodes);
    chunks.value = chunkEpisodes(episodes, chunkSize);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            chunks.length,
            (index) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 10, 5),
                child: ChoiceChip(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.4),
                  showCheckmark: false,
                  label: Text(
                    '${chunks[index].first.number} - ${chunks[index].last.number}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: selectedChunkIndex.value == index,
                  onSelected: (bool selected) {
                    if (selected) {
                      selectedChunkIndex.value = index;
                      onChunkSelected(index);
                    }
                  },
                ),
              );
            },
          ),
        ),
      );
    });
  }
}
