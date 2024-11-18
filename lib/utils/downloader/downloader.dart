import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class Downloader {
  int _notificationId = 0;
  final Map<int, bool> _cancellationTokens = {};
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late int parallelDownloads;
  late int retries;

  Downloader() {
    _initializeNotifications();
    parallelDownloads =
        Hive.box('app-data').get('parallelDownloads', defaultValue: 5);
    retries = Hive.box('app-data').get('downloadRetries', defaultValue: 3);
  }

  Future<void> _initializeNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_rounded_launcher');
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId != null &&
            response.actionId!.startsWith('cancel_')) {
          final notificationId = int.parse(response.actionId!.substring(7));
          cancelDownload(notificationId);
        }
      },
    );
  }

  Future<bool> checkPermission() async {
    final os = await DeviceInfoPlugin().androidInfo;
    final sdkVer = os.version.sdkInt;
    final access =
        sdkVer > 32 ? Permission.manageExternalStorage : Permission.storage;

    final status = await access.request();
    return status.isGranted;
  }

  Future<bool> checkNotificationPermission() async {
    final permissionStatus = await Permission.notification.status;
    if (!permissionStatus.isGranted) {
      await Permission.notification.request();
    }
    return permissionStatus.isGranted;
  }

  String _makeBaseLink(String uri) =>
      uri.split('/').takeWhile((part) => !part.endsWith('.m3u8')).join('/');

  Future<void> download(
    String streamLink,
    String fileName,
    String folderName,
  ) async {
    if (!await checkPermission()) {
      throw Exception("ERR_NO_STORAGE_PERMISSION");
    }
    if (!await checkNotificationPermission()) {
      throw Exception("ERR_NO_NOTIFICATION_PERMISSION");
    }

    final notificationId = _notificationId++;
    _cancellationTokens[notificationId] = false;

    await _showDownloadNotification(notificationId, '$folderName - $fileName',
        progress: 0);

    final downloadDir =
        Directory('/storage/emulated/0/Download/AnymeX/$folderName');
    if (!downloadDir.existsSync()) {
      await downloadDir.create(recursive: true);
    }

    final outputPath = '${downloadDir.path}/$fileName.mp4';
    final output = File(outputPath);

    try {
      final segments = await _getSegments(streamLink);
      if (segments.isEmpty) throw Exception("No segments found.");

      final buffers = <BufferItem>[];
      final baseUri = _makeBaseLink(streamLink);

      final tasks = <Future<void>>[];
      for (int i = 0; i < segments.length; i++) {
        if (_cancellationTokens[notificationId] ?? false) {
          await flutterLocalNotificationsPlugin.cancel(notificationId);
          if (await output.exists()) await output.delete();
          await _showCancellationNotification(
              notificationId, '$folderName - $fileName');
          return;
        }

        if (tasks.length >= parallelDownloads) {
          await Future.wait(tasks);
          tasks.clear();
        }

        final segmentUri = segments[i].startsWith('http')
            ? segments[i]
            : '$baseUri/${segments[i]}';
        tasks.add(_downloadAndStoreSegment(segmentUri, i, buffers, retries,
            notificationId, segments.length, '$folderName - $fileName'));
      }

      await Future.wait(tasks);

      buffers.sort((a, b) => a.index.compareTo(b.index));
      await _writeToFile(output, buffers);

      await _showCompletionNotification(
          notificationId, '$folderName - $fileName');
    } catch (err) {
      if (await output.exists()) await output.delete();
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      throw Exception("Download failed: $err");
    } finally {
      _cancellationTokens.remove(notificationId);
    }
  }

  Future<void> _downloadAndStoreSegment(
    String url,
    int index,
    List<BufferItem> buffers,
    int retries,
    int notificationId,
    int totalSegments,
    String notificationTitle,
  ) async {
    if (_cancellationTokens[notificationId] ?? false) return;

    final response = await _downloadSegmentWithRetry(url, retries);
    buffers.add(BufferItem(index: index, buffer: response.bodyBytes));

    // Print progress to console: e.g., "1/300"
    print("${buffers.length}/$totalSegments");

    await _updateDownloadNotification(notificationId, notificationTitle,
        (buffers.length / totalSegments) * 100);
  }

  Future<Response> _downloadSegmentWithRetry(String url, int maxRetries) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        attempt++;
        return await get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      } catch (err) {
        if (attempt >= maxRetries) throw Exception("Max retries reached: $err");
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
    throw Exception("Failed to download segment after retries.");
  }

  Future<List<String>> _getSegments(String url) async {
    final response = await get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception(
          "Failed to fetch segments. HTTP Status: ${response.statusCode}");
    }
    return response.body
        .split('\n')
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
  }

  Future<void> _writeToFile(File file, List<BufferItem> buffers) async {
    final sink = file.openWrite();
    for (final buffer in buffers) {
      sink.add(buffer.buffer);
    }
    await sink.close();
  }

  Future<void> _showDownloadNotification(int id, String title,
      {double progress = 0}) async {
    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Notifications for ongoing downloads',
      importance: Importance.max,
      priority: Priority.high,
      showProgress: true,
      maxProgress: 100,
      progress: progress.toInt(),
      ongoing: true,
      onlyAlertOnce: true,
      actions: [
        AndroidNotificationAction(
          'cancel_$id',
          'Cancel',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );
    final notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(id, 'Downloading $title',
        'Progress: ${progress.toInt()}%', notificationDetails);
  }

  Future<void> _updateDownloadNotification(
      int id, String title, double progress) async {
    await _showDownloadNotification(id, title, progress: progress);
  }

  Future<void> _showCompletionNotification(int id, String title) async {
    const androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Notifications for completed downloads',
      importance: Importance.max,
      priority: Priority.high,
      onlyAlertOnce: true,
      ongoing: false,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(id, 'Download Complete',
        '$title has finished downloading.', notificationDetails);
  }

  Future<void> _showCancellationNotification(int id, String title) async {
    const androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Notifications for cancelled downloads',
      importance: Importance.max,
      priority: Priority.high,
      onlyAlertOnce: true,
      ongoing: false,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(id, 'Download Cancelled',
        '$title has been cancelled.', notificationDetails);
  }

  void cancelDownload(int notificationId) {
    _cancellationTokens[notificationId] = true;
  }
}

class BufferItem {
  final int index;
  final Uint8List buffer;

  BufferItem({required this.index, required this.buffer});
}
