import 'package:anymex/controllers/sync/cloud_sync_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class ProgressSyncSection extends StatelessWidget {
  const ProgressSyncSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CloudSyncController>()) {
      Get.put(CloudSyncController());
    }
    final controller = Get.find<CloudSyncController>();
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: AnymexText(
            text: 'PROGRESS SYNC',
            variant: TextVariant.bold,
            color: colors.onSurfaceVariant.withOpacity(0.7),
            size: 12,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 10.0),
          child: AnymexText(
            text: 'Keep your watch position in sync across all your devices. '
                'When you switch from phone to PC, you\'ll resume right where you left off.',
            color: colors.onSurfaceVariant.withOpacity(0.55),
            size: 11,
          ),
        ),
        const SizedBox(height: 4),
        _SyncCard(controller: controller),
      ],
    );
  }
}

class _SyncCard extends StatelessWidget {
  final CloudSyncController controller;
  const _SyncCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Obx(() {
      final isSignedIn = controller.isSignedIn.value;
      final isSyncing = controller.isSyncing.value;
      final isAuthenticating = controller.isAuthenticating.value;
      final lastSync = controller.lastSyncTime.value;
      final syncEnabled = controller.syncEnabled.value;
      final isBusy = isSyncing || isAuthenticating;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSignedIn
                ? [
                    colors.primary.withOpacity(0.12),
                    colors.surfaceContainer.withOpacity(0.4),
                  ]
                : [
                    colors.surfaceContainer.withOpacity(0.4),
                    colors.surfaceContainerHighest.withOpacity(0.4),
                  ],
          ),
          border: Border.all(
            color: isSignedIn
                ? colors.primary.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  if (isBusy) return;
                  if (isSignedIn) {
                    _showManageSheet(context, controller);
                  } else {
                    controller.signIn();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildIcon(colors, isSignedIn, isBusy),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AnymexText(
                              text: 'Google Drive Sync',
                              variant: TextVariant.bold,
                              size: 16,
                            ),
                            const SizedBox(height: 4),
                            AnymexText(
                              text: _subtitle(
                                isSignedIn,
                                isSyncing,
                                isAuthenticating,
                                lastSync,
                              ),
                              color: isSignedIn
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                              size: 12,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSignedIn
                              ? colors.primary
                              : colors.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSignedIn ? Icons.cloud_done : Icons.cloud_upload,
                          color: isSignedIn
                              ? colors.onPrimary
                              : colors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isSignedIn)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20)
                      .copyWith(bottom: 12),
                  child: Row(
                    children: [
                      Icon(IconlyLight.tick_square,
                          size: 18, color: colors.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnymexText(
                          text: 'Automatically sync progress',
                          size: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Switch(
                        value: syncEnabled,
                        onChanged: (v) => controller.syncEnabled.value = v,
                        activeColor: colors.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  String _subtitle(bool isSignedIn, bool isSyncing, bool isAuthenticating,
      DateTime? lastSync) {
    if (isAuthenticating) return 'Opening Google sign-in…';
    if (!isSignedIn) return 'Sign in to sync progress across devices';
    if (isSyncing) return 'Syncing…';
    if (lastSync == null) return 'Connected · waiting for first sync';
    final diff = DateTime.now().difference(lastSync);
    if (diff.inSeconds < 60) return 'Last synced just now';
    if (diff.inMinutes < 60) return 'Last synced ${diff.inMinutes}m ago';
    return 'Last synced ${diff.inHours}h ago';
  }

  Widget _buildIcon(dynamic colors, bool isSignedIn, bool isBusy) {
    if (isBusy) {
      return SizedBox(
        width: 56,
        height: 56,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: colors.primary,
        ),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isSignedIn
            ? colors.primary.withOpacity(0.15)
            : colors.surfaceContainerHighest.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.cloud_sync,
        color: isSignedIn ? colors.primary : colors.onSurfaceVariant,
        size: 28,
      ),
    );
  }

  void _showManageSheet(BuildContext context, CloudSyncController controller) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnymexText(
                text: 'Manage Progress Sync',
                variant: TextVariant.bold,
                size: 18),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(IconlyLight.logout),
              title: const Text('Sign out'),
              subtitle: const Text('Progress sync will be disabled'),
              onTap: () {
                controller.signOut();
                Navigator.pop(ctx);
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: colors.surfaceContainer,
            ),
          ],
        ),
      ),
    );
  }
}
