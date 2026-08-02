import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
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
    return Obx(() {
      final selected = selectedChunkIndex.value;
      return AnymeXPills(
        scrollPadding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
        items: List.generate(chunks.length, (index) {
          final label = index == 0
              ? 'All'
              : '${formatEpisodeNumberLabel(chunks[index].first.number)} - ${formatEpisodeNumberLabel(chunks[index].last.number)}';
          return PillItem(
            label: label,
            isSelected: selected == index,
            onTap: () => onChunkSelected(index),
          );
        }),
      );
    });
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
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Obx(() {
          final selected = selectedSortKey.value;
          return AnymeXPills(
            scrollPadding: const EdgeInsets.fromLTRB(0, 6, 0, 5),
            items: sortKeys.map((sortKey) {
              return PillItem(
                label: '$labelPrefix $sortKey',
                isSelected: selected == sortKey,
                onTap: () => onSortKeySelected(sortKey),
              );
            }).toList(),
          );
        }),
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

String formatEpisodeNumberLabel(dynamic rawNumber) {
  if (rawNumber == null) return '';
  final parsed = double.tryParse(rawNumber.toString().trim());
  if (parsed == null) return rawNumber.toString();

  if (parsed == parsed.toInt()) {
    return parsed.toInt().toString();
  }

  final rounded = double.parse(parsed.toStringAsFixed(2));
  if (rounded == rounded.toInt()) {
    return rounded.toInt().toString();
  }

  return rounded.toString().replaceAll(RegExp(r'\.?0+$'), '');
}
