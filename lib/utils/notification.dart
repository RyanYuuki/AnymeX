import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final data = message.data;
  final title = data['title'] as String? ?? 'Notification';
  final body = data['body'] as String? ?? '';
  final actorAvatar = data['actor_avatar'] as String?;
  final channelId = data['channel_id'] as String? ?? 'comments';

  final localNotifications = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@drawable/ic_stat_anymex');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await localNotifications.initialize(settings);

  ByteArrayAndroidBitmap? avatarBitmap;
  if (actorAvatar != null && actorAvatar.isNotEmpty) {
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(actorAvatar));
      final response = await request.close();
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      final uint8list = Uint8List.fromList(bytes);
      httpClient.close();
      avatarBitmap = ByteArrayAndroidBitmap(uint8list);
    } catch (_) {}
  }

  final androidDetails = AndroidNotificationDetails(
    channelId,
    _getChannelName(channelId),
    importance: _getChannelImportance(channelId),
    priority: Priority.high,
    icon: '@drawable/ic_stat_anymex',
    largeIcon: avatarBitmap,
    playSound: true,
    enableVibration: true,
  );

  await localNotifications.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: jsonEncode(data),
  );
}

String _getChannelName(String channelId) {
  switch (channelId) {
    case 'votes': return 'Votes';
    case 'moderation': return 'Moderation';
    case 'reports': return 'Reports';
    case 'announcements': return 'Announcements';
    case 'mentions': return 'Mentions';
    default: return 'Comments';
  }
}

Importance _getChannelImportance(String channelId) {
  switch (channelId) {
    case 'comments':
    case 'moderation':
    case 'announcements':
    case 'mentions':
      return Importance.high;
    default:
      return Importance.defaultImportance;
  }
}

class NotificationService extends GetxController {
  static NotificationService get instance => Get.find<NotificationService>();

  FirebaseMessaging? _firebaseMessaging;
  FlutterLocalNotificationsPlugin? _localNotifications;

  final RxnString fcmToken = RxnString(null);
  final RxBool notificationsEnabled = true.obs;

