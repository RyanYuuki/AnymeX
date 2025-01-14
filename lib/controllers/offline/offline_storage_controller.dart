import 'dart:developer';
import 'package:anymex/models/Anilist/anilist_media_full.dart';
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
  List<CustomList> animeCustomLists = [CustomList()];
  List<CustomList> mangaCustomLists = [CustomList()];
  RxList<CustomListData> animeCustomListData = <CustomListData>[].obs;
  RxList<CustomListData> mangaCustomListData = <CustomListData>[].obs;

  late Box<OfflineStorage> _offlineStorageBox;

  @override
  Future<void> onInit() async {
    super.onInit();
    try {
      _offlineStorageBox = await Hive.openBox<OfflineStorage>('offlineStorage');
      _loadLibraries();
    } catch (e) {
      log('Error opening Hive box: $e');
    }
  }

  void _loadLibraries() {
    final offlineStorage =
        _offlineStorageBox.get('storage') ?? OfflineStorage();

    animeLibrary.assignAll(offlineStorage.animeLibrary ?? []);
    mangaLibrary.assignAll(offlineStorage.mangaLibrary ?? []);
    animeCustomLists
        .assignAll(offlineStorage.animeCustomList ?? [CustomList()]);
    mangaCustomLists
        .assignAll(offlineStorage.mangaCustomList ?? [CustomList()]);
    _initListData();
  }

  void _initListData() {
    for (var e in animeCustomLists) {
      final field = e.mediaIds
          ?.map((e) => getAnimeById(e))
          .where((media) => media != null)
          .cast<OfflineMedia>()
          .toList();

      animeCustomListData
          .add(CustomListData(listData: field!, listName: e.listName!));
    }
    for (var e in mangaCustomLists) {
      final field = e.mediaIds
          ?.map((e) => getMangaById(e))
          .where((media) => media != null)
          .cast<OfflineMedia>()
          .toList();

      mangaCustomListData
          .add(CustomListData(listData: field!, listName: e.listName!));
    }
    animeCustomListData[0].listData = animeLibrary;
    mangaCustomListData[0].listData = mangaLibrary;
  }

  void addOrUpdateAnime(AnilistMediaData original, List<Episode>? episodes,
      Episode? currentEpisode) {
    OfflineMedia? existingAnime = getAnimeById(original.id);

    if (existingAnime != null) {
      existingAnime.episodes = episodes;
      existingAnime.currentEpisode = currentEpisode;
      log('Updated anime: ${existingAnime.name}');
      animeLibrary.remove(existingAnime);
      animeLibrary.insert(0, existingAnime);
    } else {
      animeLibrary.insert(0,
          _createOfflineMedia(original, null, episodes, null, currentEpisode));
      log('Added new anime: ${original.name}');
    }

    _saveLibraries();
  }

  void addOrUpdateManga(AnilistMediaData original, List<Chapter>? chapters,
      Chapter? currentChapter) {
    OfflineMedia? existingManga = getMangaById(original.id);

    if (existingManga != null) {
      existingManga.chapters = chapters;
      existingManga.currentChapter = currentChapter;
      log('Updated manga: ${existingManga.name}');
      mangaLibrary.remove(existingManga);
      mangaLibrary.insert(0, existingManga);
    } else {
      mangaLibrary.insert(0,
          _createOfflineMedia(original, chapters, null, currentChapter, null));
      log('Added new manga: ${original.name}');
    }

    _saveLibraries();
  }

  void addOrUpdateReadChapter(int mangaId, Chapter chapter) {
    OfflineMedia? existingManga = getMangaById(mangaId);
    if (existingManga != null) {
      existingManga.readChapters ??= [];
      int index = existingManga.readChapters!
          .indexWhere((c) => c.number == chapter.number);
      if (index != -1) {
        chapter.lastReadTime = DateTime.now().millisecondsSinceEpoch;
        existingManga.readChapters![index] = chapter;
        log('Overwritten chapter: ${chapter.title} for manga ID: $mangaId');
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

  void addOrUpdateWatchedEpisode(int animeId, Episode episode) {
    OfflineMedia? existingAnime = getAnimeById(animeId);
    if (existingAnime != null) {
      existingAnime.watchedEpisodes ??= [];
      int index = existingAnime.watchedEpisodes!
          .indexWhere((e) => e.number == episode.number);
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
      AnilistMediaData original,
      List<Chapter>? chapters,
      List<Episode>? episodes,
      Chapter? currentChapter,
      Episode? currentEpisode) {
    return OfflineMedia(
      id: original.id,
      jname: original.jname,
      name: original.name,
      english: original.english,
      japanese: original.japanese,
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
    );
  }

  void _saveLibraries() {
    final updatedStorage = OfflineStorage(
        animeLibrary: animeLibrary.toList(),
        mangaLibrary: mangaLibrary.toList(),
        animeCustomList: animeCustomLists,
        mangaCustomList: mangaCustomLists);

    try {
      _offlineStorageBox.put('storage', updatedStorage);
      log("Anime/Manga Successfully Saved!");
    } catch (e) {
      log('Error saving libraries: $e');
    }
    refresh();
  }

  OfflineMedia? getAnimeById(int id) {
    return animeLibrary.firstWhereOrNull((anime) => anime.id == id);
  }

  OfflineMedia? getMangaById(int id) {
    return mangaLibrary.firstWhereOrNull((manga) => manga.id == id);
  }

  Episode? getWatchedEpisode(int anilistId, String episodeOrChapterNumber) {
    OfflineMedia? anime = getAnimeById(anilistId);
    if (anime != null) {
      Episode? episode = anime.watchedEpisodes
          ?.firstWhereOrNull((e) => e.number == episodeOrChapterNumber);
      log("Found Episode! Episode Title is ${episode?.title}");
      return episode;
    }
    return null;
  }

  Chapter? getReadChapter(int anilistId, double number) {
    OfflineMedia? manga = getMangaById(anilistId);
    if (manga != null) {
      Chapter? chapter =
          manga.readChapters?.firstWhereOrNull((c) => c.number == number);
      return chapter;
    }
    log('No data found for AniList ID: $anilistId with number $number');
    return null;
  }

  Chapter? getHighestChapter(int anilistId) {
    OfflineMedia? manga = getMangaById(anilistId);
    if (manga != null &&
        manga.readChapters != null &&
        manga.readChapters!.isNotEmpty) {
      manga.readChapters?.sort((a, b) => b.number!.compareTo(a.number!));
      return manga.readChapters!.first;
    }
    log('No chapters found for manga with ID: $anilistId');
    return null;
  }

  Episode? getHighestEpisode(int anilistId) {
    OfflineMedia? anime = getAnimeById(anilistId);
    if (anime != null &&
        anime.watchedEpisodes != null &&
        anime.watchedEpisodes!.isNotEmpty) {
      anime.watchedEpisodes!
          .sort((a, b) => int.parse(b.number).compareTo(int.parse(a.number)));
      return anime.watchedEpisodes!.first;
    }
    log('No episodes found for anime with ID: $anilistId');
    return null;
  }

  void clearCache() {
    _offlineStorageBox.clear();
    animeLibrary.clear();
    mangaLibrary.clear();
  }
}

class CustomListData {
  String listName;
  List<OfflineMedia> listData;

  CustomListData({required this.listData, required this.listName});
}
