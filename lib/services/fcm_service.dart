import 'dart:io';
import 'package:anymex/firebase_options.dart';
import 'package:anymex/utils/notification.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/non_widgets/in_app_notification_banner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class FcmService {
  static String? _lastHandledMessageId;

  static Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // alert: false — foreground visuals come from our in-app top banner.
    // Leaving the OS banner on would double-show every push (OS banner +
    // banner). Badge + sound still apply.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

    try {
      await messaging.subscribeToTopic('all');
    } catch (_) {}

    // Foreground: lightweight top banner (never a blocking dialog).
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      handleForegroundMessage(message);
    });

    // Tapped from system tray / killed state: navigate straight in.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleOpenedMessage(message);
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      handleOpenedMessage(initialMessage);
    }
  }

  static void handleForegroundMessage(RemoteMessage? message) {
    if (message == null) return;

    if (message.messageId != null &&
        message.messageId == _lastHandledMessageId) {
      return;
    }
    _lastHandledMessageId = message.messageId;

    final title = message.data['title']?.toString() ??
        message.notification?.title ??
        'Notification';

    final description = message.data['body']?.toString() ??
        message.data['description']?.toString() ??
        message.data['message']?.toString() ??
        message.notification?.body ??
        '';

    final avatarUrl = message.data['actor_avatar']?.toString();
    final actorId = message.data['actor_id']?.toString();
    final type = message.data['type']?.toString();
    final data = Map<String, dynamic>.from(message.data);

    showInAppNotification(
      title: title,
      body: description,
      avatarUrl: (avatarUrl == null || avatarUrl.isEmpty) ? null : avatarUrl,
      userId: (actorId == null || actorId.isEmpty) ? null : actorId,
      type: type,
      onTap: () => _openFromData(data),
    );
  }

  /// Backwards-compatible entry point (foreground only).
  static void handleMessage(RemoteMessage? message) =>
      handleForegroundMessage(message);

  static void handleOpenedMessage(RemoteMessage? message) {
    if (message == null) return;
    _openFromData(Map<String, dynamic>.from(message.data));
  }

  static void _openFromData(Map<String, dynamic> data) {
    if (Get.isRegistered<NotificationService>()) {
      Get.find<NotificationService>().navigateFromPush(data);
      return;
    }
    // Fallback when the notification service isn't up yet.
    final context = Get.key.currentContext ?? Get.context;
    if (context == null) return;
    AnymeXDialog(
      title: data['title']?.toString() ?? 'Notification',
      message: data['body']?.toString() ?? '',
      confirmText: 'Okay',
      showCancelButton: false,
      onConfirm: () {},
    ).show(context);
  }
}
