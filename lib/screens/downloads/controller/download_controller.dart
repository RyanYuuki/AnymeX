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
import 'package:anymex/utils/media_downloader.dart';
import 'package:anymex/utils/download_isolate_pool.dart' as dl;
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/screens/downloads/nested_screens/active_downloads/active_downloads.dart';
import 'package:anymex/database/isar_models/video.dart' as hive;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:anymex/utils/background_service_handler.dart';

class DownloadController extends GetxController {
  final RxList<ActiveDownloadTask> activeTasks = <ActiveDownloadTask>[].obs;
  final RxList<ActiveMangaDownloadTask> activeMangaTasks =
      <ActiveMangaDownloadTask>[].obs;
  final RxList<DownloadedMediaSummary> downloadedMedia =
      <DownloadedMediaSummary>[].obs;
  final RxBool isInitialized = false.obs;

  final Queue<_ScrapeRequest> _scrapeQueue = Queue();
  final Queue<_MangaScrapeRequest> _mangaScrapeQueue = Queue();
  final Map<String, String> _scrapeTokens = {};
  int _activeTaskCount = 0;
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

    final sourceController = Get.find<SourceController>();

    _initForegroundTask();

    Future.delayed(const Duration(seconds: 3), () async {
      if (!await FlutterForegroundTask.isRunningService) {
        for (final task in activeTasks) {
          if (task.status == DownloadStatus.downloading ||
              task.status == DownloadStatus.queued) {
            _runEpisodeDownload(task: task);
          }
        }
        for (final task in activeMangaTasks) {
          if (task.status == MangaDownloadStatus.downloading ||
              task.status == MangaDownloadStatus.queued) {
            final source = sourceController.installedMangaExtensions
                .firstWhereOrNull((s) => s.name == task.extensionName);
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
    if (_receivePortListening) return;
    final port = FlutterForegroundTask.receivePort;
    if (port == null) return;
    port.listen(_onForegroundReceiveData);
    _receivePortListening = true;
  }

  Future<void> _startBackgroundServiceIfNotRunning() async {
    if (Platform.isIOS) return;
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
            } else if (statusStr == 'completed') {
              task.status = DownloadStatus.completed;
              task.filePath = payload['filePath'] as String?;
            } else if (statusStr == 'failed') {
              task.status = DownloadStatus.failed;
              task.errorMessage = payload['errorMessage'] as String?;
            }
            task.progress = prog;

            if (isTerminal) {
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
            } else if (statusStr == 'completed') {
              task.status = MangaDownloadStatus.completed;
            } else if (statusStr == 'failed') {
              task.status = MangaDownloadStatus.failed;
            }
            task.progress = prog;

            if (isTerminal) {
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
        Get.to(() => const ActiveDownloads());
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
      activeMangaTasks.addAll(tasks);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<List<hive.Video>> fetchServersForEpisode(Source source, Episode ep,
      {String? passedToken}) async {
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
      await for (final v in videoStream) {
        final next = hive.Video.fromVideo(v);
        final alreadyExists = videos.any(
          (existing) =>
              existing.quality == next.quality &&
              existing.originalUrl == next.originalUrl,
        );
        if (!alreadyExists) videos.add(next);
      }
      return videos;
    } else {
      final videoList = await methods.getVideoList(
        deEpisode,
        parameters: SourceParams(cancelToken: token),
      );
      return videoList.map((v) => hive.Video.fromVideo(v)).toList();
    }
  }

  Future<void> enqueueDownloadBatch({
    required List<Episode> episodes,
    required Source source,
    required OfflineMedia media,
    required String preferredQuality,
  }) async {
    final mediaTitle = media.name ?? 'Unknown';
    final sanitizedTitle = MediaDownloader.sanitizePathSegment(mediaTitle);
    final sanitizedExt =
        MediaDownloader.sanitizePathSegment(source.name ?? 'unknown');

    await setMediaMeta(sanitizedExt, sanitizedTitle, media, mediaType: 'Anime');

    for (final ep in episodes) {
      _enqueueEpisode(
        episode: ep,
        source: source,
        sanitizedTitle: sanitizedTitle,
        sanitizedExt: sanitizedExt,
        preferredQuality: preferredQuality,
      );
    }
  }

  void _enqueueEpisode({
    required Episode episode,
    required Source source,
    required String sanitizedTitle,
    required String sanitizedExt,
    required String preferredQuality,
  }) {
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
      videoUrl: '',
      videoQuality: preferredQuality,
      linkType: VideoLinkType.unknown,
      status: DownloadStatus.queued,
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
      final request = _scrapeQueue.removeFirst();
      if (request.task.status == DownloadStatus.cancelled) continue;

      _activeTaskCount++;
      _runEpisodeDownload(
        task: request.task,
        source: request.source,
        preferredQuality: request.preferredQuality,
      ).catchError((e) {
        _activeTaskCount--;
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

    try {
      task.status = DownloadStatus.downloading;
      activeTasks.refresh();
      _saveActiveTasks();

      hive.Video? chosenVideo;
      if (task.videoUrl.isEmpty) {
        if (source == null) {
          task.status = DownloadStatus.failed;
          task.errorMessage = 'Source not found for resuming scrape';
          activeTasks.refresh();
          return;
        }

        final token =
            'dl_scrape_${task.taskId}_${DateTime.now().millisecondsSinceEpoch}';
        _scrapeTokens[task.taskId] = token;

        final videos = await fetchServersForEpisode(source, task.episode,
            passedToken: token);
        _scrapeTokens.remove(task.taskId);

        if (videos.isEmpty) {
          task.status = DownloadStatus.failed;
          task.errorMessage = 'No servers found for this episode';
          activeTasks.refresh();
          return;
        }

        final qualityLabels = videos.map((v) => v.quality ?? '').toList();
        final bestLabel = MediaDownloader.pickBestMatchingVideo(
            qualityLabels, preferredQuality ?? '720p');

        if (bestLabel.isEmpty) {
          task.status = DownloadStatus.failed;
          task.errorMessage = 'Could not find a server with matching quality';
          activeTasks.refresh();
          return;
        }

        chosenVideo = videos.firstWhereOrNull((v) => v.quality == bestLabel) ??
            videos.first;
        task.videoUrl = chosenVideo.url ?? chosenVideo.originalUrl ?? '';
        task.videoHeaders ??= {};
        task.videoHeaders!.addAll(chosenVideo.headers ?? {});
      }

      final linkType = detectLinkType(task.videoUrl);

      if (task.videoUrl.isEmpty) {
        task.status = DownloadStatus.failed;
        task.errorMessage = 'Empty video URL';
        activeTasks.refresh();
        return;
      }

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
        subtitles: chosenVideo?.subtitles,
        subDownloadDir: fullDirPath,
        m3u8Url: isHls ? task.videoUrl : null,
        videoFileName: fileName,
        headers: chosenVideo?.headers ?? task.videoHeaders,
        concurrentDownloads: Get.find<Settings>().hlsParallelSegments.value,
        episodeNumber: task.episode.number,
      );

      _activeFileTasks.add(task.taskId);

      await mDownloader.download((progress) {
        task.progress = progress.completed / progress.total;
        task.status = DownloadStatus.downloading;
        final now = DateTime.now();
        final last = _lastProgressUpdate[task.taskId];
        if (last == null ||
            now.difference(last).inMilliseconds > _progressThrottleMs) {
          _lastProgressUpdate[task.taskId] = now;
          activeTasks.refresh();
        }
      });

      _lastProgressUpdate.remove(task.taskId);
      task.status = DownloadStatus.completed;
      task.filePath = p.join(fullDirPath, fileName);
      task.progress = 1.0;
      await _onTaskFinished(task, fileName);

      _activeFileTasks.remove(task.taskId);
      _activeTaskCount--;
      _processScrapeQueue();
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = e.toString();
      _activeFileTasks.remove(task.taskId);
      _activeTaskCount--;
      _processScrapeQueue();
    } finally {
      activeTasks.refresh();
      _saveActiveTasks();
    }
  }

  Future<void> enqueueMangaDownloadBatch({
    required List<Chapter> chapters,
    required Source source,
    required OfflineMedia media,
  }) async {
    final mediaTitle = media.name ?? 'Unknown';
    final sanitizedTitle = MediaDownloader.sanitizePathSegment(mediaTitle);
    final sanitizedExt =
        MediaDownloader.sanitizePathSegment(source.name ?? 'unknown');

    await setMediaMeta(sanitizedExt, sanitizedTitle, media, mediaType: 'Manga');

    for (final chapter in chapters) {
      _enqueueMangaChapter(
        chapter: chapter,
        source: source,
        sanitizedTitle: sanitizedTitle,
        sanitizedExt: sanitizedExt,
      );
    }
  }

  void _enqueueMangaChapter({
    required Chapter chapter,
    required Source source,
    required String sanitizedTitle,
    required String sanitizedExt,
  }) {
    final chapterNum = chapter.number?.toString() ?? '0';
    final taskId =
        'manga_${sanitizedExt}_${sanitizedTitle}_ch${chapterNum}_${DateTime.now().millisecondsSinceEpoch % 100000}_${Random().nextInt(9999)}';

    final task = ActiveMangaDownloadTask(
      taskId: taskId,
      mediaTitle: sanitizedTitle,
      extensionName: sanitizedExt,
      chapter: chapter,
      status: MangaDownloadStatus.queued,
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
        activeMangaTasks.refresh();
        return;
      }

      final pages = await source.methods.getPageList(
        DEpisode(episodeNumber: '1', url: chapterUrl),
      );

      if (pages.isEmpty) {
        task.status = MangaDownloadStatus.failed;
        task.errorMessage = 'No pages found for this chapter';
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
        return dl.PageUrl(
          url: page.url,
          headers: page.headers?.map((k, v) => MapEntry(k, v.toString())),
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
        final now = DateTime.now();
        final last = _lastProgressUpdate[task.taskId];
        if (last == null ||
            now.difference(last).inMilliseconds > _progressThrottleMs) {
          _lastProgressUpdate[task.taskId] = now;
          activeMangaTasks.refresh();
        }
      });

      _lastProgressUpdate.remove(task.taskId);
      task.status = MangaDownloadStatus.completed;
      task.progress = 1.0;
      await _onForegroundMangaTaskFinished(task, pages.length);
    } catch (e) {
      task.status = MangaDownloadStatus.failed;
      task.errorMessage = e.toString();
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
          chapter: task.chapter,
          imageDir: imageDir,
          pageCount: pageCount,
          downloadedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];
      updatedChapters.sort(
          (a, b) => (a.chapter.number ?? 0).compareTo(b.chapter.number ?? 0));
      meta = DownloadedMangaMeta(chapters: updatedChapters);
    }

    await metaFile.writeAsString(jsonEncode(meta.toJson()), flush: true);
  }

  Future<void> cancelMangaDownload(String taskId) async {
    final task = activeMangaTasks.firstWhereOrNull((t) => t.taskId == taskId);
    if (task != null) {
      task.status = MangaDownloadStatus.cancelled;
      activeMangaTasks.refresh();
      _saveMangaActiveTasks();

      if (await FlutterForegroundTask.isRunningService) {
        _sendToBackground({
          'type': 'CANCEL_TASK',
          'taskId': taskId,
        });
      }
    }
  }

  Future<void> removeMangaTask(String taskId) async {
    activeMangaTasks.removeWhere((t) => t.taskId == taskId);
    _saveMangaActiveTasks();
  }

  Future<DownloadedMangaMeta?> getMangaMeta(String ext, String title) async {
    final mediaDir = await _getMangaMediaDirPath(title, ext);
    final metaFile = File(p.join(mediaDir, 'metadata.json'));
    if (!await metaFile.exists()) return null;
    final raw =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    return DownloadedMangaMeta.fromJson(raw);
  }

  Future<void> pauseDownload(String taskId) async {
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
      final source = Get.find<SourceController>()
          .installedMangaExtensions
          .firstWhereOrNull((s) => s.name == mangaTask.extensionName);
      if (source != null) {
        _runChapterDownload(task: mangaTask, source: source);
      }
    }

    _saveActiveTasks();
    _saveMangaActiveTasks();
  }

  Future<void> cancelDownload(String taskId) async {
    dl.DownloadIsolatePool.instance.cancelTask(taskId);

    if (await FlutterForegroundTask.isRunningService) {
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
        final source = Get.find<SourceController>()
                .installedExtensions
                .firstWhereOrNull(
                    (s) => s.name == taskInActive.extensionName) ??
            Get.find<SourceController>()
                .installedMangaExtensions
                .firstWhereOrNull((s) => s.name == taskInActive.extensionName);
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

  Future<void> removeTask(String taskId) async {
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
      );
    }

    await metaFile.writeAsString(jsonEncode(meta.toJson()), flush: true);
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

      await metaFile.writeAsString(
        jsonEncode(meta.toJson()),
        flush: true,
      );
    } else {
      final metaFile = File(p.join(mediaDir, 'metadata.json'));
      if (!await metaFile.exists()) {
        await metaFile.writeAsString(
          jsonEncode(const DownloadedMangaMeta(chapters: []).toJson()),
          flush: true,
        );
      }
    }

    await _loadIndex();
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
  }

  Future<void> _loadIndex() async {
    try {
      final root = await _getRootDir();
      final indexFile = File(p.join(root.path, 'metadata.json'));
      if (!await indexFile.exists()) {
        downloadedMedia.clear();
        return;
      }

      final raw =
          jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
      final itemsRaw = raw['items'] as List<dynamic>? ?? [];

      final summaries = itemsRaw
          .map(
              (e) => DownloadedMediaSummary.fromJson(e as Map<String, dynamic>))
          .toList();

      downloadedMedia.value = summaries;
    } catch (e) {
      debugPrint('DownloadController: error loading index: $e');
    }
  }

  Future<void> updateEpisodeProgress(
    String ext,
    String title,
    String epNumber,
    Map<String, String> sortMap,
    int timestampMs,
    int durationMs,
  ) async {
    final mediaDir = await _getMediaDirPath(title, ext, mediaType: 'Anime');
    final metaFile = File(p.join(mediaDir, 'metadata.json'));
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
    );
    await metaFile.writeAsString(jsonEncode(updated.toJson()), flush: true);
    await _loadIndex();
  }

