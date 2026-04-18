import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/episode.dart';

enum DownloadStatus {
  queued,
  downloading,
  completed,
  failed,
  cancelled,
  paused
}

enum VideoLinkType { direct, hls, unknown }

VideoLinkType detectLinkType(String url) {
  final lower = url.toLowerCase().split('?').first;
  if (lower.contains('.m3u8') ||
      lower.contains('/m3u8') ||
      lower.contains('playlist.m3u')) {
    return VideoLinkType.hls;
  }
  if (lower.endsWith('.mp4') ||
      lower.endsWith('.mkv') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.mov')) {
    return VideoLinkType.direct;
  }
  return VideoLinkType.unknown;
}

class DownloadResult {
  final bool success;
  final String? filePath;
  final String? error;

  const DownloadResult({required this.success, this.filePath, this.error});
}

class ActiveDownloadTask {
  String taskId;
  String mediaTitle;
  String extensionName;
  Episode episode;
  String videoUrl;
  String videoQuality;
  Map<String, String>? videoHeaders;
  VideoLinkType linkType;
  DownloadStatus status;
  double progress;
  String? filePath;
  String? errorMessage;

  ActiveDownloadTask({
    required this.taskId,
    required this.mediaTitle,
    required this.extensionName,
    required this.episode,
    required this.videoUrl,
    required this.videoQuality,
    this.videoHeaders,
    required this.linkType,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.filePath,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'mediaTitle': mediaTitle,
        'extensionName': extensionName,
        'episode': episode.toJson(),
        'videoUrl': videoUrl,
        'videoQuality': videoQuality,
        'videoHeaders': videoHeaders,
        'linkType': linkType.index,
        'status': status.index,
        'progress': progress,
        'filePath': filePath,
        'errorMessage': errorMessage,
      };

  factory ActiveDownloadTask.fromJson(Map<String, dynamic> json) =>
      ActiveDownloadTask(
        taskId: json['taskId'] as String? ?? '',
        mediaTitle: json['mediaTitle'] as String? ?? '',
        extensionName: json['extensionName'] as String? ?? '',
        episode: Episode.fromJson(json['episode'] as Map<String, dynamic>),
        videoUrl: json['videoUrl'] as String? ?? '',
        videoQuality: json['videoQuality'] as String? ?? '',
        videoHeaders: (json['videoHeaders'] as Map<dynamic, dynamic>?)
            ?.map((k, v) => MapEntry(k.toString(), v.toString())),
        linkType: VideoLinkType.values[json['linkType'] as int? ?? 0],
        status: DownloadStatus.values[json['status'] as int? ?? 0],
        progress: (json['progress'] as num? ?? 0.0).toDouble(),
        filePath: json['filePath'] as String?,
        errorMessage: json['errorMessage'] as String?,
      );

  String get episodeDisplayId {
    final sortPart = episode.sortMap.isNotEmpty
        ? ' (${episode.sortMap.values.join(', ')})'
        : '';
    return 'Ep ${episode.number}$sortPart';
  }
}

class DownloadedEpisodeMeta {
  final Episode episode;
  final String fileName;
  final int downloadedAt;
  final String filePath;
  final String? quality;

  const DownloadedEpisodeMeta({
    required this.episode,
    required this.fileName,
    required this.downloadedAt,
    required this.filePath,
    this.quality,
  });

  Map<String, dynamic> toJson() => {
        'episode': episode.toJson(),
        'fileName': fileName,
        'downloadedAt': downloadedAt,
        'filePath': filePath,
        'quality': quality,
      };

  factory DownloadedEpisodeMeta.fromJson(Map<String, dynamic> json) =>
      DownloadedEpisodeMeta(
        episode: Episode.fromJson(json['episode'] as Map<String, dynamic>),
        fileName: json['fileName'] as String? ?? '',
        downloadedAt: json['downloadedAt'] as int? ?? 0,
        filePath: json['filePath'] as String? ?? '',
        quality: json['quality'] as String?,
      );

  String get number => episode.number;
  String? get title => episode.title;
  String? get thumbnail => episode.thumbnail;
  Map<String, String> get sortMap => episode.sortMap;
  String get displayId {
    if (sortMap.isNotEmpty) return 'Ep $number (${sortMap.values.join(', ')})';
    return title ?? 'Episode $number';
  }
}

class DownloadedMediaSummary {
  final String title;
  final String? poster;
  final String extensionName;
  final String folderName;
  final String mediaType;

