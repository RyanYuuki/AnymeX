import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppData extends ChangeNotifier {
  List<Map<String, dynamic>>? watchedAnimes;
  List<Map<String, dynamic>>? readMangas;
  bool? isGrid;

  AppData() {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      var box = await Hive.openBox('app-data');
      watchedAnimes = List<Map<String, dynamic>>.from(
        box.get('currently-watching', defaultValue: []),
      );
      readMangas = List<Map<String, dynamic>>.from(
        box.get('currently-reading', defaultValue: []),
      );
      isGrid = box.get('grid-context', defaultValue: false);
      notifyListeners();
    } catch (e) {
      log('Failed to load data from Hive: $e');
    }
  }

  void setWatchedAnimes(List<Map<String, dynamic>> animes) {
    watchedAnimes = animes;
    var box = Hive.box('app-data');
    box.put('currently-watching', animes);
    notifyListeners();
  }

  void addWatchedAnime({
    required String animeId,
    required String animeTitle,
    required String currentEpisode,
    required String animePosterImageUrl,
  }) {
    watchedAnimes ??= [];

    final newAnime = {
      'animeId': animeId,
      'animeTitle': animeTitle,
      'currentEpisode': currentEpisode,
      'poster': animePosterImageUrl,
    };

    watchedAnimes!.removeWhere((anime) => anime['animeId'] == animeId);
    watchedAnimes!.add(newAnime);

    var box = Hive.box('app-data');
    box.put('currently-watching', watchedAnimes);
    notifyListeners();
  }

  void setReadMangas(List<Map<String, dynamic>> mangas) {
    readMangas = mangas;
    var box = Hive.box('app-data');
    box.put('currently-reading', mangas);
    notifyListeners();
  }

  void addReadManga({
    required String mangaId,
    required String mangaTitle,
    required String currentChapter,
    required String mangaPosterImage,
  }) {
    readMangas ??= [];

    final newManga = {
      'mangaId': mangaId,
      'mangaTitle': mangaTitle,
      'currentChapter': currentChapter,
      'poster': mangaPosterImage,
    };

    readMangas!.removeWhere((manga) => manga['mangaId'] == mangaId);
    readMangas!.add(newManga);

    var box = Hive.box('app-data');
    box.put('currently-reading', readMangas);
    notifyListeners();
  }

  void setIsGrid(bool isGrid) {
    this.isGrid = isGrid;
    var box = Hive.box('app-data');
    box.put('grid-context', isGrid);
    notifyListeners();
  }

  Map<String, dynamic>? getAnimeById(String animeId) {
    return watchedAnimes?.firstWhere(
      (anime) => anime['animeId'] == animeId,
      orElse: () => {},
    );
  }

  Map<String, dynamic>? getMangaById(String mangaId) {
    return readMangas?.firstWhere(
      (manga) => manga['mangaId'] == mangaId,
      orElse: () => {},
    );
  }

  String? getCurrentEpisodeForAnime(String animeId) {
    final anime = getAnimeById(animeId);
    log('Anime fetched: $anime');
    return anime?['currentEpisode'] ?? '1';
  }

  String? getCurrentChapterForManga(String mangaId) {
    final manga = getMangaById(mangaId);
    log('Manga fetched: $manga');
    return manga?['currentChapter'];
  }
}
