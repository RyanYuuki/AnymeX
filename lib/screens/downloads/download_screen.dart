import 'dart:async';
import 'package:anymex/screens/downloads/controller/download_controller.dart';
import 'package:anymex/screens/downloads/controller/download_search_controller.dart';
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/screens/anime/widgets/episode_range.dart';
import 'package:anymex/screens/downloads/nested_screens/active_downloads/active_downloads.dart';
import 'package:anymex/screens/downloads/widgets/download_server_selector.dart';
import 'package:anymex/screens/downloads/widgets/downloaded_media_view.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

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
  final searchController = Get.put(DownloadSearchController());

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
                children: const [
                  _MyDownloadsTab(),
                  _NewDownloadTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyDownloadsTab extends StatelessWidget {
  const _MyDownloadsTab();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DownloadController>();
    return Obx(() {
      final media = controller.downloadedMedia;
      if (media.isEmpty) {
        return const _EmptyState(
          icon: HugeIcons.strokeRoundedFolderLibrary,
          message: 'No downloaded media',
          subtitle: 'Downloaded episodes will appear here',
        );
      }
      final screenWidth = MediaQuery.of(context).size.width;
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
          return _MediaCard(
            meta: item,
            onTap: () => navigate(() => DownloadedMediaView(summary: item)),
          );
        },
      );
    });
  }
}

class _MediaCard extends StatelessWidget {
  final DownloadedMediaSummary meta;
  final VoidCallback onTap;
  const _MediaCard({required this.meta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
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
              child: ClipRRect(
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
                          child: Icon(HugeIcons.strokeRoundedPlay,
                              size: 40, color: theme.primary.opaque(0.4)),
                        ),
                      ),
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
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.primary.opaque(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FutureBuilder<DownloadedMediaMeta?>(
                      future: Get.find<DownloadController>().getMediaMeta(meta.extensionName, meta.folderName),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.episodes.length ?? 0;
                        return AnymexText(
                            text: '$count eps',
                            size: 11,
                            color: theme.primary,
                            variant: TextVariant.semiBold);
                      }
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
}

class _NewDownloadTab extends StatelessWidget {
  const _NewDownloadTab();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DownloadSearchController>();
    return Obx(() {
      if (controller.step.value == 1)
        return _buildEpisodeStep(context, controller);

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
            child: TextField(
              controller: controller.searchController,
              onSubmitted: controller.search,
              style: TextStyle(fontSize: 15, color: theme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search across extensions...',
                hintStyle:
                    TextStyle(color: theme.onSurface.opaque(0.4), fontSize: 14),
                filled: true,
                fillColor: theme.surfaceContainer.opaque(0.3),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon:
                    Icon(Icons.search_rounded, color: theme.primary, size: 20),
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
          const SizedBox(height: 12),
          Expanded(
            child: controller.mediaType.value == 1
                ? const _EmptyState(
                    icon: HugeIcons.strokeRoundedBookOpen01,
                    message: 'Manga downloads not yet supported',
                    subtitle: 'This feature will be added in a future update',
                  )
                : _buildSearchResults(context, controller),
          ),
        ],
      );
    });
  }

  Widget _buildSearchResults(
      BuildContext context, DownloadSearchController controller) {
    final theme = context.colors;
    
    final sources = controller.searchingSources;

    if (sources.isEmpty) {
      if (controller.isSearching.value) {
        return const Center(child: AnymexProgressIndicator());
      }
      return const _EmptyState(
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              AnymexOnTap(
                onTap: () => controller.step.value = 0,
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
              return const _EmptyState(
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
                            )
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
                      final selectedObjs = controller.filteredEpisodes
                          .where((e) => controller.selectedEpisodes
                              .contains(e.link ?? e.number))
                          .toList();
                      final started = await DownloadServerSelector.show(
                        context,
                        episodes: selectedObjs,
                        source: controller.selectedSource.value!,
                        media: OfflineMedia(
                          name: media?.title,
                          poster: media?.cover,
                          cover: media?.cover,
                        ),
                      );

                      if (started) {
                        navigate(() => const ActiveDownloads());
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
}

class _EmptyState extends StatelessWidget {
  final dynamic icon;
  final String message;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.message, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: context.colors.onSurface.opaque(0.15)),
          const SizedBox(height: 16),
          AnymexText(
              text: message,
              size: 16,
              variant: TextVariant.semiBold,
              color: context.colors.onSurface.opaque(0.4)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AnymexText(
                text: subtitle,
                size: 13,
                color: context.colors.onSurface.opaque(0.3),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
