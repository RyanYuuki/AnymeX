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

class MangaBakaSeries {
  final int id;
  final String title;
  final String? coverUrl;
  final String? description;
  final MangaBakaStatus status;
  final MangaBakaType type;
  final String? totalChapters;
  final String? finalVolume;
  final int? anilistId;
  final int? malId;
  final double? rating;

  const MangaBakaSeries({
    required this.id,
    required this.title,
    this.coverUrl,
    this.description,
    required this.status,
    required this.type,
    this.totalChapters,
    this.finalVolume,
    this.anilistId,
    this.malId,
    this.rating,
  });

  factory MangaBakaSeries.fromJson(Map<String, dynamic> json) {
    final cover = json['cover'] as Map<String, dynamic>?;
    final raw = cover?['raw'] as Map<String, dynamic>?;
    final source = json['source'] as Map<String, dynamic>?;
    final anilistSource = source?['anilist'] as Map<String, dynamic>?;
    final malSource = source?['my_anime_list'] as Map<String, dynamic>?;

    return MangaBakaSeries(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      coverUrl: raw?['url'] as String?,
      description: json['description'] as String?,
      status: MangaBakaStatus.fromString(json['status'] as String?),
      type: MangaBakaType.fromString(json['type'] as String?),
      totalChapters: json['total_chapters'] as String?,
      finalVolume: json['final_volume'] as String?,
      anilistId: anilistSource?['id'] as int?,
      malId: malSource?['id'] as int?,
      rating: (json['rating'] as num?)?.toDouble(),
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

class MangaBakaLibraryEntry {
  final int? id;
  final int? seriesId;
  final MangaBakaLibraryState? state;
  final int? rating;
  final int? progressChapter;
  final int? progressVolume;
  final String? startDate;
  final String? finishDate;

  const MangaBakaLibraryEntry({
    this.id,
    this.seriesId,
    this.state,
    this.rating,
    this.progressChapter,
    this.progressVolume,
    this.startDate,
    this.finishDate,
  });

  factory MangaBakaLibraryEntry.fromJson(Map<String, dynamic> json) {
    return MangaBakaLibraryEntry(
      id: json['id'] as int?,
      seriesId: json['series_id'] as int?,
      state: MangaBakaLibraryState.fromString(json['state'] as String?),
      rating: json['rating'] as int?,
      progressChapter: json['progress_chapter'] as int?,
      progressVolume: json['progress_volume'] as int?,
      startDate: json['start_date'] as String?,
      finishDate: json['finish_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    bool isEpochDate(String? d) =>
        d != null && (d.startsWith('1969-12-31') || d.startsWith('1970-01-01'));

    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (seriesId != null) map['series_id'] = seriesId;
    if (state != null) map['state'] = state!.value;
    if (rating != null) map['rating'] = rating;
    if (progressChapter != null) map['progress_chapter'] = progressChapter;
    if (progressVolume != null) map['progress_volume'] = progressVolume;
    if (startDate != null) {
      map['start_date'] = isEpochDate(startDate) ? null : startDate;
    }
    if (finishDate != null) {
      map['finish_date'] = isEpochDate(finishDate) ? null : finishDate;
    }
    return map;
  }

  MangaBakaLibraryEntry copyWith({
    int? id,
    int? seriesId,
    MangaBakaLibraryState? state,
    int? rating,
    int? progressChapter,
    int? progressVolume,
    String? startDate,
    String? finishDate,
  }) {
    return MangaBakaLibraryEntry(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      state: state ?? this.state,
      rating: rating ?? this.rating,
      progressChapter: progressChapter ?? this.progressChapter,
      progressVolume: progressVolume ?? this.progressVolume,
      startDate: startDate ?? this.startDate,
      finishDate: finishDate ?? this.finishDate,
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
