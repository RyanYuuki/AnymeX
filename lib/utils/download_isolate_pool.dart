import 'dart:collection';
import 'dart:isolate';
import 'dart:async';
import 'dart:io';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:pointycastle/export.dart';

// GRABBED EVERYTHING FROM MANGAYOMI AND MODIFIED FOR ANYMEX, CREDIT TO MANGAYOMI TEAM FOR THE BASE IMPLEMENTATION

class PageUrl {
  final String url;
  final Map<String, String>? headers;
  final String? fileName;

  PageUrl({required this.url, this.headers, this.fileName});
}

class TsInfo {
  final String url;
  final String name;

  TsInfo({required this.url, required this.name});
}

class DownloadProgress {
  final int completed;
  final int total;
  final ItemType itemType;
  final PageUrl? pageUrl;
  final TsInfo? segment;
  final bool isCompleted;

  DownloadProgress(this.completed, this.total, this.itemType,
      {this.pageUrl, this.segment, this.isCompleted = false});
}

class DownloadComplete {}

final downloadTaskCancellation = <String, bool>{};

class DownloadIsolatePool {
  static DownloadIsolatePool? _instance;
  final List<_PoolWorker> _workers = [];
  final Queue<_DownloadTask> _taskQueue = Queue();
  final Set<int> _availableWorkers = {};
  final int poolSize;
  bool _initialized = false;

  DownloadIsolatePool._({this.poolSize = 3});

  static DownloadIsolatePool get instance {
    _instance ??= DownloadIsolatePool._();
    return _instance!;
  }

  static void configure({int poolSize = 3}) {
    if (_instance != null && _instance!._initialized) {
      return;
    }
    _instance = DownloadIsolatePool._(poolSize: poolSize);
  }

  Future<void> initialize() async {
    if (_initialized) return;

    for (int i = 0; i < poolSize; i++) {
      final worker = await _PoolWorker.create(i);
      _workers.add(worker);
      _availableWorkers.add(i);
    }

    _initialized = true;
  }

  Future<void> submitFileDownload({
    required String taskId,
    required List<PageUrl> pageUrls,
    required int concurrentDownloads,
    required ItemType itemType,
    required void Function(DownloadProgress) onProgress,
    required void Function() onComplete,
    required void Function(Exception) onError,
  }) async {
    if (!_initialized) await initialize();

    downloadTaskCancellation[taskId] = false;

    final receivePort = ReceivePort();
    final task = _DownloadTask(
      taskId: taskId,
      type: _TaskType.fileDownload,
      params: FileDownloadParams(
        pageUrls: pageUrls,
        concurrentDownloads: concurrentDownloads,
        itemType: itemType,
      ),
      sendPort: receivePort.sendPort,
    );

    receivePort.listen((message) {
      if (downloadTaskCancellation[taskId] == true) {
        receivePort.close();
        return;
      }

      if (message is DownloadProgress) {
        onProgress(message);
      } else if (message is DownloadComplete) {
        downloadTaskCancellation.remove(taskId);
        receivePort.close();
        onComplete();
      } else if (message is Exception) {
        downloadTaskCancellation.remove(taskId);
        receivePort.close();
        onError(message);
      }
    });

    _enqueueTask(task);
  }

  Future<void> submitM3u8Download({
    required String taskId,
    required List<TsInfo> segments,
    required String tempDir,
    required Uint8List? key,
    required Uint8List? iv,
    required int? mediaSequence,
    required int concurrentDownloads,
    required Map<String, String>? headers,
    required ItemType itemType,
    required void Function(DownloadProgress) onProgress,
    required void Function() onComplete,
    required void Function(Exception) onError,
  }) async {
    if (!_initialized) await initialize();

    downloadTaskCancellation[taskId] = false;

    final receivePort = ReceivePort();
    final task = _DownloadTask(
      taskId: taskId,
      type: _TaskType.m3u8Download,
      params: M3u8DownloadParams(
        segments: segments,
        tempDir: tempDir,
        key: key,
        iv: iv,
        mediaSequence: mediaSequence,
        concurrentDownloads: concurrentDownloads,
        headers: headers,
        itemType: itemType,
      ),
      sendPort: receivePort.sendPort,
    );

    receivePort.listen((message) {
      if (downloadTaskCancellation[taskId] == true) {
        receivePort.close();
        return;
      }

      if (message is DownloadProgress) {
        onProgress(message);
      } else if (message is DownloadComplete) {
        downloadTaskCancellation.remove(taskId);
        receivePort.close();
        onComplete();
      } else if (message is Exception) {
        downloadTaskCancellation.remove(taskId);
        receivePort.close();
        onError(message);
      }
    });

    _enqueueTask(task);
  }

