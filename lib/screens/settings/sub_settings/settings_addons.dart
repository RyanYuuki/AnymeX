import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class SettingsAddons extends StatefulWidget {
  const SettingsAddons({super.key});

  static void push(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsAddons()),
      );

  @override
  State<SettingsAddons> createState() => _SettingsAddonsState();
}

class _SettingsAddonsState extends State<SettingsAddons> {
  late final AddonManager _addonManager;
  bool _isCheckingUpdates = false;

  @override
  void initState() {
    super.initState();
    _addonManager = Get.isRegistered<AddonManager>()
        ? Get.find<AddonManager>()
        : Get.put(AddonManager());
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    for (final addon in _addonManager.addons) {
      try {
        final installed = await addon.isInstalled();
        addon.installed.value = installed;
        if (installed) {
          await addon.checkForUpdate();
        }
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _checkUpdates() async {
    setState(() => _isCheckingUpdates = true);
    try {
      await _addonManager.checkForUpdates();
      snackBar('Update check complete');
    } catch (e) {
      errorSnackBar('Failed to check for updates: $e');
    } finally {
      if (mounted) setState(() => _isCheckingUpdates = false);
    }
  }

  Future<void> _installAddon(Addon addon) async {
    try {
      await addon.install();
      successSnackBar('${addon.name} installed successfully');
    } catch (e) {
      errorSnackBar('Failed to install ${addon.name}: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _updateAddon(Addon addon) async {
    try {
      await addon.update();
      successSnackBar('${addon.name} updated successfully');
    } catch (e) {
      errorSnackBar('Failed to update ${addon.name}: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _uninstallAddon(Addon addon) async {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AnymeXDialog(
        title: 'Uninstall ${addon.name}',
        message:
            'Are you sure you want to uninstall ${addon.name}? This will delete the downloaded binary.',
        confirmText: 'Uninstall',
        onConfirm: () async {
          try {
            await addon.uninstall();
            snackBar('${addon.name} uninstalled');
          } catch (e) {
            errorSnackBar('Failed to uninstall ${addon.name}: $e');
          }
          if (mounted) setState(() {});
        },
      ),
    );
  }

  Future<void> _toggleTorrServer(TorrServerAddon addon) async {
    try {
      if (addon.isRunning) {
        await addon.stop();
        snackBar('TorrServer stopped');
      } else {
        await addon.ensureStarted();
        snackBar(
            'TorrServer started on port ${addon.controller?.port ?? 'default'}');
      }
    } catch (e) {
      errorSnackBar('Failed to toggle TorrServer: $e');
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Add-ons',
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16.0,
            AnymeXHeaderScope.of(ctx),
            16.0,
            32.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoBanner(theme),
              const SizedBox(height: 20),
              AnymeXSectionBuilder(
                title: 'Available Add-ons',
                children: _addonManager.addons.map((addon) {
                  if (addon is TorrServerAddon) {
                    return _buildTorrServerTile(context, addon, theme);
                  }
                  return _buildGenericAddonTile(context, addon, theme);
                }).toList(),
              ),
              const SizedBox(height: 20),
              _buildQuickActions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(ColorScheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceContainer.opaque(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.outlineVariant.opaque(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.primary.opaque(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              HugeIcons.strokeRoundedPlug01,
              color: theme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymeXText(
                  'Add-on Extensions',
                  variant: TextVariant.bold,
                  size: 15,
                  color: theme.onSurface,
                ),
                const SizedBox(height: 4),
                AnymeXText(
                  'Add-ons power background services such as the TorrServer torrent streaming engine for direct magnet link playback.',
                  variant: TextVariant.regular,
                  size: 13,
                  color: theme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTorrServerTile(
    BuildContext context,
    TorrServerAddon addon,
    ColorScheme theme,
  ) {
    return Obx(() {
      final isInstalled = addon.installed.value;
      final isDownloading = addon.downloading.value;
      final progress = addon.progress.value;
      final hasUpdate = addon.hasUpdate.value;
      final isRunning = addon.isRunning;
      final port = addon.controller?.port;

      return AnymeXTile(
        icon: Icons.cloud_download_rounded,
        title: addon.name,
        showChevron: false,
        subtitleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildBadge(
                  label: addon.version,
                  color: theme.primary.opaque(0.12),
                  textColor: theme.primary,
                ),
                const SizedBox(width: 8),
                _buildStatusDot(
                  isActive: isInstalled,
                  activeColor: theme.primary,
                  inactiveColor: theme.onSurfaceVariant.opaque(0.4),
                ),
                const SizedBox(width: 6),
                AnymeXText(
                  isInstalled ? 'Installed' : 'Not Installed',
                  variant: TextVariant.semiBold,
                  size: 12,
                  color: isInstalled ? theme.onSurface : theme.onSurfaceVariant,
                ),
                if (isInstalled) ...[
                  const SizedBox(width: 10),
                  _buildStatusDot(
                    isActive: isRunning,
                    activeColor: Colors.green,
                    inactiveColor: theme.onSurfaceVariant.opaque(0.4),
                  ),
                  const SizedBox(width: 6),
                  AnymeXText(
                    isRunning
                        ? 'Running${port != null ? ' (:$port)' : ''}'
                        : 'Stopped',
                    variant: TextVariant.semiBold,
                    size: 12,
                    color: isRunning ? Colors.green : theme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ],
        ),
        customContent: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDownloading) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.surfaceContainerHighest.opaque(0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.outlineVariant.opaque(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnymeXText(
                              'Downloading package...',
                              size: 12.5,
                              variant: TextVariant.semiBold,
                              color: theme.onSurface,
                            ),
                          ],
                        ),
                        AnymeXText(
                          progress > 0
                              ? '${(progress * 100).toStringAsFixed(0)}%'
                              : 'Preparing...',
                          size: 12.5,
                          variant: TextVariant.bold,
                          color: theme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress > 0 ? progress : null,
                        backgroundColor: theme.surfaceContainerHighest.opaque(0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isDownloading && !isInstalled) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _installAddon(addon),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_rounded, color: theme.onPrimary, size: 20),
                      const SizedBox(width: 8),
                      AnymeXText(
                        'Install ${addon.name}',
                        variant: TextVariant.bold,
                        color: theme.onPrimary,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (isInstalled && !isDownloading) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _toggleTorrServer(addon),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRunning
                            ? theme.surfaceContainerHighest.opaque(0.6)
                            : theme.primary,
                        foregroundColor: isRunning ? theme.onSurface : theme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            size: 20,
                            color: isRunning ? theme.onSurface : theme.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          AnymeXText(
                            isRunning ? 'Stop Service' : 'Start Service',
                            variant: TextVariant.bold,
                            size: 15,
                            color: isRunning ? theme.onSurface : theme.onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasUpdate) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _updateAddon(addon),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.tertiary,
                        foregroundColor: theme.onTertiary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.system_update_alt_rounded,
                            size: 20,
                            color: theme.onTertiary,
                          ),
                          const SizedBox(width: 8),
                          AnymeXText(
                            'Update',
                            variant: TextVariant.bold,
                            size: 15,
                            color: theme.onTertiary,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => _uninstallAddon(addon),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.error.opaque(0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: theme.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildGenericAddonTile(
    BuildContext context,
    Addon addon,
    ColorScheme theme,
  ) {
    return Obx(() {
      final isInstalled = addon.installed.value;
      final isDownloading = addon.downloading.value;

      return AnymeXTile(
        icon: addon.icon,
        title: addon.name,
        showChevron: false,
        subtitleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusDot(
                  isActive: isInstalled,
                  activeColor: theme.primary,
                  inactiveColor: theme.onSurfaceVariant.opaque(0.4),
                ),
                const SizedBox(width: 6),
                AnymeXText(
                  isInstalled ? 'Installed' : 'Not Installed',
                  variant: TextVariant.semiBold,
                  size: 12,
                  color: isInstalled ? theme.onSurface : theme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
        customContent: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isDownloading && !isInstalled) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _installAddon(addon),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_rounded, color: theme.onPrimary, size: 20),
                      const SizedBox(width: 8),
                      AnymeXText(
                        'Install ${addon.name}',
                        variant: TextVariant.bold,
                        color: theme.onPrimary,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (isInstalled && !isDownloading) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _uninstallAddon(addon),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.error.opaque(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline_rounded, color: theme.error, size: 20),
                      const SizedBox(width: 8),
                      AnymeXText(
                        'Uninstall ${addon.name}',
                        variant: TextVariant.bold,
                        color: theme.error,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: AnymeXText(
        label,
        size: 11,
        variant: TextVariant.bold,
        color: textColor,
      ),
    );
  }

  Widget _buildStatusDot({
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? activeColor : inactiveColor,
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme theme) {
    return AnymeXSectionBuilder(
      title: 'Management',
      children: [
        AnymeXTile(
          icon: Icons.refresh_rounded,
          title: 'Check for Add-on Updates',
          subtitle: 'Query remote repository for add-on updates',
          trailing: _isCheckingUpdates
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primary,
                  ),
                )
              : null,
          onTap: _isCheckingUpdates ? null : _checkUpdates,
        ),
      ],
    );
  }
}
