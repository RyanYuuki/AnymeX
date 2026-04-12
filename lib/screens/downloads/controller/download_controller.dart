import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:collection';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/utils/download_engine.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/database/isar_models/video.dart' as hive;
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';

class DownloadController extends GetxController {
  final RxList<ActiveDownloadTask> activeTasks = <ActiveDownloadTask>[].obs;
  final RxList<DownloadedMediaSummary> downloadedMedia =
      <DownloadedMediaSummary>[].obs;
  final RxBool isInitialized = false.obs;

  final Queue<_ScrapeRequest> _scrapeQueue = Queue();
  final Map<String, String> _scrapeTokens = {};
  bool _isScraping = false;

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
    await _loadIndex();
    await _loadActiveTasks();
    isInitialized.value = true;
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

  Future<List<hive.Video>> fetchServersForEpisode(
      Source source, Episode ep, {String? passedToken}) async {
    final deEpisode = DEpisode(
      episodeNumber: ep.number,
      url: ep.link,
      sortMap: ep.sortMap.isEmpty ? null : ep.sortMap,
    );

    final token =
        passedToken ?? 'dl_scrape_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
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

    await setMediaMeta(sanitizedExt, sanitizedTitle, media);

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

  Future<void> _processScrapeQueue() async {
    if (_isScraping || _scrapeQueue.isEmpty) return;
    _isScraping = true;

    while (_scrapeQueue.isNotEmpty) {
      final request = _scrapeQueue.removeFirst();
      if (request.task.status == DownloadStatus.cancelled ||
          request.task.status == DownloadStatus.paused) {
        continue;
      }
      
      await _runEpisodeDownload(
        task: request.task,
        source: request.source,
        preferredQuality: request.preferredQuality,
      );
    }

    _isScraping = false;
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
        
        final token = 'dl_scrape_${task.taskId}_${DateTime.now().millisecondsSinceEpoch}';
        _scrapeTokens[task.taskId] = token;
        
        final videos = await fetchServersForEpisode(source, task.episode, passedToken: token);
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

      final subDir =
          'AnymeX/Downloads/${task.extensionName}/${task.mediaTitle}';

      DownloadResult result;

      if (linkType == VideoLinkType.hls) {
        final fileName = DownloadEngine.buildFileName(
          episodeNumber: task.episode.number,
          sortMap: task.episode.sortMap,
          url: task.videoUrl,
        );
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
        if (result.success) {
          task.status = DownloadStatus.completed;
          task.progress = 1.0;
          task.filePath = result.filePath;
          activeTasks.refresh();
          await _writeEpisodeMeta(task, fileName);
          await _loadIndex();
          _saveActiveTasks();
        } else {
          task.status = DownloadStatus.failed;
          task.errorMessage = result.error;
          activeTasks.refresh();
          _saveActiveTasks();
        }
      } else {
        final fileName = DownloadEngine.buildFileName(
          episodeNumber: task.episode.number,
          sortMap: task.episode.sortMap,
          url: task.videoUrl,
        );
        result = await DownloadEngine.downloadFile(
          taskId: task.taskId,
          url: task.videoUrl,
          fileName: fileName,
          subDirectory: subDir,
          headers: chosenVideo?.headers ?? task.videoHeaders,
          chunks: Get.find<Settings>().downloadChunks.value,
          onProgress: (prog) {
            task.progress = prog;
            activeTasks.refresh();
          },
          onStatus: (status) {
            if (status == TaskStatus.failed) {
              task.status = DownloadStatus.failed;
              activeTasks.refresh();
            }
          },
        );
        if (result.success) {
          task.status = DownloadStatus.completed;
          task.progress = 1.0;
          task.filePath = result.filePath;
          activeTasks.refresh();
          await _writeEpisodeMeta(task, fileName);
          await _loadIndex();
          _saveActiveTasks();
        } else {
          task.status = DownloadStatus.failed;
          task.errorMessage = result.error;
          activeTasks.refresh();
          _saveActiveTasks();
        }
      }
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = e.toString();
      activeTasks.refresh();
      _saveActiveTasks();
    }
  }

