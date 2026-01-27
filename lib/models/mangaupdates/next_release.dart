class NextRelease {
  final DateTime? nextReleaseDate;
  final int? averageIntervalDays;
  final String? lastReleaseDate;
  final String? error;

  NextRelease({
    this.nextReleaseDate,
    this.averageIntervalDays,
    this.lastReleaseDate,
    this.error,
  });

  @override
  String toString() {
    if (error != null) return 'Error: $error';
    return 'Next: $nextReleaseDate (Interval: $averageIntervalDays days)';
  }
}
