// screens/watch_offline.dart
// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/local_source/player/offline_player_old.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:anymex/models/Offline/Hive/video.dart' as h;
import 'package:anymex/screens/local_source/controller/local_source_controller.dart';
import 'package:anymex/screens/local_source/model/detail_result.dart';
import 'package:anymex/screens/local_source/player/offline_player.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path/path.dart' as path;

class WatchOffline extends StatefulWidget {
  const WatchOffline({super.key});

  @override
  State<WatchOffline> createState() => _WatchOfflineState();
}

class _WatchOfflineState extends State<WatchOffline> {
  final LocalSourceController controller = Get.put(LocalSourceController());
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    controller.dispose();
    Get.delete<LocalSourceController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          bool shouldPop = controller.handleBackButton();
          if (shouldPop) {
            Navigator.pop(context);
          }
        }
      },
      child: Glow(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.4),
            ),
            child: Column(
              children: [
                _buildAppBar(theme, controller),
                Expanded(
                  child: _buildContent(theme, controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, LocalSourceController controller) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.4),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => controller.handleNavigation(context),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: theme.colorScheme.onSurface,
            ),
            style: IconButton.styleFrom(
              backgroundColor:
                  theme.colorScheme.surfaceVariant.withOpacity(0.3),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local Library',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                      controller.viewMode.value == ViewMode.search
                          ? 'Search stuff you wanna download'
                          : controller.viewMode.value == ViewMode.download
                              ? "AnymeX Downloads"
                              : controller.currentDirectoryName,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )),
              ],
            ),
          ),
          // 8.width(),
          // Stack(
          //   alignment: Alignment.center,
          //   children: [
          //     IconButton(
          //       onPressed: () {
          //         navigate(() => const DownloadManagerPage());
          //       },
          //       icon: Icon(
          //         Icons.download,
          //         color: theme.colorScheme.onSurface,
          //       ),
          //       style: IconButton.styleFrom(
          //         backgroundColor:
          //             theme.colorScheme.surfaceVariant.withOpacity(0.3),
          //         padding: const EdgeInsets.all(12),
          //       ),
          //     ),
          //     // Badge
          //     Obx(() {
          //       return DownloadManagerController.instance.downloadsList.isEmpty
          //           ? const SizedBox.shrink()
          //           : Positioned(
          //               right: 0,
          //               top: 0,
          //               child: Container(
          //                 padding: const EdgeInsets.all(4),
          //                 decoration: BoxDecoration(
          //                   color: theme.colorScheme.primary,
          //                   shape: BoxShape.circle,
          //                 ),
          //                 constraints: const BoxConstraints(
          //                   minWidth: 20,
          //                   minHeight: 20,
          //                 ),
          //                 child: Center(
          //                   child: Text(
          //                     DownloadManagerController
          //                         .instance.downloadsList.length
          //                         .toString(),
          //                     style: TextStyle(
          //                       color: theme.colorScheme.onPrimary,
          //                       fontSize: 12,
          //                       fontWeight: FontWeight.bold,
          //                     ),
          //                   ),
          //                 ),
          //               ),
          //             );
          //     }),
          //   ],
          // )
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, LocalSourceController controller) {
    return Obx(() {
      if (controller.viewMode.value == ViewMode.search) {
        return _buildSearchContent(theme, controller);
      }

      if (controller.viewMode.value == ViewMode.download) {
        return _buildItemGrid(theme, controller, isDownloads: true);
      }

      if (controller.isLoading.value) {
        return _buildLoadingState(theme);
      }

      if (!controller.hasPermission.value) {
        return _buildPermissionDeniedState(theme, controller);
      }

      if (!controller.hasSelectedDirectory.value) {
        return _buildNoDirectorySelectedState(theme, controller);
      }

      return _buildItemGrid(theme, controller);
    });
  }

  Widget _buildSearchContent(
      ThemeData theme, LocalSourceController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _buildModernViewSwitcher(controller),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSearchBar(theme, controller)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchResults(theme, controller),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, LocalSourceController controller) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  controller.search(value);
                }
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                hintText: 'Search anime, movies...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (searchController.text.isNotEmpty) {
                  controller.search(searchController.text);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Iconsax.search_normal,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
      ThemeData theme, LocalSourceController controller) {
    return Obx(() {
      if (controller.isLoadingServers.value) {
        return _buildMediaLoadingState(theme);
      }

      if (controller.isLoadingMedia.value) {
        return _buildMediaLoadingState(theme);
      }
      if (controller.isSearching.value) {
        return _buildSearchLoadingState(theme);
      }

      if (controller.searchResults.isEmpty) {
        return _buildNoSearchResultsState(theme);
      }

      if (controller.selectedVideos.value.isNotEmpty) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                getResponsiveValue(context, mobileValue: 1, desktopValue: 2),
            mainAxisExtent: 130,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: controller.selectedVideos.value.length,
          itemBuilder: (context, index) {
            return _buildServerTile(
                theme, controller.selectedVideos.value[index]);
          },
        );
      }

      if (controller.selectedSeason.value != null) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                getResponsiveValue(context, mobileValue: 1, desktopValue: 2),
            mainAxisExtent: 130,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: controller.selectedSeason.value?.episodes.length,
          itemBuilder: (context, index) {
            return _buildEpisodesTile(
                theme, controller.selectedSeason.value!.episodes[index]);
          },
        );
      }

      if (controller.selectedMedia.value != null) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                getResponsiveValue(context, mobileValue: 1, desktopValue: 2),
            mainAxisExtent: 130,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: controller.selectedMedia.value?.seasons.length,
          itemBuilder: (context, index) {
            return _buildSeasonsTile(
                theme, controller.selectedMedia.value!.seasons[index]);
          },
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              getResponsiveValue(context, mobileValue: 1, desktopValue: 2),
          mainAxisExtent: 130,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: controller.searchResults.length,
        itemBuilder: (context, index) {
          return _buildSearchResultTile(theme, controller.searchResults[index]);
        },
      );
    });
  }

  Widget _buildSearchLoadingState(ThemeData theme) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExpressiveLoadingIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaLoadingState(ThemeData theme) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExpressiveLoadingIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading Media...',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState(ThemeData theme) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Iconsax.search_normal,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              searchController.text.isEmpty
                  ? 'Search Something...'
                  : 'No results found',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchController.text.isEmpty
                  ? 'e.q. "Attack on Titan", "Breaking Bad", "Naruto"'
                  : 'Try searching for different keywords',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultTile(ThemeData theme, DMedia? searchResult) {
    String title = searchResult?.title ?? 'Unknown Title';
    String poster = searchResult?.cover ?? '';
    Map<String, dynamic> otherData = jsonDecode(searchResult?.author ?? '');

    return GestureDetector(
      onTap: () async => await controller.onSearchResultTap(searchResult),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: _buildPosterWidget(theme, poster),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (otherData['type'].isNotEmpty)
                          _buildInfoChip(
                            theme,
                            otherData['type'].toString().toUpperCase(),
                            Iconsax.document,
                          ),
                        5.width(),
                        if (otherData['rating'].isNotEmpty)
                          _buildInfoChip(
                            theme,
                            otherData['rating'].toString(),
                            Iconsax.star5,
                          ),
                        // 5.width(),
                        // if (otherData['year'].isNotEmpty)
                        //   _buildInfoChip(
                        //     theme,
                        //     otherData['year'].toString(),
                        //     Iconsax.calendar,
                        //   ),
                      ],
                    )
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                size: 16,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonsTile(ThemeData theme, DetailSeasons season) {
    String title = season.title;

    return GestureDetector(
      onTap: () => controller.onSeasonTap(season),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: _buildPosterWidget(theme, season.poster),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          theme,
                          controller.selectedMedia.value?.title ?? '',
                          Iconsax.archive,
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                size: 16,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodesTile(ThemeData theme, DetailEpisode? chapter) {
    String title = chapter?.title ?? 'Unknown Title';

    return GestureDetector(
      onTap: () async => await controller.onEpisodeTap(chapter),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: _buildPosterWidget(theme, chapter!.poster),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          theme,
                          controller.selectedSeason.value?.title ?? '',
                          Iconsax.archive,
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                size: 16,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerTile(ThemeData theme, h.Video? video) {
    return GestureDetector(
      onTap: () async => await controller.downloadVideo(video!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: _buildPosterWidget(theme, ''),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      video?.quality ?? 'Auto',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.download_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                size: 16,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPosterWidget(ThemeData theme, String posterUrl) {
    if (posterUrl.isEmpty) {
      return Center(
        child: Icon(
          Iconsax.video_play,
          color: theme.colorScheme.primary,
          size: 32,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        posterUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: ExpressiveLoadingIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Iconsax.video_play,
              color: theme.colorScheme.primary,
              size: 32,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return SizedBox(
      height: Get.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExpressiveLoadingIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Loading media files...',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedState(
      ThemeData theme, LocalSourceController controller) {
    return Container(
      height: Get.height * 0.6,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Storage Permission Required',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please grant storage permission to browse your media files',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.checkPermissionAndShowPicker,
              icon: const Icon(Icons.folder_open),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.4),
                foregroundColor: theme.colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDirectorySelectedState(
      ThemeData theme, LocalSourceController controller) {
    return Container(
      height: Get.height * 0.6,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Media Directory',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose a directory to browse your media files',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.showDirectoryPicker,
              icon: const Icon(Icons.folder_open),
              label: const Text('Select Directory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.4),
                foregroundColor: theme.colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, LocalSourceController controller) {
    return Container(
      height: Get.height * 0.6,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Media Files Found',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This directory contains no supported media files',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemGrid(ThemeData theme, LocalSourceController controller,
      {bool isDownloads = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernViewSwitcher(controller),
          const SizedBox(height: 16),
          Obx(() {
            final items = isDownloads
                ? controller.downloadItems
                : controller.currentItems;

            if (items.isEmpty) {
              return _buildEmptyState(theme, controller);
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: getResponsiveValue(context,
                    mobileValue: 1, desktopValue: 2),
                mainAxisExtent: 130,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildItemTile(theme, controller, item, index);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildModernViewSwitcher(LocalSourceController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Get.theme.colorScheme.outline.withOpacity(0.12),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => controller.supportsDownloads.value
              ? _buildModernTab(
                  controller: controller,
                  icon: Iconsax.search_normal,
                  label: 'Search',
                  viewMode: ViewMode.search,
                  isSelected: controller.viewMode.value == ViewMode.search,
                )
              : const SizedBox.shrink()),
          Obx(() => controller.supportsDownloads.value
              ? _buildModernTab(
                  controller: controller,
                  icon: Icons.download_rounded,
                  label: 'Download',
                  viewMode: ViewMode.download,
                  isSelected: controller.viewMode.value == ViewMode.download,
                )
              : const SizedBox.shrink()),
          Obx(() => _buildModernTab(
                controller: controller,
                icon: Iconsax.folder_open,
                label: 'Local',
                viewMode: ViewMode.local,
                isSelected: controller.viewMode.value == ViewMode.local,
              )),
        ],
      ),
    );
  }

  Widget _buildModernTab({
    required LocalSourceController controller,
    required IconData icon,
    required String label,
    required ViewMode viewMode,
    required bool isSelected,
  }) {
    final theme = Get.theme;
    final canChangeDirectory = viewMode == ViewMode.local && isSelected;

    return Expanded(
      flex: 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.handleTabSwitch(viewMode),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      icon,
                      key: ValueKey('$viewMode-$isSelected'),
                      size: 18,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            fontSize: 11),
                      ),
                    ),
                    if (canChangeDirectory) ...[
                      const SizedBox(width: 4),
                      AnimatedOpacity(
                        opacity: canChangeDirectory ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: theme.colorScheme.onPrimary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemTile(ThemeData theme, LocalSourceController controller,
      FileSystemEntity item, int index) {
    String itemName = path.basename(item.path);
    bool isDirectory = item is Directory;
    String extension = isDirectory ? '' : path.extension(item.path);
    String fileSize =
        !isDirectory && item is File ? controller.getFileSize(item) : '';
    bool isVideoFile = !isDirectory &&
        controller.watchableExtensions.contains(extension.toLowerCase());

    return GestureDetector(
      onTap: () {
        if (isDirectory) {
          controller.navigateToFolder(item.path);
        } else {
          if (settingsController.preferences
              .get('useOldPlayer', defaultValue: false)) {
            navigate(() => OfflineWatchPageOld(
                  episodePath: LocalEpisode(
                      path: item.path,
                      name: itemName,
                      folderName: path.basename(controller.currentPath.value)),
                  episodesList: const [],
                ));
          } else {
            navigate(() => OfflineWatchPage(
                episodeList: const [],
                episode: LocalEpisode(
                    path: item.path,
                    name: itemName,
                    folderName: path.basename(controller.currentPath.value))));
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDirectory
                      ? theme.colorScheme.secondary.withOpacity(0.1)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  border: Border.all(
                    color: isDirectory
                        ? theme.colorScheme.secondary.withOpacity(0.3)
                        : theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: _buildThumbnailWidget(
                    theme, controller, item, isDirectory, isVideoFile),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (!isDirectory) ...[
                          _buildInfoChip(
                            theme,
                            extension.toUpperCase().substring(1),
                            Iconsax.document_text,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            theme,
                            fileSize,
                            Iconsax.archive,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(theme, 'Play', Iconsax.play5,
                              isFilled: true),
                        ] else ...[
                          _buildInfoChip(
                            theme,
                            'FOLDER',
                            Iconsax.folder,
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              isDirectory
                  ? Icon(
                      Iconsax.arrow_right_3,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    )
                  : const SizedBox.shrink()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, String text, IconData icon,
      {bool isFilled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFilled
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isFilled
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.secondary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isFilled
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailWidget(
      ThemeData theme,
      LocalSourceController controller,
      FileSystemEntity item,
      bool isDirectory,
      bool isVideoFile) {
    if (isDirectory) {
      return Center(
        child: Icon(
          Icons.folder_outlined,
          color: theme.colorScheme.secondary,
          size: 32,
        ),
      );
    }

    if (isVideoFile) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
        ),
        child: Center(
            child: Icon(
          Icons.movie_outlined,
          color: theme.colorScheme.primary,
          size: 32,
        )),
      );
    }

    return Center(
      child: Icon(
        Icons.movie_outlined,
        color: theme.colorScheme.primary,
        size: 32,
      ),
    );
  }
}
