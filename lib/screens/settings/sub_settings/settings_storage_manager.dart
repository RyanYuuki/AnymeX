import 'package:anymex/l10n/l10n_extension.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/services/storage/storage_manager_service.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

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
            return AnymeXDialog(
              title: context.l10n.clearAppCache,
              confirmText: context.l10n.clearSelected,
              onConfirm: () async {
                await _executeClear(
                  deleteImages: deleteImages,
                  deleteTorrents: deleteTorrents,
                  deleteSnapshots: deleteSnapshots,
                  deleteOther: deleteOther,
                );
              },
              contentWidget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnymeXTile.checkbox(
                    title: context.l10n.cachedImages,
                    subtitle: context.l10n.appPostersIconsAvatarsSize((_service.formatBytes(imageSize)).toString()),
                    value: deleteImages,
                    onChanged: (v) => setDialogState(() => deleteImages = v),
                  ),
                  const SizedBox(height: 8),
                  AnymeXTile.checkbox(
                    title: context.l10n.torrentStreamCache,
                    subtitle: context.l10n.temporaryVideoChunksSize((_service.formatBytes(torrentSize)).toString()),
                    value: deleteTorrents,
                    onChanged: (v) => setDialogState(() => deleteTorrents = v),
                  ),
                  const SizedBox(height: 8),
                  AnymeXTile.checkbox(
                    title: context.l10n.novelSnapshots,
                    subtitle: context.l10n.downloadedWebNovelPagesSize((_service.formatBytes(snapshotSize)).toString()),
                    value: deleteSnapshots,
                    onChanged: (v) => setDialogState(() => deleteSnapshots = v),
                  ),
                  const SizedBox(height: 8),
                  AnymeXTile.checkbox(
                    title: context.l10n.otherTemporaryFiles,
                    subtitle: context.l10n.logsTempDownloadsSize((_service.formatBytes(otherTempSize)).toString()),
                    value: deleteOther,
                    onChanged: (v) => setDialogState(() => deleteOther = v),
                  ),
                ],
              ),
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
      snackBar(Get.context!.l10n.selectedCacheCleared);
    } catch (e) {
      snackBar(Get.context!.l10n.failedToClearCache(e.toString()));
    } finally {
      if (mounted) setState(() => _isRunningAction = false);
    }
  }

  Future<void> _factoryResetIsar() async {
    if (_isRunningAction) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AnymeXDialog(
        title: context.l10n.factoryReset,
        confirmText: context.l10n.deleteAll,
        confirmResultGetter: () => true,
        onConfirm: () {},
        message: context.l10n.thisWillPermanentlyDeleteAllData,
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRunningAction = true);
    try {
      await _service.factoryResetIsar();
      snackBar(Get.context!.l10n.appDataHasBeenCompletelyReset);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      snackBar(Get.context!.l10n.factoryResetFailed(e.toString()));
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

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: context.l10n.storageManager,
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.0, AnymeXHeaderScope.of(ctx), 16.0, 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXSectionBuilder(
                        title: context.l10n.cacheOverview,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AnymeXText(
                                        context.l10n.temporaryAppCache,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: context.colors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      AnymeXText(
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
                                      AnymeXText(
                                        context.l10n.thresholdGb(_thresholdGb.toStringAsFixed(1)),
                                        style: TextStyle(
                                          color: context.colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                      AnymeXSectionBuilder(
                        title: context.l10n.storageOptions,
                        children: [
                          AnymeXTile.slider(
                            icon: Icons.storage_rounded,
                            title: context.l10n.autoClearThreshold,
                            subtitle:
                                context.l10n.ifTemporaryAppCacheReachesThis,
                            value: _thresholdGb,
                            min: StorageManagerService.minThresholdGb,
                            max: StorageManagerService.maxThresholdGb,
                            divisions: 39,
                            valueTransformer: (v) =>
                                '${v.toStringAsFixed(1)} GB',
                            onChanged: (value) {
                              setState(() => _thresholdGb = value);
                              _service.setThresholdGb(value);
                              _service
                                  .enforceImageCacheLimit()
                                  .then((wasCleared) {
                                if (!mounted || !wasCleared) return;
                                snackBar(
                                    Get.context!.l10n.appCacheExceededThresholdAndWas);
                                _refresh();
                              });
                            },
                          ),
                          AnymeXTile(
                            icon: Icons.delete_sweep_rounded,
                            title: context.l10n.clearAppCacheNow,
                            subtitle:
                                context.l10n.deleteAllCachedImagesTorrentStream,
                            onTap: _showClearCacheDialog,
                            trailing: _isRunningAction
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                          ),
                          AnymeXTile(
                            icon: Icons.warning_rounded,
                            title: context.l10n.factoryReset2,
                            subtitle:
                                context.l10n.deleteEverythingStoredOfAnymexPermanently,
                            iconColor: context.colors.error,
                            onTap: _factoryResetIsar,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
      ),
    );
  }
}
