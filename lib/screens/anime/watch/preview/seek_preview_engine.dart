import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:anymex/screens/anime/watch/player/media_kit_player.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';

class SeekPreviewEngine {
  static const double _previewWindowSeconds = 30.0;
  static const double _marginSeconds = 4.0;

  final MediaKitPlayer Function() _mainPlayerProvider;
  final String? Function() _streamUrlProvider;
  final Map<String, String> Function() _headersProvider;

  SeekPreviewEngine({
    required MediaKitPlayer Function() mainPlayerProvider,
    required String? Function() streamUrlProvider,
    required Map<String, String> Function() headersProvider,
  })  : _mainPlayerProvider = mainPlayerProvider,
        _streamUrlProvider = streamUrlProvider,
        _headersProvider = headersProvider;

  final RxBool hasThumbnail = false.obs;

  Player? _previewPlayer;
  VideoController? _previewController;
  Directory? _cacheDir;
  File? _activeDumpFile;
  double _cachedRangeFrom = 0.0;
  double _cachedRangeTo = 0.0;
  double _timeBase = 0.0;
  String? _currentlyOpenedTarget;
  bool _isBusy = false;
  bool _isDisposed = false;
  int _bufferFileIndex = 0;
  Timer? _throttleTimer;
  Duration? _pendingSeekPosition;

  VideoController? get controller => _previewController;

  static Future<Directory> _getPreviewCacheDir() async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory('${tempDir.path}/anymex_seek_preview');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<void> sweepCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory('${tempDir.path}/anymex_seek_preview');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  Future<void> _ensurePreviewPlayer() async {
    if (_previewPlayer != null) return;

    final player = Player(
      configuration: const PlayerConfiguration(
        logLevel: MPVLogLevel.error,
        bufferSize: 8 * 1024 * 1024,
        libass: false,
      ),
    );

    _previewPlayer = player;
    _previewController = VideoController(player);

    try {
      final mpv = player.platform as dynamic;
      final fastProps = {
        'aid': 'no',
        'sid': 'no',
        'ao': 'null',
        'volume': '0',
        'hr-seek': 'no',
        'hwdec': 'no',
        'vd-lavc-skiploopfilter': 'all',
        'vd-lavc-fast': 'yes',
        'vd-lavc-threads': '2',
        'keep-open': 'yes',
        'ytdl': 'no',
        'cache': 'yes',
        'cache-pause': 'no',
        'demuxer-readahead-secs': '0',
        'hls-bitrate': 'min',
        'network-timeout': '15',
      };

      for (final entry in fastProps.entries) {
        await mpv.setProperty(entry.key, entry.value);
      }
    } catch (e) {
      Logger.e('SeekPreviewEngine mpv properties initialization failed: $e');
    }
  }

  void seek(Duration position) {
    _pendingSeekPosition = position;
    if (_throttleTimer?.isActive ?? false) return;
    _throttleTimer = Timer(const Duration(milliseconds: 90), _processQueue);
  }

  void stop() {
    _pendingSeekPosition = null;
    _throttleTimer?.cancel();
    hasThumbnail.value = false;
  }

