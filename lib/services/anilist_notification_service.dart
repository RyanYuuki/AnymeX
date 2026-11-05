import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/database/kv_helper.dart';
import 'package:anymex/models/Anilist/anilist_notification.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/notification.dart';
import 'package:get/get.dart';

class AnilistNotificationService extends GetxService {
  static AnilistNotificationService get instance =>
      Get.find<AnilistNotificationService>();

  Timer? _pollingTimer;
  Worker? _authWorker;

  @override
  void onInit() {
    super.onInit();
    final anilistAuth = Get.find<AnilistAuth>();
    _authWorker = ever(anilistAuth.isLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        restartPolling();
      } else {
        stopPolling();
      }
    });

    if (anilistAuth.isLoggedIn.value) {
      restartPolling();
    }
  }

  @override
  void onClose() {
    _authWorker?.dispose();
    stopPolling();
    super.onClose();
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void restartPolling() {
    stopPolling();
    final enabled =
        KvHelper.get<bool>('anilist_notifications_enabled', defaultVal: true);
    if (!enabled) return;

    final mins =
        KvHelper.get<int>('anilist_polling_interval_minutes', defaultVal: 30);

    Future.delayed(const Duration(seconds: 4), () {
      pollNotifications();
    });

    _pollingTimer = Timer.periodic(Duration(minutes: mins), (_) {
      pollNotifications();
    });
  }

  Future<void> pollNotifications() async {
    try {
      final anilistAuth = Get.find<AnilistAuth>();
      if (!anilistAuth.isLoggedIn.value) return;

      final enabled =
          KvHelper.get<bool>('anilist_notifications_enabled', defaultVal: true);
      if (!enabled) return;

      final items = await anilistAuth.getNotifications(
        page: 1,
        perPage: 30,
        resetCount: false,
      );

      await anilistAuth.getUnreadNotificationCount();

      if (items.isEmpty) return;

      final lastSeen = KvHelper.get<int>(
          'last_seen_anilist_notification_timestamp',
          defaultVal: 0);

      if (lastSeen == 0) {
        KvHelper.set(
            'last_seen_anilist_notification_timestamp', items.first.createdAt);
        return;
      }

      final newItems =
          items.where((e) => e.createdAt > lastSeen).toList();
      if (newItems.isEmpty) return;

      final maxTimestamp =
          newItems.map((e) => e.createdAt).reduce(max);
      KvHelper.set(
          'last_seen_anilist_notification_timestamp', maxTimestamp);

      final allowAiring =
          KvHelper.get<bool>('anilist_notif_airing', defaultVal: true);
      final allowSocial =
          KvHelper.get<bool>('anilist_notif_social', defaultVal: true);
      final allowActivity =
          KvHelper.get<bool>('anilist_notif_activity', defaultVal: true);

      final eligible = newItems.where((e) {
        if (e.kind == AnilistNotificationKind.airing && !allowAiring) {
          return false;
        }
        if (e.kind == AnilistNotificationKind.social && !allowSocial) {
          return false;
        }
        if (e.kind == AnilistNotificationKind.activity && !allowActivity) {
          return false;
        }
        return true;
      }).toList();

      if (eligible.isEmpty) return;

      if (eligible.length <= 3) {
        for (final item in eligible) {
          NotificationService.instance.showRichNotification(
            id: item.id != 0
                ? item.id
                : DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: item.displayTitle,
            body: item.displayBody,
            imageUrl: item.thumbnail,
            channelId: item.kind == AnilistNotificationKind.airing
                ? 'anilist_airing'
                : 'anilist_social',
            payload: jsonEncode({
              'source': 'anilist',
              'kind': item.kind.name,
              'media_id': item.mediaId,
              'user_id': item.userId,
              'activity_id': item.activityId,
            }),
          );
        }
      } else {
        final summaryText =
            eligible.take(3).map((e) => '• ${e.displayBody}').join('\n');
        NotificationService.instance.showRichNotification(
          id: 999001,
          title: '${eligible.length} New AniList Updates',
          body: '$summaryText\n+${eligible.length - 3} more',
          channelId: 'anilist_social',
          payload: jsonEncode({
            'source': 'anilist',
            'kind': 'digest',
          }),
        );
      }
    } catch (e) {
      Logger.i('Error during AniList notifications poll: $e');
    }
  }

  Future<void> markAllRead() async {
    try {
      final anilistAuth = Get.find<AnilistAuth>();
      await anilistAuth.getNotifications(page: 1, resetCount: true);
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      KvHelper.set('last_seen_anilist_notification_timestamp', nowSeconds);
      anilistAuth.unreadAnilistCount.value = 0;
    } catch (e) {
      Logger.i('Error marking notifications as read: $e');
    }
  }

  void updateLastSeenTimestamp(int timestamp) {
    final current = KvHelper.get<int>(
        'last_seen_anilist_notification_timestamp',
        defaultVal: 0);
    if (timestamp > current) {
      KvHelper.set('last_seen_anilist_notification_timestamp', timestamp);
    }
  }
}
