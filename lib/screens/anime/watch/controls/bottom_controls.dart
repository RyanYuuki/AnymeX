import 'dart:convert';
import 'dart:io';

import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/bottom_sheet.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/control_button.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/progress_slider.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class BottomControls extends StatelessWidget {
  const BottomControls({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;

    return Obx(() {
      if (controller.isLocked.value) {
        if (!controller.showControls.value) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 20,
                vertical: isDesktop ? 24 : 8,
              ),
              child: IgnorePointer(
                ignoring: true,
                child: Opacity(
                  opacity: 0.7,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    child: const ProgressSlider(),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      final showControls = controller.showControls.value;
      final inSkipSegment = controller.currentSkipInterval.value != null;
      final bottomBarVisible = showControls || inSkipSegment;

      return IgnorePointer(
        ignoring: !bottomBarVisible,
        child: AnimatedSlide(
          offset: bottomBarVisible ? Offset.zero : const Offset(0, 1),
          duration: controller.overlayAnimationDuration(400),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: bottomBarVisible ? 1.0 : 0.0,
            duration: controller.overlayAnimationDuration(300),
            curve: Curves.easeOut,
            child: showControls
                ? _buildFullBar(context, isDesktop)
                : _buildStandaloneSkip(context, isDesktop),
          ),
        ),
      );
    });
  }

  Widget _buildStandaloneSkip(BuildContext context, bool isDesktop) {
    final horizontal = isDesktop ? 32.0 : 20.0;
    final vertical = isDesktop ? 24.0 : 8.0;
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: horizontal + 20,
            bottom: vertical + 5,
            child: _buildSkipButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBar(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 20,
            vertical: isDesktop ? 24 : 8,
          ),
          child: _buildLayout(context),
        ),
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    final controller = Get.find<PlayerController>();
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final isCountdownActive = controller.isAutoSkipCountdownActive;
      final interval = controller.currentSkipInterval.value;
      final inSegment = interval != null || isCountdownActive;
      final progress = isCountdownActive
          ? 1.0 -
              (controller.autoSkipCountdownRemaining.value /
                  PlayerController.autoSkipCountdownSeconds)
          : 0.0;

      return Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap:
              controller.isLocked.value ? null : controller.performSkipAction,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? theme.colorScheme.outline
                    : theme.colorScheme.outline.opaque(0.5),
                width: 0.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isCountdownActive)
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.linear,
                      tween: Tween<double>(begin: 0.0, end: progress),
                      builder: (context, value, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (inSegment)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            isCountdownActive
                                ? Icons.close_rounded
                                : Icons.skip_next_rounded,
                            color: controller.isLocked.value
                                ? theme.colorScheme.onSurface.opaque(0.4)
                                : theme.colorScheme.onSurface,
                            size: 20,
                          ),
                        ),
                      AnymexText(
                        text: controller.skipButtonLabel,
                        variant: TextVariant.semiBold,
                        color: controller.isLocked.value
                            ? theme.colorScheme.onSurface.opaque(0.4)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLayout(BuildContext context) {
    final controller = Get.find<PlayerController>();
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;

    final String jsonString =
        PlayerUiKeys.bottomControlsSettings.get<String>('{}');
    final Map<String, dynamic> decodedConfig = json.decode(jsonString);

    final List<String> leftButtonIds =
        List<String>.from(decodedConfig['leftButtonIds'] ?? []);
    final List<String> rightButtonIds =
        List<String>.from(decodedConfig['rightButtonIds'] ?? []);
    final Map<String, dynamic> buttonConfigs =
        Map<String, dynamic>.from(decodedConfig['buttonConfigs'] ?? {});

    bool isVisible(String id) =>
        (buttonConfigs[id]?['visible'] as bool?) ?? true;

    final serverCount = controller.episodeTracks.length;

    final Map<String, Widget> buttonWidgets = {
      'playlist': ControlButton(
        icon: Symbols.playlist_play_rounded,
        onPressed: () {
          controller.isEpisodePaneOpened.value =
              !controller.isEpisodePaneOpened.value;
        },
        tooltip: 'Playlist',
        compact: true,
      ),
      'shaders': ControlButton(
        icon: Symbols.tune_rounded,
        onPressed: () => controller.openColorProfileBottomSheet(context),
        tooltip: 'Shaders & Color Profiles',
        compact: true,
      ),
      'source': ControlButton(
        icon: Symbols.cloud_rounded,
        onPressed: () {
          controller.isSourcePaneOpened.value =
              !controller.isSourcePaneOpened.value;
        },
        tooltip: 'Source',
        compact: true,
      ),
      'tracks': ControlButton(
        icon: Symbols.library_music_rounded,
        onPressed: () {
          controller.isTracksPaneOpened.value =
              !controller.isTracksPaneOpened.value;
        },
        tooltip: 'Tracks',
        compact: true,
      ),
      'sync_subs': ControlButton(
        icon: Symbols.sync_rounded,
        onPressed: () {
          controller.isSyncSubsPaneOpened.value =
              !controller.isSyncSubsPaneOpened.value;
        },
        tooltip: 'Sync Subtitles',
        compact: true,
      ),
      'speed': ControlButton(
        icon: Symbols.speed_rounded,
        onPressed: () =>
            PlayerBottomSheets.showPlaybackSpeed(context, controller),
        tooltip: 'Speed',
        compact: true,
      ),
      'orientation': ControlButton(
        icon: Icons.screen_rotation_rounded,
        onPressed: () => controller.toggleOrientation(),
        tooltip: 'Toggle Orientation',
        compact: true,
      ),
      'aspect_ratio': ControlButton(
        icon: Symbols.fit_screen,
        onPressed: () => controller.toggleVideoFit(),
        onLongPress: controller.resetVideoFit,
        tooltip: 'Aspect Ratio',
        compact: true,
      ),
    };

    List<Widget> buildButtonList(List<String> ids) {
      final regularButtons = <Widget>[];
      final compactButtons = <Widget>[];

      for (var id in ids) {
        if (!isVisible(id)) continue;
        if (id == 'source' && (controller.isOffline.value || (serverCount <= 1 && controller.getCurrentStreamSubtitleOptions().isEmpty))) continue;
        if (id == 'tracks' && (controller.embeddedAudioTracks.value.isEmpty && controller.embeddedSubs.value.isEmpty)) continue;
        if (id == 'orientation' && !(Platform.isAndroid || Platform.isIOS)) {
          continue;
        }

        final widget = buttonWidgets[id];
        if (widget != null) {
          if (widget is ControlButton && widget.compact) {
            compactButtons.add(widget);
          } else {
            regularButtons.add(widget);
          }
        }
      }

      if (compactButtons.isNotEmpty) {
        regularButtons.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceVariant.opaque(0.2)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? theme.colorScheme.outline.opaque(0.15)
                    : theme.colorScheme.outline.opaque(0.3),
                width: 0.5,
              ),
            ),
            child:
                Row(mainAxisSize: MainAxisSize.min, children: compactButtons),
          ),
        );
      }
      return regularButtons;
    }

    final leftButtons = buildButtonList(leftButtonIds);
    final rightButtons = buildButtonList(rightButtonIds);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 20, 5),
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildSkipButton(context),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          child: const ProgressSlider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surfaceVariant.opaque(0.3)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? theme.colorScheme.outline.opaque(0.2)
                            : theme.colorScheme.outline.opaque(0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Obx(() => Text(
                          controller.formattedCurrentPosition,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        )),
                  ),
                  if (leftButtons.isNotEmpty) const SizedBox(width: 16),
                  ...leftButtons,
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  ...rightButtons,
                  if (rightButtons.isNotEmpty) const SizedBox(width: 20),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surfaceVariant.opaque(0.3)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? theme.colorScheme.outline.opaque(0.2)
                            : theme.colorScheme.outline.opaque(0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Obx(() => Text(
                          controller.formattedEpisodeDuration,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
