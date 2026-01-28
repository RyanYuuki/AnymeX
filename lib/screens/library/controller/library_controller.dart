import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/utils/extension_utils.dart';
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

  final customListData = <CustomListData>[].obs;
  final initialCustomListData = <CustomListData>[].obs;
  final filteredData = <OfflineMedia>[].obs;
  final historyData = <OfflineMedia>[].obs;

  final customListDataManga = <CustomListData>[].obs;
  final initialCustomListMangaData = <CustomListData>[].obs;
  final filteredDataManga = <OfflineMedia>[].obs;
  final historyDataManga = <OfflineMedia>[].obs;

  final customListNovelData = <CustomListData>[].obs;
  final initialCustomListNovelData = <CustomListData>[].obs;
  final filteredDataNovel = <OfflineMedia>[].obs;
  final historyDataNovel = <OfflineMedia>[].obs;

  SortType currentSort = SortType.lastAdded;
  bool isAscending = false;

  @override
  void onInit() {
    super.onInit();
    initLibraryData();
    getPreferences();

    ever(offlineStorage.animeCustomLists, (_) => initLibraryData());
    ever(offlineStorage.mangaCustomLists, (_) => initLibraryData());
    ever(offlineStorage.novelCustomLists, (_) => initLibraryData());
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void initLibraryData() {
    customListData.value = offlineStorage.animeCustomListData.value
        .map((e) => CustomListData(
              listName: e.listName,
              listData: e.listData.toList(),
            ))
        .toList();

    customListDataManga.value = offlineStorage.mangaCustomListData.value
        .map((e) => CustomListData(
              listName: e.listName,
              listData: e.listData.toList(),
            ))
        .toList();

    customListNovelData.value = offlineStorage.novelCustomListData.value
        .map((e) => CustomListData(
              listName: e.listName,
              listData: e.listData.toList(),
            ))
        .toList();

    historyData.value = offlineStorage.animeLibrary
        .where((e) => e.currentEpisode?.currentTrack != null)
        .toList();
    historyDataManga.value = offlineStorage.mangaLibrary.toList();
    historyDataNovel.value = offlineStorage.novelLibrary.toList();

    initialCustomListData.value = customListData;
    initialCustomListMangaData.value = customListDataManga;
    initialCustomListNovelData.value = customListNovelData;
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

  void search(String val) {
    searchQuery.value = val;
    final currentIndex = selectedListIndex.value;

    if (currentIndex == -1) {
      if (type.value.isAnime) {
        filteredData.value = historyData
            .where((e) =>
                e.name?.toLowerCase().contains(val.toLowerCase()) ?? false)
            .toList();
      } else if (type.value.isManga) {
        filteredDataManga.value = historyDataManga
            .where((e) =>
                e.name?.toLowerCase().contains(val.toLowerCase()) ?? false)
            .toList();
      } else if (type.value.isNovel) {
        filteredDataNovel.value = historyDataNovel
            .where((e) =>
                e.name?.toLowerCase().contains(val.toLowerCase()) ?? false)
            .toList();
      }
      return;
    }

    if (type.value.isAnime) {
      final initialData = customListData[currentIndex].listData;
      filteredData.value = initialData
          .where(
              (e) => e.name?.toLowerCase().contains(val.toLowerCase()) ?? false)
          .toList();
    } else if (type.value.isManga) {
      final initialData = customListDataManga[currentIndex].listData;
      filteredDataManga.value = initialData
          .where(
              (e) => e.name?.toLowerCase().contains(val.toLowerCase()) ?? false)
          .toList();
    } else if (type.value.isNovel) {
      final initialData = customListNovelData[currentIndex].listData;
      filteredDataNovel.value = initialData
          .where(
              (e) => e.name?.toLowerCase().contains(val.toLowerCase()) ?? false)
          .toList();
    }
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
    print(type.value == typ);
  }

  void selectList(int index) {
    selectedListIndex.value = index;
    if (searchQuery.isNotEmpty) {
      searchController.clear();
      searchQuery.value = '';
    }
    savePreferences();
  }

  void toggleSearch() {
    isSearchActive.value = !isSearchActive.value;
    if (!isSearchActive.value) {
      searchController.clear();
      searchQuery.value = '';
    }
  }

  void handleSortChange(SortType sortType) {
    if (currentSort == sortType) {
      isAscending = !isAscending;
    } else {
      currentSort = sortType;
      isAscending = false;
    }
    savePreferences();
    applySorting();
  }

  void applySorting() {
    final lists = typeBuilder(type.value,
        animeValue: customListData,
        mangaValue: customListDataManga,
        novelValue: customListNovelData);

    if (lists.isEmpty || selectedListIndex.value >= lists.length) return;

    final currentList = lists[selectedListIndex.value];
    final initialList = typeBuilder(type.value,
        animeValue: initialCustomListData[selectedListIndex.value],
        mangaValue: initialCustomListMangaData[selectedListIndex.value],
        novelValue: initialCustomListNovelData[selectedListIndex.value]);

    currentList.listData.sort((a, b) {
      int comparison = 0;

      switch (currentSort) {
        case SortType.title:
          comparison = a.name.compareTo(b.name);
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
          break;
      }

      return isAscending ? comparison : -comparison;
    });

    if (currentSort == SortType.lastAdded) {
      if (isAscending) {
        currentList.listData = initialList.listData.reversed.toList();
      } else {
        currentList.listData = initialList.listData;
      }
    }

    if (type.value.isAnime) {
      customListData.refresh();
    } else if (type.value.isManga) {
      customListDataManga.refresh();
    } else if (type.value.isNovel) {
      customListNovelData.refresh();
    }
  }

  dynamic typeBuilder(ItemType type,
      {required dynamic animeValue,
      required dynamic mangaValue,
      required dynamic novelValue}) {
    switch (type) {
      case ItemType.anime:
        return animeValue;
      case ItemType.manga:
        return mangaValue;
      case ItemType.novel:
        return novelValue;
    }
  }

  List<OfflineMedia> getCurrentItems() {
    if (selectedListIndex.value == -1) {
      if (searchQuery.isNotEmpty) {
        return typeBuilder(type.value,
            animeValue: filteredData,
            mangaValue: filteredDataManga,
            novelValue: filteredDataNovel);
      }
      return getHistoryItems();
    }

    final lists = typeBuilder(type.value,
        animeValue: customListData,
        mangaValue: customListDataManga,
        novelValue: customListNovelData);

    if (searchQuery.isNotEmpty) {
      return typeBuilder(type.value,
          animeValue: filteredData,
          mangaValue: filteredDataManga,
          novelValue: filteredDataNovel);
    }

    return lists.isEmpty ? [] : lists[selectedListIndex.value].listData;
  }

  List<OfflineMedia> getHistoryItems() {
    return typeBuilder(type.value,
        animeValue: historyData,
        mangaValue: historyDataManga,
        novelValue: historyDataNovel);
  }

  bool get isListEmpty {
    if (selectedListIndex.value == -1) {
      return getHistoryItems().isEmpty;
    }

    final lists = typeBuilder(type.value,
        animeValue: customListData,
        mangaValue: customListDataManga,
        novelValue: customListNovelData);
    final currentIndex = selectedListIndex.value;
    return lists.isEmpty || lists[currentIndex].listData.isEmpty;
  }
}
