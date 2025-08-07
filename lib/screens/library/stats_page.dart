import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';

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
            Obx(() => _buildLibrarySection(
                  context,
                  'Anime Count: ${controller.animeLibrary.length}',
                  controller.animeLibrary,
                )),
            const SizedBox(height: 24),

            // Manga Library Section
            const Text(
              'Manga Library',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Obx(() => _buildLibrarySection(
                  context,
                  'Manga Count: ${controller.mangaLibrary.length}',
                  controller.mangaLibrary,
                )),
            const SizedBox(height: 24),

            // Anime Custom Lists Section
            const Text(
              'Anime Custom Lists',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Obx(() => _buildCustomListsSection(
                  context,
                  controller.animeCustomListData,
                )),
            const SizedBox(height: 24),

            // Manga Custom Lists Section
            const Text(
              'Manga Custom Lists',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Obx(() => _buildCustomListsSection(
                  context,
                  controller.mangaCustomListData,
                )),
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
                          Text('ID: ${media.id}'),
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
      BuildContext context, Rx<List<CustomListData>> customLists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Lists: ${customLists.value.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        customLists.value.isEmpty
            ? const Text(
                'No custom lists available.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: customLists.value.length,
                itemBuilder: (context, index) {
                  final customList = customLists.value[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ExpansionTile(
                      title: Text(customList.listName),
                      subtitle: Text('Items: ${customList.listData.length}'),
                      children: customList.listData.isEmpty
                          ? [
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No media in this list.'),
                              )
                            ]
                          : customList.listData.map((media) {
                              return ListTile(
                                title: Text(media.name ?? 'Unnamed Media'),
                                subtitle: Text('ID: ${media.id}'),
                              );
                            }).toList(),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
