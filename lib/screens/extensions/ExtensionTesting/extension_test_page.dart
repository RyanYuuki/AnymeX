import 'dart:io';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'extension_test_controller.dart';

class ExtensionTestPage extends StatefulWidget {
  const ExtensionTestPage({super.key});

  @override
  State<ExtensionTestPage> createState() => _ExtensionTestPageState();
}

class _ExtensionTestPageState extends State<ExtensionTestPage> {
  late ExtensionTestController controller;
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ExtensionTestController());
    searchController =
        TextEditingController(text: controller.searchQuery.value);
  }

  @override
  void dispose() {
    searchController.dispose();
    Get.delete<ExtensionTestController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final sourceController = Get.find<SourceController>();

    return Glow(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestedHeader(title: 'Extension Testing'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExtensionTypeSection(theme),
                    const SizedBox(height: 20),
                    _buildTestTypeSection(theme),
                    const SizedBox(height: 20),
                    _buildSearchQuerySection(theme),
                    const SizedBox(height: 20),
                    _buildExtensionsSection(theme, sourceController),
                    const SizedBox(height: 24),
                    _buildStartButton(theme),
                    const SizedBox(height: 32),
                    _buildTestResults(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtensionTypeSection(ColorScheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Extension Type',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: theme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    'Anime',
                    ItemType.anime,
                    controller.extensionType.value == ItemType.anime,
                    theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTypeButton(
                    'Manga',
                    ItemType.manga,
                    controller.extensionType.value == ItemType.manga,
                    theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTypeButton(
                    'Novel',
                    ItemType.novel,
                    controller.extensionType.value == ItemType.novel,
                    theme,
                  ),
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildTypeButton(
      String label, ItemType type, bool isSelected, ColorScheme theme) {
    return GestureDetector(
      onTap: () {
        controller.extensionType.value = type;
        controller.selectedExtensions.clear();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primary.withValues(alpha: 0.3)
              : theme.surfaceContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.primary.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isSelected ? theme.primary : theme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestTypeSection(ColorScheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Type',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: theme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => Row(
              children: [
                Expanded(
                  child: _buildTestButton('Ping', 'ping', theme),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTestButton('Basic', 'basic', theme),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTestButton('Full', 'full', theme),
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildTestButton(String label, String type, ColorScheme theme) {
    final isSelected = controller.testType.value == type;
    return GestureDetector(
      onTap: () => controller.testType.value = type,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primary.withValues(alpha: 0.3)
              : theme.surfaceContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.primary.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isSelected ? theme.primary : theme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchQuerySection(ColorScheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Query',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: theme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.surfaceContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: searchController,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: theme.onSurface,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.surfaceContainer.withValues(alpha: 0.2),
              hintText: 'Enter search query',
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                color: theme.onSurface.withValues(alpha: 0.4),
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (value) => controller.searchQuery.value = value,
          ),
        ),
      ],
    );
  }

  Widget _buildExtensionsSection(
      ColorScheme theme, SourceController sourceController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Extensions',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: theme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final extensions = _getInstalledExtensions(sourceController);
          if (extensions.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.surfaceContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No extensions installed',
                  style: TextStyle(
                    color: theme.onSurface.withValues(alpha: 0.6),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            );
          }
          return Container(
            decoration: BoxDecoration(
              color: theme.surfaceContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: extensions.map((source) {
                return Obx(() => _buildExtensionTile(source, theme));
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExtensionTile(Source source, ColorScheme theme) {
    final isSelected = controller.selectedExtensions.contains(source.name);
    return InkWell(
      onTap: () => controller.toggleExtension(source.name ?? '', !isSelected),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            _buildExtensionIcon(source, theme),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                source.name ?? 'Unknown',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: theme.onSurface,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? theme.primary.withValues(alpha: 0.3)
                    : theme.surfaceContainer.withValues(alpha: 0.3),
                border: Border.all(
                  color: isSelected
                      ? theme.primary
                      : theme.outline.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: theme.primary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtensionIcon(Source source, ColorScheme theme) {
    if (source.iconUrl == null || source.iconUrl!.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.extension, color: theme.primary, size: 24),
      );
    }

    if (source.iconUrl!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          source.iconUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.extension, color: theme.primary, size: 24),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(source.iconUrl!),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.extension, color: theme.primary, size: 24),
        ),
      ),
    );
  }

  Widget _buildStartButton(ColorScheme theme) {
    return Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.selectedExtensions.isEmpty
                ? null
                : () => controller.startTests(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary.withValues(alpha: 0.3),
              foregroundColor: theme.primary,
              disabledBackgroundColor:
                  theme.surfaceContainer.withValues(alpha: 0.2),
              disabledForegroundColor: theme.onSurface.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Start Test',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ));
  }

  Widget _buildTestResults(ColorScheme theme) {
    return Obx(() {
      if (controller.testResults.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: theme.surfaceContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 48,
                  color: theme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No tests running',
                  style: TextStyle(
                    color: theme.onSurface.withValues(alpha: 0.6),
                    fontFamily: 'Poppins',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Results',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...controller.testResults.map((result) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: result,
              )),
        ],
      );
    });
  }

  List<Source> _getInstalledExtensions(SourceController sourceController) {
    switch (controller.extensionType.value) {
      case ItemType.anime:
        return sourceController.installedExtensions;
      case ItemType.manga:
        return sourceController.installedMangaExtensions;
      case ItemType.novel:
        return sourceController.installedNovelExtensions;
    }
  }
}
