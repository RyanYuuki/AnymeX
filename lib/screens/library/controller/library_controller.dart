import 'dart:async';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/database/isar_models/custom_list.dart';
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
  popularity,
  progress,
  aired,
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

  StreamSubscription? _streamSubscription;
  StreamSubscription? _customListsSubscription;
  final rawItems = <OfflineMedia>[].obs;
  final customListNames = <String>[].obs;
  final customLists = <CustomList>[].obs;
  final isLoading = false.obs;

  bool _isSwitchingCategory = false;
  late bool _isUnified;

  List<OfflineMedia> get processedItems {
    final searched = applySearch(rawItems, searchQuery.value);
    return applySorting(searched);
  }

  @override
  void onInit() {
    super.onInit();
    _migrateGridDefaultToAuto();
    _isUnified = General.unifiedLibrary.get<bool>(true);
    getPreferences();
    
    ever(type, (_) {
      if (!_isSwitchingCategory) {
        _setupCustomListsSubscription();
      }
    });
    ever(selectedListIndex, (_) {
      if (!_isSwitchingCategory) {
        _updateSourceStream();
      }
    });
    ever(serviceHandler.serviceType, (_) {
      if (!_isSwitchingCategory) {
        _updateSourceStream();
      }
    });
    
    _setupCustomListsSubscription();
  }

  void _setupCustomListsSubscription() {
    _customListsSubscription?.cancel();
    _customListsSubscription = offlineStorage.watchCustomLists(type.value).listen((lists) {
      final filteredLists = lists
          .where((l) => l.mediaTypeIndex == type.value.index)
          .toList();
      customLists.value = filteredLists;
      customListNames.value = filteredLists.map((l) => l.listName ?? '').toList();
      
      if (selectedListIndex.value != -1) {
        if (customListNames.isEmpty) {
          selectedListIndex.value = 0;
        } else if (selectedListIndex.value >= customListNames.length) {
          selectedListIndex.value = customListNames.length - 1;
        }
      }
      
      if (!_isSwitchingCategory) {
        _updateSourceStream();
      }
    });
  }

  Future<void> _updateSourceStream() async {
    _streamSubscription?.cancel();
    isLoading.value = true;
    rawItems.value = [];

    if (selectedListIndex.value != -1) {
      if (customListNames.isEmpty || selectedListIndex.value >= customListNames.length) {
        rawItems.clear();
        isLoading.value = false;
        return;
      }
    }

    Stream<List<OfflineMedia>> stream;
    if (selectedListIndex.value == -1) {
      stream = getLibraryStream();
    } else {
      final selectedListName = customListNames[selectedListIndex.value];
      stream = getCustomListStream(selectedListName, type.value);
    }

    _streamSubscription = stream.listen((items) {
      if (selectedListIndex.value == -1) {
        List<OfflineMedia> filtered;
        if (type.value.isAnime) {
          filtered = items
              .where((e) => e.currentEpisode?.currentTrack != null)
              .toList();
        } else {
          filtered = items
              .where((e) => e.currentChapter?.link != null)
              .toList();
        }
        rawItems.value = filtered;
      } else {
        rawItems.value = items;
      }
      isLoading.value = false;
    }, onError: (e) {
      isLoading.value = false;
    });
  }

  @override
  void onClose() {
    _streamSubscription?.cancel();
    _customListsSubscription?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void _migrateGridDefaultToAuto() {
    final migrated = General.libraryGridAutoMigrated.get<bool>(false);
    if (migrated) return;

    for (final mediaType in ItemType.values) {
      DynamicKeys.libraryGridSize.set(mediaType.name, 0);
    }

    General.libraryGridAutoMigrated.set(true);
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
    final isHistory = selectedListIndex.value == -1;
    final prefix = isHistory ? '${type.value.name}_history' : type.value.name;
    final defaultSort = isHistory ? SortType.lastRead.index : SortType.lastAdded.index;

    final savedSortIndex = DynamicKeys.librarySortType.get<int>(prefix, defaultSort);
    var loadedSort = SortType.values[savedSortIndex.clamp(0, SortType.values.length - 1)];

    if (isHistory && (loadedSort == SortType.lastAdded || loadedSort == SortType.aired || loadedSort == SortType.popularity)) {
      loadedSort = SortType.lastRead;
    }

    currentSort.value = loadedSort;
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
    if (type.value == typ) return;

    _isSwitchingCategory = true;
    Future.microtask(savePreferences);

    type.value = typ;

    final savedListIndex =
        DynamicKeys.libraryLastListIndex.get<int>(type.value.name, 0);
    selectedListIndex.value = savedListIndex;
    gridCount.value = DynamicKeys.libraryGridSize.get<int>(type.value.name, 0);

    if (searchQuery.isNotEmpty) {
      searchController.clear();
      searchQuery.value = '';
    }
    _loadSortPrefs();
    _isSwitchingCategory = false;

    _setupCustomListsSubscription();
    _updateSourceStream();

    Future.microtask(savePreferences);
  }

  void selectList(int index) {
    if (selectedListIndex.value == index) return;
    _isSwitchingCategory = true;
    selectedListIndex.value = index;
    if (searchQuery.isNotEmpty) {
      searchController.clear();
      searchQuery.value = '';
    }
    _loadSortPrefs();
    _isSwitchingCategory = false;

    _updateSourceStream();
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
          comparison = a.id.compareTo(b.id);
          break;
        case SortType.popularity:
          final aPop = double.tryParse(a.popularity ?? '0.0') ?? 0.0;
          final bPop = double.tryParse(b.popularity ?? '0.0') ?? 0.0;
          comparison = aPop.compareTo(bPop);
          break;
        case SortType.progress:
          final aProg = type.value.isAnime
              ? (a.watchedEpisodes?.length ?? 0)
              : (a.readChapters?.length ?? 0);
          final bProg = type.value.isAnime
              ? (b.watchedEpisodes?.length ?? 0)
              : (b.readChapters?.length ?? 0);
          comparison = aProg.compareTo(bProg);
          break;
        case SortType.aired:
          comparison = (a.aired ?? '').compareTo(b.aired ?? '');
          break;
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

  List<OfflineMedia> _filterByService(List<OfflineMedia> items) {
    if (_isUnified) return items;
    final currentServiceIndex = serviceHandler.serviceType.value.index;
    return items
        .where((e) => e.serviceIndex == null || e.serviceIndex == currentServiceIndex)
        .toList();
  }

  Stream<List<OfflineMedia>> getLibraryStream() {
    Stream<List<OfflineMedia>> rawStream;
    switch (type.value) {
      case ItemType.anime:
        rawStream = offlineStorage.watchAnimeLibrary();
        break;
      case ItemType.manga:
        rawStream = offlineStorage.watchMangaLibrary();
        break;
      case ItemType.novel:
        rawStream = offlineStorage.watchNovelLibrary();
        break;
    }
    return rawStream.map((items) => _filterByService(items));
  }

  Stream<List<OfflineMedia>> getHistoryStream() {
    return getLibraryStream().asyncMap((items) async {
      List<OfflineMedia> filtered;
      if (type.value.isAnime) {
        filtered = items
            .where((e) => e.currentEpisode?.currentTrack != null)
            .toList();
      } else {
        filtered = items.where((e) => e.currentChapter?.link != null).toList();
      }
      final searched = applySearch(filtered, searchQuery.value);
      return applySorting(searched);
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
        .map((data) => _filterByService(data.listData));
  }

  Stream<List<OfflineMedia>> getProcessedCustomListStream(
      String listName, ItemType type) {
    return getCustomListStream(listName, type).asyncMap((items) async {
      final searched = applySearch(items, searchQuery.value);
      return applySorting(searched);
    });
  }
}
