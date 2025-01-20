import 'package:anymex/api/Mangayomi/Model/Manga.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/custom_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomListDialog extends StatefulWidget {
  final Media original;
  final List<CustomList> customLists;
  final bool isManga;

  const CustomListDialog({
    super.key,
    required this.original,
    required this.customLists,
    required this.isManga,
  });

  @override
  _CustomListDialogState createState() => _CustomListDialogState();
}

class _CustomListDialogState extends State<CustomListDialog> {
  late List<CustomList> modifiedLists;
  late Map<String, bool> initialState;
  final storage = Get.find<OfflineStorageController>();

  @override
  void initState() {
    super.initState();
    modifiedLists = widget.customLists;

    initialState = {
      for (var list in widget.customLists)
        list.listName ?? '':
            list.mediaIds?.contains(widget.original.id) ?? false
    };
  }

  void _handleCheckboxChanged(bool? checked, int index) {
    setState(() {
      if (checked ?? false) {
        if (!modifiedLists[index].mediaIds!.contains(widget.original.id)) {
          modifiedLists[index].mediaIds!.add(widget.original.id);
        }
      } else {
        modifiedLists[index].mediaIds!.remove(widget.original.id);
      }
    });
  }

  Future<void> _showCreateListDialog() async {
    String? newListName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String tempListName = '';
        return AlertDialog(
          title: const Text('Create New List'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'List Name',
              hintText: 'Enter list name',
            ),
            onChanged: (value) => tempListName = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(tempListName),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (newListName != null && newListName.isNotEmpty) {
      setState(() {
        storage.addCustomList(newListName,
            mediaType: widget.isManga ? ItemType.manga : ItemType.anime);
        initialState[newListName] = false;
        modifiedLists = widget.customLists
            .map((list) => CustomList(
                  listName: list.listName,
                  mediaIds: List<int>.from(list.mediaIds ?? []),
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
          storage.addMedia(listName, widget.original, widget.isManga);
        } else {
          storage.removeMedia(listName, widget.original.id, widget.isManga);
        }
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to List'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: modifiedLists.length,
                itemBuilder: (context, index) {
                  final list = modifiedLists[index];
                  final isChecked =
                      list.mediaIds?.contains(widget.original.id) ?? false;

                  return CheckboxListTile(
                    title: Text(list.listName ?? 'Unnamed List'),
                    value: isChecked,
                    onChanged: (checked) =>
                        _handleCheckboxChanged(checked, index),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              onTap: _showCreateListDialog,
              leading: const Icon(Icons.add),
              title: const Text('Create New List'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _handleOkPress,
          child: const Text('OK'),
        ),
      ],
    );
  }
}

void showCustomListDialog(BuildContext context, Media media,
    List<CustomList> lists, bool isManga) {
  showDialog(
    context: context,
    builder: (context) => CustomListDialog(
      original: media,
      customLists: lists,
      isManga: isManga,
    ),
  );
}
