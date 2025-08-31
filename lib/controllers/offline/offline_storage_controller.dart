import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/models/Offline/Hive/custom_list.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:get/get.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:hive/hive.dart';
import 'package:anymex/models/Offline/Hive/offline_storage.dart';

class OfflineStorageController extends GetxController {
  var animeLibrary = <OfflineMedia>[].obs;
  var mangaLibrary = <OfflineMedia>[].obs;
  var novelLibrary = <OfflineMedia>[].obs;
  Rx<List<CustomList>> animeCustomLists = Rx([]);
  Rx<List<CustomList>> mangaCustomLists = Rx([]);
  Rx<List<CustomList>> novelCustomLists = Rx([]);
  Rx<List<CustomListData>> animeCustomListData = Rx([]);
  Rx<List<CustomListData>> mangaCustomListData = Rx([]);
  Rx<List<CustomListData>> novelCustomListData = Rx([]);

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
      Logger.i('Error opening Hive box: $e');
    }
  }

  void _loadLibraries() {
    if (_isUpdating) return;

    final offlineStorage =
        _offlineStorageBox.get('storage') ?? OfflineStorage();

    animeLibrary.assignAll(offlineStorage.animeLibrary ?? []);
    mangaLibrary.assignAll(offlineStorage.mangaLibrary ?? []);
    novelLibrary.assignAll(offlineStorage.novelLibrary ?? []);
    animeCustomLists.value
        .assignAll(offlineStorage.animeCustomList ?? [CustomList()]);
    mangaCustomLists.value
        .assignAll(offlineStorage.mangaCustomList ?? [CustomList()]);
    novelCustomLists.value
        .assignAll(offlineStorage.novelCustomList ?? [CustomList()]);

    _refreshListData();
  }

  void _refreshListData() {
    if (_isUpdating) return;

    _removeDuplicateMediaIds();
    _buildCustomListData();
    animeCustomLists.refresh();
    mangaCustomLists.refresh();
    novelCustomLists.refresh();
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

    for (var list in novelCustomLists.value) {
      if (list.mediaIds != null) {
        list.mediaIds = list.mediaIds!.toSet().toList();
        list.mediaIds!.removeWhere((id) => id == '0' || id.isEmpty);
      }
    }
  }

  void _buildCustomListData() {
    mangaCustomListData.value.clear();
    animeCustomListData.value.clear();
    novelCustomListData.value.clear();

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

    for (var customList in novelCustomLists.value) {
      final mediaList = <OfflineMedia>[];

      if (customList.mediaIds != null) {
        for (var mediaId in customList.mediaIds!) {
          final media = getNovelById(mediaId);
          if (media != null) {
            mediaList.add(media);
          }
        }
      }

      novelCustomListData.value.add(CustomListData(
          listData: mediaList,
          listName: customList.listName ?? 'Unnamed List'));
    }
  }

  void addCustomList(String listName, {ItemType mediaType = ItemType.anime}) {
    if (listName.isEmpty) return;

    final targetLists = mediaType == ItemType.anime
        ? animeCustomLists
        : mediaType == ItemType.manga
            ? mangaCustomLists
            : novelCustomLists;

    if (targetLists.value.any((list) => list.listName == listName)) {
      Logger.i('List with name "$listName" already exists');
      return;
    }

    targetLists.value.add(CustomList(listName: listName, mediaIds: []));
    _refreshListData();
    _saveLibraries();
  }

  void removeCustomList(String listName,
      {ItemType mediaType = ItemType.anime}) {
    if (listName.isEmpty) return;

    final targetLists = mediaType == ItemType.anime
        ? animeCustomLists
        : mediaType == ItemType.manga
            ? mangaCustomLists
            : novelCustomLists;
    final beforeLength = targetLists.value.length;
    targetLists.value.removeWhere((e) => e.listName == listName);
    final afterLength = targetLists.value.length;

    if (beforeLength != afterLength) {
      _refreshListData();
      _saveLibraries();
    }
  }

  void renameCustomList(String oldName, String newName,
      {ItemType mediaType = ItemType.anime}) {
    if (oldName.isEmpty || newName.isEmpty || oldName == newName) return;

    final targetLists = mediaType == ItemType.anime
        ? animeCustomLists
        : mediaType == ItemType.manga
            ? mangaCustomLists
            : novelCustomLists;

    if (targetLists.value.any((list) => list.listName == newName)) {
      Logger.i('List with name "$newName" already exists');
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
      {ItemType mediaType = ItemType.anime}) {
    if (listName.isEmpty || mediaId.isEmpty) return;

    final targetLists = mediaType == ItemType.anime
        ? animeCustomLists
        : mediaType == ItemType.manga
            ? mangaCustomLists
            : novelCustomLists;
    final targetList =
        targetLists.value.firstWhereOrNull((list) => list.listName == listName);

    if (targetList != null) {
      Logger.i('Adding Media to List => $listName  $mediaId');
      targetList.mediaIds ??= [];
      targetList.mediaIds!.add(mediaId);
      _refreshListData();
      _saveLibraries();
    }
  }

  void removeMediaFromList(String listName, String mediaId,
      {ItemType mediaType = ItemType.anime}) {
    if (listName.isEmpty || mediaId.isEmpty) return;

    final targetLists = mediaType == ItemType.anime
        ? animeCustomLists
        : mediaType == ItemType.manga
            ? mangaCustomLists
            : novelCustomLists;
    final targetList =
        targetLists.value.firstWhereOrNull((list) => list.listName == listName);

    if (targetList != null && targetList.mediaIds != null) {
      final beforeLength = targetList.mediaIds!.length;
      targetList.mediaIds!.removeWhere((id) => id == mediaId);
      final afterLength = targetList.mediaIds!.length;

      if (mediaType == ItemType.anime) {
        animeLibrary.removeWhere((media) => media.id == mediaId);
      } else if (mediaType == ItemType.manga) {
        mangaLibrary.removeWhere((media) => media.id == mediaId);
      } else if (mediaType == ItemType.novel) {
        novelLibrary.removeWhere((media) => media.id == mediaId);
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
      ItemType mediaType = ItemType.anime}) {
    if (listName.isEmpty) return;

    _isUpdating = true;

    try {
      final targetLists = mediaType == ItemType.anime
          ? animeCustomLists
          : mediaType == ItemType.manga
              ? mangaCustomLists
              : novelCustomLists;
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
      {ItemType mediaType = ItemType.anime}) {
    final sourceData = mediaType == ItemType.anime
        ? animeCustomListData.value
        : mediaType == ItemType.manga
            ? mangaCustomListData.value
            : novelCustomListData.value;

    return sourceData
        .map((listData) => CustomListData(
            listName: listData.listName,
            listData: List<OfflineMedia>.from(listData.listData)))
        .toList();
  }

  void applyCustomListChanges(List<CustomListData> editedData,
      {ItemType mediaType = ItemType.anime}) {
    if (editedData.isEmpty) return;

    _isUpdating = true;

    try {
      final targetList = mediaType == ItemType.anime
          ? animeCustomLists
          : mediaType == ItemType.manga
              ? mangaCustomLists
              : novelCustomLists;
      final targetData = mediaType == ItemType.anime
          ? animeCustomListData
          : mediaType == ItemType.manga
              ? mangaCustomListData
              : novelCustomListData;

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

  List<OfflineMedia> getLibraryFromType(ItemType mediaType) {
    return (mediaType == ItemType.anime
        ? animeLibrary
        : mediaType == ItemType.manga
            ? mangaLibrary
            : novelLibrary);
  }

  List<CustomList> getListFromType(ItemType mediaType) {
    return (mediaType == ItemType.anime
            ? animeCustomLists
            : mediaType == ItemType.manga
                ? mangaCustomLists
                : novelCustomLists)
        .value;
  }

  void addMedia(String listName, Media original, ItemType type) {
    final library = getLibraryFromType(type);

    if (library.firstWhereOrNull((e) => e.id == original.id) == null) {
      if (type == ItemType.manga || type == ItemType.novel) {
        final chapter = Chapter(number: 1);
        library.insert(
            0, _createOfflineMedia(original, null, null, chapter, null));
      } else {
        final episode = Episode(number: '1');
        library.insert(
            0, _createOfflineMedia(original, null, null, null, episode));
      }
    }

    addMediaToList(listName, original.id, mediaType: type);
  }

  void removeMedia(String listName, String id, ItemType type) {
    removeMediaFromList(listName, id, mediaType: type);
  }

  void addOrUpdateAnime(
      Media original, List<Episode>? episodes, Episode? currentEpisode) {
    OfflineMedia? existingAnime = getAnimeById(original.id);

    if (existingAnime != null) {
      existingAnime.episodes = episodes;
      currentEpisode?.source = sourceController.activeSource.value?.name;
      existingAnime.currentEpisode = currentEpisode;

      Logger.i('Updated anime: ${existingAnime.name}');
      animeLibrary.remove(existingAnime);
      animeLibrary.insert(0, existingAnime);
    } else {
      animeLibrary.insert(0,
          _createOfflineMedia(original, null, episodes, null, currentEpisode));
      Logger.i('Added new anime: ${original.title}');
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
      currentChapter?.sourceName =
          sourceController.activeMangaSource.value?.name;
      existingManga.currentChapter = currentChapter;
      Logger.i('Updated manga: ${existingManga.name}');
      mangaLibrary.remove(existingManga);
      mangaLibrary.insert(0, existingManga);
    } else {
      mangaLibrary.insert(0,
          _createOfflineMedia(original, chapters, null, currentChapter, null));
      Logger.i('Added new manga: ${original.title}');
    }

    _saveLibraries();

    if (!_isUpdating) {
      _refreshListData();
    }
  }

  void addOrUpdateNovel(Media original, List<Chapter>? chapters,
      Chapter? currentChapter, Source source) {
    OfflineMedia? existingNovel = getNovelById(original.id);

    if (existingNovel != null) {
      existingNovel.chapters = chapters;
      currentChapter?.sourceName = source.name;
      existingNovel.currentChapter = currentChapter;
      Logger.i('Updated novel: ${existingNovel.name}');
      novelLibrary.remove(existingNovel);
      novelLibrary.insert(0, existingNovel);
    } else {
      novelLibrary.insert(0,
          _createOfflineMedia(original, chapters, null, currentChapter, null));
      Logger.i('Added new novel: ${original.title}');
    }

    _saveLibraries();

    if (!_isUpdating) {
      _refreshListData();
    }
  }

  void addOrUpdateReadChapter(String mangaId, Chapter chapter,
      {Source? source}) {
    OfflineMedia? existingManga = getMangaById(mangaId);
    existingManga ??= getNovelById(mangaId);
    if (existingManga != null) {
      existingManga.readChapters ??= [];
      chapter.sourceName =
          source?.name ?? sourceController.activeMangaSource.value?.name;
      int index = existingManga.readChapters!
          .indexWhere((c) => c.number == chapter.number);

      if (index != -1) {
        chapter.lastReadTime = DateTime.now().millisecondsSinceEpoch;
        existingManga.readChapters![index] = chapter;
        Logger.i(
            'Overwritten chapter: ${chapter.title} for manga ID: $mangaId');
        Logger.i(
            'Page number => ${chapter.pageNumber} / ${chapter.totalPages}');
      } else {
        chapter.lastReadTime = DateTime.now().millisecondsSinceEpoch;
        existingManga.readChapters!.add(chapter);
        Logger.i('Added new chapter: ${chapter.title} for manga ID: $mangaId');
      }
    } else {
      Logger.i(
          'Manga with ID: $mangaId not found. Unable to add/update chapter.');
    }
    _saveLibraries();
  }

  void addOrUpdateNovelChapter(String novelId, Chapter chapter) {
    OfflineMedia? existingNovel = getNovelById(novelId);
    if (existingNovel != null) {
      existingNovel.readChapters ??= [];
      chapter.sourceName = sourceController.activeNovelSource.value?.name;
      int index = existingNovel.readChapters!
          .indexWhere((c) => c.number == chapter.number);

      if (index != -1) {
        chapter.lastReadTime = DateTime.now().millisecondsSinceEpoch;
        existingNovel.readChapters![index] = chapter;
        Logger.i(
            'Overwritten chapter: ${chapter.title} for novel ID: $novelId');
        Logger.i(
            'Page number => ${chapter.pageNumber} / ${chapter.totalPages}');
      } else {
        chapter.lastReadTime = DateTime.now().millisecondsSinceEpoch;
        existingNovel.readChapters!.add(chapter);
        Logger.i('Added new chapter: ${chapter.title} for novel ID: $novelId');
      }
    } else {
      Logger.i(
          'Novel with ID: $novelId not found. Unable to add/update chapter.');
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
        Logger.i(
            'Overwritten episode: ${episode.number} for anime ID: $animeId');
      } else {
        episode.lastWatchedTime = DateTime.now().millisecondsSinceEpoch;
        existingAnime.watchedEpisodes!.add(episode);
        Logger.i('Added new episode: ${episode.title} for anime ID: $animeId');
      }
    } else {
      Logger.i(
          'Anime with ID: $animeId not found. Unable to add/update episode.');
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
        novelLibrary: novelLibrary.toList(),
        animeCustomList: animeCustomLists.value,
        mangaCustomList: mangaCustomLists.value,
        novelCustomList: novelCustomLists.value);

    try {
      _offlineStorageBox.put('storage', updatedStorage);
      Logger.i("Anime/Manga/Novel Successfully Saved!");
    } catch (e) {
      Logger.i('Error saving libraries: $e');
    }
  }

  OfflineMedia? getAnimeById(String id) {
    return animeLibrary.firstWhereOrNull((anime) => anime.id == id);
  }

  OfflineMedia? getMangaById(String id) {
    return mangaLibrary.firstWhereOrNull((manga) => manga.id == id);
  }

  OfflineMedia? getNovelById(String id) {
    return novelLibrary.firstWhereOrNull((novel) => novel.id == id);
  }

  Episode? getWatchedEpisode(String anilistId, String episodeOrChapterNumber) {
    OfflineMedia? anime = getAnimeById(anilistId);
    if (anime != null) {
      Episode? episode = anime.watchedEpisodes
          ?.firstWhereOrNull((e) => e.number == episodeOrChapterNumber);
      if (episode != null) {
        Logger.i("Found Episode! Episode Number is ${episode.number}");
        Logger.i(episode.timeStampInMilliseconds.toString());
        return episode;
      } else {
        Logger.i(
            'No watched episode with number $episodeOrChapterNumber found for anime with ID: $anilistId');
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
        Logger.i(
            'No read chapter with number $number found for manga with ID: $anilistId');
      }
    }
    return null;
  }

  Chapter? getReadNovelChapter(String novelId, double number) {
    OfflineMedia? novel = getNovelById(novelId);
    if (novel != null) {
      Chapter? chapter =
          novel.readChapters?.firstWhereOrNull((c) => c.number == number);
      if (chapter != null) {
        return chapter;
      } else {
        Logger.i(
            'No read chapter with number $number found for novel with ID: $novelId');
      }
    }
    return null;
  }

  List<OfflineMedia> getNovelsFromCustomList(String listName) {
    final customListData = novelCustomListData.value
        .firstWhereOrNull((list) => list.listName == listName);
    return customListData?.listData ?? [];
  }

  double getNovelReadingProgress(String novelId) {
    final novel = getNovelById(novelId);
    if (novel == null || novel.chapters == null || novel.chapters!.isEmpty) {
      return 0.0;
    }

    final totalChapters = novel.chapters!.length;
    final readChapters = novel.readChapters?.length ?? 0;

    return readChapters / totalChapters;
  }

  Chapter? getLatestReadNovelChapter(String novelId) {
    final novel = getNovelById(novelId);
    if (novel?.readChapters == null || novel!.readChapters!.isEmpty) {
      return null;
    }

    novel.readChapters!
        .sort((a, b) => (b.lastReadTime ?? 0).compareTo(a.lastReadTime ?? 0));

    return novel.readChapters!.first;
  }

  void markNovelChapterAsRead(String novelId, double chapterNumber) {
    final novel = getNovelById(novelId);
    if (novel == null) return;

    novel.readChapters ??= [];

    final existingIndex =
        novel.readChapters!.indexWhere((c) => c.number == chapterNumber);

    if (existingIndex != -1) {
      novel.readChapters![existingIndex].lastReadTime =
          DateTime.now().millisecondsSinceEpoch;
    } else {
      final readChapter = Chapter(
        number: chapterNumber,
        lastReadTime: DateTime.now().millisecondsSinceEpoch,
        sourceName: sourceController.activeNovelSource.value?.name,
      );
      novel.readChapters!.add(readChapter);
    }

    _saveLibraries();
    Logger.i('Marked chapter $chapterNumber as read for novel: ${novel.name}');
  }

  Chapter? getNextUnreadNovelChapter(String novelId) {
    final novel = getNovelById(novelId);
    if (novel?.chapters == null || novel!.chapters!.isEmpty) {
      return null;
    }

    final readChapterNumbers =
        novel.readChapters?.map((c) => c.number).toSet() ?? <double>{};

    for (final chapter in novel.chapters!) {
      if (!readChapterNumbers.contains(chapter.number)) {
        return chapter;
      }
    }

    return null;
  }

  bool isNovelChapterRead(String novelId, double chapterNumber) {
    final novel = getNovelById(novelId);
    if (novel?.readChapters == null) return false;

    return novel!.readChapters!
        .any((chapter) => chapter.number == chapterNumber);
  }

  Map<String, dynamic> getNovelStats() {
    final totalNovels = novelLibrary.length;
    final completedNovels = novelLibrary.where((novel) {
      if (novel.chapters == null || novel.chapters!.isEmpty) return false;
      final totalChapters = novel.chapters!.length;
      final readChapters = novel.readChapters?.length ?? 0;
      return readChapters >= totalChapters;
    }).length;

    final readingNovels = novelLibrary.where((novel) {
      final readChapters = novel.readChapters?.length ?? 0;
      return readChapters > 0 && readChapters < (novel.chapters?.length ?? 0);
    }).length;

    return {
      'total': totalNovels,
      'completed': completedNovels,
      'reading': readingNovels,
      'planToRead': totalNovels - completedNovels - readingNovels,
    };
  }

  void clearCache() {
    _offlineStorageBox.clear();
    animeLibrary.clear();
    mangaLibrary.clear();
    novelLibrary.clear();
    animeCustomLists.value.clear();
    mangaCustomLists.value.clear();
    novelCustomLists.value.clear();
    animeCustomListData.value.clear();
    mangaCustomListData.value.clear();
    novelCustomListData.value.clear();
  }
}

class CustomListData {
  String listName;
  List<OfflineMedia> listData;

  CustomListData({required this.listData, required this.listName});
}
