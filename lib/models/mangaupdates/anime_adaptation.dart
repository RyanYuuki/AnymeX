class AnimeAdaptation {
  final String? animeStart;
  final String? animeEnd;
  final bool hasAdaptation;
  final String? error;

  AnimeAdaptation({
    this.animeStart,
    this.animeEnd,
    required this.hasAdaptation,
    this.error,
  });

  @override
  String toString() {
    if (error != null) return 'Error: $error';
    if (!hasAdaptation) return 'No anime adaptation found';
    return 'Anime: ${animeStart ?? 'Unknown'} - ${animeEnd ?? 'Ongoing'}';
  }
}
