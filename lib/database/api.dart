// ignore_for_file: constant_identifier_names, unused_local_variable

import 'dart:convert';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

String proxyUrl = "https://goodproxy.goodproxy.workers.dev/fetch?url=";
String consumetUrl = "${dotenv.get('CONSUMET_URL')}meta/anilist/";
String aniwatchUrl = "${dotenv.get('ANIME_URL')}anime/";
bool isRomaji = Hive.box('app-data').get('isRomaji', defaultValue: false);
void toggleRomaji(String source, bool state) {}

Future<dynamic>? fetchHomePageAniwatch() async {
  final response =
      await http.get(Uri.parse('$proxyUrl${aniwatchUrl}home'));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    log('Error fetching data from Aniwatch API: $response.statusCode');
    return [];
  }
}

Future<dynamic>? fetchHomePageConsumet() async {
  dynamic data = {};

  try {
    final spotlightAnimesResponse = await http.get(Uri.parse(
        '$proxyUrl${dotenv.get('CONSUMET_URL')}meta/anilist/trending'));
    final trendingAnimesResponse = await http.get(Uri.parse(
        '$proxyUrl${dotenv.get('CONSUMET_URL')}meta/anilist/trending?page=2'));
    final latestEpisodesResponse = await http.get(Uri.parse(
        '$proxyUrl${dotenv.get('CONSUMET_URL')}meta/anilist/advanced-search?sort=["EPISODES"]'));
    final topUpcomingAnimesResponse = await http.get(Uri.parse(
        '$proxyUrl${dotenv.get('CONSUMET_URL')}meta/anilist/advanced-search?status=NOT_YET_RELEASED'));
    final topAiringAnimesResponse = await http.get(Uri.parse(
        '$proxyUrl${dotenv.get('CONSUMET_URL')}meta/anilist/trending?page=3'));
    final mostPopularAnimesResponse = await http.get(Uri.parse(
        '$proxyUrl${dotenv.get('CONSUMET_URL')}meta/anilist/popular'));
    final mostFavouriteAnimesResponse = await http.get(Uri.parse(
        '$proxyUrl${dotenv.get('CONSUMET_URL')}meta/anilist/popular?page=2'));
    final latestCompletedAnimesResponse = await http.get(Uri.parse(
        '$proxyUrl${dotenv.get('CONSUMET_URL')}meta/anilist/advanced-search?year=2024&status=FINISHED'));

    if (spotlightAnimesResponse.statusCode == 200) {
      data['spotlightAnimes'] =
          jsonDecode(spotlightAnimesResponse.body)['results'];
    }
    if (trendingAnimesResponse.statusCode == 200) {
      data['trendingAnimes'] =
          jsonDecode(trendingAnimesResponse.body)['results'];
    }
    if (latestEpisodesResponse.statusCode == 200) {
      data['latestEpisodesAnimes'] =
          jsonDecode(latestEpisodesResponse.body)['results'];
    }
    if (topUpcomingAnimesResponse.statusCode == 200) {
      data['topUpcomingAnimes'] =
          jsonDecode(topUpcomingAnimesResponse.body)['results'];
    }
    if (topAiringAnimesResponse.statusCode == 200) {
      data['topAiringAnimes'] =
          jsonDecode(topAiringAnimesResponse.body)['results'];
    }
    if (mostPopularAnimesResponse.statusCode == 200) {
      data['mostPopularAnimes'] =
          jsonDecode(mostPopularAnimesResponse.body)['results'];
    }
    if (mostFavouriteAnimesResponse.statusCode == 200) {
      data['mostFavouriteAnimes'] =
          jsonDecode(mostFavouriteAnimesResponse.body)['results'];
    }
    if (latestCompletedAnimesResponse.statusCode == 200) {
      data['latestCompletedAnimes'] =
          jsonDecode(latestCompletedAnimesResponse.body)['results'];
    }
    if (spotlightAnimesResponse.statusCode == 200 &&
        topAiringAnimesResponse.statusCode == 200 &&
        trendingAnimesResponse.statusCode == 200) {
      final today = jsonDecode(spotlightAnimesResponse.body);
      final week = jsonDecode(trendingAnimesResponse.body);
      final month = jsonDecode(topAiringAnimesResponse.body);
      data['top10Animes'] = {
        'today': extractData(today['results']),
        'week': extractData(week['results']),
        'month': extractData(month['results']),
      };
    }
  } catch (e) {
    log('Error fetching data from Consumet API: $e');
  }

  return data;
}

Future<dynamic>? fetchAnimeDetailsConsumet(String id) async {
  try {
    final resp =
        await http.get(Uri.parse('$proxyUrl${consumetUrl}info/$id'));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data;
    } else {
      log('Failed to fetch data: ${resp.statusCode}');
      return null;
    }
  } catch (e) {
    log(e.toString());
  }
}

Future<dynamic> fetchAnimeDetailsAniwatch(String id) async {
  try {
    final resp =
        await http.get(Uri.parse('$proxyUrl${aniwatchUrl}info?id=$id'));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data;
    } else {
      log('Failed to fetch data: ${resp.statusCode}');
      return null;
    }
  } catch (e) {
    log('Error fetching anime details: $e');
    return null;
  }
}

