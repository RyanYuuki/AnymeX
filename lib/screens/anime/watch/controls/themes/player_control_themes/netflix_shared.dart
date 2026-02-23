import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/bottom_sheet.dart';
import 'package:anymex/screens/settings/sub_settings/settings_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class NFColors {
  static const white = Color(0xFFFFFFFF);
  static const white70 = Color(0xB3FFFFFF);
  static const white50 = Color(0x80FFFFFF);
  static const netflixRed = Color(0xFFE50914);
}

String buildNFTitle(PlayerController c) {
  final epNum = c.currentEpisode.value.number;
  final epTitle = c.currentEpisode.value.title;
  if (epNum != null && epNum != 'Offline') {
    if (epTitle != null && epTitle.isNotEmpty) return 'E$epNum: $epTitle';
    return 'Episode $epNum';
  }
  return c.itemName ?? '';
}

void showNFMoreSheet(BuildContext context, PlayerController controller) {
  showBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => NFMoreSheet(controller: controller, ctx: context),
  );
}

class NFSeekButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const NFSeekButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Icon(
          icon,
          color: NFColors.white,
          size: 56,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 10)],
        ),
      ),
    );
  }
}

class NFCenterPlayPause extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;

  const NFCenterPlayPause({
    super.key,
    required this.isPlaying,
    required this.isBuffering,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: isBuffering
            ? const SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                    color: NFColors.netflixRed, strokeWidth: 4),
              )
            : Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey(isPlaying),
                color: NFColors.white,
                size: 88,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 15)],
              ),
      ),
    );
  }
}

class NFLabeledButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const NFLabeledButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? NFColors.white : NFColors.white50;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class NFDesktopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final double size;

  const NFDesktopButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Icon(icon,
            color: enabled ? NFColors.white : NFColors.white50, size: size),
      ),
    );
  }
}

class NFRawButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const NFRawButton({super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    );
  }
}

class NFVerticalScrim extends StatelessWidget {
  final Widget child;
  final bool fromTop;
  final double height;

  const NFVerticalScrim({
    super.key,
    required this.child,
    required this.fromTop,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
          end: fromTop ? Alignment.bottomCenter : Alignment.topCenter,
          colors: const [Colors.black87, Colors.black45, Colors.transparent],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: child,
    );
  }
}

class NFUnlockButton extends StatefulWidget {
  final VoidCallback onUnlock;
  const NFUnlockButton({super.key, required this.onUnlock});

  @override
  State<NFUnlockButton> createState() => _NFUnlockButtonState();
}

class _NFUnlockButtonState extends State<NFUnlockButton> {
  bool _confirm = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_confirm) {
          widget.onUnlock();
        } else {
          setState(() => _confirm = true);
          Future.delayed(const Duration(seconds: 2),
              () => mounted ? setState(() => _confirm = false) : null);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _confirm
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.6),
          border: Border.all(color: NFColors.white70, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_open_rounded,
                color: NFColors.white, size: 22),
            if (_confirm) ...[
              const SizedBox(width: 12),
              const Text(
                'Tap again to unlock',
                style: TextStyle(
                  color: NFColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NFMoreSheet extends StatelessWidget {
  final PlayerController controller;
  final BuildContext ctx;

  const NFMoreSheet({super.key, required this.controller, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          NFSheetTile(
            icon: Symbols.high_quality_rounded,
            label: 'Quality',
            onTap: () {
              Get.back();
              PlayerBottomSheets.showVideoQuality(ctx, controller);
            },
          ),
          NFSheetTile(
            icon: Symbols.speed_rounded,
            label: 'Playback speed',
            onTap: () {
              Get.back();
              PlayerBottomSheets.showPlaybackSpeed(ctx, controller);
            },
          ),
          NFSheetTile(
            icon: Symbols.music_note_rounded,
            label: 'Audio track',
            onTap: () {
              Get.back();
              PlayerBottomSheets.showAudioTracks(ctx, controller);
            },
          ),
          NFSheetTile(
            icon: Symbols.tune_rounded,
            label: 'Picture & shaders',
            onTap: () {
              Get.back();
              controller.openColorProfileBottomSheet(ctx);
            },
          ),
          if (!controller.isOffline.value)
            NFSheetTile(
              icon: Symbols.cloud_rounded,
              label: 'Server',
              onTap: () {
                Get.back();
                PlayerBottomSheets.showVideoServers(ctx, controller);
              },
            ),
          NFSheetTile(
            icon: Icons.settings_outlined,
            label: 'Player settings',
            onTap: () {
              Get.back();
              showModalBottomSheet(
                context: Get.context!,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (c) => SizedBox(
                  height: MediaQuery.of(c).size.height,
                  child: const SettingsPlayer(isModal: true),
                ),
              );
            },
          ),
          NFSheetTile(
            icon: Icons.lock_outline_rounded,
            label: 'Lock screen',
            onTap: () {
              Get.back();
              controller.isLocked.value = true;
            },
          ),
          if (MediaQuery.sizeOf(context).width < 600)
            NFSheetTile(
              icon: Icons.screen_rotation_alt_rounded,
              label: 'Rotate',
              onTap: () {
                Get.back();
                controller.toggleOrientation();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class NFSheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const NFSheetTile(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: NFColors.white70, size: 26),
      title: Text(
        label,
        style: const TextStyle(
          color: NFColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}

class VerticalScrim extends StatelessWidget {
  final Widget child;
  final bool fromTop;
  final double height;

  const VerticalScrim({
    super.key,
    required this.child,
    required this.fromTop,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
          end: fromTop ? Alignment.bottomCenter : Alignment.topCenter,
          colors: const [Colors.black87, Colors.black45, Colors.transparent],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: child,
    );
  }
}
