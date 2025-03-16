import 'dart:convert';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

Future<List<Media>> getAiRecommendations(bool isManga, int page,
    {bool isAdult = false, String? username}) async {
  final query = username?.trim().toLowerCase();
  final service = Get.find<ServiceHandler>();
  final isAL = service.serviceType.value == ServicesType.anilist;
  final userName = query ?? service.onlineService.profileData.value.name;

  Future<List<Media>> fetchRecommendations() async {
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
            genres: (item['genres'] as List)
                .map((genre) => genre.toString().trim().toUpperCase())
                .toList());
      }).toList();
    }
    return [];
  }

  List<Media> recommendations = await fetchRecommendations();

  if (recommendations.isEmpty) {
    snackBar("Syncing Your List...");
    await syncUserList(userName!, isAL);
    recommendations = await fetchRecommendations();
  }

  if (recommendations.isEmpty) {
    snackBar('Error Occurred!');
  }

  return recommendations;
}

Future<void> syncUserList(String username, bool isAL) async {
  final url = !isAL
      ? 'https://anibrain.ai/api/-/super-media/external-list/create-similar?externalListProvider=MyAnimeList&externalListProfileName=$username'
      : 'https://anibrain.ai/api/-/super-media/external-list/create-similar?externalListProvider=AniList&externalListProfileName=$username';
  final resp = await http.get(Uri.parse(url));

  if (resp.statusCode == 200) {
    snackBar("Sync Successfull! Getting Recommendations");
  } else {
    snackBar('Sync Failed!!');
  }
}
