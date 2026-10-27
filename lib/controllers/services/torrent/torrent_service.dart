import 'dart:async';
import 'dart:math' as math;
import 'package:anymex/widgets/non_widgets/torrent_server_overlay.dart';
import 'package:anymex_extension_runtime_bridge/AddonManager.dart';
import 'package:anymex_extension_runtime_bridge/Engines/TorrentEngine/Models/TorrentInfo.dart';
import 'package:anymex_extension_runtime_bridge/Engines/TorrentEngine/TorrServerAddon.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

class TorrentService {
  static final TorrentService instance = TorrentService._();
  TorrentService._();

  static const _videoExtensions = {
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.webm',
    '.m4v',
    '.flv',
    '.wmv',
    '.ts',
  };

  int _activeStreams = 0;
  int _activeDownloads = 0;
  Timer? _autoStopTimer;

  TorrServerAddon get addon {
    final manager = Get.isRegistered<AddonManager>()
        ? Get.find<AddonManager>()
        : Get.put(AddonManager());
    return manager.get<TorrServerAddon>();
  }

  TorrentInfo? get activeTorrent => addon.activeTorrent;
  TorrentFileStat? get activeFile => addon.activeFile;
  String? get activeHash => addon.activeHash;

  String switchStreamFile(int fileIndex) {
    final hash = addon.activeHash;
    if (hash == null) {
      throw StateError("No active torrent");
    }
    addon.switchStreamFile(fileIndex);
    return addon.fileUrl(hash, fileIndex).toString();
  }

  Future<TorrentInfo?> refreshActiveTorrent() async {
    return addon.refreshActiveTorrent();
  }

  List<TorrentFileStat> get activeTorrentFiles {
    final torrent = activeTorrent;
    if (torrent == null) return [];
    final videos = torrent.fileStats.where((file) {
      return _videoExtensions.contains(p.extension(file.path).toLowerCase());
    }).toList();
    if (videos.isNotEmpty) {
      videos.sort((a, b) => a.path.compareTo(b.path));
      return videos;
    }
    final all = List<TorrentFileStat>.from(torrent.fileStats)
      ..sort((a, b) => a.path.compareTo(b.path));
    return all;
  }

  Future<TorrServerAddon> ensureTorrServerReady({
    String contextMessage = 'Preparing torrent playback...',
  }) async {
    _autoStopTimer?.cancel();
    final torr = addon;
    final isInstalled = await torr.isInstalled();

    if (!isInstalled) {
      TorrentServerOverlay.show(
        addon: torr,
        status: 'Downloading Torrent Server...',
      );

      try {
        await torr.install();
        TorrentServerOverlay.updateStatus('Starting Torrent Server...');
      } catch (e) {
        TorrentServerOverlay.showError('Failed to download server: $e');
        rethrow;
      }
    }

    try {
      if (!torr.isRunning) {
        TorrentServerOverlay.updateStatus('Starting Torrent Server...');
        await torr.ensureStarted();
      }
    } catch (e) {
      TorrentServerOverlay.showError('Failed to start server: $e');
      rethrow;
    }

    return torr;
  }

  Future<String> startStream({
    required String url,
    required String title,
    String? episode,
    int? preferredFileIndex,
  }) async {
    _autoStopTimer?.cancel();
    final torr = await ensureTorrServerReady(
      contextMessage: 'Preparing torrent stream...',
    );

    TorrentServerOverlay.updateStatus('Resolving torrent stream...');
    _activeStreams++;

    try {
      final streamUrl = await torr.startStream(
        url: url,
        title: title,
        episode: episode,
        preferredFileIndex: preferredFileIndex,
      );
      TorrentServerOverlay.dismiss();
      return streamUrl;
    } catch (e) {
      _activeStreams = math.max(0, _activeStreams - 1);
      TorrentServerOverlay.showError('Failed to start torrent: $e');
      _scheduleAutoStop();
      rethrow;
    }
  }

  Future<void> stopStream() async {
    try {
      await addon.stopStream();
    } catch (_) {}
    _activeStreams = math.max(0, _activeStreams - 1);
    _scheduleAutoStop();
  }

  Future<TorrServerAddon> acquireDownload() async {
    _autoStopTimer?.cancel();
    final torr = await ensureTorrServerReady(
      contextMessage: 'Preparing torrent download...',
    );
    _activeDownloads++;
    TorrentServerOverlay.dismiss();
    return torr;
  }

  Future<void> releaseDownload(String hash) async {
    try {
      await addon.release(hash);
    } catch (_) {}
    _activeDownloads = math.max(0, _activeDownloads - 1);
    _scheduleAutoStop();
  }

  void _scheduleAutoStop() {
    if (_activeStreams == 0 && _activeDownloads == 0) {
      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(const Duration(seconds: 15), () async {
        if (_activeStreams == 0 && _activeDownloads == 0) {
          try {
            if (addon.isRunning) {
              await addon.stop();
            }
          } catch (_) {}
        }
      });
    }
  }

  static TorrentFileStat? pickStreamableFile(
    TorrentInfo info, {
    String? episode,
    int? preferredFileIndex,
  }) {
    final streamable = info.fileStats.where((file) {
      return _videoExtensions.contains(
        p.extension(file.path).toLowerCase(),
      );
    }).toList();

    if (streamable.isEmpty) return null;

    if (preferredFileIndex != null) {
      for (final file in streamable) {
        if (file.id == preferredFileIndex) return file;
      }
    }

    if (episode != null) {
      final matched = _findFileForEpisode(streamable, episode);
      if (matched != null) return matched;
    }

    TorrentFileStat? selected;
    for (final file in streamable) {
      if (selected == null || file.length > selected.length) {
        selected = file;
      }
    }

    return selected;
  }

  static TorrentFileStat? _findFileForEpisode(
    List<TorrentFileStat> files,
    String episode,
  ) {
    final intEp = int.tryParse(episode);
    if (intEp == null) return null;

    final normalizedEpisode = intEp.toString();
    final paddedEpisode = intEp.toString().padLeft(2, '0');

    final epPattern = RegExp(
      r'\b(?:e|ep|episode|ep\.)\s*0*' + normalizedEpisode + r'\b',
      caseSensitive: false,
    );

    for (final file in files) {
      final name = p.basename(file.path).toLowerCase();
      if (epPattern.hasMatch(name)) {
        return file;
      }
    }

    for (final file in files) {
      final name = p.basename(file.path).toLowerCase();
      final matches = RegExp(r'\b\d+\b').allMatches(name);
      for (final match in matches) {
        final numStr = match.group(0);
        if (numStr == null) continue;
        final numVal = int.tryParse(numStr);
        if (numVal == intEp) {
          if (intEp == 720 ||
              intEp == 1080 ||
              intEp == 2160 ||
              intEp == 480 ||
              (intEp >= 1990 && intEp <= 2030)) {
            continue;
          }
          return file;
        }
      }
    }

    for (final file in files) {
      final name = p.basename(file.path).toLowerCase();
      if (name.contains('e$paddedEpisode') ||
          name.contains('ep$paddedEpisode') ||
          name.contains('episode $paddedEpisode') ||
          name.contains('e$normalizedEpisode') ||
          name.contains('ep$normalizedEpisode') ||
          name.contains('episode $normalizedEpisode')) {
        return file;
      }
    }

    return null;
  }
}
