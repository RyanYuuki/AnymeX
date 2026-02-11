import 'package:workmanager/workmanager.dart';
import 'package:anymex/utils/notification_service.dart';
import 'package:anymex/controllers/services/anilist/anilist_queries.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:anymex/utils/logger.dart';

const String fetchBackgroundEpisodeTask = "fetchBackgroundEpisodeTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == fetchBackgroundEpisodeTask) {
      try {
        await Logger.init();
        await NotificationService.init();
        await Hive.initFlutter('AnymeX');
        await Hive.openBox('auth');
        final authBox = Hive.box('auth');
        final token = authBox.get('auth_token');

        if (token == null) {
          Logger.i("Background: No auth token, skipping check.");
          return Future.value(true);
        }

        await _pollNotifications(token);
      } catch (e) {
        Logger.e("Background Task Error: $e");
      }
    }
    return Future.value(true);
  });
}

Future<void> _pollNotifications(String token) async {
  final authBox = Hive.box('auth');
  final lastNotificationId = authBox.get('last_notification_id', defaultValue: 0);

  final response = await http.post(
    Uri.parse('https://graphql.anilist.co'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({
      'query': notificationQuery,
      'variables': {
        'page': 1,
        'perPage': 10, // Check last 10
      }
    }),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final notifications = data['data']['Page']['notifications'] as List;
    
    // Sort logic? API returns newest first.
    // We want to process them.
    
    int maxId = lastNotificationId;

    for (var item in notifications) {
      final id = item['id'] as int;
      if (id > lastNotificationId) {
        // New notification!
        final type = item['type'];
        String title = "New Notification";
        String body = "You have a new update.";
        
        if (type == 'AIRING') {
          final showTitle = item['media']['title']['userPreferred'];
          final episode = item['episode'];
          final context = item['contexts']?[0] ?? item['context'] ?? "aired";
          
          title = "Episode Released";
          // "Attack on Titan Episode 5 aired"
          body = "$showTitle Episode $episode $context";
        } else if (type == 'RELATED_MEDIA_ADDITION') {
          final showTitle = item['media']['title']['userPreferred'];
          final context = item['context'] ?? "New related media";
           title = "New Related Anime";
           body = "$showTitle: $context";
        }

        if (id > maxId) maxId = id;

        NotificationService.showNotification(
          id,
          title,
          body,
          item['media']['id'].toString(),
        );
      }
    }
    
    // Update last seen ID
    if (maxId > lastNotificationId) {
      authBox.put('last_notification_id', maxId);
      Logger.i("Background: Updated last_notification_id to $maxId");
    }
  } else {
    Logger.e("Background: Failed to fetch notifications: ${response.body}");
  }
}
