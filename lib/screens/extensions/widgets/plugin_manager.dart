import 'dart:convert';
import 'dart:io';

import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PluginManager {
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/RyanYuuki/AnymeXExtensionRuntimeBridge/releases/latest';

  String get installedVersion => AnymeXRuntimeBridge.installedVersion;

  String get installedReleaseTitle => AnymeXRuntimeBridge.installedReleaseTitle;

  Future<void> ensurePluginLoaded(BuildContext context) async {
    if (Platform.isIOS) return;
    final isLoaded = await AnymeXRuntimeBridge.isLoaded();
    if (isLoaded) return;

    final release = await fetchLatestRelease();
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
    if (Platform.isIOS) return;
    final release = await fetchLatestRelease();
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

    if (isNewerVersion(currentVersion, release.tagName)) {
      if (!context.mounted) return;
      await showUpdateSheet(
        context,
        release: release,
        installedVersion: currentVersion,
      );
      successSnackBar("Restart the App to apply the update.");
      return;
    }

    if (showIfUpToDate) {
      print('Plugin is already up to date.');
    }
  }

  Future<void> showInstallSheet(
    BuildContext context, {
    PluginRelease? release,
  }) async {
    if (!context.mounted) return;

    await AnymexSheet.custom(
      _PluginReleaseSheet(
        manager: this,
        release: release,
        installedVersion: installedVersion,
        mode: _PluginSheetMode.install,
      ),
      context,
      showDragHandle: true,
    );
  }

  Future<void> showUpdateSheet(
    BuildContext context, {
    required PluginRelease release,
    required String installedVersion,
  }) async {
    if (!context.mounted) return;

    await AnymexSheet.custom(
      _PluginReleaseSheet(
        manager: this,
        release: release,
        installedVersion: installedVersion,
        mode: _PluginSheetMode.update,
      ),
      context,
      showDragHandle: true,
    );
  }

  Future<PluginRelease?> fetchLatestRelease() async {
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

      return PluginRelease(
        tagName: (json['tag_name'] as String? ?? '').trim(),
        title: ((json['name'] as String?)?.trim().isNotEmpty ?? false)
            ? (json['name'] as String).trim()
            : (json['tag_name'] as String? ?? 'Latest Plugin Release').trim(),
        body: (json['body'] as String? ?? '').trim(),
        publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
        asset: PluginAsset(
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

  bool isNewerVersion(String installed, String latest) {
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

  void persistInstalledRelease(PluginRelease release) {
    AnymeXRuntimeBridge.setInstalledRelease(release.tagName, release.title);
  }

  Future<bool> syncLocalApk(String apkPath) async {
    final isJar = apkPath.toLowerCase().endsWith('.jar');
    final isApk = apkPath.toLowerCase().endsWith('.apk');

    if (Platform.isAndroid && !isApk) {
      errorSnackBar('Please select a valid APK file.');
      return false;
    }
    if (!Platform.isAndroid && !isJar) {
      errorSnackBar('Please select a valid JAR file.');
      return false;
    }

    if (!await File(apkPath).exists()) {
      errorSnackBar('Local file not found at: $apkPath');
      return false;
    }

    try {
      if (Platform.isAndroid) {
        await AnymeXRuntimeBridge.useLocalApk(apkPath);
      } else {
        final paths = RuntimePaths();
        final destPath = await paths.bridgePath;
        final destFile = File(destPath);
        if (await destFile.exists()) {
          await destFile.delete();
        }
        await File(apkPath).copy(destPath);
        
        final toolsDir = await paths.toolsDir;
        final metadataFile = File('${toolsDir.path}/metadata.json');
        await metadataFile.writeAsString(jsonEncode({
          'version': 'Local-${DateTime.now().millisecondsSinceEpoch}',
          'title': 'Local Synced Jar',
        }));
        await AnymeXRuntimeBridge.loadMetadata();
      }

      final bridge = AnymeXRuntimeBridge.controller;
      if (Platform.isAndroid && bridge.isReady.value) {
        await Get.find<ExtensionManager>()
            .onRuntimeBridgeInitialization(force: true);
        successSnackBar('Plugin synced from local APK.');
        return true;
      } else if (!Platform.isAndroid) {
        successSnackBar('Plugin jar copied. Please restart the app.');
        return true;
      }

      errorSnackBar('Sync completed, but the plugin is not ready yet.');
      return false;
    } catch (e) {
      errorSnackBar('Sync failed: $e');
      return false;
    }
  }

  Future<bool> forceSyncLocalApk() async {
    const localPath = '/storage/emulated/0/AnymeX/anymex_runtime_host.apk';
    if (!await File(localPath).exists()) {
      errorSnackBar('Local APK not found at: $localPath');
      return false;
    }

    return syncLocalApk(localPath);
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
  final PluginRelease? release;
  final String installedVersion;
  final _PluginSheetMode mode;

  @override
  State<_PluginReleaseSheet> createState() => _PluginReleaseSheetState();
}

class _PluginReleaseSheetState extends State<_PluginReleaseSheet>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _installFinished = false;

  PluginRelease? _release;
  bool _isLoadingRelease = false;

  @override
  void initState() {
    super.initState();
    _release = widget.release;

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

    if (_release == null) {
      _fetchReleaseDetails();
    } else {
      _checkBridgeReady();
    }
  }

  void _checkBridgeReady() {
    final bridge = AnymeXRuntimeBridge.controller;
    if (bridge.isReady.value && !AnymeXRuntimeBridge.isPluginInstalled) {
      if (_release != null) {
        widget.manager.persistInstalledRelease(_release!);
      }
      _installFinished = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.find<ExtensionManager>().onRuntimeBridgeInitialization(force: true);
      });
    }
  }

  Future<void> _fetchReleaseDetails() async {
    setState(() {
      _isLoadingRelease = true;
    });
    try {
      final fetched = await widget.manager.fetchLatestRelease();
      if (mounted) {
        setState(() {
          _release = fetched;
          _isLoadingRelease = false;
        });
        if (fetched != null) {
          _checkBridgeReady();
        } else {
          errorSnackBar('Failed to fetch release details.');
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRelease = false;
        });
        errorSnackBar('Error: $e');
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _downloadAndInstall() async {
    if (_release == null) return;
    final bridge = AnymeXRuntimeBridge.controller;
    if (bridge.isDownloading.value) return;

    try {
      await AnymeXRuntimeBridge.setupRuntime(
        force: widget.mode == _PluginSheetMode.update,
      );

      if (bridge.isReady.value) {
        await Get.find<ExtensionManager>()
            .onRuntimeBridgeInitialization(force: true);
        widget.manager.persistInstalledRelease(_release!);
        if (mounted) {
          setState(() {
            _installFinished = true;
          });
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

    if (_isLoadingRelease || _release == null) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: colors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Fetching latest release details...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Obx(() {
      final bool isBusy = bridge.isDownloading.value ||
          (bridge.status.value != "Idle" &&
              !bridge.isReady.value &&
              (bridge.status.value.contains("Extracting") ||
                  bridge.status.value.contains("Finalizing")));
      final bool isComplete = _installFinished ||
          (widget.mode == _PluginSheetMode.install &&
              bridge.isReady.value &&
              AnymeXRuntimeBridge.isPluginInstalled);

      return SizedBox(
        height: context.mediaQuerySize.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors, theme),
            const SizedBox(height: 14),
            _buildVersionCard(colors, bridge, isBusy, isComplete),
            const SizedBox(height: 14),
            Text(
              'CHANGELOG',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colors.primary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: SingleChildScrollView(
                  child: MarkdownBody(
                    data: _release!.body.isEmpty
                        ? 'No changelog provided for this release.'
                        : _release!.body,
                    selectable: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildFooter(colors, theme, isBusy, isComplete),
            if (bridge.error.value.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                bridge.error.value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.error,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildHeader(ColorScheme colors, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _release!.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildChip(colors, _release!.tagName),
      ],
    );
  }

  Widget _buildVersionCard(
      ColorScheme colors, dynamic bridge, bool isBusy, bool isComplete) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetaRow(
            colors,
            'Installed version',
            widget.installedVersion.isEmpty
                ? 'Not installed'
                : widget.installedVersion,
          ),
          const SizedBox(height: 8),
          _buildMetaRow(
            colors,
            'Latest version',
            _release!.tagName,
          ),
          const SizedBox(height: 8),
          _buildMetaRow(
            colors,
            'File size',
            Platform.isAndroid
                ? _formatBytes(_release!.asset.sizeBytes)
                : (widget.mode == _PluginSheetMode.install
                    ? '${_formatBytes(_release!.asset.sizeBytes)} + ~60 MB JRE'
                    : _formatBytes(_release!.asset.sizeBytes)),
          ),
          if (isBusy) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 5,
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
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isComplete ? 'Close' : 'Later',
              style: const TextStyle(fontWeight: FontWeight.w600),
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
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              isComplete ? Icons.check_rounded : Icons.download_rounded,
              size: 20,
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

}

class PluginRelease {
  const PluginRelease({
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
  final PluginAsset asset;
}

class PluginAsset {
  const PluginAsset({
    required this.name,
    required this.downloadUrl,
    required this.sizeBytes,
  });

  final String name;
  final String downloadUrl;
  final int sizeBytes;
}
