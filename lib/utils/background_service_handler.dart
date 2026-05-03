import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:anymex/utils/download_engine.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

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
    IsolateNameServer.registerPortWithName(_bgReceivePort!.sendPort, 'anymex_bg_port');

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
        DownloadEngine.cancel(taskId);
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
    final preferredQuality = task['preferredQuality'] as String?;
    final parallelSegments = task['parallelSegments'] as int? ?? 3;
    final docsPath = task['docsPath'] as String?;

    final headers = headersraw?.map((k, v) => MapEntry(k, v.toString()));

    _uiSendPort?.send(jsonEncode({
      'type': 'TASK_UPDATE',
      'taskId': taskId,
      'status': 'downloading',
      'progress': 0.0,
    }));

    final result = await DownloadEngine.downloadHls(
      taskId: taskId,
      m3u8Url: m3u8Url,
      fileName: fileName,
      subDirectory: subDirectory,
      docsPath: docsPath,
      preferredQuality: preferredQuality,
      parallelSegments: parallelSegments,
      headers: headers,
      onProgress: (prog) {
        _hlsProgress = prog;
        FlutterForegroundTask.updateService(
          notificationTitle: 'Downloading Anime',
          notificationText: '$fileName: ${(prog * 100).toStringAsFixed(0)}%',
        );

        _uiSendPort?.send(jsonEncode({
          'type': 'TASK_UPDATE',
          'taskId': taskId,
          'status': 'downloading',
          'progress': prog,
        }));
      },
    );

    if (_cancelledTasks.contains(taskId)) {
      return;
    }

    if (result.success) {
      final msg = {
        'type': 'TASK_UPDATE',
        'taskId': taskId,
        'status': 'completed',
        'progress': 1.0,
        'filePath': result.filePath,
      };
      _completedResults[taskId] = msg;
      _uiSendPort?.send(jsonEncode(msg));
    } else {
      _uiSendPort?.send(jsonEncode({
        'type': 'TASK_UPDATE',
        'taskId': taskId,
        'status': 'failed',
        'errorMessage': result.error,
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
    
    final chapterDir = Directory(chapterDirPath);
    await chapterDir.create(recursive: true);

    int downloaded = 0;
    const concurrentPages = 3;
    final List<Future<void>> downloadFutures = [];
    
    _uiSendPort?.send(jsonEncode({
      'type': 'MANGA_TASK_UPDATE',
      'taskId': taskId,
      'status': 'downloading',
      'progress': 0.0,
    }));

    for (int i = 0; i < pagesRaw.length; i++) {
        if (_cancelledTasks.contains(taskId)) break;
        
        while (downloadFutures.length >= concurrentPages) {
            await Future.any(downloadFutures);
        }

        final pIndex = i;
        final pageMap = pagesRaw[pIndex] as Map<String, dynamic>?;
        if (pageMap == null) continue;
        
        final url = pageMap['url'] as String?;
        if (url == null || url.isEmpty) continue;
        
        final headersRaw = pageMap['headers'] as Map<String, dynamic>?;
        final headers = headersRaw?.map((k, v) => MapEntry(k, v.toString()));

        final f = () async {
          try {
            var ext = _imageExtension(url);
            final fileName = 'page_${(pIndex + 1).toString().padLeft(3, '0')}$ext';
            final filePath = p.join(chapterDir.path, fileName);
            final file = File(filePath);
            
            if (await file.exists() && (await file.length()) > 0) {
              return;
            }

            final response = await http.get(Uri.parse(url), headers: headers);
            if (response.statusCode == 200) {
              await file.writeAsBytes(response.bodyBytes);
            }
          } catch (e) {
            debugPrint(e.toString());
          } finally {
            downloaded++;
            final prog = downloaded / pagesRaw.length;
            _mangaProgress = prog;
            
            FlutterForegroundTask.updateService(
              notificationTitle: 'Downloading Manga',
              notificationText: '$mediaTitle - $chapterName: ${(prog * 100).toStringAsFixed(0)}%',
            );

            _uiSendPort?.send(jsonEncode({
              'type': 'MANGA_TASK_UPDATE',
              'taskId': taskId,
              'status': 'downloading',
              'progress': prog,
            }));
          }
        }();

        downloadFutures.add(f);
        f.whenComplete(() => downloadFutures.remove(f));
    }
    await Future.wait(downloadFutures);

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
  }

  String _imageExtension(String url) {
    final lower = url.toLowerCase().split('?').first;
    for (final ext in ['.jpg', '.jpeg', '.png', '.webp', '.gif']) {
      if (lower.endsWith(ext)) return ext;
    }
    return '.jpg';
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
