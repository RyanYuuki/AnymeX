import 'dart:async';

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
      final autoDeleteCompletedOnExit = ctrl.autoDeleteCompletedOnExit.value;
      final lastSync = ctrl.lastSyncTime.value;
      final lastSyncSuccessful = ctrl.lastSyncSuccessful.value;
      final lastSyncDurationMs = ctrl.lastSyncDurationMs.value;
      final lastSyncError = ctrl.lastSyncError.value;

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                              text: _subtitle(isLogged, username: username),
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
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: colors.outlineVariant.withOpacity(0.25),
                    ),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor(
                            colors,
                            isLogged: isLogged,
                            isSyncing: isSyncing,
                            lastSyncSuccessful: lastSyncSuccessful,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnymexText(
                          text: _statusText(
                            isLogged: isLogged,
                            isSyncing: isSyncing,
                            lastSync: lastSync,
                            lastSyncSuccessful: lastSyncSuccessful,
                            lastSyncDurationMs: lastSyncDurationMs,
                            lastSyncError: lastSyncError,
                          ),
                          size: 12,
                          color: colors.onSurfaceVariant,
                          maxLines: 2,
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
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          height: 1,
                          color: colors.outlineVariant.withOpacity(0.25),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: AnymexText(
                                text: 'Auto-delete completed media from cloud',
                                size: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            Switch(
                              value: autoDeleteCompletedOnExit,
                              onChanged: (v) {
                                unawaited(
                                  ctrl.setAutoDeleteCompletedOnExit(v),
                                );
                              },
                              activeColor: colors.primary,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
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

  String _subtitle(bool isLogged, {String username = ''}) {
    if (!isLogged) return 'Resume progress across all your devices';
    return 'Connected as $username';
  }

  Color _statusColor(
    dynamic colors, {
    required bool isLogged,
    required bool isSyncing,
    required bool? lastSyncSuccessful,
  }) {
    if (!isLogged) return colors.outline;
    if (isSyncing) return colors.primary;
    if (lastSyncSuccessful == false) return const Color(0xFFEF5350);
    return const Color(0xFF238636);
  }

  String _statusText({
    required bool isLogged,
    required bool isSyncing,
    required DateTime? lastSync,
    required bool? lastSyncSuccessful,
    required int? lastSyncDurationMs,
    required String? lastSyncError,
  }) {
    if (!isLogged) return 'Status: Not connected';
    if (isSyncing) return 'Status: Sync in progress...';
    if (lastSync == null) return 'Status: Connected · waiting for first sync';
    final base = _formatLastSync(lastSync, durationMs: lastSyncDurationMs);
    if (lastSyncSuccessful == false) {
      if (lastSyncError != null && lastSyncError.isNotEmpty) {
        return 'Status: Last sync failed · $base';
      }
      return 'Status: Last sync failed';
    }
    return 'Status: Connected · $base';
  }

  String _formatLastSync(DateTime lastSync, {int? durationMs}) {
    final diff = DateTime.now().difference(lastSync);
    final durationPart =
        durationMs != null ? ' in ${_formatDuration(durationMs)}' : '';
    if (diff.inSeconds < 60) return 'synced just now$durationPart';
    if (diff.inMinutes < 60) {
      return 'synced ${diff.inMinutes}m ago$durationPart';
    }
    return 'synced ${diff.inHours}h ago$durationPart';
  }

  String _formatDuration(int ms) {
    if (ms < 1000) return '${ms}ms';
    final seconds = ms / 1000;
    if (seconds < 60) {
      final decimals = seconds < 10 ? 2 : 1;
      return '${seconds.toStringAsFixed(decimals)}s';
    }
    final minutes = seconds / 60;
    if (minutes < 60) {
      return '${minutes.toStringAsFixed(1)}m';
    }
    final hours = minutes / 60;
    return '${hours.toStringAsFixed(1)}h';
  }

  Widget _buildIcon(bool isLogged, bool isSyncing, dynamic colors) {
    if (isSyncing) {
      return SizedBox(
        width: 44,
        height: 44,
        child:
            CircularProgressIndicator(strokeWidth: 2.5, color: colors.primary),
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
      builder: (ctx) => Obx(
        () => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AnymexText(
                text: 'Manage GitHub Gist Sync',
                variant: TextVariant.bold,
                size: 18,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: ctx.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnymexText(
                  text: _statusText(
                    isLogged: ctrl.isLoggedIn.value,
                    isSyncing: ctrl.isSyncing.value,
                    lastSync: ctrl.lastSyncTime.value,
                    lastSyncSuccessful: ctrl.lastSyncSuccessful.value,
                    lastSyncDurationMs: ctrl.lastSyncDurationMs.value,
                    lastSyncError: ctrl.lastSyncError.value,
                  ),
                  size: 12,
                  color: ctx.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(IconlyLight.logout),
                title: const Text('Log Out'),
                onTap: () {
                  ctrl.logout();
                  Navigator.pop(ctx);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: ctx.colors.surfaceContainer,
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: ctrl.isSyncing.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: ctx.colors.primary,
                        ),
                      )
                    : const Icon(Icons.sync_rounded),
                title: Text(ctrl.isSyncing.value ? 'Syncing...' : 'Sync Now'),
                onTap: ctrl.isSyncing.value
                    ? null
                    : () {
                        ctrl.manualSyncNow();
                      },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: ctx.colors.surfaceContainer,
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_rounded,
                  color: ctx.colors.error,
                ),
                title: const Text('Delete Cloud Gist'),
                subtitle: const Text('Permanently remove AnymeX sync data'),
                onTap: ctrl.isSyncing.value
                    ? null
                    : () {
                        _showDeleteGistDialog(ctx, ctrl);
                      },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: ctx.colors.surfaceContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteGistDialog(
    BuildContext context,
    GistSyncController ctrl,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteGistConfirmDialog(),
    );
    if (confirmed == true) {
      await ctrl.deleteRemoteSyncGist();
    }
  }
}

class _DeleteGistConfirmDialog extends StatefulWidget {
  const _DeleteGistConfirmDialog();

  @override
  State<_DeleteGistConfirmDialog> createState() =>
      _DeleteGistConfirmDialogState();
}

class _DeleteGistConfirmDialogState extends State<_DeleteGistConfirmDialog> {
  int _secondsLeft = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        setState(() {
          _secondsLeft = 0;
        });
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft -= 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      backgroundColor: colors.surfaceContainer,
      title: const Text('Delete AnymeX Sync Gist?'),
      content: const Text(
        'This permanently deletes your AnymeX cloud progress gist from GitHub and cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          onPressed:
              _secondsLeft == 0 ? () => Navigator.of(context).pop(true) : null,
          child: Text(
            _secondsLeft == 0
                ? 'I Understand, Delete'
                : 'I Understand ($_secondsLeft)',
          ),
        ),
      ],
    );
  }
}
