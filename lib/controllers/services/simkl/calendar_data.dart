import 'dart:convert';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> fetchSimklCalendarData(RxList<Media> callbackData, {bool isMovies = false}) async {
  final String url = isMovies 
      ? 'https://data.simkl.in/calendar/movie_release.json'
      : 'https://data.simkl.in/calendar/tv.json';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final List<dynamic> schedules = json.decode(response.body);
    final isMAL = serviceHandler.serviceType.value == ServicesType.mal;
    final Set<String> seenIds = {};
    
    List<Media> newMediaList = schedules
        .map<Media?>((schedule) {
          final id = schedule['ids']?['simkl_id']?.toString() ?? 
                     schedule['ids']?['simkl']?.toString() ?? 
                     schedule['url']?.toString();
          if (id != null && seenIds.contains(id)) {
            return null;
          }
          if (id != null) {
            seenIds.add(id);
          }
          
          final media = Media.fromSmallSimkl(schedule, !isMovies);
          return media;
        })
        .toList()
        .whereType<Media>()
        .toList();

    callbackData.addAll(newMediaList);

    Logger.i('Fetched ${callbackData.length} total Simkl calendar items (${seenIds.length} unique) so far.');
  } else {
    Logger.i('Error: ${response.body}');
    throw Exception('Failed to load Simkl calendar data: ${response.statusCode}');
  }
}
