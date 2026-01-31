import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
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
  late List<HistoryItem> _historyItems;
  bool _isSelecting = false;
  final Set<int> _selectedIndices = {};

  final offlineStorage = Get.find<OfflineStorageController>();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final items = <HistoryItem>[];

    for (var anime in offlineStorage.animeLibrary) {
      if (anime.currentEpisode?.currentTrack != null) {
        items.add(HistoryItem(
          media: anime,
          episode: anime.currentEpisode!,
        ));
      }
    }

    items.sort((a, b) => (b.episode.lastWatchedTime ?? 0)
        .compareTo(a.episode.lastWatchedTime ?? 0));

    setState(() {
      _historyItems = items;
    });
  }

  void _deleteHistory(int index) {
    final item = _historyItems[index];

    setState(() {
      item.media.currentEpisode?.currentTrack = null;
      _historyItems.removeAt(index);
    });

    offlineStorage.saveEverything();
    HapticFeedback.lightImpact();
    snackBar('History item deleted (Restart Required)');
  }

  void _deleteAllHistory() {
    for (var item in _historyItems) {
      item.media.currentEpisode?.currentTrack = null;
    }

    setState(() {
      _historyItems.clear();
      _selectedIndices.clear();
      _isSelecting = false;
    });

    offlineStorage.saveEverything();
    HapticFeedback.mediumImpact();
    offlineStorage.animeLibrary.refresh();
    snackBar('All history cleared (Restart Required)');
  }

  void _deleteSelectedHistory() {
    final sortedIndices = _selectedIndices.toList()
      ..sort((a, b) => b.compareTo(a));

    for (var index in sortedIndices) {
      if (index < _historyItems.length) {
        _historyItems[index].media.currentEpisode?.currentTrack = null;
        _historyItems.removeAt(index);
      }
    }

    setState(() {
      _selectedIndices.clear();
      _isSelecting = false;
    });

    offlineStorage.saveEverything();
    HapticFeedback.mediumImpact();
    snackBar('${sortedIndices.length} history items deleted');
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) {
          _isSelecting = false;
        }
      } else {
        _selectedIndices.add(index);
      }
    });
    HapticFeedback.selectionClick();
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelecting = !_isSelecting;
      if (!_isSelecting) {
        _selectedIndices.clear();
      }
    });
    HapticFeedback.lightImpact();
  }

  void _selectAll() {
    setState(() {
      if (_selectedIndices.length == _historyItems.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices.addAll(List.generate(_historyItems.length, (i) => i));
      }
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  Widget _buildAppBar() {
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
                      ? '${_selectedIndices.length} selected'
                      : '${_historyItems.length} items',
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
                onTap: _selectAll,
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
                    _selectedIndices.length == _historyItems.length
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

  Widget _buildContent() {
    if (_historyItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _historyItems.length,
      itemBuilder: (context, index) {
        return _buildHistoryCard(index);
      },
    );
  }

  Widget _buildHistoryCard(int index) {
    final theme = Theme.of(context);
    final item = _historyItems[index];
    final isSelected = _selectedIndices.contains(index);

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
          onTap: _isSelecting ? () => _toggleSelection(index) : null,
          onLongPress: !_isSelecting
              ? () {
                  setState(() {
                    _isSelecting = true;
                    _selectedIndices.add(index);
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
                    imageUrl: item.episode.thumbnail ??
                        item.media.poster ??
                        item.media.cover ??
                        '',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.media.name ?? item.media.jname ?? 'Unknown',
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
                        item.episode.title ?? 'Episode ${item.episode.number}',
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
                        'Episode ${item.episode.number}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.opaque(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (item.episode.currentTrack != null)
                        _buildProgressBar(item, theme),
                    ],
                  ),
                ),
                if (!_isSelecting) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showDeleteDialog(index),
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

  Widget _buildProgressBar(HistoryItem item, ThemeData theme) {
    final currentTrack = item.episode.timeStampInMilliseconds ?? 1;
    final totalDuration = item.episode.durationInMilliseconds ?? 1;
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

  Widget? _buildFAB() {
    if (_historyItems.isEmpty) return null;

    final theme = Theme.of(context);

    if (_isSelecting && _selectedIndices.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: _deleteSelectedHistory,
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
      onPressed: _showClearAllDialog,
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

  void _showDeleteDialog(int index) {
    final theme = Theme.of(context);
    final item = _historyItems[index];

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
          'Remove "${item.episode.title ?? 'Episode ${item.episode.number}'}" from your watch history?',
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
              _deleteHistory(index);
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

  void _showClearAllDialog() {
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
              _deleteAllHistory();
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

class HistoryItem {
  final OfflineMedia media;
  final Episode episode;

  HistoryItem({
    required this.media,
    required this.episode,
  });
}