  Future<DownloadedMediaMeta?> getMediaMeta(String ext, String title) async {
    final mediaDir = await _getMediaDirPath(title, ext, mediaType: 'Anime');
    final metaFile = File(p.join(mediaDir, 'metadata.json'));
    if (!await metaFile.exists()) return null;
    final raw =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    return DownloadedMediaMeta.fromJson(raw);
  }

  Future<void> deleteMedia(String ext, String title,
      {String mediaType = 'Anime'}) async {
    final mediaDir = await _getMediaDirPath(title, ext, mediaType: mediaType);
    final dir = Directory(mediaDir);
    if (await dir.exists()) await dir.delete(recursive: true);
    await _removeFromGlobalIndex(ext, title);
    await _loadIndex();
  }

  Future<void> deleteEpisode(String ext, String title, String epNumber,
      Map<String, String> sortMap) async {
    final mediaDir = await _getMediaDirPath(title, ext, mediaType: 'Anime');
    final metaFile = File(p.join(mediaDir, 'metadata.json'));
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
    );
    await metaFile.writeAsString(jsonEncode(meta.toJson()), flush: true);
    await _loadIndex();
  }

  Future<void> deleteChapter(
      String ext, String title, double? chapterNum) async {
    final mediaDir = await _getMediaDirPath(title, ext, mediaType: 'Manga');
    final metaFile = File(p.join(mediaDir, 'metadata.json'));
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
    );

    await metaFile.writeAsString(jsonEncode(meta.toJson()), flush: true);
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
        .where((i) => !(i['extensionName'] == ext && i['folderName'] == title))
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

      for (final sub in subs) {
        if (sub.file == null || sub.file!.isEmpty) continue;

        try {
          final response = await http.get(Uri.parse(sub.file!));
          if (response.statusCode == 200) {
            final fileName = MediaDownloader.sanitizePathSegment(
                '${sub.label ?? "Unknown"}.vtt');
            final filePath = p.join(subsDir.path, fileName);
            await File(filePath).writeAsBytes(response.bodyBytes);
          }
        } catch (e) {
          debugPrint('Error downloading subtitle ${sub.label}: $e');
        }
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
