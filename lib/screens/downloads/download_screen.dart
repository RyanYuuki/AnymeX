import 'dart:async';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/screens/downloads/controller/download_controller.dart';
import 'package:anymex/screens/downloads/controller/download_search_controller.dart';
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/screens/anime/widgets/episode_range.dart';
import 'package:anymex/screens/manga/widgets/scanlators_ranges.dart';
import 'package:anymex/screens/downloads/nested_screens/active_downloads/active_downloads.dart';
import 'package:anymex/screens/downloads/widgets/download_server_selector.dart';
import 'package:anymex/screens/downloads/widgets/downloaded_media_view.dart';
import 'package:anymex/screens/downloads/widgets/manga_chapter_download_confirm.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:anymex/database/database.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'dart:io';

Widget _buildDynamicTabBar({
  required ColorScheme colors,
  required List<({String label, IconData icon, int type})> tabs,
  required int currentTab,
  required ValueChanged<int> onChanged,
  double height = 54.0,
}) {
  final total = tabs.length;
  final alignX = total > 1 ? -1.0 + (2.0 * currentTab / (total - 1)) : 0.0;

  return LayoutBuilder(builder: (context, constraints) {
    const minTabWidth = 100.0;
    final naturalTabWidth = constraints.maxWidth / total;
    final tabWidth =
        naturalTabWidth < minTabWidth ? minTabWidth : naturalTabWidth;
    final totalWidth = tabWidth * total;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
        child: Container(
          height: height,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(height == 54 ? 20 : 16),
            border: Border.all(color: colors.outline.withOpacity(0.1)),
          ),
          child: Stack(children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              alignment: Alignment(alignX, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / total,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(height == 54 ? 16 : 12),
                    boxShadow: [
                      BoxShadow(
                          color: colors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: tabs.map((t) {
                final selected = currentTab == t.type;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (!selected) {
                        HapticFeedback.lightImpact();
                        onChanged(t.type);
                      }
                    },
                    child: AnimatedScale(
                      scale: selected ? 1.05 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: AnimatedOpacity(
                        opacity: selected ? 1.0 : 0.7,
                        duration: const Duration(milliseconds: 200),
                        child: SizedBox.expand(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(t.icon,
                                  size: height == 54 ? 16 : 14,
                                  color: selected
                                      ? colors.onPrimary
                                      : colors.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Flexible(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: height == 54 ? 13 : 12,
                                    fontFamily: 'Poppins',
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: selected
                                        ? colors.onPrimary
                                        : colors.onSurfaceVariant,
                                  ),
                                  child: Text(t.label,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ]),
        ),
      ),
    );
  });
}

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  int _currentTab = 0;
  int _mediaTypeFilter = 0;
  final searchController = Get.put(DownloadSearchController());

  bool _isPermissionsGranted = false;
  bool _isCheckingPermissions = true;
  bool _hasDownloadDir = false;

  Settings get _settings => Get.find<Settings>();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (mounted) setState(() => _isCheckingPermissions = true);

    if (Platform.isIOS) {
      if (mounted) setState(() {
        _isPermissionsGranted = true;
        _hasDownloadDir = true;
        _isCheckingPermissions = false;
      });
      return;
    }

    bool hasStorage = await Permission.storage.isGranted ||
        await Permission.manageExternalStorage.isGranted ||
        await Permission.videos.isGranted ||
        await Permission.photos.isGranted;

    if (!hasStorage) {
      hasStorage = await Database().requestPermission();
      if (!hasStorage) {
        hasStorage = await Permission.storage.isGranted ||
            await Permission.manageExternalStorage.isGranted ||
            await Permission.videos.isGranted ||
            await Permission.photos.isGranted;
      }
    }

    bool hasNotifications = await Permission.notification.isGranted;
    if (!hasNotifications) {
      hasNotifications = (await Permission.notification.request()).isGranted;
    }

    if (await FlutterForegroundTask.isIgnoringBatteryOptimizations == false) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    final savedPath = _settings.downloadPath.value;
    final dirAlreadySet = savedPath.isNotEmpty && await Directory(savedPath).exists();

    if (mounted) {
      setState(() {
        _isPermissionsGranted = hasStorage && hasNotifications;
        _hasDownloadDir = dirAlreadySet;
        _isCheckingPermissions = false;
      });
    }
  }

  Future<void> _pickDownloadDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null && mounted) {
      _settings.saveDownloadPath(result);
      setState(() => _hasDownloadDir = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            NestedHeader(
              title: 'Downloads',
              action: Container(
                decoration: BoxDecoration(
                  color: theme.primaryContainer.opaque(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => navigate(() => const ActiveDownloads()),
                  icon: Icon(
                    HugeIcons.strokeRoundedDownload04,
                    color: theme.primary,
                  ),
                ),
              ),
            ),
            if (_isCheckingPermissions)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!_isPermissionsGranted)
              Expanded(child: _buildPermissionRoadblock(theme))
            else if (!_hasDownloadDir)
              Expanded(child: _buildDirectoryPickerGate(theme))
            else ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildDynamicTabBar(
                  colors: theme,
                  tabs: const [
                    (
                      label: 'Downloaded Media',
                      icon: HugeIcons.strokeRoundedFolderLibrary,
                      type: 0
                    ),
                    (
                      label: 'New Download',
                      icon: HugeIcons.strokeRoundedAdd01,
                      type: 1
                    ),
                  ],
                  currentTab: _currentTab,
                  onChanged: (v) => setState(() => _currentTab = v),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: IndexedStack(
                  index: _currentTab,
                  children: [
                    _buildMyDownloadsTab(context),
                    _buildNewDownloadTab(context),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDirectoryPickerGate(ColorScheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(HugeIcons.strokeRoundedFolder01, size: 64, color: theme.primary),
            const SizedBox(height: 24),
            const AnymexText(
              text: 'Choose Download Folder',
              variant: TextVariant.bold,
              size: 20,
            ),
            const SizedBox(height: 12),
            AnymexText(
              text: 'Select a folder where AnymeX will save your downloaded anime episodes and manga chapters.',
              textAlign: TextAlign.center,
              color: theme.onSurface.opaque(0.7),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _pickDownloadDirectory,
                icon: const Icon(Icons.folder_open_rounded),
                label: const AnymexText(
                  text: 'Select Folder',
                  variant: TextVariant.semiBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRoadblock(ColorScheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(HugeIcons.strokeRoundedSecurityLock,
                size: 64, color: theme.primary),
            const SizedBox(height: 24),
            const AnymexText(
              text: 'Permissions Required',
              variant: TextVariant.bold,
              size: 20,
            ),
            const SizedBox(height: 12),
            AnymexText(
              text:
                  'Manage device storage and notifications to download and manage your media offline.',
              textAlign: TextAlign.center,
              color: theme.onSurface.opaque(0.7),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _checkPermissions,
                child: const AnymexText(
                    text: 'Grant Permissions', variant: TextVariant.semiBold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyDownloadsTab(BuildContext context) {
    final theme = context.colors;
    final controller = Get.find<DownloadController>();
    return Obx(() {
      final allMedia = controller.downloadedMedia;
      final media = _mediaTypeFilter == 0
          ? allMedia.where((m) => m.mediaType == 'Anime').toList()
          : allMedia.where((m) => m.mediaType == 'Manga').toList();

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDynamicTabBar(
              colors: theme,
              height: 46,
              tabs: const [
                (label: 'Anime', icon: Icons.movie_creation_outlined, type: 0),
                (label: 'Manga', icon: Icons.menu_book_outlined, type: 1),
              ],
              currentTab: _mediaTypeFilter,
              onChanged: (v) => setState(() => _mediaTypeFilter = v),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: media.isEmpty
                ? _buildEmptyState(
                    theme: theme,
                    icon: _mediaTypeFilter == 0
                        ? HugeIcons.strokeRoundedFolderLibrary
                        : HugeIcons.strokeRoundedBookOpen01,
                    message:
                        'No downloaded ${_mediaTypeFilter == 0 ? 'anime' : 'manga'}',
                    subtitle: _mediaTypeFilter == 0
                        ? 'Downloaded episodes will appear here'
                        : 'Downloaded chapters will appear here',
                  )
                : Builder(builder: (ctx) {
                    final screenWidth = MediaQuery.of(ctx).size.width;
                    final crossCount = getResponsiveCrossAxisVal(screenWidth,
                        itemWidth: screenWidth > 600 ? 200 : 150);
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2 / 3,
                      ),
                      itemCount: media.length,
                      itemBuilder: (context, index) {
                        final item = media[index];
                        return _buildMediaCard(
                          context: context,
                          meta: item,
                          onTap: () => navigate(
                              () => DownloadedMediaView(summary: item)),
                        );
                      },
                    );
                  }),
          ),
        ],
      );
    });
  }

  Widget _buildMediaCard({
    required BuildContext context,
    required DownloadedMediaSummary meta,
    required VoidCallback onTap,
  }) {
    final theme = context.colors;
    final isManga = meta.mediaType == 'Manga';
    return AnymexOnTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.surfaceContainer.opaque(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.outline.opaque(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: meta.poster != null && meta.poster!.isNotEmpty
                        ? AnymeXImage(
                            imageUrl: meta.poster!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            radius: 0,
                          )
                        : Container(
                            color: theme.primaryContainer.opaque(0.2),
                            child: Center(
                              child: Icon(
                                  isManga
                                      ? HugeIcons.strokeRoundedBook02
                                      : HugeIcons.strokeRoundedPlay,
                                  size: 40,
                                  color: theme.primary.opaque(0.4)),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymexText(
                      text: meta.title,
                      variant: TextVariant.semiBold,
                      size: 13,
                      maxLines: 2),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.extension_rounded,
                          size: 11, color: theme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AnymexText(
                            text: meta.extensionName,
                            size: 11,
                            color: theme.primary,
                            maxLines: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.primary.opaque(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isManga
                        ? FutureBuilder<DownloadedMangaMeta?>(
                            future: Get.find<DownloadController>().getMangaMeta(
                                meta.extensionName, meta.folderName),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.chapters.length ?? 0;
                              return AnymexText(
                                  text: '$count ch',
                                  size: 11,
                                  color: theme.primary,
                                  variant: TextVariant.semiBold);
                            },
                          )
                        : FutureBuilder<DownloadedMediaMeta?>(
                            future: Get.find<DownloadController>().getMediaMeta(
                                meta.extensionName, meta.folderName),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.episodes.length ?? 0;
                              return AnymexText(
                                  text: '$count eps',
                                  size: 11,
                                  color: theme.primary,
                                  variant: TextVariant.semiBold);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewDownloadTab(BuildContext context) {
    final controller = Get.find<DownloadSearchController>();
    return Obx(() {
      if (controller.step.value == 1) {
        return _buildEpisodeStep(context, controller);
      }

      final theme = context.colors;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDynamicTabBar(
              colors: theme,
              height: 46,
              tabs: const [
                (label: 'Anime', icon: Icons.movie_creation_outlined, type: 0),
                (label: 'Manga', icon: Icons.menu_book_outlined, type: 1),
              ],
              currentTab: controller.mediaType.value,
              onChanged: (v) {
                controller.mediaType.value = v;
                controller.searchResults.clear();
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    onSubmitted: controller.search,
                    style: TextStyle(fontSize: 15, color: theme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search across extensions...',
                      hintStyle: TextStyle(
                          color: theme.onSurface.opaque(0.4), fontSize: 14),
                      filled: true,
                      fillColor: theme.surfaceContainer.opaque(0.3),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: theme.primary, size: 20),
                      suffixIcon: controller.isSearching.value
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: AnymexProgressIndicator()),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnymexOnTap(
                  onTap: () => _showExtensionSelector(context, controller),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.surfaceContainer.opaque(0.3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(HugeIcons.strokeRoundedFilter,
                            color: theme.primary, size: 20),
                        if (controller.disabledSourceIds.isNotEmpty)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: theme.surface, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildSearchResults(context, controller),
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState({
    required ColorScheme theme,
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: theme.onSurface.opaque(0.1)),
          const SizedBox(height: 16),
          AnymexText(
            text: message,
            size: 16,
            variant: TextVariant.semiBold,
            color: theme.onSurface.opaque(0.5),
          ),
          const SizedBox(height: 4),
          AnymexText(
            text: subtitle,
            size: 13,
            color: theme.onSurface.opaque(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
      BuildContext context, DownloadSearchController controller) {
    final theme = context.colors;
    final sources = controller.searchingSources;

    if (sources.isEmpty) {
      if (controller.isSearching.value) {
        return const Center(child: AnymexProgressIndicator());
      }
      return _buildEmptyState(
        theme: theme,
        icon: Icons.search_off_rounded,
        message: 'Search for anime',
        subtitle: 'Results will appear grouped by extension',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        final medias = controller.searchResults[source] ?? [];
        final isLoading = controller.loadingSources.contains(source);

        if (isLoading && medias.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.extension_rounded, size: 16, color: theme.primary),
                const SizedBox(width: 8),
                AnymexText(
                    text: source.name ?? 'Unknown',
                    variant: TextVariant.bold,
                    size: 15),
                const SizedBox(width: 12),
                const SizedBox(
                    width: 14, height: 14, child: AnymexProgressIndicator()),
              ],
            ),
          );
        }

        if (medias.isEmpty && !isLoading) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.extension_rounded, size: 16, color: theme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnymexText(
                        text: source.name ?? 'Unknown',
                        variant: TextVariant.bold,
                        size: 15),
                  ),
                  if (isLoading)
                    const SizedBox(
                        width: 14,
                        height: 14,
                        child: AnymexProgressIndicator()),
                ],
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: medias.length,
                itemBuilder: (context, mIndex) {
                  final media = medias[mIndex];
                  return AnymexOnTap(
                    onTap: () => controller.fetchDetail(media, source),
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: theme.surfaceContainer.opaque(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.outline.opaque(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: AnymeXImage(
                                imageUrl: media.cover ?? '',
                                width: double.infinity,
                                fit: BoxFit.cover,
                                radius: 0,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: AnymexText(
                                text: media.title ?? 'Unknown',
                                variant: TextVariant.semiBold,
                                size: 12,
                                maxLines: 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEpisodeStep(
      BuildContext context, DownloadSearchController controller) {
    final theme = context.colors;
    final media = controller.selectedMedia.value;
    final isManga = controller.mediaType.value == 1;

    if (isManga) {
      return _buildChapterStep(context, controller, theme, media);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              AnymexOnTap(
                onTap: () => controller.resetDetail(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.surfaceContainerHighest.opaque(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: theme.onSurface),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnymexText(
                    text: media?.title ?? 'Details',
                    variant: TextVariant.semiBold,
                    size: 15,
                    maxLines: 1),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isFetchingDetail.value) {
              return const Center(child: AnymexProgressIndicator());
            }
            if (controller.episodes.isEmpty) {
              return _buildEmptyState(
                theme: theme,
                icon: HugeIcons.strokeRoundedPlay,
                message: 'No episodes found',
                subtitle: 'Could not fetch episodes for this title',
              );
            }

            final sortSections = buildEpisodeSortSections(controller.episodes);
            final filteredList = controller.filteredEpisodes;
            final chunkedEpisodes = chunkEpisodes(
              filteredList,
              calculateChunkSize(filteredList),
            );

            final safeChunkIndex = chunkedEpisodes.isEmpty
                ? 0
                : controller.selectedChunkIndex.value
                    .clamp(0, chunkedEpisodes.length - 1);

            final currentBatch = chunkedEpisodes.isNotEmpty
                ? chunkedEpisodes[safeChunkIndex]
                : <Episode>[];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              children: [
                if (sortSections.isNotEmpty)
                  ...sortSections.map((section) {
                    final values = controller.episodes
                        .where((episode) {
                          final sortMap = episode.sortMap;
                          return controller.selectedSortValues.entries
                              .every((entry) {
                            if (entry.key == section.key) return true;
                            return sortMap[entry.key]?.trim() == entry.value;
                          });
                        })
                        .map((episode) => episode.sortMap[section.key]?.trim())
                        .whereType<String>()
                        .where((value) => value.isNotEmpty)
                        .toSet()
                        .toList()
                      ..sort(compareEpisodeSortValues);

                    if (values.length <= 1) {
                      return const SizedBox.shrink();
                    }
                    return EpisodeSortKeySelector(
                      title: section.title,
                      labelPrefix: section.labelPrefix != "Type"
                          ? section.labelPrefix
                          : "",
                      sortKeys: values,
                      selectedSortKey:
                          RxnString(controller.selectedSortValues[section.key]),
                      onSortKeySelected: (sortValue) {
                        if (controller.selectedSortValues[section.key] ==
                            sortValue) {
                          return;
                        }
                        controller.selectedSortValues[section.key] = sortValue;
                        controller.initSortGrouping(controller.episodes);
                        controller.selectedChunkIndex.value = 0;
                      },
                    );
                  }).toList(),
                if (chunkedEpisodes.isNotEmpty && chunkedEpisodes.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AnymexText(
                            text: "Range", variant: TextVariant.bold, size: 14),
                        EpisodeChunkSelector(
                          chunks: chunkedEpisodes,
                          selectedChunkIndex: controller.selectedChunkIndex,
                          onChunkSelected: (index) {
                            controller.selectedChunkIndex.value = index;
                          },
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(HugeIcons.strokeRoundedPlay,
                          size: 14, color: theme.primary),
                      const SizedBox(width: 6),
                      AnymexText(
                        text: '${filteredList.length} episodes available',
                        size: 12,
                        color: theme.primary,
                      ),
                      const Spacer(),
                      AnymexOnTap(
                        onTap: () {
                          final allKeys = currentBatch
                              .map((e) => e.link ?? e.number)
                              .toSet();
                          if (allKeys.isNotEmpty &&
                              allKeys.every(
                                  controller.selectedEpisodes.contains)) {
                            controller.selectedEpisodes.removeAll(allKeys);
                          } else {
                            controller.selectedEpisodes.addAll(allKeys);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: theme.primaryContainer.opaque(0.3),
                              borderRadius: BorderRadius.circular(10)),
                          child: AnymexText(
                            text: currentBatch.isNotEmpty &&
                                    currentBatch.every((e) => controller
                                        .selectedEpisodes
                                        .contains(e.link ?? e.number))
                                ? 'Deselect All'
                                : 'Select All',
                            size: 12,
                            color: theme.primary,
                            variant: TextVariant.semiBold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...currentBatch.map((ep) {
                  final key = ep.link ?? ep.number;
                  final isSelected = controller.selectedEpisodes.contains(key);
                  final sortLabel = ep.sortMap.isNotEmpty
                      ? ep.sortMap.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join(' · ')
                      : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: AnymexOnTap(
                      onTap: () {
                        if (isSelected) {
                          controller.selectedEpisodes.remove(key);
                        } else {
                          controller.selectedEpisodes.add(key);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.primaryContainer.opaque(0.3)
                              : theme.surfaceContainer.opaque(0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? theme.primary.opaque(0.5)
                                : theme.outline.opaque(0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (ep.thumbnail != null &&
                                ep.thumbnail!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AnymeXImage(
                                  imageUrl: ep.thumbnail!,
                                  width: 60,
                                  height: 38,
                                  fit: BoxFit.cover,
                                  radius: 8,
                                ),
                              )
                            else
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: theme.primaryContainer.opaque(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: AnymexText(
                                      text: ep.number,
                                      size: 12,
                                      variant: TextVariant.semiBold,
                                      color: theme.primary),
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnymexText(
                                    text: ep.title?.isNotEmpty == true
                                        ? ep.title!
                                        : 'Episode ${ep.number}',
                                    size: 13,
                                    maxLines: 1,
                                    variant: isSelected
                                        ? TextVariant.semiBold
                                        : TextVariant.regular,
                                  ),
                                  if (sortLabel != null)
                                    AnymexText(
                                        text: sortLabel,
                                        size: 10,
                                        color: theme.primary.opaque(0.7)),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? theme.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.primary
                                        : theme.outline.opaque(0.4),
                                    width: 2,
                                  )),
                              child: isSelected
                                  ? Icon(Icons.check_rounded,
                                      size: 14, color: theme.onPrimary)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            );
          }),
        ),
        Obx(() => controller.selectedEpisodes.isEmpty ||
                controller.isFetchingDetail.value
            ? const SizedBox.shrink()
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: AnymexOnTap(
                    onTap: () async {
                      final episodes = controller.selectedEpisodesList;
                      final source = controller.selectedSource.value!;
                      final media = controller.selectedMedia.value;
                      final offlineMedia = OfflineMedia(
                        name: media?.title,
                        poster: media?.cover,
                        cover: media?.cover,
                      );

                      final started = await DownloadServerSelector.show(context,
                          episodes: episodes,
                          source: source,
                          media: offlineMedia);

                      if (started) {
                        controller.selectedEpisodes.clear();
                        controller.resetDetail();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(HugeIcons.strokeRoundedDownload04,
                              size: 20, color: theme.onPrimary),
                          const SizedBox(width: 8),
                          AnymexText(
                            text:
                                'Download ${controller.selectedEpisodes.length} Episode${controller.selectedEpisodes.length > 1 ? 's' : ''}',
                            size: 15,
                            variant: TextVariant.semiBold,
                            color: theme.onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildChapterStep(BuildContext context,
      DownloadSearchController controller, ColorScheme theme, DMedia? media) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              AnymexOnTap(
                onTap: () => controller.resetDetail(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.surfaceContainerHighest.opaque(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: theme.onSurface),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnymexText(
                    text: media?.title ?? 'Details',
                    variant: TextVariant.semiBold,
                    size: 15,
                    maxLines: 1),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isFetchingDetail.value) {
              return const Center(child: AnymexProgressIndicator());
            }
            if (controller.chapters.isEmpty) {
              return _buildEmptyState(
                theme: theme,
                icon: HugeIcons.strokeRoundedBookOpen01,
                message: 'No chapters found',
                subtitle: 'Could not fetch chapters for this title',
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(HugeIcons.strokeRoundedBookOpen01,
                          size: 14, color: theme.primary),
                      const SizedBox(width: 6),
                      AnymexText(
                        text:
                            '${controller.filteredChapters.length} chapters available',
                        size: 12,
                        color: theme.primary,
                      ),
                      const Spacer(),
                      AnymexOnTap(
                        onTap: () {
                          if (controller.selectedChapters.length ==
                              controller.filteredChapters.length) {
                            controller.deselectAllChapters();
                          } else {
                            controller.selectAllChapters();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: theme.primaryContainer.opaque(0.3),
                              borderRadius: BorderRadius.circular(10)),
                          child: AnymexText(
                            text: controller.selectedChapters.length ==
                                    controller.filteredChapters.length
                                ? 'Deselect All'
                                : 'Select All',
                            size: 12,
                            color: theme.primary,
                            variant: TextVariant.semiBold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.scanlators.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ScanlatorsRanges(
                      scanlators: controller.scanlators,
                      selectedScanIndex: controller.selectedScanlatorIndex,
                      onScanIndexChanged: () {},
                    ),
                  ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickSelectBtn(
                          'Next 10', () => controller.selectNextChapters(10)),
                      const SizedBox(width: 8),
                      _buildQuickSelectBtn(
                          'Next 20', () => controller.selectNextChapters(20)),
                      const SizedBox(width: 8),
                      _buildQuickSelectBtn(
                          'Next 100', () => controller.selectNextChapters(100)),
                      const SizedBox(width: 8),
                      _buildQuickSelectBtn(
                          'Custom Range', () => _showRangeDialog(controller)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...controller.filteredChapters.map((chapter) {
                  final isSelected = controller.isChapterSelected(chapter);
                  final numDisplay = chapter.number != null
                      ? 'Chapter ${chapter.number! % 1 == 0 ? chapter.number!.toInt() : chapter.number}'
                      : chapter.title ?? 'Chapter';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: AnymexOnTap(
                      onTap: () => controller.toggleChapter(chapter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.primaryContainer.opaque(0.3)
                              : theme.surfaceContainer.opaque(0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? theme.primary.opaque(0.5)
                                : theme.outline.opaque(0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.primary.opaque(0.15)
                                    : theme.primaryContainer.opaque(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  HugeIcons.strokeRoundedBook02,
                                  size: 18,
                                  color: isSelected
                                      ? theme.primary
                                      : theme.primary.opaque(0.5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnymexText(
                                    text: numDisplay,
                                    size: 13,
                                    maxLines: 1,
                                    variant: isSelected
                                        ? TextVariant.semiBold
                                        : TextVariant.regular,
                                  ),
                                  if (chapter.title != null &&
                                      chapter.title!.isNotEmpty &&
                                      chapter.title != numDisplay)
                                    AnymexText(
                                      text: chapter.title!,
                                      size: 11,
                                      color: theme.onSurface.opaque(0.5),
                                      maxLines: 1,
                                    ),
                                  if (chapter.releaseDate != null &&
                                      chapter.releaseDate!.isNotEmpty)
                                    AnymexText(
                                      text: chapter.releaseDate!,
                                      size: 10,
                                      color: theme.primary.opaque(0.6),
                                    ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? theme.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.primary
                                        : theme.outline.opaque(0.4),
                                    width: 2,
                                  )),
                              child: isSelected
                                  ? Icon(Icons.check_rounded,
                                      size: 14, color: theme.onPrimary)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ),
        Obx(() => controller.selectedChapters.isEmpty ||
                controller.isFetchingDetail.value
            ? const SizedBox.shrink()
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: AnymexOnTap(
                    onTap: () {
                      final chapters = controller.selectedChaptersList;
                      final source = controller.selectedSource.value!;
                      MangaChapterDownloadConfirm.show(
                        context,
                        chapters: chapters,
                        source: source,
                        media: OfflineMedia(
                          name: media?.title,
                          poster: media?.cover,
                          cover: media?.cover,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(HugeIcons.strokeRoundedDownload04,
                              size: 20, color: theme.onPrimary),
                          const SizedBox(width: 8),
                          AnymexText(
                            text:
                                'Download ${controller.selectedChapters.length} Chapter${controller.selectedChapters.length > 1 ? 's' : ''}',
                            size: 15,
                            variant: TextVariant.semiBold,
                            color: theme.onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  void _showExtensionSelector(
      BuildContext context, DownloadSearchController controller) {
    final theme = context.colors;
    final sourceController = Get.find<SourceController>();
    final allSources = controller.mediaType.value == 0
        ? sourceController.installedExtensions
        : sourceController.installedMangaExtensions;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: theme.outline.opaque(0.1), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AnymexText(
                      text: 'Search Extensions',
                      variant: TextVariant.bold,
                      size: 20,
                    ),
                    AnymexText(
                      text: '${allSources.length} available',
                      size: 13,
                      color: theme.onSurface.opaque(0.6),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    if (controller.disabledSourceIds.isEmpty) {
                      controller.disabledSourceIds
                          .addAll(allSources.map((s) => s.id ?? ''));
                    } else {
                      controller.disabledSourceIds.clear();
                    }
                  },
                  child: Obx(() => AnymexText(
                        text: controller.disabledSourceIds.isEmpty
                            ? 'Disable All'
                            : 'Enable All',
                        color: theme.primary,
                        variant: TextVariant.semiBold,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allSources.length,
                itemBuilder: (context, index) {
                  final source = allSources[index];
                  final sourceId = source.id ?? '';
                  return Obx(() {
                    final isEnabled =
                        !controller.disabledSourceIds.contains(sourceId);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? theme.primaryContainer.opaque(0.15)
                            : theme.surfaceContainer.opaque(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isEnabled
                              ? theme.primary.opaque(0.3)
                              : theme.outline.opaque(0.1),
                        ),
                      ),
                      child: ListTile(
                        onTap: () => controller.toggleSource(sourceId),
                        leading: Icon(
                          Icons.extension_rounded,
                          color: isEnabled
                              ? theme.primary
                              : theme.onSurface.opaque(0.4),
                        ),
                        title: AnymexText(
                          text: source.name ?? 'Unknown',
                          variant: TextVariant.semiBold,
                          color: isEnabled
                              ? theme.onSurface
                              : theme.onSurface.opaque(0.5),
                        ),
                        trailing: Switch(
                          value: isEnabled,
                          activeColor: theme.primary,
                          onChanged: (_) => controller.toggleSource(sourceId),
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const AnymexText(
                  text: 'Done',
                  variant: TextVariant.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectBtn(String label, VoidCallback onTap) {
    final theme = context.colors;
    return AnymexOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: AnymexText(
          text: label,
          size: 12,
          color: theme.onSurface,
          variant: TextVariant.semiBold,
        ),
      ),
    );
  }

  void _showRangeDialog(DownloadSearchController controller) {
    double start = 1;
    double end = 10;

    AnymexDialog(
      title: 'Select Range',
      contentWidget: Obx(() => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSelectionTypeBtn(
                      label: 'Chapter Number',
                      isSelected: !controller.selectByIndex.value,
                      onTap: () => controller.selectByIndex.value = false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSelectionTypeBtn(
                      label: 'By Index',
                      isSelected: controller.selectByIndex.value,
                      onTap: () => controller.selectByIndex.value = true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildRoundedInput(
                label: controller.selectByIndex.value
                    ? 'Start Index'
                    : 'Start Chapter',
                onChanged: (val) {
                  start = double.tryParse(val) ?? start;
                },
              ),
              const SizedBox(height: 12),
              _buildRoundedInput(
                label: controller.selectByIndex.value
                    ? 'End Index'
                    : 'End Chapter',
                onChanged: (val) {
                  end = double.tryParse(val) ?? end;
                },
              ),
            ],
          )),
      onConfirm: () {
        if (controller.selectByIndex.value) {
          controller.selectChapterByIndexRange(start.toInt(), end.toInt());
        } else {
          controller.selectChapterRange(start, end);
        }
      },
    ).show(context);
  }

  Widget _buildSelectionTypeBtn({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = context.colors;
    return AnymexOnTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary : theme.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: AnymexText(
            text: label,
            size: 12,
            color: isSelected ? theme.onPrimary : theme.onSurface,
            variant: isSelected ? TextVariant.semiBold : TextVariant.regular,
          ),
        ),
      ),
    );
  }

  Widget _buildRoundedInput({
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    final theme = context.colors;

    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.onSurface.opaque(0.5),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: theme.surfaceVariant.opaque(0.4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.outline.opaque(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.primary,
            width: 1.5,
          ),
        ),
      ),
      style: TextStyle(
        color: theme.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      onChanged: onChanged,
    );
  }
}
