import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/screens/library/controller/library_controller.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HistoryEditor extends StatefulWidget {
  const HistoryEditor({super.key});

  @override
  State<HistoryEditor> createState() => _HistoryEditorState();
}

class _HistoryEditorState extends State<HistoryEditor> {
  bool _isSelecting = false;
  final Set<String> _selectedMediaIds = {};

  final offlineStorage = Get.find<OfflineStorageController>();

  Future<void> _deleteHistory(OfflineMedia media) async {
    final mediaToUpdate = offlineStorage.getAnimeById(media.mediaId ?? '');
    if (mediaToUpdate == null) return;

    await offlineStorage.addOrUpdateAnime(
      convertOfflineToMedia(mediaToUpdate),
      mediaToUpdate.episodes,
      null,
    );

    HapticFeedback.lightImpact();
    snackBar('History item deleted');
    Get.delete<LibraryController>();
  }

  Future<void> _deleteAllHistory(List<OfflineMedia> items) async {
    for (var media in items) {
      final mediaToUpdate = offlineStorage.getAnimeById(media.mediaId ?? '');
      if (mediaToUpdate == null) continue;

      await offlineStorage.addOrUpdateAnime(
        convertOfflineToMedia(mediaToUpdate),
        mediaToUpdate.episodes,
        null,
      );
    }

    setState(() {
      _selectedMediaIds.clear();
      _isSelecting = false;
    });

    HapticFeedback.mediumImpact();
    snackBar('All history cleared');
    Get.delete<LibraryController>();
  }

  Future<void> _deleteSelectedHistory(List<OfflineMedia> allItems) async {
    for (var mediaId in _selectedMediaIds) {
      final mediaToUpdate = offlineStorage.getAnimeById(mediaId);
      if (mediaToUpdate == null) continue;

      await offlineStorage.addOrUpdateAnime(
        convertOfflineToMedia(mediaToUpdate),
        mediaToUpdate.episodes,
        null,
      );
    }

    setState(() {
      _selectedMediaIds.clear();
      _isSelecting = false;
    });

    HapticFeedback.mediumImpact();
    snackBar('${_selectedMediaIds.length} history items deleted');
    Get.delete<LibraryController>();
  }

