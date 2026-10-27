import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:collection';
import 'dart:ui';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/track.dart' as hive;
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/media_downloader.dart';
import 'package:anymex/utils/download_isolate_pool.dart' as dl;
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/screens/downloads/nested_screens/active_downloads/active_downloads.dart';
import 'package:anymex/database/isar_models/video.dart' as hive;
import 'package:anymex/models/Media/media.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/background_service_handler.dart';
import 'package:anymex/controllers/services/torrent/torrent_service.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';

class DownloadController extends GetxController {
  final RxList<ActiveDownloadTask> activeTasks = <ActiveDownloadTask>[].obs;
  final RxList<ActiveMangaDownloadTask> activeMangaTasks =
      <ActiveMangaDownloadTask>[].obs;
  final RxList<DownloadedMediaSummary> downloadedMedia =
      <DownloadedMediaSummary>[].obs;
  final RxBool isInitialized = false.obs;

  final RxMap<String, DownloadedMediaMeta> mediaMetaCache =
      <String, DownloadedMediaMeta>{}.obs;
  final RxMap<String, DownloadedMangaMeta> mangaMetaCache =
      <String, DownloadedMangaMeta>{}.obs;

  final RxMap<String, double> taskSpeedBytesPerSec = <String, double>{}.obs;
  final Map<String, DateTime> _lastSpeedTimestamp = {};
  final Map<String, double> _lastSpeedProgress = {};
  final Map<String, int> _lastSpeedBytes = {};

  void _updateSpeed(String taskId, double progress,
      {int? bytes, required bool isManga}) {
    final now = DateTime.now();
    final lastTime = _lastSpeedTimestamp[taskId];
    final lastProg = _lastSpeedProgress[taskId];
    final lastBytes = _lastSpeedBytes[taskId];

    _lastSpeedTimestamp[taskId] = now;
    _lastSpeedProgress[taskId] = progress;
    if (bytes != null) {
      _lastSpeedBytes[taskId] = bytes;
    }

    if (lastTime == null) return;
    final dtMs = now.difference(lastTime).inMilliseconds;
    if (dtMs < 80) return;
    final dtSec = dtMs / 1000.0;

    double instantSpeed = 0.0;
    if (bytes != null && lastBytes != null && bytes >= lastBytes) {
      instantSpeed = (bytes - lastBytes) / dtSec;
    } else if (lastProg != null && progress > lastProg) {
      final estimatedTotal =
          isManga ? (30.0 * 1024 * 1024) : (180.0 * 1024 * 1024);
      instantSpeed = ((progress - lastProg) * estimatedTotal) / dtSec;
    }

    final currentSpeed = taskSpeedBytesPerSec[taskId] ?? 0.0;
    final smoothed = currentSpeed == 0.0
        ? instantSpeed
        : (0.65 * instantSpeed + 0.35 * currentSpeed);
    taskSpeedBytesPerSec[taskId] = smoothed;
  }

  void _clearSpeed(String taskId) {
    taskSpeedBytesPerSec[taskId] = 0.0;
    _lastSpeedTimestamp.remove(taskId);
    _lastSpeedProgress.remove(taskId);
    _lastSpeedBytes.remove(taskId);
  }

  double getTaskSpeed(String taskId) {
    final last = _lastSpeedTimestamp[taskId];
    if (last == null || DateTime.now().difference(last).inSeconds > 3) {
      return 0.0;
    }
    return taskSpeedBytesPerSec[taskId] ?? 0.0;
  }

  static String formatSpeed(double bytesPerSec) {
    if (bytesPerSec <= 0) return '0 KB/s';
    if (bytesPerSec < 1024) {
      return '${bytesPerSec.toStringAsFixed(0)} B/s';
    } else if (bytesPerSec < 1024 * 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    }
  }

  String _cacheKey(String ext, String title) =>
      '${MediaDownloader.sanitizePathSegment(ext).toLowerCase()}_${MediaDownloader.sanitizePathSegment(title).toLowerCase()}';

  Future<DownloadedMediaMeta?> ensureMediaMetaLoaded(
      String ext, String title) async {
    final key = _cacheKey(ext, title);
    if (mediaMetaCache.containsKey(key)) {
      return mediaMetaCache[key];
    }
    final unifiedKey = _cacheKey('AnymeX', title);
    if (mediaMetaCache.containsKey(unifiedKey)) {
      return mediaMetaCache[unifiedKey];
    }
    final sTitle = MediaDownloader.sanitizePathSegment(title).toLowerCase();
    for (final entry in mediaMetaCache.entries) {
      if (entry.key.endsWith('_$sTitle') && entry.value.episodes.isNotEmpty) {
        return entry.value;
      }
    }
    final direct = await getMediaMeta(ext, title);
    if (direct != null && direct.episodes.isNotEmpty) return direct;
    return getMediaMeta('AnymeX', title);
  }

  Future<DownloadedMangaMeta?> ensureMangaMetaLoaded(
      String ext, String title) async {
    final key = _cacheKey(ext, title);
    if (mangaMetaCache.containsKey(key)) {
      return mangaMetaCache[key];
    }
    final unifiedKey = _cacheKey('AnymeX', title);
    if (mangaMetaCache.containsKey(unifiedKey)) {
      return mangaMetaCache[unifiedKey];
    }
    final sTitle = MediaDownloader.sanitizePathSegment(title).toLowerCase();
    for (final entry in mangaMetaCache.entries) {
      if (entry.key.endsWith('_$sTitle') && entry.value.chapters.isNotEmpty) {
        return entry.value;
      }
    }
    final direct = await getMangaMeta(ext, title);
    if (direct != null && direct.chapters.isNotEmpty) return direct;
    return getMangaMeta('AnymeX', title);
  }

  DownloadItemState getEpisodeState(
    String ext,
    String title,
    String epNumber,
    Map<String, String> sortMap,
  ) {
    if (isEpisodeDownloaded(ext, title, epNumber, sortMap)) {
      return const DownloadItemState(status: DownloadItemStatus.downloaded);
    }
    final active = getActiveEpisodeTask(
      ext: ext,
      title: title,
      epNumber: epNumber,
      sortMap: sortMap,
    );
    if (active != null) {
      if (active.status == DownloadStatus.downloading) {
        return DownloadItemState(
          status: DownloadItemStatus.downloading,
          progress: active.progress,
          taskId: active.taskId,
        );
      }
      if (active.status == DownloadStatus.failed) {
        return DownloadItemState(
          status: DownloadItemStatus.failed,
          progress: active.progress,
          taskId: active.taskId,
          errorMessage: active.errorMessage,
        );
      }
      return DownloadItemState(
        status: DownloadItemStatus.queued,
        progress: active.progress,
        taskId: active.taskId,
      );
    }
    return const DownloadItemState(status: DownloadItemStatus.notDownloaded);
  }

  DownloadItemState getChapterState(
    String ext,
    String title,
    double? chapterNum,
  ) {
    if (isChapterDownloaded(ext, title, chapterNum)) {
      return const DownloadItemState(status: DownloadItemStatus.downloaded);
    }
    final active = getActiveMangaTask(
      ext: ext,
      title: title,
      chapterNum: chapterNum,
    );
    if (active != null) {
      if (active.status == MangaDownloadStatus.downloading) {
        return DownloadItemState(
          status: DownloadItemStatus.downloading,
          progress: active.progress,
          taskId: active.taskId,
        );
      }
      if (active.status == MangaDownloadStatus.failed) {
        return DownloadItemState(
          status: DownloadItemStatus.failed,
          progress: active.progress,
          taskId: active.taskId,
          errorMessage: active.errorMessage,
        );
      }
      return DownloadItemState(
        status: DownloadItemStatus.queued,
        progress: active.progress,
        taskId: active.taskId,
      );
    }
    return const DownloadItemState(status: DownloadItemStatus.notDownloaded);
  }

  bool isEpisodeDownloaded(
    String ext,
    String title,
    String epNumber,
    Map<String, String> sortMap,
  ) {
    final eps = getDownloadedEpisodes(ext, title);
    return eps.any(
      (e) => e.number == epNumber && _mapsEqual(e.sortMap, sortMap),
    );
  }

  bool isChapterDownloaded(
    String ext,
    String title,
    double? chapterNum,
  ) {
    final chs = getDownloadedChapters(ext, title);
    return chs.any((c) => c.chapter.number == chapterNum);
  }

  static Source? findMatchingSource(
      List<Source> sources, String extensionName) {
    for (final s in sources) {
      final formatted = (s.lang ?? '').isNotEmpty
          ? '${s.name ?? ''} (${completeLanguageName(s.lang!)})'
          : (s.name ?? '');
      if (MediaDownloader.sanitizePathSegment(formatted).toLowerCase() ==
          extensionName.toLowerCase()) {
        return s;
      }
    }
    for (final s in sources) {
      final codeFormat = (s.lang ?? '').isNotEmpty
          ? '${s.name ?? ''} (${s.lang})'
          : (s.name ?? '');
      if (MediaDownloader.sanitizePathSegment(codeFormat).toLowerCase() ==
          extensionName.toLowerCase()) {
        return s;
      }
    }
    for (final s in sources) {
      if (MediaDownloader.sanitizePathSegment(s.name ?? '').toLowerCase() ==
          extensionName.toLowerCase()) {
        return s;
      }
    }
    return sources.firstWhereOrNull((s) => extensionName
        .toLowerCase()
        .startsWith(
            MediaDownloader.sanitizePathSegment(s.name ?? '').toLowerCase()));
  }

  ActiveDownloadTask? getActiveEpisodeTask({
    required String ext,
    required String title,
    required String epNumber,
    required Map<String, String> sortMap,
  }) {
    final sExt = MediaDownloader.sanitizePathSegment(ext).toLowerCase();
    final sTitle = MediaDownloader.sanitizePathSegment(title).toLowerCase();
    return activeTasks.firstWhereOrNull(
      (t) =>
          t.mediaTitle.toLowerCase() == sTitle &&
          (t.extensionName.toLowerCase() == sExt ||
              t.extensionName.toLowerCase() == 'anymex') &&
          t.episode.number == epNumber &&
          _mapsEqual(t.episode.sortMap, sortMap) &&
          t.status != DownloadStatus.completed &&
          t.status != DownloadStatus.cancelled,
    );
  }

  ActiveMangaDownloadTask? getActiveMangaTask({
    required String ext,
    required String title,
    required double? chapterNum,
  }) {
    final sExt = MediaDownloader.sanitizePathSegment(ext).toLowerCase();
    final sTitle = MediaDownloader.sanitizePathSegment(title).toLowerCase();
    return activeMangaTasks.firstWhereOrNull(
      (t) =>
          t.mediaTitle.toLowerCase() == sTitle &&
          (t.extensionName.toLowerCase() == sExt ||
              t.extensionName.toLowerCase() == 'anymex') &&
          t.chapter.number == chapterNum &&
          t.status != MangaDownloadStatus.completed &&
          t.status != MangaDownloadStatus.cancelled,
    );
  }

  List<DownloadedEpisodeMeta> getDownloadedEpisodes(String ext, String title) {
    final direct = mediaMetaCache[_cacheKey(ext, title)]?.episodes;
    if (direct != null && direct.isNotEmpty) return direct;

    final unified = mediaMetaCache[_cacheKey('AnymeX', title)]?.episodes;
    if (unified != null && unified.isNotEmpty) return unified;

    final sTitle = MediaDownloader.sanitizePathSegment(title).toLowerCase();
    for (final entry in mediaMetaCache.entries) {
      if (entry.key.endsWith('_$sTitle') && entry.value.episodes.isNotEmpty) {
        return entry.value.episodes;
      }
    }
    return [];
  }

