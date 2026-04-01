import 'dart:convert';
import 'dart:io';

import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/AnymeXBridge.dart';
import 'package:anymex_extension_runtime_bridge/ExtensionManager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PluginManager {
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/RyanYuuki/AnymeXExtensionRuntimeBridge/releases/latest';

  String get installedVersion =>
      PluginKeys.runtimeHostInstalledVersion.get<String>('');

  String get installedReleaseTitle =>
      PluginKeys.runtimeHostInstalledReleaseTitle.get<String>('');

  Future<void> ensurePluginLoaded(BuildContext context) async {
    final isLoaded = await AnymeXRuntimeBridge.isLoaded();
    if (isLoaded) return;

    final release = await _fetchLatestRelease();
    if (release == null) {
      errorSnackBar('Failed to fetch plugin release details.');
      return;
    }

    if (!context.mounted) return;
    await showInstallSheet(context, release: release);
  }

  Future<void> checkForUpdates(
    BuildContext context, {
    bool showIfUpToDate = false,
  }) async {
    final release = await _fetchLatestRelease();
    if (release == null) {
      errorSnackBar('Failed to check plugin updates.');
      return;
    }

    final currentVersion = installedVersion;
    if (currentVersion.isEmpty) {
      if (!context.mounted) return;
      await showInstallSheet(context, release: release);
      return;
    }

    if (_isNewerVersion(currentVersion, release.tagName)) {
      if (!context.mounted) return;
      await showUpdateSheet(
        context,
        release: release,
        installedVersion: currentVersion,
      );
      return;
    }

    if (showIfUpToDate) {
      successSnackBar('Plugin is already up to date.');
    }
  }

  Future<void> showInstallSheet(
    BuildContext context, {
    _PluginRelease? release,
  }) async {
    final resolvedRelease = release ?? await _fetchLatestRelease();
    if (resolvedRelease == null) {
      errorSnackBar('Failed to load plugin release.');
      return;
    }

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      builder: (_) => _PluginReleaseSheet(
        manager: this,
        release: resolvedRelease,
        installedVersion: installedVersion,
        mode: _PluginSheetMode.install,
      ),
    );
  }

  Future<void> showUpdateSheet(
    BuildContext context, {
    required _PluginRelease release,
    required String installedVersion,
  }) async {
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      builder: (_) => _PluginReleaseSheet(
        manager: this,
        release: release,
        installedVersion: installedVersion,
        mode: _PluginSheetMode.update,
      ),
    );
  }

  Future<_PluginRelease?> _fetchLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse(_latestReleaseUrl),
        headers: const {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode != 200) {
        Logger.e(
          'Failed to fetch runtime host release: ${response.statusCode}',
        );
        return null;
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      final assets = (json['assets'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

      final extension = Platform.isAndroid ? '.apk' : '.jar';
      final assetJson = assets.firstWhereOrNull(
        (asset) =>
            (asset['name'] as String? ?? '').toLowerCase().endsWith(extension),
      );

      if (assetJson == null) {
        Logger.e('Runtime host release has no compatible asset.');
        return null;
      }

      return _PluginRelease(
        tagName: (json['tag_name'] as String? ?? '').trim(),
        title: ((json['name'] as String?)?.trim().isNotEmpty ?? false)
            ? (json['name'] as String).trim()
            : (json['tag_name'] as String? ?? 'Latest Plugin Release').trim(),
        body: (json['body'] as String? ?? '').trim(),
        publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
        asset: _PluginAsset(
          name: (assetJson['name'] as String? ?? 'anymex_bridge').trim(),
          downloadUrl:
              (assetJson['browser_download_url'] as String? ?? '').trim(),
          sizeBytes: (assetJson['size'] as num?)?.toInt() ?? 0,
        ),
      );
    } catch (error, stackTrace) {
      Logger.e(
        'Error fetching runtime host release',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  bool _isNewerVersion(String installed, String latest) {
    final installedParts = _normalizeVersion(installed);
    final latestParts = _normalizeVersion(latest);
    final maxLength = installedParts.length > latestParts.length
        ? installedParts.length
        : latestParts.length;

    for (var index = 0; index < maxLength; index++) {
      final installedPart =
          index < installedParts.length ? installedParts[index] : 0;
      final latestPart = index < latestParts.length ? latestParts[index] : 0;

      if (latestPart > installedPart) return true;
      if (latestPart < installedPart) return false;
    }

    return false;
  }

  List<int> _normalizeVersion(String version) {
    final cleaned = version.toLowerCase().replaceFirst(RegExp(r'^v'), '');
    final stablePart = cleaned.split('-').first;
    return stablePart
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }

  void persistInstalledRelease(_PluginRelease release) {
    PluginKeys.runtimeHostInstalledVersion.set(release.tagName);
    PluginKeys.runtimeHostInstalledReleaseTitle.set(release.title);
  }

  Future<void> forceSyncLocalApk() async {
    const localPath =
        '/storage/emulated/0/AnymeX/anymex_runtime_host.apk';
    if (!await File(localPath).exists()) {
      errorSnackBar('Local APK not found at: $localPath');
      return;
    }

    try {
      await AnymeXRuntimeBridge.setupRuntime(localApkPath: localPath);
      final bridge = AnymeXRuntimeBridge.controller;
      if (bridge.isReady.value) {
        await Get.find<ExtensionManager>().onRuntimeBridgeInitialization();
        successSnackBar('Plugin synced from SD Card.');
      }
    } catch (e) {
      errorSnackBar('Sync failed: $e');
    }
  }
}

enum _PluginSheetMode { install, update }

class _PluginReleaseSheet extends StatefulWidget {
  const _PluginReleaseSheet({
    required this.manager,
    required this.release,
    required this.installedVersion,
    required this.mode,
  });

  final PluginManager manager;
  final _PluginRelease release;
  final String installedVersion;
  final _PluginSheetMode mode;

  @override
  State<_PluginReleaseSheet> createState() => _PluginReleaseSheetState();
}

class _PluginReleaseSheetState extends State<_PluginReleaseSheet>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.02).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _downloadAndInstall() async {
    final bridge = AnymeXRuntimeBridge.controller;
    if (bridge.isDownloading.value) return;

    try {
      await AnymeXRuntimeBridge.setupRuntime();

      if (bridge.isReady.value) {
        await Get.find<ExtensionManager>().onRuntimeBridgeInitialization();

        widget.manager.persistInstalledRelease(widget.release);
        if (mounted) {
          successSnackBar(
            widget.mode == _PluginSheetMode.install
                ? 'Plugin installed successfully.'
                : 'Plugin updated successfully.',
          );
        }
      }
    } catch (error) {
      if (mounted) errorSnackBar('Plugin installation failed: $error');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return 'Unknown';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes < kb) return '$bytes B';
    if (bytes < mb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '${(bytes / mb).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final bridge = AnymeXRuntimeBridge.controller;

    return Obx(() {
      final bool isBusy = bridge.isDownloading.value ||
          (bridge.status.value != "Idle" &&
              !bridge.isReady.value &&
              (bridge.status.value.contains("Extracting") ||
                  bridge.status.value.contains("Finalizing")));
      final bool isComplete = bridge.isReady.value;

      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colors, theme),
                const SizedBox(height: 16),
                _buildVersionCard(colors, bridge, isBusy, isComplete),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: colors.outlineVariant.withOpacity(0.45),
                      ),
                    ),
                    child: Markdown(
                      data: widget.release.body.isEmpty
                          ? 'No changelog provided for this release.'
                          : widget.release.body,
                      selectable: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFooter(colors, theme, isBusy, isComplete),
                if (bridge.error.value.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    bridge.error.value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(ColorScheme colors, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: widget.installedVersion.isNotEmpty
                ? IconButton(
                    onPressed: widget.manager.forceSyncLocalApk,
                    icon: Icon(Icons.sync_rounded, color: colors.primary),
                    tooltip: 'Force Sync from SD Card',
                  )
                : Icon(
                    widget.mode == _PluginSheetMode.install
                        ? Icons.extension_rounded
                        : Icons.system_update_alt_rounded,
                    color: colors.primary,
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.mode == _PluginSheetMode.install
                    ? 'Plugin Setup'
                    : 'Plugin Update Available',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.release.title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip(colors, widget.release.tagName),
                  _buildChip(
                    colors,
                    widget.release.publishedAt == null
                        ? 'Latest release'
                        : _formatDate(widget.release.publishedAt!),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVersionCard(
      ColorScheme colors, dynamic bridge, bool isBusy, bool isComplete) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetaRow(
            colors,
            'Installed plugin version',
            widget.installedVersion.isEmpty
                ? 'Not installed'
                : widget.installedVersion,
          ),
          const SizedBox(height: 10),
          _buildMetaRow(
            colors,
            'Latest plugin version',
            '${widget.release.title} (${widget.release.tagName})',
          ),
          const SizedBox(height: 10),
          _buildMetaRow(
            colors,
            'Plugin size',
            Platform.isAndroid
                ? _formatBytes(widget.release.asset.sizeBytes)
                : '${_formatBytes(widget.release.asset.sizeBytes)} + ~60 MB JRE',
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isComplete ? 'Plugin is ready.' : bridge.status.value,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ),
              if (isBusy && bridge.sizeInfo.value.isNotEmpty)
                Text(
                  bridge.sizeInfo.value,
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (isBusy) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: bridge.downloadProgress.value > 0
                    ? bridge.downloadProgress.value
                    : null,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(
      ColorScheme colors, ThemeData theme, bool isBusy, bool isComplete) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isBusy ? null : () => Navigator.of(context).pop(),
            child: Text(
              isComplete ? 'Close' : 'Later',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: isComplete
                ? () => Navigator.of(context).pop()
                : (isBusy ? null : _downloadAndInstall),
            icon: Icon(
              isComplete ? Icons.check_rounded : Icons.download_rounded,
            ),
            label: Text(
              isComplete
                  ? 'Done'
                  : (widget.mode == _PluginSheetMode.install
                      ? 'Download & Install'
                      : 'Update Plugin'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(ColorScheme colors, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(ColorScheme colors, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = switch (date.month) {
      1 => 'Jan',
      2 => 'Feb',
      3 => 'Mar',
      4 => 'Apr',
      5 => 'May',
      6 => 'Jun',
      7 => 'Jul',
      8 => 'Aug',
      9 => 'Sep',
      10 => 'Oct',
      11 => 'Nov',
      _ => 'Dec',
    };
    return '$month ${date.day}, ${date.year}';
  }
}

class _PluginRelease {
  const _PluginRelease({
    required this.tagName,
    required this.title,
    required this.body,
    required this.asset,
    this.publishedAt,
  });

  final String tagName;
  final String title;
  final String body;
  final DateTime? publishedAt;
  final _PluginAsset asset;
}

class _PluginAsset {
  const _PluginAsset({
    required this.name,
    required this.downloadUrl,
    required this.sizeBytes,
  });

  final String name;
  final String downloadUrl;
  final int sizeBytes;
}
