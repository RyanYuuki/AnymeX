import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/main.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';

import '../../../database/isar_models/custom_list.dart';

class CustomListDialog extends StatefulWidget {
  final Media original;

  const CustomListDialog({
    super.key,
    required this.original,
  });

  @override
  State<CustomListDialog> createState() => _CustomListDialogState();
}

class _CustomListDialogState extends State<CustomListDialog> {
  late List<CustomList> modifiedLists;
  late Map<String, bool> initialState;
  final storage = Get.find<OfflineStorageController>();
  final TextEditingController _searchController = TextEditingController();
  late List<CustomList> customList;
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _init();
  }

  bool _isItemInList(CustomList list) {
    final targetId = widget.original.id;
    if (targetId.isEmpty) return false;
    return list.mediaIds?.contains(targetId) ?? false;
  }

  void _init() {
    final raw = isar.customLists
        .filter()
        .mediaTypeIndexEqualTo(widget.original.mediaType.index)
        .findAllSync();

    customList = raw
        .map((l) => CustomList(
              listName: l.listName,
              mediaIds: List<String>.from(l.mediaIds ?? []),
              mediaTypeIndex: l.mediaTypeIndex,
            )..id = l.id)
        .toList();

    modifiedLists = customList;

    initialState = {
      for (var list in modifiedLists)
        list.listName ?? '': _isItemInList(list)
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _handleCheckboxChanged(bool? checked, CustomList list) {
    setState(() {
      if (checked ?? false) {
        if (!list.mediaIds!.contains(widget.original.id)) {
          list.mediaIds!.add(widget.original.id);
        }
      } else {
        list.mediaIds!.remove(widget.original.id);
      }
    });
  }

  Future<void> _showCreateListDialog() async {
    final TextEditingController textController = TextEditingController();

    String? newListName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AnymeXDialog(
            title: 'New Collection',
            confirmText: 'Create',
            onConfirm: () {},
            confirmResultGetter: () => textController.text.trim(),
            showCancelButton: true,
            contentWidget: TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Collection name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          );
        });
      },
    );

    if (newListName != null && newListName.isNotEmpty) {
      await storage.addCustomList(newListName,
          mediaType: widget.original.mediaType);

      setState(() {
        _init();
      });
    }
  }

  Future<void> _handleOkPress() async {
    for (var list in modifiedLists) {
      final listName = list.listName ?? '';
      final wasChecked = initialState[listName] ?? false;
      final isCheckedNow = list.mediaIds?.contains(widget.original.id) ?? false;

      if (wasChecked != isCheckedNow) {
        if (isCheckedNow) {
          await storage.addMedia(listName, widget.original);
        } else {
          await storage.removeMedia(listName, widget.original);
        }
      }
    }
  }

  List<CustomList> get filteredLists {
    if (_searchQuery.isEmpty) {
      return modifiedLists;
    }
    return modifiedLists
        .where((list) =>
            (list.listName?.toLowerCase() ?? '').contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return AnymeXDialog(
      title: 'Collections',
      confirmText: 'Save',
      onConfirm: _handleOkPress,
      showCancelButton: true,
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (modifiedLists.length > 3) ...[
            CustomSearchBar(
              padding: const EdgeInsets.all(0),
              disableIcons: true,
              onSubmitted: (_) {},
              controller: _searchController,
              focusNode: _searchFocus,
            ),
            const SizedBox(height: 16),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.4,
              minHeight: 80,
            ),
            child: filteredLists.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off_outlined
                                : Icons.playlist_add_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant.opaque(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No collections found'
                                : 'No collections yet',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: AnymeXSectionBuilder(
                      margin: EdgeInsets.zero,
                      children: filteredLists.map((list) {
                        final listName = list.listName ?? 'Unnamed List';
                        final isChecked = _isItemInList(list);
                        final itemCount = list.mediaIds?.length ?? 0;

                        return AnymeXTile.checkbox(
                          title: listName,
                          subtitle: itemCount > 0 ? '$itemCount items' : 'No items',
                          value: isChecked,
                          onChanged: (val) {
                            _handleCheckboxChanged(val, list);
                          },
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _showCreateListDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Collection'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: colorScheme.outline.opaque(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showCustomListDialog(BuildContext context, Media media) {
  showDialog(
    context: context,
    builder: (context) => CustomListDialog(
      original: media,
    ),
  );
}
