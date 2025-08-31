import 'dart:convert';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

Future<List<Media>> getAiRecommendations(
  bool isManga,
  int page, {
  bool isAdult = false,
  String? username,
}) async {
  final query = username?.trim().toLowerCase();
  final service = Get.find<ServiceHandler>();
  final isAL = service.serviceType.value == ServicesType.anilist;
  final userName = query ?? service.onlineService.profileData.value.name;

  Future<List<Media>> fetchRecommendations() async {
    try {
      final url = isManga
          ? 'https://anibrain.ai/api/-/recommender/recs/external-list/super-media-similar?filterCountry=[]&filterFormat=["MANGA"]&filterGenre={}&filterTag={"max":{},"min":{}}&filterRelease=[1930,2025]&filterScore=0&algorithmWeights={"genre":0.3,"setting":0.15,"synopsis":0.4,"theme":0.2}&externalListProvider=${isAL ? 'AniList' : 'MyAnimeList'}&externalListProfileName=$userName&mediaType=MANGA&adult=$isAdult&page=$page'
          : 'https://anibrain.ai/api/-/recommender/recs/external-list/super-media-similar?filterCountry=[]&filterFormat=[]&filterGenre={}&filterTag={"max":{},"min":{}}&filterRelease=[1917,2025]&filterScore=0&algorithmWeights={"genre":0.3,"setting":0.15,"synopsis":0.4,"theme":0.2}&externalListProvider=${isAL ? 'AniList' : 'MyAnimeList'}&externalListProfileName=$userName&mediaType=ANIME&adult=$isAdult&page=$page';

      final resp = await http.get(Uri.parse(url));

      if (resp.statusCode == 200) {
        final document = jsonDecode(resp.body);
        final recItems = document['data'];

        return recItems.map<Media>((item) {
          final title = item['titleEnglish'] ?? item['titleRomaji'];
          final imageUrl = item['imgURLs'][0];
          final synopsis = item['description'];
          final id = isAL ? item['anilistId'] : item['myanimelistId'];

          return Media(
            id: id.toString(),
            title: title,
            poster: imageUrl,
            description: synopsis,
            serviceType: ServicesType.anilist,
            genres: (item['genres'] as List)
                .map((genre) => genre.toString().trim().toUpperCase())
                .toList(),
          );
        }).toList();
      } else {
        Logger.i(
            'Recommendation API failed: ${resp.statusCode} - ${resp.body}');
      }
    } catch (e) {
      Logger.i('Recommendation fetch error: $e');
    }
    return [];
  }

  List<Media> recommendations = await fetchRecommendations();

  if (recommendations.isEmpty) {
    recommendations = await syncAndFetchRecommendations(
        userName!, isAL, fetchRecommendations);
  }

  if (recommendations.isEmpty) {
    snackBar('Error Occurred!');
  }

  return recommendations;
}

Future<List<Media>> syncAndFetchRecommendations(String username, bool isAL,
    Future<List<Media>> Function() fetchRecommendations) async {
  try {
    snackBar("Getting Your ${isAL ? 'AniList' : 'MyAnimeList'} Data...",
        duration: 1000);
    await getUserList(username, isAL);

    snackBar("Syncing Your List...", duration: 1000);
    await syncUserList(username, isAL);

    snackBar("Fetching AI Recommendations...", duration: 1000);
    final recommendations = await fetchRecommendations();

    if (recommendations.isNotEmpty) {
      snackBar("Recommendations Ready!", duration: 1000);
      return recommendations;
    }
  } catch (e) {
    Logger.i('Sync and fetch error: $e');
    snackBar('Sync Failed!');
  }

  return [];
}

Future<void> getUserList(String username, bool isAL) async {
  try {
    final url =
        'https://anibrain.ai/api/-/list/${isAL ? 'anilist' : 'myanimelist'}/fetch-list?profileId=$username&refresh=false';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Logger.i('User list fetched successfully: ${response.body.toString()}');
    } else {
      Logger.i(
          'Failed to fetch user list: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch user list');
    }
  } catch (e) {
    Logger.i('Get user list error: $e');
    rethrow;
  }
}

Future<void> syncUserList(String username, bool isAL) async {
  try {
    final url =
        'https://anibrain.ai/api/-/super-media/external-list/create-similar?externalListProvider=${isAL ? 'AniList' : 'MyAnimeList'}&externalListProfileName=$username';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Logger.i('User list synced successfully: ${response.body.toString()}');
    } else {
      Logger.i(
          'Failed to sync user list: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to sync user list');
    }
  } catch (e) {
    Logger.i('Sync user list error: $e');
    rethrow;
  }
}
