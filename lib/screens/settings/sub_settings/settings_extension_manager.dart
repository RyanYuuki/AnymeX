import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/extensions/widgets/plugin_manager.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/AnymeXBridge.dart';
import 'package:anymex_extension_runtime_bridge/ExtensionManager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsExtensionManager extends StatefulWidget {
  const SettingsExtensionManager({super.key});

  @override
  State<SettingsExtensionManager> createState() =>
      _SettingsExtensionManagerState();
}

class _SettingsExtensionManagerState extends State<SettingsExtensionManager> {
  final _pluginManager = PluginManager();
  bool _isCheckingUpdate = false;

  String get _installedVersion =>
      AnymeXRuntimeBridge.installedVersion;

  String get _installedReleaseTitle =>
      AnymeXRuntimeBridge.installedReleaseTitle;

  bool get _isPluginInstalled =>
      AnymeXRuntimeBridge.isPluginInstalled;

  void _showInstallPopup() async {
    await _pluginManager.showInstallSheet(context);
    if (mounted) setState(() {});
  }

  void _showUpdatePopup() async {
    final release = await _pluginManager.fetchLatestRelease();
    if (!mounted) return;
    if (release == null) {
      errorSnackBar('Failed to check for updates.');
      return;
    }
    final currentVersion = _installedVersion;
    if (currentVersion.isEmpty) {
      _showInstallPopup();
      return;
    }
    if (_pluginManager.isNewerVersion(currentVersion, release.tagName)) {
      await _pluginManager.showUpdateSheet(
        context,
        release: release,
        installedVersion: currentVersion,
      );
      if (mounted) setState(() {});
    } else {
      successSnackBar('Plugin is already up to date.');
    }
  }

  void _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);
    try {
      final release = await _pluginManager.fetchLatestRelease();
      if (!mounted) return;
      if (release == null) {
        errorSnackBar('Failed to check for updates.');
        return;
      }
      final currentVersion = _installedVersion;
      if (currentVersion.isEmpty) {
        _showInstallPopup();
        return;
      }
      if (_pluginManager.isNewerVersion(currentVersion, release.tagName)) {
        _showUpdatePopup();
      } else {
        successSnackBar('Plugin is already up to date.');
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  void _forceReDownload() async {
    final bridge = AnymeXRuntimeBridge.controller;
    if (bridge.isDownloading.value) return;
    try {
      await AnymeXRuntimeBridge.setupRuntime(force: true);
      if (bridge.isReady.value) {
        await Get.find<ExtensionManager>()
            .onRuntimeBridgeInitialization(force: true);
        if (mounted) {
          setState(() {});
          successSnackBar('Plugin re-downloaded successfully.');
        }
      }
    } catch (error) {
      if (mounted) errorSnackBar('Re-download failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            const NestedHeader(title: 'Extension Manager'),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: getResponsiveValue(context,
                      mobileValue:
                          const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 20.0),
                      desktopValue:
                          const EdgeInsets.fromLTRB(25.0, 20.0, 25.0, 20.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymexExpansionTile(
                        initialExpanded: true,
                        title: 'Plugin Status',
                        content: Column(
                          children: [
                            _buildPluginStatusCard(context),
                            const SizedBox(height: 10),
                            _buildPluginActions(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPluginStatusCard(BuildContext context) {
    final colors = context.colors;
    final bridge = AnymeXRuntimeBridge.controller;
    return Obx(() {
      final isDownloading = bridge.isDownloading.value;
      final progress = bridge.downloadProgress.value;
      final status = bridge.status.value;
      final isReady = bridge.isReady.value;
      final sizeInfo = bridge.sizeInfo.value;
      final hasError = bridge.error.value.isNotEmpty;
      final isBusy = isDownloading ||
          (status != "Idle" &&
              !isReady &&
              (status.contains("Extracting") ||
                  status.contains("Finalizing")));

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surfaceContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isBusy
                        ? colors.tertiaryContainer
                        : _isPluginInstalled
                            ? colors.primaryContainer
                            : colors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isBusy
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colors.onTertiaryContainer,
                          ),
                        )
                      : Icon(
                          _isPluginInstalled
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          size: 22,
                          color: _isPluginInstalled
                              ? colors.onPrimaryContainer
                              : colors.onErrorContainer,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBusy
                            ? 'Downloading Plugin...'
                            : _isPluginInstalled
                                ? 'Plugin Installed'
                                : 'Plugin Not Installed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isBusy
                            ? status
                            : _isPluginInstalled
                                ? 'Aniyomi & Cloudstream ready'
                                : 'Download plugin to unlock Aniyomi & Cloudstream',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isBusy) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: progress > 0 ? progress : null,
                        backgroundColor: colors.surfaceContainerHighest,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colors.primary),
                      ),
                    ),
                  ),
                  if (sizeInfo.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      sizeInfo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (hasError) ...[
              const SizedBox(height: 12),
              Text(
                bridge.error.value,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.error,
                ),
              ),
            ],
            if (_isPluginInstalled && !isBusy) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _buildMetaRow(colors, 'Version', _installedVersion),
              const SizedBox(height: 8),
              _buildMetaRow(
                  colors,
                  'Release',
                  _installedReleaseTitle.isNotEmpty
                      ? _installedReleaseTitle
                      : 'Unknown'),
              const SizedBox(height: 8),
              _buildMetaRow(
                colors,
                'Bridge Mode',
                PluginKeys.bridgeMode.get<String>('sidecar'),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildMetaRow(ColorScheme colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colors.onSurfaceVariant,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPluginActions(BuildContext context) {
    final colors = context.colors;
    final bridge = AnymeXRuntimeBridge.controller;
    return Obx(() {
      final isBusy = bridge.isDownloading.value ||
          (bridge.status.value != "Idle" && !bridge.isReady.value);
      if (isBusy) return const SizedBox.shrink();
      if (!_isPluginInstalled) {
        return CustomTile(
          icon: Icons.download_rounded,
          title: 'Download Plugin',
          description: 'Install the runtime plugin to enable Aniyomi & Cloudstream',
          onTap: _showInstallPopup,
        );
      }
      return Column(
        children: [
          CustomTile(
            icon: Icons.system_update_alt_rounded,
            title: 'Check for Updates',
            description: 'Check if a newer plugin version is available',
            onTap: _isCheckingUpdate ? null : _checkForUpdates,
            postFix: _isCheckingUpdate
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          CustomTile(
            icon: Icons.refresh_rounded,
            title: 'Force Re-download',
            description: 'Re-download and reinstall the plugin from scratch',
            onTap: _forceReDownload,
          ),
        ],
      );
    });
  }
}
