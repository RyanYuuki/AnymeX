import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum SortType {
  title,
  lastAdded,
  lastRead,
  rating,
}

class LibraryController extends GetxController {
  final offlineStorage = Get.find<OfflineStorageController>();
  final TextEditingController searchController = TextEditingController();

  final gridCount = 0.obs;
  final searchQuery = ''.obs;
  final selectedListIndex = 0.obs;
  final type = ItemType.anime.obs;
  final isSearchActive = false.obs;

  final currentSort = SortType.lastAdded.obs;
  final isAscending = false.obs;

  @override
  void onInit() {
    super.onInit();
    _migrateGridDefaultToAuto();
    getPreferences();
  }

  void _migrateGridDefaultToAuto() {
    final migrated = General.libraryGridAutoMigrated.get<bool>(false);
    if (migrated) return;

    for (final mediaType in ItemType.values) {
      DynamicKeys.libraryGridSize.set(mediaType.name, 0);
    }

    General.libraryGridAutoMigrated.set(true);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void getPreferences() {
    final savedType =
        LibraryKeys.libraryLastType.get<int>(ItemType.anime.index);
    type.value = ItemType.values[savedType];

    final savedListIndex =
        DynamicKeys.libraryLastListIndex.get<int>(type.value.name, 0);
    selectedListIndex.value = savedListIndex;

    gridCount.value = DynamicKeys.libraryGridSize.get<int>(type.value.name, 0);

    _loadSortPrefs();
  }

  void _loadSortPrefs() {
    final prefix = selectedListIndex.value == -1 ? '${type.value.name}_history' : type.value.name;
    final defaultSort = selectedListIndex.value == -1 ? SortType.lastRead.index : SortType.lastAdded.index;

    currentSort.value = SortType.values[DynamicKeys.librarySortType.get<int>(prefix, defaultSort)];
    isAscending.value = DynamicKeys.librarySortOrder.get<bool>(prefix, false);
  }

  void _saveSortPrefs() {
    final prefix = selectedListIndex.value == -1 ? '${type.value.name}_history' : type.value.name;
    DynamicKeys.librarySortType.set(prefix, currentSort.value.index);
    DynamicKeys.librarySortOrder.set(prefix, isAscending.value);
  }

  void savePreferences() {
    _saveSortPrefs();
    DynamicKeys.libraryGridSize.set(type.value.name, gridCount.value);

    LibraryKeys.libraryLastType.set(type.value.index);
    DynamicKeys.libraryLastListIndex
        .set(type.value.name, selectedListIndex.value);
  }

  void switchCategory(ItemType typ) {
    type.value = typ;

    DynamicKeys.libraryLastListIndex.set(type.value.name, type.value.index);

    if (searchQuery.isNotEmpty) {
      searchController.clear();
      searchQuery.value = '';
    }
    savePreferences();
  }

  void selectList(int index) {
    selectedListIndex.value = index;
    if (searchQuery.isNotEmpty) {
      searchController.clear();
      searchQuery.value = '';
    }
    _loadSortPrefs();
    savePreferences();

    if (index == -1) {
      snackBar('Hold to access history editor');
    }
  }

  void toggleSearch() {
    isSearchActive.value = !isSearchActive.value;
    if (!isSearchActive.value) {
      searchController.clear();
      searchQuery.value = '';
    }
  }

  void search(String query) {
    searchQuery.value = query;
  }

  void handleSortChange(SortType sortType) {
    if (currentSort.value == sortType) {
      isAscending.value = !isAscending.value;
    } else {
      currentSort.value = sortType;
      isAscending.value = false;
    }
    _saveSortPrefs();
  }

  List<OfflineMedia> applySorting(List<OfflineMedia> items) {
    final sorted = List<OfflineMedia>.from(items);

    sorted.sort((a, b) {
      int comparison = 0;

      switch (currentSort.value) {
        case SortType.title:
          comparison = (a.name ?? '').compareTo(b.name ?? '');
          break;
        case SortType.lastRead:
          final aTime = type.value.isAnime
              ? (a.currentEpisode?.lastWatchedTime ?? 0)
              : (a.currentChapter?.lastReadTime ?? 0);
          final bTime = type.value.isAnime
              ? (b.currentEpisode?.lastWatchedTime ?? 0)
              : (b.currentChapter?.lastReadTime ?? 0);
          comparison = aTime.compareTo(bTime);
          break;
        case SortType.rating:
          final aRating = double.tryParse(a.rating ?? '0.0') ?? 0.0;
          final bRating = double.tryParse(b.rating ?? '0.0') ?? 0.0;
          comparison = aRating.compareTo(bRating);
          break;
        case SortType.lastAdded:
        // return isAscending ? items.reversed.toList() : items;
      }

      return isAscending.value ? comparison : -comparison;
    });

    return sorted;
  }

  List<OfflineMedia> applySearch(List<OfflineMedia> items, String query) {
    if (query.isEmpty) return items;

    return items
        .where(
            (e) => e.name?.toLowerCase().contains(query.toLowerCase()) ?? false)
        .toList();
  }

  Stream<List<OfflineMedia>> getLibraryStream() {
    switch (type.value) {
      case ItemType.anime:
        return offlineStorage.watchAnimeLibrary();
      case ItemType.manga:
        return offlineStorage.watchMangaLibrary();
      case ItemType.novel:
        return offlineStorage.watchNovelLibrary();
    }
  }

  Stream<List<OfflineMedia>> getHistoryStream() {
    return getLibraryStream().map((items) {
      if (type.value.isAnime) {
        var filtered = items
            .where((e) => e.currentEpisode?.currentTrack != null)
            .toList();
        filtered.sort((a, b) => (b.currentEpisode?.lastWatchedTime ?? 0)
            .compareTo(a.currentEpisode?.lastWatchedTime ?? 0));
        return filtered;
      }

      if (type.value.isManga) {
        var filtered = items.where((e) => e.currentChapter?.link != null).toList();
        filtered.sort((a, b) => (b.currentChapter?.lastReadTime ?? 0)
            .compareTo(a.currentChapter?.lastReadTime ?? 0));
        return filtered;
      }

      if (type.value.isNovel) {
        var filtered = items.where((e) => e.currentChapter?.link != null).toList();
        filtered.sort((a, b) => (b.currentChapter?.lastReadTime ?? 0)
            .compareTo(a.currentChapter?.lastReadTime ?? 0));
        return filtered;
      }

      return items;
    });
  }

  Future<List<String>> getCustomListNames() async {
    final lists = await offlineStorage.getCustomListsByType(type.value);
    return lists.map((l) => l.listName ?? '').toList();
  }

  Stream<List<OfflineMedia>> getCustomListStream(
      String listName, ItemType type) {
    return offlineStorage
        .watchCustomListData(listName, type)
        .map((data) => data.listData);
  }
}
