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

  final Rx<DMedia?> selectedMedia = Rx<DMedia?>(null);
  final Rx<Source?> selectedSource = Rx<Source?>(null);

  final RxList<Episode> episodes = <Episode>[].obs;
  final RxList<Episode> filteredEpisodes = <Episode>[].obs;
  final RxSet<String> selectedEpisodes = <String>{}.obs;

  final RxMap<String, String> selectedSortValues = <String, String>{}.obs;
  final RxInt selectedChunkIndex = 0.obs;

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
    selectedSortValues.clear();
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
    final sources = mediaType.value == 0
        ? sourceController.installedExtensions
        : sourceController.installedMangaExtensions;

    searchingSources.assignAll(sources);
    loadingSources.addAll(sources);
    searchingSources.refresh();
    loadingSources.refresh();

    // Cancel any existing search requests
    _activeSearchTokens.forEach((source, token) {
      source.cancelRequest(token);
    });
    _activeSearchTokens.clear();

    final List<Future<void>> searchTasks = sources.map((source) async {
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

  Future<void> fetchDetail(DMedia media, Source source) async {
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
      final convertEp = detail.episodes
          ?.map((ep) => DEpisodeToEpisode(ep))
          .toList()
          .reversed
          .toList();
      episodes.assignAll(convertEp ?? []);
      initSortGrouping(episodes);
    } catch (e) {
      debugPrint('Fetch detail error: $e');
    } finally {
      _activeDetailToken = null;
      isFetchingDetail.value = false;
    }
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
