import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/database/isar_models/video.dart' as local_video;
import 'package:anymex/screens/anime/watch/watch_view.dart';
import 'package:anymex/screens/manga/reading_page.dart';
import 'package:anymex/screens/novel/reader/novel_reader.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/m3u8_parser.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

typedef _LogFn = void Function(String message);

class HistoryModel {
  OfflineMedia? media;
  String? title;
  String cover;
  String poster;
  String? sourceName;
  String? formattedEpisodeTitle;
  num? progress;
  num? totalProgress;
  String? progressTitle;
  bool? isManga;
  double? calculatedProgress;
  VoidCallback? onTap;
  String? progressText;
  String? date;

  HistoryModel(
      {this.media,
      this.title,
      required this.cover,
      required this.poster,
      this.formattedEpisodeTitle,
      this.sourceName,
      this.progress,
      this.totalProgress,
      this.progressTitle,
      this.isManga,
      this.calculatedProgress,
      this.onTap,
      this.progressText,
      this.date});

  factory HistoryModel.fromOfflineMedia(OfflineMedia media, ItemType type) {
    final onTap = _buildHistoryTapHandler(media, type);

    final isManga = !type.isAnime;
    return HistoryModel(
        media: media,
        title: media.name,
        cover: media.currentEpisode?.thumbnail ?? media.cover ?? media.poster!,
        poster: media.poster!,
        formattedEpisodeTitle: formatEpChapTitle(
            isManga
                ? media.currentChapter?.number
                : media.currentEpisode?.number,
            isManga),
        sourceName: isManga
            ? media.currentChapter?.sourceName
            : media.currentEpisode?.source,
        progress: isManga
            ? media.currentChapter?.pageNumber
            : media.currentEpisode?.timeStampInMilliseconds,
        totalProgress: isManga
            ? media.currentChapter?.totalPages
            : media.currentEpisode?.durationInMilliseconds,
        progressTitle:
            isManga ? media.currentChapter?.title : media.currentEpisode?.title,
        isManga: isManga,
        calculatedProgress: isManga
            ? calculateProgress(media.currentChapter?.pageNumber,
                media.currentChapter?.totalPages)
            : calculateProgress(
                media.currentEpisode?.timeStampInMilliseconds,
                media.currentEpisode?.durationInMilliseconds,
              ),
        onTap: onTap,
        date: formattedDate(isManga
            ? media.currentChapter?.lastReadTime ?? 0
            : media.currentEpisode?.lastWatchedTime ?? 0),
        progressText: formatProgressText(media, isManga));
  }
  @override
  String toString() {
    return '''
HistoryModel(
  title: $title,
  cover: $cover,
  poster: $poster,
  sourceName: $sourceName,
  formattedEpisodeTitle: $formattedEpisodeTitle,
  progress: $progress,
  totalProgress: $totalProgress,
  progressTitle: $progressTitle,
  isManga: $isManga,
  calculatedProgress: $calculatedProgress,
  progressText: $progressText,
  date: $date
)
  ''';
  }
}

VoidCallback _buildHistoryTapHandler(OfflineMedia media, ItemType type) {
  return () async {
    await _handleHistoryTap(media, type);
  };
}

Future<void> _handleHistoryTap(OfflineMedia media, ItemType type) async {
  switch (type) {
    case ItemType.anime:
      await _handleAnimeTap(media);
      return;
    case ItemType.manga:
      await _handleMangaTap(media);
      return;
    case ItemType.novel:
      await _handleNovelTap(media);
      return;
  }
}

