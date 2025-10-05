import 'dart:io';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:dartotsu_extension_bridge/ExtensionManager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RepoBottomSheet extends StatefulWidget {
  final Function() onSave;

  const RepoBottomSheet({
    super.key,
    required this.onSave,
  });

  @override
  State<RepoBottomSheet> createState() => _RepoBottomSheetState();

  static void show(BuildContext context, {required Function() onSave}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => RepoBottomSheet(onSave: onSave),
    );
  }
}

class _RepoBottomSheetState extends State<RepoBottomSheet> {
  final controller = Get.find<SourceController>();
  late final bool isAndroid;

  late final TextEditingController animeRepoController;
  late final TextEditingController mangaRepoController;
  late final TextEditingController novelRepoController;

  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    isAndroid = Platform.isAndroid;

    final type = isAndroid && selectedTab == 1
        ? ExtensionType.aniyomi
        : ExtensionType.mangayomi;

    animeRepoController = TextEditingController(
      text: controller.getAnimeRepo(type),
    );
    mangaRepoController = TextEditingController(
      text: controller.getMangaRepo(type),
    );
    novelRepoController = TextEditingController(
      text: controller.activeNovelRepo,
    );
  }

  @override
  void dispose() {
    animeRepoController.dispose();
    mangaRepoController.dispose();
    novelRepoController.dispose();
    super.dispose();
  }

  void onTabChanged(int index) {
    setState(() {
      selectedTab = index;

      final type = isAndroid && selectedTab == 1
          ? ExtensionType.aniyomi
          : ExtensionType.mangayomi;

      animeRepoController.text = controller.getAnimeRepo(type);
      mangaRepoController.text = controller.getMangaRepo(type);
    });
  }

  Future<void> handleSave() async {
    final type = isAndroid && selectedTab == 1
        ? ExtensionType.aniyomi
        : ExtensionType.mangayomi;

    print('${type.name} - ${animeRepoController.text}');

    controller.setAnimeRepo(animeRepoController.text, type);
    controller.setMangaRepo(mangaRepoController.text, type);

    if (selectedTab == 0) {
      controller.activeNovelRepo = novelRepoController.text;
    }

    Navigator.of(context).pop();
    await widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 3,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "Repository Settings",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 24),
              if (isAndroid)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onTabChanged(0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedTab == 0
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: selectedTab == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              "Mangayomi",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: selectedTab == 0
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: selectedTab == 0
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onTabChanged(1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedTab == 1
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: selectedTab == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              "Aniyomi",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: selectedTab == 1
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: selectedTab == 1
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Third-party repositories are not officially supported",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (selectedTab == 0) ...[
                _buildRepoField(
                  context,
                  "Anime Repository",
                  animeRepoController,
                  Icons.play_circle_outline,
                  "Enter anime repository URL",
                ),
                const SizedBox(height: 16),
                _buildRepoField(
                  context,
                  "Manga Repository",
                  mangaRepoController,
                  Icons.book_outlined,
                  "Enter manga repository URL",
                ),
                const SizedBox(height: 16),
                _buildRepoField(
                  context,
                  "Novel Repository",
                  novelRepoController,
                  Icons.menu_book_outlined,
                  "Enter novel repository URL",
                ),
              ] else ...[
                _buildRepoField(
                  context,
                  "Anime Repository",
                  animeRepoController,
                  Icons.play_circle_outline,
                  "Enter anime repository URL",
                ),
                const SizedBox(height: 16),
                _buildRepoField(
                  context,
                  "Manga Repository",
                  mangaRepoController,
                  Icons.book_outlined,
                  "Enter manga repository URL",
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepoField(
    BuildContext context,
    String label,
    TextEditingController controller,
    IconData icon,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
