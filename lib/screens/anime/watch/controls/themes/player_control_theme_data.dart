import 'dart:io';

import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:flutter/material.dart';

class PlayerTopSectionData {
  final PlayerController controller;
  final ThemeData theme;
  final bool isDesktop;
  final bool isDark;

  const PlayerTopSectionData({
    required this.controller,
    required this.theme,
    required this.isDesktop,
    required this.isDark,
  });

  String get episodeTitle =>
      controller.currentEpisode.value.title ??
      controller.itemName ??
      'Unknown Title';

  String get animeTitle =>
      (controller.anilistData.title == '?'
          ? controller.folderName
          : controller.anilistData.title) ??
      '';

  String get episodeLabel => controller.currentEpisode.value.number == 'Offline'
      ? 'Offline'
      : 'Episode ${controller.currentEpisode.value.number}';

  int? get videoHeight => controller.videoHeight.value;

  factory PlayerTopSectionData.fromContext(
    BuildContext context,
    PlayerController controller,
  ) {
    final theme = Theme.of(context);
    return PlayerTopSectionData(
      controller: controller,
      theme: theme,
      isDesktop: !Platform.isAndroid && !Platform.isIOS,
      isDark: theme.brightness == Brightness.dark,
    );
  }
}

class PlayerCenterSectionData {
  final PlayerController controller;
  final ThemeData theme;
  final bool isDesktop;

  const PlayerCenterSectionData({
    required this.controller,
    required this.theme,
    required this.isDesktop,
  });

  factory PlayerCenterSectionData.fromContext(
    BuildContext context,
    PlayerController controller,
  ) {
    return PlayerCenterSectionData(
      controller: controller,
      theme: Theme.of(context),
      isDesktop: !Platform.isAndroid && !Platform.isIOS,
    );
  }
}

class PlayerBottomSectionData {
  final PlayerController controller;
  final ThemeData theme;
  final bool isDesktop;
  final bool isDark;
  final String skipDurationLabel;

  const PlayerBottomSectionData({
    required this.controller,
    required this.theme,
    required this.isDesktop,
    required this.isDark,
    required this.skipDurationLabel,
  });

  factory PlayerBottomSectionData.fromContext(
    BuildContext context,
    PlayerController controller,
  ) {
    final theme = Theme.of(context);
    return PlayerBottomSectionData(
      controller: controller,
      theme: theme,
      isDesktop: !Platform.isAndroid && !Platform.isIOS,
      isDark: theme.brightness == Brightness.dark,
      skipDurationLabel: '+${controller.playerSettings.skipDuration}',
    );
  }
}
