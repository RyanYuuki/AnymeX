// import 'package:path/path.dart' as p;

// import 'package:anymex/screens/downloader/model/download_item.dart';
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:background_downloader/background_downloader.dart';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';

// class DownloadManagerController extends GetxController {
//   static DownloadManagerController get instance =>
//       Get.find<DownloadManagerController>();

//   late FileDownloader _downloader;

//   final RxMap<String, DownloadItem> _downloads = <String, DownloadItem>{}.obs;
//   final RxBool _isInitialized = false.obs;
//   final RxString _downloadPath = ''.obs;
//   final RxInt _activeDownloads = 0.obs;
//   final RxInt _completedDownloads = 0.obs;
//   final RxInt _failedDownloads = 0.obs;

//   final Map<String, DownloadTask> _tasks = {};

//   Map<String, DownloadItem> get downloads => _downloads;
//   List<DownloadItem> get downloadsList => _downloads.values.toList()
//     ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
//   bool get isInitialized => _isInitialized.value;
//   String get downloadPath => _downloadPath.value;
//   int get activeDownloads => _activeDownloads.value;
//   int get completedDownloads => _completedDownloads.value;
//   int get failedDownloads => _failedDownloads.value;
//   int get totalDownloads => _downloads.length;

//   List<DownloadItem> get activeDownloadsList =>
//       downloadsList.where((item) => item.isDownloading).toList();

//   List<DownloadItem> get completedDownloadsList =>
//       downloadsList.where((item) => item.isCompleted).toList();

//   List<DownloadItem> get failedDownloadsList =>
//       downloadsList.where((item) => item.isFailed || item.isCanceled).toList();

//   List<DownloadItem> get pausedDownloadsList =>
//       downloadsList.where((item) => item.isPaused).toList();

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeDownloader();
//   }

//   Future<void> _initializeDownloader() async {
//     try {
//       _downloader = FileDownloader();

//       _downloadPath.value = await _getDownloadPath();

//       await _downloader.configure(
//         globalConfig: [
//           (Config.requestTimeout, const Duration(seconds: 100)),
//           (Config.checkAvailableSpace, Config.never),
//           (Config.useCacheDir, Config.never),
//         ],
//         androidConfig: [
//           (Config.useExternalStorage, Config.always),
//           (Config.runInForeground, Config.always),
//         ],
//         iOSConfig: [
//           (Config.localize, {'Cancel': 'Stop'}),
//         ],
//       );

//       _downloader.configureNotificationForGroup(
//         FileDownloader.defaultGroup,
//         running: const TaskNotification('Downloading', 'file: {filename}'),
//         complete:
//             const TaskNotification('Download completed', 'file: {filename}'),
//         error: const TaskNotification('Download failed', 'file: {filename}'),
//         paused: const TaskNotification('Download paused', 'file: {filename}'),
//         progressBar: true,
//       );

//       _downloader.registerCallbacks(
//         taskStatusCallback: _onTaskStatusUpdate,
//         taskProgressCallback: _onTaskProgressUpdate,
//       );

//       await _loadExistingTasks();

//       _isInitialized.value = true;

//       if (kDebugMode) {
//         print('DownloadManager initialized successfully');
//         print('Download path: ${_downloadPath.value}');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Failed to initialize DownloadManager: $e');
//       }
//     }
//   }

//   Future<void> _loadExistingTasks() async {
//     try {
//       final database = _downloader.database;
//       final records = await database.allRecords();

//       for (final record in records) {
//         final task = record.task;
//         final status = record.status;

//         final downloadTask = DownloadTask(
//           taskId: task.taskId,
//           url: task.url,
//           filename: task.filename,
//           directory: task.directory,
//           headers: task.headers,
//           updates: task.updates,
//           allowPause: task.allowPause,
//           metaData: task.metaData,
//         );

//         _tasks[task.taskId] = downloadTask;

//         final downloadItem = DownloadItem(
//           id: task.taskId,
//           url: task.url,
//           filename: task.filename,
//           displayName: _getDisplayName(task.filename),
//           status: status,
//           progress: record.progress,
//           totalBytes: record.expectedFileSize,
//           downloadedBytes: (record.expectedFileSize * record.progress).round(),
//           createdAt: DateTime.now(),
//           localPath: status == TaskStatus.complete
//               ? await _getCompletedFilePath(task)
//               : null,
//           task: downloadTask,
//         );

//         _downloads[task.taskId] = downloadItem;
//       }
//       _updateCounters();
//     } catch (e) {
//       if (kDebugMode) {
//         print('Failed to load existing tasks: $e');
//       }
//     }
//   }

//   Future<String?> _getCompletedFilePath(Task task) async {
//     try {
//       return await task.filePath();
//     } catch (e) {
//       return null;
//     }
//   }

//   void _onTaskStatusUpdate(TaskStatusUpdate update) async {
//     final taskId = update.task.taskId;
//     final existingItem = _downloads[taskId];