  void cancelTask(String taskId) {
    downloadTaskCancellation[taskId] = true;
  }

  void _enqueueTask(_DownloadTask task) {
    _taskQueue.add(task);
    _processQueue();
  }

  void _processQueue() {
    while (_taskQueue.isNotEmpty && _availableWorkers.isNotEmpty) {
      final task = _taskQueue.removeFirst();
      final workerIndex = _availableWorkers.first;
      _availableWorkers.remove(workerIndex);
      final worker = _workers[workerIndex];

      worker.executeTask(task).then((_) {
        _availableWorkers.add(workerIndex);
        _processQueue();
      });
    }
  }

  int get pendingTasks => _taskQueue.length;

  int get activeWorkers => poolSize - _availableWorkers.length;

  void dispose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    _workers.clear();
    _taskQueue.clear();
    _availableWorkers.clear();
    downloadTaskCancellation.clear();
    _initialized = false;
  }
}

enum _TaskType { fileDownload, m3u8Download }

class _DownloadTask {
  final String taskId;
  final _TaskType type;
  final dynamic params;
  final SendPort sendPort;

  _DownloadTask({
    required this.taskId,
    required this.type,
    required this.params,
    required this.sendPort,
  });
}

class FileDownloadParams {
  final List<PageUrl> pageUrls;
  final int concurrentDownloads;
  final ItemType itemType;

  FileDownloadParams({
    required this.pageUrls,
    required this.concurrentDownloads,
    required this.itemType,
  });
}

class M3u8DownloadParams {
  final List<TsInfo> segments;
  final String tempDir;
  final Uint8List? key;
  final Uint8List? iv;
  final int? mediaSequence;
  final int concurrentDownloads;
  final Map<String, String>? headers;
  final ItemType itemType;

  M3u8DownloadParams({
    required this.segments,
    required this.tempDir,
    required this.key,
    required this.iv,
    required this.mediaSequence,
    required this.concurrentDownloads,
    required this.headers,
    required this.itemType,
  });
}

class _PoolWorker {
  final int id;
  late Isolate _isolate;
  late SendPort _sendPort;
  late ReceivePort _receivePort;
  final Completer<void> _ready = Completer();

  _PoolWorker._(this.id);

  static Future<_PoolWorker> create(int id) async {
    final worker = _PoolWorker._(id);
    await worker._spawn();
    return worker;
  }

  Future<void> _spawn() async {
    _receivePort = ReceivePort();

    _isolate = await Isolate.spawn(
      _workerEntryPoint,
      _WorkerInit(id, _receivePort.sendPort),
    );

    final completer = Completer<SendPort>();
    _receivePort.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
      }
    });

    _sendPort = await completer.future;
    _ready.complete();
  }

  Future<void> executeTask(_DownloadTask task) async {
    await _ready.future;

    final completer = Completer<void>();

    final taskPort = ReceivePort();

    taskPort.listen((message) {
      task.sendPort.send(message);

      if (message is DownloadComplete || message is Exception) {
        taskPort.close();
        completer.complete();
      }
    });

    _sendPort.send(
      _WorkerTask(
        taskId: task.taskId,
        type: task.type,
        params: task.params,
        replyPort: taskPort.sendPort,
      ),
    );

    return completer.future;
  }

  void dispose() {
    _isolate.kill();
    _receivePort.close();
  }
}

class _WorkerInit {
  final int workerId;
  final SendPort mainPort;
  _WorkerInit(this.workerId, this.mainPort);
}

class _WorkerTask {
  final String taskId;
  final _TaskType type;
  final dynamic params;
  final SendPort replyPort;

  _WorkerTask({
    required this.taskId,
    required this.type,
    required this.params,
    required this.replyPort,
  });
}

void _workerEntryPoint(_WorkerInit init) async {
  final httpClient = http.Client();

  final receivePort = ReceivePort();

  init.mainPort.send(receivePort.sendPort);

  await for (final message in receivePort) {
    if (message is _WorkerTask) {
      try {
        if (message.type == _TaskType.fileDownload) {
          await _processFileDownload(
            message.params as FileDownloadParams,
            message.replyPort,
            httpClient,
          );
        } else if (message.type == _TaskType.m3u8Download) {
          await _processM3u8Download(
            message.params as M3u8DownloadParams,
            message.replyPort,
            httpClient,
          );
        }
      } catch (e) {
        message.replyPort.send(DownloadPoolException('Task failed', e));
      }
    }
  }
}

