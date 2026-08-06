import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/screens/anime/widgets/episode_range.dart';
import 'package:anymex/utils/function.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/controllers/source/source_controller.dart';

class DownloadSearchController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  int _searchSessionId = 0;

  final RxInt step = 0.obs;
  final RxInt mediaType = 0.obs;
  final RxBool isSearching = false.obs;
  final RxBool isFetchingDetail = false.obs;

  final Map<Source, String> _activeSearchTokens = {};
  String? _activeDetailToken;

  final RxMap<Source, List<DMedia>> searchResults =
      <Source, List<DMedia>>{}.obs;
  final RxList<Source> searchingSources = <Source>[].obs;
  final RxSet<Source> loadingSources = <Source>{}.obs;
  final RxSet<String> disabledSourceIds = <String>{}.obs;

  final Rx<DMedia?> selectedMedia = Rx<DMedia?>(null);
  final Rx<Source?> selectedSource = Rx<Source?>(null);

  final RxList<Episode> episodes = <Episode>[].obs;
  final RxList<Episode> filteredEpisodes = <Episode>[].obs;
  final RxSet<String> selectedEpisodes = <String>{}.obs;

  final RxList<Chapter> chapters = <Chapter>[].obs;
  final RxSet<String> selectedChapters = <String>{}.obs;

  final RxMap<String, String> selectedSortValues = <String, String>{}.obs;
  final RxInt selectedChunkIndex = 0.obs;

  final RxInt selectedScanlatorIndex = 0.obs;
  final RxBool selectByIndex = false.obs;

  List<String> get scanlators {
    return chapters
        .map((c) => c.scanlator?.trim() ?? 'Unknown')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<Chapter> get filteredChapters {
    if (selectedScanlatorIndex.value == 0 || scanlators.isEmpty) {
      return chapters;
    }
    final selectedScanlator = scanlators[selectedScanlatorIndex.value - 1];
    return chapters.where((c) {
      final s = c.scanlator?.trim() ?? 'Unknown';
      return s == selectedScanlator;
    }).toList();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void resetDetail() {
    selectedMedia.value = null;
    selectedSource.value = null;
    episodes.clear();
    filteredEpisodes.clear();
    selectedEpisodes.clear();
    chapters.clear();
    selectedChapters.clear();
    selectedSortValues.clear();
    selectedScanlatorIndex.value = 0;
    selectedChunkIndex.value = 0;
    isFetchingDetail.value = false;
    step.value = 0;
  }

  Future<void> search(String query) async {
    if (query.isEmpty) return;
    final sessionId = ++_searchSessionId;

    isSearching.value = true;
    searchResults.clear();
    searchResults.refresh();
    searchingSources.clear();
    searchingSources.refresh();
    loadingSources.clear();
    loadingSources.refresh();

    final sourceController = Get.find<SourceController>();
    final searching = (mediaType.value == 0
            ? sourceController.installedExtensions
            : sourceController.installedMangaExtensions)
        .where((s) => !disabledSourceIds.contains(s.id))
        .toList();

    searchingSources.assignAll(searching);
    loadingSources.addAll(searching);
    searchingSources.refresh();
    loadingSources.refresh();

    _activeSearchTokens.forEach((source, token) {
      source.cancelRequest(token);
    });
    _activeSearchTokens.clear();

    final List<Future<void>> searchTasks = searching.map((source) async {
      final token =
          'search_${source.id}_${DateTime.now().millisecondsSinceEpoch}';
      _activeSearchTokens[source] = token;

      try {
        final medias = await source.methods
            .search(query, 1, [], parameters: SourceParams(cancelToken: token));
        if (sessionId != _searchSessionId) return;

        if (medias.list.isNotEmpty) {
          searchResults[source] = medias.list;
          searchResults.refresh();

          final sourceIndex = searchingSources.indexOf(source);
          if (sourceIndex > 0) {
            searchingSources.removeAt(sourceIndex);
            searchingSources.insert(0, source);
            searchingSources.refresh();
          }
        }
      } catch (e) {
        debugPrint('Search error for ${source.name}: $e');
      } finally {
        if (sessionId == _searchSessionId) {
          loadingSources.remove(source);
          loadingSources.refresh();
          _activeSearchTokens.remove(source);
        }
      }
    }).toList();

    await Future.wait(searchTasks);

    if (sessionId == _searchSessionId) {
      isSearching.value = false;
    }
  }

  void toggleSource(String id) {
    if (disabledSourceIds.contains(id)) {
      disabledSourceIds.remove(id);
    } else {
      disabledSourceIds.add(id);
    }
  }

  Future<void> fetchDetail(DMedia media, Source source) async {
    episodes.clear();
    filteredEpisodes.clear();
    selectedEpisodes.clear();
    chapters.clear();
    selectedChapters.clear();

    selectedMedia.value = media;
    selectedSource.value = source;
    isFetchingDetail.value = true;
    step.value = 1;
    selectedSortValues.clear();
    selectedChunkIndex.value = 0;

    if (_activeDetailToken != null) {
      selectedSource.value?.cancelRequest(_activeDetailToken!);
    }
    _activeDetailToken = 'detail_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final detail = await source.methods.getDetail(media,
          parameters: SourceParams(cancelToken: _activeDetailToken));

      if (mediaType.value == 1) {
        final converted = DEpisodeToChapter(
          detail.episodes?.reversed.toList() ?? [],
          media.title ?? '',
        );
        chapters.assignAll(converted);
      } else {
        final convertEp = detail.episodes
            ?.map((ep) => DEpisodeToEpisode(ep))
            .toList()
            .reversed
            .toList();
        episodes.assignAll(convertEp ?? []);
        initSortGrouping(episodes);
      }
    } catch (e) {
      debugPrint('Fetch detail error: $e');
    } finally {
      _activeDetailToken = null;
      isFetchingDetail.value = false;
    }
  }

  void toggleChapter(Chapter chapter) {
    final key = chapter.link ?? chapter.number?.toString() ?? '';
    if (selectedChapters.contains(key)) {
      selectedChapters.remove(key);
    } else {
      selectedChapters.add(key);
    }
  }

  void selectAllChapters() {
    selectedChapters.assignAll(
      filteredChapters.map((c) => c.link ?? c.number?.toString() ?? ''),
    );
  }

  void deselectAllChapters() {
    selectedChapters.clear();
  }

  void selectNextChapters(int count) {
    selectedChapters.clear();
    final list = filteredChapters;
    final maxCount = count < list.length ? count : list.length;
    for (int i = 0; i < maxCount; i++) {
      final key = list[i].link ?? list[i].number?.toString() ?? '';
      selectedChapters.add(key);
    }
  }

  void selectChapterRange(double start, double end) {
    selectedChapters.clear();
    for (final c in chapters) {
      if (c.number != null && c.number! >= start && c.number! <= end) {
        final key = c.link ?? c.number?.toString() ?? '';
        selectedChapters.add(key);
      }
    }
  }

  void selectChapterByIndexRange(int start, int end) {
    selectedChapters.clear();
    final list = filteredChapters;
    final startIndex = (start - 1).clamp(0, list.length - 1);
    final endIndex = (end - 1).clamp(0, list.length - 1);

    for (int i = startIndex; i <= endIndex; i++) {
      final key = list[i].link ?? list[i].number?.toString() ?? '';
      selectedChapters.add(key);
    }
  }

  bool isChapterSelected(Chapter chapter) {
    final key = chapter.link ?? chapter.number?.toString() ?? '';
    return selectedChapters.contains(key);
  }

  List<Chapter> get selectedChaptersList {
    final keySet = selectedChapters.toSet();
    return chapters.where((c) {
      final key = c.link ?? c.number?.toString() ?? '';
      return keySet.contains(key);
    }).toList();
  }

  List<Episode> get selectedEpisodesList {
    final keySet = selectedEpisodes.toSet();
    return episodes.where((e) {
      final key = e.link ?? e.number;
      return keySet.contains(key);
    }).toList();
  }

  void initSortGrouping(List<Episode> allEpisodes) {
    final sections = buildEpisodeSortSections(allEpisodes);
    if (sections.isEmpty) {
      selectedSortValues.clear();
      filteredEpisodes.assignAll(allEpisodes);
      return;
    }

    final nextSelection = <String, String>{};

    for (final section in sections) {
      final availableValues = _availableValuesForKey(
        allEpisodes,
        section.key,
        sections: sections,
        activeSelection: nextSelection,
      );

      if (availableValues.isEmpty) {
        continue;
      }

      final currentValue = selectedSortValues[section.key];
      nextSelection[section.key] = availableValues.contains(currentValue)
          ? currentValue!
          : availableValues.first;
    }

    selectedSortValues.assignAll(nextSelection);

    filteredEpisodes.assignAll(allEpisodes.where((ep) {
      return selectedSortValues.entries.every((entry) {
        return ep.sortMap[entry.key]?.trim() == entry.value;
      });
    }).toList());
  }

  List<String> _availableValuesForKey(
    List<Episode> allEpisodes,
    String key, {
    List<EpisodeSortSection>? sections,
    Map<String, String>? activeSelection,
  }) {
    final effectiveSelection = activeSelection ?? selectedSortValues;
    final values = allEpisodes
        .where((episode) {
          final sortMap = episode.sortMap;
          return effectiveSelection.entries.every((entry) {
            if (entry.key == key) {
              return true;
            }
            return sortMap[entry.key]?.trim() == entry.value;
          });
        })
        .map((episode) => episode.sortMap[key]?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort(compareEpisodeSortValues);

    if (values.isNotEmpty) {
      return values;
    }

    final fallbackSection = (sections ?? buildEpisodeSortSections(allEpisodes))
        .firstWhereOrNull((section) => section.key == key);
    return fallbackSection?.values ?? const [];
  }
}
