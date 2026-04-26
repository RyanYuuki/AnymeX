import 'package:anymex/controllers/services/cloud/cloud_auth_service.dart';
import 'package:anymex/controllers/services/cloud/cloud_realtime_service.dart';
import 'package:anymex/controllers/services/cloud/cloud_sync_service.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A compact cloud status indicator showing sync state.
/// Shows nothing when cloud is not active (guest/uninitialized mode).
/// Shows colored icon: green=synced, yellow=syncing, red=disconnected.
class CloudStatusIndicator extends StatelessWidget {
  const CloudStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<CloudAuthService>();
    final syncService = Get.find<CloudSyncService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      // Hide entirely when not in cloud mode
      if (!authService.isCloudMode) {
        return const SizedBox.shrink();
      }

      final isSyncing = syncService.isSyncing.value;
      final syncStatus = syncService.syncStatus.value;
      final realtimeConnected = Get.isRegistered<CloudRealtimeService>() &&
          Get.find<CloudRealtimeService>().isConnected.value;

      // Determine state
      Color iconColor;
      IconData iconData;
      String tooltip;

      if (isSyncing) {
        iconColor = Colors.amber;
        iconData = Icons.cloud_sync_rounded;
        tooltip = 'Syncing...';
      } else if (realtimeConnected) {
        iconColor = Colors.green;
        iconData = Icons.cloud_done_rounded;
        tooltip = 'Connected & synced';
      } else {
        iconColor = Colors.orange.shade400;
        iconData = Icons.cloud_outlined;
        tooltip = 'Connected (offline mode)';
      }

      if (syncStatus.isNotEmpty && isSyncing) {
        tooltip = syncStatus;
      }

      return GestureDetector(
        onTap: () => _showStatusSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconData,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 4),
              // Small status dot
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showStatusSheet(BuildContext context) {
    final authService = Get.find<CloudAuthService>();
    final syncService = Get.find<CloudSyncService>();
    final onSurface = context.colors.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(context);
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Cloud Sync Status',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _statusRow('Account', authService.username.value),
              _statusRow(
                'Mode',
                authService.isCloudMode ? 'Cloud (main)' : 'Guest',
              ),
              _statusRow(
                'Last Status',
                syncService.syncStatus.value.isEmpty
                    ? 'Idle'
                    : syncService.syncStatus.value,
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
