import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AniListProvider with ChangeNotifier {
  final storage = Hive.box('login-data');
  dynamic _userData = {};
  bool _isLoading = false;

  dynamic get userData => _userData;
  bool get isLoading => _isLoading;

  Future<void> tryAutoLogin() async {}

  Future<void> login(BuildContext context) async {}

  Future<void> _exchangeCodeForToken(String code, String clientId,
      String clientSecret, String redirectUri, BuildContext context) async {}

  Future<void> updateAnimeList({
    required int animeId,
    required int episodeProgress,
    required double rating,
    required String status,
  }) async {}

  Future<void> updateMangaList({
    required int mangaId,
    required int chapterProgress,
    required double rating,
    required String status,
  }) async {}

  Future<void> deleteMangaFromList({
    required int mangaId,
  }) async {}

  Future<void> deleteAnimeFromList({
    required int animeId,
  }) async {}

  Future<void> updateMangaProgress({
    required int mangaId,
    required int chapterProgress,
    required String status,
  }) async {}

  Future<void> updateAnimeProgress({
    required int animeId,
    required int episodeProgress,
    required String status,
  }) async {}

  Future<void> fetchUserProfile() async {}

  Future<void> fetchAnilistHomepage() async {}

  Future<void> fetchAnilistMangaPage() async {}

  Future<void> fetchUserAnimeList() async {}

  Future<void> fetchUserMangaList() async {}

  Future<void> logout(BuildContext context) async {}
}
