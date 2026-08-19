import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anymex/controllers/sync/gist_sync_controller.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:url_launcher/url_launcher.dart';

class ProgressSyncSection extends StatelessWidget {
  const ProgressSyncSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<GistSyncController>();

    return _GistSyncCard(ctrl: ctrl);
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
      final needsInitialize = hasCloudGist == false;
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
                        child: AnymeXText('GitHub Gist Sync',
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
                      label: AnymeXText(primaryActionLabel),
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
                              label: AnymeXText(primaryActionLabel),
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
                              label: const AnymeXText('Manage'),
                            ),
                          ),
                        ],
                      ),
                      if (hasCloudGist == true) ...[
                        AnymeXSectionBuilder(
                          title: 'Sync Preferences',
                          margin: const EdgeInsets.only(top: 14),
                          children: [
                            AnymeXTile.toggle(
                              icon: Icons.sync_rounded,
                              title: 'Auto-sync progress',
                              subtitle:
                                  'While watching episodes or reading chapters',
                              value: syncEnabled,
                              onChanged: (v) => ctrl.syncEnabled.value = v,
                            ),
                            AnymeXTile.toggle(
                              icon: Icons.auto_delete_rounded,
                              title: 'Auto-delete completed entries',
                              subtitle:
                                  'Removes finished media from cloud gist',
                              value: autoDeleteCompletedOnExit,
                              onChanged: (v) {
                                unawaited(ctrl.setAutoDeleteCompletedOnExit(v));
                              },
                            ),
                            AnymeXTile.toggle(
                              icon: Icons.notifications_active_outlined,
                              title: 'Exit sync notifications',
                              subtitle:
                                  'Show sync result when player or reader closes',
                              value: showExitSyncNotifications,
                              onChanged: (v) {
                                unawaited(ctrl.setExitSyncNotifications(v));
                              },
                            ),
                          ],
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
                                child: AnymeXText(hasCloudGist == null
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
    final ctx = context;
    AnymeXSheet.custom(
        Obx(
          () => Padding(
            padding: const EdgeInsets.fromLTRB(
              10,
              10,
              10,
              0
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
                  const AnymeXText('Manage GitHub Gist Sync',
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
                        color:
                            ctx.colors.surfaceContainerHigh.withOpacity(0.55),
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
                                    AnymeXText(displayName ?? username,
                                      variant: TextVariant.semiBold,
                                      size: 14,
                                    ),
                                    if (displayName != null &&
                                        username.isNotEmpty &&
                                        username != 'GitHub User')
                                      AnymeXText('@$username',
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
                          AnymeXText(_statusText(
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
                              ctrl.hasCloudGist.value == false
                                  ? Icons.cloud_upload_rounded
                                  : Icons.sync_rounded,
                            ),
                      label: AnymeXText(
                        _primaryActionLabel(
                          isLogged: ctrl.isLoggedIn.value,
                          isAuthenticating: ctrl.isAuthenticating.value,
                          isSyncing: ctrl.isSyncing.value,
                          needsInitialize: ctrl.hasCloudGist.value == false,
                        ),
                      ),
                    ),
                  ),
                  AnymeXSectionBuilder(
                    title: 'Cloud Tools',
                    margin: const EdgeInsets.only(top: 16),
                    children: [
                      AnymeXTile(
                        icon: Icons.open_in_new_rounded,
                        title: 'View Cloud Gist',
                        subtitle: 'Open your AnymeX sync gist on GitHub',
                        enabled: !ctrl.isSyncing.value &&
                            ctrl.hasCloudGist.value != false,
                        onTap: () => _openGistInBrowser(ctx, ctrl),
                      ),
                      AnymeXTile(
                        icon: Icons.download_rounded,
                        title: 'Export Gist JSON',
                        subtitle: 'Save your current cloud progress to a file',
                        enabled: !ctrl.isSyncing.value &&
                            ctrl.hasCloudGist.value != false,
                        onTap: () => _exportGistJson(ctx, ctrl),
                      ),
                      AnymeXTile(
                        icon: Icons.upload_file_rounded,
                        title: 'Import Gist JSON',
                        subtitle:
                            'Merge uploaded entries or replace cloud data',
                        enabled: !ctrl.isSyncing.value,
                        onTap: () => _importGistJson(ctx, ctrl),
                      ),
                      AnymeXTile(
                        icon: Icons.delete_forever_rounded,
                        title: 'Delete Cloud Gist',
                        subtitle: 'Permanently remove AnymeX sync data',
                        iconColor: ctx.colors.error,
                        enabled: !ctrl.isSyncing.value &&
                            ctrl.hasCloudGist.value != false,
                        onTap: () {
                          _showDeleteGistDialog(ctx, ctrl);
                        },
                      ),
                    ],
                  ),
                  AnymeXSectionBuilder(
                    title: 'Account',
                    margin: const EdgeInsets.only(top: 16),
                    children: [
                      AnymeXTile(
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
                ],
              ),
            ),
          ),
        ),
        context);
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
    final selectedMode = _GistImportMode.merge.obs;
    return showDialog<_GistImportMode>(
      context: context,
      builder: (ctx) => Obx(() => AnymeXDialog(
            title: 'Import Gist JSON',
            message:
                'Choose how to apply the selected JSON file to your AnymeX cloud gist.',
            confirmText: 'Import',
            onConfirm: () {},
            confirmResultGetter: () => selectedMode.value,
            contentWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnymeXTile.radio(
                  selected: selectedMode.value == _GistImportMode.merge,
                  title: 'Merge With Cloud',
                  subtitle:
                      'Keep both uploaded and cloud entries. If the same entry exists in both places, the newer one is kept. (Recommended)',
                  onTap: () => selectedMode.value = _GistImportMode.merge,
                ),
                const SizedBox(height: 8),
                AnymeXTile.radio(
                  selected: selectedMode.value == _GistImportMode.replace,
                  title: 'Replace Cloud Gist',
                  subtitle:
                      'Remove current cloud entries and replace them with the uploaded file.',
                  onTap: () => selectedMode.value = _GistImportMode.replace,
                ),
              ],
            ),
          )),
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
      child: AnymeXText(label,
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
    return AnymeXDialog(
      title: 'Delete AnymeX Sync Gist?',
      message:
          'This permanently deletes your AnymeX cloud progress gist from GitHub and cannot be undone.',
      confirmText: _secondsLeft == 0
          ? 'I Understand, Delete'
          : 'I Understand ($_secondsLeft)',
      isConfirmEnabled: _secondsLeft == 0,
      onConfirm: () {},
      confirmResultGetter: () => true,
      cancelResultGetter: () => false,
    );
  }
}
