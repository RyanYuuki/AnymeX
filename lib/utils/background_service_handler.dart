import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:anymex/utils/media_downloader.dart';
import 'package:anymex/utils/download_isolate_pool.dart' as dl;
import 'package:path/path.dart' as p;

@pragma('vm:entry-point')
void startBackgroundService() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(BackgroundDownloadTaskHandler());
}

class BackgroundDownloadTaskHandler extends TaskHandler {
  SendPort? _uiSendPort;
  ReceivePort? _bgReceivePort;

  final List<Map<String, dynamic>> _hlsQueue = [];
  final List<Map<String, dynamic>> _mangaQueue = [];

  bool _isProcessingHls = false;
  bool _isProcessingManga = false;
  bool _isUiReady = false;
  bool _pendingTap = false;

  Map<String, dynamic>? _activeHlsTask;
  Map<String, dynamic>? _activeMangaTask;
  double _hlsProgress = 0.0;
  double _mangaProgress = 0.0;

  final Set<String> _cancelledTasks = {};
  final Map<String, Map<String, dynamic>> _completedResults = {};

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    WidgetsFlutterBinding.ensureInitialized();
    _uiSendPort = sendPort;
    _bgReceivePort = ReceivePort();

    IsolateNameServer.removePortNameMapping('anymex_bg_port');
    IsolateNameServer.registerPortWithName(
        _bgReceivePort!.sendPort, 'anymex_bg_port');

    _bgReceivePort?.listen((message) {
      if (message is String) {
        _handleIncomingData(message);
      }
    });

    _uiSendPort?.send(_bgReceivePort?.sendPort);
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {}

  @override
  void onNotificationPressed() {
    if (_isUiReady) {
      _sendNotificationTapped();
    } else {
      _pendingTap = true;
    }
    FlutterForegroundTask.launchApp();
  }

  void _sendNotificationTapped() {
    _uiSendPort?.send(jsonEncode({'type': 'NOTIFICATION_TAPPED'}));
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    _bgReceivePort?.close();
  }