//     if (existingItem != null) {
//       _downloads[taskId] = existingItem.copyWith(
//         status: update.status,
//         localPath: update.status == TaskStatus.complete
//             ? (await _getCompletedFilePath(update.task))
//             : existingItem.localPath,
//         error: update.exception?.toString(),
//       );
//       _updateCounters();
//     }
//   }

//   void _onTaskProgressUpdate(TaskProgressUpdate update) {
//     final taskId = update.task.taskId;
//     final existingItem = _downloads[taskId];

//     if (existingItem != null) {
//       _downloads[taskId] = existingItem.copyWith(
//         progress: update.progress,
//         totalBytes: update.expectedFileSize <= 1
//             ? existingItem.totalBytes
//             : update.expectedFileSize,
//         downloadedBytes: (update.expectedFileSize * update.progress).round(),
//       );
//     }

//     debugPrint('Progress update for task $taskId: ${update.progress}');
//   }

//   String _sanitizePathComponent(String input) {
//     final invalidChars = RegExp(r'[\\/:*?"<>|]');
//     return input.replaceAll(invalidChars, '_');
//   }

//   Future<bool> addDownload({
//     required String url,
//     String? filename,
//     String? displayName,
//     Map<String, String>? headers,
//     Map<String, String>? metaData,
//   }) async {
//     try {
//       if (!_isInitialized.value) {
//         throw Exception('DownloadManager not initialized');
//       }

//       final rawFilename = filename ?? _generateFilenameFromUrl(url);
//       final finalDisplayName = displayName ?? _getDisplayName(rawFilename);

//       final sanitizedPath = p.normalize(
//         rawFilename
//             .split(RegExp(r'[\\/]+'))
//             .map(_sanitizePathComponent)
//             .join(p.separator),
//       );
//       final actualFilename = p.basename(sanitizedPath);
//       final subDir = p.dirname(sanitizedPath);
//       final fullDirectory = p.join(_downloadPath.value, subDir);

//       debugPrint('Downloading $url to $fullDirectory/$actualFilename');

//       final directory = Directory(fullDirectory);
//       if (!await directory.exists()) {
//         await directory.create(recursive: true);
//       }

//       final task = DownloadTask(
//         taskId: DateTime.now().millisecondsSinceEpoch.toString(),
//         url: url,
//         filename: actualFilename,
//         directory: fullDirectory,
//         headers: headers ?? {},
//         updates: Updates.statusAndProgress,
//         allowPause: true,
//         metaData: metaData != null
//             ? metaData['poster'] ?? ''
//             : '{"displayName": "$finalDisplayName"}',
//       );

//       _tasks[task.taskId] = task;

//       final downloadItem = DownloadItem(
//           id: task.taskId,
//           url: url,
//           filename: actualFilename,
//           displayName: finalDisplayName,
//           status: TaskStatus.enqueued,
//           createdAt: DateTime.now(),
//           task: task,
//           metaData: metaData);

//       _downloads[task.taskId] = downloadItem;

//       final success = await _downloader.enqueue(task);

//       if (success) {
//         _updateCounters();
//         if (kDebugMode) {
//           print(
//               'Download added: $finalDisplayName → $fullDirectory/$actualFilename');
//         }
//         return true;
//       } else {
//         _downloads.remove(task.taskId);
//         _tasks.remove(task.taskId);
//         throw Exception('Failed to enqueue download task');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Failed to add download: $e');
//       }
//       return false;
//     }
//   }

//   Future<bool> pauseDownload(String taskId) async {
//     try {
//       final task = _tasks[taskId];
//       if (task == null) {
//         if (kDebugMode) {
//           print('Task not found for pausing: $taskId');
//         }
//         return false;
//       }

//       final success = await _downloader.pause(task);
//       if (success && kDebugMode) {
//         print('Download paused: $taskId');
//       }
//       return success;
//     } catch (e) {
//       if (kDebugMode) {
//         print('Failed to pause download: $e');
//       }
//       return false;
//     }
//   }

//   Future<bool> resumeDownload(String taskId) async {
//     try {
//       final task = _tasks[taskId];
//       if (task == null) {
//         if (kDebugMode) {
//           print('Task not found for resuming: $taskId');
//         }
//         return false;
//       }

//       final success = await _downloader.resume(task);
//       if (success && kDebugMode) {
//         print('Download resumed: $taskId');
//       }
//       return success;
//     } catch (e) {
//       if (kDebugMode) {
//         print('Failed to resume download: $e');
//       }
//       return false;
//     }
//   }

//   Future<bool> cancelDownload(String taskId) async {
//     try {
//       final task = _tasks[taskId];
//       if (task == null) {
//         if (kDebugMode) {
//           print('Task not found for canceling: $taskId');
//         }
//         return false;
//       }

