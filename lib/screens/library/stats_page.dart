import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/database/isar_models/custom_list.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final OfflineStorageController controller =
        Get.find<OfflineStorageController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Statistics'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anime Library Section
            const Text(
              'Anime Library',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            const Text(
              'Manga Library',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            const Text(
              'Novel Library',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            const Text(
              'Anime Custom Lists',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            const Text(
              'Manga Custom Lists',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            const Text(
              'Novel Custom Lists',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        library.isEmpty
            ? const Text(
                'No items in this library.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
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
                      title: Text(media.name ?? 'Unnamed Media'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${media.mediaId}'),
                          if (media.type != null) Text('Type: ${media.type}'),
                          if (media.genres != null && media.genres!.isNotEmpty)
                            Text('Genres: ${media.genres!.join(', ')}'),
                          Text(
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
        Text(
          'Total Lists: ${customLists.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        customLists.isEmpty
            ? const Text(
                'No custom lists available.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
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
                          title: Text(listName),
                          subtitle: Text('Items: ${listData.length}'),
                          children: listData.isEmpty
                              ? [
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('No media in this list.'),
                                  )
                                ]
                              : listData.map((media) {
                                  return ListTile(
                                    title: Text(media.name ?? 'Unnamed Media'),
                                    subtitle: Text('ID: ${media.mediaId}'),
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
