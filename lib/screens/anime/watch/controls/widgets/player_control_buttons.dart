import 'dart:convert';
import 'dart:io';

import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/control_button.dart';
import 'package:anymex/services/cast/widgets/cast_device_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/l10n/l10n_extension.dart';

class PlayerControlItemMeta {
  final String id;
  final String name;
  final IconData icon;
  final String defaultSlot;

  const PlayerControlItemMeta({
    required this.id,
    required this.name,
    required this.icon,
    required this.defaultSlot,
  });
}

const List<PlayerControlItemMeta> playerControlCatalog = [
  PlayerControlItemMeta(
    id: 'lock',
    name: 'Lock Controls',
    icon: Icons.lock_rounded,
    defaultSlot: 'top',
  ),
  PlayerControlItemMeta(
    id: 'pip',
    name: 'Picture in Picture',
    icon: Icons.picture_in_picture_rounded,
    defaultSlot: 'top',
  ),
  PlayerControlItemMeta(
    id: 'settings',
    name: 'Player Settings',
    icon: Icons.settings_rounded,
    defaultSlot: 'top',
  ),
  PlayerControlItemMeta(
    id: 'chapters',
    name: 'Chapters',
    icon: Icons.bookmarks_rounded,
    defaultSlot: 'left',
  ),
  PlayerControlItemMeta(
    id: 'playlist',
    name: 'Playlist',
    icon: Icons.playlist_play_rounded,
    defaultSlot: 'left',
  ),
  PlayerControlItemMeta(
    id: 'torrent',
    name: 'Torrent Files',
    icon: Icons.folder_zip_rounded,
    defaultSlot: 'left',
  ),
  PlayerControlItemMeta(
    id: 'shaders',
    name: 'Shaders',
    icon: Icons.tune_rounded,
    defaultSlot: 'right',
  ),
  PlayerControlItemMeta(
    id: 'source',
    name: 'Quality',
    icon: Icons.high_quality_rounded,
    defaultSlot: 'right',
  ),
  PlayerControlItemMeta(
    id: 'tracks',
    name: 'Subtitles',
    icon: Icons.subtitles_rounded,
    defaultSlot: 'right',
  ),
  PlayerControlItemMeta(
    id: 'audio',
    name: 'Audio',
    icon: Icons.volume_up_rounded,
    defaultSlot: 'right',
  ),
  PlayerControlItemMeta(
    id: 'sync_subs',
    name: 'Sync Subs',
    icon: Icons.sync_rounded,
    defaultSlot: 'right',
  ),
  PlayerControlItemMeta(
    id: 'speed',
    name: 'Speed',
    icon: Icons.speed_rounded,
    defaultSlot: 'right',
  ),
  PlayerControlItemMeta(
    id: 'orientation',
    name: 'Orientation',
    icon: Icons.screen_rotation_rounded,
    defaultSlot: 'right',
  ),
  PlayerControlItemMeta(
    id: 'aspect_ratio',
    name: 'Aspect Ratio',
    icon: Icons.fit_screen,
    defaultSlot: 'right',
  ),
  PlayerControlItemMeta(
    id: 'external_player',
    name: 'External Player',
    icon: Icons.launch_rounded,
    defaultSlot: 'right',
  ),
  PlayerControlItemMeta(
    id: 'watch_together',
    name: 'Watch Together',
    icon: Icons.people_outline_rounded,
    defaultSlot: 'right',
  ),
  PlayerControlItemMeta(
    id: 'cast',
    name: 'Cast to Device',
    icon: Icons.cast_rounded,
    defaultSlot: 'right',
  ),
];

Map<String, dynamic> readPlayerControlConfig() {
  final raw = PlayerUiKeys.bottomControlsSettings.get<String>('{}');
  try {
    return Map<String, dynamic>.from(json.decode(raw) as Map);
  } catch (_) {
    return {};
  }
}

List<String> resolvePlayerTopButtonIds(Map<String, dynamic> decodedConfig) {
  if (decodedConfig.containsKey('topButtonIds')) {
    return List<String>.from(decodedConfig['topButtonIds'] ?? []);
  }
  return ['lock', 'pip', 'settings'];
}

