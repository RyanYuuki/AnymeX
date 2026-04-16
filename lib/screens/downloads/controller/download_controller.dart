import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:collection';
import 'dart:typed_data';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/track.dart' as hive;
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/utils/download_engine.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/database/isar_models/video.dart' as hive;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:jxl_coder/jxl_coder.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

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

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    final concurrency = DownloadKeys.concurrentDownloads.get<int>(3);
    await FileDownloader().configure(
      globalConfig: [
        (Config.requestTimeout, const Duration(seconds: 90)),
        (Config.holdingQueue, (concurrency, null, null)),
      ],
    );

    FileDownloader().configureNotification(
      running: const TaskNotification('AnymeX', 'Downloading {filename}'),
      complete:
          const TaskNotification('AnymeX', 'Finished downloading {filename}'),
      progressBar: true,
      tapOpensFile: true,
    );

    FileDownloader().updates.listen((update) {
      if (update is TaskStatusUpdate) {
        _handleStatusUpdate(update);
      } else if (update is TaskProgressUpdate) {
        _handleProgressUpdate(update);
      }
    });

    await _loadIndex();
    await _loadActiveTasks();

    ever(Get.find<Settings>().concurrentDownloads, (val) {
      FileDownloader().configure(
        globalConfig: [
          (Config.holdingQueue, (val, null, null)),
        ],
      );
      _processScrapeQueue();
      _processMangaScrapeQueue();
    });

    isInitialized.value = true;
  }

  void _handleStatusUpdate(TaskStatusUpdate update) async {
    final task =
        activeTasks.firstWhereOrNull((t) => t.taskId == update.task.taskId);
    if (task == null) return;

    switch (update.status) {
      case TaskStatus.enqueued:
        task.status = DownloadStatus.queued;
        break;
      case TaskStatus.running:
        task.status = DownloadStatus.downloading;
        if (!_activeFileTasks.contains(update.task.taskId)) {
          _activeFileTasks.add(update.task.taskId);
        }
        break;
      case TaskStatus.complete:
        task.status = DownloadStatus.completed;
        task.progress = 1.0;
        if (_activeFileTasks.contains(update.task.taskId)) {
          _activeFileTasks.remove(update.task.taskId);
          _activeTaskCount--;
          _processScrapeQueue();
          _processMangaScrapeQueue();
        }
        _onTaskFinished(task, update.task.filename);
        break;
      case TaskStatus.failed:
      case TaskStatus.canceled:
        if (_activeFileTasks.contains(update.task.taskId)) {
          _activeFileTasks.remove(update.task.taskId);
          _activeTaskCount--;
          _processScrapeQueue();
          _processMangaScrapeQueue();
        }
        task.status = update.status == TaskStatus.failed
            ? DownloadStatus.failed
            : DownloadStatus.cancelled;
        if (update.status == TaskStatus.failed)
          task.errorMessage = 'Download failed';
        break;
      case TaskStatus.paused:
        task.status = DownloadStatus.paused;
        break;
      default:
        break;
    }
    activeTasks.refresh();
  }

  void _handleProgressUpdate(TaskProgressUpdate update) {
    final task =
        activeTasks.firstWhereOrNull((t) => t.taskId == update.task.taskId);
    if (task != null) {
      task.progress = update.progress;
      activeTasks.refresh();
    }
  }

  Future<void> _onTaskFinished(ActiveDownloadTask task, String fileName) async {
    final filePath =
        await (await FileDownloader().taskForId(task.taskId))?.filePath() ?? '';
    task.filePath = filePath;
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

      for (final task in tasks) {
        if (task.status == DownloadStatus.downloading ||
            task.status == DownloadStatus.queued) {
          final bdTask = await FileDownloader().taskForId(task.taskId);
          if (bdTask == null) {
            _runEpisodeDownload(task: task);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading active tasks: $e');
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
    final sanitizedTitle = DownloadEngine.sanitizePathSegment(mediaTitle);
    final sanitizedExt =
        DownloadEngine.sanitizePathSegment(source.name ?? 'unknown');

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
    final taskId = DownloadEngine.buildTaskId(
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
        final bestLabel = DownloadEngine.pickBestMatchingVideo(
            qualityLabels, preferredQuality ?? '720p');

        if (bestLabel == null) {
          task.status = DownloadStatus.failed;
          task.errorMessage =
              'Could not find a server with matching quality and sub/dub preference';
          activeTasks.refresh();
          return;
        }

        chosenVideo = videos.firstWhereOrNull((v) => v.quality == bestLabel) ??
            videos.first;

        if (chosenVideo.subtitles != null && chosenVideo.subtitles!.isNotEmpty) {
          await _downloadSubtitles(task, chosenVideo.subtitles!);
        }

        task.videoUrl = chosenVideo.url ?? chosenVideo.originalUrl ?? '';
        task.videoHeaders ??= {};
        task.videoHeaders!.addAll(chosenVideo.headers ?? {});
      }
      final linkType = detectLinkType(task.videoUrl);

      if (task.videoUrl.isEmpty) {
        task.status = DownloadStatus.failed;
        task.errorMessage = 'Empty video URL returned by extension';
        activeTasks.refresh();
        return;
      }

      final subDir = 'AnymeX/Downloads/Anime/${task.mediaTitle}';

      DownloadResult result;

      if (linkType == VideoLinkType.hls) {
        final fileName = DownloadEngine.buildFileName(
          episodeNumber: task.episode.number,
          sortMap: task.episode.sortMap,
          url: task.videoUrl,
        );
        _activeFileTasks.add(task.taskId);

        result = await DownloadEngine.downloadHls(
          taskId: task.taskId,
          m3u8Url: task.videoUrl,
          fileName: fileName,
          subDirectory: subDir,
          headers: chosenVideo?.headers ?? task.videoHeaders,
          preferredQuality: preferredQuality,
          parallelSegments: Get.find<Settings>().hlsParallelSegments.value,
          onProgress: (prog) {
            task.progress = prog;
            activeTasks.refresh();
          },
        );

        _activeFileTasks.remove(task.taskId);
        _activeTaskCount--;

        if (result.success) {
          task.status = DownloadStatus.completed;
          task.progress = 1.0;
          task.filePath = result.filePath;
          await _writeEpisodeMeta(task, fileName);
          await _loadIndex();
        } else {
          task.status = DownloadStatus.failed;
          task.errorMessage = result.error ?? 'HLS download failed';
        }
        activeTasks.refresh();
        _saveActiveTasks();
        _processScrapeQueue();
        _processMangaScrapeQueue();
      } else {
        final fileName = DownloadEngine.buildFileName(
          episodeNumber: task.episode.number,
          sortMap: task.episode.sortMap,
          url: task.videoUrl,
        );
        final standardTask = DownloadTask(
          taskId: task.taskId,
          url: task.videoUrl,
          filename: fileName,
          directory: subDir,
          baseDirectory: BaseDirectory.applicationDocuments,
          updates: Updates.statusAndProgress,
          headers: chosenVideo?.headers ?? task.videoHeaders,
          allowPause: true,
        );

        await FileDownloader().enqueue(standardTask);
      }
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = e.toString();
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
    final sanitizedTitle = DownloadEngine.sanitizePathSegment(mediaTitle);
    final sanitizedExt =
        DownloadEngine.sanitizePathSegment(source.name ?? 'unknown');

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

    final maxConcurrent = Get.find<Settings>().concurrentDownloads.value;
    while (_mangaScrapeQueue.isNotEmpty && _activeTaskCount < maxConcurrent) {
      final request = _mangaScrapeQueue.removeFirst();
      if (request.task.status == MangaDownloadStatus.cancelled) continue;

      _activeTaskCount++;
      _runChapterDownload(task: request.task, source: request.source)
          .whenComplete(() {
        _activeTaskCount--;
        _processMangaScrapeQueue();
        _processScrapeQueue();
      });
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

      final chapterNum = task.chapter.number.toString();
      final sanitizedChNum = DownloadEngine.sanitizePathSegment(chapterNum);

      final mediaDir =
          await _getMangaMediaDirPath(task.mediaTitle, task.extensionName);
      final chapterDir = Directory(p.join(
        mediaDir,
        'Ch_$sanitizedChNum',
      ));
      await chapterDir.create(recursive: true);

      int downloaded = 0;
      final concurrentPages = 3;
      final List<Future<void>> downloadFutures = [];
      final settings = Get.find<Settings>();

      for (int i = 0; i < pages.length; i++) {
        if (task.status == MangaDownloadStatus.cancelled) break;
        if (task.status == MangaDownloadStatus.paused) {
          await Future.doWhile(() async {
            await Future.delayed(const Duration(milliseconds: 500));
            return task.status == MangaDownloadStatus.paused;
          });
          if (task.status == MangaDownloadStatus.cancelled) break;
        }

        if (downloadFutures.length >= concurrentPages) {
          await Future.any(downloadFutures);
        }

        final pIndex = i;
        final page = pages[pIndex];

        final future = () async {
          try {
            final response = await http.get(
              Uri.parse(page.url),
              headers: page.headers ?? {},
            );

            if (response.statusCode == 200) {
              var bytes = response.bodyBytes;
              var ext = _imageExtension(page.url);

              if (settings.enableJxlCompression.value) {
                try {
                  final jxlBytes = await compute(_backgroundJxlCompress, {
                    'bytes': bytes,
                    'isJpg': ext == '.jpg' || ext == '.jpeg',
                  });

                  if (jxlBytes != null) {
                    bytes = jxlBytes;
                    ext = '.jxl';
                  }
                } catch (e) {
                  debugPrint('JXL Encoding error: $e');
                }
              }

              final fileName =
                  'page_${(pIndex + 1).toString().padLeft(3, '0')}$ext';
              final filePath = p.join(chapterDir.path, fileName);
              await File(filePath).writeAsBytes(bytes);
            }
          } catch (e) {
            debugPrint('Error downloading manga page: $e');
          } finally {
            downloaded++;
            task.progress = downloaded / pages.length;
            activeMangaTasks.refresh();
          }
        }();

        downloadFutures.add(future);
        future.whenComplete(() => downloadFutures.remove(future));
      }

      await Future.wait(downloadFutures);

      task.status = MangaDownloadStatus.completed;
      task.progress = 1.0;
      activeMangaTasks.refresh();

      await _writeChapterMeta(task, chapterDir.path, pages.length);
      await _loadIndex();
      _saveMangaActiveTasks();
    } catch (e) {
      task.status = MangaDownloadStatus.failed;
      task.errorMessage = e.toString();
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
      if (task.linkType == VideoLinkType.hls) {
        DownloadEngine.pause(taskId);
      } else {
        final bdTask = await FileDownloader().taskForId(taskId);
        if (bdTask != null) {
          await FileDownloader().pause(bdTask as dynamic);
        }
      }
      task.status = DownloadStatus.paused;
      activeTasks.refresh();
    } else if (mangaTask != null) {
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
      if (task.linkType == VideoLinkType.hls) {
        DownloadEngine.resume(taskId);
      } else {
        final bdTask = await FileDownloader().taskForId(taskId);
        if (bdTask != null) {
          await FileDownloader().resume(bdTask as dynamic);
        }
      }
      task.status = DownloadStatus.downloading;
      activeTasks.refresh();
    } else if (mangaTask != null) {
      mangaTask.status = MangaDownloadStatus.downloading;
      activeMangaTasks.refresh();
    }

    _saveActiveTasks();
    _saveMangaActiveTasks();
  }

  Future<void> cancelDownload(String taskId) async {
    await FileDownloader().cancelTaskWithId(taskId);
    DownloadEngine.cancel(taskId);

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

    if (selectedVideo.subtitles != null && selectedVideo.subtitles!.isNotEmpty) {
      await _downloadSubtitles(task, selectedVideo.subtitles!);
    }

    activeTasks.refresh();
    _saveActiveTasks();

    _runEpisodeDownload(task: task);
  }

  Future<void> _downloadSubtitles(
      ActiveDownloadTask task, List<hive.Track> subs) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final subsDir = Directory(p.join(
        docs.path,
        'AnymeX',
        'Downloads',
        'Anime',
        task.mediaTitle,
        'Episode_${task.episode.number}_subs',
      ));
      if (!await subsDir.exists()) await subsDir.create(recursive: true);

      for (final sub in subs) {
        if (sub.file == null || sub.file!.isEmpty) continue;

        try {
          final response = await http.get(Uri.parse(sub.file!));
          if (response.statusCode == 200) {
            final fileName = DownloadEngine.sanitizePathSegment(
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

  static Future<Uint8List?> _backgroundJxlCompress(
      Map<String, dynamic> params) async {
    final bytes = params['bytes'] as Uint8List;
    final isJpg = params['isJpg'] as bool;

    if (isJpg) {
      return await JxlCoder.jpegToJxl(bytes);
    } else {
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final jpegBytes =
            Uint8List.fromList(img.encodeJpg(decoded, quality: 100));
        return await JxlCoder.jpegToJxl(jpegBytes);
      }
    }
    return null;
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
