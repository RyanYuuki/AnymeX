class NextRelease {
  final DateTime? nextReleaseDate;
  final int? averageIntervalDays;
  final String? nextChapter;
  final String? error;

  NextRelease({
    this.nextReleaseDate,
    this.averageIntervalDays,
    this.nextChapter,
    this.error,
  });

  @override
  String toString() {
    if (error != null) return 'Error: $error';
    return 'Next: $nextChapter on $nextReleaseDate (Interval: $averageIntervalDays days)';
  }
}
