import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EpisodeChunkSelector extends StatelessWidget {
  final RxInt selectedChunkIndex;
  final ValueChanged<int> onChunkSelected;
  final List<List<Episode>> chunks;

  const EpisodeChunkSelector({
    super.key,
    required this.selectedChunkIndex,
    required this.onChunkSelected,
    required this.chunks,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(
          chunks.length,
          (index) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 10, 5),
              child: Obx(() {
                final isSelected = selectedChunkIndex.value == index;

                return InkWell(
                  onTap: () {
                    onChunkSelected(index);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.opaque(0.4, iReallyMeanIt: true)
                          : colorScheme.surfaceContainerHigh
                              .opaque(0.4, iReallyMeanIt: true),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary.opaque(0.4)
                            : colorScheme.outline.opaque(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      index == 0
                          ? "All"
                          : '${chunks[index].first.number} - ${chunks[index].last.number}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
