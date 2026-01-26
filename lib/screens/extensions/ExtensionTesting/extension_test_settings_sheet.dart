import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'extension_test_controller.dart';

class ExtensionTestSettingsSheet extends StatefulWidget {
  final ExtensionTestController controller;

  const ExtensionTestSettingsSheet({
    super.key,
    required this.controller,
  });

  @override
  State<ExtensionTestSettingsSheet> createState() =>
      _ExtensionTestSettingsSheetState();
}

class _ExtensionTestSettingsSheetState
    extends State<ExtensionTestSettingsSheet> {
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController =
        TextEditingController(text: widget.controller.searchQuery.value);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    final sourceController = Get.find<SourceController>();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Test Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Extension Type Radio Group
            Text(
              'Extension Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Center(
              child: ToggleButtons(
                isSelected: [
                  widget.controller.extensionType.value == ItemType.anime,
                  widget.controller.extensionType.value == ItemType.manga,
                  widget.controller.extensionType.value == ItemType.novel,
                ],
                onPressed: (index) {
                  ItemType selectedType;
                  if (index == 0) {
                    selectedType = ItemType.anime;
                  } else if (index == 1) {
                    selectedType = ItemType.manga;
                  } else {
                    selectedType = ItemType.novel;
                  }
                  widget.controller.extensionType.value = selectedType;
                  widget.controller.selectedExtensions.clear();
                },
                borderRadius: BorderRadius.circular(8),
                selectedColor: theme.onPrimary,
                color: theme.primary,
                fillColor: theme.primary,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Anime'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Manga'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Novel'),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            // Test Type Radio Group
            Text(
              'Test Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Center(
              child: ToggleButtons(
                isSelected: [
                  widget.controller.testType.value == 'ping',
                  widget.controller.testType.value == 'basic',
                  widget.controller.testType.value == 'full',
                ],
                onPressed: (index) {
                  String selectedType;
                  if (index == 0) {
                    selectedType = 'ping';
                  } else if (index == 1) {
                    selectedType = 'basic';
                  } else {
                    selectedType = 'full';
                  }
                  widget.controller.testType.value = selectedType;
                },
                borderRadius: BorderRadius.circular(8),
                selectedColor: theme.onPrimary,
                color: theme.primary,
                fillColor: theme.primary,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Ping'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Basic'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Full'),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            // Search Query Input
            Text(
              'Search Query',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Enter search query',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                widget.controller.searchQuery.value = value;
              },
            ),
            const SizedBox(height: 16),
            // Extensions List
            Text(
              'Select Extensions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final extensions = _getInstalledExtensions(sourceController);
              if (extensions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No extensions installed',
                    style: TextStyle(
                      color: theme.onSurfaceVariant,
                      fontFamily: 'Poppins',
                    ),
                  ),
                );
              }
              return Column(
                children: extensions.map((source) {
                  return Obx(() => CheckboxListTile(
                    title: Text(
                      source.name ?? 'Unknown',
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                    value: widget.controller.selectedExtensions
                        .contains(source.name),
                    onChanged: (isChecked) {
                      widget.controller.toggleExtension(
                        source.name ?? '',
                        isChecked ?? false,
                      );
                    },
                    secondary: _buildExtensionIcon(source),
                  ));
                }).toList(),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.onPrimary,
              ),
              child: const Text('Done'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExtensionIcon(Source source) {
    if (source.iconUrl == null || source.iconUrl!.isEmpty) {
      return Icon(
        Icons.extension,
        size: 32,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    if (source.iconUrl!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          source.iconUrl!,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.extension,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.file(
        File(source.iconUrl!),
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.extension,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  List<Source> _getInstalledExtensions(SourceController sourceController) {
    switch (widget.controller.extensionType.value) {
      case ItemType.anime:
        return sourceController.installedExtensions;
      case ItemType.manga:
        return sourceController.installedMangaExtensions;
      case ItemType.novel:
        return sourceController.installedNovelExtensions;
    }
  }
}