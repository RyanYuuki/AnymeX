import 'dart:convert';
import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/bottom_sheet.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/control_button.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/progress_slider.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
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
      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: AnimatedSlide(
          offset:
              controller.showControls.value ? Offset.zero : const Offset(0, 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: controller.showControls.value ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: Container(
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
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLayout(BuildContext context) {
    final controller = Get.find<PlayerController>();
    final settings = Get.find<Settings>();
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;

    final String jsonString =
        settings.preferences.get('bottomControlsSettings', defaultValue: '{}');
    final Map<String, dynamic> decodedConfig = json.decode(jsonString);

    final List<String> leftButtonIds =
        List<String>.from(decodedConfig['leftButtonIds'] ?? []);
    final List<String> rightButtonIds =
        List<String>.from(decodedConfig['rightButtonIds'] ?? []);
    final Map<String, dynamic> buttonConfigs =
        Map<String, dynamic>.from(decodedConfig['buttonConfigs'] ?? {});

    bool isVisible(String id) =>
        (buttonConfigs[id]?['visible'] as bool?) ?? true;

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
      'subtitles': !controller.isOffline.value
          ? ControlButton(
              icon: Symbols.subtitles_rounded,
              onPressed: () => PlayerBottomSheets.showSubtitleTracks(
                context,
                controller,
              ),
              tooltip: 'Subtitles',
              compact: true,
            )
          : ControlButton(
              icon: Symbols.subtitles_rounded,
              onPressed: () => PlayerBottomSheets.showOfflineSubs(
                context,
                controller,
              ),
              tooltip: 'Subtitles',
              compact: true,
            ),
      'server': ControlButton(
        icon: Symbols.cloud_rounded,
        onPressed: () {
          PlayerBottomSheets.showVideoServers(context, controller);
        },
        tooltip: 'Server',
        compact: true,
      ),
      'quality': ControlButton(
        icon: Symbols.high_quality_rounded,
        onPressed: () =>
            PlayerBottomSheets.showVideoQuality(context, controller),
        tooltip: 'Quality',
        compact: true,
      ),
      'speed': ControlButton(
        icon: Symbols.speed_rounded,
        onPressed: () =>
            PlayerBottomSheets.showPlaybackSpeed(context, controller),
        tooltip: 'Speed',
        compact: true,
      ),
      'audio_track': ControlButton(
        icon: Symbols.music_note_rounded,
        onPressed: () =>
            PlayerBottomSheets.showAudioTracks(context, controller),
        tooltip: 'Audio Track',
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
        tooltip: 'Aspect Ratio',
        compact: true,
      ),
    };

    List<Widget> buildButtonList(List<String> ids) {
      final regularButtons = <Widget>[];
      final compactButtons = <Widget>[];

      for (var id in ids) {
        if (!isVisible(id)) continue;
        if (id == 'server' && controller.isOffline.value) continue;
        if (id == 'quality' && controller.isOffline.value) continue;
        if (id == 'orientation' && !(Platform.isAndroid || Platform.isIOS))
          continue;

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
                  ? theme.colorScheme.surfaceVariant.withOpacity(0.2)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? theme.colorScheme.outline.withOpacity(0.15)
                    : theme.colorScheme.outline.withOpacity(0.3),
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
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
              child: InkWell(
                onTap: controller.isLocked.value
                    ? null
                    : () => controller
                        .megaSeek(controller.playerSettings.skipDuration),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surfaceContainer
                            .withValues(alpha: 0.6)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? theme.colorScheme.outline
                          : theme.colorScheme.outline.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                  child: AnymexText(
                    text: '+${controller.playerSettings.skipDuration}',
                    variant: TextVariant.semiBold,
                    color: controller.isLocked.value
                        ? theme.colorScheme.onSurface.withOpacity(0.4)
                        : null,
                  ),
                ),
              ),
            ),
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
                          ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? theme.colorScheme.outline.withOpacity(0.2)
                            : theme.colorScheme.outline.withOpacity(0.4),
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
                          ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? theme.colorScheme.outline.withOpacity(0.2)
                            : theme.colorScheme.outline.withOpacity(0.4),
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