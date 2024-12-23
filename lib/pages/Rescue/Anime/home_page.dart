import 'dart:math';
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_manga.dart';
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_pages.dart';
import 'package:anymex/api/Mangayomi/Extensions/extensions_provider.dart';
import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:anymex/api/Mangayomi/Search/search.dart';
import 'package:anymex/pages/Rescue/Anime/details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

class RescueAnimeHome extends StatefulWidget {
  const RescueAnimeHome({super.key});

  @override
  State<RescueAnimeHome> createState() => _RescueAnimeHomeState();
}

class _RescueAnimeHomeState extends State<RescueAnimeHome> {
  late Future<MPages?> _searchFuture;
  final TextEditingController _controller = TextEditingController();
  Source? activeSource;
  late List<Source> installedExtensions;

  void _performSearch(String query) async {
    final tempData =
        search(source: activeSource!, query: query, page: 1, filterList: []);
    setState(() {
      _searchFuture = tempData;
    });
  }

  @override
  void initState() {
    super.initState();
    _initExtensions();
  }

  Future<void> _initExtensions() async {
    final container = ProviderContainer();
    final sourcesAsyncValue =
        await container.read(getExtensionsStreamProvider(false).future);
    installedExtensions =
        sourcesAsyncValue.where((source) => source.isAdded!).toList();
    if (installedExtensions.isNotEmpty) {
      setState(() {
        activeSource = installedExtensions[0];
      });
      _searchFuture =
          search(source: activeSource!, query: "Aot", page: 1, filterList: []);
    } else {
      setState(() {
        activeSource = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: activeSource == null
            ? Center(
                child: Text(
                  'No sources available.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.arrow_back_ios_new)),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                onSubmitted: _performSearch,
                                decoration: InputDecoration(
                                  labelText: 'Search Anime',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.auto,
                                  filled: true,
                                  fillColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHigh,
                                  suffixIcon: const Icon(Iconsax.search_normal),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: activeSource?.name,
                          decoration: InputDecoration(
                            labelText: 'Choose Source',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            labelStyle: TextStyle(
                                color: Theme.of(context).colorScheme.primary),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryFixedVariant),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                          isExpanded: true,
                          items: installedExtensions.map((source) {
                            return DropdownMenuItem<String>(
                              value: source.name,
                              child: Text(
                                source.name!,
                                style: const TextStyle(
                                    fontFamily: 'Poppins-SemiBold'),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            setState(() {
                              activeSource = installedExtensions
                                  .firstWhere((e) => e.name == value);
                            });
                            _performSearch(_controller.text);
                          },
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          icon: Icon(Icons.arrow_drop_down,
                              color: Theme.of(context).colorScheme.primary),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<MPages?>(
                      future: _searchFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData) {
                          return const Center(child: Text('No results found'));
                        } else {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: snapshot.data!.list.length,
                              itemBuilder: (BuildContext context, int index) {
                                final anime = snapshot.data!.list[index];
                                return searchItemList(
                                    context, anime, activeSource!);
                              },
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

GestureDetector searchItemList(
    BuildContext context, MManga anime, Source activeSource) {
  final tag = '${anime.link}-${Random().nextInt(1000)}';
  return GestureDetector(
    onTap: () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => RescueDetailsPage(
                    id: anime.link!,
                    posterUrl: anime.imageUrl,
                    tag: tag,
                    title: anime.name!,
                    source: activeSource,
                  )));
    },
    child: Container(
      height: 110,
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Theme.of(context).colorScheme.surfaceContainer),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          SizedBox(
            height: 70,
            width: 50,
            child: Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: CachedNetworkImage(
                  imageUrl: anime.imageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            anime.name!.length > 28
                ? '${anime.name!.toString().substring(0, 28)}...'
                : anime.name!.toString(),
          )
        ],
      ),
    ),
  );
}
