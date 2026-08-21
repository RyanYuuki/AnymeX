class MediaIds {
  final String? anilistId;
  final String? malId;
  final String? simklId;
  final String? tmdbId;
  final String? kitsuId;

  const MediaIds({
    this.anilistId,
    this.malId,
    this.simklId,
    this.tmdbId,
    this.kitsuId,
  });

  Map<String, dynamic> toJson() => {
        'anilistId': anilistId,
        'malId': malId,
        'simklId': simklId,
        'tmdbId': tmdbId,
        'kitsuId': kitsuId,
      };

  factory MediaIds.fromJson(Map<String, dynamic> json) => MediaIds(
        anilistId: json['anilistId'] as String?,
        malId: json['malId'] as String?,
        simklId: json['simklId'] as String?,
        tmdbId: json['tmdbId'] as String?,
        kitsuId: json['kitsuId'] as String?,
      );
}
