import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/custom_list.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/main.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';

enum MediaLibraryType {
  anime,
  manga,
  novel,
}

class OfflineStorageController extends GetxController {
  Stream<List<OfflineMedia>> watchAnimeLibrary() {
    return isar.offlineMedias
        .filter()
        .mediaTypeIndexEqualTo(1)
        .watch(fireImmediately: true);
  }

  Stream<List<OfflineMedia>> watchMangaLibrary() {
    return isar.offlineMedias
        .filter()
        .mediaTypeIndexEqualTo(0)
        .watch(fireImmediately: true);
  }

  Stream<List<OfflineMedia>> watchNovelLibrary() {
    return isar.offlineMedias
        .filter()
        .mediaTypeIndexEqualTo(2)
        .watch(fireImmediately: true);
  }

  Stream<OfflineMedia?> watchMediaById(String mediaId) {
    return isar.offlineMedias
        .filter()
        .mediaIdEqualTo(mediaId)
        .watch(fireImmediately: true)
        .map((list) => list.isNotEmpty ? list.first : null);
  }

  Stream<List<CustomList>> watchCustomLists(ItemType mediaType) {
    return isar.customLists.where().watch(fireImmediately: true);
  }

  Stream<CustomListData> watchCustomListData(
      String listName, ItemType mediaType) async* {
    await for (final customList in isar.customLists
        .filter()
        .listNameEqualTo(listName)
        .and()
        .mediaTypeIndexEqualTo(mediaType.index)
        .watch(fireImmediately: true)) {
      if (customList.isEmpty) {
        yield CustomListData(listName: listName, listData: []);
        continue;
      }

      final list = customList.first;
      final mediaIds = list.mediaIds ?? [];

      if (mediaIds.isEmpty) {
        yield CustomListData(listName: listName, listData: []);
        continue;
      }

      final mediaItems = await isar.offlineMedias
          .filter()
          .anyOf(
              mediaIds,
              (q, String id) => q
                  .mediaIdEqualTo(id)
                  .and()
                  .mediaTypeIndexEqualTo(mediaType.index))
          .findAll();

      yield CustomListData(
        listName: listName,
        listData: mediaItems,
      );
    }
  }