  Future<void> _processQueue() async {
    if (_isBusy || _isDisposed) return;
    _isBusy = true;
    try {
      while (!_isDisposed) {
        final target = _pendingSeekPosition;
        if (target == null) break;
        _pendingSeekPosition = null;
        await _renderFrame(target.inMilliseconds / 1000.0);
      }
    } catch (e) {
      hasThumbnail.value = false;
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _renderFrame(double positionSeconds) async {
    final streamUrl = _streamUrlProvider();
    if (streamUrl == null || streamUrl.isEmpty) {
      hasThumbnail.value = false;
      return;
    }

    await _ensurePreviewPlayer();
    final player = _previewPlayer;
    if (player == null || _isDisposed) return;

    if (_isLocalFile(streamUrl)) {
      final localPath = streamUrl.startsWith('file:')
          ? Uri.parse(streamUrl).toFilePath()
          : streamUrl;
      if (_currentlyOpenedTarget != localPath) {
        await player.open(Media(localPath), play: false);
        _currentlyOpenedTarget = localPath;
      }
      _timeBase = 0.0;
      await player.seek(Duration(milliseconds: (positionSeconds * 1000).round()));
      hasThumbnail.value = true;
      return;
    }

    final isWithinCachedWindow = _activeDumpFile != null &&
        _currentlyOpenedTarget == _activeDumpFile!.path &&
        positionSeconds >= _cachedRangeFrom + _marginSeconds &&
        positionSeconds <= _cachedRangeTo - _marginSeconds;

    if (isWithinCachedWindow || await _dumpCachedRange(player, positionSeconds)) {
      _timeBase = _cachedRangeFrom;
    } else {
      await _openRemoteStream(player, streamUrl);
      _timeBase = 0.0;
    }

    final seekOffset = (positionSeconds - _timeBase).clamp(0.0, double.infinity);
    await player.seek(Duration(milliseconds: (seekOffset * 1000).round()));
    hasThumbnail.value = true;
  }

  Future<bool> _dumpCachedRange(Player preview, double atSeconds) async {
    try {
      final mainPlatform = _mainPlayerProvider().nativePlayer.platform as dynamic;
      final rawRanges = await mainPlatform.getProperty('demuxer-cache-state');
      final rangesList = _parseSeekableRanges(rawRanges);

      final matchingRange = rangesList
          .where((r) => atSeconds >= r.$1 && atSeconds <= r.$2)
          .cast<(double, double)?>()
          .firstOrNull;

      if (matchingRange == null) return false;

      _cacheDir ??= await _getPreviewCacheDir();
      final root = _cacheDir!;

      final from = (atSeconds - _previewWindowSeconds).clamp(matchingRange.$1, matchingRange.$2);
      final to = (atSeconds + _previewWindowSeconds).clamp(matchingRange.$1, matchingRange.$2);

      if (to - from < 2.0) return false;

      _bufferFileIndex = (_bufferFileIndex + 1) % 2;
      final dumpFile = File('${root.path}/buf_$_bufferFileIndex.mkv');

      await mainPlatform.command([
        'dump-cache',
        from.toStringAsFixed(3),
        to.toStringAsFixed(3),
        dumpFile.path,
      ]);

      if (_isDisposed || !await dumpFile.exists()) return false;

      await preview.open(Media(dumpFile.path), play: false);
      _currentlyOpenedTarget = dumpFile.path;
      _activeDumpFile = dumpFile;
      _cachedRangeFrom = from;
      _cachedRangeTo = to;
      return true;
    } catch (_) {
      return false;
    }
  }

  List<(double, double)> _parseSeekableRanges(dynamic raw) {
    if (raw == null) return const [];
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map) return const [];
      final list = decoded['seekable-ranges'];
      if (list is! List) return const [];

      final result = <(double, double)>[];
      for (final r in list) {
        if (r is Map && r['start'] is num && r['end'] is num) {
          result.add(((r['start'] as num).toDouble(), (r['end'] as num).toDouble()));
        }
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _openRemoteStream(Player player, String streamUrl) async {
    if (_currentlyOpenedTarget == streamUrl) return;

    final headers = _headersProvider();
    final userAgent = headers.entries
        .where((e) => e.key.toLowerCase() == 'user-agent')
        .firstOrNull
        ?.value;

    final mpv = player.platform as dynamic;
    if (userAgent != null) {
      await mpv.setProperty('user-agent', userAgent);
    }

    final filteredHeaders = {
      for (final e in headers.entries)
        if (e.key.toLowerCase() != 'user-agent') e.key: e.value
    };

    await player.open(
      Media(streamUrl, httpHeaders: filteredHeaders),
      play: false,
    );
    _currentlyOpenedTarget = streamUrl;
  }

  bool _isLocalFile(String url) {
    final uri = Uri.tryParse(url);
    return uri == null || !uri.hasScheme || uri.scheme == 'file';
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _throttleTimer?.cancel();
    final player = _previewPlayer;
    _previewPlayer = null;
    _previewController = null;
    _activeDumpFile = null;

    try {
      await player?.dispose();
    } catch (_) {}

    await sweepCache();
  }
}