  VoidCallback? onNotificationTap;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    try {
      if (Firebase.apps.isEmpty) {
        Logger.i('NotificationService: Firebase not initialized, skipping');
        return;
      }

      _firebaseMessaging = FirebaseMessaging.instance;
      _localNotifications = FlutterLocalNotificationsPlugin();

      await _setupLocalNotifications();
      await _setupFirebaseMessaging();
      await _requestPermission();
    } catch (e) {
      Logger.e('NotificationService init error: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    final local = _localNotifications;
    if (local == null) return;

    const androidSettings = AndroidInitializationSettings('@drawable/ic_stat_anymex');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await local.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      final androidPlugin = local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) return;

      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'comments',
        'Comments',
        description: 'New comments, replies, and edits',
        importance: Importance.high,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'votes',
        'Votes',
        description: 'Upvotes and downvotes on your comments',
        importance: Importance.defaultImportance,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'moderation',
        'Moderation',
        description: 'Warnings, mutes, bans, and moderation actions',
        importance: Importance.high,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'reports',
        'Reports',
        description: 'Report filed, resolved, dismissed',
        importance: Importance.defaultImportance,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'announcements',
        'Announcements',
        description: 'Official announcements',
        importance: Importance.high,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'mentions',
        'Mentions',
        description: 'When someone @mentions you in a comment',
        importance: Importance.high,
      ));
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    final fm = _firebaseMessaging;
    if (fm == null) return;

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    try {
      final initialMessage = await fm.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      Logger.e('Error getting initial message: $e');
    }

    fm.onTokenRefresh.listen((newToken) {
      Logger.i('FCM token refreshed');
      fcmToken.value = newToken;
      _registerTokenWithBackend(newToken);
    });
  }

  Future<void> _requestPermission() async {
    final fm = _firebaseMessaging;
    if (fm == null) return;

    try {
      final settings = await fm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final authorized = settings.authorizationStatus == AuthorizationStatus.authorized;
      final provisional = settings.authorizationStatus == AuthorizationStatus.provisional;
      notificationsEnabled.value = authorized || provisional;

      if (notificationsEnabled.value) {
        final token = await fm.getToken();
        if (token != null) {
          fcmToken.value = token;
          Logger.i('FCM token obtained: ${token.substring(0, 20)}...');
          _registerTokenWithBackend(token);
        }
      }
    } catch (e) {
      Logger.e('Error requesting notification permission: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    try {
      final local = _localNotifications;
      if (local == null) return;

      final data = message.data;
      final title = data['title'] as String? ?? message.notification?.title ?? 'Notification';
      final body = data['body'] as String? ?? message.notification?.body ?? '';
      final actorAvatar = data['actor_avatar'] as String?;
      final channelId = data['channel_id'] as String? ?? 'comments';

      AndroidNotificationDetails androidDetails;
      if (actorAvatar != null && actorAvatar.isNotEmpty) {
        try {
          final httpClient = HttpClient();
          final request = await httpClient.getUrl(Uri.parse(actorAvatar));
          final response = await request.close();
          final bytes = <int>[];
          await for (final chunk in response) {
            bytes.addAll(chunk);
          }
          final uint8list = Uint8List.fromList(bytes);
          httpClient.close();

          androidDetails = AndroidNotificationDetails(
            channelId,
            _getChannelNameForService(channelId),
            importance: _getChannelImportanceForService(channelId),
            priority: Priority.high,
            icon: '@drawable/ic_stat_anymex',
            largeIcon: ByteArrayAndroidBitmap(uint8list),
          );
        } catch (e) {
          Logger.e('Failed to load avatar for notification: $e');
          androidDetails = AndroidNotificationDetails(
            channelId,
            _getChannelNameForService(channelId),
            importance: _getChannelImportanceForService(channelId),
            priority: Priority.high,
            icon: '@drawable/ic_stat_anymex',
          );
        }
      } else {
        androidDetails = AndroidNotificationDetails(
          channelId,
          _getChannelNameForService(channelId),
          importance: _getChannelImportanceForService(channelId),
          priority: Priority.high,
          icon: '@drawable/ic_stat_anymex',
        );
      }

      local.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: androidDetails,
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(data),
      );
    } catch (e) {
      Logger.e('Error showing foreground notification: $e');
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    Logger.i('Notification tapped: ${message.data}');
    onNotificationTap?.call();
    _navigateFromNotification(message.data);
  }

  ServicesType? _serviceTypeFromClientType(String clientType) {
    switch (clientType.toLowerCase()) {
      case 'anilist':
        return ServicesType.anilist;
      case 'mal':
      case 'myanimelist':
        return ServicesType.mal;
      case 'simkl':
        return ServicesType.simkl;
      default:
        return null;
    }
  }

  void _navigateFromNotification(Map<String, dynamic> data, {int attempts = 0}) {
    final mediaId = data['media_id']?.toString();
    final mediaType = data['media_type']?.toString();
    final commentId = data['comment_id']?.toString();
    final clientType = data['client_type']?.toString() ?? 'anilist';

    if (mediaId == null || mediaId.isEmpty || mediaType == null) {
      final clickAction = data['click_action'] as String?;
      if (clickAction != null && clickAction.isNotEmpty && clickAction.startsWith('anymex://')) {
        Logger.i('Navigating via click_action (fallback): $clickAction');
      }
      Logger.i('Notification has no navigable media info');
      return;
    }

    if (!Get.isRegistered<ServiceHandler>() || Get.context == null) {
      if (attempts >= 300) {
        Logger.i('Notification nav timed out after 60s');
        return;
      }
      Future.delayed(const Duration(milliseconds: 200), () {
        _navigateFromNotification(data, attempts: attempts + 1);
      });
      return;
    }

    final type = mediaType.toLowerCase();
    final isManga = type == 'manga' || type == 'novel';
    final handler = Get.find<ServiceHandler>();

    final serviceType = _serviceTypeFromClientType(clientType) ?? handler.serviceType.value;

    if (handler.serviceType.value != serviceType) {
      handler.changeService(serviceType);
    }

    final media = Media(
      id: mediaId,
      serviceType: serviceType,
      mediaType: isManga ? ItemType.manga : ItemType.anime,
    );

    final tag = 'fcm-${DateTime.now().millisecondsSinceEpoch}';

    Logger.i('Navigating to media: $mediaId ($type) on $serviceType');

    if (isManga) {
      navigate(() => MangaDetailsPage(
        media: media,
        tag: tag,
        initialTabIndex: 2,
        scrollToCommentId: commentId,
      ));
    } else {
      navigate(() => AnimeDetailsPage(
        media: media,
        tag: tag,
        initialTabIndex: 2,
        scrollToCommentId: commentId,
      ));
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      if (Get.isRegistered<CommentumService>()) {
        final service = Get.find<CommentumService>();
        await service.getUnreadNotificationCount();
        Logger.i('Unread notification count refreshed');
      }
    } catch (e) {
      Logger.i('Error refreshing unread count: $e');
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      if (Get.isRegistered<CommentumService>()) {
        final service = Get.find<CommentumService>();
        await service.registerFcmToken(token);
        Logger.i('FCM token registered with backend');
      } else {
        Logger.i('CommentumService not yet registered, token will be registered later');
      }
    } catch (e) {
      Logger.e('Failed to register FCM token: $e');
    }
  }

  String _getChannelNameForService(String channelId) {
    switch (channelId) {
      case 'votes': return 'Votes';
      case 'moderation': return 'Moderation';
      case 'reports': return 'Reports';
      case 'announcements': return 'Announcements';
      case 'mentions': return 'Mentions';
      default: return 'Comments';
    }
  }

  Importance _getChannelImportanceForService(String channelId) {
    switch (channelId) {
      case 'comments':
      case 'moderation':
      case 'announcements':
      case 'mentions':
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  String? getToken() => fcmToken.value;

  Future<bool> registerToken({
    required String token,
    required String clientType,
    required String userId,
  }) async {
    try {
      Logger.i('FCM token registered for user $userId ($clientType)');
      return true;
    } catch (e) {
      Logger.e('Failed to register token: $e');
      return false;
    }
  }

  Future<bool> unregisterToken({
    required String token,
    required String clientType,
    required String userId,
  }) async {
    try {
      Logger.i('FCM token unregistered for user $userId');
      return true;
    } catch (e) {
      Logger.e('Failed to unregister token: $e');
      return false;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    Logger.i('Local notification tapped: ${response.payload}');
    onNotificationTap?.call();
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _navigateFromNotification(data);
      } catch (e) {
        Logger.e('Error parsing notification payload: $e');
      }
    }
  }
}
