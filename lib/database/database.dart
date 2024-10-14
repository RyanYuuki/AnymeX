import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppData extends ChangeNotifier {
  dynamic watchedAnimes;
  dynamic readMangas;
  bool? isGrid;
  bool? usingConsumet;

  AppData() {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      var box = await Hive.openBox('app-data');
      watchedAnimes = box.get('currently-watching', defaultValue: []);
      readMangas = box.get('currently-reading', defaultValue: []);
      isGrid = box.get('grid-context', defaultValue: false);
      usingConsumet = box.get('using-consumet', defaultValue: false);
      notifyListeners();
    } catch (e) {
      log('Failed to load data from Hive: $e');
    }
  }

  void setWatchedAnimes(dynamic animes) {
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
    required bool isConsumet,
  }) {
    watchedAnimes ??= [];

    final newAnime = {
      'animeId': animeId,
      'animeTitle': animeTitle,
      'currentEpisode': currentEpisode,
      'poster': animePosterImageUrl,
      'isConsumet': isConsumet,
    };

    watchedAnimes!.removeWhere((anime) => anime['animeId'] == animeId);
    watchedAnimes!.add(newAnime);

    var box = Hive.box('app-data');
    box.put('currently-watching', watchedAnimes);
    notifyListeners();
  }

  void setReadMangas(dynamic mangas) {
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

  dynamic getAnimeById(String animeId) {
    return watchedAnimes?.firstWhere(
      (anime) => anime['animeId'] == animeId,
      orElse: () => {},
    );
  }

  dynamic getMangaById(String mangaId) {
    return readMangas?.firstWhere(
      (manga) => manga['mangaId'] == mangaId,
      orElse: () => {},
    );
  }

  String? getCurrentEpisodeForAnime(String animeId) {
    final anime = getAnimeById(animeId);
    return anime?['currentEpisode'] ?? '1';
  }

  String? getCurrentChapterForManga(String mangaId) {
    final manga = getMangaById(mangaId);
    return manga?['currentChapter'];
  }
}
