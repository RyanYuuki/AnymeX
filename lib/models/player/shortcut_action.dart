import 'package:flutter/services.dart';

/// Player-screen keyboard shortcuts that can be rebound from Settings.
///
/// Plain Space/ArrowLeft/ArrowRight are intentionally excluded: they're
/// owned unconditionally by [DoubleTapSeekWidget]'s legacy `KeyboardListener`
/// (play/pause and seek), which can't be marked "handled" and would fire
/// alongside any shortcut bound to the same key. See [reservedShortcutKeys].
enum ShortcutAction {
  playPause,
  megaSkipForward,
  megaSkipBackward,
  volumeUp,
  volumeDown,
  mute,
  fullscreen,
  nextEpisode,
  previousEpisode,
  audioPane,
  subtitlePane,
  playlistPane,
}

/// Keys claimed unconditionally by [DoubleTapSeekWidget]'s legacy
/// `KeyboardListener`. Binding a shortcut to one of these would silently
/// fire both actions on every press, so the capture UI rejects them.
final Set<LogicalKeyboardKey> reservedShortcutKeys = {
  LogicalKeyboardKey.space,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowRight,
};

extension ShortcutActionData on ShortcutAction {
  String get label {
    switch (this) {
      case ShortcutAction.playPause:
        return 'Play / Pause';
      case ShortcutAction.megaSkipForward:
        return 'Mega-Skip Forward';
      case ShortcutAction.megaSkipBackward:
        return 'Mega-Skip Backward';
      case ShortcutAction.volumeUp:
        return 'Volume Up';
      case ShortcutAction.volumeDown:
        return 'Volume Down';
      case ShortcutAction.mute:
        return 'Mute';
      case ShortcutAction.fullscreen:
        return 'Fullscreen';
      case ShortcutAction.nextEpisode:
        return 'Next Episode';
      case ShortcutAction.previousEpisode:
        return 'Previous Episode';
      case ShortcutAction.audioPane:
        return 'Audio Track';
      case ShortcutAction.subtitlePane:
        return 'Subtitles';
      case ShortcutAction.playlistPane:
        return 'Playlist';
    }
  }

  LogicalKeyboardKey get defaultKey {
    switch (this) {
      case ShortcutAction.playPause:
        return LogicalKeyboardKey.keyK;
      case ShortcutAction.megaSkipForward:
        return LogicalKeyboardKey.bracketRight;
      case ShortcutAction.megaSkipBackward:
        return LogicalKeyboardKey.bracketLeft;
      case ShortcutAction.volumeUp:
        return LogicalKeyboardKey.arrowUp;
      case ShortcutAction.volumeDown:
        return LogicalKeyboardKey.arrowDown;
      case ShortcutAction.mute:
        return LogicalKeyboardKey.keyM;
      case ShortcutAction.fullscreen:
        return LogicalKeyboardKey.keyF;
      case ShortcutAction.nextEpisode:
        return LogicalKeyboardKey.keyN;
      case ShortcutAction.previousEpisode:
        return LogicalKeyboardKey.keyB;
      case ShortcutAction.audioPane:
        return LogicalKeyboardKey.keyA;
      case ShortcutAction.subtitlePane:
        return LogicalKeyboardKey.keyS;
      case ShortcutAction.playlistPane:
        return LogicalKeyboardKey.keyP;
    }
  }

  /// Whether this action bypasses the "another pane is open" guard: it's
  /// the mechanism that opens *and* closes its own pane, mirroring the
  /// on-screen buttons in bottom_controls.dart.
  bool get isPaneToggle {
    switch (this) {
      case ShortcutAction.audioPane:
      case ShortcutAction.subtitlePane:
      case ShortcutAction.playlistPane:
        return true;
      default:
        return false;
    }
  }

  /// Whether holding the key down should repeat the action (seek/volume),
  /// as opposed to firing once per press (toggles, navigation).
  bool get allowsKeyRepeat {
    switch (this) {
      case ShortcutAction.volumeUp:
      case ShortcutAction.volumeDown:
        return true;
      default:
        return false;
    }
  }
}

String describeShortcutKey(LogicalKeyboardKey key) {
  final name = key.debugName ?? key.keyLabel;
  if (name.isEmpty) return 'Key ${key.keyId}';
  return name;
}
