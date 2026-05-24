import 'dart:async';
import 'dart:io';

import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/torrent/torrent_url_detector.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:libtorrent_flutter/libtorrent_flutter.dart';

class TorrentStreamResolver {
  static bool _isInitialized = false;
  static final Map<int, _TorrentSession> _sessions = {};
  static int? _currentActiveTorrentId;

  static bool get isInitialized => _isInitialized;
  static int? get currentTorrentId => _currentActiveTorrentId;

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    Logger.i('[TorrentResolver] Initializing libtorrent engine...');

    try {
      final downloadPath = await _getDownloadPath();
      await LibtorrentFlutter.init(
        defaultSavePath: downloadPath,
        fetchTrackers: true,
      );

      _isInitialized = true;
      Logger.i('[TorrentResolver] Engine ready — path: $downloadPath');
      return true;
    } catch (e) {
      Logger.e('[TorrentResolver] Init failed: $e');
      return false;
    }
  }

  static Future<ResolvedStream> resolve(
    String url, {
    void Function(double progress)? onProgress,
    void Function(List<TorrentFileInfo> files)? onFilesDiscovered,
    int? preferredFileIndex,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        throw Exception('Torrent engine not available');
      }
    }

    final engine = LibtorrentFlutter.instance;
    final infoHash = extractInfoHash(url) ?? url;
    Logger.i('[TorrentResolver] Resolving: $infoHash');

    for (final session in _sessions.values) {
      if (session.originalUrl == url) {
        _currentActiveTorrentId = session.torrentId;
        Logger.i('[TorrentResolver] Reusing stream: ${session.streamUrl}');
        return ResolvedStream(
          streamUrl: session.streamUrl,
          infoHash: infoHash,
          fileName: session.fileName,
        );
      }
    }

    try {
      onProgress?.call(0.0);

      int torrentId;
      if (url.trimLeft().startsWith('magnet:')) {
        torrentId = engine.addMagnet(url);
      } else {
        final torrentPath = await _prepareTorrentFile(url);
        torrentId = engine.addTorrentFile(torrentPath);
      }

      Logger.i('[TorrentResolver] Added torrent: $torrentId');
      onProgress?.call(0.1);

      await _waitForMetadata(torrentId, timeout: const Duration(seconds: 60));
      onProgress?.call(0.4);
      Logger.i('[TorrentResolver] Metadata received');

      final files = engine.getFiles(torrentId);
      final allFiles = files.map((f) => TorrentFileInfo(
            index: f.index,
            name: f.name,
            path: f.path,
            size: f.size,
            isVideo: _isVideoExtension(f.path),
          )).toList();

      final videoFiles = allFiles.where((f) => f.isVideo).toList();
      onFilesDiscovered?.call(allFiles);

      if (videoFiles.isEmpty) {
        throw Exception('No video files found in torrent');
      }

      int fileIndex;
      if (preferredFileIndex != null &&
          videoFiles.any((f) => f.index == preferredFileIndex)) {
        fileIndex = preferredFileIndex;
      } else if (videoFiles.length == 1) {
        fileIndex = videoFiles.first.index;
      } else {
        fileIndex = videoFiles
            .reduce((a, b) => a.size > b.size ? a : b)
            .index;
      }

      final chosenFile = allFiles.firstWhere((f) => f.index == fileIndex);
      Logger.i(
          '[TorrentResolver] Streaming: ${chosenFile.name} (${_formatBytes(chosenFile.size)})');

      final matchedSubs = _findMatchingSubtitles(chosenFile.name, allFiles);
      final matchedAudio = _findMatchingAudio(chosenFile.name, allFiles);
      if (matchedSubs.isNotEmpty || matchedAudio.isNotEmpty) {
        final priorities = List<int>.filled(allFiles.length, 0);
        for (final s in matchedSubs) {
          priorities[s.fileIndex] = 4;
        }
        for (final a in matchedAudio) {
          priorities[a.fileIndex] = 4;
        }
        priorities[fileIndex] = 7;
        engine.setFilePriorities(torrentId, priorities);
        Logger.i('[TorrentResolver] Found ${matchedSubs.length} subs, ${matchedAudio.length} audio tracks');
      }

      final streamInfo = engine.startStream(torrentId, fileIndex: fileIndex);
      onProgress?.call(0.5);

      engine.preloadStream(streamInfo.id);
      onProgress?.call(1.0);

      Logger.i('[TorrentResolver] Stream ready: ${streamInfo.url}');

      _sessions[torrentId] = _TorrentSession(
        torrentId: torrentId,
        streamUrl: streamInfo.url,
        fileName: chosenFile.name,
        originalUrl: url,
        fileIndex: fileIndex,
      );

      _currentActiveTorrentId = torrentId;

      return ResolvedStream(
        streamUrl: streamInfo.url,
        infoHash: infoHash,
        fileName: chosenFile.name,
        subtitles: matchedSubs,
        audioTracks: matchedAudio,
      );
    } catch (e) {
      Logger.e('[TorrentResolver] Failed to resolve: $e');
      rethrow;
    }
  }

  static Future<void> _waitForMetadata(int torrentId, {required Duration timeout}) async {
    final engine = LibtorrentFlutter.instance;
    final completer = Completer<void>();

    late StreamSubscription sub;
    sub = engine.torrentUpdates.listen((torrents) {
      final t = torrents[torrentId];
      if (t != null && t.hasMetadata) {
        sub.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });

    final existing = engine.torrents[torrentId];
    if (existing != null && existing.hasMetadata) {
      sub.cancel();
      completer.complete();
    }

    await completer.future.timeout(timeout, onTimeout: () {
      sub.cancel();
      throw TimeoutException('Metadata fetch timed out', timeout);
    });
  }

  static Future<String> _prepareTorrentFile(String url) async {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to download .torrent file: HTTP ${response.statusCode}');
      }
      final dir = await _getDownloadPath();
      final filePath = p.join(dir, 'temp_${DateTime.now().millisecondsSinceEpoch}.torrent');
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    }

    if (!await File(url).exists()) {
      throw Exception('Torrent file not found: $url');
    }
    return url;
  }

  static Future<void> stopActiveStream() async {
    final torrentId = _currentActiveTorrentId;
    if (torrentId == null) return;

    Logger.i('[TorrentResolver] Player closed — stopping stream: $torrentId');
    await stop(torrentId);
    _currentActiveTorrentId = null;
  }

  static Future<void> stop(int torrentId) async {
    final session = _sessions.remove(torrentId);
    if (session == null) return;

    try {
      final engine = LibtorrentFlutter.instance;
      engine.stopAllStreamsForTorrent(torrentId);
      engine.removeTorrent(torrentId, deleteFiles: true);
      Logger.i('[TorrentResolver] Removed torrent: $torrentId');
    } catch (e) {
      Logger.e('[TorrentResolver] Error removing torrent: $e');
    }
  }

  static Future<void> stopAll() async {
    for (final torrentId in _sessions.keys.toList()) {
      await stop(torrentId);
    }
    _currentActiveTorrentId = null;
  }

  static Future<void> dispose() async {
    await stopAll();
    if (_isInitialized && LibtorrentFlutter.isInitialized) {
      await LibtorrentFlutter.instance.dispose();
    }
    _isInitialized = false;
  }

  static List<TorrentSubtitle> _findMatchingSubtitles(
      String videoName, List<TorrentFileInfo> allFiles) {
    final videoBaseName = videoName.replaceAll(RegExp(r'\.[^.]+$'), '');
    final subFiles = allFiles.where((f) => _isSubtitleExtension(f.path)).toList();
    if (subFiles.isEmpty) return [];

    final langMap = {
      'eng': 'English', 'en': 'English', 'english': 'English',
      'jpn': 'Japanese', 'ja': 'Japanese', 'jap': 'Japanese', 'japanese': 'Japanese',
      'chi': 'Chinese', 'zh': 'Chinese', 'chs': 'Chinese Simplified', 'cht': 'Chinese Traditional', 'chinese': 'Chinese',
      'kor': 'Korean', 'ko': 'Korean', 'korean': 'Korean',
      'spa': 'Spanish', 'es': 'Spanish', 'spanish': 'Spanish',
      'fre': 'French', 'fr': 'French', 'french': 'French',
      'ger': 'German', 'de': 'German', 'german': 'German',
      'por': 'Portuguese', 'pt': 'Portuguese', 'portuguese': 'Portuguese',
      'ita': 'Italian', 'it': 'Italian', 'italian': 'Italian',
      'rus': 'Russian', 'ru': 'Russian', 'russian': 'Russian',
      'ara': 'Arabic', 'ar': 'Arabic', 'arabic': 'Arabic',
      'hin': 'Hindi', 'hi': 'Hindi', 'hindi': 'Hindi',
      'tha': 'Thai', 'th': 'Thai', 'thai': 'Thai',
      'vie': 'Vietnamese', 'vi': 'Vietnamese', 'vietnamese': 'Vietnamese',
      'ind': 'Indonesian', 'id': 'Indonesian', 'indonesian': 'Indonesian',
      'may': 'Malay', 'ms': 'Malay', 'malay': 'Malay',
      'tur': 'Turkish', 'tr': 'Turkish', 'turkish': 'Turkish',
      'pol': 'Polish', 'pl': 'Polish', 'polish': 'Polish',
      'nld': 'Dutch', 'nl': 'Dutch', 'dutch': 'Dutch',
      'swe': 'Swedish', 'sv': 'Swedish', 'swedish': 'Swedish',
      'nor': 'Norwegian', 'no': 'Norwegian', 'norwegian': 'Norwegian',
      'dan': 'Danish', 'da': 'Danish', 'danish': 'Danish',
      'fin': 'Finnish', 'fi': 'Finnish', 'finnish': 'Finnish',
      'ukr': 'Ukrainian', 'uk': 'Ukrainian', 'ukrainian': 'Ukrainian',
      'rum': 'Romanian', 'ro': 'Romanian', 'romanian': 'Romanian',
      'hun': 'Hungarian', 'hu': 'Hungarian', 'hungarian': 'Hungarian',
      'cze': 'Czech', 'cs': 'Czech', 'czech': 'Czech',
      'bra': 'Portuguese (BR)', 'pt-BR': 'Portuguese (BR)',
      'lat': 'Spanish (LAT)', 'es-419': 'Spanish (LAT)',
    };

    final matched = <TorrentSubtitle>[];
    for (final sub in subFiles) {
      final subName = sub.name.replaceAll(RegExp(r'\.[^.]+$'), '').toLowerCase();
      final videoLower = videoBaseName.toLowerCase();

      if (subName == videoLower ||
          subName.startsWith(videoLower) ||
          videoLower.startsWith(subName)) {
        String lang = 'Unknown';
        final nameLower = sub.name.toLowerCase();
        for (final entry in langMap.entries) {
          if (nameLower.contains(entry.key)) {
            lang = entry.value;
            break;
          }
        }
        matched.add(TorrentSubtitle(
          fileIndex: sub.index,
          fileName: sub.name,
          language: lang,
        ));
      }
    }
    return matched;
  }

  static List<TorrentAudioTrack> _findMatchingAudio(
      String videoName, List<TorrentFileInfo> allFiles) {
    final videoBaseName = videoName.replaceAll(RegExp(r'\.[^.]+$'), '');
    final audioFiles = allFiles.where((f) => _isAudioExtension(f.path)).toList();
    if (audioFiles.isEmpty) return [];

    final langMap = {
      'eng': 'English', 'en': 'English', 'english': 'English',
      'jpn': 'Japanese', 'ja': 'Japanese', 'jap': 'Japanese', 'japanese': 'Japanese',
      'chi': 'Chinese', 'zh': 'Chinese', 'chs': 'Chinese Simplified', 'cht': 'Chinese Traditional', 'chinese': 'Chinese',
      'kor': 'Korean', 'ko': 'Korean', 'korean': 'Korean',
      'spa': 'Spanish', 'es': 'Spanish', 'spanish': 'Spanish',
      'fre': 'French', 'fr': 'French', 'french': 'French',
      'ger': 'German', 'de': 'German', 'german': 'German',
      'por': 'Portuguese', 'pt': 'Portuguese', 'portuguese': 'Portuguese',
      'ita': 'Italian', 'it': 'Italian', 'italian': 'Italian',
      'rus': 'Russian', 'ru': 'Russian', 'russian': 'Russian',
      'ara': 'Arabic', 'ar': 'Arabic', 'arabic': 'Arabic',
      'hin': 'Hindi', 'hi': 'Hindi', 'hindi': 'Hindi',
      'tha': 'Thai', 'th': 'Thai', 'thai': 'Thai',
      'vie': 'Vietnamese', 'vi': 'Vietnamese', 'vietnamese': 'Vietnamese',
      'ind': 'Indonesian', 'id': 'Indonesian', 'indonesian': 'Indonesian',
      'may': 'Malay', 'ms': 'Malay', 'malay': 'Malay',
      'tur': 'Turkish', 'tr': 'Turkish', 'turkish': 'Turkish',
      'pol': 'Polish', 'pl': 'Polish', 'polish': 'Polish',
      'nld': 'Dutch', 'nl': 'Dutch', 'dutch': 'Dutch',
      'swe': 'Swedish', 'sv': 'Swedish', 'swedish': 'Swedish',
      'nor': 'Norwegian', 'no': 'Norwegian', 'norwegian': 'Norwegian',
      'dan': 'Danish', 'da': 'Danish', 'danish': 'Danish',
      'fin': 'Finnish', 'fi': 'Finnish', 'finnish': 'Finnish',
      'ukr': 'Ukrainian', 'uk': 'Ukrainian', 'ukrainian': 'Ukrainian',
      'rum': 'Romanian', 'ro': 'Romanian', 'romanian': 'Romanian',
      'hun': 'Hungarian', 'hu': 'Hungarian', 'hungarian': 'Hungarian',
      'cze': 'Czech', 'cs': 'Czech', 'czech': 'Czech',
      'bra': 'Portuguese (BR)', 'pt-BR': 'Portuguese (BR)',
      'lat': 'Spanish (LAT)', 'es-419': 'Spanish (LAT)',
    };

    final matched = <TorrentAudioTrack>[];
    for (final audio in audioFiles) {
      final audioName = audio.name.replaceAll(RegExp(r'\.[^.]+$'), '').toLowerCase();
      final videoLower = videoBaseName.toLowerCase();

      if (audioName == videoLower ||
          audioName.startsWith(videoLower) ||
          videoLower.startsWith(audioName)) {
        String lang = 'Unknown';
        String label = 'Audio';
        final nameLower = audio.name.toLowerCase();

        if (nameLower.contains('.ja.') || nameLower.contains('.jpn.') || nameLower.contains('.japanese.')) {
          lang = 'Japanese';
          label = 'Japanese';
        } else if (nameLower.contains('.en.') || nameLower.contains('.eng.') || nameLower.contains('.english.')) {
          lang = 'English';
          label = 'English';
        } else {
          for (final entry in langMap.entries) {
            if (nameLower.contains(entry.key)) {
              lang = entry.value;
              label = entry.value;
              break;
            }
          }
        }

        final ext = audio.path.split('.').last.toLowerCase();
        final codecMap = {
          'flac': 'FLAC', 'aac': 'AAC', 'ac3': 'AC3', 'eac3': 'E-AC3',
          'dts': 'DTS', 'dtshd': 'DTS-HD', 'truehd': 'TrueHD', 'thd': 'TrueHD',
          'opus': 'Opus', 'ogg': 'OGG', 'wav': 'WAV', 'wma': 'WMA',
          'm4a': 'AAC', 'mp3': 'MP3', 'alac': 'ALAC', 'ape': 'APE',
          'tak': 'TAK', 'tta': 'TTA', 'wv': 'WavPack', 'lpcm': 'LPCM',
          'pcm': 'PCM', 'aiff': 'AIFF', 'mka': 'MKA',
        };
        final codec = codecMap[ext] ?? ext.toUpperCase();

        if (nameLower.contains('dub') || nameLower.contains('dubbed')) {
          label = '$label (Dub)';
        }
        if (nameLower.contains('commentary')) {
          label = '$label (Commentary)';
        }

        matched.add(TorrentAudioTrack(
          fileIndex: audio.index,
          fileName: audio.name,
          language: lang,
          label: label,
          codec: codec,
        ));
      }
    }
    return matched;
  }

  static Future<String> _getDownloadPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final torrentDir = Directory(p.join(dir.path, 'torrent_cache'));
    if (!await torrentDir.exists()) {
      await torrentDir.create(recursive: true);
    }
    return torrentDir.path;
  }

  static const _videoExtensions = {
    'mkv', 'mp4', 'avi', 'webm', 'mov', 'wmv', 'flv', 'ts', 'm4v', 'ogv',
    'mpg', 'mpeg', 'mpe', 'mpv', '3gp', '3g2', 'rmvb', 'divx', 'vob',
    'f4v', 'h264', 'h265', 'hevc', 'm2ts', 'mts', 'm2t', 'tivo', 'ogm',
    'asf', 'asx', 'dat', 'vro', 'rec', 'wtv', 'xvid', 'prores',
    'swf', 'ivf', 'gxf', 'mxf', 'nut', 'mk3d',
  };

  static const _audioExtensions = {
    'aac', 'flac', 'ogg', 'opus', 'wav', 'wma', 'm4a', 'mp3', 'ac3',
    'eac3', 'dts', 'dtshd', 'truehd', 'thd', 'lpcm', 'pcm', 'alac',
    'amr', 'awb', 'ape', 'tak', 'wv', 'tta', 'mka', 'mpa', 'mp2',
    'm2a', 'aiff', 'aif', 'aifc', 'snd', 'au', 'ra', 'mid', 'midi',
    'oga', 'm4b', 'm4p',
  };

  static const _subtitleExtensions = {
    'srt', 'ass', 'ssa', 'vtt', 'sub', 'sup', 'idx', 'lrc', 'sbv',
    'smi', 'sami', 'rt', 'dfxp', 'ttml', 'stl', 'pjs', 'psb', 'jss',
    'ssf', 'usf', 'cdg', 'ktv', 'mks',
  };

  static bool _isVideoExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    return _videoExtensions.contains(ext);
  }

  static bool _isAudioExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    return _audioExtensions.contains(ext);
  }

  static bool _isSubtitleExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    return _subtitleExtensions.contains(ext);
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }
}

