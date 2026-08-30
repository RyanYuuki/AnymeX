import 'dart:ui';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:anymex/screens/library/editor/history_editor.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hugeicons/hugeicons.dart';

class CustomListsEditor extends StatefulWidget {
  final ItemType type;
  const CustomListsEditor({super.key, required this.type});

  @override
  State<CustomListsEditor> createState() => _CustomListsEditorState();
}

class _CustomListsEditorState extends State<CustomListsEditor> {
  late List<CustomListData> _lists;
  bool _isReordering = false;

  final offlineStorage = Get.find<OfflineStorageController>();

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  void _loadLists() {
    _lists = offlineStorage.getEditableCustomListData(mediaType: widget.type);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _saveListData() {
    offlineStorage.applyCustomListChanges(_lists, mediaType: widget.type);
    _loadLists();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Custom Lists',
      headerSubtitle: '${_lists.length} lists total',
      headerAction: IconButton(
        onPressed: () {
          setState(() {
            _isReordering = !_isReordering;
          });
          HapticFeedback.lightImpact();
        },
        icon: Icon(
          _isReordering ? Icons.check_rounded : Icons.swap_vert_rounded,
          color: _isReordering
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
        ),
      ),
      body: Builder(
        builder: (ctx) {
          final headerHeight = AnymeXHeaderScope.of(ctx);
          return Column(
            children: [
              SizedBox(height: headerHeight),
              Expanded(
                child: _buildContent(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildListsFAB(),
    );
  }

  Stream<List<OfflineMedia>> _historyStream() {
    if (widget.type == ItemType.anime) {
      return offlineStorage.watchAnimeLibrary().map((items) => items
          .where((e) =>
              e.currentEpisode?.currentTrack != null ||
              (e.watchedEpisodes != null && e.watchedEpisodes!.isNotEmpty))
          .toList());
    }
    if (widget.type == ItemType.manga) {
      return offlineStorage.watchMangaLibrary().map((items) => items
          .where((e) =>
              e.currentChapter?.link != null ||
              (e.readChapters != null && e.readChapters!.isNotEmpty))
          .toList());
    }
    return offlineStorage.watchNovelLibrary().map((items) => items
        .where((e) =>
            e.currentChapter?.link != null ||
            (e.readChapters != null && e.readChapters!.isNotEmpty))
        .toList());
  }

  void _confirmClearHistory(List<OfflineMedia> items) {
    final isAnime = widget.type == ItemType.anime;
    final label = isAnime ? 'watch history' : 'read history';

    AnymeXDialog(
      title: 'Clear History',
      contentWidget: AnymeXText(
        'Are you sure you want to clear all $label? This action cannot be undone.',
        size: 14,
      ),
      confirmText: 'Clear All',
      onConfirm: () async {
        final ids = items
            .map((e) => e.mediaId)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toList();
        final count = await offlineStorage.clearMediaHistoryBulk(
          ids,
          mediaType: widget.type,
        );
        snackBar(count > 0 ? 'History cleared' : 'No history to clear');
      },
    ).show(context);
  }

  Widget _buildHistoryCard(ThemeData theme) {
    final isAnime = widget.type == ItemType.anime;
    final historyTitle = isAnime ? 'Watch History' : 'Read History';

    return StreamBuilder<List<OfflineMedia>>(
      stream: _historyStream(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.opaque(0.08, iReallyMeanIt: true),
                width: 1.0,
              ),
            ),
            child: InkWell(
              onTap: () => navigate(() => HistoryEditor(type: widget.type)),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymeXText(
                            historyTitle,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnymeXText(
                            '${items.length} ${items.length == 1 ? 'item' : 'items'} in history',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.opaque(0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (items.isNotEmpty)
                      IconButton(
                        onPressed: () => _confirmClearHistory(items),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        tooltip: 'Clear History',
                      ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.colorScheme.onSurface.opaque(0.4),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHistoryCard(theme),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnymeXText(
                'Custom Lists',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
              ),
              AnymeXText(
                '${_lists.length} lists',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.opaque(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _lists.isEmpty
              ? _buildEmptyListsState()
              : ReorderableListView.builder(
                  onReorder: _isReordering ? _onReorder : (a, b) {},
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: _lists.length,
                  buildDefaultDragHandles: false,
                  itemBuilder: (context, index) {
                    return _buildListCard(index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildListCard(int index) {
    final theme = Theme.of(context);
    final listData = _lists[index];

    return Container(
      key: ValueKey('list_$index'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.opaque(0.08, iReallyMeanIt: true),
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _openMediaEditorBottomSheet(context, index),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_isReordering) ...[
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: theme.colorScheme.onSurface.opaque(0.4),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              _buildCoverPreview(listData),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymeXText(
                      listData.listName,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnymeXText(
                      '${listData.listData.length} items',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.opaque(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isReordering) ...[
                IconButton(
                  onPressed: () => _showRenameDialog(index),
                  icon: Icon(
                    Iconsax.edit,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        theme.colorScheme.primary.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showDeleteDialog(index),
                  icon: Icon(Iconsax.trash,
                      color: theme.colorScheme.error, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.error.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPreview(CustomListData listData) {
    final theme = Theme.of(context);
    if (listData.listData.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.playlist_play_rounded,
          color: theme.colorScheme.primary,
          size: 28,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AnymeXImage(
        width: 50,
        height: 50,
        imageUrl: listData.listData.first.poster ?? '',
      ),
    );
  }

  Widget _buildEmptyListsState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.playlist_add_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.opaque(0.4),
            ),
          ),
          const SizedBox(height: 24),
          AnymeXText(
            'No custom lists yet',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          AnymeXText(
            'Create your first custom list to organize\nyour favorite content',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.opaque(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListsFAB() {
    final theme = Theme.of(context);
    return FloatingActionButton.extended(
      onPressed: _showCreateListDialog,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      icon: const Icon(Icons.add_rounded),
      label: AnymeXText(
        'New List',
        style: TextStyle(
            fontWeight: FontWeight.w600, color: theme.colorScheme.onPrimary),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _lists.removeAt(oldIndex);
      _lists.insert(newIndex, item);
    });
    _saveListData();
    HapticFeedback.mediumImpact();
  }

  void _openMediaEditorBottomSheet(BuildContext context, int listIndex) {
    AnymeXSheet.custom(
      _ListMediaEditorBottomSheet(
        listData: _lists[listIndex],
        type: widget.type,
        onListChanged: () {
          setState(() {
            _saveListData();
          });
        },
      ),
      context,
      showDragHandle: true,
    );
  }

  void _showRenameDialog(int index) {
    final controller = TextEditingController(text: _lists[index].listName);
    final theme = Theme.of(context);

    AnymeXDialog(
      title: 'Rename List',
      contentWidget: TextField(
        controller: controller,
        style: TextStyle(color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Enter list name',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.opaque(0.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.opaque(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainer.withOpacity(0.3),
        ),
      ),
      confirmText: 'Rename',
      onConfirm: () {
        if (controller.text.isNotEmpty &&
            controller.text != _lists[index].listName) {
          if (_lists.any((list) => list.listName == controller.text)) {
            snackBar('List name already exists');
            return;
          }

          setState(() {
            _lists[index].listName = controller.text;
          });
          _saveListData();
          HapticFeedback.lightImpact();
        }
      },
    ).show(context);
  }

  void _showDeleteDialog(int index) {
    AnymeXDialog(
      title: 'Delete List',
      message:
          'Are you sure you want to delete "${_lists[index].listName}"? This action cannot be undone.',
      confirmText: 'Delete',
      onConfirm: () {
        setState(() {
          _lists.removeAt(index);
          _saveListData();
        });
        HapticFeedback.mediumImpact();
      },
    ).show(context);
  }

  void _showCreateListDialog() {
    final controller = TextEditingController();
    final theme = Theme.of(context);

    AnymeXDialog(
      title: 'Create New List',
      contentWidget: TextField(
        controller: controller,
        style: TextStyle(color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Enter list name',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.opaque(0.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.opaque(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainer.withOpacity(0.3),
        ),
      ),
      confirmText: 'Create',
      onConfirm: () {
        if (controller.text.isNotEmpty) {
          if (_lists.any((list) => list.listName == controller.text)) {
            snackBar('List name already exists');
            return;
          }

          setState(() {
            _lists.add(CustomListData(
              listName: controller.text,
              listData: [],
            ));
          });
          _saveListData();
          HapticFeedback.lightImpact();
        }
      },
    ).show(context);
  }
}

class _ListMediaEditorBottomSheet extends StatefulWidget {
  final CustomListData listData;
  final ItemType type;
  final VoidCallback onListChanged;

  const _ListMediaEditorBottomSheet({
    required this.listData,
    required this.type,
    required this.onListChanged,
  });

  @override
  State<_ListMediaEditorBottomSheet> createState() =>
      __ListMediaEditorBottomSheetState();
}

class __ListMediaEditorBottomSheetState
    extends State<_ListMediaEditorBottomSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<int> _selectedItemIndices = {};
  bool _isMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _removeSingleMediaItem(int itemIndex) {
    final itemName = widget.listData.listData[itemIndex].name ?? 'Item';
    setState(() {
      widget.listData.listData.removeAt(itemIndex);
    });
    widget.onListChanged();
    HapticFeedback.lightImpact();
    snackBar('Removed "$itemName"');
  }

  void _deleteSelectedItems() {
    AnymeXDialog(
      title: 'Remove Items',
      message:
          'Are you sure you want to remove the ${_selectedItemIndices.length} selected items from "${widget.listData.listName}"?',
      confirmText: 'Remove',
      onConfirm: () {
        final sortedIndices = _selectedItemIndices.toList()
          ..sort((a, b) => b.compareTo(a));

        setState(() {
          for (final idx in sortedIndices) {
            widget.listData.listData.removeAt(idx);
          }
          _selectedItemIndices.clear();
          _isMultiSelectMode = false;
        });
        widget.onListChanged();
        HapticFeedback.mediumImpact();
        snackBar('Selected items removed');
      },
    ).show(context);
  }

  Widget _buildCheckmark(BuildContext context, bool isSelected) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              isSelected ? colors.primary : colors.onSurface.withOpacity(0.24),
          width: 2,
        ),
        color: isSelected ? colors.primary : Colors.transparent,
      ),
      child: isSelected
          ? Icon(
              Icons.check_rounded,
              size: 14,
              color: colors.onPrimary,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final allItems = widget.listData.listData;

    final filteredItems = allItems.asMap().entries.where((entry) {
      if (_searchQuery.isEmpty) return true;
      final name = (entry.value.name ?? '').toLowerCase();
      final jname = (entry.value.jname ?? '').toLowerCase();
      return name.contains(_searchQuery) || jname.contains(_searchQuery);
    }).toList();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Stack(
        children: [
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymeXText(
                          widget.listData.listName,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        AnymeXText(
                          '${allItems.length} items total',
                          style: TextStyle(
                            color: colors.onSurface.withOpacity(0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: colors.onSurface),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surfaceContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer.withOpacity(0.4),
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(12),
                                right: Radius.circular(5)),
                        border:
                            Border.all(color: colors.outline.withOpacity(0.1)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(Iconsax.search_normal_1,
                              color: colors.onSurface.withOpacity(0.5),
                              size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search items in list...',
                                hintStyle: TextStyle(
                                  color: colors.onSurface.withOpacity(0.4),
                                  fontSize: 14,
                                ),
                                filled: false,
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () => _searchController.clear(),
                              child: Icon(Icons.close_rounded,
                                  color: colors.onSurface.withOpacity(0.6),
                                  size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  InkWell(
                      onTap: () {
                        setState(() {
                          _isMultiSelectMode = !_isMultiSelectMode;
                          _selectedItemIndices.clear();
                        });
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                                                    border:
                            Border.all(color: colors.outline.withOpacity(0.1)),
                            color: colors.surfaceContainer.withOpacity(0.4),
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(12),
                                left: Radius.circular(5)),
                          ),
                          child: Center(
                              child: _buildCheckmark(
                                  context, _isMultiSelectMode)))),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredItems.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 80),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final entry = filteredItems[index];
                          final itemIndex = entry.key;
                          final media = entry.value;
                          final isSelected =
                              _selectedItemIndices.contains(itemIndex);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.primary.withOpacity(0.08)
                                  : colors.surfaceContainer.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? colors.primary.withOpacity(0.4)
                                    : colors.outline.withOpacity(0.1),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onLongPress: () {
                                if (!_isMultiSelectMode) {
                                  setState(() {
                                    _isMultiSelectMode = true;
                                    _selectedItemIndices.add(itemIndex);
                                  });
                                  HapticFeedback.mediumImpact();
                                }
                              },
                              onTap: () {
                                if (_isMultiSelectMode) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedItemIndices.remove(itemIndex);
                                    } else {
                                      _selectedItemIndices.add(itemIndex);
                                    }
                                  });
                                  HapticFeedback.selectionClick();
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    if (_isMultiSelectMode) ...[
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedItemIndices
                                                  .remove(itemIndex);
                                            } else {
                                              _selectedItemIndices
                                                  .add(itemIndex);
                                            }
                                          });
                                        },
                                        child: _buildCheckmark(
                                            context, isSelected),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: AnymeXImage(
                                        width: 40,
                                        height: 55,
                                        imageUrl:
                                            media.poster ?? media.cover ?? '',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AnymeXText(
                                            media.name ??
                                                media.jname ??
                                                'Unknown Title',
                                            style: TextStyle(
                                              color: colors.onSurface,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (media.type != null) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: colors.primary
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: AnymeXText(
                                                media.type!.toUpperCase(),
                                                style: TextStyle(
                                                  color: colors.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (!_isMultiSelectMode)
                                      IconButton(
                                        onPressed: () =>
                                            _removeSingleMediaItem(itemIndex),
                                        icon: Icon(Icons.close_rounded,
                                            color: colors.error, size: 18),
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              colors.error.withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
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
            ],
          ),
          if (_isMultiSelectMode)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer.withOpacity(0.85),
                      border:
                          Border.all(color: colors.outline.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: AnymeXText(
                            '${_selectedItemIndices.length} selected',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedItemIndices.length ==
                                  allItems.length) {
                                _selectedItemIndices.clear();
                              } else {
                                _selectedItemIndices.addAll(List.generate(
                                    allItems.length, (index) => index));
                              }
                            });
                          },
                          child: AnymeXText(
                            _selectedItemIndices.length == allItems.length
                                ? 'Deselect All'
                                : 'Select All',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _selectedItemIndices.isNotEmpty
                              ? _deleteSelectedItems
                              : null,
                          icon: Icon(Iconsax.trash,
                              color: colors.onError, size: 16),
                          label: AnymeXText(
                            'Remove',
                            style: TextStyle(
                              color: colors.onError,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedItemIndices.isNotEmpty
                                ? colors.error
                                : colors.error.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.folder_open5,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          AnymeXText(
            _searchQuery.isNotEmpty ? 'No matches found' : 'This list is empty',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          AnymeXText(
            _searchQuery.isNotEmpty
                ? 'Try checking spelling or using different keywords'
                : 'Browse media in the library and add them to this list',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