Future<dynamic>? fetchSearchesAniwatch(String id) async {}
Future<dynamic>? fetchSearchesConsumet(String id) async {}
Future<dynamic>? fetchStreamingDataConsumet(String id) async {
  final resp =
      await http.get(Uri.parse('$proxyUrl${consumetUrl}episodes/$id'));
  if (resp.statusCode == 200) {
    final tempData = jsonDecode(resp.body);
    return tempData;
  }
}

Future<dynamic>? fetchStreamingDataAniwatch(String id) async {
  final resp =
      await http.get(Uri.parse('$proxyUrl${aniwatchUrl}episodes/$id'));
  if (resp.statusCode == 200) {
    final tempData = jsonDecode(resp.body);
    return tempData;
  }
}

Future<dynamic> fetchStreamingLinksAniwatch(
    String id, String server, String category) async {
  try {
    final url =
        '${aniwatchUrl}episode-srcs?id=$id?server=$server&category=$category';
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode == 200) {
      final tempData = jsonDecode(resp.body);
      return tempData;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

Future<dynamic>? fetchStreamingLinksConsumet(String id) async {
  final resp =
      await http.get(Uri.parse('$proxyUrl${consumetUrl}watch/$id'));
  if (resp.statusCode == 200) {
    final tempData = jsonDecode(resp.body);
    return tempData;
  }
}

dynamic extractData(dynamic items) {
  bool? isConsumet =
      Hive.box('app-data').get('using-consumet', defaultValue: false);
  if (items != null) {
    dynamic results = [];
    for (var item in items) {
      String id = 'one-piece-100';
      String name = 'Unknown';
      String jname = 'Unknown';
      String poster = 'Unknown';
      List<String> otherInfo = [];
      String description = 'Unknown';
      String type = 'Unknown';
      String? cover;
      String carouselImage = 'Unknown';
      dynamic episodes = {};
      if (isConsumet!) {
        id = item['id'] ?? '';
        name = isRomaji
            ? item['title']['romaji']
            : item['title']['english'] ??
                item['title']['user-preferred'] ??
                'Unknown';
        poster = item['image'] ?? 'Consumet';
        cover = item['cover'] ?? item['image'] ?? item['poster'] ?? '';
        description = item['description'] ?? 'No description available';
        carouselImage = item['cover'] ?? 'Consumet';
        otherInfo = [
          (item['type'] ?? '??').toString(),
          (item['duration'] ?? '??').toString(),
          (item['releaseDate'] ?? '??').toString(),
          'HD'
        ];
        jname = item['title']['romaji'] ?? '??';
        type = item['type'] ?? 'TV';
        episodes = {
          'sub': item['totalEpisodes'] ?? '??',
          'dub': '0',
        };
      } else {
        id = item['id'] ?? 'unknown-id';
        name = isRomaji ? item['jname'] ?? '??' : item['name'] ?? '??';
        poster = item['poster'] ?? 'Aniwatch';
        otherInfo =
            (item['otherInfo'] as List<dynamic>? ?? ['??', '??', '??', '??'])
                .map((info) => info.toString())
                .toList();
        description = item['description'] ?? 'No description available';
        carouselImage = item['poster'] ?? 'Aniwatch';
        episodes = item['episodes'] != null
            ? {
                "sub": item['episodes']['sub'] ?? '??',
                "dub": item['episodes']['dub'] ?? '??',
              }
            : {
                "sub": '??',
                "dub": '??',
              };
        type = item['type'] ?? 'TV';
      }
      results.add({
        'id': id,
        'name': name,
        'poster': poster,
        'otherInfo': otherInfo,
        'description': description,
        'cover': cover,
        'jname': jname,
        'type': type,
        'episodes': episodes,
        'carouselImage': carouselImage,
      });
    }
    return results;
  } else {
    return [];
  }
}

dynamic mergeData(dynamic mainArr) {
  dynamic info = mainArr?['anime']?['info'];
  dynamic moreInfo = mainArr?['anime']?['moreInfo'];
  dynamic mostPopularAnimes = mainArr?['mostPopularAnimes'];
  dynamic relatedAnimes = mainArr?['relatedAnimes'];
  dynamic recommendedAnimes = mainArr?['recommendedAnimes'];
  dynamic animeSeasons = mainArr?['seasons'];
  dynamic mergedData = {};

  if (info is Map) {
    mergedData.addAll(info);
  }
  if (moreInfo is Map) {
    mergedData.addAll(moreInfo);
  }
  if (animeSeasons != null) {
    mergedData['seasons'] = animeSeasons;
  }
  if (mostPopularAnimes != null) {
    mergedData['mostPopularAnimes'] = mostPopularAnimes;
  }
  if (relatedAnimes != null) {
    mergedData['relatedAnimes'] = relatedAnimes;
  }
  if (recommendedAnimes != null) {
    mergedData['recommendedAnimes'] = recommendedAnimes;
  }
  return mergedData;
}

dynamic conditionDetailPageData(dynamic data, bool isConsumet) {
  dynamic result = {};

  String id = '??';
  String name = '??';
  String jname = '??';
  String premiered = '??';
  String description = '??';
  String poster = '??';
  String cover = '??';
  String rating = '??';
  String color = '??';
  dynamic stats = {};
  List<String> genres = [];
  String totalEpisodes = '??';
  String duration = '??';
  dynamic characters = [];
  dynamic popularAnimes = {};
  dynamic relatedAnimes = {};
  dynamic recommendedAnimes = {};
  dynamic seasons = [];

  if (isConsumet) {
    id = data['id'] ?? '??';
    name = isRomaji
        ? data?['title']?['romaji']
        : data?['title']?['english'] ??
            data?['title']?['romaji'] ??
            data?['name'] ??
            '??';
    jname = data?['title']?['romaji'] ?? data?['jname'] ?? '??';
    poster = data['image'] ?? data['poster'] ?? '??';
    cover = data['cover'] ?? data['image'] ?? '??';
    premiered = '${data["season"]} ${data["releaseDate"]}' ?? '??';
    description = data['description'] ?? '??';
    rating = data['rating']?.toString() ?? data?['malscore'].toString() ?? '??';
    genres =
        List<String>.from(data['genres'] ?? ['Action, Adventure, Fantasy']);
    totalEpisodes = data['currentEpisode']?.toString() ??
        data['totalEpisode']?.toString() ??
        '??';
    duration = data['duration']?.toString() ?? '??';
    stats = data?['stats'] ?? {};
    characters = data['characters'] ?? [];
    relatedAnimes = data['relations'] ?? {};
    recommendedAnimes = data['recommendations'] ?? {};
    seasons = data['seasons'] ?? [];
    popularAnimes = null;
    color = data['color'] ?? '??';
  } else {
    id = data['id'] ?? '??';
    name = isRomaji ? data['jname'] : data['name'] ?? data['title'] ?? '??';
    jname = data?['japanese'] ?? '??';
    poster = data['poster'] ?? data['image'] ?? '??';
    cover = '??';
    description = data['description'] ?? '??';
    premiered = data['premiered'] ?? '??';
    stats = data?['stats'] ?? {};
    rating = data['malscore']?.toString() ?? '??';
    genres =
        List<String>.from(data['genres'] ?? ['Action, Adventure, Fantasy']);
    totalEpisodes = data['stats']?['episodes']?['sub']?.toString() ?? '??';
    duration = data['duration']?.toString() ?? '??';
    characters = [];
    popularAnimes = data['mostPopularAnimes'] ?? {};
    relatedAnimes = data['relatedAnimes'] ?? {};
    recommendedAnimes = data['recommendedAnimes'] ?? {};
    seasons = data['seasons'] ?? [];
    color = data['color'] ?? '??';
  }

  result = {
    'id': id,
    'name': name,
    'jname': jname,
    'description': description,
    'poster': poster,
    'cover': cover,
    'rating': rating,
    'genres': genres,
    'premiered': premiered,
    'totalEpisodes': totalEpisodes,
    'duration': duration,
    "stats": stats,
    'characters': characters,
    'popularAnimes': popularAnimes,
    'relatedAnimes': isConsumet
        ? extractRelationData(relatedAnimes, isConsumet)
        : relatedAnimes,
    'recommendedAnimes': isConsumet
        ? extractRelationData(recommendedAnimes, isConsumet)
        : recommendedAnimes,
    'seasons': seasons,
    'color': color,
  };

  return result;
}

dynamic extractRelationData(dynamic data, bool isConsumet) {
  List<Map<String, String>> result = [];
  dynamic filteredData =
      data?.where((item) => item?['type'] != "MANGA").toList();
  for (var item in filteredData) {
    String id = '??';
    String name = '??';
    String type = '??';
    String poster = '??';

    if (isConsumet) {
      id = item['id']?.toString() ?? '??';
      name = !isRomaji
          ? item['title']['english'].toString()
          : item['title']['romaji']?.toString() ?? '??';
      type = item['type']?.toString() ?? '??';
      poster = item['image']?.toString() ?? '??';
    } else {
      id = item['id']?.toString() ?? '??';
      name = (!isRomaji
          ? item['name']?.toString()
          : item['jname']?.toString() ?? '??')!;
      type = item['type']?.toString() ?? '??';
      poster = item['poster']?.toString() ?? '??';
    }

    result.add({"id": id, "name": name, "type": type, "poster": poster});
  }

  return result;
}

dynamic mergeEpisodesData(dynamic data) {
  dynamic result = [];
  result.addAll(data['episodes']);
  return result;
}

dynamic episodeDataExtraction(dynamic episodeData) {
  return episodeData.map((episode) {
    return {
      'episodeId': episode['id']?.toString() ?? '??',
      'title': episode['title'] ?? "Episode ${episode['number'].toString()}",
      'number': episode['number']?.toString() ?? '??',
      'image': episode['image']?.toString() ?? '??',
      'isFiller': episode['isFiller'] ?? false,
    };
  }).toList();
}
