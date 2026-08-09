import 'dart:convert';

import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

Future<void> fetchSimklCalendarData(RxList<Media> callbackData, {bool isMovies = false}) async {
  final String url = isMovies 
      ? 'https://data.simkl.in/calendar/movie_release.json'
      : 'https://data.simkl.in/calendar/tv.json';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final List<dynamic> schedules = json.decode(response.body);
    final Set<String> seenKeys = {};
    
    List<Media> newMediaList = schedules
        .map<Media?>((schedule) {
          final baseId = schedule['ids']?['simkl_id']?.toString() ?? 
                         schedule['ids']?['simkl']?.toString() ?? 
                         schedule['url']?.toString() ?? '';
          final ep = schedule['episode'];
          final epKey = ep is Map ? '-S${ep['season']}E${ep['episode']}' : '';
          final dateKey = schedule['date']?.toString() ?? '';
          final uniqueKey = '$baseId$epKey-$dateKey';

          if (uniqueKey.isNotEmpty && seenKeys.contains(uniqueKey)) {
            return null;
          }
          if (uniqueKey.isNotEmpty) {
            seenKeys.add(uniqueKey);
          }
          
          final media = Media.fromSmallSimkl(schedule, isMovies);
          return media;
        })
        .toList()
        .whereType<Media>()
        .toList();

    callbackData.addAll(newMediaList);

    Logger.i('Fetched ${callbackData.length} total Simkl calendar items (${seenKeys.length} unique) so far.');
  } else {
    Logger.i('Error: ${response.body}');
    throw Exception('Failed to load Simkl calendar data: ${response.statusCode}');
  }
}
