import 'dart:convert';
import 'dart:developer';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

Future<List<Media>> getAiRecommendation() async {
  final service = Get.find<ServiceHandler>();
  final isAL = service.serviceType.value == ServicesType.anilist;
  final userName = service.onlineService.profileData.value.name;

  if (userName == null || userName.isEmpty) {
    log("Username is null or empty.");
    return [];
  }

  List<Media> recs = [];

  final idResp = await http.get(Uri.parse(isAL
      ? 'https://anime.ameo.dev/user/$userName/recommendations/__data.json?source=anilist'
      : 'https://anime.ameo.dev/user/${userName.toLowerCase()}/recommendations/__data.json'));

  if (idResp.statusCode != 200) {
    log("Failed to fetch initial recommendations: ${idResp.statusCode}");
    return [];
  }

  final recJson = jsonDecode(idResp.body);
  final id = recJson['initialRecommendations']['recommendations']
      .map((e) => e['id'])
      .toList();
  final recItems = recJson['initialRecommendations']['animeData'];

  for (var e in (recItems as Map<String, dynamic>).entries) {
    recs.add(Media(
      id: e.key,
      title: e.value['title'],
      poster: e.value['main_picture']['large'],
      description: e.value['synopsis'],
      genres: (e.value['genres'] as List)
          .map((genre) => genre['name'].toString().trim())
          .toList(),
    ));
  }

  final resp = await http.post(
    Uri.parse('https://anime.ameo.dev/recommendation/recommendation'),
    headers: {"Content-Type": "application/json"},
    body: json.encode({
      "dataSource": {"type": "username", "username": userName.toLowerCase()},
      "availableAnimeMetadataIDs": id,
      "includeContributors": true,
      "modelName": "model_6-5k_new2",
      "excludedRankingAnimeIDs": [],
      "excludedGenreIDs": [],
      "includeExtraSeasons": false,
      "includeONAsOVAsSpecials": false,
      "includeMovies": false,
      "includeMusic": false,
      "popularityAttenuationFactor": 0.0008,
      "profileSource": isAL ? 'anilist' : "mal"
    }),
  );

  if (resp.statusCode != 200) {
    log("Failed to fetch AI recommendations: ${resp.statusCode}");
    return recs;
  }

  final data = jsonDecode(resp.body);
  data['animeData'].entries.forEach((e) {
    recs.add(Media(
      id: e.key,
      title: e.value['title'],
      poster: e.value['main_picture']['large'],
      description: e.value['synopsis'],
      genres: (e.value['genres'] as List)
          .map((genre) => genre['name'].toString().trim())
          .toList(),
    ));
  });

  log("Total recommendations: ${recs.length}");
  return recs;
}

Future<List<Media>> getAiRecommendations(bool isManga, int page) async {
  final service = Get.find<ServiceHandler>();
  final isAL = service.serviceType.value == ServicesType.anilist;
  final userName = service.onlineService.profileData.value.name;

  final resp = await http.get(Uri.parse(isManga
      ? 'https://anibrain.ai/api/-/recommender/recs/external-list/super-media-similar?filterCountry=[]&filterFormat=["MANGA"]&filterGenre={}&filterTag={"max":{},"min":{}}&filterRelease=[1930,2025]&filterScore=0&algorithmWeights={"genre":0.3,"setting":0.15,"synopsis":0.4,"theme":0.2}&externalListProvider=${isAL ? 'AniList' : 'MyAnimeList'}&externalListProfileName=$userName&mediaType=MANGA&adult=false&page=$page'
      : 'https://anibrain.ai/api/-/recommender/recs/external-list/super-media-similar?filterCountry=[]&filterFormat=[]&filterGenre={}&filterTag={"max":{},"min":{}}&filterRelease=[1917,2025]&filterScore=0&algorithmWeights={"genre":0.3,"setting":0.15,"synopsis":0.4,"theme":0.2}&externalListProvider=${isAL ? 'AniList' : 'MyAnimeList'}&externalListProfileName=$userName&mediaType=ANIME&adult=false&page=1'));

  if (resp.statusCode == 200) {
    final document = jsonDecode(resp.body);
    final recItems = document['data'];

    List<Media> recommendations = [];

    for (var item in recItems) {
      final title = item['titleEnglish'] ?? item['titleRomaji'];
      final imageUrl = item['imgURLs'][0];
      final synopsis = item['description'];

      final id = isAL ? item['anilistId'] : item['myanimelistId'];

      recommendations.add(Media(
          id: id.toString(),
          title: title,
          poster: imageUrl,
          description: synopsis,
          genres: (item['genres'] as List)
              .map((genre) => genre.toString().trim().toUpperCase())
              .toList()));
    }

    return recommendations;
  }
  log(resp.body);
  snackBar('Yep, We Failed');
  return [];
}
