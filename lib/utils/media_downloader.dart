import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:typed_data';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:anymex/database/isar_models/track.dart' as hive;
import 'package:anymex/utils/download_isolate_pool.dart';

class HlsSegmentKey {
  final String method;
  final String? uri;
  final Uint8List? keyBytes;
  final Uint8List? iv;

  const HlsSegmentKey({
    required this.method,
    this.uri,
    this.keyBytes,
    this.iv,
  });
}

class _HlsSegment {
  final String url;
  final HlsSegmentKey key;
  const _HlsSegment({required this.url, required this.key});
}

class MediaDownloader {
  final String taskId;
  final ItemType itemType;
  final List<PageUrl>? pageUrls;
  final int concurrentDownloads;
  final List<hive.Track>? subtitles;
  final String? subDownloadDir;
  final String? m3u8Url;
  final String? videoFileName;
  final Map<String, String>? headers;
  final String? episodeNumber;

  static var httpClient = http.Client();

  MediaDownloader({
    required this.taskId,
    required this.itemType,
    this.pageUrls,
    this.subtitles,
    this.subDownloadDir,
    this.m3u8Url,
    this.videoFileName,
    this.headers,
    this.concurrentDownloads = 1,
    this.episodeNumber,
  });

  static Future<void> initializeIsolatePool({int poolSize = 6}) async {
    DownloadIsolatePool.configure(poolSize: poolSize);
    await DownloadIsolatePool.instance.initialize();
  }

  void close() {
    DownloadIsolatePool.instance.cancelTask(taskId);
  }

