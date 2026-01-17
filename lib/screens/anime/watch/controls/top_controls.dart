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

    return Obx(() {
      if (controller.isLocked.value) {
        if (!controller.showControls.value) {
          return const SizedBox.shrink();
        }
        return Align(
          alignment: Alignment.centerRight,
          child: _UnlockButton(
            onUnlock: () => controller.isLocked.value = false,
          ),
        );
      }
      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: AnimatedSlide(
          offset:
              controller.showControls.value ? Offset.zero : const Offset(0, -1),
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
      );
    });
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
          Obx(
            () => _QualityChip(
                videoHeight: controller.videoHeight.value, isMobile: true),
          ),
          const SizedBox(width: 8),
          ControlButton(
            icon: Icons.lock_rounded,
            onPressed: () => controller.isLocked.value = true,
            tooltip: 'Lock Controls',
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
        Obx(
          () => _QualityChip(
              videoHeight: controller.videoHeight.value, isMobile: false),
        ),
        const SizedBox(width: 8),
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

class _QualityChip extends StatelessWidget {
  final int? videoHeight;
  final bool isMobile;

  const _QualityChip({required this.videoHeight, required this.isMobile});

  String get _qualityText {
    if (videoHeight == null) return '';
    if (videoHeight! >= 2160) return '2160p';
    if (videoHeight! >= 1440) return '1440p';
    if (videoHeight! >= 1080) return '1080p';
    if (videoHeight! >= 720) return '720p';
    if (videoHeight! >= 480) return '480p';
    if (videoHeight! >= 360) return '360p';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_qualityText.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12, vertical: isMobile ? 2 : 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
      ),
      child: Text(
        _qualityText,
        style:
            (isMobile ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
                ?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 12 : null,
        ),
      ),
    );
  }
}

// Unlock button widget
class _UnlockButton extends StatefulWidget {
  final VoidCallback onUnlock;
  const _UnlockButton({required this.onUnlock});

  @override
  State<_UnlockButton> createState() => _UnlockButtonState();
}

class _UnlockButtonState extends State<_UnlockButton> {
  bool _confirm = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 24),
      child: GestureDetector(
        onTap: () {
          if (_confirm) {
            widget.onUnlock();
          } else {
            setState(() {
              _confirm = true;
            });
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _confirm = false);
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_open_rounded, // open lock for unlock popup
                color: theme.colorScheme.primary,
                size: 22,
              ),
              if (_confirm) ...[
                const SizedBox(width: 8),
                Text(
                  "Are you sure?",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
