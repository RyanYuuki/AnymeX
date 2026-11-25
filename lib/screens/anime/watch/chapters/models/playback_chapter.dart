class PlaybackChapter {
  final String title;
  final double startSeconds;

  const PlaybackChapter({
    required this.title,
    required this.startSeconds,
  });

  Duration get startDuration => Duration(milliseconds: (startSeconds * 1000).round());
}

enum PlaybackSegmentKind {
  opening,
  ending,
  recap,
  preview,
  other,
}

class PlaybackSkipSegment {
  final String title;
  final PlaybackSegmentKind kind;
  final double startSeconds;
  final double endSeconds;
  final String? source;

  const PlaybackSkipSegment({
    required this.title,
    required this.kind,
    required this.startSeconds,
    required this.endSeconds,
    this.source,
  });

  bool covers(double currentSeconds) =>
      currentSeconds >= startSeconds && currentSeconds < endSeconds;

  Duration get startDuration => Duration(milliseconds: (startSeconds * 1000).round());
  Duration get endDuration => Duration(milliseconds: (endSeconds * 1000).round());
}
