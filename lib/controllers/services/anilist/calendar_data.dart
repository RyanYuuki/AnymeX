import 'dart:convert';

import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_cache.dart';
import 'package:anymex/controllers/services/anilist/anilist_error_handler.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';

const String url = 'https://graphql.anilist.co';

Future<void> fetchCalendarData(RxList<Media> callbackData,
    {int page = 1, bool force = false}) async {
  final isMAL = serviceHandler.serviceType.value == ServicesType.mal;
  if (page == 1 && !force) {
    final cached = await AnilistCache.instance.get('calendar_data');
    if (cached != null && cached['data'] is List) {
      final list = (cached['data'] as List)
          .map<Media?>((schedule) {
            final media =
                Media.fromSmallJson(schedule['media'], false, isMal: isMAL);
            if (media.isAdult ?? false) return null;
            return media
              ..nextAiringEpisode = NextAiringEpisode(
                  airingAt: schedule['airingAt'],
                  timeUntilAiring: schedule['timeUntilAiring'],
                  episode: schedule['episode']);
          })
          .whereType<Media>()
          .toList();
      if (list.isNotEmpty) {
        callbackData.addAll(list);
        return;
      }
    }
  }

  int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  int startTime = currentTime - 86400;
  int endTime = currentTime + (86400 * 6);

  const String query = '''
  query (\$page: Int, \$startTime: Int, \$endTime: Int) {
    Page(page: \$page, perPage: 50) {
      pageInfo {
        hasNextPage
      }
      airingSchedules(
        airingAt_greater: \$startTime,
        airingAt_lesser: \$endTime,
        sort: TIME_DESC,
      ) {
        episode
        airingAt
        timeUntilAiring
        media {
          id
          idMal
          isAdult
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

  final token = AuthKeys.authToken.get<String?>();
  final headers = {
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  final response = await NetworkManager.instance.compatibleClient.post(
    Uri.parse(url),
    headers: headers,
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

    List<Media> newMediaList = schedules
        .map<Media?>((schedule) {
          final media =
              Media.fromSmallJson(schedule['media'], false, isMal: isMAL);
          if (media.isAdult ?? false) return null;
          return media
            ..nextAiringEpisode = NextAiringEpisode(
                airingAt: schedule['airingAt'],
                timeUntilAiring: schedule['timeUntilAiring'],
                episode: schedule['episode']);
        })
        .toList()
        .whereType<Media>()
        .toList();

    callbackData.addAll(newMediaList);

    if (page == 1 && schedules is List) {
      AnilistCache.instance.put(
        'calendar_data',
        {'data': schedules},
        ttl: const Duration(hours: 2),
        persist: true,
      );
    }

    Logger.i('Fetched ${callbackData.length} total airing schedules so far.');

    if (pageInfo['hasNextPage'] && page < 4) {
      await fetchCalendarData(callbackData, page: page + 1, force: force);
    }
  } else {
    AnilistErrorHandler.handleResponse(response);
    Logger.i('Error: ${response.body}');
    final msg = AnilistErrorHandler.extractErrorMessage(response.body);
    throw Exception(msg ?? 'Failed to load AniList data: ${response.statusCode}');
  }
}
