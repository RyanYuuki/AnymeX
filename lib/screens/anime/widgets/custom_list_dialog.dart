import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/custom_list.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class CustomListDialog extends StatefulWidget {
  final Media original;
  final List<CustomList> customLists;
  final ItemType type;

  const CustomListDialog({
    super.key,
    required this.original,
    required this.customLists,
    required this.type,
  });

  @override
  State<CustomListDialog> createState() => _CustomListDialogState();
}

class _CustomListDialogState extends State<CustomListDialog> {
  late List<CustomList> modifiedLists;
  late Map<String, bool> initialState;
  final storage = Get.find<OfflineStorageController>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    modifiedLists = widget.customLists;

    initialState = {
      for (var list in widget.customLists)
        list.listName ?? '':
            list.mediaIds?.contains(widget.original.id) ?? false
    };

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final TextEditingController textController = TextEditingController();
    bool isButtonEnabled = false;

    String? newListName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Collection',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {
                        isButtonEnabled = value.trim().isNotEmpty;
                      });
                    },
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: isButtonEnabled
                            ? () => Navigator.of(context)
                                .pop(textController.text.trim())
                            : null,
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    if (newListName != null && newListName.isNotEmpty) {
      setState(() {
        storage.addCustomList(newListName, mediaType: widget.type);
        initialState[newListName] = false;
        modifiedLists = widget.customLists
            .map((list) => CustomList(
                  listName: list.listName,
                  mediaIds: List<String>.from(list.mediaIds ?? []),
                ))
            .toList();
      });
    }
  }

  void _handleOkPress() {
    for (var list in modifiedLists) {
      final listName = list.listName ?? '';
      final wasChecked = initialState[listName] ?? false;
      final isCheckedNow = list.mediaIds?.contains(widget.original.id) ?? false;

      if (wasChecked != isCheckedNow) {
        if (isCheckedNow) {
          storage.addMedia(listName, widget.original, widget.type);
        } else {
          storage.removeMedia(listName, widget.original.id, widget.type);
        }
      }
    }

    Navigator.of(context).pop();
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Collections',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon:
                        Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            if (modifiedLists.length > 3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CustomSearchBar(
                  padding: const EdgeInsets.all(0),
                  disableIcons: true,
                  onSubmitted: (_) {},
                  controller: _searchController,
                  focusNode: _searchFocus,
                ),
              ),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                  minHeight: 100,
                ),
                margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: filteredLists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off_outlined
                                  : Icons.playlist_add_outlined,
                              size: 48,
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.5),
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
                      )
                    : SuperListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredLists.length,
                        itemBuilder: (context, index) {
                          final list = filteredLists[index];
                          final listName = list.listName ?? 'Unnamed List';
                          final isChecked =
                              list.mediaIds?.contains(widget.original.id) ??
                                  false;
                          final itemCount = list.mediaIds?.length ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isChecked
                                  ? colorScheme.primaryContainer
                                      .withOpacity(0.3)
                                  : colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isChecked
                                    ? colorScheme.primary.withOpacity(0.5)
                                    : colorScheme.outline.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    _handleCheckboxChanged(!isChecked, list),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: isChecked
                                              ? colorScheme.primary
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isChecked
                                                ? colorScheme.primary
                                                : colorScheme.outline,
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: isChecked
                                            ? Icon(
                                                Icons.check,
                                                size: 14,
                                                color: colorScheme.onPrimary,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              listName,
                                              style:
                                                  textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: isChecked
                                                    ? colorScheme.primary
                                                    : colorScheme.onSurface,
                                              ),
                                            ),
                                            if (itemCount > 0)
                                              Text(
                                                '$itemCount items',
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (isChecked)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Added',
                                            style:
                                                textTheme.labelSmall?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
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
                        color: colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          child: Text(
                            'Cancel',
                            style:
                                TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _handleOkPress,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showCustomListDialog(
    BuildContext context, Media media, List<CustomList> lists, ItemType type) {
  showDialog(
    context: context,
    builder: (context) => CustomListDialog(
      original: media,
      customLists: lists,
      type: type,
    ),
  );
}
