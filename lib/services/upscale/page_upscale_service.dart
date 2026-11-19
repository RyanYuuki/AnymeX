import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:anymex/controllers/services/storage/anymex_cache_manager.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'gpu_upscale_runner.dart';
import 'mode_chains.dart';
import 'shader_registry.dart';

class UpscaleConfig {
  final String mode;
  final String profile;
  final double sharpness;
  final bool denoise;

  UpscaleConfig({
    required this.mode,
    required this.profile,
    required this.sharpness,
    required this.denoise,
  });

  String get fingerprint {
    final raw = '$mode|$profile|${sharpness.toStringAsFixed(2)}|$denoise';
    return sha1.convert(utf8.encode(raw)).toString().substring(0, 12);
  }
}

class _UpscaleJob {
  final PageUrl page;
  final UpscaleConfig config;
  final int targetWidthPx;
  final int priority;
  final Completer<File?> completer;
  bool isCancelled = false;

  _UpscaleJob({
    required this.page,
    required this.config,
    required this.targetWidthPx,
    required this.priority,
    required this.completer,
  });
}

class PageUpscaleService {
  static final PageUpscaleService instance = PageUpscaleService._();
  PageUpscaleService._();

  final List<_UpscaleJob> _queue = [];
  bool _isProcessing = false;
  final Set<String> _skipSet = {};
  int maxCacheSizeBytes = 500 * 1024 * 1024;

  Future<File?> upscaled(
    PageUrl page,
    UpscaleConfig config, {
    int targetWidthPx = 0,
    int priority = 0,
  }) async {
    final key = _computeKey(page.url, config.fingerprint);
    final cached = await _getCachedFile(key);
    if (cached != null) return cached;

    if (_skipSet.contains('${page.url}|${config.fingerprint}')) {
      return null;
    }

    final completer = Completer<File?>();
    final job = _UpscaleJob(
      page: page,
      config: config,
      targetWidthPx: targetWidthPx,
      priority: priority,
      completer: completer,
    );

    _queue.add(job);
    _queue.sort((a, b) => b.priority.compareTo(a.priority));
    _pumpQueue();

    return completer.future;
  }

  void prefetch(
    List<PageUrl> pages,
    UpscaleConfig config, {
    int targetWidthPx = 0,
  }) {
    for (final page in pages) {
      upscaled(page, config, targetWidthPx: targetWidthPx, priority: 0);
    }
  }

  void cancelAll() {
    for (final job in _queue) {
      job.isCancelled = true;
      if (!job.completer.isCompleted) {
        job.completer.complete(null);
      }
    }
    _queue.clear();
  }

  void _pumpQueue() {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;
    _processNext();
  }

  Future<void> _processNext() async {
    while (_queue.isNotEmpty) {
      final job = _queue.removeAt(0);
      if (job.isCancelled) continue;
      await _executeJob(job);
    }
    _isProcessing = false;
  }

  Future<void> _executeJob(_UpscaleJob job) async {
    try {
      if (!ShaderRegistry.isLoaded) {
        await ShaderRegistry.load();
      }

      final key = _computeKey(
        job.page.url,
        job.config.fingerprint,
      );

      final cached = await _getCachedFile(key);
      if (cached != null) {
        job.completer.complete(cached);
        return;
      }

      final Uint8List originalBytes;
      if (job.page.url.startsWith('http')) {
        final f = await AnymeXCacheManager.instance.getSingleFile(
          job.page.url,
          headers: job.page.headers,
        );
        originalBytes = await f.readAsBytes();
      } else {
        originalBytes = await File(job.page.url).readAsBytes();
      }

      if (job.isCancelled) {
        job.completer.complete(null);
        return;
      }

      final codec = await ui.instantiateImageCodec(originalBytes);
      final frame = await codec.getNextFrame();
      final source = frame.image;
      codec.dispose();

      final origW = source.width;
      final origH = source.height;

      final isWebtoonStrip =
          origH > 3500 || origW > 3500 || (origH / origW) > 2.2;
      if (isWebtoonStrip) {
        source.dispose();
        _skipSet.add('${job.page.url}|${job.config.fingerprint}');
        job.completer.complete(null);
        return;
      }

      const maxDim = 4096.0;
      final double largestDim = math.max(origW * 2, origH * 2).toDouble();
      final double uniformScale =
          largestDim > maxDim ? (maxDim / largestDim) * 2.0 : 2.0;

      if (uniformScale < 1.15) {
        source.dispose();
        _skipSet.add('${job.page.url}|${job.config.fingerprint}');
        job.completer.complete(null);
        return;
      }

      final outW = (origW * uniformScale).round();
      final outH = (origH * uniformScale).round();

      final params = getShaderParams(
        profile: job.config.profile,
        sharpness: job.config.sharpness,
        denoise: job.config.denoise,
      );

      final upscaledImage = await GpuUpscaleRunner.run(
        input: source,
        mode: job.config.mode,
        params: params,
        outW: outW,
        outH: outH,
      );

      source.dispose();

      if (upscaledImage == null) {
        job.completer.complete(null);
        return;
      }

      final byteData =
          await upscaledImage.toByteData(format: ui.ImageByteFormat.png);
      upscaledImage.dispose();

      if (byteData == null) {
        job.completer.complete(null);
        return;
      }

      final file = await _writeAtomic(key, byteData.buffer.asUint8List());
      await _cleanLruCache();
      job.completer.complete(file);
    } catch (_) {
      if (!job.completer.isCompleted) {
        job.completer.complete(null);
      }
    }
  }

  String _computeKey(String url, String fingerprint) {
    final raw = '$url|$fingerprint';
    return sha1.convert(utf8.encode(raw)).toString();
  }

  Future<File?> _getCachedFile(String key) async {
    final dir = await _getCacheDir();
    final f = File('$dir/$key.png');
    return await f.exists() ? f : null;
  }

  Future<String> _getCacheDir() async {
    final temp = await getTemporaryDirectory();
    final dir = Directory('${temp.path}/anymex_upscaled');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<File> _writeAtomic(String key, Uint8List bytes) async {
    final dir = await _getCacheDir();
    final tmp = File('$dir/$key.tmp');
    final out = File('$dir/$key.png');
    await tmp.writeAsBytes(bytes);
    await tmp.rename(out.path);
    return out;
  }

  Future<void> _cleanLruCache() async {
    try {
      final dir = Directory(await _getCacheDir());
      final files = await dir
          .list()
          .where((e) => e is File && e.path.endsWith('.png'))
          .cast<File>()
          .toList();

      int total = 0;
      for (final f in files) {
        total += await f.length();
      }

      if (total <= maxCacheSizeBytes) return;

      files.sort(
          (a, b) => a.statSync().modified.compareTo(b.statSync().modified));

      for (final f in files) {
        final len = await f.length().catchError((_) => 0);
        await f.delete().catchError((_) => f);
        total -= len;
        if (total <= maxCacheSizeBytes) break;
      }
    } catch (_) {}
  }

  Future<void> clearCache() async {
    try {
      final dir = Directory(await _getCacheDir());
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  Future<int> cacheBytes() async {
    try {
      final dir = Directory(await _getCacheDir());
      if (!await dir.exists()) return 0;
      int total = 0;
      await for (final f in dir.list()) {
        if (f is File) {
          total += await f.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }
}