//       final success = await _downloader.cancel(task);
//       if (success && kDebugMode) {
//         print('Download canceled: $taskId');
//       }
//       return success;
//     } catch (e) {
//       if (kDebugMode) {
//         print('Failed to cancel download: $e');
//       }
//       return false;
//     }
//   }

//   Future<bool> removeDownload(String taskId, {bool deleteFile = false}) async {
//     try {
//       final item = _downloads[taskId];
//       if (item != null && (item.isDownloading || item.isPaused)) {
//         await cancelDownload(taskId);
//       }

//       if (deleteFile && item?.localPath != null) {
//         final file = File(item!.localPath!);
//         if (await file.exists()) {
//           await file.delete();
//         }
//       }

//       _downloads.remove(taskId);
//       _tasks.remove(taskId);
//       _updateCounters();

//       if (kDebugMode) {
//         print('Download removed: $taskId');
//       }
//       return true;
//     } catch (e) {
//       if (kDebugMode) {
//         print('Failed to remove download: $e');
//       }
//       return false;
//     }
//   }

//   Future<bool> retryDownload(String taskId) async {
//     try {
//       final item = _downloads[taskId];
//       if (item == null) return false;

//       await removeDownload(taskId);

//       return await addDownload(
//         url: item.url,
//         filename: item.filename,
//         displayName: item.displayName,
//       );
//     } catch (e) {
//       if (kDebugMode) {
//         print('Failed to retry download: $e');
//       }
//       return false;
//     }
//   }

//   Future<void> pauseAllDownloads() async {
//     final activeDownloads =
//         downloadsList.where((item) => item.canPause).toList();
//     for (final item in activeDownloads) {
//       await pauseDownload(item.id);
//     }
//   }

//   Future<void> resumeAllDownloads() async {
//     final pausedDownloads =
//         downloadsList.where((item) => item.canResume).toList();
//     for (final item in pausedDownloads) {
//       await resumeDownload(item.id);
//     }
//   }

//   Future<void> cancelAllDownloads() async {
//     final activeDownloads = downloadsList
//         .where((item) => item.isDownloading || item.isPaused)
//         .toList();
//     for (final item in activeDownloads) {
//       await cancelDownload(item.id);
//     }
//   }

//   Future<void> clearCompletedDownloads({bool deleteFiles = false}) async {
//     final completed = completedDownloadsList;
//     for (final item in completed) {
//       await removeDownload(item.id, deleteFile: deleteFiles);
//     }
//   }

//   Future<void> clearFailedDownloads() async {
//     final failed = failedDownloadsList;
//     for (final item in failed) {
//       await removeDownload(item.id);
//     }
//   }

//   DownloadItem? getDownload(String taskId) {
//     return _downloads[taskId];
//   }

//   bool hasDownload(String taskId) {
//     return _downloads.containsKey(taskId);
//   }

//   DownloadItem? getDownloadByUrl(String url) {
//     return downloadsList.firstWhereOrNull((item) => item.url == url);
//   }

//   void _updateCounters() {
//     _activeDownloads.value =
//         downloadsList.where((item) => item.isDownloading).length;
//     _completedDownloads.value =
//         downloadsList.where((item) => item.isCompleted).length;
//     _failedDownloads.value =
//         downloadsList.where((item) => item.isFailed || item.isCanceled).length;
//   }

//   String _generateFilenameFromUrl(String url) {
//     final uri = Uri.parse(url);
//     final segments = uri.pathSegments;
//     if (segments.isNotEmpty && segments.last.contains('.')) {
//       return segments.last;
//     }
//     return 'download_${DateTime.now().millisecondsSinceEpoch}';
//   }

//   String _getDisplayName(String filename) {
//     final lastDotIndex = filename.lastIndexOf('.');
//     if (lastDotIndex > 0) {
//       return filename.substring(0, lastDotIndex);
//     }
//     return filename;
//   }

//   Future<String> _getDownloadPath() async {
//     try {
//       if (Platform.isAndroid) {
//         final directory = await getExternalStorageDirectory();
//         return '${directory!.path}/Downloads';
//       } else if (Platform.isIOS) {
//         final directory = await getApplicationDocumentsDirectory();
//         return '${directory.path}/Downloads';
//       } else {
//         final directory = await getDownloadsDirectory();
//         return directory?.path ??
//             (await getApplicationDocumentsDirectory()).path;
//       }
//     } catch (e) {
//       debugPrint('Error getting download path: $e');
//       final directory = await getApplicationDocumentsDirectory();
//       return '${directory.path}/Downloads';
//     }
//   }

//   void setDownloadPath(String path) => _downloadPath.value = path;

//   @override
//   void onClose() {
//     _tasks.clear();
//     super.onClose();
//   }
// }

// extension DownloadManagerBinding on GetxController {
//   static void initializeDownloadManager() {
//     Get.put<DownloadManagerController>(DownloadManagerController(),
//         permanent: true);
//   }
// }
