import 'dart:io';
import 'package:anymex/firebase_options.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
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

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    try {
      await messaging.subscribeToTopic('all');
    } catch (_) {}

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleMessage(message);
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      handleMessage(initialMessage);
    }
  }

  static void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    if (message.messageId != null &&
        message.messageId == _lastHandledMessageId) {
      return;
    }
    _lastHandledMessageId = message.messageId;

    final title = message.data['title']?.toString() ??
        message.notification?.title ??
        'Notification';

    final description = message.data['description']?.toString() ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        message.notification?.body ??
        '';

    _showNotificationDialog(title, description);
  }

  static void _showNotificationDialog(String title, String description) {
    void tryShow() {
      final context = Get.key.currentContext ?? Get.context;
      if (context != null) {
        AnymeXDialog(
          title: title,
          message: description,
          confirmText: 'Okay',
          showCancelButton: false,
          onConfirm: () {},
        ).show(context);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 500), tryShow);
        });
      }
    }

    tryShow();
  }
}
