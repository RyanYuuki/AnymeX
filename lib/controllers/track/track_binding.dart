import 'package:anymex/controllers/service_handler/service_handler.dart';

/// A single (media, tracker) binding stored locally.
///
/// One downloaded media item can have MULTIPLE [TrackBinding]s at once —
/// e.g. one for AniList, one for MAL, one for Simkl — mirroring aniyomi's
/// "one track row per (media, tracker) pair" design.
///
/// This is a pure local record (persisted via [DynamicKeys.trackBindings]
/// in the existing KV store). It does NOT make any network calls itself —
/// all remote sync goes through the existing per-service
/// `updateListEntry` / `search` methods (see [TrackBindingController]).
class TrackBinding {
  /// Index into [Tracker.values] (0 = AniList, 1 = MAL, 2 = Simkl).
  final int trackerId;

  /// The media id on the bound tracker (AniList media id / MAL anime id / Simkl id).
  final String remoteId;

  final String title;
  final String? poster;
  final String? totalEpisodes;

  /// Tracker-specific status string ("CURRENT", "COMPLETED", "PLANNING",
  /// "PAUSED", "DROPPED"). Kept in the tracker's own vocabulary — the
  /// existing per-service `updateListEntry` already accepts these.
  String status;

  double? score;

  /// Last episode/chapter number pushed to this tracker.
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

/// The set of trackers AnymeX supports for downloaded-media tracking.
///
/// Login state for each is read from the EXISTING service singletons
/// (`AnilistData.isLoggedIn`, `MalService.isLoggedIn`, `SimklService.isLoggedIn`)
/// — the same ones wired up under Settings → Accounts.
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

  /// The active [ServicesType] this tracker corresponds to — used so we
  /// can reuse the existing service singletons without new wiring.
  ServicesType get servicesType => switch (this) {
        Tracker.anilist => ServicesType.anilist,
        Tracker.mal => ServicesType.mal,
        Tracker.simkl => ServicesType.simkl,
      };
}
