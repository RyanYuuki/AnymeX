import 'package:anymex/controllers/services/storage/storage_manager_service.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';

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

  Future<void> _showClearCacheDialog() async {
    setState(() => _isRunningAction = true);
    
    int imageSize = 0;
    int torrentSize = 0;
    int snapshotSize = 0;
    int otherTempSize = 0;
    
    try {
      imageSize = await _service.getImageCacheSize();
      torrentSize = await _service.getTorrentCacheSize();
      snapshotSize = await _service.getSnapshotsCacheSize();
      otherTempSize = await _service.getOtherTempCacheSize();
    } catch (_) {}
    
    setState(() => _isRunningAction = false);
    
    if (!mounted) return;
    
    bool deleteImages = true;
    bool deleteTorrents = true;
    bool deleteSnapshots = false;
    bool deleteOther = true;
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: context.colors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Clear App Cache'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    activeColor: context.colors.primary,
                    title: const Text('Cached Images'),
                    subtitle: Text('App posters, icons, avatars. Size: ${_service.formatBytes(imageSize)}'),
                    value: deleteImages,
                    onChanged: (val) {
                      setDialogState(() => deleteImages = val ?? false);
                    },
                  ),
                  CheckboxListTile(
                    activeColor: context.colors.primary,
                    title: const Text('Torrent Stream Cache'),
                    subtitle: Text('Temporary torrent video data. Size: ${_service.formatBytes(torrentSize)}'),
                    value: deleteTorrents,
                    onChanged: (val) {
                      setDialogState(() => deleteTorrents = val ?? false);
                    },
                  ),
                  CheckboxListTile(
                    activeColor: context.colors.primary,
                    title: const Text('Watch History Snapshots'),
                    subtitle: Text('Screenshots of last-watched frames. Size: ${_service.formatBytes(snapshotSize)}'),
                    value: deleteSnapshots,
                    onChanged: (val) {
                      setDialogState(() => deleteSnapshots = val ?? false);
                    },
                  ),
                  CheckboxListTile(
                    activeColor: context.colors.primary,
                    title: const Text('Other Temporary Files'),
                    subtitle: Text('Video buffer, updates, thumbnails. Size: ${_service.formatBytes(otherTempSize)}'),
                    value: deleteOther,
                    onChanged: (val) {
                      setDialogState(() => deleteOther = val ?? false);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _executeClear(
                      deleteImages: deleteImages,
                      deleteTorrents: deleteTorrents,
                      deleteSnapshots: deleteSnapshots,
                      deleteOther: deleteOther,
                    );
                  },
                  child: const Text('Clear Selected'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeClear({
    required bool deleteImages,
    required bool deleteTorrents,
    required bool deleteSnapshots,
    required bool deleteOther,
  }) async {
    if (_isRunningAction) return;
    setState(() => _isRunningAction = true);
    try {
      if (deleteImages) await _service.clearImageCacheOnly();
      if (deleteTorrents) await _service.clearTorrentCacheOnly();
      if (deleteSnapshots) await _service.clearSnapshotsOnly();
      if (deleteOther) await _service.clearOtherTempOnly();
      
      await Future.delayed(const Duration(milliseconds: 150));
      await _refresh();
      snackBar('Selected cache cleared');
    } catch (e) {
      snackBar('Failed to clear cache: $e');
    } finally {
      if (mounted) setState(() => _isRunningAction = false);
    }
  }

  Future<void> _factoryResetIsar() async {
    if (_isRunningAction) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Factory Reset'),
        content: const Text(
          'This will permanently delete all data stored of AnymeX. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRunningAction = true);
    try {
      await _service.factoryResetIsar();
      snackBar('Isar data deleted');
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
                                  'Temporary App Cache',
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
                                'If temporary app cache reaches this size, it will be cleared automatically.',
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
                                    'App cache exceeded threshold and was cleared');
                                _refresh();
                              });
                            },
                          ),
                          CustomTile(
                            icon: Icons.delete_sweep_rounded,
                            title: 'Clear app cache now',
                            description:
                                'Delete all cached images, torrent stream chunks, and temporary files.',
                            onTap: _showClearCacheDialog,
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
                            description:
                                'Delete everything stored of AnymeX permanently.',
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
