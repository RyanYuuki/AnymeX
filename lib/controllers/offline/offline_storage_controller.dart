import 'dart:developer';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/models/Offline/Hive/custom_list.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:get/get.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:hive/hive.dart';
import 'package:anymex/models/Offline/Hive/offline_storage.dart';

class OfflineStorageController extends GetxController {
  var animeLibrary = <OfflineMedia>[].obs;
  var mangaLibrary = <OfflineMedia>[].obs;
  Rx<List<CustomList>> animeCustomLists = Rx([]);
  Rx<List<CustomList>> mangaCustomLists = Rx([]);
  Rx<List<CustomListData>> animeCustomListData = Rx([]);
  Rx<List<CustomListData>> mangaCustomListData = Rx([]);

  late Box<OfflineStorage> _offlineStorageBox;
  late Box storage;

  bool _isUpdating = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    try {
      _offlineStorageBox = await Hive.openBox<OfflineStorage>('offlineStorage');
      storage = await Hive.openBox('storage');
      _loadLibraries();
    } catch (e) {
      log('Error opening Hive box: $e');
    }
  }

  void _loadLibraries() {
    if (_isUpdating) return;

    final offlineStorage =
        _offlineStorageBox.get('storage') ?? OfflineStorage();

    animeLibrary.assignAll(offlineStorage.animeLibrary ?? []);
    mangaLibrary.assignAll(offlineStorage.mangaLibrary ?? []);
    animeCustomLists.value
        .assignAll(offlineStorage.animeCustomList ?? [CustomList()]);
    mangaCustomLists.value
        .assignAll(offlineStorage.mangaCustomList ?? [CustomList()]);

    _refreshListData();
  }

  void _refreshListData() {
    if (_isUpdating) return;

    _removeDuplicateMediaIds();
    _buildCustomListData();
    animeCustomLists.refresh();
    mangaCustomLists.refresh();
  }

  void _removeDuplicateMediaIds() {
    for (var list in animeCustomLists.value) {
      if (list.mediaIds != null) {
        list.mediaIds = list.mediaIds!.toSet().toList();
        list.mediaIds!.removeWhere((id) => id == '0' || id.isEmpty);
      }
    }

    for (var list in mangaCustomLists.value) {
      if (list.mediaIds != null) {
        list.mediaIds = list.mediaIds!.toSet().toList();
        list.mediaIds!.removeWhere((id) => id == '0' || id.isEmpty);
      }
    }
  }

  void _buildCustomListData() {
    mangaCustomListData.value.clear();
    animeCustomListData.value.clear();

    for (var customList in animeCustomLists.value) {
      final mediaList = <OfflineMedia>[];

      if (customList.mediaIds != null) {
        for (var mediaId in customList.mediaIds!) {
          final media = getAnimeById(mediaId);
          if (media != null) {
            mediaList.add(media);
          }
        }
      }

      animeCustomListData.value.add(CustomListData(
          listData: mediaList,
          listName: customList.listName ?? 'Unnamed List'));
    }

    for (var customList in mangaCustomLists.value) {
      final mediaList = <OfflineMedia>[];

      if (customList.mediaIds != null) {
        for (var mediaId in customList.mediaIds!) {
          final media = getMangaById(mediaId);
          if (media != null) {
            mediaList.add(media);
          }
        }
      }

      mangaCustomListData.value.add(CustomListData(
          listData: mediaList,
          listName: customList.listName ?? 'Unnamed List'));
    }
  }

  void addCustomList(String listName, {MediaType mediaType = MediaType.anime}) {
    if (listName.isEmpty) return;

    final targetLists =
        mediaType == MediaType.anime ? animeCustomLists : mangaCustomLists;

    if (targetLists.value.any((list) => list.listName == listName)) {
      log('List with name "$listName" already exists');
      return;
    }

    targetLists.value.add(CustomList(listName: listName, mediaIds: []));
    _refreshListData();
    _saveLibraries();
  }

  void removeCustomList(String listName,
      {MediaType mediaType = MediaType.anime}) {
    if (listName.isEmpty) return;

    final targetLists =
        mediaType == MediaType.anime ? animeCustomLists : mangaCustomLists;
    final beforeLength = targetLists.value.length;
    targetLists.value.removeWhere((e) => e.listName == listName);
    final afterLength = targetLists.value.length;

    if (beforeLength != afterLength) {
      _refreshListData();
      _saveLibraries();
    }
  }

  void renameCustomList(String oldName, String newName,
      {MediaType mediaType = MediaType.anime}) {
    if (oldName.isEmpty || newName.isEmpty || oldName == newName) return;

    final targetLists =
        mediaType == MediaType.anime ? animeCustomLists : mangaCustomLists;

    if (targetLists.value.any((list) => list.listName == newName)) {
      log('List with name "$newName" already exists');
      return;
    }

    final listToRename =
        targetLists.value.firstWhereOrNull((list) => list.listName == oldName);
    if (listToRename != null) {
      listToRename.listName = newName;
      _refreshListData();
      _saveLibraries();
    }
  }

  void addMediaToList(String listName, String mediaId,
      {MediaType mediaType = MediaType.anime}) {
    if (listName.isEmpty || mediaId.isEmpty) return;

    final targetLists =
        mediaType == MediaType.anime ? animeCustomLists : mangaCustomLists;
    final targetList =
        targetLists.value.firstWhereOrNull((list) => list.listName == listName);

    if (targetList != null) {
      log('Adding Media to List => $listName  $mediaId');
      targetList.mediaIds ??= [];
      targetList.mediaIds!.add(mediaId);
      _refreshListData();
      _saveLibraries();
    }
  }

  void removeMediaFromList(String listName, String mediaId,
      {MediaType mediaType = MediaType.anime}) {
    if (listName.isEmpty || mediaId.isEmpty) return;

    final targetLists =
        mediaType == MediaType.anime ? animeCustomLists : mangaCustomLists;
    final targetList =
        targetLists.value.firstWhereOrNull((list) => list.listName == listName);

    if (targetList != null && targetList.mediaIds != null) {
      final beforeLength = targetList.mediaIds!.length;
      targetList.mediaIds!.removeWhere((id) => id == mediaId);
      final afterLength = targetList.mediaIds!.length;

      if (mediaType == MediaType.anime) {
        animeLibrary.removeWhere((media) => media.id == mediaId);
      } else {
        mangaLibrary.removeWhere((media) => media.id == mediaId);
      }

      if (beforeLength != afterLength) {
        _refreshListData();
        _saveLibraries();
      }
    }
  }

  void batchUpdateCustomList(
      {required String listName,
      String? newListName,
      List<String>? mediaIds,
      MediaType mediaType = MediaType.anime}) {
    if (listName.isEmpty) return;

    _isUpdating = true;

    try {
      final targetLists =
          mediaType == MediaType.anime ? animeCustomLists : mangaCustomLists;
      final targetList = targetLists.value
          .firstWhereOrNull((list) => list.listName == listName);

      if (targetList != null) {
        if (newListName != null &&
            newListName.isNotEmpty &&
            newListName != listName) {
          if (!targetLists.value.any((list) => list.listName == newListName)) {
            targetList.listName = newListName;
          }
        }

        if (mediaIds != null) {
          targetList.mediaIds = mediaIds
              .where((id) => id.isNotEmpty && id != '0')
              .toSet()
              .toList();
        }

        _refreshListData();
        _saveLibraries();
      }
    } finally {
      _isUpdating = false;
    }
  }

  List<CustomListData> getEditableCustomListData(
      {MediaType mediaType = MediaType.anime}) {
    final sourceData = mediaType == MediaType.anime
        ? animeCustomListData.value
        : mangaCustomListData.value;

    return sourceData
        .map((listData) => CustomListData(
            listName: listData.listName,
            listData: List<OfflineMedia>.from(listData.listData)))
        .toList();
  }

  void applyCustomListChanges(List<CustomListData> editedData,
      {MediaType mediaType = MediaType.anime}) {
    if (editedData.isEmpty) return;

    _isUpdating = true;

    try {
      final targetList =
          mediaType == MediaType.anime ? animeCustomLists : mangaCustomLists;
      final targetData = mediaType == MediaType.anime
          ? animeCustomListData
          : mangaCustomListData;

      final newLists = <CustomList>[];

      for (var listData in editedData) {
        final mediaIds = listData.listData
            .map((media) => media.id ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        newLists
            .add(CustomList(listName: listData.listName, mediaIds: mediaIds));
      }

      targetList.value = newLists;
      targetData.value = editedData;

      targetList.refresh();
      targetData.refresh();
      _saveLibraries();
    } finally {
      _isUpdating = false;
    }
  }

  void addMedia(String listName, Media original, bool isManga) {
    final mediaType = isManga ? MediaType.manga : MediaType.anime;
    final library = isManga ? mangaLibrary : animeLibrary;

    if (library.firstWhereOrNull((e) => e.id == original.id) == null) {
      if (isManga) {
        final chapter = Chapter(number: 1);
        library.insert(
            0, _createOfflineMedia(original, null, null, chapter, null));
      } else {
        final episode = Episode(number: '1');
        library.insert(
            0, _createOfflineMedia(original, null, null, null, episode));
      }
    }

    addMediaToList(listName, original.id, mediaType: mediaType);
  }

  void removeMedia(String listName, String id, bool isManga) {
    final mediaType = isManga ? MediaType.manga : MediaType.anime;
    removeMediaFromList(listName, id, mediaType: mediaType);
  }

  void addOrUpdateAnime(
      Media original, List<Episode>? episodes, Episode? currentEpisode) {
    OfflineMedia? existingAnime = getAnimeById(original.id);

    if (existingAnime != null) {
      existingAnime.episodes = episodes;
      currentEpisode?.source = sourceController.activeSource.value?.name;
      existingAnime.currentEpisode = currentEpisode;

      log('Updated anime: ${existingAnime.name}');
      animeLibrary.remove(existingAnime);
      animeLibrary.insert(0, existingAnime);
    } else {
      animeLibrary.insert(0,
          _createOfflineMedia(original, null, episodes, null, currentEpisode));
      log('Added new anime: ${original.title}');
    }

    _saveLibraries();

    if (!_isUpdating) {
      _refreshListData();
    }
  }

  void addOrUpdateManga(
      Media original, List<Chapter>? chapters, Chapter? currentChapter) {
    OfflineMedia? existingManga = getMangaById(original.id);

    if (existingManga != null) {
      existingManga.chapters = chapters;
      currentChapter?.sourceName = sourceController.activeSource.value?.name;
      existingManga.currentChapter = currentChapter;
      log('Updated manga: ${existingManga.name}');
      mangaLibrary.remove(existingManga);
      mangaLibrary.insert(0, existingManga);
    } else {
      mangaLibrary.insert(0,
          _createOfflineMedia(original, chapters, null, currentChapter, null));
      log('Added new manga: ${original.title}');
    }

    _saveLibraries();

    if (!_isUpdating) {
      _refreshListData();
    }
  }

  void addOrUpdateReadChapter(String mangaId, Chapter chapter) {
    OfflineMedia? existingManga = getMangaById(mangaId);
    if (existingManga != null) {
      existingManga.readChapters ??= [];
      chapter.sourceName = sourceController.activeMangaSource.value?.name;
      int index = existingManga.readChapters!
          .indexWhere((c) => c.number == chapter.number);

      if (index != -1) {
        chapter.lastReadTime = DateTime.now().millisecondsSinceEpoch;
        existingManga.readChapters![index] = chapter;
        log('Overwritten chapter: ${chapter.title} for manga ID: $mangaId');
        log('Page number => ${chapter.pageNumber} / ${chapter.totalPages}');
      } else {
        chapter.lastReadTime = DateTime.now().millisecondsSinceEpoch;
        existingManga.readChapters!.add(chapter);
        log('Added new chapter: ${chapter.title} for manga ID: $mangaId');
      }
    } else {
      log('Manga with ID: $mangaId not found. Unable to add/update chapter.');
    }
    _saveLibraries();
  }

  void addOrUpdateWatchedEpisode(String animeId, Episode episode) {
    OfflineMedia? existingAnime = getAnimeById(animeId);
    if (existingAnime != null) {
      existingAnime.watchedEpisodes ??= [];
      int index = existingAnime.watchedEpisodes!
          .indexWhere((e) => e.number == episode.number);
      episode.source = sourceController.activeSource.value?.name;

      if (index != -1) {
        episode.lastWatchedTime = DateTime.now().millisecondsSinceEpoch;
        existingAnime.watchedEpisodes![index] = episode;
        log('Overwritten episode: ${episode.number} for anime ID: $animeId');
      } else {
        episode.lastWatchedTime = DateTime.now().millisecondsSinceEpoch;
        existingAnime.watchedEpisodes!.add(episode);
        log('Added new episode: ${episode.title} for anime ID: $animeId');
      }
    } else {
      log('Anime with ID: $animeId not found. Unable to add/update episode.');
    }
    _saveLibraries();
  }

  OfflineMedia _createOfflineMedia(
      Media original,
      List<Chapter>? chapters,
      List<Episode>? episodes,
      Chapter? currentChapter,
      Episode? currentEpisode) {
    final handler = Get.find<ServiceHandler>();
    return OfflineMedia(
        id: original.id,
        jname: original.romajiTitle,
        name: original.title,
        english: original.title,
        japanese: original.romajiTitle,
        description: original.description,
        poster: original.poster,
        cover: original.cover,
        totalEpisodes: original.totalEpisodes,
        type: original.type,
        season: original.season,
        premiered: original.premiered,
        duration: original.duration,
        status: original.status,
        rating: original.rating,
        popularity: original.popularity,
        format: original.format,
        aired: original.aired,
        totalChapters: original.totalChapters,
        genres: original.genres,
        studios: original.studios,
        chapters: chapters,
        episodes: episodes,
        currentEpisode: currentEpisode,
        currentChapter: currentChapter,
        watchedEpisodes: episodes ?? [],
        readChapters: chapters ?? [],
        serviceIndex: handler.serviceType.value.index);
  }

  void _saveLibraries() {
    if (_isUpdating) return;

    final updatedStorage = OfflineStorage(
        animeLibrary: animeLibrary.toList(),
        mangaLibrary: mangaLibrary.toList(),
        animeCustomList: animeCustomLists.value,
        mangaCustomList: mangaCustomLists.value);

    try {
      _offlineStorageBox.put('storage', updatedStorage);
      log("Anime/Manga Successfully Saved!");
    } catch (e) {
      log('Error saving libraries: $e');
    }
  }

  OfflineMedia? getAnimeById(String id) {
    return animeLibrary.firstWhereOrNull((anime) => anime.id == id);
  }

  OfflineMedia? getMangaById(String id) {
    return mangaLibrary.firstWhereOrNull((manga) => manga.id == id);
  }

  Episode? getWatchedEpisode(String anilistId, String episodeOrChapterNumber) {
    OfflineMedia? anime = getAnimeById(anilistId);
    if (anime != null) {
      Episode? episode = anime.watchedEpisodes
          ?.firstWhereOrNull((e) => e.number == episodeOrChapterNumber);
      if (episode != null) {
        log("Found Episode! Episode Number is ${episode.number}");
        log(episode.timeStampInMilliseconds.toString());
        return episode;
      } else {
        log('No watched episode with number $episodeOrChapterNumber found for anime with ID: $anilistId');
        return null;
      }
    }
    return null;
  }

  Chapter? getReadChapter(String anilistId, double number) {
    OfflineMedia? manga = getMangaById(anilistId);
    if (manga != null) {
      Chapter? chapter =
          manga.readChapters?.firstWhereOrNull((c) => c.number == number);
      if (chapter != null) {
        return chapter;
      } else {
        log('No read chapter with number $number found for manga with ID: $anilistId');
      }
    }
    return null;
  }

  void clearCache() {
    _offlineStorageBox.clear();
    animeLibrary.clear();
    mangaLibrary.clear();
    animeCustomLists.value.clear();
    mangaCustomLists.value.clear();
    animeCustomListData.value.clear();
    mangaCustomListData.value.clear();
  }
}

class CustomListData {
  String listName;
  List<OfflineMedia> listData;

  CustomListData({required this.listData, required this.listName});
}