  List<DownloadedChapterMeta> getDownloadedChapters(String ext, String title) {
    final direct = mangaMetaCache[_cacheKey(ext, title)]?.chapters;
    if (direct != null && direct.isNotEmpty) return direct;

    final unified = mangaMetaCache[_cacheKey('AnymeX', title)]?.chapters;
    if (unified != null && unified.isNotEmpty) return unified;

    final sTitle = MediaDownloader.sanitizePathSegment(title).toLowerCase();
    for (final entry in mangaMetaCache.entries) {
      if (entry.key.endsWith('_$sTitle') && entry.value.chapters.isNotEmpty) {
        return entry.value.chapters;
      }
    }
    return [];
  }

  static OfflineMedia createOfflineMediaFromTracker(Media media) {
    return media.toOfflineMedia();
  }

  final Queue<_ScrapeRequest> _scrapeQueue = Queue();
  final Queue<_MangaScrapeRequest> _mangaScrapeQueue = Queue();
  final Map<String, String> _scrapeTokens = {};
  int _activeTaskCount = 0;
  bool _isFetching = false;
  final List<String> _activeFileTasks = [];
  SendPort? _bgSendPort;

  final Map<String, DateTime> _lastProgressUpdate = {};
  static const _progressThrottleMs = 250;
  bool _receivePortListening = false;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    final concurrency = DownloadKeys.concurrentDownloads.get<int>(3);
    await MediaDownloader.initializeIsolatePool(poolSize: concurrency);

    await _loadIndex();
    await _loadActiveTasks();
    await _loadMangaActiveTasks();

    ever(Get.find<Settings>().concurrentDownloads, (val) {
      _processScrapeQueue();
      _processMangaScrapeQueue();
    });

    ever(Get.find<Settings>().downloadPath, (val) async {
      await _loadIndex();
      activeTasks.clear();
      await _loadActiveTasks();
      activeMangaTasks.clear();
      await _loadMangaActiveTasks();
    });

    final sourceController = Get.find<SourceController>();

    _initForegroundTask();

    Future.delayed(const Duration(seconds: 3), () async {
      bool isRunning = false;
      if (Platform.isAndroid || Platform.isIOS) {
        isRunning = await FlutterForegroundTask.isRunningService;
      }

      if (!isRunning) {
        for (final task in activeTasks) {
          if (task.status == DownloadStatus.downloading ||
              task.status == DownloadStatus.queued) {
            _runEpisodeDownload(task: task);
          }
        }
        for (final task in activeMangaTasks) {
          if (task.status == MangaDownloadStatus.downloading ||
              task.status == MangaDownloadStatus.queued) {
            final source = findMatchingSource(
                sourceController.installedMangaExtensions, task.extensionName);
            if (source != null) {
              _runChapterDownload(task: task, source: source);
            }
          }
        }
      }
    });

