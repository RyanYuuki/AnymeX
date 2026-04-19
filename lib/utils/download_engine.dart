import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart';

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

class HlsDownloadResult {
  final bool success;
  final String? filePath;
  final String? error;

  const HlsDownloadResult({required this.success, this.filePath, this.error});
}

class DownloadEngine {
  static final Set<String> _cancelledTasks = {};
  static final Set<String> _pausedTasks = {};

  static void cancel(String taskId) {
    _cancelledTasks.add(taskId);
  }

  static void pause(String taskId) {
    _pausedTasks.add(taskId);
  }

  static void resume(String taskId) {
    _pausedTasks.remove(taskId);
  }

  static bool isPaused(String taskId) => _pausedTasks.contains(taskId);

  static String _extensionFor(String url) {
    final lower = url.toLowerCase().split('?').first;
    for (final ext in ['.mp4', '.mkv', '.avi', '.webm', '.mov']) {
      if (lower.endsWith(ext)) return ext;
    }
    return '.mp4';
  }

  static String buildFileName({
    required String episodeNumber,
    required Map<String, String> sortMap,
    required String url,
  }) {
    final ext = _extensionFor(url);
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

  static Future<DownloadResult> downloadHls({
    required String taskId,
    required String m3u8Url,
    required String fileName,
    required String subDirectory,
    String? docsPath,
    Map<String, String>? headers,
    String? preferredQuality,
    int parallelSegments = 3,
    void Function(double progress)? onProgress,
  }) async {
    print('Starting HLS download: $m3u8Url with headers $headers');
    final tsFileName = fileName.replaceAll(RegExp(r'\.\w+$'), '.ts');
    _cancelledTasks.remove(taskId);

    try {
      final String effectiveDocsPath = docsPath ?? (await getApplicationDocumentsDirectory()).path;
      final outDir = Directory(p.join(effectiveDocsPath, subDirectory));
      await outDir.create(recursive: true);

      final outPath = p.join(outDir.path, tsFileName);
      final progressPath = '$outPath.hls_progress';

      final rootBody = await _fetchText(m3u8Url, headers);
      String mediaM3u8Url = m3u8Url;
      String mediaBody = rootBody;

      if (_isMasterPlaylist(rootBody)) {
        mediaM3u8Url = _resolveBestVariant(rootBody, m3u8Url, preferredQuality);
        mediaBody = await _fetchText(mediaM3u8Url, headers);
      }

      final segments =
          await _parseMediaPlaylist(mediaBody, mediaM3u8Url, headers);
      if (segments.isEmpty) {
        return const DownloadResult(success: false, error: 'No segments found');
      }

      int startSegment = 0;
      final progressFile = File(progressPath);
      if (await progressFile.exists()) {
        final content = await progressFile.readAsString();
        startSegment = int.tryParse(content) ?? 0;
      }

      final outFile = File(outPath);
      final sink = await outFile.open(
          mode: startSegment > 0 ? FileMode.append : FileMode.write);

      final Map<int, Uint8List> sessionResults = {};
      int nextToSave = startSegment;
      Set<int> activeIndices = {};

      for (int i = startSegment; i < segments.length; i++) {
        if (_cancelledTasks.contains(taskId)) {
          await sink.close();
          return const DownloadResult(success: false, error: 'Cancelled');
        }

        while (_pausedTasks.contains(taskId)) {
          if (_cancelledTasks.contains(taskId)) {
            await sink.close();
            return const DownloadResult(success: false, error: 'Cancelled');
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }

        while (activeIndices.length >= parallelSegments || _pausedTasks.contains(taskId)) {
          if (_cancelledTasks.contains(taskId)) break;
          await Future.delayed(const Duration(milliseconds: 100));
        }

        final currentIndex = i;
        activeIndices.add(currentIndex);

        _fetchAndDecrypt(segments[currentIndex], currentIndex, headers)
            .then((data) async {
          sessionResults[currentIndex] = data;
          activeIndices.remove(currentIndex);

          while (sessionResults.containsKey(nextToSave)) {
            if (_cancelledTasks.contains(taskId)) break;

            final orderedData = sessionResults.remove(nextToSave)!;
            sink.writeFromSync(orderedData);
            nextToSave++;
            progressFile.writeAsStringSync(nextToSave.toString());
            onProgress?.call(nextToSave / segments.length);
          }
        }).catchError((e) {
          _cancelledTasks.add(taskId);
        });
      }

      while (activeIndices.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await sink.close();
      if (await progressFile.exists()) await progressFile.delete();

      if (_cancelledTasks.contains(taskId)) {
        return const DownloadResult(
            success: false, error: 'Cancelled or failed during segment fetch');
      }

      return DownloadResult(success: true, filePath: outPath);
    } catch (e) {
      return DownloadResult(success: false, error: e.toString());
    }
  }

  static Future<Uint8List> _fetchAndDecrypt(
      _HlsSegment seg, int index, Map<String, String>? headers) async {
    final rawBytes = await _fetchBytes(seg.url, headers);
    final keyToUse = seg.key.method == 'AES-128' && seg.key.iv == null
        ? HlsSegmentKey(
            method: seg.key.method,
            uri: seg.key.uri,
            keyBytes: seg.key.keyBytes,
            iv: _indexToIv(index),
          )
        : seg.key;
    return _decryptSegment(rawBytes, keyToUse);
  }

  static Future<DownloadResult> downloadFile({
    required String taskId,
    required String url,
    required String fileName,
    required String subDirectory,
    Map<String, String>? headers,
    int? chunks,
    void Function(double progress)? onProgress,
    void Function(TaskStatus status)? onStatus,
  }) async {
    try {
      Task task;
      if (chunks != null && chunks > 1) {
        task = ParallelDownloadTask(
          taskId: taskId,
          chunks: chunks,
          filename: fileName,
          directory: subDirectory,
          baseDirectory: BaseDirectory.applicationDocuments,
          updates: Updates.statusAndProgress,
          allowPause: true,
          requiresWiFi: false,
          retries: 2,
          headers: headers ?? {},
          url: [url],
        );
      } else {
        task = DownloadTask(
          taskId: taskId,
          url: url,
          filename: fileName,
          directory: subDirectory,
          baseDirectory: BaseDirectory.applicationDocuments,
          updates: Updates.statusAndProgress,
          allowPause: true,
          requiresWiFi: false,
          retries: 2,
          headers: headers ?? {},
        );
      }

      await FileDownloader().download(
        task as dynamic,
        onProgress: (prog) => onProgress?.call(prog),
        onStatus: (status) {
          onStatus?.call(status);
        },
      );

      final filePath = await task.filePath();
      return DownloadResult(success: true, filePath: filePath);
    } catch (e) {
      return DownloadResult(success: false, error: e.toString());
    }
  }

  static String? pickBestMatchingVideo(
      List<String> qualityLabels, String preferred) {
    if (qualityLabels.isEmpty) return null;

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

    if (best.value < 20) return null;

    return best.key;
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
    int segmentIndex = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('#EXT-X-KEY')) {
        currentKey = await _parseKeyTag(line, baseUrl, headers, segmentIndex);
        continue;
      }

      if (line.startsWith('#') || line.isEmpty) continue;

      final segUrl = _resolveUrl(line, baseUrl);
      HlsSegmentKey segKey = currentKey;
      if (currentKey.method == 'AES-128' && currentKey.iv == null) {
        final ivBytes = _indexToIv(segmentIndex);
        segKey = HlsSegmentKey(
          method: currentKey.method,
          uri: currentKey.uri,
          keyBytes: currentKey.keyBytes,
          iv: ivBytes,
        );
      }

      segments.add(_HlsSegment(url: segUrl, key: segKey));
      segmentIndex++;
    }
    return segments;
  }

  static Future<HlsSegmentKey> _parseKeyTag(
    String tag,
    String baseUrl,
    Map<String, String>? headers,
    int segmentIndex,
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

  static Uint8List _decryptSegment(Uint8List data, HlsSegmentKey key) {
    if (key.method == 'NONE' || key.keyBytes == null) return data;
    if (key.method == 'AES-128') {
      final iv = key.iv ?? _indexToIv(0);
      return _aes128CbcDecrypt(data, key.keyBytes!, iv);
    }
    return data;
  }

  static Uint8List _aes128CbcDecrypt(
      Uint8List data, Uint8List key, Uint8List iv) {
    final cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV(KeyParameter(key), iv));

    final blockSize = cipher.blockSize;
    final out = Uint8List(data.length);
    for (int offset = 0; offset < data.length; offset += blockSize) {
      cipher.processBlock(data, offset, out, offset);
    }

    final padLen = out.last;
    if (padLen > 0 && padLen <= blockSize) {
      return out.sublist(0, out.length - padLen);
    }
    return out;
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

  static String _resolveUrl(String href, String base) {
    if (href.startsWith('http://') || href.startsWith('https://')) return href;

    final baseUri = Uri.parse(base);
    return baseUri.resolve(href).toString();
  }

  static Uint8List _indexToIv(int index) {
    final iv = Uint8List(16);
    for (int i = 15; i >= 0; i--) {
      iv[i] = index & 0xff;
      index >>= 8;
    }
    return iv;
  }

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}

class _HlsSegment {
  final String url;
  final HlsSegmentKey key;
  const _HlsSegment({required this.url, required this.key});
}
