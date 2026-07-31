import 'package:anymex/models/Media/media.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';

class MangaBakaResponse<T> {
  final int status;
  final String? message;
  final T? data;
  final List<MangaBakaIssue>? issues;

  const MangaBakaResponse({
    required this.status,
    this.message,
    this.data,
    this.issues,
  });

  factory MangaBakaResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromData,
  ) {
    return MangaBakaResponse<T>(
      status: json['status'] as int? ?? 0,
      message: json['message'] as String?,
      data: json['data'] != null ? fromData(json['data']) : null,
      issues: (json['issues'] as List<dynamic>?)
          ?.map((e) => MangaBakaIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MangaBakaIssue {
  final String code;
  final String? message;

  const MangaBakaIssue({required this.code, this.message});

  factory MangaBakaIssue.fromJson(Map<String, dynamic> json) =>
      MangaBakaIssue(
        code: json['code'] as String? ?? '',
        message: json['message'] as String?,
      );
}

enum MangaBakaStatus {
  cancelled,
  completed,
  hiatus,
  releasing,
  unknown,
  upcoming;

  static MangaBakaStatus fromString(String? v) => switch (v) {
        'cancelled' => cancelled,
        'completed' => completed,
        'hiatus' => hiatus,
        'releasing' => releasing,
        'upcoming' => upcoming,
        _ => unknown,
      };
  
  String get displayName => switch (this) {
        cancelled => 'Cancelled',
        completed => 'Completed',
        hiatus => 'Hiatus',
        releasing => 'Releasing',
        unknown => 'Unknown',
        upcoming => 'Upcoming',
      };
}

enum MangaBakaType {
  manga,
  novel,
  manhwa,
  manhua,
  oel,
  other;

  static MangaBakaType fromString(String? v) => switch (v) {
        'manga' => manga,
        'novel' => novel,
        'manhwa' => manhwa,
        'manhua' => manhua,
        'oel' => oel,
        _ => other,
      };

  String get apiValue => switch (this) {
        manga => 'manga',
        novel => 'novel',
        manhwa => 'manhwa',
        manhua => 'manhua',
        oel => 'oel',
        other => 'other',
      };

  String get displayName => switch (this) {
        manga => 'Manga',
        novel => 'Novel',
        manhwa => 'Manhwa',
        manhua => 'Manhua',
        oel => 'OEL',
        other => 'Other',
      };
}

enum MangaBakaContentRating {
  safe,
  suggestive,
  erotica,
  pornographic;

  static MangaBakaContentRating fromString(String? v) => switch (v) {
        'suggestive' => suggestive,
        'erotica' => erotica,
        'pornographic' => pornographic,
        _ => safe,
      };
}

enum MangaBakaLibraryState {
  considering('considering'),
  planToRead('plan_to_read'),
  reading('reading'),
  completed('completed'),
  rereading('rereading'),
  paused('paused'),
  dropped('dropped');

  final String value;
  const MangaBakaLibraryState(this.value);

  static MangaBakaLibraryState fromString(String? v) => switch (v) {
        'considering' => considering,
        'plan_to_read' => planToRead,
        'reading' => reading,
        'completed' => completed,
        'rereading' => rereading,
        'paused' => paused,
        'dropped' => dropped,
        _ => reading,
      };

  static MangaBakaLibraryState fromAnilistStatus(String? status) =>
      switch (status?.toUpperCase()) {
        'PLANNING' => planToRead,
        'CURRENT' => reading,
        'COMPLETED' => completed,
        'REPEATING' => rereading,
        'PAUSED' => paused,
        'DROPPED' => dropped,
        _ => reading,
      };

  String toAnilistStatus() => switch (this) {
        considering => 'PLANNING',
        planToRead => 'PLANNING',
        reading => 'CURRENT',
        completed => 'COMPLETED',
        rereading => 'REPEATING',
        paused => 'PAUSED',
        dropped => 'DROPPED',
      };

  String toMalStatus() => switch (this) {
        considering => 'plan_to_read',
        planToRead => 'plan_to_read',
        reading => 'reading',
        completed => 'completed',
        rereading => 'reading',
        paused => 'on_hold',
        dropped => 'dropped',
      };

  String get displayName => switch (this) {
        considering => 'Considering',
        planToRead => 'Plan to Read',
        reading => 'Reading',
        completed => 'Completed',
        rereading => 'Rereading',
        paused => 'Paused',
        dropped => 'Dropped',
      };
}

const _titlePriorities = [
  'en',
  'ja-Latn',
  'ja',
  'ko-Latn',
  'ko',
  'zh-Latn',
  'zh',
];

class MangaBakaItemTitle {
  final String language;
  final List<String> traits;
  final String title;
  final bool isPrimary;

  const MangaBakaItemTitle({
    required this.language,
    required this.traits,
    required this.title,
    required this.isPrimary,
  });

  factory MangaBakaItemTitle.fromJson(Map<String, dynamic> json) {
    return MangaBakaItemTitle(
      language: json['language'] as String? ?? '',
      traits: (json['traits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      title: json['title'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

String chooseBestTitle(
    int id, List<MangaBakaItemTitle>? titles, String? defaultTitle) {
  if (titles != null && titles.isNotEmpty) {
    for (final lang in _titlePriorities) {
      final matching = titles.where((t) => t.language == lang).toList();
      if (matching.isNotEmpty) {
        matching.sort((a, b) {
          int score(MangaBakaItemTitle t) {
            if (t.isPrimary) return 0;
            if (t.traits.contains('official')) return 1;
            if (t.traits.contains('native')) return 2;
            return 3;
          }

          return score(a).compareTo(score(b));
        });
        return matching.first.title;
      }
    }
    return titles.first.title;
  }
  if (defaultTitle != null && defaultTitle.isNotEmpty) return defaultTitle;
  return 'ID: $id - Title unavailable';
}

String? parseCoverUrl(Map<String, dynamic>? cover) {
  if (cover == null) return null;
  final raw = cover['raw'] as Map<String, dynamic>?;
  if (raw != null && raw['url'] != null) {
    return raw['url'] as String;
  }
  final x250 = cover['x250'] as Map<String, dynamic>?;
  if (x250 != null && x250['x1'] != null) {
    return x250['x1'] as String;
  }
  return null;
}

class MangaBakaSeries {
  final int id;
  final String title;
  final List<MangaBakaItemTitle>? titles;
  final String? coverUrl;
  final String? description;
  final MangaBakaStatus status;
  final MangaBakaType type;
  final String? totalChapters;
  final String? finalVolume;
  final int? anilistId;
  final int? malId;
  final double? rating;
  final List<String>? authors;
  final List<String>? artists;
  final String? startDate;

  const MangaBakaSeries({
    required this.id,
    required this.title,
    this.titles,
    this.coverUrl,
    this.description,
    required this.status,
    required this.type,
    this.totalChapters,
    this.finalVolume,
    this.anilistId,
    this.malId,
    this.rating,
    this.authors,
    this.artists,
    this.startDate,
  });

  factory MangaBakaSeries.fromJson(Map<String, dynamic> json) {
    final cover = json['cover'] as Map<String, dynamic>?;
    final coverUrl = parseCoverUrl(cover);
    final rawTitles = json['titles'] as List<dynamic>?;
    final titles = rawTitles
        ?.map((e) => MangaBakaItemTitle.fromJson(e as Map<String, dynamic>))
        .toList();
    final defaultTitle = json['title'] as String?;
    final bestTitle = chooseBestTitle(
        json['id'] as int? ?? 0, titles, defaultTitle);

    final source = json['source'] as Map<String, dynamic>?;
    final anilistSource = source?['anilist'] as Map<String, dynamic>?;
    final malSource = source?['my_anime_list'] as Map<String, dynamic>?;

    final authorsList = (json['authors'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    final artistsList = (json['artists'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    final pubData = json['published'] as Map<String, dynamic>?;
    final startDate = pubData?['start_date'] as String?;

    return MangaBakaSeries(
      id: json['id'] as int,
      title: bestTitle,
      titles: titles,
      coverUrl: coverUrl,
      description: json['description'] as String?,
      status: MangaBakaStatus.fromString(json['status'] as String?),
      type: MangaBakaType.fromString(json['type'] as String?),
      totalChapters: json['total_chapters']?.toString(),
      finalVolume: json['final_volume']?.toString(),
      anilistId: anilistSource?['id'] as int?,
      malId: malSource?['id'] as int?,
      rating: (json['rating'] as num?)?.toDouble(),
      authors: authorsList,
      artists: artistsList,
      startDate: startDate,
    );
  }

  Media toMedia() {
    return Media(
      id: id.toString(),
      title: title,
      cover: coverUrl,
      poster: coverUrl ?? '?',
      description: description ?? '?',
      totalChapters: totalChapters,
      mediaType: type == MangaBakaType.novel ? ItemType.novel : ItemType.manga,
      serviceType: ServicesType.mangabaka,
      rating: rating?.toString() ?? '',
      status: status.displayName,
    );
  }
}

class MangaBakaUserProfile {
  final String? id;
  final String? nickname;
  final String? preferredUsername;
  final int ratingSteps;

  const MangaBakaUserProfile({
    this.id,
    this.nickname,
    this.preferredUsername,
    this.ratingSteps = 1,
  });

  factory MangaBakaUserProfile.fromJson(Map<String, dynamic> json) {
    return MangaBakaUserProfile(
      id: json['id']?.toString(),
      nickname: json['nickname'] as String?,
      preferredUsername: json['preferred_username'] as String?,
      ratingSteps: (json['rating_steps'] as num?)?.toInt() ?? 1,
    );
  }

  String get displayName =>
      nickname ?? preferredUsername ?? id ?? 'MangaBaka User';
}

class MangaBakaLibraryEntry {
  final int? id;
  final int? seriesId;
  final MangaBakaLibraryState? state;
  final String? note;
  final double? progressChapter;
  final int? progressVolume;
  final int? numberOfRereads;
  final int? rating;
  final int? priority;
  final bool? isPrivate;
  final String? startDate;
  final String? finishDate;
  final String? updatedAt;
  final String? createdAt;
  final MangaBakaSeries? series;

  const MangaBakaLibraryEntry({
    this.id,
    this.seriesId,
    this.state,
    this.note,
    this.progressChapter,
    this.progressVolume,
    this.numberOfRereads,
    this.rating,
    this.priority,
    this.isPrivate,
    this.startDate,
    this.finishDate,
    this.updatedAt,
    this.createdAt,
    this.series,
  });

  factory MangaBakaLibraryEntry.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['Series'] ?? json['series'];
    return MangaBakaLibraryEntry(
      id: json['id'] as int?,
      seriesId: json['series_id'] as int?,
      state: MangaBakaLibraryState.fromString(json['state'] as String?),
      note: json['note'] as String?,
      progressChapter: (json['progress_chapter'] as num?)?.toDouble(),
      progressVolume: (json['progress_volume'] as num?)?.toInt(),
      numberOfRereads: (json['number_of_rereads'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toInt(),
      priority: json['priority'] as int?,
      isPrivate: json['is_private'] as bool?,
      startDate: json['start_date'] as String?,
      finishDate: json['finish_date'] as String?,
      updatedAt: json['updated_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      series: rawSeries is Map<String, dynamic>
          ? MangaBakaSeries.fromJson(rawSeries)
          : null,
    );
  }
}

class MangaBakaOAuthToken {
  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final DateTime fetchedAt;

  const MangaBakaOAuthToken({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
    required this.fetchedAt,
  });

  factory MangaBakaOAuthToken.fromJson(Map<String, dynamic> json) {
    return MangaBakaOAuthToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int?,
      fetchedAt: json['fetched_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['fetched_at'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        if (refreshToken != null) 'refresh_token': refreshToken,
        if (expiresIn != null) 'expires_in': expiresIn,
        'fetched_at': fetchedAt.millisecondsSinceEpoch,
      };

  bool get isExpired {
    if (expiresIn == null) return false;
    return DateTime.now().isAfter(fetchedAt.add(Duration(seconds: expiresIn!)));
  }
}
