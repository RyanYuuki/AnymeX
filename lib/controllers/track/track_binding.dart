import 'package:anymex/controllers/service_handler/service_handler.dart';

class TrackBinding {
  final int trackerId;
  final String remoteId;

  final String title;
  final String? poster;
  final String? totalEpisodes;

  String status;

  double? score;

  int progress;

  final bool isAnime;
  bool private;

  TrackBinding({
    required this.trackerId,
    required this.remoteId,
    required this.title,
    this.poster,
    this.totalEpisodes,
    this.status = 'CURRENT',
    this.score,
    this.progress = 0,
    required this.isAnime,
    this.private = false,
  });

  Tracker get tracker => Tracker.values[trackerId];

  Map<String, dynamic> toJson() => {
        'trackerId': trackerId,
        'remoteId': remoteId,
        'title': title,
        'poster': poster,
        'totalEpisodes': totalEpisodes,
        'status': status,
        'score': score,
        'progress': progress,
        'isAnime': isAnime,
        'private': private,
      };

  factory TrackBinding.fromJson(Map<String, dynamic> json) {
    return TrackBinding(
      trackerId: (json['trackerId'] as num?)?.toInt() ?? 0,
      remoteId: json['remoteId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      poster: json['poster']?.toString(),
      totalEpisodes: json['totalEpisodes']?.toString(),
      status: json['status']?.toString() ?? 'CURRENT',
      score: (json['score'] as num?)?.toDouble(),
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      isAnime: json['isAnime'] as bool? ?? true,
      private: json['private'] as bool? ?? false,
    );
  }
}

enum Tracker {
  anilist,
  mal,
  simkl;

  String get label => switch (this) {
        Tracker.anilist => 'AniList',
        Tracker.mal => 'MyAnimeList',
        Tracker.simkl => 'Simkl',
      };

  int get color => switch (this) {
        Tracker.anilist => 0xFF02A9FF,
        Tracker.mal => 0xFF2E51A2,
        Tracker.simkl => 0xFF7E57C2,
      };

  String get iconAsset => switch (this) {
        Tracker.anilist => 'assets/images/anilist-icon.png',
        Tracker.mal => 'assets/images/mal-icon.png',
        Tracker.simkl => 'assets/images/simkl-icon.png',
      };

  ServicesType get servicesType => switch (this) {
        Tracker.anilist => ServicesType.anilist,
        Tracker.mal => ServicesType.mal,
        Tracker.simkl => ServicesType.simkl,
      };
}
