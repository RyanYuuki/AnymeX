import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/player/shortcut_action.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Wraps the watch screen with hardware-keyboard shortcuts for playback
/// navigation (mega-skip, episode switching, volume, mute, fullscreen and
/// pane toggles). Bindings are configurable from Settings > Player >
/// Keyboard Shortcuts; see [ShortcutAction] for the action list and
/// [reservedShortcutKeys] for keys that can't be reassigned here.
/// Disabled in TV mode, where arrow keys drive focus traversal between
/// on-screen controls instead.
class PlayerKeyboardShortcuts extends StatefulWidget {
  final PlayerController controller;
  final Widget child;

  const PlayerKeyboardShortcuts({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<PlayerKeyboardShortcuts> createState() =>
      _PlayerKeyboardShortcutsState();
}

class _PlayerKeyboardShortcutsState extends State<PlayerKeyboardShortcuts> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'PlayerKeyboardShortcuts');

  PlayerController get controller => widget.controller;

  Settings? get _settings {
    try {
      return Get.find<Settings>();
    } catch (_) {
      return null;
    }
  }

  bool get _isTV => _settings?.isTV.value ?? false;

  bool get _isOverlayOpen =>
      controller.isSourcePaneOpened.value ||
      controller.isTracksPaneOpened.value ||
      controller.isAudioPaneOpened.value ||
      controller.isSyncSubsPaneOpened.value ||
      controller.isSettingsPaneOpened.value ||
      controller.isEpisodePaneOpened.value ||
      controller.isSpeedPaneOpened.value;

  ShortcutAction? _actionForKey(LogicalKeyboardKey key, Settings? settings) {
    for (final action in ShortcutAction.values) {
      final bound = settings?.shortcutFor(action) ?? action.defaultKey;
      if (bound == key) return action;
    }
    return null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_isTV || controller.isLocked.value) {
      return KeyEventResult.ignored;
    }

    final isTap = event is KeyDownEvent;
    final isTapOrRepeat = isTap || event is KeyRepeatEvent;
    if (!isTapOrRepeat) return KeyEventResult.ignored;

    final settings = _settings;
    final action = _actionForKey(event.logicalKey, settings);
    if (action == null) return KeyEventResult.ignored;

    // Pane toggles are exempt from the overlay guard below since they're
    // the mechanism that opens *and closes* those panes, matching the
    // on-screen buttons they mirror (bottom_controls.dart).
    if (isTap && action.isPaneToggle) {
      switch (action) {
        case ShortcutAction.audioPane:
          controller.isAudioPaneOpened.value =
              !controller.isAudioPaneOpened.value;
          break;
        case ShortcutAction.subtitlePane:
          controller.isTracksPaneOpened.value =
              !controller.isTracksPaneOpened.value;
          break;
        case ShortcutAction.playlistPane:
          controller.isEpisodePaneOpened.value =
              !controller.isEpisodePaneOpened.value;
          break;
        default:
          break;
      }
      return KeyEventResult.handled;
    }

    if (_isOverlayOpen) return KeyEventResult.ignored;

    if (!action.allowsKeyRepeat && !isTap) return KeyEventResult.ignored;

    switch (action) {
      case ShortcutAction.volumeUp:
        _adjustVolume(0.05);
        return KeyEventResult.handled;
      case ShortcutAction.volumeDown:
        _adjustVolume(-0.05);
        return KeyEventResult.handled;
      case ShortcutAction.megaSkipForward:
        controller.megaSeek(controller.playerSettings.skipDuration);
        return KeyEventResult.handled;
      case ShortcutAction.megaSkipBackward:
        controller.megaSeek(-controller.playerSettings.skipDuration);
        return KeyEventResult.handled;
      case ShortcutAction.playPause:
        controller.togglePlayPause();
        return KeyEventResult.handled;
      case ShortcutAction.mute:
        controller.toggleMute();
        return KeyEventResult.handled;
      case ShortcutAction.fullscreen:
        controller.toggleFullScreen();
        return KeyEventResult.handled;
      case ShortcutAction.nextEpisode:
        if (controller.hasNextEpisode) controller.navigator(true);
        return KeyEventResult.handled;
      case ShortcutAction.previousEpisode:
        if (controller.hasPreviousEpisode) controller.navigator(false);
        return KeyEventResult.handled;
      case ShortcutAction.audioPane:
      case ShortcutAction.subtitlePane:
      case ShortcutAction.playlistPane:
        return KeyEventResult.ignored;
    }
  }

  void _adjustVolume(double delta) {
    final next = (controller.volume.value + delta).clamp(0.0, 1.0);
    controller.setVolume(next);
    controller.onUserInteraction();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}