Future<void> _processFileDownload(
  FileDownloadParams params,
  SendPort replyPort,
  http.Client client,
) async {
  int completed = 0;
  final total = params.pageUrls.length;
  final queue = Queue<PageUrl>.from(params.pageUrls);
  final List<Future<void>> activeTasks = [];

  try {
    while (queue.isNotEmpty || activeTasks.isNotEmpty) {
      while (
          queue.isNotEmpty && activeTasks.length < params.concurrentDownloads) {
        final pageUrl = queue.removeFirst();
        final task = _downloadFile(pageUrl, client, params.itemType, replyPort)
            .then((_) {
          if (params.itemType != ItemType.anime) {
            completed++;
            replyPort.send(
              DownloadProgress(
                completed,
                total,
                params.itemType,
                pageUrl: pageUrl,
              ),
            );
          }
        }).catchError((error) {
          replyPort.send(
            DownloadPoolException(
              'Error downloading ${pageUrl.fileName}',
              error,
            ),
          );
          throw error;
        });

        activeTasks.add(task);
      }

      if (activeTasks.isNotEmpty) {
        await Future.wait(activeTasks.toList(), eagerError: true);
        activeTasks.clear();
      }
    }

    replyPort.send(DownloadComplete());
  } catch (e) {
    replyPort.send(DownloadPoolException('Download failed', e));
  }
}

Future<void> _downloadFile(
  PageUrl pageUrl,
  http.Client client,
  ItemType itemType,
  SendPort replyPort,
) async {
  try {
    if (itemType != ItemType.anime) {
      final response = await _withRetry(
        (_) => client.get(Uri.parse(pageUrl.url), headers: pageUrl.headers),
        3,
      );
      if (response.statusCode != 200) {
        throw DownloadPoolException(
          'Failed to download file: ${pageUrl.fileName!}',
        );
      }

      final file = File(pageUrl.fileName!);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes);
    } else {
      await _withRetry((_) async {
        var request = http.Request('GET', Uri.parse(pageUrl.url));
        request.headers.addAll(pageUrl.headers ?? {});
        http.StreamedResponse response = await client.send(request);
        if (response.statusCode != 200) {
          throw DownloadPoolException(
            'Failed to download file: ${pageUrl.fileName!}',
          );
        }
        int total = response.contentLength ?? 0;
        int received = 0;

        final file = File(pageUrl.fileName!);
        await file.parent.create(recursive: true);
        final sink = file.openWrite();
        try {
          await for (var value in response.stream) {
            sink.add(value);
            received += value.length;
            try {
              replyPort.send(
                DownloadProgress(
                  received,
                  total,
                  itemType,
                  pageUrl: pageUrl,
                ),
              );
            } catch (_) {}
          }
        } finally {
          await sink.flush();
          await sink.close();
        }
      }, 3);
    }
  } catch (e) {
    throw DownloadPoolException(
      'Failed to process file: ${pageUrl.fileName!}',
      e,
    );
  }
}

Future<void> _processM3u8Download(
  M3u8DownloadParams params,
  SendPort replyPort,
  http.Client client,
) async {
  int completed = 0;
  final total = params.segments.length;
  final Queue<TsInfo> queue = Queue<TsInfo>.from(params.segments);
  final List<TsInfo> failedSegments = [];
  int maxPasses = 5;

  try {
    for (int pass = 1; pass <= maxPasses; pass++) {
      if (queue.isEmpty && failedSegments.isEmpty) break;

      if (pass > 1) {
        if (kDebugMode) {
          print('[DownloadIsolate] Pass ${pass - 1} finished with ${failedSegments.length} failed segments. Cooling down 2s before Pass $pass...');
        }
        await Future.delayed(const Duration(seconds: 2));
        queue.addAll(failedSegments);
        failedSegments.clear();
      }

      final List<Future<void>> activeTasks = [];

      while (queue.isNotEmpty || activeTasks.isNotEmpty) {
        while (queue.isNotEmpty && activeTasks.length < params.concurrentDownloads) {
          final segment = queue.removeFirst();
          final task = _downloadSegment(segment, params, client).then((_) {
            completed++;
            replyPort.send(
              DownloadProgress(
                completed,
                total,
                params.itemType,
                segment: segment,
              ),
            );
          }).catchError((error) {
            if (kDebugMode) {
              print('[DownloadIsolate] Segment ${segment.name} deferred to retry queue (Pass $pass): $error');
            }
            failedSegments.add(segment);
          });

          activeTasks.add(task);
        }

        if (activeTasks.isNotEmpty) {
          await Future.wait(activeTasks.toList());
          activeTasks.clear();
        }
      }

      if (failedSegments.isEmpty) {
        break;
      }
    }

    if (failedSegments.isNotEmpty) {
      final names = failedSegments.map((s) => s.name).join(', ');
      throw DownloadPoolException('Failed segments after $maxPasses passes: $names');
    }

    replyPort.send(DownloadComplete());
  } catch (e) {
    replyPort.send(DownloadPoolException('M3U8 download failed', e));
  }
}