  void _toggleSelection(String mediaId) {
    setState(() {
      if (_selectedMediaIds.contains(mediaId)) {
        _selectedMediaIds.remove(mediaId);
        if (_selectedMediaIds.isEmpty) {
          _isSelecting = false;
        }
      } else {
        _selectedMediaIds.add(mediaId);
      }
    });
    HapticFeedback.selectionClick();
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelecting = !_isSelecting;
      if (!_isSelecting) {
        _selectedMediaIds.clear();
      }
    });
    HapticFeedback.lightImpact();
  }

  void _selectAll(List<OfflineMedia> items) {
    setState(() {
      if (_selectedMediaIds.length == items.length) {
        _selectedMediaIds.clear();
      } else {
        _selectedMediaIds.clear();
        _selectedMediaIds.addAll(items.map((e) => e.mediaId ?? ''));
      }
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<List<OfflineMedia>>(
          stream: offlineStorage.watchAnimeLibrary().map((items) => items
              .where((e) => e.currentEpisode?.currentTrack != null)
              .toList()
            ..sort((a, b) => (b.currentEpisode?.lastWatchedTime ?? 0)
                .compareTo(a.currentEpisode?.lastWatchedTime ?? 0))),
          builder: (context, snapshot) {
            final historyItems = snapshot.data ?? [];

            return Column(
              children: [
                _buildAppBar(historyItems),
                Expanded(
                  child: _buildContent(historyItems),
                ),
              ],
            );
          },
        ),
        floatingActionButton: StreamBuilder<List<OfflineMedia>>(
          stream: offlineStorage.watchAnimeLibrary().map((items) => items
              .where((e) => e.currentEpisode?.currentTrack != null)
              .toList()),
          builder: (context, snapshot) {
            final historyItems = snapshot.data ?? [];
            return _buildFAB(historyItems);
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(List<OfflineMedia> historyItems) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.4),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.opaque(0.1, iReallyMeanIt: true),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.opaque(0.05, iReallyMeanIt: true),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant
                      .opaque(0.3, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline
                        .opaque(0.1, iReallyMeanIt: true),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Watch History',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _isSelecting
                      ? '${_selectedMediaIds.length} selected'
                      : '${historyItems.length} items',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface
                        .opaque(0.6, iReallyMeanIt: true),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_isSelecting) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectAll(historyItems),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant
                        .opaque(0.3, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline
                          .opaque(0.1, iReallyMeanIt: true),
                    ),
                  ),
                  child: Icon(
                    _selectedMediaIds.length == historyItems.length
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    color: theme.colorScheme.onSurface,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleSelectMode,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSelecting
                      ? theme.colorScheme.primary
                          .opaque(0.3, iReallyMeanIt: true)
                      : theme.colorScheme.surfaceVariant
                          .opaque(0.3, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isSelecting
                        ? theme.colorScheme.primary
                            .opaque(0.3, iReallyMeanIt: true)
                        : theme.colorScheme.outline
                            .opaque(0.1, iReallyMeanIt: true),
                  ),
                ),
                child: Icon(
                  _isSelecting ? Icons.check_rounded : Icons.checklist_rounded,
                  color: _isSelecting
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<OfflineMedia> historyItems) {
    if (historyItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: historyItems.length,
      itemBuilder: (context, index) {
        return _buildHistoryCard(historyItems[index]);
      },
    );
  }

  Widget _buildHistoryCard(OfflineMedia item) {
    final theme = Theme.of(context);
    final mediaId = item.mediaId ?? '';
    final isSelected = _selectedMediaIds.contains(mediaId);
    final episode = item.currentEpisode!;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: theme.colorScheme.surface.opaque(0.4, iReallyMeanIt: true),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary.opaque(0.3, iReallyMeanIt: true)
              : theme.colorScheme.outline.opaque(0.1, iReallyMeanIt: true),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSelecting ? () => _toggleSelection(mediaId) : null,
          onLongPress: !_isSelecting
              ? () {
                  setState(() {
                    _isSelecting = true;
                    _selectedMediaIds.add(mediaId);
                  });
                  HapticFeedback.mediumImpact();
                }
              : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary
                            .opaque(0.05, iReallyMeanIt: true),
                        theme.colorScheme.secondary
                            .opaque(0.05, iReallyMeanIt: true),
                      ],
                    )
                  : null,
            ),
            child: Row(
              children: [
                if (_isSelecting) ...[
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.opaque(0.3),
                        width: 2,
                      ),
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
                          )
                        : null,
                  ),
                ],
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AnymeXImage(
                    width: 80,
                    height: 80,
                    imageUrl:
                        episode.thumbnail ?? item.poster ?? item.cover ?? '',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name ?? item.jname ?? 'Unknown',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        episode.title ?? 'Episode ${episode.number}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.opaque(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Episode ${episode.number}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.opaque(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (episode.currentTrack != null)
                        _buildProgressBar(episode, theme),
                    ],
                  ),
                ),
                if (!_isSelecting) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showDeleteDialog(item),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error
                              .opaque(0.3, iReallyMeanIt: true),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(Episode episode, ThemeData theme) {
    final currentTrack = episode.timeStampInMilliseconds ?? 1;
    final totalDuration = episode.durationInMilliseconds ?? 1;
    final progress = (currentTrack / totalDuration).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _formatDuration(currentTrack),
              style: TextStyle(
                color: theme.colorScheme.onSurface.opaque(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              ' / ${_formatDuration(totalDuration)}',
              style: TextStyle(
                color: theme.colorScheme.onSurface.opaque(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceVariant.opaque(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.opaque(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.opaque(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No watch history',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your watch history will appear here\nonce you start watching',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.opaque(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(List<OfflineMedia> historyItems) {
    if (historyItems.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    if (_isSelecting && _selectedMediaIds.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: () => _deleteSelectedHistory(historyItems),
        backgroundColor: theme.colorScheme.error.opaque(0.7),
        foregroundColor: theme.colorScheme.onError,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: const Icon(Icons.delete_rounded),
        label: Text(
          'Delete Selected',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onError,
          ),
        ),
      );
    }

    return FloatingActionButton.extended(
      onPressed: () => _showClearAllDialog(historyItems),
      backgroundColor: theme.colorScheme.error.opaque(0.7),
      foregroundColor: theme.colorScheme.onError,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      icon: const Icon(Icons.delete_sweep_rounded),
      label: Text(
        'Clear All',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onError,
        ),
      ),
    );
  }

  void _showDeleteDialog(OfflineMedia item) {
    final theme = Theme.of(context);
    final episode = item.currentEpisode!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete History Item',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Remove "${episode.title ?? 'Episode ${episode.number}'}" from your watch history?',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          FilledButton(
            onPressed: () {
              _deleteHistory(item);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(List<OfflineMedia> items) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Clear All History',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to clear all watch history? This action cannot be undone.',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          FilledButton(
            onPressed: () {
              _deleteAllHistory(items);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
