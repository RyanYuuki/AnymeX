class AnilistUserSettings {
  AnilistUserSettings({
    this.about,
    required this.titleLanguage,
    required this.staffNameLanguage,
    required this.activityMergeTime,
    required this.displayAdultContent,
    required this.airingNotifications,
    required this.restrictMessagesToFollowing,
    required this.scoreFormat,
    required this.rowOrder,
    required this.splitCompletedAnime,
    required this.splitCompletedManga,
    required this.advancedScoringEnabled,
    required this.advancedScoring,
    required this.animeCustomLists,
    required this.mangaCustomLists,
    required this.animeSectionOrder,
    required this.mangaSectionOrder,
    this.animeTheme,
    this.mangaTheme,
    this.timezone,
  });

  String? about;
  String titleLanguage;
  String staffNameLanguage;
  int activityMergeTime;
  bool displayAdultContent;
  bool airingNotifications;
  bool restrictMessagesToFollowing;
  String scoreFormat;
  String rowOrder;
  bool splitCompletedAnime;
  bool splitCompletedManga;
  bool advancedScoringEnabled;
  List<String> advancedScoring;
  List<String> animeCustomLists;
  List<String> mangaCustomLists;
  List<String> animeSectionOrder;
  List<String> mangaSectionOrder;
  String? animeTheme;
  String? mangaTheme;
  String? timezone;

  static String? _coerceTheme(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      final candidates = [
        value['name'],
        value['theme'],
        value['value'],
        value['id']
      ];
      for (final candidate in candidates) {
        if (candidate is String && candidate.isNotEmpty) {
          return candidate;
        }
      }
    }
    return value.toString();
  }

  factory AnilistUserSettings.fromJson(Map<String, dynamic> json) {
    final options = json['options'] as Map<String, dynamic>? ?? const {};
    final mediaListOptions =
        json['mediaListOptions'] as Map<String, dynamic>? ?? const {};
    final animeList =
        mediaListOptions['animeList'] as Map<String, dynamic>? ?? const {};
    final mangaList =
        mediaListOptions['mangaList'] as Map<String, dynamic>? ?? const {};

    return AnilistUserSettings(
      about: json['about'] as String?,
      titleLanguage: options['titleLanguage'] as String? ?? 'ROMAJI',
      staffNameLanguage:
          options['staffNameLanguage'] as String? ?? 'ROMAJI_WESTERN',
      activityMergeTime: options['activityMergeTime'] as int? ?? 720,
      displayAdultContent: options['displayAdultContent'] as bool? ?? false,
      airingNotifications: options['airingNotifications'] as bool? ?? true,
      restrictMessagesToFollowing:
          options['restrictMessagesToFollowing'] as bool? ?? false,
      scoreFormat: mediaListOptions['scoreFormat'] as String? ?? 'POINT_10',
      rowOrder: mediaListOptions['rowOrder'] as String? ?? 'score',
      splitCompletedAnime:
          animeList['splitCompletedSectionByFormat'] as bool? ?? false,
      splitCompletedManga:
          mangaList['splitCompletedSectionByFormat'] as bool? ?? false,
      advancedScoringEnabled:
          animeList['advancedScoringEnabled'] as bool? ?? false,
      advancedScoring: List<String>.from(
          animeList['advancedScoring'] as List<dynamic>? ?? const []),
      animeCustomLists: List<String>.from(
          animeList['customLists'] as List<dynamic>? ?? const []),
      mangaCustomLists: List<String>.from(
          mangaList['customLists'] as List<dynamic>? ?? const []),
      animeSectionOrder: List<String>.from(
          animeList['sectionOrder'] as List<dynamic>? ?? const []),
      mangaSectionOrder: List<String>.from(
          mangaList['sectionOrder'] as List<dynamic>? ?? const []),
      animeTheme: _coerceTheme(animeList['theme']),
      mangaTheme: _coerceTheme(mangaList['theme']),
      timezone: options['timezone'] as String?,
    );
  }

  AnilistUserSettings copyWith({
    String? about,
    String? titleLanguage,
    String? staffNameLanguage,
    int? activityMergeTime,
    bool? displayAdultContent,
    bool? airingNotifications,
    bool? restrictMessagesToFollowing,
    String? scoreFormat,
    String? rowOrder,
    bool? splitCompletedAnime,
    bool? splitCompletedManga,
    bool? advancedScoringEnabled,
    List<String>? advancedScoring,
    List<String>? animeCustomLists,
    List<String>? mangaCustomLists,
    List<String>? animeSectionOrder,
    List<String>? mangaSectionOrder,
    String? animeTheme,
    String? mangaTheme,
    String? timezone,
  }) {
    return AnilistUserSettings(
      about: about ?? this.about,
      titleLanguage: titleLanguage ?? this.titleLanguage,
      staffNameLanguage: staffNameLanguage ?? this.staffNameLanguage,
      activityMergeTime: activityMergeTime ?? this.activityMergeTime,
      displayAdultContent: displayAdultContent ?? this.displayAdultContent,
      airingNotifications: airingNotifications ?? this.airingNotifications,
      restrictMessagesToFollowing:
          restrictMessagesToFollowing ?? this.restrictMessagesToFollowing,
      scoreFormat: scoreFormat ?? this.scoreFormat,
      rowOrder: rowOrder ?? this.rowOrder,
      splitCompletedAnime: splitCompletedAnime ?? this.splitCompletedAnime,
      splitCompletedManga: splitCompletedManga ?? this.splitCompletedManga,
      advancedScoringEnabled:
          advancedScoringEnabled ?? this.advancedScoringEnabled,
      advancedScoring:
          advancedScoring ?? List<String>.from(this.advancedScoring),
      animeCustomLists:
          animeCustomLists ?? List<String>.from(this.animeCustomLists),
      mangaCustomLists:
          mangaCustomLists ?? List<String>.from(this.mangaCustomLists),
      animeSectionOrder:
          animeSectionOrder ?? List<String>.from(this.animeSectionOrder),
      mangaSectionOrder:
          mangaSectionOrder ?? List<String>.from(this.mangaSectionOrder),
      animeTheme: animeTheme ?? this.animeTheme,
      mangaTheme: mangaTheme ?? this.mangaTheme,
      timezone: timezone ?? this.timezone,
    );
  }

  Map<String, dynamic> toGraphQlVariables() {
    return {
      'about': about,
      'titleLanguage': titleLanguage,
      'staffNameLanguage': staffNameLanguage,
      'activityMergeTime': activityMergeTime,
      'displayAdultContent': displayAdultContent,
      'airingNotifications': airingNotifications,
      'restrictMessagesToFollowing': restrictMessagesToFollowing,
      'scoreFormat': scoreFormat,
      'rowOrder': rowOrder,
      'splitCompletedAnime': splitCompletedAnime,
      'splitCompletedManga': splitCompletedManga,
      'advancedScoringEnabled': advancedScoringEnabled,
      'advancedScoring': advancedScoring,
      'animeCustomLists': animeCustomLists,
      'mangaCustomLists': mangaCustomLists,
      'animeSectionOrder': animeSectionOrder,
      'mangaSectionOrder': mangaSectionOrder,
      'animeTheme': animeTheme,
      'mangaTheme': mangaTheme,
    };
  }
}

