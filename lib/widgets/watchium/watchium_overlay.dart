import 'dart:io';

import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/controllers/watchium/watchium_sync_controller.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/custom_widgets/anymex_titlebar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WatchiumOverlay extends StatelessWidget {
  const WatchiumOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final watchium = Get.find<WatchiumService>();

    return Obx(() {
      if (!watchium.inRoom.value) return const SizedBox.shrink();
      final state = watchium.roomState.value;
      if (state == null) return const SizedBox.shrink();

      return ValueListenableBuilder<bool>(
        valueListenable: AnymexTitleBar.isFullScreen,
        builder: (_, isFullScreen, __) {
          final isWindows = !kIsWeb && Platform.isWindows;
          return Positioned(
            top: isWindows && !isFullScreen ? 48 : 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.live_tv, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Room ${state.code}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.people,
                      color: Colors.white70,
                      size: 14,
                    ),
                    Text(
                      '${state.members.where((m) => m.online).length}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    // Sync to host button (joiners only, when out of sync)
                    if (!watchium.isHost.value)
                      _SyncToHostButton()
                    else
                      const SizedBox.shrink(),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _togglePartyPanel(context, watchium),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Party',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  void _togglePartyPanel(BuildContext context, WatchiumService watchium) {
    Logger.d('Toggling party panel', 'WATCHIUM_UI');
    watchium.isPartyPaneOpened.value = !watchium.isPartyPaneOpened.value;
  }
}

/// Sync-to-host button for joiners.
/// Uses the [WatchiumSyncController] already registered by [WatchScreen]
/// (tag: 'watchiumSync'). Falls back to [SizedBox.shrink] if the controller
/// isn't registered yet (race-safe).
class _SyncToHostButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<WatchiumSyncController>(tag: 'watchiumSync')) {
      return const SizedBox.shrink();
    }
    final syncCtrl = Get.find<WatchiumSyncController>(tag: 'watchiumSync');
    return Obx(() {
      if (!syncCtrl.isOutOfSync.value) return const SizedBox.shrink();
      return GestureDetector(
        onTap: () => syncCtrl.syncToHost(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: Colors.orange.withValues(alpha: 0.6), width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync_problem, color: Colors.orange, size: 14),
              SizedBox(width: 4),
              Text(
                'Sync',
                style: TextStyle(color: Colors.orange, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    });
  }
}