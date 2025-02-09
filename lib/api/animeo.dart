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

  final resp = await http.post(
    Uri.parse('https://anime.ameo.dev/recommendation/recommendation'),
    body: json.encode({
      "dataSource": {"type": "username", "username": "ryan_yuuki"},
      "availableAnimeMetadataIDs": [
        6547,
        8074,
        10620,
        11061,
        15583,
        20785,
        23273,
        23755,
        30276,
        30749,
        30831,
        31338,
        34134,
        34572,
        35507,
        35790,
        37450,
        38572,
        40221,
        40748
      ],
      "includeContributors": true,
      "modelName": "model_6-5k_new2",
      "excludedRankingAnimeIDs": [],
      "excludedGenreIDs": [],
      "includeExtraSeasons": false,
      "includeONAsOVAsSpecials": false,
      "includeMovies": false,
      "includeMusic": false,
      "popularityAttenuationFactor": 0.0008,
      "profileSource": "mal"
    }),
  );
  final data = await jsonDecode(resp.body);
  log(data['animeData'].toString());
  return [];
  // final resp = await http.get(Uri.parse(isAL
  //     ? 'https://anime.ameo.dev/user/$userName/recommendations/__data.json?source=anilist'
  //     : 'https://anime.ameo.dev/user/${userName?.toLowerCase()}/recommendations/__data.json'));

  // if (resp.statusCode == 200) {
  //   final document = jsonDecode(resp.body);
  //   final recItems = document['initialRecommendations']['animeData'];

  //   List<Media> recommendations =
  //       (recItems as Map<String, dynamic>).entries.map((e) {
  //     return Media(
  //       id: e.key,
  //       title: e.value['title'],
  //       poster: e.value['main_picture']['large'],
  //       description: e.value['synopsis'],
  //       genres: (e.value['genres'] as List)
  //           .map((genre) => genre['name'].toString().trim())
  //           .toList(),
  //     );
  //   }).toList();

  //   return recommendations;
  // } else {
  //   snackBar('Yep, We Failed');
  //   log(resp.body);
  // }
  // return [];
}

Future<List<Media>> getAiMangaRecommendation() async {
  final service = Get.find<ServiceHandler>();
  final isAL = service.serviceType.value == ServicesType.anilist;
  final userName = service.onlineService.profileData.value.name;

  final resp = await http.get(Uri.parse(
      'https://anibrain.ai/integrations/${isAL ? 'anilist' : 'myanimelist'}/manga?ext_profile_provider_id=${isAL ? 'anilist' : 'myanimelist'}&ext_profile_name=$userName'));

  if (resp.statusCode == 200) {
    final document = parse(resp.body);
    final recItems = document.querySelectorAll('.styles_main__1IB__ ');

    List<Media> recommendations = [];

    for (var item in recItems) {
      final title = item.querySelector('.title-text')?.text.trim() ?? "Unknown";
      final imageUrl = item.querySelector('img')?.attributes['src'] ?? "";
      final synopsis = item.querySelector('.synopsis')?.text.trim() ?? "";

      final genreElements = item.querySelectorAll('.genres .bx--tag');
      final genres = genreElements.map((e) => e.text.trim()).toList();

      final id = item
              .querySelector('img')
              ?.attributes['src']
              ?.split('anime/')
              .last
              .split('/')
              .first ??
          '';

      recommendations.add(Media(
        id: id,
        title: title,
        poster: imageUrl,
        description: synopsis,
        genres: genres,
      ));
    }

    return recommendations;
  }
  snackBar('Yep, We Failed');
  return [];
}
