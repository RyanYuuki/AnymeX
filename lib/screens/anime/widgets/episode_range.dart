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
                          : '${formatEpisodeNumberLabel(chunks[index].first.number)} - ${formatEpisodeNumberLabel(chunks[index].last.number)}',
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

class EpisodeSortKeySelector extends StatelessWidget {
  final String title;
  final String labelPrefix;
  final RxnString selectedSortKey;
  final ValueChanged<String> onSortKeySelected;
  final List<String> sortKeys;

  const EpisodeSortKeySelector({
    super.key,
    required this.title,
    required this.labelPrefix,
    required this.selectedSortKey,
    required this.onSortKeySelected,
    required this.sortKeys,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(
              sortKeys.length,
              (index) {
                final sortKey = sortKeys[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 10, 5),
                  child: Obx(() {
                    final isSelected = selectedSortKey.value == sortKey;

                    return InkWell(
                      onTap: () {
                        onSortKeySelected(sortKey);
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
                              ? colorScheme.primary
                                  .opaque(0.4, iReallyMeanIt: true)
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
                          '$labelPrefix $sortKey',
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
        ),
      ],
    );
  }
}

class EpisodeSortSection {
  final String key;
  final String title;
  final String labelPrefix;
  final List<String> values;

  const EpisodeSortSection({
    required this.key,
    required this.title,
    required this.labelPrefix,
    required this.values,
  });
}

String formatEpisodeSortKeyLabel(String key) {
  final normalized = key.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  if (normalized.isEmpty) return key;

  return normalized
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

List<EpisodeSortSection> buildEpisodeSortSections(List<Episode> episodes) {
  final Map<String, Set<String>> groupedValues = {};

  for (final episode in episodes) {
    episode.sortMap.forEach((key, value) {
      final trimmedKey = key.trim();
      final trimmedValue = value.trim();
      if (trimmedKey.isEmpty || trimmedValue.isEmpty) {
        return;
      }

      groupedValues.putIfAbsent(trimmedKey, () => <String>{}).add(trimmedValue);
    });
  }

  final sections = groupedValues.entries
      .where((entry) => entry.value.length > 1)
      .map(
        (entry) => EpisodeSortSection(
          key: entry.key,
          title: formatEpisodeSortKeyLabel(entry.key),
          labelPrefix: formatEpisodeSortKeyLabel(entry.key),
          values: entry.value.toList()..sort(compareEpisodeSortValues),
        ),
      )
      .toList()
    ..sort((a, b) => a.title.compareTo(b.title));

  return sections;
}

int compareEpisodeSortValues(String first, String second) {
  final firstNumber = double.tryParse(first.trim());
  final secondNumber = double.tryParse(second.trim());

  if (firstNumber != null && secondNumber != null) {
    return firstNumber.compareTo(secondNumber);
  }
  if (firstNumber != null) return -1;
  if (secondNumber != null) return 1;
  return first.compareTo(second);
}

String formatEpisodeNumberLabel(String number) {
  final parsedNumber = double.tryParse(number.trim());
  if (parsedNumber == null) {
    return number;
  }

  if (parsedNumber == parsedNumber.toInt()) {
    return parsedNumber.toInt().toString();
  }

  return parsedNumber.toString();
}
