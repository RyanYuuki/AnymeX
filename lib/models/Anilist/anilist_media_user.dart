class AnilistMediaUser {
  String? id;
  String? title;
  String? poster;
  String? episodeCount;
  String? chapterCount;
  String? rating;
  String? totalEpisodes;
  String? watchingStatus;
  String? format;
  String? mediaStatus;
  String? score;
  String? type;

  AnilistMediaUser({
    this.id,
    this.title,
    this.poster,
    this.episodeCount,
    this.chapterCount,
    this.rating,
    this.totalEpisodes,
    this.watchingStatus,
    this.format,
    this.mediaStatus,
    this.score,
    this.type,
  });

  factory AnilistMediaUser.fromJson(Map<String, dynamic> json) {
    return AnilistMediaUser(
      id: json['media']['id']?.toString(),
      title: json['media']['title']['english'] ??
          json['media']['title']['romaji'] ??
          json['media']['title']['native'],
      poster: json['media']['coverImage']['large'],
      episodeCount: json['progress']?.toString(),
      chapterCount: json['media']['chapters']?.toString(),
      totalEpisodes: json['media']['episodes']?.toString(),
      rating: json['score']?.toString() ??
          (double.tryParse(json['averageScore']?.toString() ?? "0")! / 10)
              .toString(),
      watchingStatus: json['status'],
      format: json['media']['format'],
      mediaStatus: json['media']['status'],
      score: json['score']?.toString(),
      type: json['media']['type']?.toString(),
    );
  }
}