class TorrentSubtitle {
  final int fileIndex;
  final String fileName;
  final String language;

  const TorrentSubtitle({
    required this.fileIndex,
    required this.fileName,
    required this.language,
  });
}

class TorrentAudioTrack {
  final int fileIndex;
  final String fileName;
  final String language;
  final String label;
  final String codec;

  const TorrentAudioTrack({
    required this.fileIndex,
    required this.fileName,
    required this.language,
    required this.label,
    required this.codec,
  });
}

class ResolvedStream {
  final String streamUrl;
  final String infoHash;
  final String fileName;
  final List<TorrentSubtitle> subtitles;
  final List<TorrentAudioTrack> audioTracks;

  const ResolvedStream({
    required this.streamUrl,
    required this.infoHash,
    required this.fileName,
    this.subtitles = const [],
    this.audioTracks = const [],
  });
}

class TorrentProgress {
  final String infoHash;
  final int downloadSpeed;
  final int uploadSpeed;
  final double progress;
  final int peers;
  final int seeds;

  const TorrentProgress({
    required this.infoHash,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.progress,
    required this.peers,
    required this.seeds,
  });

  String get formattedDownloadSpeed => '${_fmt(downloadSpeed)}/s';
  String get formattedUploadSpeed => '${_fmt(uploadSpeed)}/s';
  String get formattedProgress => '${(progress * 100).toStringAsFixed(1)}%';

  static String _fmt(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }
}

class TorrentFileInfo {
  final int index;
  final String name;
  final String path;
  final int size;
  final bool isVideo;

  const TorrentFileInfo({
    required this.index,
    required this.name,
    required this.path,
    required this.size,
    required this.isVideo,
  });
}

class _TorrentSession {
  final int torrentId;
  final String streamUrl;
  final String fileName;
  final String originalUrl;
  final int fileIndex;

  _TorrentSession({
    required this.torrentId,
    required this.streamUrl,
    required this.fileName,
    required this.originalUrl,
    required this.fileIndex,
  });
}
