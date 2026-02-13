import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
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

  SortType currentSort = SortType.lastAdded;
  bool isAscending = false;

  @override
  void onInit() {
    super.onInit();
    getPreferences();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void getPreferences() {
    final savedType = settingsController.preferences
        .get('library_last_type', defaultValue: ItemType.anime.index);
    type.value = ItemType.values[savedType];

    final savedListIndex = settingsController.preferences
        .get('library_last_list_index_${type.value.name}', defaultValue: 0);
    selectedListIndex.value = savedListIndex;

    currentSort = SortType.values[settingsController.preferences.get(
        '${type.value.name}_sort_type',
        defaultValue: SortType.lastAdded.index)];
    isAscending = settingsController.preferences
        .get('${type.value.name}_sort_order', defaultValue: false);
    gridCount.value = settingsController.preferences
        .get('${type.value.name}_grid_size', defaultValue: 3);
  }

  void savePreferences() {
    settingsController.preferences
        .put('${type.value.name}_sort_type', currentSort.index);
    settingsController.preferences
        .put('${type.value.name}_sort_order', isAscending);
    settingsController.preferences
        .put('${type.value.name}_grid_size', gridCount.value);

    settingsController.preferences.put('library_last_type', type.value.index);
    settingsController.preferences.put(
        'library_last_list_index_${type.value.name}', selectedListIndex.value);
  }

  void switchCategory(ItemType typ) {
    type.value = typ;

    settingsController.preferences
        .put('library_last_list_index_${type.value.name}', type.value.index);

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
    savePreferences();

    if (index == -1 && type.value.isAnime) {
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
    if (currentSort == sortType) {
      isAscending = !isAscending;
    } else {
      currentSort = sortType;
      isAscending = false;
    }
    savePreferences();
  }

  List<OfflineMedia> applySorting(List<OfflineMedia> items) {
    final sorted = List<OfflineMedia>.from(items);

    sorted.sort((a, b) {
      int comparison = 0;

      switch (currentSort) {
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

      return isAscending ? comparison : -comparison;
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
        return items
            .where((e) => e.currentEpisode?.currentTrack != null)
            .toList();
      }

      if (type.value.isManga) {
        return items.where((e) => e.currentChapter?.link != null).toList();
      }

      if (type.value.isNovel) {
        return items.where((e) => e.currentChapter?.link != null).toList();
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
