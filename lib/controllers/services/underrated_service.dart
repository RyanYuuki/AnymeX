import 'dart:convert';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// Service to fetch underrated anime/manga from a GitHub JSON file
class UnderratedService extends GetxController {
  // GitHub raw URLs for the JSON files
  static const String _animeJsonUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/underrated_anime.json';
  static const String _mangaJsonUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/underrated_manga.json';

  // Observable lists for underrated content
  RxList<Media> underratedAnimes = <Media>[].obs;
  RxList<Media> underratedMangas = <Media>[].obs;

  // Loading states
  RxBool isLoadingAnime = false.obs;
  RxBool isLoadingManga = false.obs;

  // Error states
  RxString animeError = ''.obs;
  RxString mangaError = ''.obs;

  /// Fetch underrated anime from GitHub JSON
  Future<void> fetchUnderratedAnime() async {
    if (underratedAnimes.isNotEmpty) return; // Already fetched

    isLoadingAnime.value = true;
    animeError.value = '';

    try {
      final response = await http.get(Uri.parse(_animeJsonUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        underratedAnimes.value =
            data.map((item) => Media.fromUnderratedJson(item, false)).toList();
        Logger.i('Fetched ${underratedAnimes.length} underrated anime');
      } else {
        animeError.value = 'Failed to load: ${response.statusCode}';
        Logger.i('Failed to fetch underrated anime: ${response.statusCode}');
      }
    } catch (e) {
      animeError.value = 'Error: $e';
      Logger.i('Error fetching underrated anime: $e');
    } finally {
      isLoadingAnime.value = false;
    }
  }

  /// Fetch underrated manga from GitHub JSON
  Future<void> fetchUnderratedManga() async {
    if (underratedMangas.isNotEmpty) return; // Already fetched

    isLoadingManga.value = true;
    mangaError.value = '';

    try {
      final response = await http.get(Uri.parse(_mangaJsonUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        underratedMangas.value =
            data.map((item) => Media.fromUnderratedJson(item, true)).toList();
        Logger.i('Fetched ${underratedMangas.length} underrated manga');
      } else {
        mangaError.value = 'Failed to load: ${response.statusCode}';
        Logger.i('Failed to fetch underrated manga: ${response.statusCode}');
      }
    } catch (e) {
      mangaError.value = 'Error: $e';
      Logger.i('Error fetching underrated manga: $e');
    } finally {
      isLoadingManga.value = false;
    }
  }

  /// Fetch both anime and manga
  Future<void> fetchAll() async {
    await Future.wait([
      fetchUnderratedAnime(),
      fetchUnderratedManga(),
    ]);
  }

  /// Refresh all data (force reload)
  Future<void> refresh() async {
    underratedAnimes.clear();
    underratedMangas.clear();
    await fetchAll();
  }
}