  static Future<T> _withRetryStatic<T>(
    Future<T> Function() operation,
    int maxRetries,
  ) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        if (attempts >= maxRetries) {
          throw MediaDownloaderException(
            'Operation failed after $maxRetries attempts',
            e,
          );
        }
        await Future.delayed(Duration(milliseconds: 500 * (1 << (attempts - 1))));
      }
    }
  }

  Future<void> download(void Function(DownloadProgress) onProgress) async {
    try {
      if (itemType == ItemType.anime &&
          m3u8Url != null &&
          videoFileName != null &&
          subDownloadDir != null) {
        await _downloadM3u8WithProgress(onProgress);
      } else if (pageUrls != null) {
        await _downloadFilesWithProgress(pageUrls!, onProgress);
      }

      for (var element in subtitles ?? <hive.Track>[]) {
        if (subDownloadDir == null ||
            element.file == null ||
            episodeNumber == null) {
          continue;
        }
        final subFolder =
            path.join(subDownloadDir!, 'Episode_${episodeNumber}_subs');
        final subtitleFile = File(
          path.join(subFolder, '${element.label}.srt'),
        );
        if (subtitleFile.existsSync()) {
          continue;
        }
        subtitleFile.createSync(recursive: true);
        final response = await _withRetryStatic(
          () => httpClient.get(Uri.parse(element.file!)),
          3,
        );
        if (response.statusCode != 200) {
          continue;
        }
        await subtitleFile.writeAsBytes(response.bodyBytes);
      }
    } catch (e) {
      throw MediaDownloaderException('Download failed', e);
    } finally {
      close();
    }
  }

  Future<void> _downloadFilesWithProgress(
    List<PageUrl> pageUrls,
    void Function(DownloadProgress) onProgress,
  ) async {
    final completer = Completer<void>();

    await DownloadIsolatePool.instance.submitFileDownload(
      taskId: taskId,
      pageUrls: pageUrls,
      concurrentDownloads: concurrentDownloads,
      itemType: itemType,
      onProgress: (progress) {
        onProgress(progress);
      },
      onComplete: () {
        onProgress(
          DownloadProgress(1, 1, itemType, isCompleted: true),
        );
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );

    return completer.future;
  }

  Future<void> _downloadM3u8WithProgress(
      void Function(DownloadProgress) onProgress) async {
    final completer = Completer<void>();

    final rootBody = await _fetchText(m3u8Url!, headers);
    String mediaM3u8Url = m3u8Url!;
    String mediaBody = rootBody;

    if (_isMasterPlaylist(rootBody)) {
      mediaM3u8Url = _resolveBestVariant(rootBody, m3u8Url!, null);
      mediaBody = await _fetchText(mediaM3u8Url, headers);
    }

    final segments =
        await _parseMediaPlaylist(mediaBody, mediaM3u8Url, headers);
    if (segments.isEmpty) {
      throw Exception('No segments found');
    }
    final mediaSequence = _extractMediaSequence(mediaBody) ?? 0;

    final tsInfos = <TsInfo>[];
    for (int i = 0; i < segments.length; i++) {
      tsInfos.add(TsInfo(url: segments[i].url, name: 'TS_${i + 1}'));
    }

    final mediaDir = Directory(subDownloadDir!);
    await mediaDir.create(recursive: true);
    final tempDir = path.join(subDownloadDir!, 'temp_$taskId');
    await Directory(tempDir).create(recursive: true);

    Uint8List? globalKey;
    Uint8List? globalIv;
    if (segments.isNotEmpty && segments.first.key.method != 'NONE') {
      globalKey = segments.first.key.keyBytes;
      globalIv = segments.first.key.iv;
    }

    final pendingSegments = tsInfos
        .where((ts) => !File(path.join(tempDir, '${ts.name}.ts')).existsSync())
        .toList();

    await DownloadIsolatePool.instance.submitM3u8Download(
      taskId: taskId,
      segments: pendingSegments,
      tempDir: tempDir,
      key: globalKey,
      iv: globalIv,
      mediaSequence: mediaSequence,
      concurrentDownloads: concurrentDownloads,
      headers: headers,
      itemType: itemType,
      onProgress: (progress) {
        onProgress(progress);
      },
      onComplete: () async {
        try {
          await _mergeTsToFile(
            path.join(subDownloadDir!, videoFileName!),
            tempDir,
          );
          await Directory(tempDir).delete(recursive: true);
          onProgress(DownloadProgress(1, 1, itemType, isCompleted: true));
          if (!completer.isCompleted) completer.complete();
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
      onError: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
    );

    return completer.future;
  }

  Future<void> _mergeTsToFile(String outputFile, String tempDir) async {
    final dir = Directory(tempDir);
    final files = await dir
        .list()
        .where((entity) => entity.path.endsWith('.ts'))
        .toList();

    files.sort((a, b) {
      final aName = path.basenameWithoutExtension(a.path);
      final bName = path.basenameWithoutExtension(b.path);
      final aIndex = int.tryParse(aName.replaceFirst('TS_', '')) ?? 0;
      final bIndex = int.tryParse(bName.replaceFirst('TS_', '')) ?? 0;
      return aIndex.compareTo(bIndex);
    });

    final outFile = File(outputFile);
    await outFile.parent.create(recursive: true);
    final sink = outFile.openWrite();
    try {
      for (final file in files) {
        await sink.addStream(File(file.path).openRead());
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  static Future<String> _fetchText(
      String url, Map<String, String>? headers) async {
    final response = await http.get(Uri.parse(url), headers: headers ?? {});
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} fetching $url');
    }
    return response.body;
  }

  static Future<Uint8List> _fetchBytes(
      String url, Map<String, String>? headers) async {
    final response = await http.get(Uri.parse(url), headers: headers ?? {});
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} fetching $url');
    }
    return response.bodyBytes;
  }

  static bool _isMasterPlaylist(String body) =>
      body.contains('#EXT-X-STREAM-INF') || body.contains('#EXT-X-MEDIA:');

  static String _resolveBestVariant(
      String body, String baseUrl, String? preferred) {
    final lines = body.split('\n').map((l) => l.trim()).toList();
    final variants = <({String uri, int bandwidth, String resolution})>[];

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('#EXT-X-STREAM-INF')) {
        final bwMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(lines[i]);
        final resMatch = RegExp(r'RESOLUTION=([\dx]+)').firstMatch(lines[i]);
        final bandwidth = int.tryParse(bwMatch?.group(1) ?? '0') ?? 0;
        final resolution = resMatch?.group(1) ?? '';
        final uri = i + 1 < lines.length ? lines[i + 1] : '';
        if (uri.isNotEmpty && !uri.startsWith('#')) {
          variants.add((
            uri: _resolveUrl(uri, baseUrl),
            bandwidth: bandwidth,
            resolution: resolution
          ));
        }
      }
    }

    if (variants.isEmpty) return baseUrl;

    if (preferred != null && preferred.isNotEmpty) {
      for (final v in variants) {
        if (v.resolution.contains(preferred) || v.uri.contains(preferred)) {
          return v.uri;
        }
      }
    }

    variants.sort((a, b) => b.bandwidth.compareTo(a.bandwidth));
    return variants.first.uri;
  }

  static Future<List<_HlsSegment>> _parseMediaPlaylist(
    String body,
    String baseUrl,
    Map<String, String>? headers,
  ) async {
    final lines = body.split('\n').map((l) => l.trim()).toList();
    final segments = <_HlsSegment>[];

    HlsSegmentKey currentKey = const HlsSegmentKey(method: 'NONE');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('#EXT-X-KEY')) {
        currentKey = await _parseKeyTag(line, baseUrl, headers);
        continue;
      }

      if (line.startsWith('#') || line.isEmpty) continue;

      final segUrl = _resolveUrl(line, baseUrl);
      segments.add(_HlsSegment(url: segUrl, key: currentKey));
    }
    return segments;
  }

  static Future<HlsSegmentKey> _parseKeyTag(
    String tag,
    String baseUrl,
    Map<String, String>? headers,
  ) async {
    final methodMatch = RegExp(r'METHOD=([^,\s"]+)').firstMatch(tag);
    final method = methodMatch?.group(1) ?? 'NONE';

    if (method == 'NONE') return const HlsSegmentKey(method: 'NONE');

    final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(tag);
    final ivMatch = RegExp(r'IV=0x([0-9a-fA-F]+)').firstMatch(tag);

    final keyUri = uriMatch?.group(1);
    Uint8List? keyBytes;
    Uint8List? iv;

    if (keyUri != null) {
      final resolvedKeyUrl = _resolveUrl(keyUri, baseUrl);
      keyBytes = await _fetchBytes(resolvedKeyUrl, headers);
    }
    if (ivMatch != null) {
      iv = _hexToBytes(ivMatch.group(1)!.padLeft(32, '0'));
    }

    return HlsSegmentKey(
        method: method, uri: keyUri, keyBytes: keyBytes, iv: iv);
  }

  static String _resolveUrl(String href, String base) {
    if (href.startsWith('http://') || href.startsWith('https://')) return href;
    final baseUri = Uri.parse(base);
    return baseUri.resolve(href).toString();
  }

  static int? _extractMediaSequence(String body) {
    for (final line in body.split('\n')) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('#EXT-X-MEDIA-SEQUENCE')) continue;
      return int.tryParse(trimmed.split(':').last.trim());
    }
    return null;
  }

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  static String _extensionFor(String url) {
    final lower = url.toLowerCase().split('?').first;
    for (final ext in ['.mp4', '.mkv', '.avi', '.webm', '.mov', '.m3u8']) {
      if (lower.endsWith(ext)) return ext;
    }
    return '.mp4';
  }

  static String buildFileName({
    required String episodeNumber,
    required Map<String, String> sortMap,
    required String url,
    bool isHls = false,
  }) {
    final ext = isHls ? '.mp4' : _extensionFor(url);
    final season = sortMap['season'];

    if (season != null && season.isNotEmpty) {
      return 'S${season}_EP$episodeNumber$ext';
    }
    return 'Episode $episodeNumber$ext';
  }

  static String sanitizePathSegment(String input) =>
      input.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();

  static String buildTaskId({
    required String extensionName,
    required String mediaTitle,
    required String episodeNumber,
    required Map<String, String> sortMap,
  }) {
    final sortPart = sortMap.isEmpty ? '' : '_${sortMap.values.join('_')}';
    return 'dl_${sanitizePathSegment(extensionName)}_ep$episodeNumber${sortPart}_${DateTime.now().millisecondsSinceEpoch % 100000}_${Random().nextInt(9999)}';
  }

  static String pickBestMatchingVideo(
      List<String> qualityLabels, String preferred) {
    if (qualityLabels.isEmpty) return '';

    final preferredLower = preferred.toLowerCase();
    final isPreferredDub = preferredLower.contains('dub');
    final isPreferredSub = preferredLower.contains('sub');
    final preferredRes =
        RegExp(r'\d{3,4}p').firstMatch(preferredLower)?.group(0);

    final scored = qualityLabels.map((label) {
      int score = 0;
      final labelLower = label.toLowerCase();
      final isDub = labelLower.contains('dub');
      final isSub = labelLower.contains('sub');
      final res = RegExp(r'\d{3,4}p').firstMatch(labelLower)?.group(0);

      if (preferredRes != null && res == preferredRes) {
        score += 100;
      } else if (res != null && preferredRes != null) {
        score -= 50;
      }

      if (isPreferredDub && isDub) score += 80;
      if (isPreferredSub && isSub) score += 80;
      if (labelLower == preferredLower) score += 200;
      if (labelLower.contains(preferredLower) ||
          preferredLower.contains(labelLower)) {
        score += 20;
      }

      return MapEntry(label, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    final best = scored.first;

    if (best.value < 20) return qualityLabels.first;

    return best.key;
  }
}

class MediaDownloaderException implements Exception {
  final String message;
  final dynamic originalError;

  MediaDownloaderException(this.message, [this.originalError]);

  @override
  String toString() =>
      'MediaDownloaderException: $message${originalError != null ? ' ($originalError)' : ''}';
}
