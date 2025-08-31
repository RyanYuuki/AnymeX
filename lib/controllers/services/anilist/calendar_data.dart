import 'dart:convert';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

const String url = 'https://graphql.anilist.co';

Future<void> fetchCalendarData(RxList<Media> callbackData,
    {int page = 1}) async {
  int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  int startTime = currentTime - 86400;
  int endTime = currentTime + (86400 * 6);
  final isMAL = serviceHandler.serviceType.value == ServicesType.mal;

  const String query = '''
    query (\$page: Int, \$startTime: Int, \$endTime: Int) {
      Page(page: \$page, perPage: 50) {
        pageInfo {
          hasNextPage
        }
        airingSchedules(
          airingAt_greater: \$startTime,
          airingAt_lesser: \$endTime,
          sort: TIME_DESC
        ) {
          episode
          airingAt
          timeUntilAiring
          media {
            id
            idMal
            status
            averageScore
            coverImage { 
              large 
            }
            title {
              english
              romaji
            }
          }
        }
      }
    }
  ''';

  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'query': query,
      'variables': {
        'page': page,
        'startTime': startTime,
        'endTime': endTime,
      },
    }),
  );

  if (response.statusCode == 200) {
    final responseData = json.decode(response.body);
    final pageInfo = responseData['data']['Page']['pageInfo'];
    final schedules = responseData['data']['Page']['airingSchedules'];

    List<Media> newMediaList = schedules.map<Media>((schedule) {
      return Media.fromSmallJson(schedule['media'], false, isMal: isMAL)
        ..nextAiringEpisode = NextAiringEpisode(
            airingAt: schedule['airingAt'],
            timeUntilAiring: schedule['timeUntilAiring'],
            episode: schedule['episode']);
    }).toList();

    callbackData.addAll(newMediaList);

    Logger.i('Fetched ${callbackData.length} total airing schedules so far.');

    if (pageInfo['hasNextPage']) {
      await fetchCalendarData(callbackData, page: page + 1);
    }
  } else {
    Logger.i('Error: ${response.body}');
    throw Exception('Failed to load AniList data: ${response.statusCode}');
  }
}
