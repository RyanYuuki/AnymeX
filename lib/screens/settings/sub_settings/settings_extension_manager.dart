import 'dart:io';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/extensions/widgets/plugin_manager.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/AnymeXBridge.dart';
import 'package:anymex_extension_runtime_bridge/ExtensionManager.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:file_picker/file_picker.dart';
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
  bool _isSyncingLocalRuntimeFile = false;
  bool _needsRestart = false;
  final RxBool _isLoadedFromStorage = false.obs;
  String get _installedVersion => AnymeXRuntimeBridge.installedVersion;

  String get _installedReleaseTitle =>
      AnymeXRuntimeBridge.installedReleaseTitle;

  bool get _isPluginInstalled => AnymeXRuntimeBridge.isPluginInstalled;

  @override
  void initState() {
    super.initState();
    _checkStorageStatus();
  }

  void _checkStorageStatus() async {
    final status = await AnymeXRuntimeBridge.isLoadedFromStorage();
    _isLoadedFromStorage.value = status;
  }

  void _showInstallPopup() async {
    final oldVersion = _installedVersion;
    await _pluginManager.showInstallSheet(context);
    if (mounted) {
      if (_installedVersion != oldVersion) {
        setState(() {
          _needsRestart = true;
        });
      } else {
        setState(() {});
      }
    }
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
      final oldVersion = _installedVersion;
      await _pluginManager.showUpdateSheet(
        context,
        release: release,
        installedVersion: currentVersion,
      );
      if (mounted) {
        if (_installedVersion != oldVersion) {
          setState(() {
            _needsRestart = true;
          });
        } else {
          setState(() {});
        }
      }
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

  void _syncLocalRuntimeFile() async {
    if (_isSyncingLocalRuntimeFile) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: Platform.isAndroid
          ? const ['apk']
          : (Platform.isIOS ? const ['wasm'] : const ['jar']),
      allowMultiple: false,
      withData: false,
    );

    final filePath = result?.files.single.path;
    if (filePath == null || filePath.isEmpty) return;
    if (!mounted) return;

    setState(() => _isSyncingLocalRuntimeFile = true);
    try {
      final oldVersion = _installedVersion;
      final synced = await _pluginManager.syncLocalRuntimeFile(filePath);
      if (mounted && synced) {
        _checkStorageStatus();
        if (_installedVersion != oldVersion) {
          setState(() {
            _needsRestart = true;
          });
        } else {
          setState(() {});
        }
      }
    } finally {
      if (mounted) setState(() => _isSyncingLocalRuntimeFile = false);
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
        _checkStorageStatus();
        if (mounted) {
          setState(() {
            _needsRestart = true;
          });
          successSnackBar(
              'Plugin re-downloaded successfully. Please restart to apply.');
        }
      }
    } catch (error) {
      if (mounted) errorSnackBar('Re-download failed: $error');
    }
  }

  void _showRollbackDialog() async {
    setState(() => _isCheckingUpdate = true);
    final releases = await _pluginManager.fetchReleases();
    setState(() => _isCheckingUpdate = false);
    if (releases.isEmpty) {
      errorSnackBar('No releases found.');
      return;
    }
    if (!mounted) return;
    final theme = Theme.of(context);
    AnymexSheet(
      title: 'Select Version to Rollback',
      showDragHandle: true,
      contentWidget: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.5,
        ),
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: releases.length,
          itemBuilder: (context, index) {
            final release = releases[index];
            final isCurrent = release.tagName == _installedVersion;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: AnymexOnTap(
                onTap: isCurrent
                    ? null
                    : () {
                        Navigator.pop(context);
                        _performRollback(release);
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? theme.colorScheme.primaryContainer
                            .opaque(0.35, iReallyMeanIt: true)
                        : theme.colorScheme.surfaceContainer
                            .opaque(0.3, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrent
                          ? theme.colorScheme.primary
                              .opaque(0.5, iReallyMeanIt: true)
                          : theme.colorScheme.outline
                              .opaque(0.15, iReallyMeanIt: true),
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isCurrent
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline
                                    .opaque(0.4, iReallyMeanIt: true),
                            width: 2,
                          ),
                        ),
                        child: isCurrent
                            ? Icon(Icons.check_rounded,
                                size: 14, color: theme.colorScheme.onPrimary)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              release.title,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              release.tagName,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ).show(context);
  }

  void _performRollback(PluginRelease release) async {
    final bridge = AnymeXRuntimeBridge.controller;
    if (bridge.isDownloading.value) return;
    try {
      await AnymeXRuntimeBridge.setupRuntime(
        customDownloadUrl: release.asset.downloadUrl,
        force: true,
      );
      if (bridge.isReady.value) {
        await Get.find<ExtensionManager>()
            .onRuntimeBridgeInitialization(force: true);
        _pluginManager.persistInstalledRelease(release);
        _checkStorageStatus();
        if (mounted) {
          setState(() {
            _needsRestart = true;
          });
          successSnackBar(
              'Rollback to ${release.tagName} successful. Restart app to apply.');
        }
      }
    } catch (error) {
      if (mounted) errorSnackBar('Rollback failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bridge = AnymeXRuntimeBridge.controller;
    if (Platform.isIOS) {
      return const Scaffold(
        body: Column(
          children: [
            NestedHeader(title: 'Extension Manager'),
            Expanded(
              child: Center(
                child: Text('Extension Manager is not supported on iOS.'),
              ),
            ),
          ],
        ),
      );
    }

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
                          const EdgeInsets.fromLTRB(14.0, 20.0, 14.0, 30.0),
                      desktopValue:
                          const EdgeInsets.fromLTRB(25.0, 20.0, 25.0, 20.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPluginStatusCard(context),
                      ..._buildExtensionSettings(context),
                      const SizedBox(height: 25),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, bottom: 10.0),
                        child: Text(
                          'PLUGIN INSTALLATION & SYNC',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Obx(() {
                        final _ = bridge.isReady.value;
                        final isInstalled =
                            bridge.isReady.value || _isLoadedFromStorage.value;
                        return Container(
                          decoration: BoxDecoration(
                            color:
                                colors.surfaceContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: colors.outlineVariant
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            children: [
                              CustomTile(
                                icon: Icons.cloud_download_rounded,
                                title: isInstalled
                                    ? 'Update Plugin'
                                    : 'Download the Plugin',
                                description: isInstalled
                                    ? 'Check and install the latest plugin update from Github'
                                    : 'Automatically download and install the latest plugin version',
                                onTap: isInstalled
                                    ? (_isCheckingUpdate
                                        ? null
                                        : _checkForUpdates)
                                    : _showInstallPopup,
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
                              if (Platform.isAndroid || Platform.isIOS) ...[
                                Divider(
                                    height: 1,
                                    color: colors.outlineVariant
                                        .withValues(alpha: 0.3)),
                                CustomTile(
                                  icon: Icons.install_mobile_rounded,
                                  title:
                                      'Load Plugin ${Platform.isAndroid ? 'APK' : (Platform.isIOS ? 'WASM' : 'JAR')} from Storage',
                                  description: Platform.isAndroid
                                      ? 'Select a runtime APK from local storage to manually install'
                                      : (Platform.isIOS
                                          ? 'Select a runtime WASM from local storage to manually install'
                                          : 'Select a runtime JAR from local storage to manually install'),
                                  onTap: _isSyncingLocalRuntimeFile
                                      ? null
                                      : _syncLocalRuntimeFile,
                                  postFix: _isSyncingLocalRuntimeFile
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
                              ],
                              if (isInstalled) ...[
                                Divider(
                                    height: 1,
                                    color: colors.outlineVariant
                                        .withValues(alpha: 0.3)),
                                CustomTile(
                                  icon: Icons.refresh_rounded,
                                  title: 'Force Re-download',
                                  description:
                                      'Re-download and reinstall the plugin from scratch',
                                  onTap: _forceReDownload,
                                ),
                                Divider(
                                    height: 1,
                                    color: colors.outlineVariant
                                        .withValues(alpha: 0.3)),
                                CustomTile(
                                  icon: Icons.history_rounded,
                                  title: 'Rollback Version',
                                  description:
                                      'Downgrade or switch to a specific plugin version',
                                  onTap: _showRollbackDialog,
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      40.height()
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
              (status.contains("Extracting") || status.contains("Finalizing")));
      final isActive =
          isReady || _isPluginInstalled || _isLoadedFromStorage.value;

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
                        : isActive
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
                          isActive
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          size: 22,
                          color: isActive
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
                            : isActive
                                ? (_isLoadedFromStorage.value
                                    ? 'Loaded from Storage'
                                    : 'Plugin Installed')
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
                            : isActive
                                ? (_isLoadedFromStorage.value
                                    ? 'Using local runtime file'
                                    : 'Aniyomi & Cloudstream ready')
                                : 'Install runtime plugin to unlock Aniyomi & Cloudstream',
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
            if (isActive && !isBusy) ...[
              if (!_isLoadedFromStorage.value) ...[
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
              ],
              if (!Platform.isAndroid) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                _buildMetaRow(
                  colors,
                  'Bridge Mode',
                  PluginKeys.bridgeMode.get<String>('sidecar'),
                ),
              ],
            ],
            if (isActive && !isBusy && _needsRestart) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.restart_alt_rounded,
                        size: 16, color: colors.onTertiaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please restart the app to apply changes.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
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

  List<Widget> _buildExtensionSettings(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final em = Get.find<ExtensionManager>();
    final settingsList = <Widget>[];

    for (final manager in em.managers) {
      final managerSettings = manager.settings;
      if (managerSettings == null || managerSettings.isEmpty) continue;

      settingsList.add(const SizedBox(height: 25));
      settingsList.add(
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 10.0),
          child: Text(
            '${manager.name.toUpperCase()} SETTINGS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colors.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );

      final children = <Widget>[];
      for (final entry in managerSettings.entries) {
        final setting = entry.value;

        if (setting.type == 'bool') {
          children.add(
            CustomSwitchTile(
              icon: Icons.settings_input_component_rounded,
              title: setting.label,
              description: setting.description,
              switchValue: setting.value as bool,
              onChanged: (val) {
                setting.onChanged(val);
                setState(() {});
              },
            ),
          );
        } else if (setting.type == 'string') {
          children.add(
            CustomTile(
              icon: Icons.folder_open_rounded,
              title: setting.label,
              description: (setting.value as String).isNotEmpty
                  ? setting.value as String
                  : setting.description,
              onTap: () => _showTextInputDialog(
                context,
                title: setting.label,
                initialValue: setting.value as String,
                onSave: (val) {
                  setting.onChanged(val);
                  setState(() {});
                },
              ),
            ),
          );
        }
      }

      if (children.isNotEmpty) {
        settingsList.add(
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(children: children),
          ),
        );
      }
    }

    return settingsList;
  }

  void _showTextInputDialog(
    BuildContext context, {
    required String title,
    required String initialValue,
    required ValueChanged<String> onSave,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Enter value',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onSave(controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
