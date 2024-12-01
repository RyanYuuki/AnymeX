import 'package:anymex/utils/sources/anime/handler/sources_handler.dart';
import 'package:anymex/utils/sources/manga/handlers/manga_sources_handler.dart';
import 'package:anymex/utils/sources/novel/handler/novel_sources_handler.dart';
import 'package:anymex/utils/sources/unified_handler.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class SettingsSources extends StatefulWidget {
  const SettingsSources({super.key});

  @override
  State<SettingsSources> createState() => _SettingsSourcesState();
}

class _SettingsSourcesState extends State<SettingsSources> {
  late List<dynamic> animeSources;
  late List<dynamic> mangaSources;
  late List<dynamic> novelSources;
  late String selectedAnimeSource;
  late String selectedMangaSource;
  late String selectedNovelSource;
  late SourcesHandler animeInstance;
  late MangaSourceHandler mangaInstance;
  late NovelSourcesHandler novelInstance;

  @override
  void initState() {
    initVars();
    super.initState();
  }

  void initVars() {
    final provider = Provider.of<UnifiedSourcesHandler>(context, listen: false);
    animeInstance = provider.getAnimeInstance();
    mangaInstance = provider.getMangaInstance();
    novelInstance = provider.getNovelInstance();
    animeSources = animeInstance.getAvailableSource();
    mangaSources = mangaInstance.getAvailableSources();
    novelSources = novelInstance.getAvailableSources();
    selectedAnimeSource = animeInstance.selectedSource;
    selectedMangaSource = mangaInstance.selectedSourceName!;
    selectedNovelSource = novelInstance.selectedSourceName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView(
        children: [
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  IconlyBroken.arrow_left_2,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sources',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.source,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Common',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                ]),
          ),
          const SizedBox(height: 15),
          _buildSourceTile(
              'Anime Source',
              'Select your preferred anime streaming source.',
              selectedAnimeSource,
              animeSources, (newValue) {
            animeInstance.changeSelectedSource(newValue!);
            setState(() {
              selectedAnimeSource = newValue;
            });
          }, Icons.movie),
          _buildSourceTile(
              'Manga Source',
              'Select your preferred Manga Reading source.',
              selectedMangaSource,
              mangaSources, (newValue) {
            mangaInstance.setSelectedSource(newValue!);
            setState(() {
              selectedMangaSource = newValue;
            });
          }, Iconsax.book),
          _buildSourceTile(
              'Novel Source',
              'Select your preferred Novel Reading source.',
              selectedNovelSource,
              novelSources, (newValue) {
            novelInstance.setSelectedSource(newValue!);
            setState(() {
              selectedNovelSource = newValue;
            });
          }, HugeIcons.strokeRoundedBook04),
        ],
      ),
    );
  }

  Widget _buildSourceTile(
      String title,
      String description,
      String selectedValue,
      List<dynamic> options,
      ValueChanged<String?> onChanged,
      IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.surfaceContainer,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 30,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, size: 30),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontFamily: 'Poppins-SemiBold'),
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: options.map((value) {
                  return DropdownMenuItem<String>(
                    value: value['name'],
                    child: Text(
                      value['name'],
                      style: const TextStyle(fontFamily: 'Poppins-SemiBold'),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