  void _handleIncomingData(String data) {
    try {
      final payload = jsonDecode(data) as Map<String, dynamic>;
      final type = payload['type'];
      final taskId = payload['taskId'];

      if (type == 'ADD_HLS') {
        _hlsQueue.add(payload);
        _processHlsQueue();
      } else if (type == 'ADD_MANGA') {
        _mangaQueue.add(payload);
        _processMangaQueue();
      } else if (type == 'CANCEL_TASK') {
        _cancelledTasks.add(taskId);
        dl.DownloadIsolatePool.instance.cancelTask(taskId);
        _uiSendPort?.send(jsonEncode({
          'type': 'TASK_CANCELLED',
          'taskId': taskId,
        }));
      } else if (type == 'GET_STATUS') {
        _sendStatusUpdate();
      } else if (type == 'UI_READY') {
        _isUiReady = true;
        if (_pendingTap) {
          _sendNotificationTapped();
          _pendingTap = false;
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _executeHlsTask(Map<String, dynamic> task) async {
    final taskId = task['taskId'] as String;
    final m3u8Url = task['m3u8Url'] as String;
    final fileName = task['fileName'] as String;
    final subDirectory = task['subDirectory'] as String;
    final headersraw = task['headers'] as Map<String, dynamic>?;
    final parallelSegments = task['parallelSegments'] as int? ?? 3;
    final docsPath = task['docsPath'] as String?;

    final headers = headersraw?.map((k, v) => MapEntry(k, v.toString()));

    _uiSendPort?.send(jsonEncode({
      'type': 'TASK_UPDATE',
      'taskId': taskId,
      'status': 'downloading',
      'progress': 0.0,
    }));

    final fullDirPath = p.join(docsPath ?? '', subDirectory);

    final mDownloader = MediaDownloader(
      taskId: taskId,
      itemType: ItemType.anime,
      m3u8Url: m3u8Url,
      videoFileName: fileName,
      subDownloadDir: fullDirPath,
      headers: headers,
      concurrentDownloads: parallelSegments,
    );

    try {
      await mDownloader.download((prog) {
        _hlsProgress = prog.completed / prog.total;
        FlutterForegroundTask.updateService(
          notificationTitle: 'Downloading Anime',
          notificationText:
              '$fileName: ${(_hlsProgress * 100).toStringAsFixed(0)}%',
        );

        _uiSendPort?.send(jsonEncode({
          'type': 'TASK_UPDATE',
          'taskId': taskId,
          'status': 'downloading',
          'progress': _hlsProgress,
        }));
      });

      if (_cancelledTasks.contains(taskId)) return;

      final msg = {
        'type': 'TASK_UPDATE',
        'taskId': taskId,
        'status': 'completed',
        'progress': 1.0,
        'filePath': p.join(fullDirPath, fileName),
      };
      _completedResults[taskId] = msg;
      _uiSendPort?.send(jsonEncode(msg));
    } catch (e) {
      if (_cancelledTasks.contains(taskId)) return;
      _uiSendPort?.send(jsonEncode({
        'type': 'TASK_UPDATE',
        'taskId': taskId,
        'status': 'failed',
        'errorMessage': e.toString(),
      }));
    }
  }

  Future<void> _processMangaQueue() async {
    if (_isProcessingManga || _mangaQueue.isEmpty) return;
    _isProcessingManga = true;

    try {
      while (_mangaQueue.isNotEmpty) {
        final task = _mangaQueue.removeAt(0);
        final taskId = task['taskId'] as String;

        if (_cancelledTasks.contains(taskId)) {
          _cancelledTasks.remove(taskId);
          continue;
        }

        _activeMangaTask = task;
        await _executeMangaTask(task);
        _activeMangaTask = null;
      }
    } finally {
      _isProcessingManga = false;
      _updateIdleNotification();
    }
  }

  Future<void> _processHlsQueue() async {
    if (_isProcessingHls || _hlsQueue.isEmpty) return;
    _isProcessingHls = true;

    try {
      while (_hlsQueue.isNotEmpty) {
        final task = _hlsQueue.removeAt(0);
        final taskId = task['taskId'] as String;

        if (_cancelledTasks.contains(taskId)) {
          _cancelledTasks.remove(taskId);
          continue;
        }

        _activeHlsTask = task;
        await _executeHlsTask(task);
        _activeHlsTask = null;
      }
    } finally {
      _isProcessingHls = false;
      _updateIdleNotification();
    }
  }

  Future<void> _executeMangaTask(Map<String, dynamic> task) async {
    final taskId = task['taskId'] as String;
    final pagesRaw = task['pages'] as List<dynamic>;
    final chapterDirPath = task['chapterDirPath'] as String;
    final mediaTitle = task['mediaTitle'] as String;
    final chapterName = task['chapterName'] as String;

    _uiSendPort?.send(jsonEncode({
      'type': 'MANGA_TASK_UPDATE',
      'taskId': taskId,
      'status': 'downloading',
      'progress': 0.0,
    }));

    final pageUrls = pagesRaw.map((pageMap) {
      final idx = pagesRaw.indexWhere((p) => p == pageMap);
      final pMap = pageMap as Map<String, dynamic>;
      final url = pMap['url'] as String;
      final headersRaw = pMap['headers'] as Map<String, dynamic>?;
      final headers = headersRaw?.map((k, v) => MapEntry(k, v.toString()));

      final lower = url.toLowerCase().split('?').first;
      String ext = '.jpg';
      for (final e in ['.jpg', '.jpeg', '.png', '.webp', '.gif']) {
        if (lower.endsWith(e)) {
          ext = e;
          break;
        }
      }

      final fileName = 'page_${(idx + 1).toString().padLeft(3, '0')}$ext';
      return dl.PageUrl(
        url: url,
        headers: headers,
        fileName: p.join(chapterDirPath, fileName),
      );
    }).toList();

    final mDownloader = MediaDownloader(
      taskId: taskId,
      itemType: ItemType.manga,
      pageUrls: pageUrls,
      concurrentDownloads: 3,
    );

    try {
      await mDownloader.download((prog) {
        _mangaProgress = prog.completed / prog.total;
        FlutterForegroundTask.updateService(
          notificationTitle: 'Downloading Manga',
          notificationText:
              '$mediaTitle - $chapterName: ${(_mangaProgress * 100).toStringAsFixed(0)}%',
        );

        _uiSendPort?.send(jsonEncode({
          'type': 'MANGA_TASK_UPDATE',
          'taskId': taskId,
          'status': 'downloading',
          'progress': _mangaProgress,
        }));
      });

      if (_cancelledTasks.contains(taskId)) return;

      final msg = {
        'type': 'MANGA_TASK_UPDATE',
        'taskId': taskId,
        'status': 'completed',
        'progress': 1.0,
        'pageCount': pagesRaw.length,
      };
      _completedResults[taskId] = msg;
      _uiSendPort?.send(jsonEncode(msg));
    } catch (e) {
      if (_cancelledTasks.contains(taskId)) return;
      _uiSendPort?.send(jsonEncode({
        'type': 'MANGA_TASK_UPDATE',
        'taskId': taskId,
        'status': 'failed',
        'errorMessage': e.toString(),
      }));
    }
  }

  void _updateIdleNotification() {
    if (!_isProcessingHls && !_isProcessingManga) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'AnymeX Downloads',
        notificationText: 'Running in background...',
      );
    }
  }

  void _sendStatusUpdate() {
    for (final msg in _completedResults.values) {
      _uiSendPort?.send(jsonEncode(msg));
    }

    if (_activeHlsTask != null) {
      _uiSendPort?.send(jsonEncode({
        'type': 'TASK_UPDATE',
        'taskId': _activeHlsTask!['taskId'],
        'status': 'downloading',
        'progress': _hlsProgress,
      }));
    }
    for (var task in _hlsQueue) {
      _uiSendPort?.send(jsonEncode({
        'type': 'TASK_UPDATE',
        'taskId': task['taskId'],
        'status': 'downloading',
        'progress': 0.0,
      }));
    }

    if (_activeMangaTask != null) {
      _uiSendPort?.send(jsonEncode({
        'type': 'MANGA_TASK_UPDATE',
        'taskId': _activeMangaTask!['taskId'],
        'status': 'downloading',
        'progress': _mangaProgress,
      }));
    }
    for (var task in _mangaQueue) {
      _uiSendPort?.send(jsonEncode({
        'type': 'MANGA_TASK_UPDATE',
        'taskId': task['taskId'],
        'status': 'downloading',
        'progress': 0.0,
      }));
    }
  }
}
