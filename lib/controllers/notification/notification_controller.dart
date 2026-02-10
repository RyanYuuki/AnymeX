
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/anilist/anilist_queries.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/notification_service.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:anymex/utils/logger.dart';

class NotificationController extends GetxController {
  final anilistAuth = Get.find<AnilistAuth>();
  var airingSchedule = <Media>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAiringSchedule();
  }
  
  Future<void> fetchAiringSchedule() async {
    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': airingScheduleQuery,
          'variables': {
            'page': 1,
            'perPage': 20,
            'airingAtGreater': (DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch / 1000).round(),
            'airingAtLesser': (DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch / 1000).round(),
          }
        }), 
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final mediaList = data['data']['Page']['airingSchedules'];
        
        // Filter based on user's anime list if logged in
        final userAnimeIds = anilistAuth.animeList.map((e) => e.id).toSet();
        
        final List<Media> schedules = [];
        
        for (var item in mediaList) {
           final media = Media.fromSmallJson(item['media'], false);
           media.nextAiringEpisode = item['episode'];
           media.description = "Aired at ${DateTime.fromMillisecondsSinceEpoch(item['airingAt'] * 1000).toString()}";
           // Store airing time for sort
           media.extraData = item['airingAt'].toString();
           
           if (anilistAuth.isLoggedIn.value) {
             if (userAnimeIds.contains(media.id)) {
               schedules.add(media);
               _checkAndNotify(media, item['airingAt']);
             }
           } else {
             // If not logged in, just show popular ones
             schedules.add(media);
           }
        }
        
        // Sort by airing time (most recent first)
        schedules.sort((a, b) => int.parse(b.extraData!).compareTo(int.parse(a.extraData!)));
        
        airingSchedule.value = schedules;
      } else {
        Logger.e("Failed to fetch airing schedule: ${response.body}");
      }
    } catch (e) {
      Logger.e("Error fetching airing schedule: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _checkAndNotify(Media media, int airingAt) {
      // Simple logic: if aired within last 1 hour, show notification
      // In a real background task, you'd store notified IDs to avoid duplicates
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      if (now - airingAt < 3600 && now >= airingAt) {
          NotificationService.showNotification(
            media.hashCode,
            "New Episode Released!",
            "${media.title} Episode ${media.nextAiringEpisode} is out now!",
            media.id,
          );
      }
  }
}
