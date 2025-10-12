import 'dart:io';
import 'dart:ui' as ui;
import 'package:anymex/screens/anime/watch/controls/widgets/control_button.dart';
import 'package:anymex/screens/settings/sub_settings/settings_player.dart';
import 'package:anymex/utils/function.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';

class TopControls extends StatelessWidget {
  final bool enableBlur;

  const TopControls({
    super.key,
    this.enableBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;
    final theme = Theme.of(context);

    return Obx(() => IgnorePointer(
          ignoring: !controller.showControls.value,
          child: AnimatedSlide(
            offset: controller.showControls.value
                ? Offset.zero
                : const Offset(0, -1),
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
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent
                    ],
                  ),
                ),
                child: enableBlur
                    ? BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: _buildContent(theme, isDesktop),
                      )
                    : _buildContent(theme, isDesktop),
              ),
            ),
          ),
        ));
  }

  Widget _buildContent(ThemeData theme, bool isDesktop) {
    return SafeArea(
      bottom: false,
      left: false,
      right: false,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 20,
          vertical: isDesktop ? 24 : 8,
        ),
        child: isDesktop ? _buildLayout(theme) : _buildMobileLayout(theme),
      ),
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    final controller = Get.find<PlayerController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ControlButton(
            icon: Icons.arrow_back_ios_rounded,
            onPressed: () => Get.back(),
            tooltip: 'Back',
            isPrimary: true,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      controller.currentEpisode.value.title ??
                          controller.itemName ??
                          'Unknown Title',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    10.width(),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          controller.currentEpisode.value.number == "Offline"
                              ? "Offline"
                              : "Episode ${controller.currentEpisode.value.number}",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (controller.anilistData.title == "?"
                            ? controller.folderName
                            : controller.anilistData.title) ??
                        '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ControlButton(
            icon: Icons.settings_rounded,
            onPressed: () {
              showModalBottomSheet(
                  context: Get.context!,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                        height: MediaQuery.of(context).size.height,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        child: const SettingsPlayer(
                          isModal: true,
                        ),
                      ));
            },
            tooltip: 'Settings',
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLayout(ThemeData theme) {
    final controller = Get.find<PlayerController>();

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                ControlButton(
                  icon: Icons.arrow_back_ios_rounded,
                  onPressed: () => Get.back(),
                  tooltip: 'Back',
                  isPrimary: true,
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            controller.currentEpisode.value.title ??
                                controller.itemName ??
                                'Unknown Title',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontFamily: 'Poppins-SemiBold',
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          10.width(),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                controller.currentEpisode.value.number ==
                                        "Offline"
                                    ? "Offline"
                                    : "Episode ${controller.currentEpisode.value.number}",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (controller.anilistData.title == "?"
                                  ? controller.folderName
                                  : controller.anilistData.title) ??
                              '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ControlButton(
                icon: Icons.fullscreen_rounded,
                onPressed: () => controller.toggleFullScreen(),
                tooltip: 'Fullscreen',
                compact: true,
              ),
              const SizedBox(width: 8),
              ControlButton(
                icon: Icons.settings_rounded,
                onPressed: () {
                  showModalBottomSheet(
                      context: Get.context!,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Container(
                            height: MediaQuery.of(context).size.height,
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(28)),
                            ),
                            child: const SettingsPlayer(
                              isModal: true,
                            ),
                          ));
                },
                tooltip: 'Settings',
                compact: true,
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }
}