  const DownloadedMediaSummary({
    required this.title,
    this.poster,
    required this.extensionName,
    required this.folderName,
    this.mediaType = 'Anime',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'poster': poster,
        'extensionName': extensionName,
        'folderName': folderName,
        'mediaType': mediaType,
      };

  factory DownloadedMediaSummary.fromJson(Map<String, dynamic> json) =>
      DownloadedMediaSummary(
        title: json['title'] as String? ?? '',
        poster: json['poster'] as String?,
        extensionName: json['extensionName'] as String? ?? '',
        folderName: json['folderName'] as String? ?? '',
        mediaType: json['mediaType'] as String? ?? 'Anime',
      );
}

class DownloadedMediaMeta {
  final List<DownloadedEpisodeMeta> episodes;
  final Map<String, int> watchedProgress;

  const DownloadedMediaMeta({
    required this.episodes,
    this.watchedProgress = const {},
  });

  Map<String, dynamic> toJson() => {
        'episodes': episodes.map((e) => e.toJson()).toList(),
        'watchedProgress': watchedProgress,
      };

  factory DownloadedMediaMeta.fromJson(Map<String, dynamic> json) =>
      DownloadedMediaMeta(
        episodes: (json['episodes'] as List<dynamic>? ?? [])
            .map((e) =>
                DownloadedEpisodeMeta.fromJson(e as Map<String, dynamic>))
            .toList(),
        watchedProgress: (json['watchedProgress'] as Map<dynamic, dynamic>?)
                ?.map((k, v) => MapEntry(k.toString(), v as int)) ??
            {},
      );
}

class DownloadedChapterMeta {
  final Chapter chapter;
  final String imageDir;
  final int pageCount;
  final int downloadedAt;

  const DownloadedChapterMeta({
    required this.chapter,
    required this.imageDir,
    required this.pageCount,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'chapter': chapter.toJson(),
        'imageDir': imageDir,
        'pageCount': pageCount,
        'downloadedAt': downloadedAt,
      };

  factory DownloadedChapterMeta.fromJson(Map<String, dynamic> json) =>
      DownloadedChapterMeta(
        chapter: Chapter.fromJson(json['chapter'] as Map<String, dynamic>),
        imageDir: json['imageDir'] as String? ?? '',
        pageCount: json['pageCount'] as int? ?? 0,
        downloadedAt: json['downloadedAt'] as int? ?? 0,
      );

  String get displayTitle {
    final num = chapter.number;
    final t = chapter.title;
    if (t != null && t.isNotEmpty) return t;
    if (num != null) return 'Chapter ${num % 1 == 0 ? num.toInt() : num}';
    return 'Chapter';
  }
}

class DownloadedMangaMeta {
  final List<DownloadedChapterMeta> chapters;

  const DownloadedMangaMeta({required this.chapters});

  Map<String, dynamic> toJson() => {
        'chapters': chapters.map((c) => c.toJson()).toList(),
      };

  factory DownloadedMangaMeta.fromJson(Map<String, dynamic> json) =>
      DownloadedMangaMeta(
        chapters: (json['chapters'] as List<dynamic>? ?? [])
            .map((e) =>
                DownloadedChapterMeta.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

enum MangaDownloadStatus {
  queued,
  fetchingPages,
  downloading,
  completed,
  failed,
  cancelled,
  paused,
}

class ActiveMangaDownloadTask {
  String taskId;
  String mediaTitle;
  String extensionName;
  Chapter chapter;
  MangaDownloadStatus status;
  double progress;
  String? errorMessage;

  ActiveMangaDownloadTask({
    required this.taskId,
    required this.mediaTitle,
    required this.extensionName,
    required this.chapter,
    this.status = MangaDownloadStatus.queued,
    this.progress = 0.0,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'mediaTitle': mediaTitle,
        'extensionName': extensionName,
        'chapter': chapter.toJson(),
        'status': status.index,
        'progress': progress,
        'errorMessage': errorMessage,
      };

  factory ActiveMangaDownloadTask.fromJson(Map<String, dynamic> json) =>
      ActiveMangaDownloadTask(
        taskId: json['taskId'] as String? ?? '',
        mediaTitle: json['mediaTitle'] as String? ?? '',
        extensionName: json['extensionName'] as String? ?? '',
        chapter: Chapter.fromJson(json['chapter'] as Map<String, dynamic>),
        status: MangaDownloadStatus.values[json['status'] as int? ?? 0],
        progress: (json['progress'] as num? ?? 0.0).toDouble(),
        errorMessage: json['errorMessage'] as String?,
      );

  String get chapterDisplay {
    final num = chapter.number;
    if (num != null) return 'Ch. ${num % 1 == 0 ? num.toInt() : num}';
    return chapter.title ?? 'Chapter';
  }
}
