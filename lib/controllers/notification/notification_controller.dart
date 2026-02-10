import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/anilist/anilist_queries.dart';
import 'package:anymex/models/Anilist/anilist_notification.dart';
import 'package:anymex/utils/notification_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:anymex/utils/logger.dart';

class NotificationController extends GetxController {
  final anilistAuth = Get.find<AnilistAuth>();
  var notifications = <AnilistNotification>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    
    // Refetch when user list changes (login/sync)
    ever(anilistAuth.animeList, (_) {
      fetchNotifications();
    });
  }
  
  Future<void> fetchNotifications() async {
    if (!anilistAuth.isLoggedIn.value) {
      notifications.clear();
      return;
    }

    final token = anilistAuth.storage.get('auth_token');

    isLoading.value = true;
    try {
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
            'perPage': 30,
          }
        }), 
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rawNotifications = data['data']['Page']['notifications'] as List;
        
        notifications.value = rawNotifications
            .map((e) => AnilistNotification.fromJson(e))
            .toList();
            
      } else {
        Logger.e("Failed to fetch notifications: ${response.body}");
      }
    } catch (e) {
      Logger.e("Error fetching notifications: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