Future<void> _handleMangaTap(OfflineMedia media) async {
  final chapter = media.currentChapter;
  if (chapter == null) {
    snackBar(
      "Error: Missing required media. It seems you closed the app directly after reading the chapter!",
      maxLines: 3,
    );
    return;
  }

  final sourceName = chapter.sourceName;
  if (sourceName == null || sourceName.isEmpty) {
    snackBar("Cant Play since user closed the app abruptly");
    return;
  }

  final source =
      Get.find<SourceController>().getMangaExtensionByName(sourceName);
  if (source == null) {
    snackBar("Install $sourceName First, Then Click");
    return;
  }

  var chapters = media.chapters ?? [];
  if (chapters.length <= 1) {
    Get.dialog(
      const Center(child: AnymexProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      final mediaModel = convertOfflineToMedia(media);
      final details = await source.methods
          .getDetail(DMedia.withUrl(mediaModel.id.toString()));
      if (details.episodes != null && details.episodes!.isNotEmpty) {
        chapters = DEpisodeToChapter(
          details.episodes!.reversed.toList(),
          details.title ?? media.name ?? '',
        );
      }
    } catch (e) {
      Logger.i("Error fetching chapters: $e");
    } finally {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }
  }

  navigate(() => ReadingPage(
        anilistData: convertOfflineToMedia(media),
        chapterList: chapters,
        currentChapter: chapter,
        shouldTrack: true,
      ));
}

Future<void> _handleNovelTap(OfflineMedia media) async {
  final chapter = media.currentChapter;
  if (chapter == null || media.chapters == null) {
    snackBar(
      "Error: Missing required media. It seems you closed the app directly after reading the chapter!",
      maxLines: 3,
    );
    return;
  }

  final sourceName = chapter.sourceName;
  if (sourceName == null || sourceName.isEmpty) {
    snackBar("Cant Read since user closed the app abruptly");
    return;
  }

  final source =
      Get.find<SourceController>().getNovelExtensionByName(sourceName);
  if (source == null) {
    snackBar("Install $sourceName First, Then Click");
    return;
  }

  navigate(() => NovelReader(
        chapter: chapter,
        chapters: media.chapters ?? [],
        media: convertOfflineToMedia(media),
        source: source,
      ));
}

Future<void> _handleAnimeTap(OfflineMedia media) async {
  final currentEpisode = media.currentEpisode;
  final episodeList = media.episodes;
  if (currentEpisode == null ||
      currentEpisode.currentTrack == null ||
      episodeList == null) {
    snackBar(
      "Error: Missing required media. It seems you closed the app directly after watching the episode!",
      duration: 2000,
      maxLines: 3,
    );
    return;
  }

  final sourceName = currentEpisode.source;
  if (sourceName == null || sourceName.isEmpty) {
    snackBar("Cant Play since user closed the app abruptly");
    return;
  }

  final source = Get.find<SourceController>().getExtensionByValue(sourceName);
  if (source == null) {
    snackBar("Install $sourceName First, Then Click");
    return;
  }

  final logSession = _LoaderLogSession();
  logSession.show();
  logSession.log("Preparing playback...");
  logSession.log("Checking saved stream URL...");
  try {
    final playbackData = await _resolveAnimePlaybackData(
        media: media, source: source, log: logSession.log);
    if (playbackData == null) {
      logSession.log("Playback preparation failed.");
      return;
    }

    logSession.log("Playback is ready.");
    logSession.close();

    navigate(() => WatchScreen(
          episodeSrc: playbackData.currentTrack,
          episodeList: episodeList,
          anilistData: convertOfflineToMedia(media),
          currentEpisode: currentEpisode,
          episodeTracks: playbackData.tracks,
        ));
  } catch (e) {
    Logger.i("Error preparing anime playback: $e");
    logSession.log("Failed to prepare playback.");
    snackBar("Unable to prepare playback right now. Please try again.");
  } finally {
    logSession.close();
  }
}

Future<_AnimePlaybackData?> _resolveAnimePlaybackData({
  required OfflineMedia media,
  required Source source,
  required _LogFn log,
}) async {
  final currentEpisode = media.currentEpisode!;
  var tracks =
      List<local_video.Video>.from(currentEpisode.videoTracks ?? const []);

  final firstStoredTrack = tracks.isNotEmpty ? tracks.first : null;
  final isStoredLinkValid = await _pingVideoUrl(firstStoredTrack, log: log);

  if (!isStoredLinkValid) {
    log("Saved link is expired.");
    snackBar("Saved stream link has expired. Fetching a new link...");
    log("Fetching fresh stream URLs from source...");

    final episodeUrl = currentEpisode.link ?? "";
    if (episodeUrl.isEmpty) {
      log("Episode URL is missing.");
      snackBar("Link has expired and episode URL is unavailable.");
      return null;
    }

    final refreshedVideos = await source.methods.getVideoList(
      DEpisode(
        url: episodeUrl,
        episodeNumber: currentEpisode.number,
      ),
    );

    if (refreshedVideos.isEmpty) {
      log("Source returned no stream URLs.");
      snackBar("Link has expired and no alternative stream was found.");
      return null;
    }

    log("Received ${refreshedVideos.length} stream option(s).");
    tracks = refreshedVideos
        .map(local_video.Video.fromVideo)
        .where((video) => (video.url ?? '').isNotEmpty)
        .toList();
    if (tracks.isEmpty) {
      log("No playable URL in returned streams.");
      snackBar("No playable stream was returned by this source.");
      return null;
    }
  } else {
    log("Saved stream URL is valid.");
  }

  log("Choosing best quality/track...");
  final selectedTrack = _selectTrack(
    tracks: tracks,
    previousTrack: currentEpisode.currentTrack,
  );
  if (selectedTrack == null) {
    log("No playable track selected.");
    snackBar("No playable stream available for this episode.");
    return null;
  }

  currentEpisode.videoTracks = tracks;
  currentEpisode.currentTrack = selectedTrack;
  log("Selected stream: ${selectedTrack.quality ?? 'Auto'}");

  return _AnimePlaybackData(currentTrack: selectedTrack, tracks: tracks);
}

local_video.Video? _selectTrack({
  required List<local_video.Video> tracks,
  required local_video.Video? previousTrack,
}) {
  if (tracks.isEmpty) return null;
  if (previousTrack == null) return tracks.first;

  for (final track in tracks) {
    if (track.url == previousTrack.url && (track.url ?? '').isNotEmpty) {
      return track;
    }
  }
  for (final track in tracks) {
    if (track.quality == previousTrack.quality &&
        (track.url ?? '').isNotEmpty) {
      return track;
    }
  }

  return tracks.first;
}

Future<bool> _pingVideoUrl(
  local_video.Video? video, {
  required _LogFn log,
}) async {
  final url = video?.url?.trim();
  if (url == null || url.isEmpty) {
    log("Saved URL is empty.");
    return false;
  }
  log("Checking URL availability...");

  final uri = Uri.tryParse(url);
  if (uri == null) {
    log("Saved URL format is invalid.");
    return false;
  }

  var headContentType = '';
  try {
    final headResponse = await http
        .head(uri, headers: video?.headers ?? const {})
        .timeout(const Duration(seconds: 8));
    headContentType = headResponse.headers['content-type'] ?? '';

    if (headResponse.statusCode >= 200 && headResponse.statusCode < 400) {
      log("URL responded successfully.");
      final shouldValidateM3u8 =
          _looksLikeM3u8(uri.toString()) || _isM3u8ContentType(headContentType);
      if (!shouldValidateM3u8) {
        return true;
      }

      log("Checking stream playlist...");
      final firstSegmentUri = await _resolveFirstM3u8Segment(
        uri: uri,
        headers: video?.headers,
        log: log,
      );
      if (firstSegmentUri == null) {
        log("Unable to parse playable segment from playlist.");
        return false;
      }
      log("Checking first stream segment...");
      return _pingUri(firstSegmentUri, headers: video?.headers);
    }
  } catch (_) {}

  try {
    log("HEAD check failed. Trying fallback request...");
    final getHeaders = <String, String>{
      ...?video?.headers,
      'Range': 'bytes=0-0',
    };
    final getResponse = await http
        .get(uri, headers: getHeaders)
        .timeout(const Duration(seconds: 8));

    final statusCode = getResponse.statusCode;
    final ok = (statusCode >= 200 && statusCode < 400) || statusCode == 416;
    if (!ok) {
      log("URL is not reachable.");
      return false;
    }

    log("URL reachable via fallback request.");
    final contentType = getResponse.headers['content-type'] ?? headContentType;
    final shouldValidateM3u8 =
        _looksLikeM3u8(uri.toString()) || _isM3u8ContentType(contentType);
    if (!shouldValidateM3u8) {
      return true;
    }

    log("Checking stream playlist...");
    final firstSegmentUri = await _resolveFirstM3u8Segment(
      uri: uri,
      headers: video?.headers,
      cachedBody: getResponse.body,
      log: log,
    );
    if (firstSegmentUri == null) {
      log("Unable to parse playable segment from playlist.");
      return false;
    }
    log("Checking first stream segment...");
    return _pingUri(firstSegmentUri, headers: video?.headers);
  } catch (_) {
    log("URL check failed due to network error.");
    return false;
  }
}

bool _looksLikeM3u8(String url) {
  return url.toLowerCase().contains('.m3u8');
}

bool _isM3u8ContentType(String contentType) {
  final lower = contentType.toLowerCase();
  return lower.contains('application/vnd.apple.mpegurl') ||
      lower.contains('application/x-mpegurl') ||
      lower.contains('audio/mpegurl') ||
      lower.contains('audio/x-mpegurl');
}

Future<Uri?> _resolveFirstM3u8Segment({
  required Uri uri,
  required Map<String, String>? headers,
  required _LogFn log,
  String? cachedBody,
}) async {
  log("Reading playlist...");
  final playlistText =
      cachedBody ?? await _fetchText(uri: uri, headers: headers);
  if (playlistText == null || playlistText.isEmpty) {
    return null;
  }

  final parsed = parseM3u8Playlist(playlistText);
  if (parsed == null) {
    return null;
  }

  if (parsed.firstVariant != null) {
    log("Master playlist found. Opening first variant...");
    final variantUri = uri.resolve(parsed.firstVariant!);
    return _resolveFirstM3u8Segment(
      uri: variantUri,
      headers: headers,
      log: log,
    );
  }

  if (parsed.segments.isEmpty) {
    return null;
  }
  log("First segment found.");
  return uri.resolve(parsed.segments.first);
}

Future<String?> _fetchText({
  required Uri uri,
  required Map<String, String>? headers,
}) async {
  try {
    final response = await http
        .get(uri, headers: headers ?? const {})
        .timeout(const Duration(seconds: 8));
    if (response.statusCode >= 200 && response.statusCode < 400) {
      return response.body;
    }
  } catch (_) {
    return null;
  }
  return null;
}

Future<bool> _pingUri(
  Uri uri, {
  required Map<String, String>? headers,
}) async {
  try {
    final head = await http
        .head(uri, headers: headers ?? const {})
        .timeout(const Duration(seconds: 8));
    if (head.statusCode >= 200 && head.statusCode < 400) {
      return true;
    }
  } catch (_) {}

  try {
    final getHeaders = <String, String>{
      ...?headers,
      'Range': 'bytes=0-0',
    };
    final get = await http
        .get(uri, headers: getHeaders)
        .timeout(const Duration(seconds: 8));
    return (get.statusCode >= 200 && get.statusCode < 400) ||
        get.statusCode == 416;
  } catch (_) {
    return false;
  }
}

class _AnimePlaybackData {
  final local_video.Video currentTrack;
  final List<local_video.Video> tracks;

  const _AnimePlaybackData({
    required this.currentTrack,
    required this.tracks,
  });
}

class _LoaderLogSession {
  final RxList<String> _logs = <String>[].obs;
  var _isClosed = false;

  void show() {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 360),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    AnymexProgressIndicator(),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Preparing stream',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(
                    () => ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (_, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void log(String message) {
    if (_isClosed) return;
    _logs.add(message);
  }

  void close() {
    if (_isClosed) return;
    _isClosed = true;
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }
}

double calculateProgress(int? min, int? max) {
  if (min == null || max == null) {
    return 0.0;
  }

  return (min / max).clamp(0.0, 1.0);
}

String formatEpChapTitle(dynamic title, bool isManga) {
  final newTitle = title?.toString() ?? '??';
  return isManga ? 'Chapter $newTitle' : 'Episode $newTitle';
}

String formattedDate(int milliseconds) {
  return formatTimeAgo(milliseconds);
}

String formatProgressText(OfflineMedia data, bool isManga) {
  if (isManga) {
    return 'PAGE ${data.currentChapter?.pageNumber ?? '0'} / ${data.currentChapter?.totalPages ?? '??'}';
  } else {
    if (data.currentEpisode?.durationInMilliseconds == null ||
        data.currentEpisode?.timeStampInMilliseconds == null) {
      return '--:--';
    }

    final duration = data.currentEpisode!.durationInMilliseconds ?? 0;
    final timestamp = data.currentEpisode!.timeStampInMilliseconds ?? 0;
    final timeLeft = Duration(milliseconds: duration - timestamp);

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final minutes = twoDigits(timeLeft.inMinutes.remainder(60));
    final seconds = twoDigits(timeLeft.inSeconds.remainder(60));
    final hours = (timeLeft.inHours);

    if (hours > 0) return '${twoDigits(hours)}:$minutes:$seconds left';

    return '$minutes:$seconds left';
  }
}
