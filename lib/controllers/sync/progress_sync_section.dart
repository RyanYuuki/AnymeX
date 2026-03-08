import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anymex/controllers/sync/gist_sync_controller.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';

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
      final isAuthenticating = ctrl.isAuthenticating.value;
      final isSyncing = ctrl.isSyncing.value;
      final isBusy = isAuthenticating || isSyncing;
      final syncEnabled = ctrl.syncEnabled.value;
      final autoDeleteCompletedOnExit = ctrl.autoDeleteCompletedOnExit.value;
      final showExitSyncNotifications = ctrl.showExitSyncNotifications.value;
      final hasCloudGist = ctrl.hasCloudGist.value;
      final lastSyncSuccessful = ctrl.lastSyncSuccessful.value;
      final needsInitialize = hasCloudGist != true;
      final statusColor = _statusColor(
        colors,
        isLogged: isLogged,
        isSyncing: isSyncing,
        hasCloudGist: hasCloudGist,
        lastSyncSuccessful: lastSyncSuccessful,
      );
      final primaryActionLabel = _primaryActionLabel(
        isLogged: isLogged,
        isAuthenticating: isAuthenticating,
        isSyncing: isSyncing,
        needsInitialize: needsInitialize,
      );

      return Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLogged
                ? statusColor.withOpacity(0.45)
                : colors.outlineVariant.withOpacity(0.2),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      _buildIcon(
                        isLogged: isLogged,
                        isSyncing: isSyncing,
                        isAuthenticating: isAuthenticating,
                        statusColor: statusColor,
                        colors: colors,
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: AnymexText(
                          text: 'GitHub Gist Sync',
                          variant: TextVariant.semiBold,
                          size: 16,
                        ),
                      ),
                      _StatusPill(
                        label: _statusBadgeLabel(
                          isLogged: isLogged,
                          isAuthenticating: isAuthenticating,
                          isSyncing: isSyncing,
                          hasCloudGist: hasCloudGist,
                          lastSyncSuccessful: lastSyncSuccessful,
                        ),
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!isLogged)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isAuthenticating
                          ? null
                          : () {
                              unawaited(ctrl.login(context));
                            },
                      icon: isAuthenticating
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                          : const Icon(Icons.login_rounded),
                      label: Text(primaryActionLabel),
                    ),
                  ),
                if (isLogged)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: isBusy
                                  ? null
                                  : () {
                                      unawaited(ctrl.manualSyncNow());
                                    },
                              icon: isBusy
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.onPrimary,
                                      ),
                                    )
                                  : Icon(
                                      needsInitialize
                                          ? Icons.cloud_upload_rounded
                                          : Icons.sync_rounded,
                                    ),
                              label: Text(primaryActionLabel),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isBusy
                                  ? null
                                  : () {
                                      unawaited(ctrl.refreshCloudGistStatus());
                                      unawaited(ctrl.refreshGithubProfile());
                                      _showManageSheet(context, ctrl);
                                    },
                              icon: const Icon(Icons.tune_rounded),
                              label: const Text('Manage'),
                            ),
                          ),
                        ],
                      ),
                      if (hasCloudGist == true) ...[
                        const SizedBox(height: 14),
                        AnymexText(
                          text: 'Sync Preferences',
                          size: 12,
                          variant: TextVariant.bold,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        _SyncPreferenceTile(
                          icon: Icons.sync_rounded,
                          title: 'Auto-sync progress',
                          subtitle:
                              'While watching episodes or reading chapters',
                          value: syncEnabled,
                          onChanged: (v) => ctrl.syncEnabled.value = v,
                        ),
                        const SizedBox(height: 8),
                        _SyncPreferenceTile(
                          icon: Icons.auto_delete_rounded,
                          title: 'Auto-delete completed entries',
                          subtitle: 'Removes finished media from cloud gist',
                          value: autoDeleteCompletedOnExit,
                          onChanged: (v) {
                            unawaited(ctrl.setAutoDeleteCompletedOnExit(v));
                          },
                        ),
                        const SizedBox(height: 8),
                        _SyncPreferenceTile(
                          icon: Icons.notifications_active_outlined,
                          title: 'Exit sync notifications',
                          subtitle:
                              'Show sync result when player or reader closes',
                          value: showExitSyncNotifications,
                          onChanged: (v) {
                            unawaited(ctrl.setExitSyncNotifications(v));
                          },
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                colors.surfaceContainerHigh.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colors.outlineVariant.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AnymexText(
                                  text: hasCloudGist == null
                                      ? 'Checking cloud gist status. Sync now to create one if needed.'
                                      : 'Create your cloud gist first to unlock sync preferences.',
                                  size: 12,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  String _statusBadgeLabel({
    required bool isLogged,
    required bool isAuthenticating,
    required bool isSyncing,
    required bool? hasCloudGist,
    required bool? lastSyncSuccessful,
  }) {
    if (!isLogged) return isAuthenticating ? 'Connecting' : 'Disconnected';
    if (isAuthenticating) return 'Connecting';
    if (isSyncing) return 'Syncing';
    if (hasCloudGist == false) return 'Needs Setup';
    if (lastSyncSuccessful == false) return 'Attention';
    return 'Ready';
  }

  String _primaryActionLabel({
    required bool isLogged,
    required bool isAuthenticating,
    required bool isSyncing,
    required bool needsInitialize,
  }) {
    if (!isLogged) {
      return isAuthenticating ? 'Connecting...' : 'Connect GitHub';
    }
    if (isAuthenticating) return 'Connecting...';
    if (isSyncing) {
      return needsInitialize ? 'Initializing...' : 'Syncing...';
    }
    return needsInitialize ? 'Initialize' : 'Sync Now';
  }

  Color _statusColor(
    ColorScheme colors, {
    required bool isLogged,
    required bool isSyncing,
    required bool? hasCloudGist,
    required bool? lastSyncSuccessful,
  }) {
    if (!isLogged) return colors.outline;
    if (isSyncing) return colors.primary;
    if (hasCloudGist == false) return const Color(0xFFF59E0B);
    if (lastSyncSuccessful == false) return const Color(0xFFEF5350);
    return const Color(0xFF238636);
  }

  String _statusText({
    required bool isLogged,
    required bool isSyncing,
    required bool? hasCloudGist,
    required DateTime? lastSync,
    required bool? lastSyncSuccessful,
    required int? lastSyncDurationMs,
    required String? lastSyncError,
  }) {
    if (!isLogged) return 'Status: Not connected';
    if (hasCloudGist == null) {
      if (isSyncing) return 'Status: Checking cloud gist...';
      return 'Status: Connected · checking cloud gist';
    }
    if (hasCloudGist == false) {
      if (isSyncing) return 'Status: Initializing cloud gist...';
      return 'Status: Connected · gist not initialized';
    }
    if (isSyncing) return 'Status: Sync in progress...';
    if (lastSync == null) return 'Status: Connected';
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
    if (diff.inHours < 24) {
      return 'synced ${diff.inHours}h ago$durationPart';
    }
    if (diff.inDays < 7) {
      return 'synced ${diff.inDays}d ago$durationPart';
    }
    return 'synced on ${lastSync.month}/${lastSync.day}$durationPart';
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

  Widget _buildIcon({
    required bool isLogged,
    required bool isSyncing,
    required bool isAuthenticating,
    required Color statusColor,
    required ColorScheme colors,
  }) {
    if (isSyncing || isAuthenticating) {
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
        color: statusColor.withOpacity(isLogged ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.cloud_sync_rounded,
        color: isLogged ? statusColor : colors.onSurfaceVariant,
      ),
    );
  }

  void _showManageSheet(BuildContext context, GistSyncController ctrl) {
    unawaited(ctrl.refreshGithubProfile());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      builder: (ctx) => Obx(
        () => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ctx.colors.outlineVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const AnymexText(
                  text: 'Manage GitHub Gist Sync',
                  variant: TextVariant.bold,
                  size: 18,
                ),
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  final isLogged = ctrl.isLoggedIn.value;
                  final username = ctrl.githubUsername.value ?? 'GitHub User';
                  final displayName = ctrl.githubDisplayName.value;
                  final avatarUrl = ctrl.githubAvatarUrl.value;
                  final hasCloudGist = ctrl.hasCloudGist.value;
                  final isSyncing = ctrl.isSyncing.value;
                  final lastSync = ctrl.lastSyncTime.value;
                  final lastSyncSuccessful = ctrl.lastSyncSuccessful.value;
                  final lastSyncDurationMs = ctrl.lastSyncDurationMs.value;
                  final lastSyncError = ctrl.lastSyncError.value;
                  final statusColor = _statusColor(
                    ctx.colors,
                    isLogged: isLogged,
                    isSyncing: isSyncing,
                    hasCloudGist: hasCloudGist,
                    lastSyncSuccessful: lastSyncSuccessful,
                  );
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ctx.colors.surfaceContainerHigh.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: statusColor.withOpacity(0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _GithubProfileAvatar(
                              avatarUrl: avatarUrl,
                              fallbackColor: ctx.colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnymexText(
                                    text: displayName ?? username,
                                    variant: TextVariant.semiBold,
                                    size: 14,
                                  ),
                                  if (displayName != null &&
                                      username.isNotEmpty &&
                                      username != 'GitHub User')
                                    AnymexText(
                                      text: '@$username',
                                      size: 11,
                                      color: ctx.colors.onSurfaceVariant,
                                    ),
                                ],
                              ),
                            ),
                            _StatusPill(
                              label: _statusBadgeLabel(
                                isLogged: isLogged,
                                isAuthenticating: ctrl.isAuthenticating.value,
                                isSyncing: isSyncing,
                                hasCloudGist: hasCloudGist,
                                lastSyncSuccessful: lastSyncSuccessful,
                              ),
                              color: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        AnymexText(
                          text: _statusText(
                            isLogged: isLogged,
                            isSyncing: isSyncing,
                            hasCloudGist: hasCloudGist,
                            lastSync: lastSync,
                            lastSyncSuccessful: lastSyncSuccessful,
                            lastSyncDurationMs: lastSyncDurationMs,
                            lastSyncError: lastSyncError,
                          ),
                          size: 12,
                          color: ctx.colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: ctrl.isSyncing.value
                        ? null
                        : () {
                            unawaited(ctrl.manualSyncNow());
                          },
                    icon: ctrl.isSyncing.value
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ctx.colors.onPrimary,
                            ),
                          )
                        : Icon(
                            ctrl.hasCloudGist.value != true
                                ? Icons.cloud_upload_rounded
                                : Icons.sync_rounded,
                          ),
                    label: Text(
                      _primaryActionLabel(
                        isLogged: ctrl.isLoggedIn.value,
                        isAuthenticating: ctrl.isAuthenticating.value,
                        isSyncing: ctrl.isSyncing.value,
                        needsInitialize: ctrl.hasCloudGist.value != true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnymexText(
                  text: 'Cloud Tools',
                  size: 12,
                  variant: TextVariant.bold,
                  color: ctx.colors.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                _SheetActionTile(
                  icon: Icons.open_in_new_rounded,
                  title: 'View Cloud Gist',
                  subtitle: 'Open your AnymeX sync gist on GitHub',
                  onTap: ctrl.isSyncing.value || ctrl.hasCloudGist.value != true
                      ? null
                      : () => _openGistInBrowser(ctx, ctrl),
                ),
                const SizedBox(height: 8),
                _SheetActionTile(
                  icon: Icons.download_rounded,
                  title: 'Export Gist JSON',
                  subtitle: 'Save your current cloud progress to a file',
                  onTap: ctrl.isSyncing.value || ctrl.hasCloudGist.value != true
                      ? null
                      : () => _exportGistJson(ctx, ctrl),
                ),
                const SizedBox(height: 8),
                _SheetActionTile(
                  icon: Icons.upload_file_rounded,
                  title: 'Import Gist JSON',
                  subtitle: 'Merge uploaded entries or replace cloud data',
                  onTap: ctrl.isSyncing.value
                      ? null
                      : () => _importGistJson(ctx, ctrl),
                ),
                const SizedBox(height: 8),
                _SheetActionTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete Cloud Gist',
                  subtitle: 'Permanently remove AnymeX sync data',
                  color: ctx.colors.error,
                  onTap: ctrl.isSyncing.value || ctrl.hasCloudGist.value != true
                      ? null
                      : () {
                          _showDeleteGistDialog(ctx, ctrl);
                        },
                ),
                const SizedBox(height: 16),
                AnymexText(
                  text: 'Account',
                  size: 12,
                  variant: TextVariant.bold,
                  color: ctx.colors.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                _SheetActionTile(
                  icon: IconlyLight.logout,
                  title: 'Log Out',
                  subtitle: 'Disconnect this GitHub account from AnymeX',
                  onTap: () {
                    ctrl.logout();
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
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

  Future<void> _exportGistJson(
    BuildContext context,
    GistSyncController ctrl,
  ) async {
    final raw = await ctrl.fetchRemoteSyncJson();
    if (raw == null) return;

    final formattedJson = const JsonEncoder.withIndent('  ').convert(raw);
    final fileName =
        'anymex_progress_${DateTime.now().millisecondsSinceEpoch}.json';

    try {
      String? outputPath;
      if (Platform.isAndroid || Platform.isIOS) {
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Export GitHub Gist JSON',
          fileName: fileName,
          bytes: utf8.encode(formattedJson),
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
      } else {
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Export GitHub Gist JSON',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (outputPath != null) {
          await File(outputPath).writeAsString(formattedJson, flush: true);
        }
      }

      if (outputPath == null) return;
      successSnackBar('Exported gist JSON.');
    } catch (e) {
      Logger.i('[GistSync] _exportGistJson: $e');
      errorSnackBar('Failed to export gist JSON.');
    }
  }

  Future<void> _openGistInBrowser(
    BuildContext context,
    GistSyncController ctrl,
  ) async {
    final url = await ctrl.fetchRemoteSyncGistUrl();
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) {
      errorSnackBar('Invalid gist URL.');
      return;
    }

    try {
      if (!await canLaunchUrl(uri)) {
        errorSnackBar('Could not open gist in browser.');
        return;
      }
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        errorSnackBar('Could not open gist in browser.');
      }
    } catch (e) {
      Logger.i('[GistSync] _openGistInBrowser: $e');
      errorSnackBar('Failed to open gist in browser.');
    }
  }

  Future<void> _importGistJson(
    BuildContext context,
    GistSyncController ctrl,
  ) async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;

      final file = picked.files.first;
      final bytes = file.bytes ??
          (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null || bytes.isEmpty) {
        errorSnackBar('Unable to read selected JSON file.');
        return;
      }

      final decoded = json.decode(utf8.decode(bytes));
      if (decoded is! Map) {
        errorSnackBar('Selected file must contain a JSON object.');
        return;
      }

      if (!context.mounted) return;
      final importMode = await _showImportModeDialog(context);
      if (importMode == null) return;

      final imported = decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      final result = await ctrl.importProgressJson(
        imported,
        mergeWithCloud: importMode == _GistImportMode.merge,
      );
      if (result == null) return;

      if (result.merged) {
        successSnackBar(
          'Merged ${result.importedEntries} imported entries with ${result.cloudEntriesBefore} cloud entries.',
        );
      } else {
        successSnackBar(
          'Replaced cloud gist with ${result.totalEntries} imported entries.',
        );
      }
    } catch (e) {
      Logger.i('[GistSync] _importGistJson: $e');
      errorSnackBar('Failed to import gist JSON.');
    }
  }

  Future<_GistImportMode?> _showImportModeDialog(BuildContext context) {
    return showDialog<_GistImportMode>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: ctx.colors.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: ctx.colors.outlineVariant.withOpacity(0.35),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: ctx.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.upload_file_rounded,
                      color: ctx.colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: AnymexText(
                      text: 'Import Gist JSON',
                      variant: TextVariant.semiBold,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: AnymexText(
                  text:
                      'Choose how to apply the selected JSON file to your AnymeX cloud gist.',
                  size: 12,
                  color: ctx.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _ImportModeOptionTile(
                icon: Icons.hub_rounded,
                title: 'Merge With Cloud',
                subtitle:
                    'Keep both uploaded and cloud entries. If the same entry exists in both places, the newer one is kept.',
                badge: 'Recommended',
                accent: ctx.colors.primary,
                onTap: () => Navigator.of(ctx).pop(_GistImportMode.merge),
              ),
              const SizedBox(height: 10),
              _ImportModeOptionTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Replace Cloud Gist',
                subtitle:
                    'Remove current cloud entries and replace them with the uploaded file.',
                accent: ctx.colors.error,
                onTap: () => Navigator.of(ctx).pop(_GistImportMode.replace),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: AnymexText(
        text: label,
        size: 10,
        variant: TextVariant.semiBold,
        color: color,
      ),
    );
  }
}

class _GithubProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final Color fallbackColor;

  const _GithubProfileAvatar({
    required this.avatarUrl,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    final placeholder = Icon(
      Icons.account_circle_rounded,
      color: fallbackColor,
      size: 24,
    );

    return SizedBox(
      width: 32,
      height: 32,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: hasAvatar
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(child: placeholder),
              )
            : Center(child: placeholder),
      ),
    );
  }
}

class _SyncPreferenceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SyncPreferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!value),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh.withOpacity(0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.outlineVariant.withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: colors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymexText(
                      text: title,
                      size: 13,
                      variant: TextVariant.semiBold,
                    ),
                    const SizedBox(height: 1),
                    AnymexText(
                      text: subtitle,
                      size: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? color;

  const _SheetActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = color ?? colors.onSurface;
    final enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withOpacity(0.2),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymexText(
                        text: title,
                        size: 13,
                        variant: TextVariant.semiBold,
                      ),
                      const SizedBox(height: 1),
                      AnymexText(
                        text: subtitle,
                        size: 11,
                        color: colors.onSurfaceVariant,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImportModeOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final Color accent;
  final VoidCallback onTap;

  const _ImportModeOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.35), width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AnymexText(
                            text: title,
                            variant: TextVariant.semiBold,
                            size: 13,
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: AnymexText(
                              text: badge!,
                              size: 10,
                              variant: TextVariant.semiBold,
                              color: accent,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    AnymexText(
                      text: subtitle,
                      size: 11,
                      maxLines: 3,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _GistImportMode { replace, merge }

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
      setState(() {
        _secondsLeft -= 1;
      });
      if (_secondsLeft == 0) {
        timer.cancel();
      }
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