    isInitialized.value = true;
  }

  void _initForegroundTask() {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'anymex_downloads',
        channelName: 'AnymeX Downloads',
        channelDescription: 'Persistent background downloading service.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 1000,
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    _bgSendPort = IsolateNameServer.lookupPortByName('anymex_bg_port');
    if (_bgSendPort != null) {
      _sendToBackground({'type': 'GET_STATUS'});
      _sendToBackground({'type': 'UI_READY'});
    }
    _attachReceivePortListener();
  }

  void _attachReceivePortListener() {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (_receivePortListening) return;
    final port = FlutterForegroundTask.receivePort;
    if (port == null) return;
    port.listen(_onForegroundReceiveData);
    _receivePortListening = true;
  }

  Future<void> _startBackgroundServiceIfNotRunning() async {
    if (!Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.startService(
        notificationTitle: 'AnymeX Downloads',
        notificationText: 'Starting background service...',
        callback: startBackgroundService,
      );
    }
    _attachReceivePortListener();
  }

  void _onForegroundReceiveData(dynamic data) {
    if (data is SendPort) {
      _bgSendPort = data;
      _processPendingPayloads();
      return;
    }
    if (data is String) {
      try {
        final payload = jsonDecode(data) as Map<String, dynamic>;
        final type = payload['type'];
        final taskId = payload['taskId'];
        if (type == 'TASK_UPDATE') {
          final task = activeTasks.firstWhereOrNull((t) => t.taskId == taskId);
          if (task != null) {
            final statusStr = payload['status'] as String;
            final prog = (payload['progress'] as num).toDouble();
            final isTerminal =
                statusStr == 'completed' || statusStr == 'failed';

            if (statusStr == 'downloading') {
              task.status = DownloadStatus.downloading;
              _updateSpeed(taskId, prog,
                  bytes: payload['bytes'] as int?, isManga: false);
            } else if (statusStr == 'completed') {
              task.status = DownloadStatus.completed;
              task.filePath = payload['filePath'] as String?;
              _clearSpeed(taskId);
            } else if (statusStr == 'failed') {
              task.status = DownloadStatus.failed;
              task.errorMessage = payload['errorMessage'] as String?;
              _clearSpeed(taskId);
            }
            task.progress = prog;

            if (isTerminal) {
              _clearSpeed(taskId);
              _lastProgressUpdate.remove(taskId);
              activeTasks.refresh();
              _saveActiveTasks();
              if (statusStr == 'completed') {
                _activeFileTasks.remove(taskId);
                _activeTaskCount--;
                _onForegroundTaskFinished(task);
                _processScrapeQueue();
                _processMangaScrapeQueue();
              }
            } else {
              final now = DateTime.now();
              final last = _lastProgressUpdate[taskId];
              if (last == null ||
                  now.difference(last).inMilliseconds > _progressThrottleMs) {
                _lastProgressUpdate[taskId] = now;
                activeTasks.refresh();
              }
            }
          }
        } else if (type == 'MANGA_TASK_UPDATE') {
          final task =
              activeMangaTasks.firstWhereOrNull((t) => t.taskId == taskId);
          if (task != null) {
            final statusStr = payload['status'] as String;
            final prog = (payload['progress'] as num).toDouble();
            final isTerminal =
                statusStr == 'completed' || statusStr == 'failed';

            if (statusStr == 'downloading') {
              task.status = MangaDownloadStatus.downloading;
              _updateSpeed(taskId, prog,
                  bytes: payload['bytes'] as int?, isManga: true);
            } else if (statusStr == 'completed') {
              task.status = MangaDownloadStatus.completed;
              _clearSpeed(taskId);
            } else if (statusStr == 'failed') {
              task.status = MangaDownloadStatus.failed;
              _clearSpeed(taskId);
            }
            task.progress = prog;

            if (isTerminal) {
              _clearSpeed(taskId);
              _lastProgressUpdate.remove(taskId);
              activeMangaTasks.refresh();
              _saveMangaActiveTasks();
              if (statusStr == 'completed') {
                _onForegroundMangaTaskFinished(
                    task, payload['pageCount'] as int);
              }
            } else {
              final now = DateTime.now();
              final last = _lastProgressUpdate[taskId];
              if (last == null ||
                  now.difference(last).inMilliseconds > _progressThrottleMs) {
                _lastProgressUpdate[taskId] = now;
                activeMangaTasks.refresh();
              }
            }
          }
        } else if (type == 'NOTIFICATION_TAPPED') {
          _handleNotificationTap();
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  void _handleNotificationTap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute != '/ActiveDownloads') {
        navigate(() => const ActiveDownloads());
      }
    });
  }

  Future<void> _onForegroundTaskFinished(ActiveDownloadTask task) async {
    final fileName = MediaDownloader.buildFileName(
      episodeNumber: task.episode.number,
      sortMap: task.episode.sortMap,
      url: task.videoUrl,
    );
    await _writeEpisodeMeta(task, fileName);
    await _loadIndex();
  }

  Future<void> _onForegroundMangaTaskFinished(
      ActiveMangaDownloadTask task, int pageCount) async {
    final mediaDir =
        await _getMangaMediaDirPath(task.mediaTitle, task.extensionName);
    final chapterDir = Directory(p.join(
        mediaDir, MediaDownloader.sanitizePathSegment(task.chapterDisplay)));
    await _writeChapterMeta(task, chapterDir.path, pageCount);
    await _loadIndex();
  }

  final List<String> _pendingPayloads = [];
  void _processPendingPayloads() {
    for (var p in _pendingPayloads) {
      _bgSendPort?.send(p);
    }
    _pendingPayloads.clear();
  }

  void _sendToBackground(Map<String, dynamic> payload) {
    if (Platform.isIOS) return;
    final str = jsonEncode(payload);
    if (_bgSendPort == null) {
      _pendingPayloads.add(str);
      _startBackgroundServiceIfNotRunning();
    } else {
      _bgSendPort?.send(str);
    }
  }

  Future<void> _onTaskFinished(ActiveDownloadTask task, String fileName) async {
    await _writeEpisodeMeta(task, fileName);
    await _loadIndex();
    _saveActiveTasks();
  }

  Future<void> _saveActiveTasks() async {
    try {
      final root = await _getRootDir();
      final file = File(p.join(root.path, 'active_tasks.json'));
      final json = activeTasks
          .where((t) =>
              t.status != DownloadStatus.completed &&
              t.status != DownloadStatus.failed)
          .map((t) => t.toJson())
          .toList();
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      debugPrint('Error saving active tasks: $e');
    }
  }

  Future<void> _saveMangaActiveTasks() async {
    try {
      final root = await _getRootDir();
      final file = File(p.join(root.path, 'active_manga_tasks.json'));
      final json = activeMangaTasks
          .where((t) =>
              t.status != MangaDownloadStatus.completed &&
              t.status != MangaDownloadStatus.failed)
          .map((t) => t.toJson())
          .toList();
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      debugPrint('Error saving manga active tasks: $e');
    }
  }

  Future<void> _loadActiveTasks() async {
    try {
      final root = await _getRootDir();
      final file = File(p.join(root.path, 'active_tasks.json'));
      if (!await file.exists()) return;

      final raw = jsonDecode(await file.readAsString()) as List;
      final tasks = raw.map((e) => ActiveDownloadTask.fromJson(e)).toList();
      for (final t in tasks) {
        if (t.media?.mediaId != null && t.media!.mediaId!.isNotEmpty) {
          t.extensionName = 'AnymeX';
        }
      }
      activeTasks.addAll(tasks);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadMangaActiveTasks() async {
    try {
      final root = await _getRootDir();
      final file = File(p.join(root.path, 'active_manga_tasks.json'));
      if (!await file.exists()) return;

      final raw = jsonDecode(await file.readAsString()) as List;
      final tasks =
          raw.map((e) => ActiveMangaDownloadTask.fromJson(e)).toList();
      for (final t in tasks) {
        if (t.media?.mediaId != null && t.media!.mediaId!.isNotEmpty) {
          t.extensionName = 'AnymeX';
        }
      }
      activeMangaTasks.addAll(tasks);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<List<hive.Video>> fetchServersForEpisode(Source source, Episode ep,
      {String? passedToken,
      String? preferredQuality,
      Duration timeout = const Duration(seconds: 20)}) async {
    final deEpisode = DEpisode(
      episodeNumber: ep.number,
      url: ep.link,
      sortMap: ep.sortMap.isEmpty ? null : ep.sortMap,
    );

    final token = passedToken ??
        'dl_scrape_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final methods = source.methods;

    final videoStream = methods.getVideoListStream(
      deEpisode,
      parameters: SourceParams(cancelToken: token),
    );

    if (videoStream != null) {
      final videos = <hive.Video>[];
      try {
        await videoStream.timeout(timeout).forEach((v) {
          final next = hive.Video.fromVideo(v);
          final alreadyExists = videos.any(
            (existing) =>
                existing.quality == next.quality &&
                existing.originalUrl == next.originalUrl,
          );
          if (!alreadyExists) {
            videos.add(next);
            if (preferredQuality != null && next.quality == preferredQuality) {
              throw _EarlyExitException();
            }
          }
        });
      } on _EarlyExitException {
        //
      } on TimeoutException {
        debugPrint('[DownloadController] fetchServersForEpisode timed out');
      }
      return videos;
    } else {
      final videoList = await methods
          .getVideoList(
            deEpisode,
            parameters: SourceParams(cancelToken: token),
          )
          .timeout(timeout, onTimeout: () => []);
      return videoList.map((v) => hive.Video.fromVideo(v)).toList();
    }
  }

  Future<void> enqueueDownloadBatch({
    required List<Episode> episodes,
    required Source source,
    required OfflineMedia media,
    required String preferredQuality,
    String? firstEpisodeVideoUrl,
    Map<String, String>? firstEpisodeHeaders,
    List<hive.Track>? firstEpisodeSubtitles,
    bool isFromMetadataPage = true,
  }) async {
    final mediaTitle = media.name ?? 'Unknown';
    final sanitizedTitle = MediaDownloader.sanitizePathSegment(mediaTitle);
    final isFromMetadata = isFromMetadataPage ||
        (media.mediaId != null && media.mediaId!.isNotEmpty);
    final extName = isFromMetadata
        ? 'AnymeX'
        : ((source.lang ?? '').isNotEmpty
            ? '${source.name ?? 'unknown'} (${completeLanguageName(source.lang!)})'
            : (source.name ?? 'unknown'));
    final sanitizedExt = MediaDownloader.sanitizePathSegment(extName);

    await setMediaMeta(sanitizedExt, sanitizedTitle, media, mediaType: 'Anime');

    for (int i = 0; i < episodes.length; i++) {
      final ep = episodes[i];
      _enqueueEpisode(
        episode: ep,
        source: source,
        sanitizedTitle: sanitizedTitle,
        sanitizedExt: sanitizedExt,
        preferredQuality: preferredQuality,
        videoUrl: i == 0 ? firstEpisodeVideoUrl : null,
        videoHeaders: i == 0 ? firstEpisodeHeaders : null,
        videoSubtitles: i == 0 ? firstEpisodeSubtitles : null,
        media: media,
      );
    }
  }

  void _enqueueEpisode({
    required Episode episode,
    required Source source,
    required String sanitizedTitle,
    required String sanitizedExt,
    required String preferredQuality,
    String? videoUrl,
    Map<String, String>? videoHeaders,
    List<hive.Track>? videoSubtitles,
    required OfflineMedia media,
  }) {
    activeTasks.removeWhere((t) =>
        t.mediaTitle.toLowerCase() == sanitizedTitle.toLowerCase() &&
        t.extensionName.toLowerCase() == sanitizedExt.toLowerCase() &&
        t.episode.number == episode.number &&
        _mapsEqual(t.episode.sortMap, episode.sortMap) &&
        t.status == DownloadStatus.failed);

    final taskId = MediaDownloader.buildTaskId(
      extensionName: sanitizedExt,
      mediaTitle: sanitizedTitle,
      episodeNumber: episode.number,
      sortMap: episode.sortMap,
    );

    final placeholder = ActiveDownloadTask(
      taskId: taskId,
      mediaTitle: sanitizedTitle,
      extensionName: sanitizedExt,
      episode: episode,
      videoUrl: videoUrl ?? '',
      videoQuality: preferredQuality,
      linkType: VideoLinkType.unknown,
      status: DownloadStatus.queued,
      videoHeaders: videoHeaders,
      subtitles: videoSubtitles,
      media: media,
    );

    activeTasks.add(placeholder);
    _saveActiveTasks();

    _scrapeQueue.add(_ScrapeRequest(
      task: placeholder,
      source: source,
      preferredQuality: preferredQuality,
    ));
    _processScrapeQueue();
  }

  void _processScrapeQueue() {
    if (_scrapeQueue.isEmpty) return;

    final maxConcurrent = Get.find<Settings>().concurrentDownloads.value;

    while (_scrapeQueue.isNotEmpty && _activeTaskCount < maxConcurrent) {
      final request = _scrapeQueue.first;
      if (request.task.status == DownloadStatus.cancelled) {
        _scrapeQueue.removeFirst();
        continue;
      }
      final needsFetch = request.task.videoUrl.isEmpty;
      if (needsFetch && _isFetching) break;

      _scrapeQueue.removeFirst();
      _activeTaskCount++;
      _runEpisodeDownload(
        task: request.task,
        source: request.source,
        preferredQuality: request.preferredQuality,
      ).whenComplete(() {
        if (_activeTaskCount < 0) _activeTaskCount = 0;
        _processScrapeQueue();
      });
    }
  }

  Future<void> _runEpisodeDownload({
    required ActiveDownloadTask task,
    Source? source,
    String? preferredQuality,
  }) async {
    if (task.status == DownloadStatus.paused) return;
    if (task.status == DownloadStatus.awaitingServerSelection) return;

    String? torrentHash;
    try {
      hive.Video? chosenVideo;
      if (task.videoUrl.isEmpty) {
        if (source == null) {
          task.status = DownloadStatus.failed;
          task.errorMessage = 'Source not found for resuming scrape';
          activeTasks.refresh();
          _activeTaskCount--;
          return;
        }

        _isFetching = true;
        task.status = DownloadStatus.fetchingServer;
        activeTasks.refresh();
        _saveActiveTasks();
        _updateNotification();

        final token =
            'dl_scrape_${task.taskId}_${DateTime.now().millisecondsSinceEpoch}';
        _scrapeTokens[task.taskId] = token;

        late List<hive.Video> videos;
        try {
          videos = await fetchServersForEpisode(
            source,
            task.episode,
            passedToken: token,
            preferredQuality: preferredQuality,
            timeout: const Duration(seconds: 20),
          );
        } finally {
          _isFetching = false;
          _scrapeTokens.remove(task.taskId);
          _processScrapeQueue();
        }

        if (videos.isEmpty) {
          task.status = DownloadStatus.awaitingServerSelection;
          task.errorMessage = 'No servers found. Please select manually.';
          task.availableServers = [];
          activeTasks.refresh();
          _saveActiveTasks();
          _activeTaskCount--;
          _processScrapeQueue();
          return;
        }

        task.availableServers = videos;

        final qualityLabels = videos.map((v) => v.quality ?? '').toList();
        final bestLabel = MediaDownloader.pickBestMatchingVideo(
            qualityLabels, preferredQuality ?? '720p');

        if (bestLabel.isEmpty) {
          task.status = DownloadStatus.awaitingServerSelection;
          task.errorMessage =
              'No server matched "${preferredQuality ?? '720p'}". Please select manually.';
          activeTasks.refresh();
          _saveActiveTasks();
          _activeTaskCount--;
          _processScrapeQueue();
          return;
        }

        chosenVideo = videos.firstWhereOrNull((v) => v.quality == bestLabel) ??
            videos.first;
        task.videoUrl = chosenVideo.url ?? chosenVideo.originalUrl ?? '';
        task.videoHeaders ??= {};
        task.videoHeaders!.addAll(chosenVideo.headers ?? {});
        task.subtitles ??= chosenVideo.subtitles;
      }

      if (task.videoUrl.isEmpty) {
        task.status = DownloadStatus.failed;
        task.errorMessage = 'Empty video URL';
        activeTasks.refresh();
        _activeTaskCount--;
        return;
      }

      if (isTorrentUrl(task.videoUrl)) {
        final torrAddon = await TorrentService.instance.acquireDownload();
        final info = await torrAddon.addForDownload(
          url: task.videoUrl,
          title: task.mediaTitle,
        );
        torrentHash = info.hash;
        final file = TorrentService.pickStreamableFile(
          info,
          episode: task.episode.number,
        );
        if (file == null) {
          throw Exception('No streamable video file found in torrent');
        }
        task.videoUrl = torrAddon.fileUrl(info.hash, file.id).toString();
      }

      final linkType = detectLinkType(task.videoUrl);

      task.status = DownloadStatus.downloading;
      activeTasks.refresh();
      _saveActiveTasks();
      _updateNotification();

      final isHls = linkType == VideoLinkType.hls;
      final fileName = MediaDownloader.buildFileName(
        episodeNumber: task.episode.number,
        sortMap: task.episode.sortMap,
        url: task.videoUrl,
        isHls: isHls,
      );

      final rootDir = await _getRootDir();
      final subDir = p.join('Anime', task.extensionName, task.mediaTitle);
      final fullDirPath = p.join(rootDir.path, subDir);

      final mDownloader = MediaDownloader(
        taskId: task.taskId,
        itemType: ItemType.anime,
        pageUrls: isHls
            ? null
            : [
                dl.PageUrl(
                  url: task.videoUrl,
                  headers: chosenVideo?.headers ?? task.videoHeaders,
                  fileName: p.join(fullDirPath, fileName),
                )
              ],
        subtitles: task.subtitles,
        subDownloadDir: fullDirPath,
        m3u8Url: isHls ? task.videoUrl : null,
        videoFileName: fileName,
        headers: chosenVideo?.headers ?? task.videoHeaders,
        concurrentDownloads: Get.find<Settings>().hlsParallelSegments.value,
        episodeNumber: task.episode.number,
      );

      final subFolder =
          p.join(fullDirPath, 'Episode_${task.episode.number}_subs');
      final localSubs = task.subtitles?.map((s) {
        final ext = MediaDownloader.getSubtitleExtension(s.file ?? '');
        final safeName = MediaDownloader.sanitizePathSegment('${s.label}$ext');
        return hive.Track(
          file: p.join(subFolder, safeName),
          label: s.label,
        );
      }).toList();
      task.subtitles = localSubs;

      _activeFileTasks.add(task.taskId);

      await mDownloader.download((progress) {
        task.progress = progress.completed / progress.total;
        task.status = DownloadStatus.downloading;
        _updateSpeed(task.taskId, task.progress,
            bytes: progress.bytes, isManga: false);
        final now = DateTime.now();
        final last = _lastProgressUpdate[task.taskId];
        if (last == null ||
            now.difference(last).inMilliseconds > _progressThrottleMs) {
          _lastProgressUpdate[task.taskId] = now;
          activeTasks.refresh();
          _updateNotification();
        }
      });

      _clearSpeed(task.taskId);
      _lastProgressUpdate.remove(task.taskId);
      task.status = DownloadStatus.completed;
      task.filePath = p.join(fullDirPath, fileName);
      task.progress = 1.0;
      await _onTaskFinished(task, fileName);

      _activeFileTasks.remove(task.taskId);
      _activeTaskCount--;
      _processScrapeQueue();
      _updateNotification();
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = e.toString();
      _activeFileTasks.remove(task.taskId);
      _activeTaskCount--;
      _processScrapeQueue();
    } finally {
      if (torrentHash != null) {
        await TorrentService.instance.releaseDownload(torrentHash);
      }
      activeTasks.refresh();
      _saveActiveTasks();
    }
  }

  void _updateNotification() {
    final downloading = activeTasks
        .where((t) => t.status == DownloadStatus.downloading)
        .toList();
    final queued = activeTasks
        .where((t) =>
            t.status == DownloadStatus.queued ||
            t.status == DownloadStatus.fetchingServer ||
            t.status == DownloadStatus.awaitingServerSelection)
        .length;
    if (downloading.isEmpty && queued == 0) {
      _sendToBackground({
        'type': 'UPDATE_NOTIFICATION',
        'title': 'AnymeX Downloads',
        'text': 'All downloads complete.'
      });
      return;
    }
    final active = downloading.isNotEmpty ? downloading.first : null;
    final title = active != null
        ? '${active.mediaTitle} · Ep ${active.episode.number}'
        : 'AnymeX Downloads';
    final pct =
        active != null ? '${(active.progress * 100).toStringAsFixed(0)}%' : '';
    final text = [
      if (pct.isNotEmpty) pct,
      if (queued > 0) '$queued queued',
    ].join(' · ');
    _sendToBackground({
      'type': 'UPDATE_NOTIFICATION',
      'title': title,
      'text': text.isNotEmpty ? text : 'Downloading…'
    });
  }

  Future<void> enqueueMangaDownloadBatch({
    required List<Chapter> chapters,
    required Source source,
    required OfflineMedia media,
    bool isFromMetadataPage = true,
  }) async {
    final mediaTitle = media.name ?? 'Unknown';
    final sanitizedTitle = MediaDownloader.sanitizePathSegment(mediaTitle);
    final isFromMetadata = isFromMetadataPage ||
        (media.mediaId != null && media.mediaId!.isNotEmpty);
    final extName = isFromMetadata
        ? 'AnymeX'
        : ((source.lang ?? '').isNotEmpty
            ? '${source.name ?? 'unknown'} (${completeLanguageName(source.lang!)})'
            : (source.name ?? 'unknown'));
    final sanitizedExt = MediaDownloader.sanitizePathSegment(extName);

    await setMediaMeta(sanitizedExt, sanitizedTitle, media, mediaType: 'Manga');

    for (final chapter in chapters) {
      _enqueueMangaChapter(
        chapter: chapter,
        source: source,
        sanitizedTitle: sanitizedTitle,
        sanitizedExt: sanitizedExt,
        media: media,
      );
    }
  }

  void _enqueueMangaChapter({
    required Chapter chapter,
    required Source source,
    required String sanitizedTitle,
    required String sanitizedExt,
    required OfflineMedia media,
  }) {
    activeMangaTasks.removeWhere((t) =>
        t.mediaTitle.toLowerCase() == sanitizedTitle.toLowerCase() &&
        t.extensionName.toLowerCase() == sanitizedExt.toLowerCase() &&
        t.chapter.number == chapter.number &&
        t.status == MangaDownloadStatus.failed);

    final chapterNum = chapter.number?.toString() ?? '0';
    final taskId =
        'manga_${sanitizedExt}_${sanitizedTitle}_ch${chapterNum}_${DateTime.now().millisecondsSinceEpoch % 100000}_${Random().nextInt(9999)}';

    final task = ActiveMangaDownloadTask(
      taskId: taskId,
      mediaTitle: sanitizedTitle,
      extensionName: sanitizedExt,
      chapter: chapter,
      status: MangaDownloadStatus.queued,
      media: media,
    );

    activeMangaTasks.add(task);
    _saveMangaActiveTasks();

    _mangaScrapeQueue.add(_MangaScrapeRequest(task: task, source: source));
    _processMangaScrapeQueue();
  }

  void _processMangaScrapeQueue() {
    if (_mangaScrapeQueue.isEmpty) return;

    while (_mangaScrapeQueue.isNotEmpty) {
      final request = _mangaScrapeQueue.removeFirst();
      if (request.task.status == MangaDownloadStatus.cancelled) continue;
      _runChapterDownload(task: request.task, source: request.source);
    }
  }

  Future<void> _runChapterDownload({
    required ActiveMangaDownloadTask task,
    required Source source,
  }) async {
    try {
      task.status = MangaDownloadStatus.fetchingPages;
      activeMangaTasks.refresh();

      final chapterUrl = task.chapter.link;
      if (chapterUrl == null || chapterUrl.isEmpty) {
        task.status = MangaDownloadStatus.failed;
        task.errorMessage = 'Chapter has no URL';
        snackBar('Download failed: ${task.chapterDisplay} has no URL');
        activeMangaTasks.refresh();
        return;
      }

      final pages = await source.methods.getPageList(
        DEpisode(episodeNumber: '1', url: chapterUrl),
      );

      if (pages.isEmpty) {
        task.status = MangaDownloadStatus.failed;
        task.errorMessage = 'No pages found for this chapter';
        snackBar('Download failed: No pages found for ${task.chapterDisplay}');
        activeMangaTasks.refresh();
        return;
      }

      task.status = MangaDownloadStatus.downloading;
      activeMangaTasks.refresh();

      final mediaDir =
          await _getMangaMediaDirPath(task.mediaTitle, task.extensionName);
      final chapterDir = Directory(p.join(
        mediaDir,
        MediaDownloader.sanitizePathSegment(task.chapterDisplay),
      ));

      await chapterDir.create(recursive: true);

      final pageUrls = pages.map((page) {
        final ext = _imageExtension(page.url);
        final idx = pages.indexOf(page);
        final fileName = 'page_${(idx + 1).toString().padLeft(3, '0')}$ext';
        final Map<String, String> rawHeaders =
            page.headers?.map((k, v) => MapEntry(k, v.toString())) ?? {};
        final headers = getPageImageHeaders(rawHeaders, source.baseUrl);
        return dl.PageUrl(
          url: page.url,
          headers: headers,
          fileName: p.join(chapterDir.path, fileName),
        );
      }).toList();

      final mDownloader = MediaDownloader(
        taskId: task.taskId,
        itemType: ItemType.manga,
        pageUrls: pageUrls,
        concurrentDownloads: 3,
      );

      await mDownloader.download((progress) {
        task.progress = progress.completed / progress.total;
        _updateSpeed(task.taskId, task.progress,
            bytes: progress.bytes, isManga: true);
        final now = DateTime.now();
        final last = _lastProgressUpdate[task.taskId];
        if (last == null ||
            now.difference(last).inMilliseconds > _progressThrottleMs) {
          _lastProgressUpdate[task.taskId] = now;
          activeMangaTasks.refresh();
        }
      });

      _clearSpeed(task.taskId);
      _lastProgressUpdate.remove(task.taskId);
      task.status = MangaDownloadStatus.completed;
      task.progress = 1.0;
      await _onForegroundMangaTaskFinished(task, pages.length);
    } catch (e) {
      task.status = MangaDownloadStatus.failed;
      task.errorMessage = e.toString();
      snackBar('Download failed: ${task.chapterDisplay}');
    } finally {
      activeMangaTasks.refresh();
      _saveMangaActiveTasks();
    }
  }

  String _imageExtension(String url) {
    final lower = url.toLowerCase().split('?').first;
    for (final ext in ['.jpg', '.jpeg', '.png', '.webp', '.gif']) {
      if (lower.endsWith(ext)) return ext;
    }
    return '.jpg';
  }

  Future<void> _writeChapterMeta(
      ActiveMangaDownloadTask task, String imageDir, int pageCount) async {
    final mediaDir =
        await _getMangaMediaDirPath(task.mediaTitle, task.extensionName);
    final metaFile = File(p.join(mediaDir, 'metadata.json'));

    DownloadedMangaMeta meta;
    if (await metaFile.exists()) {
      try {
        final raw =
            jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
        meta = DownloadedMangaMeta.fromJson(raw);
      } catch (_) {
        meta = const DownloadedMangaMeta(chapters: []);
      }
    } else {
      meta = const DownloadedMangaMeta(chapters: []);
    }

    final chapterNum = task.chapter.number;
    final alreadyExists = meta.chapters.any(
      (c) => c.chapter.number == chapterNum,
    );

    if (!alreadyExists) {
      final updatedChapters = [
        ...meta.chapters,
        DownloadedChapterMeta(
          chapter: task.chapter
            ..localPath = imageDir
            ..link =
                (task.chapter.link != null && task.chapter.link!.isNotEmpty)
                    ? task.chapter.link
                    : imageDir,
          imageDir: imageDir,
          pageCount: pageCount,
          downloadedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];
      updatedChapters.sort(
          (a, b) => (a.chapter.number ?? 0).compareTo(b.chapter.number ?? 0));
      meta = DownloadedMangaMeta(
        chapters: updatedChapters,
        media: meta.media ?? task.media,
      );
    }

    await metaFile.writeAsString(jsonEncode(meta.toJson()), flush: true);
    mangaMetaCache[_cacheKey(task.extensionName, task.mediaTitle)] = meta;
    await _loadIndex();
  }

  Future<void> cancelMangaDownload(String taskId) async {
    _clearSpeed(taskId);
    dl.DownloadIsolatePool.instance.cancelTask(taskId);
    final task = activeMangaTasks.firstWhereOrNull((t) => t.taskId == taskId);
    if (task != null) {
      task.status = MangaDownloadStatus.cancelled;
      activeMangaTasks.refresh();
      _saveMangaActiveTasks();

      bool isRunning = false;
      if (Platform.isAndroid || Platform.isIOS) {
        isRunning = await FlutterForegroundTask.isRunningService;
      }

      if (isRunning) {
        _sendToBackground({
          'type': 'CANCEL_TASK',
          'taskId': taskId,
        });
      }
    }
  }

  Future<void> removeMangaTask(String taskId) async {
    _clearSpeed(taskId);
    dl.DownloadIsolatePool.instance.cancelTask(taskId);
    activeMangaTasks.removeWhere((t) => t.taskId == taskId);
    _saveMangaActiveTasks();
  }

  Future<DownloadedMangaMeta?> getMangaMeta(String ext, String title) async {
    final root = await _getRootDir();
    var mediaDir = p.join(root.path, 'Manga', ext, title);
    var targetExt = ext;
    if (!await Directory(mediaDir).exists()) {
      final unifiedDir = p.join(root.path, 'Manga', 'AnymeX', title);
      if (await Directory(unifiedDir).exists()) {
        mediaDir = unifiedDir;
        targetExt = 'AnymeX';
      }
    }
    await _syncMediaFolderMeta(
      mediaDir: mediaDir,
      ext: targetExt,
      title: title,
      mediaType: 'Manga',
    );
    final metaFile = File(p.join(mediaDir, 'metadata.json'));
    if (!await metaFile.exists()) return null;
    final raw =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    final result = DownloadedMangaMeta.fromJson(raw);
    mangaMetaCache[_cacheKey(targetExt, title)] = result;
    return result;
  }

  Future<void> pauseDownload(String taskId) async {
    _clearSpeed(taskId);
    final task = activeTasks.firstWhereOrNull((t) => t.taskId == taskId);
    final mangaTask =
        activeMangaTasks.firstWhereOrNull((t) => t.taskId == taskId);

    if (task != null) {
      dl.DownloadIsolatePool.instance.cancelTask(taskId);
      task.status = DownloadStatus.paused;
      activeTasks.refresh();
    } else if (mangaTask != null) {
      dl.DownloadIsolatePool.instance.cancelTask(taskId);
      mangaTask.status = MangaDownloadStatus.paused;
      activeMangaTasks.refresh();
    }

    _saveActiveTasks();
    _saveMangaActiveTasks();
  }

  Future<void> resumeDownload(String taskId) async {
    final task = activeTasks.firstWhereOrNull((t) => t.taskId == taskId);
    final mangaTask =
        activeMangaTasks.firstWhereOrNull((t) => t.taskId == taskId);

    if (task != null) {
      task.status = DownloadStatus.queued;
      activeTasks.refresh();
      _runEpisodeDownload(task: task);
    } else if (mangaTask != null) {
      mangaTask.status = MangaDownloadStatus.queued;
      activeMangaTasks.refresh();
      final source = findMatchingSource(
          Get.find<SourceController>().installedMangaExtensions,
          mangaTask.extensionName);
      if (source != null) {
        _runChapterDownload(task: mangaTask, source: source);
      }
    }

    _saveActiveTasks();
    _saveMangaActiveTasks();
  }

  Future<void> cancelDownload(String taskId) async {
    _clearSpeed(taskId);
    dl.DownloadIsolatePool.instance.cancelTask(taskId);

    bool isRunning = false;
    if (Platform.isAndroid || Platform.isIOS) {
      isRunning = await FlutterForegroundTask.isRunningService;
    }

    if (isRunning) {
      _sendToBackground({
        'type': 'CANCEL_TASK',
        'taskId': taskId,
      });
    }

    final token = _scrapeTokens[taskId];
    if (token != null) {
      final taskInActive =
          activeTasks.firstWhereOrNull((t) => t.taskId == taskId);
      if (taskInActive != null) {
        final source = findMatchingSource(
                Get.find<SourceController>().installedExtensions,
                taskInActive.extensionName) ??
            findMatchingSource(
                Get.find<SourceController>().installedMangaExtensions,
                taskInActive.extensionName);
        source?.cancelRequest(token);
      }
      _scrapeTokens.remove(taskId);
    }

    final task = activeTasks.firstWhereOrNull((t) => t.taskId == taskId);
    if (task != null) {
      task.status = DownloadStatus.cancelled;
      activeTasks.refresh();
    }
  }

  Future<void> cancelAndRemoveTasks(List<String> taskIds,
      {required bool isManga}) async {
    for (final id in taskIds) {
      _clearSpeed(id);
      dl.DownloadIsolatePool.instance.cancelTask(id);
    }

    bool isRunning = false;
    if (Platform.isAndroid || Platform.isIOS) {
      isRunning = await FlutterForegroundTask.isRunningService;
    }

    if (isRunning) {
      for (final id in taskIds) {
        _sendToBackground({
          'type': 'CANCEL_TASK',
          'taskId': id,
        });
      }
    }

    if (!isManga) {
      for (final id in taskIds) {
        final token = _scrapeTokens[id];
        if (token != null) {
          final taskInActive =
              activeTasks.firstWhereOrNull((t) => t.taskId == id);
          if (taskInActive != null) {
            final source = findMatchingSource(
                    Get.find<SourceController>().installedExtensions,
                    taskInActive.extensionName) ??
                findMatchingSource(
                    Get.find<SourceController>().installedMangaExtensions,
                    taskInActive.extensionName);
            source?.cancelRequest(token);
          }
          _scrapeTokens.remove(id);
        }
      }
      activeTasks.removeWhere((t) => taskIds.contains(t.taskId));
      _saveActiveTasks();
      _updateNotification();
    } else {
      activeMangaTasks.removeWhere((t) => taskIds.contains(t.taskId));
      _saveMangaActiveTasks();
    }

    try {
      final rootDir = await _getRootDir();
      final animeDir = Directory(p.join(rootDir.path, 'Anime'));
      if (await animeDir.exists()) {
        await for (final entity
            in animeDir.list(recursive: true, followLinks: false)) {
          if (entity is Directory) {
            final name = p.basename(entity.path);
            if (name.startsWith('temp_')) {
              final tempTaskId = name.substring(5);
              if (taskIds.contains(tempTaskId)) {
                try {
                  await entity.delete(recursive: true);
                } catch (_) {}
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> removeTask(String taskId) async {
    _clearSpeed(taskId);
    dl.DownloadIsolatePool.instance.cancelTask(taskId);
    activeTasks.removeWhere((t) => t.taskId == taskId);
    _saveActiveTasks();
  }

  Future<Directory> _getRootDir() async {
    final customPath = DownloadKeys.downloadPath.get<String>('');
    if (customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (await dir.exists()) return dir;
    }

    if (Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        return Directory(p.join(ext.path, 'AnymeX', 'Downloads'));
      }
    }
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'AnymeX', 'Downloads'));
  }

  Future<String> _getMediaDirPath(String title, String sourceName,
      {String mediaType = 'Anime'}) async {
    final root = await _getRootDir();
    final dir = Directory(p.join(root.path, mediaType, sourceName, title));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<String> _getMangaMediaDirPath(String title, String sourceName) =>
      _getMediaDirPath(title, sourceName, mediaType: 'Manga');

  Future<void> _writeEpisodeMeta(
      ActiveDownloadTask task, String fileName) async {
    final mediaDir = await _getMediaDirPath(task.mediaTitle, task.extensionName,
        mediaType: 'Anime');
    final metaFile = File(p.join(mediaDir, 'metadata.json'));

    DownloadedMediaMeta meta;
    if (await metaFile.exists()) {
      try {
        final raw =
            jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
        meta = DownloadedMediaMeta.fromJson(raw);
      } catch (e) {
        meta = const DownloadedMediaMeta(episodes: []);
      }
    } else {
      meta = const DownloadedMediaMeta(episodes: []);
    }

    final sortMap = task.episode.sortMap;
    final alreadyExists = meta.episodes.any(
      (e) => e.number == task.episode.number && _mapsEqual(e.sortMap, sortMap),
    );

    if (!alreadyExists) {
      final updatedEps = [
        ...meta.episodes,
        DownloadedEpisodeMeta(
          episode: task.episode,
          fileName: fileName,
          downloadedAt: DateTime.now().millisecondsSinceEpoch,
          filePath: task.filePath ?? '',
          quality: task.videoQuality,
          subtitles: task.subtitles,
        ),
      ];
      updatedEps.sort((a, b) {
        final sa = (int.tryParse(a.sortMap['season'] ?? '0') ?? 0);
        final sb = (int.tryParse(b.sortMap['season'] ?? '0') ?? 0);
        if (sa != sb) return sa.compareTo(sb);
        return (double.tryParse(a.number) ?? 0)
            .compareTo(double.tryParse(b.number) ?? 0);
      });
      meta = DownloadedMediaMeta(
        episodes: updatedEps,
        watchedProgress: meta.watchedProgress,
        media: meta.media ?? task.media,
      );
    }

    await metaFile.writeAsString(jsonEncode(meta.toJson()), flush: true);
    mediaMetaCache[_cacheKey(task.extensionName, task.mediaTitle)] = meta;
  }

  Future<void> setMediaMeta(String ext, String title, OfflineMedia media,
      {String mediaType = 'Anime'}) async {
    final mediaDir = await _getMediaDirPath(title, ext, mediaType: mediaType);

    await _updateGlobalSummary(
      title: title,
      poster: media.poster ?? media.cover,
      extensionName: ext,
      folderName: title,
      mediaType: mediaType,
    );

    if (mediaType == 'Anime') {
      final metaFile = File(p.join(mediaDir, 'metadata.json'));
      DownloadedMediaMeta meta;
      if (await metaFile.exists()) {
        try {
          final raw =
              jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
          meta = DownloadedMediaMeta.fromJson(raw);
        } catch (_) {
          meta = const DownloadedMediaMeta(episodes: []);
        }
      } else {
        meta = const DownloadedMediaMeta(episodes: []);
      }

      meta = DownloadedMediaMeta(
        episodes: meta.episodes,
        watchedProgress: meta.watchedProgress,
        media: media,
      );

      await metaFile.writeAsString(
        jsonEncode(meta.toJson()),
        flush: true,
      );
      mediaMetaCache[_cacheKey(ext, title)] = meta;
    } else {
      final metaFile = File(p.join(mediaDir, 'metadata.json'));
      DownloadedMangaMeta meta;
      if (await metaFile.exists()) {
        try {
          final raw =
              jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
          meta = DownloadedMangaMeta.fromJson(raw);
        } catch (_) {
          meta = const DownloadedMangaMeta(chapters: []);
        }
      } else {
        meta = const DownloadedMangaMeta(chapters: []);
      }

      meta = DownloadedMangaMeta(
        chapters: meta.chapters,
        media: media,
      );

      await metaFile.writeAsString(
        jsonEncode(meta.toJson()),
        flush: true,
      );
      mangaMetaCache[_cacheKey(ext, title)] = meta;
    }
  }

  Future<void> _updateGlobalSummary({
    required String title,
    String? poster,
    required String extensionName,
    required String folderName,
    String mediaType = 'Anime',
  }) async {
    final root = await _getRootDir();
    if (!await root.exists()) await root.create(recursive: true);
    final indexFile = File(p.join(root.path, 'metadata.json'));

    List<DownloadedMediaSummary> items = [];
    if (await indexFile.exists()) {
      try {
        final raw =
            jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
        items = (raw['items'] as List<dynamic>? ?? [])
            .map((e) =>
                DownloadedMediaSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        items = [];
      }
    }

    final index = items.indexWhere(
      (i) => i.extensionName == extensionName && i.folderName == folderName,
    );

    final summary = DownloadedMediaSummary(
      title: title,
      poster: poster,
      extensionName: extensionName,
      folderName: folderName,
      mediaType: mediaType,
    );

    if (index != -1) {
      items[index] = summary;
    } else {
      items.add(summary);
    }

    await indexFile.writeAsString(
      jsonEncode({'items': items.map((i) => i.toJson()).toList()}),
      flush: true,
    );

    final rxIdx = downloadedMedia.indexWhere(
      (i) => i.extensionName == extensionName && i.folderName == folderName,
    );
    if (rxIdx != -1) {
      downloadedMedia[rxIdx] = summary;
    } else {
      downloadedMedia.add(summary);
    }
    downloadedMedia.refresh();
  }

  Future<DownloadedMediaSummary?> updateDownloadedMediaMetadata(
    String folderName, {
    String? newTitle,
    String? newPoster,
  }) async {
    final root = await _getRootDir();
    if (!await root.exists()) return null;
    final indexFile = File(p.join(root.path, 'metadata.json'));
    if (!await indexFile.exists()) return null;

    try {
      final raw =
          jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
      final itemsRaw = raw['items'] as List<dynamic>? ?? [];
      final items = itemsRaw
          .map(
              (e) => DownloadedMediaSummary.fromJson(e as Map<String, dynamic>))
          .toList();

      final index = items.indexWhere((i) => i.folderName == folderName);
      if (index != -1) {
        final existing = items[index];
        final updated = DownloadedMediaSummary(
          title: (newTitle != null && newTitle.trim().isNotEmpty)
              ? newTitle.trim()
              : existing.title,
          poster: (newPoster != null && newPoster.trim().isNotEmpty)
              ? newPoster.trim()
              : existing.poster,
          extensionName: existing.extensionName,
          folderName: existing.folderName,
          mediaType: existing.mediaType,
        );
        items[index] = updated;

        await indexFile.writeAsString(
          jsonEncode({'items': items.map((i) => i.toJson()).toList()}),
          flush: true,
        );

        final rxIndex =
            downloadedMedia.indexWhere((i) => i.folderName == folderName);
        if (rxIndex != -1) {
          downloadedMedia[rxIndex] = updated;
          downloadedMedia.refresh();
        }
        return updated;
      }
    } catch (e) {
      debugPrint('DownloadController: error updating metadata: $e');
    }
    return null;
  }

  Future<void> _ensureNoMediaInTempDirs(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return;
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is Directory) {
          final isTemp = p.basename(entity.path).startsWith('temp_');
          bool hasTs = false;
          if (!isTemp) {
            try {
              hasTs = await entity.list().any((e) => e.path.endsWith('.ts'));
            } catch (_) {}
          }
          if (isTemp || hasTs) {
            final nomedia = File(p.join(entity.path, '.nomedia'));
            if (!await nomedia.exists()) {
              await nomedia.create();
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadIndex() async {
    try {
      final root = await _getRootDir();
      _ensureNoMediaInTempDirs(root.path);
      await resyncDownloads();
    } catch (e) {
      debugPrint('DownloadController: error loading index: $e');
    }
  }

  Future<void> _safeMoveFile(File source, String targetPath) async {
    try {
      await source.rename(targetPath);
    } catch (_) {
      await source.copy(targetPath);
      await source.delete();
    }
  }

  Future<void> _safeMoveDir(Directory source, String targetPath) async {
    try {
      await source.rename(targetPath);
    } catch (_) {
      final target = Directory(targetPath);
      if (!await target.exists()) await target.create(recursive: true);
      await for (final entity in source.list(recursive: false)) {
        final newPath = p.join(targetPath, p.basename(entity.path));
        if (entity is File) {
          await _safeMoveFile(entity, newPath);
        } else if (entity is Directory) {
          await _safeMoveDir(entity, newPath);
        }
      }
      await source.delete(recursive: true);
    }
  }

  Future<void> _consolidateDownloads() async {
    try {
      final root = await _getRootDir();
      if (!await root.exists()) return;

      for (final type in ['Anime', 'Manga']) {
        final typeDir = Directory(p.join(root.path, type));
        if (!await typeDir.exists()) continue;

        final extEntities = await typeDir.list().toList();
        final extDirs = extEntities.whereType<Directory>().toList();

        for (final extDir in extDirs) {
          final extName = p.basename(extDir.path);
          if (extName == 'AnymeX') continue;

          final mediaEntities = await extDir.list().toList();
          final mediaDirs = mediaEntities.whereType<Directory>().toList();

          for (final mediaDir in mediaDirs) {
            final folderName = p.basename(mediaDir.path);
            final metaFile = File(p.join(mediaDir.path, 'metadata.json'));
            bool isMetadataMedia = false;

            if (await metaFile.exists()) {
              try {
                final raw = jsonDecode(await metaFile.readAsString())
                    as Map<String, dynamic>;
                final mediaRaw = raw['media'] as Map<String, dynamic>?;
                final mediaId = mediaRaw?['mediaId'] as String?;
                if (mediaId != null && mediaId.trim().isNotEmpty) {
                  isMetadataMedia = true;
                }
              } catch (_) {}
            }

            final unifiedDir =
                Directory(p.join(root.path, type, 'AnymeX', folderName));
            final hasUnified = await unifiedDir.exists();

            bool hasMatchingFolderInOtherExt = false;
            for (final otherExtDir in extDirs) {
              if (otherExtDir.path == extDir.path) continue;
              final matchingDir =
                  Directory(p.join(otherExtDir.path, folderName));
              if (await matchingDir.exists()) {
                hasMatchingFolderInOtherExt = true;
                break;
              }
            }

            if (isMetadataMedia || hasUnified || hasMatchingFolderInOtherExt) {
              await _mergeMediaDirectory(
                sourceDir: mediaDir,
                sourceExt: extName,
                targetDir: unifiedDir,
                targetExt: 'AnymeX',
                folderName: folderName,
                mediaType: type,
              );
            }
          }

          if (await extDir.list().isEmpty) {
            try {
              await extDir.delete();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('DownloadController: error consolidating downloads: $e');
    }
  }

  Future<void> _mergeMediaDirectory({
    required Directory sourceDir,
    required String sourceExt,
    required Directory targetDir,
    required String targetExt,
    required String folderName,
    required String mediaType,
  }) async {
    try {
      if (!await targetDir.exists()) await targetDir.create(recursive: true);

      if (mediaType == 'Anime') {
        DownloadedMediaMeta sourceMeta =
            const DownloadedMediaMeta(episodes: []);
        final sourceMetaFile = File(p.join(sourceDir.path, 'metadata.json'));
        if (await sourceMetaFile.exists()) {
          try {
            final raw = jsonDecode(await sourceMetaFile.readAsString())
                as Map<String, dynamic>;
            sourceMeta = DownloadedMediaMeta.fromJson(raw);
          } catch (_) {}
        }

        DownloadedMediaMeta targetMeta =
            const DownloadedMediaMeta(episodes: []);
        final targetMetaFile = File(p.join(targetDir.path, 'metadata.json'));
        if (await targetMetaFile.exists()) {
          try {
            final raw = jsonDecode(await targetMetaFile.readAsString())
                as Map<String, dynamic>;
            targetMeta = DownloadedMediaMeta.fromJson(raw);
          } catch (_) {}
        }

        await for (final entity in sourceDir.list()) {
          if (entity is File) {
            final name = p.basename(entity.path);
            if (name == 'metadata.json') {
              try {
                await entity.delete();
              } catch (_) {}
              continue;
            }
            final ext = p.extension(name).toLowerCase();
            if ([
                  '.mp4',
                  '.mkv',
                  '.avi',
                  '.webm',
                  '.mov',
                  '.ts',
                  '.vtt',
                  '.srt',
                  '.ass'
                ].contains(ext) &&
                !name.startsWith('.')) {
              final destPath = p.join(targetDir.path, name);
              final destFile = File(destPath);
              if (await destFile.exists() && await destFile.length() > 0) {
                try {
                  await entity.delete();
                } catch (_) {}
              } else {
                await _safeMoveFile(entity, destPath);
              }
            }
          }
        }

        final targetEpisodes = <DownloadedEpisodeMeta>[...targetMeta.episodes];
        for (final ep in sourceMeta.episodes) {
          final newFilePath = p.join(targetDir.path,
              ep.fileName.isNotEmpty ? ep.fileName : p.basename(ep.filePath));
          final exists = targetEpisodes.any((e) =>
              e.number == ep.number && _mapsEqual(e.sortMap, ep.sortMap));
          if (!exists) {
            targetEpisodes.add(DownloadedEpisodeMeta(
              episode: ep.episode,
              fileName: ep.fileName.isNotEmpty
                  ? ep.fileName
                  : p.basename(newFilePath),
              downloadedAt: ep.downloadedAt,
              filePath: newFilePath,
              quality: ep.quality,
              subtitles: ep.subtitles,
            ));
          }
        }

        targetEpisodes.sort((a, b) {
          final aNum = double.tryParse(a.number) ?? 0.0;
          final bNum = double.tryParse(b.number) ?? 0.0;
          return aNum.compareTo(bNum);
        });

        final mergedWatched = {
          ...targetMeta.watchedProgress,
          ...sourceMeta.watchedProgress
        };
        final mergedMedia = targetMeta.media ?? sourceMeta.media;
        final updatedTargetMeta = DownloadedMediaMeta(
          episodes: targetEpisodes,
          watchedProgress: mergedWatched,
          media: mergedMedia,
        );

        await targetMetaFile
            .writeAsString(jsonEncode(updatedTargetMeta.toJson()), flush: true);
        mediaMetaCache[_cacheKey(targetExt, folderName)] = updatedTargetMeta;
        mediaMetaCache.remove(_cacheKey(sourceExt, folderName));
      } else {
        DownloadedMangaMeta sourceMeta =
            const DownloadedMangaMeta(chapters: []);
        final sourceMetaFile = File(p.join(sourceDir.path, 'metadata.json'));
        if (await sourceMetaFile.exists()) {
          try {
            final raw = jsonDecode(await sourceMetaFile.readAsString())
                as Map<String, dynamic>;
            sourceMeta = DownloadedMangaMeta.fromJson(raw);
          } catch (_) {}
        }

        DownloadedMangaMeta targetMeta =
            const DownloadedMangaMeta(chapters: []);
        final targetMetaFile = File(p.join(targetDir.path, 'metadata.json'));
        if (await targetMetaFile.exists()) {
          try {
            final raw = jsonDecode(await targetMetaFile.readAsString())
                as Map<String, dynamic>;
            targetMeta = DownloadedMangaMeta.fromJson(raw);
          } catch (_) {}
        }

        await for (final entity in sourceDir.list()) {
          if (entity is Directory) {
            final name = p.basename(entity.path);
            if (!name.startsWith('temp_')) {
              final destPath = p.join(targetDir.path, name);
              final destDir = Directory(destPath);
              if (await destDir.exists()) {
                await for (final img in entity.list()) {
                  if (img is File) {
                    final destImg =
                        File(p.join(destDir.path, p.basename(img.path)));
                    if (!await destImg.exists()) {
                      await _safeMoveFile(img, destImg.path);
                    }
                  }
                }
                try {
                  await entity.delete(recursive: true);
                } catch (_) {}
              } else {
                await _safeMoveDir(entity, destPath);
              }
            }
          } else if (entity is File &&
              p.basename(entity.path) == 'metadata.json') {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }

        final targetChapters = <DownloadedChapterMeta>[...targetMeta.chapters];
        for (final ch in sourceMeta.chapters) {
          final newImageDir = p.join(targetDir.path, p.basename(ch.imageDir));
          final exists =
              targetChapters.any((c) => c.chapter.number == ch.chapter.number);
          if (!exists) {
            ch.chapter.localPath = newImageDir;
            if (ch.chapter.link == null || ch.chapter.link!.isEmpty) {
              ch.chapter.link = newImageDir;
            }
            targetChapters.add(DownloadedChapterMeta(
              chapter: ch.chapter,
              imageDir: newImageDir,
              pageCount: ch.pageCount,
              downloadedAt: ch.downloadedAt,
            ));
          }
        }

        targetChapters.sort((a, b) {
          final aNum = a.chapter.number ?? 0.0;
          final bNum = b.chapter.number ?? 0.0;
          return aNum.compareTo(bNum);
        });

        final mergedMedia = targetMeta.media ?? sourceMeta.media;
        final updatedTargetMeta = DownloadedMangaMeta(
          chapters: targetChapters,
          media: mergedMedia,
        );

        await targetMetaFile
            .writeAsString(jsonEncode(updatedTargetMeta.toJson()), flush: true);
        mangaMetaCache[_cacheKey(targetExt, folderName)] = updatedTargetMeta;
        mangaMetaCache.remove(_cacheKey(sourceExt, folderName));
      }

      if (await sourceDir.exists()) {
        try {
          await sourceDir.delete(recursive: true);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('DownloadController: error merging media directory: $e');
    }
  }

  Future<void> resyncDownloads() async {
    try {
      final root = await _getRootDir();
      if (!await root.exists()) {
        downloadedMedia.clear();
        return;
      }

      await _consolidateDownloads();

      final Map<String, DownloadedMediaSummary> summaryMap = {};
      final indexFile = File(p.join(root.path, 'metadata.json'));
      if (await indexFile.exists()) {
        try {
          final raw = jsonDecode(await indexFile.readAsString())
              as Map<String, dynamic>;
          final itemsRaw = raw['items'] as List<dynamic>? ?? [];
          for (final item in itemsRaw) {
            final summary =
                DownloadedMediaSummary.fromJson(item as Map<String, dynamic>);
            summaryMap[
                    '${summary.mediaType}_${summary.extensionName}_${summary.folderName}'] =
                summary;
          }
        } catch (_) {}
      }

      final List<DownloadedMediaSummary> verifiedSummaries = [];

      for (final type in ['Anime', 'Manga']) {
        final typeDir = Directory(p.join(root.path, type));
        if (!await typeDir.exists()) continue;

        await for (final extEntity in typeDir.list()) {
          if (extEntity is! Directory) continue;
          final extName = p.basename(extEntity.path);

          await for (final mediaEntity in extEntity.list()) {
            if (mediaEntity is! Directory) continue;
            final folderName = p.basename(mediaEntity.path);

            final key = '${type}_${extName}_$folderName';
            final existingSummary = summaryMap[key];
            var title = existingSummary?.title.isNotEmpty == true
                ? existingSummary!.title
                : folderName;
            var poster = existingSummary?.poster;

            final hasContent = await _syncMediaFolderMeta(
              mediaDir: mediaEntity.path,
              ext: extName,
              title: title,
              mediaType: type,
            );

            if (type == 'Anime') {
              final cached = mediaMetaCache[_cacheKey(extName, title)] ??
                  mediaMetaCache[_cacheKey(extName, folderName)];
              final m = cached?.media;
              if (m != null) {
                if (poster == null || poster.isEmpty) {
                  poster = (m.poster?.isNotEmpty == true) ? m.poster : m.cover;
                }
                if (title == folderName && m.name?.isNotEmpty == true) {
                  title = m.name!;
                }
              }
            } else {
              final cached = mangaMetaCache[_cacheKey(extName, title)] ??
                  mangaMetaCache[_cacheKey(extName, folderName)];
              final m = cached?.media;
              if (m != null) {
                if (poster == null || poster.isEmpty) {
                  poster = (m.poster?.isNotEmpty == true) ? m.poster : m.cover;
                }
                if (title == folderName && m.name?.isNotEmpty == true) {
                  title = m.name!;
                }
              }
            }

            if (hasContent) {
              final summary = DownloadedMediaSummary(
                title: title,
                poster: poster,
                extensionName: extName,
                folderName: folderName,
                mediaType: type,
              );
              verifiedSummaries.add(summary);
            }
          }
        }
      }

      await indexFile.writeAsString(
        jsonEncode(
            {'items': verifiedSummaries.map((i) => i.toJson()).toList()}),
        flush: true,
      );

      downloadedMedia.value = verifiedSummaries;
    } catch (e) {
      debugPrint('DownloadController: error resyncing downloads: $e');
    }
  }

  Future<bool> _syncMediaFolderMeta({
    required String mediaDir,
    required String ext,
    required String title,
    required String mediaType,
  }) async {
    final metaFile = File(p.join(mediaDir, 'metadata.json'));

    if (mediaType == 'Anime') {
      DownloadedMediaMeta meta = const DownloadedMediaMeta(episodes: []);
      if (await metaFile.exists()) {
        try {
          final raw =
              jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
          meta = DownloadedMediaMeta.fromJson(raw);
        } catch (_) {}
      }

      final verifiedEpisodes = <DownloadedEpisodeMeta>[];
      final existingFileNames = <String>{};
      final existingFilePaths = <String>{};

      for (final epMeta in meta.episodes) {
        String epFilePath = epMeta.filePath.isNotEmpty
            ? epMeta.filePath
            : p.join(mediaDir, epMeta.fileName);
        var file = File(epFilePath);
        if (!await file.exists() || await file.length() == 0) {
          final fallbackPath = p.join(
              mediaDir,
              epMeta.fileName.isNotEmpty
                  ? epMeta.fileName
                  : p.basename(epFilePath));
          final fallbackFile = File(fallbackPath);
          if (await fallbackFile.exists() && await fallbackFile.length() > 0) {
            epFilePath = fallbackPath;
            file = fallbackFile;
          }
        }
        if (await file.exists() && await file.length() > 0) {
          verifiedEpisodes.add(epMeta.filePath == epFilePath
              ? epMeta
              : DownloadedEpisodeMeta(
                  episode: epMeta.episode,
                  fileName: epMeta.fileName.isNotEmpty
                      ? epMeta.fileName
                      : p.basename(epFilePath),
                  downloadedAt: epMeta.downloadedAt,
                  filePath: epFilePath,
                  quality: epMeta.quality,
                  subtitles: epMeta.subtitles,
                ));
          if (epMeta.fileName.isNotEmpty)
            existingFileNames.add(epMeta.fileName);
          existingFilePaths.add(epFilePath);
        }
      }

      final dir = Directory(mediaDir);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            final fileName = p.basename(entity.path);
            final extName = p.extension(fileName).toLowerCase();
            if (['.mp4', '.mkv', '.avi', '.webm', '.mov', '.ts', '.m3u8']
                    .contains(extName) &&
                !fileName.startsWith('.')) {
              if (!existingFileNames.contains(fileName) &&
                  !existingFilePaths.contains(entity.path) &&
                  await entity.length() > 0) {
                final epNum = _parseEpisodeNumberFromFileName(fileName);
                final season = _parseSeasonFromFileName(fileName);
                final sortMap = <String, String>{};
                if (season != null) sortMap['season'] = season;

                final newEp = DownloadedEpisodeMeta(
                  episode: Episode(
                    number: epNum,
                    title: 'Episode $epNum',
                    sortKeys: sortMap.keys.toList(),
                    sortVals: sortMap.values.toList(),
                  ),
                  fileName: fileName,
                  downloadedAt:
                      entity.lastModifiedSync().millisecondsSinceEpoch,
                  filePath: entity.path,
                );
                verifiedEpisodes.add(newEp);
                existingFileNames.add(fileName);
                existingFilePaths.add(entity.path);
              }
            }
          }
        }
      }

      verifiedEpisodes.sort((a, b) {
        final aNum = double.tryParse(a.number) ?? 0.0;
        final bNum = double.tryParse(b.number) ?? 0.0;
        return aNum.compareTo(bNum);
      });

      final updatedMeta = DownloadedMediaMeta(
        episodes: verifiedEpisodes,
        watchedProgress: meta.watchedProgress,
        media: meta.media,
      );

      final hasActiveAnime = activeTasks.any((t) =>
          t.extensionName.toLowerCase() == ext.toLowerCase() &&
          t.mediaTitle.toLowerCase() == title.toLowerCase());

      mediaMetaCache[_cacheKey(ext, title)] = updatedMeta;

      if (verifiedEpisodes.isNotEmpty || hasActiveAnime || meta.media != null) {
        await metaFile.writeAsString(jsonEncode(updatedMeta.toJson()),
            flush: true);
        return verifiedEpisodes.isNotEmpty;
      } else {
        if (await metaFile.exists()) await metaFile.delete();
        mediaMetaCache.remove(_cacheKey(ext, title));
        return false;
      }
    } else {
      DownloadedMangaMeta meta = const DownloadedMangaMeta(chapters: []);
      if (await metaFile.exists()) {
        try {
          final raw =
              jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
          meta = DownloadedMangaMeta.fromJson(raw);
        } catch (_) {}
      }

      final verifiedChapters = <DownloadedChapterMeta>[];
      final existingDirs = <String>{};

      for (final chMeta in meta.chapters) {
        String chDir = chMeta.imageDir;
        var dir = Directory(chDir);
        if (!await dir.exists()) {
          final fallbackDir = p.join(mediaDir, p.basename(chDir));
          if (await Directory(fallbackDir).exists()) {
            chDir = fallbackDir;
            dir = Directory(fallbackDir);
          }
        }
        if (await dir.exists()) {
          final hasImages = await dir.list().any((e) =>
              e is File &&
              ['.png', '.jpg', '.jpeg', '.webp']
                  .contains(p.extension(e.path).toLowerCase()));
          if (hasImages) {
            chMeta.chapter.localPath = chDir;
            if (chMeta.chapter.link == null || chMeta.chapter.link!.isEmpty) {
              chMeta.chapter.link = chDir;
            }
            verifiedChapters.add(chMeta.imageDir == chDir
                ? chMeta
                : DownloadedChapterMeta(
                    chapter: chMeta.chapter,
                    imageDir: chDir,
                    pageCount: chMeta.pageCount,
                    downloadedAt: chMeta.downloadedAt,
                  ));
            existingDirs.add(chDir);
          }
        }
      }

      final dir = Directory(mediaDir);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is Directory &&
              !p.basename(entity.path).startsWith('temp_')) {
            if (!existingDirs.contains(entity.path)) {
              final imageCount = await entity
                  .list()
                  .where((e) =>
                      e is File &&
                      ['.png', '.jpg', '.jpeg', '.webp']
                          .contains(p.extension(e.path).toLowerCase()))
                  .length;
              if (imageCount > 0) {
                final chNum =
                    _parseChapterNumberFromDir(p.basename(entity.path));
                final newCh = DownloadedChapterMeta(
                  chapter: Chapter(
                    number: chNum,
                    title:
                        'Chapter ${chNum != null && chNum % 1 == 0 ? chNum.toInt() : chNum}',
                    link: entity.path,
                    localPath: entity.path,
                  ),
                  imageDir: entity.path,
                  pageCount: imageCount,
                  downloadedAt:
                      entity.statSync().modified.millisecondsSinceEpoch,
                );
                verifiedChapters.add(newCh);
                existingDirs.add(entity.path);
              }
            }
          }
        }
      }

      verifiedChapters.sort((a, b) {
        final aNum = a.chapter.number ?? 0.0;
        final bNum = b.chapter.number ?? 0.0;
        return aNum.compareTo(bNum);
      });

      final updatedMeta = DownloadedMangaMeta(
        chapters: verifiedChapters,
        media: meta.media,
      );

      final hasActiveManga = activeMangaTasks.any((t) =>
          t.extensionName.toLowerCase() == ext.toLowerCase() &&
          t.mediaTitle.toLowerCase() == title.toLowerCase());

      mangaMetaCache[_cacheKey(ext, title)] = updatedMeta;

      if (verifiedChapters.isNotEmpty || hasActiveManga || meta.media != null) {
        await metaFile.writeAsString(jsonEncode(updatedMeta.toJson()),
            flush: true);
        return verifiedChapters.isNotEmpty;
      } else {
        if (await metaFile.exists()) await metaFile.delete();
        mangaMetaCache.remove(_cacheKey(ext, title));
        return false;
      }
    }
  }

  String _parseEpisodeNumberFromFileName(String fileName) {
    final nameWithoutExt = p.basenameWithoutExtension(fileName);
    final matchEp =
        RegExp(r'(?:EP|Episode[_\s]*)(\d+(?:\.\d+)?)', caseSensitive: false)
            .firstMatch(nameWithoutExt);
    if (matchEp != null) {
      return matchEp.group(1)!;
    }
    final numberMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(nameWithoutExt);
    if (numberMatch != null) {
      return numberMatch.group(1)!;
    }
    return '1';
  }

  String? _parseSeasonFromFileName(String fileName) {
    final nameWithoutExt = p.basenameWithoutExtension(fileName);
    final match =
        RegExp(r'S(\d+)_', caseSensitive: false).firstMatch(nameWithoutExt);
    return match?.group(1);
  }

  double? _parseChapterNumberFromDir(String dirName) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(dirName);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return 1.0;
  }

  Future<void> updateEpisodeProgress(
    String ext,
    String title,
    String epNumber,
    Map<String, String> sortMap,
    int timestampMs,
    int durationMs,
  ) async {
    final root = await _getRootDir();
    var targetExt = ext;
    var mediaDir = p.join(root.path, 'Anime', ext, title);
    var metaFile = File(p.join(mediaDir, 'metadata.json'));
    if (!await metaFile.exists()) {
      final unifiedDir = p.join(root.path, 'Anime', 'AnymeX', title);
      final unifiedMeta = File(p.join(unifiedDir, 'metadata.json'));
      if (await unifiedMeta.exists()) {
        mediaDir = unifiedDir;
        metaFile = unifiedMeta;
        targetExt = 'AnymeX';
      }
    }
    if (!await metaFile.exists()) {
      mediaDir = await _getMediaDirPath(title, ext, mediaType: 'Anime');
      metaFile = File(p.join(mediaDir, 'metadata.json'));
    }
    if (!await metaFile.exists()) return;

    final raw =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    final meta = DownloadedMediaMeta.fromJson(raw);

    final updatedEps = meta.episodes.map((ep) {
      if (ep.number == epNumber && _mapsEqual(ep.sortMap, sortMap)) {
        ep.episode.timeStampInMilliseconds = timestampMs;
        ep.episode.durationInMilliseconds = durationMs;
        ep.episode.lastWatchedTime = DateTime.now().millisecondsSinceEpoch;
      }
      return ep;
    }).toList();

    final updated = DownloadedMediaMeta(
      episodes: updatedEps,
      watchedProgress: meta.watchedProgress,
      media: meta.media,
    );
    await metaFile.writeAsString(jsonEncode(updated.toJson()), flush: true);
    mediaMetaCache[_cacheKey(targetExt, title)] = updated;
    await _loadIndex();
  }

  Future<void> updateChapterProgress(
    String ext,
    String title,
    String chapterNumber,
    int pageNumber,
    int totalPages,
  ) async {
    final root = await _getRootDir();
    var targetExt = ext;
    var mediaDir = p.join(root.path, 'Manga', ext, title);
    var metaFile = File(p.join(mediaDir, 'metadata.json'));
    if (!await metaFile.exists()) {
      final unifiedDir = p.join(root.path, 'Manga', 'AnymeX', title);
      final unifiedMeta = File(p.join(unifiedDir, 'metadata.json'));
      if (await unifiedMeta.exists()) {
        mediaDir = unifiedDir;
        metaFile = unifiedMeta;
        targetExt = 'AnymeX';
      }
    }
    if (!await metaFile.exists()) {
      mediaDir = await _getMangaMediaDirPath(title, ext);
      metaFile = File(p.join(mediaDir, 'metadata.json'));
    }
    if (!await metaFile.exists()) return;

    final raw =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    final meta = DownloadedMangaMeta.fromJson(raw);

    final updatedChapters = meta.chapters.map((ch) {
      final chNum = ch.chapter.number?.toString();
      if (chNum == chapterNumber) {
        ch.chapter.pageNumber = pageNumber;
        ch.chapter.totalPages = totalPages;
        ch.chapter.lastReadTime = DateTime.now().millisecondsSinceEpoch;
      }
      return ch;
    }).toList();

    final updated = DownloadedMangaMeta(
      chapters: updatedChapters,
      media: meta.media,
    );
    await metaFile.writeAsString(jsonEncode(updated.toJson()), flush: true);
    mangaMetaCache[_cacheKey(targetExt, title)] = updated;
  }

  Future<DownloadedMediaMeta?> getMediaMeta(String ext, String title) async {
    final root = await _getRootDir();
    var mediaDir = p.join(root.path, 'Anime', ext, title);
    var targetExt = ext;
    if (!await Directory(mediaDir).exists()) {
      final unifiedDir = p.join(root.path, 'Anime', 'AnymeX', title);
      if (await Directory(unifiedDir).exists()) {
        mediaDir = unifiedDir;
        targetExt = 'AnymeX';
      }
    }
    await _syncMediaFolderMeta(
      mediaDir: mediaDir,
      ext: targetExt,
      title: title,
      mediaType: 'Anime',
    );
    final metaFile = File(p.join(mediaDir, 'metadata.json'));
    if (!await metaFile.exists()) return null;
    final raw =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    final result = DownloadedMediaMeta.fromJson(raw);
    mediaMetaCache[_cacheKey(targetExt, title)] = result;
    return result;
  }

  Future<void> deleteMedia(String ext, String title,
      {String mediaType = 'Anime'}) async {
    final root = await _getRootDir();
    final directDir = Directory(p.join(root.path, mediaType, ext, title));
    if (await directDir.exists()) {
      await directDir.delete(recursive: true);
    }
    if (ext != 'AnymeX') {
      final unifiedDir =
          Directory(p.join(root.path, mediaType, 'AnymeX', title));
      if (await unifiedDir.exists()) {
        await unifiedDir.delete(recursive: true);
      }
    }
    mediaMetaCache.remove(_cacheKey(ext, title));
    mediaMetaCache.remove(_cacheKey('AnymeX', title));
    mangaMetaCache.remove(_cacheKey(ext, title));
    mangaMetaCache.remove(_cacheKey('AnymeX', title));
    await _removeFromGlobalIndex(ext, title);
    if (ext != 'AnymeX') {
      await _removeFromGlobalIndex('AnymeX', title);
    }
    await _loadIndex();
  }

  Future<void> deleteEpisode(String ext, String title, String epNumber,
      Map<String, String> sortMap) async {
    final root = await _getRootDir();
    var targetExt = ext;
    var mediaDir = p.join(root.path, 'Anime', ext, title);
    var metaFile = File(p.join(mediaDir, 'metadata.json'));
    if (!await metaFile.exists()) {
      final unifiedDir = p.join(root.path, 'Anime', 'AnymeX', title);
      final unifiedMeta = File(p.join(unifiedDir, 'metadata.json'));
      if (await unifiedMeta.exists()) {
        mediaDir = unifiedDir;
        metaFile = unifiedMeta;
        targetExt = 'AnymeX';
      }
    }
    if (!await metaFile.exists()) {
      mediaDir = await _getMediaDirPath(title, ext, mediaType: 'Anime');
      metaFile = File(p.join(mediaDir, 'metadata.json'));
    }
    if (!await metaFile.exists()) return;

    final raw =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    var meta = DownloadedMediaMeta.fromJson(raw);

    final ep = meta.episodes.firstWhereOrNull(
      (e) => e.number == epNumber && _mapsEqual(e.sortMap, sortMap),
    );
    if (ep != null) {
      final epFile = File(ep.filePath);
      if (await epFile.exists()) await epFile.delete();
    }

    meta = DownloadedMediaMeta(
      episodes: meta.episodes
          .where(
            (e) => !(e.number == epNumber && _mapsEqual(e.sortMap, sortMap)),
          )
          .toList(),
      watchedProgress: meta.watchedProgress,
      media: meta.media,
    );
    await metaFile.writeAsString(jsonEncode(meta.toJson()), flush: true);
    mediaMetaCache[_cacheKey(targetExt, title)] = meta;
    await _loadIndex();
  }

  Future<void> deleteChapter(
      String ext, String title, double? chapterNum) async {
    final root = await _getRootDir();
    var targetExt = ext;
    var mediaDir = p.join(root.path, 'Manga', ext, title);
    var metaFile = File(p.join(mediaDir, 'metadata.json'));
    if (!await metaFile.exists()) {
      final unifiedDir = p.join(root.path, 'Manga', 'AnymeX', title);
      final unifiedMeta = File(p.join(unifiedDir, 'metadata.json'));
      if (await unifiedMeta.exists()) {
        mediaDir = unifiedDir;
        metaFile = unifiedMeta;
        targetExt = 'AnymeX';
      }
    }
    if (!await metaFile.exists()) {
      mediaDir = await _getMediaDirPath(title, ext, mediaType: 'Manga');
      metaFile = File(p.join(mediaDir, 'metadata.json'));
    }
    if (!await metaFile.exists()) return;

    final raw =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    var meta = DownloadedMangaMeta.fromJson(raw);

    final ch = meta.chapters.firstWhereOrNull(
      (c) => c.chapter.number == chapterNum,
    );

    if (ch != null) {
      final chDir = Directory(ch.imageDir);
      if (await chDir.exists()) await chDir.delete(recursive: true);
    }

    meta = DownloadedMangaMeta(
      chapters:
          meta.chapters.where((c) => c.chapter.number != chapterNum).toList(),
      media: meta.media,
    );

    await metaFile.writeAsString(jsonEncode(meta.toJson()), flush: true);
    mangaMetaCache[_cacheKey(targetExt, title)] = meta;
    await _loadIndex();
  }

  Future<void> _removeFromGlobalIndex(String ext, String title) async {
    final root = await _getRootDir();
    final indexFile = File(p.join(root.path, 'metadata.json'));
    if (!await indexFile.exists()) return;

    final raw =
        jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
    final items = (raw['items'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .where((i) => !(i['extensionName'] == ext &&
            (i['folderName'] == title || i['title'] == title)))
        .toList();
    await indexFile.writeAsString(jsonEncode({'items': items}), flush: true);
  }

  bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  List<ActiveDownloadTask> get pendingOrActiveTasks => activeTasks
      .where((t) =>
          t.status == DownloadStatus.queued ||
          t.status == DownloadStatus.downloading)
      .toList();

  List<ActiveMangaDownloadTask> get pendingOrActiveMangaTasks =>
      activeMangaTasks
          .where((t) =>
              t.status == MangaDownloadStatus.queued ||
              t.status == MangaDownloadStatus.fetchingPages ||
              t.status == MangaDownloadStatus.downloading)
          .toList();

  Future<void> manualSelectServerForTask(
      ActiveDownloadTask task, hive.Video selectedVideo) async {
    task.videoUrl = selectedVideo.url ?? selectedVideo.originalUrl ?? '';
    task.videoHeaders = selectedVideo.headers ?? {};
    task.status = DownloadStatus.queued;

    if (selectedVideo.subtitles != null &&
        selectedVideo.subtitles!.isNotEmpty) {
      await _downloadSubtitles(task, selectedVideo.subtitles!);
    }

    activeTasks.refresh();
    _saveActiveTasks();

    _runEpisodeDownload(task: task);
  }

  Future<void> _downloadSubtitles(
      ActiveDownloadTask task, List<hive.Track> subs) async {
    try {
      final root = await _getRootDir();
      final subsDir = Directory(p.join(
        root.path,
        'Anime',
        task.extensionName,
        task.mediaTitle,
        'Episode_${task.episode.number}_subs',
      ));
      if (!await subsDir.exists()) await subsDir.create(recursive: true);

      final localSubs = <hive.Track>[];
      for (final sub in subs) {
        if (sub.file == null || sub.file!.isEmpty) continue;

        try {
          final ext = MediaDownloader.getSubtitleExtension(sub.file!);
          final fileName = MediaDownloader.sanitizePathSegment(
              '${sub.label ?? "Unknown"}$ext');
          final filePath = p.join(subsDir.path, fileName);
          final response = await http.get(Uri.parse(sub.file!));
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            await File(filePath).writeAsBytes(response.bodyBytes);
            localSubs.add(hive.Track(
              file: filePath,
              label: sub.label,
            ));
          }
        } catch (e) {
          debugPrint('Error downloading subtitle ${sub.label}: $e');
        }
      }
      if (localSubs.isNotEmpty) {
        task.subtitles = localSubs;
      }
    } catch (e) {
      debugPrint('Error creating subtitle directory: $e');
    }
  }
}

class _ScrapeRequest {
  final ActiveDownloadTask task;
  final Source source;
  final String preferredQuality;

  _ScrapeRequest({
    required this.task,
    required this.source,
    required this.preferredQuality,
  });
}

class _MangaScrapeRequest {
  final ActiveMangaDownloadTask task;
  final Source source;

  _MangaScrapeRequest({required this.task, required this.source});
}

class _EarlyExitException implements Exception {}
