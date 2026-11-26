import 'package:anymex/l10n/app_localizations.dart';

/// Translated name for a home-page card key such as "Planning Animes" or
/// "Continue Watching (Movies)". The English key stays the saved identifier;
/// unknown keys are returned unchanged.
String homeCardLabel(AppLocalizations l, String key) {
  final fixed = switch (key) {
    'Continue Watching' => l.homeContinueWatching,
    'Continue Reading' => l.homeContinueReading,
    'Recommended Animes' => l.recommendedAnimes,
    _ => null,
  };
  if (fixed != null) return fixed;

  String? type(String w) => switch (w) {
        'Animes' || 'Anime' => l.anime,
        'Manga' || 'Mangas' => l.manga,
        'Movie' || 'Movies' => l.movies,
        'Shows' || 'Show' => l.shows,
        'TV' => l.tv,
        _ => null,
      };

  final paren = RegExp(r'^(Continue Watching) \((\w+)\)$').firstMatch(key);
  if (paren != null) {
    final t = type(paren.group(2)!);
    if (t != null) return '${l.homeContinueWatching} ($t)';
  }

  final parts = key.split(' ');
  if (parts.length == 2) {
    final status = switch (parts[0]) {
      'Planning' => l.planning,
      'Completed' => l.libraryCompleted,
      'Paused' => l.downloadsPaused,
      'Dropped' => l.libraryDropped,
      'Rewatching' => l.rewatching,
      'Recommended' => l.recommended,
      _ => null,
    };
    final t = type(parts[1]);
    if (status != null && t != null) return '$status $t';
  }
  return key;
}
