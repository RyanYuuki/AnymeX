import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class HistoryEditor extends StatefulWidget {
  final ItemType type;

  const HistoryEditor({super.key, required this.type});

  @override
  State<HistoryEditor> createState() => _HistoryEditorState();
}

class _HistoryEditorState extends State<HistoryEditor> {
  bool _isSelecting = false;
  final Set<String> _selectedMediaIds = {};

  final offlineStorage = Get.find<OfflineStorageController>();

  bool get _isAnime => widget.type == ItemType.anime;
  String get _historyLabel => _isAnime ? 'watch history' : 'read history';
  String get _historyTitle => _isAnime ? 'Watch History' : 'Read History';

  int _getAnimeLastWatched(OfflineMedia e) {
    if (e.currentEpisode?.lastWatchedTime != null &&
        e.currentEpisode!.lastWatchedTime! > 0) {
      return e.currentEpisode!.lastWatchedTime!;
    }
    if (e.watchedEpisodes != null && e.watchedEpisodes!.isNotEmpty) {
      return e.watchedEpisodes!.last.lastWatchedTime ?? 0;
    }
    return 0;
  }

  int _getMangaLastRead(OfflineMedia e) {
    if (e.currentChapter?.lastReadTime != null &&
        e.currentChapter!.lastReadTime! > 0) {
      return e.currentChapter!.lastReadTime!;
    }
    if (e.readChapters != null && e.readChapters!.isNotEmpty) {
      return e.readChapters!.last.lastReadTime ?? 0;
    }
    return 0;
  }

  Stream<List<OfflineMedia>> _historyStream() {
    if (widget.type == ItemType.anime) {
      return offlineStorage.watchAnimeLibrary().map((items) => items
          .where((e) => e.hasRequiredHistoryMedia(ItemType.anime))
          .toList()
        ..sort((a, b) =>
            _getAnimeLastWatched(b).compareTo(_getAnimeLastWatched(a))));
    }

    if (widget.type == ItemType.manga) {
      return offlineStorage.watchMangaLibrary().map((items) => items
          .where((e) => e.hasRequiredHistoryMedia(ItemType.manga))
          .toList()
        ..sort((a, b) => _getMangaLastRead(b).compareTo(_getMangaLastRead(a))));
    }

    return offlineStorage.watchNovelLibrary().map((items) => items
        .where((e) => e.hasRequiredHistoryMedia(ItemType.novel))
        .toList()
      ..sort((a, b) => _getMangaLastRead(b).compareTo(_getMangaLastRead(a))));
  }

  Future<void> _deleteHistory(OfflineMedia media) async {
    final deleted = await offlineStorage.clearMediaHistory(
      media.mediaId ?? '',
      mediaType: widget.type,
    );
    if (!deleted) return;

    HapticFeedback.lightImpact();
    snackBar('History item deleted');
  }

  Future<void> _deleteAllHistory(List<OfflineMedia> items) async {
    final deletedCount = await offlineStorage.clearMediaHistoryBulk(
      items.map((e) => e.mediaId ?? ''),
      mediaType: widget.type,
    );

    setState(() {
      _selectedMediaIds.clear();
      _isSelecting = false;
    });

    HapticFeedback.mediumImpact();
    snackBar(deletedCount > 0 ? 'All history cleared' : 'No history to clear');
  }