class AnilistSettingsMetadata {
  const AnilistSettingsMetadata({
    required this.titleLanguageValues,
    required this.staffNameLanguageValues,
    required this.scoreFormatValues,
    required this.mediaFormatValues,
  });

  final List<String> titleLanguageValues;
  final List<String> staffNameLanguageValues;
  final List<String> scoreFormatValues;
  final List<String> mediaFormatValues;

  static List<String> _enumValuesFromType(dynamic rawType) {
    final enumValues =
        (rawType as Map<String, dynamic>?)?['enumValues'] as List<dynamic>?;
    if (enumValues == null) return const [];
    return [
      for (final v in enumValues)
        if (v is Map<String, dynamic> &&
            v['name'] != null &&
            (v['name'] as String).isNotEmpty)
          v['name'] as String,
    ];
  }

  factory AnilistSettingsMetadata.fromJson(Map<String, dynamic> json) {
    return AnilistSettingsMetadata(
      titleLanguageValues: _enumValuesFromType(json['titleLanguage']),
      staffNameLanguageValues: _enumValuesFromType(json['staffNameLanguage']),
      scoreFormatValues: _enumValuesFromType(json['scoreFormat']),
      mediaFormatValues: _enumValuesFromType(json['mediaFormat']),
    );
  }
}
