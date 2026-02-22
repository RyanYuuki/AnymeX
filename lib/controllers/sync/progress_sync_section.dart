import 'package:anymex/controllers/sync/gist_sync_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class ProgressSyncSection extends StatelessWidget {
  const ProgressSyncSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<GistSyncController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: AnymexText(
            text: 'PROGRESS SYNC',
            variant: TextVariant.bold,
            color: context.colors.onSurfaceVariant.withOpacity(0.7),
            size: 12,
          ),
        ),
        const SizedBox(height: 12),
        _GistSyncCard(ctrl: ctrl),
      ],
    );
  }
}

class _GistSyncCard extends StatelessWidget {
  final GistSyncController ctrl;
  const _GistSyncCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Obx(() {
      final isLogged = ctrl.isLoggedIn.value;
      final username =
          isLogged ? (ctrl.githubUsername.value ?? 'GitHub User') : '';
      final isSyncing = ctrl.isSyncing.value;
      final syncEnabled = ctrl.syncEnabled.value;
      final lastSync = ctrl.lastSyncTime.value;

      return Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLogged
                ? const Color(0xFF238636).withOpacity(0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  if (isLogged) {
                    _showManageSheet(context, ctrl);
                  } else {
                    ctrl.login(context);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      _buildIcon(isLogged, isSyncing, colors),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AnymexText(
                              text: 'GitHub Gist Sync',
                              variant: TextVariant.semiBold,
                              size: 16,
                            ),
                            const SizedBox(height: 2),
                            AnymexText(
                              text: _subtitle(isLogged, isSyncing, lastSync,
                                  username: username),
                              size: 12,
                              color: isLogged
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isLogged
                              ? colors.surfaceContainerHigh
                              : const Color(0xFF238636).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AnymexText(
                          text: isLogged ? 'Manage' : 'Connect',
                          variant: TextVariant.bold,
                          size: 12,
                          color: isLogged
                              ? colors.onSurface
                              : const Color(0xFF238636),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (isLogged)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: colors.outlineVariant.withOpacity(0.3)),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Icon(IconlyLight.tick_square,
                            size: 16, color: colors.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AnymexText(
                            text: 'Auto-sync while watching / reading',
                            size: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Switch(
                          value: syncEnabled,
                          onChanged: (v) => ctrl.syncEnabled.value = v,
                          activeColor: colors.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  String _subtitle(
    bool isLogged,
    bool isSyncing,
    DateTime? lastSync, {
    String username = '',
  }) {
    if (!isLogged) return 'Resume progress across all your devices';
    if (isSyncing) return 'Syncing...';
    if (lastSync == null) {
      return 'Connected as $username · waiting for first sync';
    }
    final diff = DateTime.now().difference(lastSync);
    if (diff.inSeconds < 60) return 'Connected as $username · synced just now';
    if (diff.inMinutes < 60) {
      return 'Connected as $username · synced ${diff.inMinutes}m ago';
    }
    return 'Connected as $username · synced ${diff.inHours}h ago';
  }

  Widget _buildIcon(bool isLogged, bool isSyncing, dynamic colors) {
    if (isSyncing) {
      return SizedBox(
        width: 44,
        height: 44,
        child: CircularProgressIndicator(
            strokeWidth: 2.5, color: colors.primary),
      );
    }

    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isLogged
            ? const Color(0xFF238636).withOpacity(0.15)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.cloud_sync_rounded,
        color: isLogged ? const Color(0xFF238636) : colors.onSurfaceVariant,
      ),
    );
  }

  void _showManageSheet(BuildContext context, GistSyncController ctrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnymexText(
              text: 'Manage GitHub Gist Sync',
              variant: TextVariant.bold,
              size: 18,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(IconlyLight.logout),
              title: const Text('Log Out'),
              onTap: () {
                ctrl.logout();
                Navigator.pop(ctx);
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: context.colors.surfaceContainer,
            ),
          ],
        ),
      ),
    );
  }
}