Map<String, Widget> buildPlayerControlButtonMap(
  BuildContext context,
  PlayerController controller,
) {
  return {
    'chapters': ControlButton(
      icon: Icons.bookmarks_rounded,
      onPressed: () {
        controller.isChaptersPaneOpened.value =
            !controller.isChaptersPaneOpened.value;
      },
      tooltip: context.l10n.chaptersTimestamps,
      compact: true,
    ),
    'playlist': ControlButton(
      icon: Icons.playlist_play_rounded,
      onPressed: () {
        controller.isEpisodePaneOpened.value =
            !controller.isEpisodePaneOpened.value;
      },
      tooltip: context.l10n.playlist,
      compact: true,
    ),
    'torrent': ControlButton(
      icon: Icons.folder_zip_rounded,
      onPressed: () {
        controller.isTorrentFilesPaneOpened.value =
            !controller.isTorrentFilesPaneOpened.value;
      },
      tooltip: context.l10n.torrentFiles,
      compact: true,
    ),
    'shaders': ControlButton(
      icon: Icons.tune_rounded,
      onPressed: () => controller.openColorProfileBottomSheet(context),
      tooltip: context.l10n.shadersColorProfiles,
      compact: true,
    ),
    'source': ControlButton(
      icon: Icons.high_quality_rounded,
      onPressed: () {
        controller.isSourcePaneOpened.value =
            !controller.isSourcePaneOpened.value;
      },
      tooltip: context.l10n.playerQuality,
      compact: true,
    ),
    'tracks': ControlButton(
      icon: Icons.subtitles_rounded,
      onPressed: () {
        controller.isTracksPaneOpened.value =
            !controller.isTracksPaneOpened.value;
      },
      tooltip: context.l10n.playerSubtitles,
      compact: true,
    ),
    'audio': ControlButton(
      icon: Icons.volume_up_rounded,
      onPressed: () {
        controller.isAudioPaneOpened.value =
            !controller.isAudioPaneOpened.value;
      },
      tooltip: context.l10n.audio,
      compact: true,
    ),
    'sync_subs': ControlButton(
      icon: Icons.sync_rounded,
      onPressed: () {
        controller.isSyncSubsPaneOpened.value =
            !controller.isSyncSubsPaneOpened.value;
      },
      tooltip: context.l10n.syncSubtitles,
      compact: true,
    ),
    'speed': ControlButton(
      icon: Icons.speed_rounded,
      onPressed: () {
        controller.isSpeedPaneOpened.value =
            !controller.isSpeedPaneOpened.value;
      },
      tooltip: context.l10n.playerSpeed,
      compact: true,
    ),
    'orientation': Obx(() {
      final isLocked = controller.isOrientationLocked.value;
      return ControlButton(
        icon: isLocked
            ? Icons.screen_lock_rotation_rounded
            : Icons.screen_rotation_rounded,
        onPressed: () => controller.toggleOrientation(),
        tooltip: isLocked ? context.l10n.unlockOrientation : context.l10n.lockOrientation,
        compact: true,
      );
    }),
    'aspect_ratio': ControlButton(
      icon: Icons.fit_screen,
      onPressed: () => controller.toggleVideoFit(),
      onLongPress: controller.resetVideoFit,
      tooltip: context.l10n.aspectRatio,
      compact: true,
    ),
    'external_player': ControlButton(
      icon: Icons.launch_rounded,
      onPressed: () => controller.launchExternalPlayer(),
      tooltip: context.l10n.externalPlayer,
      compact: true,
    ),
    'watch_together': Obx(() {
      if (!Get.isRegistered<WatchiumService>()) {
        return ControlButton(
          icon: Icons.people_outline_rounded,
          onPressed: () {},
          tooltip: context.l10n.watchTogether,
          compact: true,
        );
      }
      final watchium = Get.find<WatchiumService>();
      final inRoom = watchium.inRoom.value;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          ControlButton(
            icon: inRoom
                ? Icons.people_rounded
                : Icons.people_outline_rounded,
            onPressed: () {
              if (inRoom) {
                watchium.isPartyPaneOpened.value =
                    !watchium.isPartyPaneOpened.value;
              } else {
                controller.isWatchTogetherPaneOpened.value =
                    !controller.isWatchTogetherPaneOpened.value;
              }
            },
            tooltip: inRoom ? context.l10n.watchTogetherInRoom : context.l10n.watchTogether,
            compact: true,
          ),
          if (inRoom)
            Positioned(
              right: 1,
              top: 1,
              child: IgnorePointer(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }),
    'cast': ControlButton(
      icon: Icons.cast_rounded,
      onPressed: () => CastDeviceDialog.show(context, controller),
      tooltip: context.l10n.castToDevice,
      compact: true,
    ),
    'lock': ControlButton(
      icon: Icons.lock_rounded,
      onPressed: () => controller.isLocked.value = true,
      tooltip: context.l10n.lockControls,
      compact: true,
    ),
    'pip': ControlButton(
      icon: Icons.picture_in_picture_rounded,
      onPressed: () => controller.enterPip(),
      tooltip: context.l10n.pictureInPicture,
      compact: true,
    ),
    'settings': ControlButton(
      icon: Icons.settings_rounded,
      onPressed: () {
        if (controller.isPreview) return;
        controller.isSettingsPaneOpened.value =
            !controller.isSettingsPaneOpened.value;
      },
      tooltip: context.l10n.labelSettings,
      compact: true,
    ),
  };
}

bool shouldDisplayPlayerControl(String id, PlayerController controller) {
  if (id == 'orientation' && !(Platform.isAndroid || Platform.isIOS)) {
    return false;
  }
  if (id == 'pip' && !(Platform.isAndroid || Platform.isIOS)) {
    return false;
  }
  if (id == 'watch_together' && controller.isOffline.value) {
    return false;
  }
  if (id == 'torrent' && !controller.isTorrentStream.value) {
    return false;
  }
  if (id == 'chapters' && controller.chapters.isEmpty && controller.skipSegments.isEmpty) {
    return false;
  }
  return true;
}
