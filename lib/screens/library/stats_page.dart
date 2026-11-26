import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/database/isar_models/custom_list.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final OfflineStorageController controller =
        Get.find<OfflineStorageController>();

    return Scaffold(
      appBar: AppBar(
        title: AnymeXText(context.l10n.libraryStatistics),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anime Library Section
            AnymeXText(
              context.l10n.animeLibrary,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<OfflineMedia>>(
              stream: controller.watchAnimeLibrary(),
              builder: (context, snapshot) {
                final library = snapshot.data ?? [];
                return _buildLibrarySection(
                  context,
                  'Anime Count: ${library.length}',
                  library,
                );
              },
            ),
            const SizedBox(height: 24),

            // Manga Library Section
            AnymeXText(
              context.l10n.mangaLibrary,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<OfflineMedia>>(
              stream: controller.watchMangaLibrary(),
              builder: (context, snapshot) {
                final library = snapshot.data ?? [];
                return _buildLibrarySection(
                  context,
                  'Manga Count: ${library.length}',
                  library,
                );
              },
            ),
            const SizedBox(height: 24),

            // Novel Library Section
            AnymeXText(
              context.l10n.novelLibrary,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<OfflineMedia>>(
              stream: controller.watchNovelLibrary(),
              builder: (context, snapshot) {
                final library = snapshot.data ?? [];
                return _buildLibrarySection(
                  context,
                  'Novel Count: ${library.length}',
                  library,
                );
              },
            ),
            const SizedBox(height: 24),

            // Anime Custom Lists Section
            AnymeXText(
              context.l10n.animeCustomLists,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<CustomList>>(
              stream: controller.watchCustomLists(ItemType.anime),
              builder: (context, snapshot) {
                final lists = snapshot.data
                        ?.where((l) => l.mediaTypeIndex == ItemType.anime.index)
                        .toList() ??
                    [];
                return _buildCustomListsSection(context, lists, controller);
              },
            ),
            const SizedBox(height: 24),

            // Manga Custom Lists Section
            AnymeXText(
              context.l10n.mangaCustomLists,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<CustomList>>(
              stream: controller.watchCustomLists(ItemType.manga),
              builder: (context, snapshot) {
                final lists = snapshot.data
                        ?.where((l) => l.mediaTypeIndex == ItemType.manga.index)
                        .toList() ??
                    [];
                return _buildCustomListsSection(context, lists, controller);
              },
            ),
            const SizedBox(height: 24),

            // Novel Custom Lists Section
            AnymeXText(
              context.l10n.novelCustomLists,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<CustomList>>(
              stream: controller.watchCustomLists(ItemType.novel),
              builder: (context, snapshot) {
                final lists = snapshot.data
                        ?.where((l) => l.mediaTypeIndex == ItemType.novel.index)
                        .toList() ??
                    [];
                return _buildCustomListsSection(context, lists, controller);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibrarySection(
      BuildContext context, String title, List<OfflineMedia> library) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnymeXText(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        library.isEmpty
            ? AnymeXText(
                context.l10n.noItemsInThisLibrary,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: library.length,
                itemBuilder: (context, index) {
                  final media = library[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: AnymeXText(media.name ?? 'Unnamed Media'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymeXText(context.l10n.id(media.mediaId.toString())),
                          if (media.type != null) AnymeXText(context.l10n.type(media.type.toString())),
                          if (media.genres != null && media.genres!.isNotEmpty)
                            AnymeXText('Genres: ${media.genres!.join(', ')}'),
                          AnymeXText(
                              'Episodes/Chapters: ${media.totalEpisodes ?? media.totalChapters ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildCustomListsSection(
    BuildContext context,
    List<CustomList> customLists,
    OfflineStorageController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnymeXText(
          context.l10n.totalLists((customLists.length).toString()),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        customLists.isEmpty
            ? AnymeXText(
                context.l10n.noCustomListsAvailable,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: customLists.length,
                itemBuilder: (context, index) {
                  final customList = customLists[index];
                  final listName = customList.listName ?? '';

                  return StreamBuilder<CustomListData>(
                    stream: controller.watchCustomListData(
                        listName, ItemType.values[customList.mediaTypeIndex]),
                    builder: (context, snapshot) {
                      final listData = snapshot.data?.listData ?? [];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ExpansionTile(
                          title: AnymeXText(listName),
                          subtitle: AnymeXText(context.l10n.items(listData.length.toString())),
                          children: listData.isEmpty
                              ? [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: AnymeXText(context.l10n.noMediaInThisList),
                                  )
                                ]
                              : listData.map((media) {
                                  return ListTile(
                                    title: AnymeXText(media.name ?? 'Unnamed Media'),
                                    subtitle: AnymeXText(context.l10n.id(media.mediaId.toString())),
                                  );
                                }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
      ],
    );
  }
}
