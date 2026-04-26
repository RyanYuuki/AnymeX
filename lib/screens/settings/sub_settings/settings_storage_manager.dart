import 'package:anymex/controllers/services/cloud/cloud_auth_service.dart';
import 'package:anymex/controllers/services/storage/storage_manager_service.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsStorageManager extends StatefulWidget {
  const SettingsStorageManager({super.key});

  @override
  State<SettingsStorageManager> createState() => _SettingsStorageManagerState();
}

class _SettingsStorageManagerState extends State<SettingsStorageManager> {
  final _service = StorageManagerService();

  bool _isLoading = true;
  bool _isRunningAction = false;
  int _imageCacheBytes = 0;
  late double _thresholdGb;

  bool get _isCloudLoggedIn {
    try {
      return Get.find<CloudAuthService>().isLoggedIn.value;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _thresholdGb = _service.getThresholdGb();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    final cacheBytes = await _service.getImageCacheSizeBytes();
    if (!mounted) return;
    setState(() {
      _imageCacheBytes = cacheBytes;
      _isLoading = false;
    });
  }

  Future<void> _clearCacheNow() async {
    if (_isRunningAction) return;
    setState(() => _isRunningAction = true);
    try {
      await _service.clearImageCache();
      await Future.delayed(const Duration(milliseconds: 150));
      await _refresh();
      snackBar('Image cache cleared');
    } catch (e) {
      snackBar('Failed to clear cache: $e');
    } finally {
      if (mounted) setState(() => _isRunningAction = false);
    }
  }

  Future<void> _factoryResetIsar() async {
    if (_isRunningAction) return;

    String warningMessage = _isCloudLoggedIn
        ? 'This will permanently delete all LOCAL data stored by AnymeX on this device. This cannot be undone.\n\n'
            '⚠️ Your cloud data (profiles, library, settings) will NOT be affected. '
            'You can restore it by signing back into your cloud account.'
        : 'This will permanently delete all data stored by AnymeX. This cannot be undone.\n\n'
            'This includes your profiles, library, settings, and all cached data.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Factory Reset'),
        content: Text(warningMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRunningAction = true);
    try {
      await _service.factoryResetIsar();
      if (mounted) {
        snackBar('Local data deleted. App will restart.');
      }
    } catch (e) {
      snackBar('Factory reset failed: $e');
    } finally {
      if (mounted) setState(() => _isRunningAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thresholdBytes = (_thresholdGb * 1024 * 1024 * 1024).round();
    final usageRatio = thresholdBytes == 0
        ? 0.0
        : (_imageCacheBytes / thresholdBytes).clamp(0.0, 1.0);

    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            const NestedHeader(title: 'Storage Manager'),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                child: Column(
                  children: [
                    // ── Cloud warning banner ──
                    if (_isCloudLoggedIn)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.orange.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_rounded,
                                size: 20, color: Colors.orange[700]),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You are signed into cloud sync. Factory reset only clears LOCAL data — your cloud data is safe.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Cached images card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: context.colors.surfaceContainer.opaque(0.35),
                        border: Border.all(
                          color: context.colors.outline.opaque(0.12),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cached Images',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _service.formatBytes(_imageCacheBytes),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.primary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: usageRatio,
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Threshold: ${_thresholdGb.toStringAsFixed(1)} GB',
                                  style: TextStyle(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),

                    // ── Actions card ──
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: context.colors.surfaceContainer.opaque(0.30),
                      ),
                      child: Column(
                        children: [
                          CustomSliderTile(
                            icon: Icons.storage_rounded,
                            title: 'Auto-clear threshold',
                            description:
                                'If image cache reaches this size, it will be cleared automatically.',
                            sliderValue: _thresholdGb,
                            min: StorageManagerService.minThresholdGb,
                            max: StorageManagerService.maxThresholdGb,
                            divisions: 39,
                            label: '${_thresholdGb.toStringAsFixed(1)} GB',
                            onChanged: (value) {
                              setState(() => _thresholdGb = value);
                            },
                            onChangedEnd: (value) {
                              _service.setThresholdGb(value);
                              _service
                                  .enforceImageCacheLimit()
                                  .then((wasCleared) {
                                if (!mounted || !wasCleared) return;
                                snackBar(
                                    'Image cache exceeded threshold and was cleared');
                                _refresh();
                              });
                            },
                          ),
                          CustomTile(
                            icon: Icons.delete_sweep_rounded,
                            title: 'Clear image cache now',
                            description:
                                'Delete all currently cached network images.',
                            onTap: _clearCacheNow,
                            postFix: _isRunningAction
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                          ),
                          CustomTile(
                            icon: Icons.warning_rounded,
                            title: 'Factory reset',
                            description: _isCloudLoggedIn
                                ? 'Delete all local data (cloud data is safe)'
                                : 'Delete everything stored of AnymeX permanently.',
                            descColor: context.colors.error,
                            onTap: _factoryResetIsar,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
