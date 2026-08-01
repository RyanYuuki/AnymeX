
enum WatchiumKeys {
  serverUrl,
  notifyOnMemberJoin,
  notifyOnMemberLeave,
  commentOverlay,
  followHost,
  reactionOverlay,
  overlayPosition,
}

/// Where on-screen chat/reaction overlays appear.
enum WatchiumOverlayPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight;

  /// Parse from a stored string, defaulting to [bottomRight].
  static WatchiumOverlayPosition fromString(String? s) {
    if (s == null) return WatchiumOverlayPosition.bottomRight;
    return WatchiumOverlayPosition.values.firstWhere(
      (e) => e.name == s,
      orElse: () => WatchiumOverlayPosition.bottomRight,
    );
  }
}