  Future<void> pauseDownload(String taskId) async {
    final task = activeTasks.firstWhereOrNull((t) => t.taskId == taskId);
    if (task == null) return;

    if (task.linkType == VideoLinkType.hls) {
      DownloadEngine.cancel(taskId);
    } else {
      final bdTask = await FileDownloader().taskForId(taskId);
      if (bdTask != null) {
        await FileDownloader().pause(bdTask as dynamic);
      }
    }
    
    
    final token = _scrapeTokens[taskId];
    if (token != null) {
       
       final taskInActive = activeTasks.firstWhereOrNull((t) => t.taskId == taskId);
       if (taskInActive != null) {
          final source = Get.find<SourceController>().installedExtensions.firstWhereOrNull((s) => s.name == taskInActive.extensionName) ??
                         Get.find<SourceController>().installedMangaExtensions.firstWhereOrNull((s) => s.name == taskInActive.extensionName);
          source?.cancelRequest(token);
       }
       _scrapeTokens.remove(taskId);
    }

    task.status = DownloadStatus.paused;
    activeTasks.refresh();
    _saveActiveTasks();
  }

  Future<void> resumeDownload(String taskId) async {
    final task = activeTasks.firstWhereOrNull((t) => t.taskId == taskId);
    if (task == null) return;

    task.status = DownloadStatus.queued;
    activeTasks.refresh();
    
    
    
    if (task.videoUrl.isEmpty) {
       
       
       _runEpisodeDownload(task: task);
    } else {
       _runEpisodeDownload(task: task);
    }
    _saveActiveTasks();
  }

  Future<void> cancelDownload(String taskId) async {
    await FileDownloader().cancelTaskWithId(taskId);
    DownloadEngine.cancel(taskId);
    
    final token = _scrapeTokens[taskId];
    if (token != null) {
       final taskInActive = activeTasks.firstWhereOrNull((t) => t.taskId == taskId);
       if (taskInActive != null) {
          final source = Get.find<SourceController>().installedExtensions.firstWhereOrNull((s) => s.name == taskInActive.extensionName) ??
                         Get.find<SourceController>().installedMangaExtensions.firstWhereOrNull((s) => s.name == taskInActive.extensionName);
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

  Future<String> _getMediaDirPath(String ext, String title) async {
    final root = await _getRootDir();
    final dir = Directory(p.join(root.path, ext, title));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<void> _writeEpisodeMeta(
      ActiveDownloadTask task, String fileName) async {
    final mediaDir =
        await _getMediaDirPath(task.extensionName, task.mediaTitle);
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

  Future<void> setMediaMeta(
      String ext, String title, OfflineMedia media) async {
    final mediaDir = await _getMediaDirPath(ext, title);

    
    await _updateGlobalSummary(
      title: title,
      poster: media.poster ?? media.cover,
      extensionName: ext,
      folderName: title,
    );

    
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

    final updatedMeta = DownloadedMediaMeta(
      episodes: meta.episodes,
      watchedProgress: meta.watchedProgress,
    );
    await metaFile.writeAsString(
      jsonEncode(updatedMeta.toJson()),
      flush: true,
    );

    await _loadIndex();
  }

  Future<void> _updateGlobalSummary({
    required String title,
    String? poster,
    required String extensionName,
    required String folderName,
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
    final mediaDir = await _getMediaDirPath(ext, title);
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
    final mediaDir = await _getMediaDirPath(ext, title);
    final metaFile = File(p.join(mediaDir, 'metadata.json'));
    if (!await metaFile.exists()) return null;
    final raw =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    return DownloadedMediaMeta.fromJson(raw);
  }

  Future<void> deleteMedia(String ext, String title) async {
    final mediaDir = await _getMediaDirPath(ext, title);
    final dir = Directory(mediaDir);
    if (await dir.exists()) await dir.delete(recursive: true);
    await _removeFromGlobalIndex(ext, title);
    await _loadIndex();
  }

  Future<void> deleteEpisode(String ext, String title, String epNumber,
      Map<String, String> sortMap) async {
    final mediaDir = await _getMediaDirPath(ext, title);
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

  Future<void> _removeFromGlobalIndex(String ext, String title) async {
    final root = await _getRootDir();
    final indexFile = File(p.join(root.path, 'metadata.json'));
    if (!await indexFile.exists()) return;

    final raw =
        jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
    final items = (raw['items'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .where((i) => !(i['extension'] == ext && i['title'] == title))
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

  Future<void> manualSelectServerForTask(
      ActiveDownloadTask task, hive.Video selectedVideo) async {
    task.videoUrl = selectedVideo.url ?? selectedVideo.originalUrl ?? '';
    task.videoHeaders = selectedVideo.headers ?? {};
    task.status = DownloadStatus.queued;
    activeTasks.refresh();
    _saveActiveTasks();
    
    
    _runEpisodeDownload(task: task);
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

DownloadController get downloadController => Get.find<DownloadController>();