Future<void> _downloadSegment(
  TsInfo ts,
  M3u8DownloadParams params,
  http.Client client,
) async {
  try {
    final file = File(path.join(params.tempDir, '${ts.name}.ts'));
    if (file.existsSync() && file.lengthSync() > 0) {
      if (kDebugMode) {
        print('[DownloadIsolate] Skipped ${ts.name} (already downloaded)');
      }
      return;
    }
    await file.parent.create(recursive: true);

    await _withRetry((attempt) async {
      if (kDebugMode) {
        print('[DownloadIsolate] Downloading ${ts.name} (attempt $attempt) -> ${ts.url}');
      }
      final request = http.Request('GET', Uri.parse(ts.url));
      if (params.headers != null) {
        request.headers.addAll(params.headers!);
      }
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw DownloadPoolException('HTTP ${response.statusCode} downloading ${ts.name}');
      }
      final sink = file.openWrite();
      try {
        await for (var chunk in response.stream) {
          sink.add(chunk);
        }
      } finally {
        await sink.flush();
        await sink.close();
      }
    }, 2, tag: ts.name);

    if (params.key != null) {
      final bytes = await file.readAsBytes();
      final indexStr = ts.name.split('TS_').last;
      final index = int.parse(indexStr);
      final decrypted = _aesDecrypt(
        (params.mediaSequence ?? 1) + (index - 1),
        bytes,
        params.key!,
        iv: params.iv,
      );
      await file.writeAsBytes(decrypted);
    }
    if (kDebugMode) {
      print('[DownloadIsolate] Successfully downloaded ${ts.name}');
    }
  } catch (e) {
    if (kDebugMode) {
      print('[DownloadIsolate] Error downloading segment ${ts.name}: $e');
    }
    throw DownloadPoolException('Failed to process segment: ${ts.name}', e);
  }
}

Uint8List _aesDecrypt(
  int sequence,
  Uint8List encrypted,
  Uint8List key, {
  Uint8List? iv,
}) {
  try {
    if (iv == null) {
      iv = Uint8List(16);
      ByteData.view(iv.buffer).setUint64(8, sequence);
    }
    final cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV(KeyParameter(key), iv));

    final blockSize = cipher.blockSize;
    final out = Uint8List(encrypted.length);
    for (int offset = 0; offset < encrypted.length; offset += blockSize) {
      cipher.processBlock(encrypted, offset, out, offset);
    }

    final padLen = out.last;
    if (padLen > 0 && padLen <= blockSize) {
      return out.sublist(0, out.length - padLen);
    }
    return out;
  } catch (e) {
    throw DownloadPoolException('Decryption failed', e);
  }
}

Future<T> _withRetry<T>(
  Future<T> Function(int attempt) operation,
  int maxRetries, {
  String? tag,
}) async {
  int attempts = 0;
  while (true) {
    try {
      attempts++;
      return await operation(attempts);
    } catch (e) {
      if (kDebugMode && tag != null) {
        print('[DownloadIsolate] Attempt $attempts/$maxRetries failed for $tag: $e');
      }
      if (attempts >= maxRetries) {
        throw DownloadPoolException(
          'Operation failed after $maxRetries attempts for ${tag ?? "task"}',
          e,
        );
      }
      await Future.delayed(Duration(milliseconds: 500 * (1 << (attempts - 1))));
    }
  }
}

class DownloadPoolException implements Exception {
  final String message;
  final dynamic originalError;

  DownloadPoolException(this.message, [this.originalError]);

  @override
  String toString() =>
      'DownloadPoolException: $message${originalError != null ? ' ($originalError)' : ''}';
}