  Future<List<OfflineMedia>> getAnimeLibrary(
      {int offset = 0, int limit = 50}) async {
    return await isar.offlineMedias
        .filter()
        .mediaTypeIndexEqualTo(1)
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  Future<List<OfflineMedia>> getMangaLibrary(
      {int offset = 0, int limit = 50}) async {
    return await isar.offlineMedias
        .filter()
        .mediaTypeIndexEqualTo(0)
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  Future<List<OfflineMedia>> getNovelLibrary(
      {int offset = 0, int limit = 50}) async {
    return await isar.offlineMedias
        .filter()
        .mediaTypeIndexEqualTo(2)
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  Future<List<OfflineMedia>> getLibraryFromType(
    ItemType mediaType, {
    int offset = 0,
    int limit = 50,
  }) async {
    return await isar.offlineMedias
        .filter()
        .mediaTypeIndexEqualTo(mediaType.index)
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  Future<List<CustomList>> getCustomListsFromType(ItemType type) async {
    return await isar.customLists
        .filter()
        .mediaTypeIndexEqualTo(type.index)
        .findAll();
  }

  Future<List<OfflineMedia>> searchMedia(
    String query,
    ItemType mediaType,
  ) async {
    return await isar.offlineMedias
        .filter()
        .mediaTypeIndexEqualTo(mediaType.index)
        .group((q) => q
            .nameContains(query, caseSensitive: false)
            .or()
            .jnameContains(query, caseSensitive: false)
            .or()
            .englishContains(query, caseSensitive: false))
        .findAll();
  }

  OfflineMedia? getMediaById(String mediaId) {
    return isar.offlineMedias.filter().mediaIdEqualTo(mediaId).findFirstSync();
  }

  OfflineMedia? getAnimeById(String id) => getMediaById(id);
  OfflineMedia? getMangaById(String id) => getMediaById(id);
  OfflineMedia? getNovelById(String id) => getMediaById(id);

  Future<bool> clearMediaHistory(
    String mediaId, {
    required ItemType mediaType,
  }) async {
    if (mediaId.isEmpty) return false;

    final media = getMediaById(mediaId);
    if (media == null || media.mediaTypeIndex != mediaType.index) {
      return false;
    }

    final hadHistory = mediaType == ItemType.anime
        ? media.currentEpisode != null
        : media.currentChapter != null;
    if (!hadHistory) return false;

    await isar.writeTxn(() async {
      if (mediaType == ItemType.anime) {
        media.currentEpisode = null;
      } else {
        media.currentChapter = null;
      }
      await isar.offlineMedias.put(media);
    });

    return true;
  }

  Future<int> clearMediaHistoryBulk(
    Iterable<String> mediaIds, {
    required ItemType mediaType,
  }) async {
    final ids = mediaIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return 0;

    final mediaItems = ids
        .map(getMediaById)
        .whereType<OfflineMedia>()
        .where((media) => media.mediaTypeIndex == mediaType.index)
        .toList();
    if (mediaItems.isEmpty) return 0;

    var clearedCount = 0;
    await isar.writeTxn(() async {
      for (final media in mediaItems) {
        final hasHistory = mediaType == ItemType.anime
            ? media.currentEpisode != null
            : media.currentChapter != null;
        if (!hasHistory) continue;

        if (mediaType == ItemType.anime) {
          media.currentEpisode = null;
        } else {
          media.currentChapter = null;
        }

        await isar.offlineMedias.put(media);
        clearedCount++;
      }
    });

    return clearedCount;
  }

  Future<List<CustomList>> getCustomListsByType(ItemType type) async {
    return await isar.customLists
        .filter()
        .mediaTypeIndexEqualTo(type.index)
        .findAll();
  }

  Future<CustomList?> getCustomListByName(String listName,
      {ItemType? mediaType}) async {
    var query = isar.customLists.filter().listNameEqualTo(listName);
    if (mediaType != null) {
      return await query.mediaTypeIndexEqualTo(mediaType.index).findFirst();
    }
    return await query.findFirst();
  }

  Future<void> addCustomList(String listName,
      {ItemType mediaType = ItemType.anime}) async {
    if (listName.isEmpty) return;

    final existing = await getCustomListByName(listName, mediaType: mediaType);
    if (existing != null) {
      Logger.i('List with name "$listName" already exists');
      return;
    }

    await isar.writeTxn(() async {
      await isar.customLists.put(CustomList(
        listName: listName,
        mediaIds: [],
        mediaTypeIndex: mediaType.index,
      ));
    });

    Logger.i('Created custom list: $listName');
  }

  Future<void> removeCustomList(String listName,
      {required ItemType mediaType}) async {
    if (listName.isEmpty) return;

    final list = await getCustomListByName(listName, mediaType: mediaType);
    if (list == null) return;

    await isar.writeTxn(() async {
      await isar.customLists.delete(list.id);
    });

    Logger.i('Removed custom list: $listName');
  }

  Future<void> renameCustomList(String oldName, String newName,
      {required ItemType mediaType}) async {
    if (oldName.isEmpty || newName.isEmpty || oldName == newName) return;

    final existing = await getCustomListByName(newName, mediaType: mediaType);
    if (existing != null) {
      Logger.i('List with name "$newName" already exists');
      return;
    }

    final list = await getCustomListByName(oldName, mediaType: mediaType);
    if (list == null) return;

    await isar.writeTxn(() async {
      list.listName = newName;
      await isar.customLists.put(list);
    });

    Logger.i('Renamed list: $oldName -> $newName');
  }

  Future<void> addMediaToList(String listName, String mediaId,
      {ItemType? mediaType}) async {
    if (listName.isEmpty || mediaId.isEmpty) return;

    final list = await getCustomListByName(listName, mediaType: mediaType);
    if (list == null) {
      Logger.i('List not found: $listName');
      return;
    }

    await isar.writeTxn(() async {
      list.mediaIds = List<String>.from(list.mediaIds ?? []);
      if (!list.mediaIds!.contains(mediaId)) {
        list.mediaIds!.add(mediaId);
        await isar.customLists.put(list);
        Logger.i('Added media $mediaId to list $listName');
      }
    });
  }

  Future<void> removeMediaFromList(
    String listName,
    String mediaId, {
    ItemType? mediaType,
  }) async {
    if (listName.isEmpty || mediaId.isEmpty) return;

    final list = await getCustomListByName(listName, mediaType: mediaType);
    if (list == null) return;

    await isar.writeTxn(() async {
      list.mediaIds = List<String>.from(list.mediaIds ?? []);
      list.mediaIds!.remove(mediaId);
      await isar.customLists.put(list);
      Logger.i('Removed media $mediaId from list $listName');
    });
  }

  Future<List<OfflineMedia>> getMediaFromCustomList(String listName,
      {ItemType? mediaType}) async {
    final list = await getCustomListByName(listName, mediaType: mediaType);
    if (list == null || list.mediaIds == null || list.mediaIds!.isEmpty) {
      return [];
    }

    return await isar.offlineMedias
        .filter()
        .anyOf(list.mediaIds!, (q, String id) => q.mediaIdEqualTo(id))
        .findAll();
  }

  Future<void> addMediaToLibrary(OfflineMedia original) async {
    final existing = getMediaById(original.mediaId ?? "");

    if (existing != null) return;

    await isar.writeTxn(() async {
      await isar.offlineMedias.put(original);
    });
  }

  Future<void> addMedia(String listName, Media original) async {
    final type = original.mediaType;
    final existing = getMediaById(original.id);

    if (existing == null) {
      await isar.writeTxn(() async {
        if (type == ItemType.manga || type == ItemType.novel) {
          final chapter = Chapter(number: 1);
          await isar.offlineMedias.put(
            _createOfflineMedia(original, null, null, chapter, null),
          );
        } else {
          final episode = Episode(number: '1');
          await isar.offlineMedias.put(
            _createOfflineMedia(original, null, null, null, episode),
          );
        }
      });
    }

    await addMediaToList(listName, original.id, mediaType: type);
  }

  Future<void> removeMedia(String listName, Media original) async {
    await removeMediaFromList(listName, original.id,
        mediaType: original.mediaType);
  }

  Future<void> addOrUpdateAnime(
    Media original,
    List<Episode>? episodes,
    Episode? currentEpisode,
  ) async {
    final existingAnime = getAnimeById(original.id);

    await isar.writeTxn(() async {
      if (existingAnime != null) {
        existingAnime.episodes = episodes;
        if (currentEpisode != null) {
          currentEpisode.source = sourceController.activeSource.value?.name;
        }
        existingAnime.currentEpisode = currentEpisode;
        await isar.offlineMedias.put(existingAnime);
        Logger.i('Updated anime: ${existingAnime.name}');
      } else {
        await isar.offlineMedias.put(
          _createOfflineMedia(original, null, episodes, null, currentEpisode),
        );
        Logger.i('Added new anime: ${original.title}');
      }
    });
  }

  Future<void> addOrUpdateManga(
    Media original,
    List<Chapter>? chapters,
    Chapter? currentChapter,
  ) async {
    final existingManga = getMangaById(original.id);

    await isar.writeTxn(() async {
      if (existingManga != null) {
        existingManga.chapters = chapters;
        if (currentChapter != null) {
          currentChapter.sourceName =
              sourceController.activeMangaSource.value?.name;
        }
        existingManga.currentChapter = currentChapter;
        await isar.offlineMedias.put(existingManga);
        Logger.i('Updated manga: ${existingManga.name}');
      } else {
        await isar.offlineMedias.put(
          _createOfflineMedia(original, chapters, null, currentChapter, null),
        );
        Logger.i('Added new manga: ${original.title}');
      }
    });
  }

  Future<void> addOrUpdateNovel(
    Media original,
    List<Chapter>? chapters,
    Chapter? currentChapter,
    Source source,
  ) async {
    final existingNovel = getNovelById(original.id);

    await isar.writeTxn(() async {
      if (existingNovel != null) {
        existingNovel.chapters = chapters;
        if (currentChapter != null) {
          currentChapter.sourceName = source.name;
        }
        existingNovel.currentChapter = currentChapter;
        await isar.offlineMedias.put(existingNovel);
        Logger.i('Updated novel: ${existingNovel.name}');
      } else {
        await isar.offlineMedias.put(
          _createOfflineMedia(original, chapters, null, currentChapter, null),
        );
        Logger.i('Added new novel: ${original.title}');
      }
    });
  }

  Future<void> addOrUpdateWatchedEpisode(
      String animeId, Episode episode) async {
    final existingAnime = getAnimeById(animeId);
    if (existingAnime == null) {
      Logger.i(
          'Anime with ID: $animeId not found. Unable to add/update episode.');
      return;
    }

    await isar.writeTxn(() async {
      existingAnime.watchedEpisodes ??= [];
      episode.source = sourceController.activeSource.value?.name;
      episode.lastWatchedTime = DateTime.now().millisecondsSinceEpoch;

      final index = existingAnime.watchedEpisodes!
          .indexWhere((e) => e.number == episode.number);
      existingAnime.watchedEpisodes =
          List<Episode>.from(existingAnime.watchedEpisodes!);

      if (index != -1) {
        existingAnime.watchedEpisodes![index] = episode;
        Logger.i(
            'Overwritten episode: ${episode.number} for anime ID: $animeId with source => ${episode.source}');
      } else {
        existingAnime.watchedEpisodes!.add(episode);
        Logger.i('Added new episode: ${episode.title} for anime ID: $animeId');
      }

      existingAnime.currentEpisode = episode;

      await isar.offlineMedias.put(existingAnime);
    });

    // Sync progress with AniList/MyAnimeList
    final syncCtrl = Get.find<ServiceHandler>().syncController;
    if (syncCtrl != null) {
      await syncCtrl.pushEpisodeProgress(animeId, episode.number);
    }
  }

  Episode? getWatchedEpisode(String anilistId, String episodeNumber) {
    final anime = getAnimeById(anilistId);
    if (anime?.watchedEpisodes == null) return null;

    return anime!.watchedEpisodes!
        .firstWhereOrNull((e) => e.number == episodeNumber);
  }

  Future<void> addOrUpdateReadChapter(
    String mangaId,
    Chapter chapter, {
    Source? source,
  }) async {
    print(chapter.toJson());
    OfflineMedia? existingManga = getMangaById(mangaId);
    existingManga ??= getNovelById(mangaId);

    if (existingManga == null) {
      Logger.i(
          'Manga with ID: $mangaId not found. Unable to add/update chapter.');
      return;
    }

    await isar.writeTxn(() async {
      existingManga!.readChapters ??= [];
      chapter.sourceName =
          source?.name ?? sourceController.activeMangaSource.value?.name;
      chapter.lastReadTime = DateTime.now().millisecondsSinceEpoch;

      final index = existingManga.readChapters!
          .indexWhere((c) => c.number == chapter.number);
      existingManga.readChapters =
          List<Chapter>.from(existingManga.readChapters!);
      if (index != -1) {
        existingManga.readChapters![index] = chapter;
        Logger.i(
            'Overwritten chapter: ${chapter.title} for manga ID: $mangaId');
      } else {
        existingManga.readChapters!.add(chapter);
        Logger.i('Added new chapter: ${chapter.title} for manga ID: $mangaId');
      }

      existingManga.currentChapter = chapter;

      await isar.offlineMedias.put(existingManga);
    });

    // Sync progress with AniList/MyAnimeList
    final syncCtrl = Get.find<ServiceHandler>().syncController;
    if (syncCtrl != null) {
      await syncCtrl.pushChapterProgress(mangaId, chapter.number);
    }
  }

  Chapter? getReadChapter(String anilistId, double number) {
    final manga = getMangaById(anilistId);
    if (manga?.readChapters == null) return null;

    return manga!.readChapters!.firstWhereOrNull((c) => c.number == number);
  }

  Future<void> addOrUpdateNovelChapter(String novelId, Chapter chapter) async {
    final existingNovel = getNovelById(novelId);
    if (existingNovel == null) {
      Logger.i(
          'Novel with ID: $novelId not found. Unable to add/update chapter.');
      return;
    }

    await isar.writeTxn(() async {
      existingNovel.readChapters ??= [];
      chapter.sourceName = sourceController.activeNovelSource.value?.name;
      chapter.lastReadTime = DateTime.now().millisecondsSinceEpoch;

      final index = existingNovel.readChapters!
          .indexWhere((c) => c.number == chapter.number);
      existingNovel.readChapters =
          List<Chapter>.from(existingNovel.readChapters!);
      if (index != -1) {
        existingNovel.readChapters![index] = chapter;
        Logger.i(
            'Overwritten chapter: ${chapter.title} for novel ID: $novelId');
      } else {
        existingNovel.readChapters!.add(chapter);
        Logger.i('Added new chapter: ${chapter.title} for novel ID: $novelId');
      }

      existingNovel.currentChapter = chapter;

      await isar.offlineMedias.put(existingNovel);
    });
  }

  Future<Chapter?> getReadNovelChapter(String novelId, double number) async {
    final novel = getNovelById(novelId);
    if (novel?.readChapters == null) return null;

    return novel!.readChapters!.firstWhereOrNull((c) => c.number == number);
  }

  Future<List<OfflineMedia>> getNovelsFromCustomList(String listName) async {
    return await getMediaFromCustomList(listName);
  }

  Future<double> getNovelReadingProgress(String novelId) async {
    final novel = getNovelById(novelId);
    if (novel?.chapters == null || novel!.chapters!.isEmpty) {
      return 0.0;
    }

    final totalChapters = novel.chapters!.length;
    final readChapters = novel.readChapters?.length ?? 0;

    return readChapters / totalChapters;
  }

  Future<Chapter?> getLatestReadNovelChapter(String novelId) async {
    final novel = getNovelById(novelId);
    if (novel?.readChapters == null || novel!.readChapters!.isEmpty) {
      return null;
    }

    final sorted = List<Chapter>.from(novel.readChapters!);
    sorted.sort((a, b) => (b.lastReadTime ?? 0).compareTo(a.lastReadTime ?? 0));

    return sorted.first;
  }

  Future<void> markNovelChapterAsRead(
      String novelId, double chapterNumber) async {
    final novel = getNovelById(novelId);
    if (novel == null) return;

    await isar.writeTxn(() async {
      novel.readChapters ??= [];

      final existingIndex =
          novel.readChapters!.indexWhere((c) => c.number == chapterNumber);
      novel.readChapters = List<Chapter>.from(novel.readChapters!);

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

      await isar.offlineMedias.put(novel);
      Logger.i(
          'Marked chapter $chapterNumber as read for novel: ${novel.name}');
    });
  }

  Future<Chapter?> getNextUnreadNovelChapter(String novelId) async {
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

  Future<bool> isNovelChapterRead(String novelId, double chapterNumber) async {
    final novel = getNovelById(novelId);
    if (novel?.readChapters == null) return false;

    return novel!.readChapters!
        .any((chapter) => chapter.number == chapterNumber);
  }

  Future<Map<String, dynamic>> getNovelStats() async {
    final allNovels =
        await isar.offlineMedias.filter().mediaTypeIndexEqualTo(2).findAll();

    int completedNovels = 0;
    int readingNovels = 0;

    for (final novel in allNovels) {
      if (novel.chapters == null || novel.chapters!.isEmpty) continue;

      final totalChapters = novel.chapters!.length;
      final readChapters = novel.readChapters?.length ?? 0;

      if (readChapters >= totalChapters) {
        completedNovels++;
      } else if (readChapters > 0) {
        readingNovels++;
      }
    }

    final totalNovels = allNovels.length;

    return {
      'total': totalNovels,
      'completed': completedNovels,
      'reading': readingNovels,
      'planToRead': totalNovels - completedNovels - readingNovels,
    };
  }

  OfflineMedia _createOfflineMedia(
    Media original,
    List<Chapter>? chapters,
    List<Episode>? episodes,
    Chapter? currentChapter,
    Episode? currentEpisode,
  ) {
    final handler = Get.find<ServiceHandler>();
    return OfflineMedia(
      mediaId: original.id,
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
      watchedEpisodes: [],
      readChapters: [],
      serviceIndex: handler.serviceType.value.index,
      mediaTypeIndex: original.mediaType.index,
    );
  }

  Future<void> clearCache() async {
    await isar.writeTxn(() async {
      await isar.offlineMedias.clear();
      await isar.customLists.clear();
    });

    Logger.i('Cache cleared successfully');
  }

  List<CustomListData> getEditableCustomListData(
      {required ItemType mediaType}) {
    final lists = isar.customLists
        .filter()
        .mediaTypeIndexEqualTo(mediaType.index)
        .findAllSync();

    return lists.map((list) {
      final mediaIds = list.mediaIds ?? [];

      if (mediaIds.isEmpty) {
        return CustomListData(listName: list.listName ?? '', listData: []);
      }

      final mediaItems = isar.offlineMedias
          .filter()
          .anyOf(
            mediaIds,
            (q, String id) => q
                .mediaIdEqualTo(id)
                .and()
                .mediaTypeIndexEqualTo(mediaType.index),
          )
          .findAllSync();

      return CustomListData(
        listName: list.listName ?? '',
        listData: mediaItems,
      );
    }).toList();
  }

  Future<void> applyCustomListChanges(
    List<CustomListData> updatedLists, {
    required ItemType mediaType,
  }) async {
    final existingLists = await getCustomListsByType(mediaType);

    final existingListsMap = {
      for (var list in existingLists) list.listName: list
    };

    await isar.writeTxn(() async {
      for (var existingList in existingLists) {
        final stillExists = updatedLists.any(
          (updated) => updated.listName == existingList.listName,
        );
        if (!stillExists) {
          await isar.customLists.delete(existingList.id);
        }
      }

      for (var updatedListData in updatedLists) {
        final existingList = existingListsMap[updatedListData.listName];

        if (existingList != null) {
          existingList.listName = updatedListData.listName;
          existingList.mediaIds = updatedListData.listData
              .map((media) => media.mediaId ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
          await isar.customLists.put(existingList);
        } else {
          await isar.customLists.put(CustomList(
            listName: updatedListData.listName,
            mediaIds: updatedListData.listData
                .map((media) => media.mediaId ?? '')
                .where((id) => id.isNotEmpty)
                .toList(),
            mediaTypeIndex: mediaType.index,
          ));
        }
      }
    });

    Logger.i('Applied custom list changes for ${mediaType.name}');
  }
}

class CustomListData {
  String listName;
  List<OfflineMedia> listData;

  CustomListData({required this.listData, required this.listName});
}