  Future<void> _deleteSelectedHistory() async {
    final deletedCount = await offlineStorage.clearMediaHistoryBulk(
      _selectedMediaIds,
      mediaType: widget.type,
    );

    setState(() {
      _selectedMediaIds.clear();
      _isSelecting = false;
    });

    HapticFeedback.mediumImpact();
    snackBar('$deletedCount history items deleted');
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

  void _onCardTap(String mediaId) {
    if (!_isSelecting) {
      setState(() {
        _isSelecting = true;
        _selectedMediaIds.add(mediaId);
      });
      HapticFeedback.selectionClick();
    } else {
      _toggleSelection(mediaId);
    }
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

  String _formatChapterNumber(double? number) {
    if (number == null) return '?';
    return number % 1 == 0 ? number.toInt().toString() : number.toString();
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

  void _showDeleteDialog(OfflineMedia item) {
    final episode = item.currentEpisode ??
        (item.watchedEpisodes != null && item.watchedEpisodes!.isNotEmpty
            ? item.watchedEpisodes!.last
            : null);
    final chapter = item.currentChapter ??
        (item.readChapters != null && item.readChapters!.isNotEmpty
            ? item.readChapters!.last
            : null);
    final itemName = _isAnime
        ? (episode?.title ??
            (episode?.number != null
                ? 'Episode ${episode!.number}'
                : item.name ?? 'Item'))
        : (chapter?.title ??
            (chapter?.number != null
                ? 'Chapter ${_formatChapterNumber(chapter!.number)}'
                : item.name ?? 'Item'));

    AnymeXDialog(
      title: 'Delete History Item',
      message: 'Remove "$itemName" from your $_historyLabel?',
      confirmText: 'Delete',
      onConfirm: () => _deleteHistory(item),
    ).show(context);
  }

  void _showClearAllDialog(List<OfflineMedia> items) {
    AnymeXDialog(
      title: 'Clear All History',
      message:
          'Are you sure you want to clear all $_historyLabel? This action cannot be undone.',
      confirmText: 'Clear All',
      onConfirm: () => _deleteAllHistory(items),
    ).show(context);
  }

  void _showDeleteSelectedDialog() {
    AnymeXDialog(
      title: 'Delete Selected',
      message:
          'Are you sure you want to delete ${_selectedMediaIds.length} ${_selectedMediaIds.length == 1 ? "item" : "items"} from your $_historyLabel?',
      confirmText: 'Delete',
      onConfirm: _deleteSelectedHistory,
    ).show(context);
  }

  BorderRadius _getConnectiveBorderRadius(int index, int totalCount) {
    if (totalCount <= 1) {
      return BorderRadius.circular(18.multiplyRadius());
    }
    if (index == 0) {
      return BorderRadius.only(
        topLeft: Radius.circular(18.multiplyRadius()),
        topRight: Radius.circular(18.multiplyRadius()),
        bottomLeft: Radius.circular(5.multiplyRadius()),
        bottomRight: Radius.circular(5.multiplyRadius()),
      );
    }
    if (index == totalCount - 1) {
      return BorderRadius.only(
        bottomLeft: Radius.circular(18.multiplyRadius()),
        bottomRight: Radius.circular(18.multiplyRadius()),
        topLeft: Radius.circular(5.multiplyRadius()),
        topRight: Radius.circular(5.multiplyRadius()),
      );
    }
    return BorderRadius.circular(5.multiplyRadius());
  }

  Widget _buildEpisodePills(Episode? episode, OfflineMedia item) {
    final epLabel = episode?.number != null
        ? 'EP ${episode!.number}'
        : '${item.watchedEpisodes?.length ?? 1} watched';

    final hasTrack = episode?.timeStampInMilliseconds != null &&
        episode?.durationInMilliseconds != null;
    final currentTrack = episode?.timeStampInMilliseconds ?? 0;
    final totalDuration = episode?.durationInMilliseconds ?? 1;
    final progress =
        totalDuration > 0 ? (currentTrack / totalDuration).clamp(0.0, 1.0) : 0.0;

    final leftRadius = BorderRadius.only(
      topLeft: Radius.circular(14.multiplyRadius()),
      bottomLeft: Radius.circular(14.multiplyRadius()),
      topRight: Radius.circular(4.multiplyRadius()),
      bottomRight: Radius.circular(4.multiplyRadius()),
    );
    final rightRadius = BorderRadius.only(
      topRight: Radius.circular(14.multiplyRadius()),
      bottomRight: Radius.circular(14.multiplyRadius()),
      topLeft: Radius.circular(4.multiplyRadius()),
      bottomLeft: Radius.circular(4.multiplyRadius()),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.12),
                borderRadius: leftRadius,
                border: Border.all(
                  color: context.colors.primary.withOpacity(0.25),
                  width: 0.6,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 13,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: 3),
                  AnymeXText(
                    epLabel,
                    size: 11,
                    variant: TextVariant.semiBold,
                    color: context.colors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2.5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest.withOpacity(0.45),
                borderRadius: rightRadius,
                border: Border.all(
                  color: context.colors.onSurface.withOpacity(0.06),
                  width: 0.6,
                ),
              ),
              child: AnymeXText(
                hasTrack
                    ? '${_formatDuration(currentTrack)} / ${_formatDuration(totalDuration)}'
                    : '${(progress * 100).toInt()}%',
                size: 11,
                variant: TextVariant.semiBold,
                color: context.colors.onSurface.withOpacity(0.65),
              ),
            ),
          ],
        ),
        if (hasTrack) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  context.colors.surfaceContainerHighest.withOpacity(0.4),
              valueColor: AlwaysStoppedAnimation<Color>(
                context.colors.primary,
              ),
              minHeight: 3.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChapterPills(Chapter? chapter, OfflineMedia item) {
    final chapLabel = chapter?.number != null
        ? 'CH ${_formatChapterNumber(chapter!.number)}'
        : '${item.readChapters?.length ?? 1} read';

    final hasPages =
        chapter?.pageNumber != null && chapter?.totalPages != null;
    final currentPage = chapter?.pageNumber ?? 1;
    final totalPages =
        (chapter?.totalPages ?? 1) <= 0 ? 1 : chapter!.totalPages!;
    final progress = (currentPage / totalPages).clamp(0.0, 1.0);

    final leftRadius = BorderRadius.only(
      topLeft: Radius.circular(14.multiplyRadius()),
      bottomLeft: Radius.circular(14.multiplyRadius()),
      topRight: Radius.circular(4.multiplyRadius()),
      bottomRight: Radius.circular(4.multiplyRadius()),
    );
    final rightRadius = BorderRadius.only(
      topRight: Radius.circular(14.multiplyRadius()),
      bottomRight: Radius.circular(14.multiplyRadius()),
      topLeft: Radius.circular(4.multiplyRadius()),
      bottomLeft: Radius.circular(4.multiplyRadius()),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.12),
                borderRadius: leftRadius,
                border: Border.all(
                  color: context.colors.primary.withOpacity(0.25),
                  width: 0.6,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 13,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: 3),
                  AnymeXText(
                    chapLabel,
                    size: 11,
                    variant: TextVariant.semiBold,
                    color: context.colors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2.5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest.withOpacity(0.45),
                borderRadius: rightRadius,
                border: Border.all(
                  color: context.colors.onSurface.withOpacity(0.06),
                  width: 0.6,
                ),
              ),
              child: AnymeXText(
                hasPages
                    ? '$currentPage / $totalPages pages'
                    : '${(progress * 100).toInt()}%',
                size: 11,
                variant: TextVariant.semiBold,
                color: context.colors.onSurface.withOpacity(0.65),
              ),
            ),
          ],
        ),
        if (hasPages) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  context.colors.surfaceContainerHighest.withOpacity(0.4),
              valueColor: AlwaysStoppedAnimation<Color>(
                context.colors.primary,
              ),
              minHeight: 3.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoryProgress(OfflineMedia item) {
    if (_isAnime) {
      final episode = item.currentEpisode ??
          (item.watchedEpisodes != null && item.watchedEpisodes!.isNotEmpty
              ? item.watchedEpisodes!.last
              : null);
      return _buildEpisodePills(episode, item);
    }

    final chapter = item.currentChapter ??
        (item.readChapters != null && item.readChapters!.isNotEmpty
            ? item.readChapters!.last
            : null);
    return _buildChapterPills(chapter, item);
  }

  Widget _buildHistoryCard(OfflineMedia item, int index, int totalCount) {
    final mediaId = item.mediaId ?? '';
    final isSelected = _selectedMediaIds.contains(mediaId);
    final episode = item.currentEpisode ??
        (item.watchedEpisodes != null && item.watchedEpisodes!.isNotEmpty
            ? item.watchedEpisodes!.last
            : null);
    final chapter = item.currentChapter ??
        (item.readChapters != null && item.readChapters!.isNotEmpty
            ? item.readChapters!.last
            : null);

    final subtitle = _isAnime
        ? (episode?.title ??
            (episode?.number != null ? 'Episode ${episode!.number}' : 'Watched'))
        : (chapter?.title ??
            (chapter?.number != null
                ? 'Chapter ${_formatChapterNumber(chapter!.number)}'
                : 'Read'));
    final imageUrl = _isAnime
        ? (episode?.thumbnail ?? item.poster ?? item.cover ?? '')
        : (item.cover ?? item.poster ?? '');
    final radius = _getConnectiveBorderRadius(index, totalCount);

    return Container(
      margin: const EdgeInsets.only(bottom: 3.5),
      decoration: BoxDecoration(
        color: isSelected
            ? context.colors.primary.withOpacity(0.12)
            : context.colors.surfaceContainer
                .opaque(0.45, iReallyMeanIt: true),
        borderRadius: radius,
        border: Border.all(
          color: isSelected
              ? context.colors.primary.withOpacity(0.5)
              : context.colors.onSurface
                  .opaque(0.08, iReallyMeanIt: true),
          width: 0.8,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: context.colors.primary.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: AnymexOnTap(
          onTap: () => _onCardTap(mediaId),
          onLongPress: () {
            if (!_isSelecting) {
              setState(() {
                _isSelecting = true;
                _selectedMediaIds.add(mediaId);
              });
              HapticFeedback.mediumImpact();
            }
          },
          scale: 0.98,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (_isSelecting) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? context.colors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.onSurface.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: context.colors.onPrimary,
                          )
                        : null,
                  ),
                ],
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.multiplyRadius()),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.colors.outline.withOpacity(0.08),
                      ),
                      borderRadius: BorderRadius.circular(12.multiplyRadius()),
                    ),
                    child: AnymeXImage(
                      width: 64,
                      height: 64,
                      radius: 12.multiplyRadius(),
                      imageUrl: imageUrl,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXText(
                        item.name ?? item.jname ?? 'Unknown',
                        size: 14.5,
                        variant: TextVariant.semiBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        isMarquee: true,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        AnymeXText(
                          subtitle,
                          size: 12,
                          color: context.colors.onSurfaceVariant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      _buildHistoryProgress(item),
                    ],
                  ),
                ),
                if (!_isSelecting) ...[
                  const SizedBox(width: 8),
                  AnymexOnTap(
                    scale: 0.9,
                    onTap: () => _showDeleteDialog(item),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colors.error.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(14.multiplyRadius()),
                        border: Border.all(
                          color: context.colors.error.withOpacity(0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        Iconsax.trash,
                        color: context.colors.error,
                        size: 16,
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

  Widget _buildEmptyState(double topPadding) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: topPadding, left: 24, right: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colors.outline.withOpacity(0.1),
                ),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 56,
                color: context.colors.onSurface.withOpacity(0.35),
              ),
            ),
            const SizedBox(height: 20),
            AnymeXText(
              _isAnime ? 'No watch history' : 'No read history',
              size: 20,
              variant: TextVariant.semiBold,
              color: context.colors.onSurface,
            ),
            const SizedBox(height: 8),
            AnymeXText(
              _isAnime
                  ? 'Your watch history will appear here once you start watching.'
                  : 'Your read history will appear here once you start reading.',
              textAlign: TextAlign.center,
              size: 14,
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomFAB(List<OfflineMedia> historyItems) {
    if (historyItems.isEmpty) return const SizedBox.shrink();

    final isSelectionActive = _isSelecting && _selectedMediaIds.isNotEmpty;
    final isClearAllActive = !_isSelecting;

    if (!isSelectionActive && !isClearAllActive) {
      return const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isSelectionActive
          ? AnymexOnTap(
              key: const ValueKey('fab_delete_selected'),
              onTap: _showDeleteSelectedDialog,
              scale: 0.94,
              child: Container(
                height: 50,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: context.colors.error,
                  borderRadius: BorderRadius.circular(30.multiplyRadius()),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.error.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.trash,
                      color: context.colors.onError,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    AnymeXText(
                      'Delete Selected (${_selectedMediaIds.length})',
                      size: 14,
                      variant: TextVariant.bold,
                      color: context.colors.onError,
                    ),
                  ],
                ),
              ),
            )
          : AnymexOnTap(
              key: const ValueKey('fab_clear_all'),
              onTap: () => _showClearAllDialog(historyItems),
              scale: 0.94,
              child: Container(
                height: 50,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      context.colors.surfaceContainerHighest.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30.multiplyRadius()),
                  border: Border.all(
                    color: context.colors.error.withOpacity(0.3),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_sweep_rounded,
                      color: context.colors.error,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    AnymeXText(
                      'Clear History',
                      size: 14,
                      variant: TextVariant.bold,
                      color: context.colors.error,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderAction(List<OfflineMedia> historyItems) {
    if (historyItems.isEmpty) return const SizedBox.shrink();

    final leftRadius = BorderRadius.only(
      topLeft: Radius.circular(18.multiplyRadius()),
      bottomLeft: Radius.circular(18.multiplyRadius()),
      topRight: Radius.circular(5.multiplyRadius()),
      bottomRight: Radius.circular(5.multiplyRadius()),
    );
    final rightRadius = BorderRadius.only(
      topRight: Radius.circular(18.multiplyRadius()),
      bottomRight: Radius.circular(18.multiplyRadius()),
      topLeft: Radius.circular(5.multiplyRadius()),
      bottomLeft: Radius.circular(5.multiplyRadius()),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isSelecting) ...[
          AnymexOnTap(
            scale: 0.92,
            onTap: () => _selectAll(historyItems),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    context.colors.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: leftRadius,
                border: Border.all(
                  color: context.colors.onSurface.withOpacity(0.08),
                  width: 0.8,
                ),
              ),
              child: Icon(
                _selectedMediaIds.length == historyItems.length
                    ? Icons.deselect_rounded
                    : Icons.select_all_rounded,
                color: context.colors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 3),
          AnymexOnTap(
            scale: 0.92,
            onTap: _toggleSelectMode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.15),
                borderRadius: rightRadius,
                border: Border.all(
                  color: context.colors.primary.withOpacity(0.3),
                  width: 0.8,
                ),
              ),
              child: Icon(
                Icons.check_rounded,
                color: context.colors.primary,
                size: 20,
              ),
            ),
          ),
        ] else ...[
          AnymexOnTap(
            scale: 0.92,
            onTap: _toggleSelectMode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    context.colors.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(18.multiplyRadius()),
                border: Border.all(
                  color: context.colors.onSurface.withOpacity(0.08),
                  width: 0.8,
                ),
              ),
              child: Icon(
                Icons.checklist_rounded,
                color: context.colors.onSurface,
                size: 20,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OfflineMedia>>(
      stream: _historyStream(),
      builder: (context, snapshot) {
        final historyItems = snapshot.data ?? [];
        final subtitle = _isSelecting
            ? '${_selectedMediaIds.length} of ${historyItems.length} selected'
            : '${historyItems.length} ${historyItems.length == 1 ? "item" : "items"}';

        return AnymeXScaffold(
          showHeader: true,
          headerTitle: _historyTitle,
          headerSubtitle: subtitle,
          headerAction: _buildHeaderAction(historyItems),
          floatingActionButton: _buildCustomFAB(historyItems),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          body: Builder(
            builder: (ctx) {
              final topPadding = AnymeXHeaderScope.of(ctx);

              if (historyItems.isEmpty) {
                return _buildEmptyState(topPadding);
              }

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 100),
                itemCount: historyItems.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _buildHistoryCard(
                      historyItems[index], index, historyItems.length);
                },
              );
            },
          ),
        );
      },
    );
  }
}
