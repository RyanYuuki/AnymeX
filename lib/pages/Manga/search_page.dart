import 'dart:math';
import 'dart:ui';
import 'package:anymex/components/platform_builder.dart';
import 'package:anymex/pages/Manga/details_page.dart';
import 'package:anymex/utils/apiHooks/anilist/manga/search_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class MangaSearchPage extends StatefulWidget {
  final String searchTerm;
  const MangaSearchPage({super.key, required this.searchTerm});

  @override
  State<MangaSearchPage> createState() => _MangaSearchPageState();
}

const String proxyUrl = '';

class _MangaSearchPageState extends State<MangaSearchPage> {
  final TextEditingController controller = TextEditingController();
  List<dynamic>? _searchData;
  List<String> layoutModes = ['List', 'Box', 'Cover'];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    controller.text = widget.searchTerm;
    fetchSearchedTerm();
  }

  Future<void> fetchSearchedTerm() async {
    _searchData = null;
    dynamic tempData = await fetchMangaBySearch(controller.text);
    setState(() {
      _searchData = tempData;
    });
  }

  void _search(String searchTerm) {
    setState(() {
      controller.text = searchTerm;
    });
    fetchSearchedTerm();
  }

  void _toggleView() {
    setState(() {
      currentIndex = (currentIndex + 1) % layoutModes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isList = layoutModes[currentIndex] == 'List';
    bool isBox = layoutModes[currentIndex] == 'Box';
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(IconlyBold.arrow_left)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onSubmitted: _search,
                      decoration: InputDecoration(
                        hintText: 'Eg.. Attack on Titan',
                        prefixIcon: const Icon(Iconsax.search_normal),
                        suffixIcon: const Icon(IconlyBold.filter),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _toggleView,
                    icon: Icon(
                      isList
                          ? Iconsax.menu
                          : (isBox ? Iconsax.image : Icons.menu),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: _searchData == null
                    ? const Center(child: CircularProgressIndicator())
                    : PlatformBuilder(
                        desktopBuilder: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: isList
                              ? const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1,
                                  mainAxisExtent: 100,
                                )
                              : (isBox
                                  ? const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6,
                                      crossAxisSpacing: 10.0,
                                      mainAxisSpacing: 10.0,
                                      mainAxisExtent: 150)
                                  : const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 1,
                                      mainAxisExtent: 170,
                                    )),
                          itemCount: _searchData!.length,
                          itemBuilder: (context, index) {
                            final anime = _searchData![index];
                            final tag = _searchData![index]['id'].toString();
                            return isList
                                ? SearchItem_LIST(context, anime, tag)
                                : isBox
                                    ? SearchItem_BOX(context, anime, tag)
                                    : SearchItem_COVER(context, anime, tag);
                          },
                        ),
                        androidBuilder: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: isList
                              ? const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1,
                                  mainAxisExtent: 100,
                                )
                              : (isBox
                                  ? const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 10.0,
                                      mainAxisSpacing: 10.0,
                                      childAspectRatio: 0.7,
                                    )
                                  : const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 1,
                                      mainAxisExtent: 170,
                                    )),
                          itemCount: _searchData!.length,
                          itemBuilder: (context, index) {
                            final anime = _searchData![index];
                            final tag = _searchData![index]['id'].toString();
                            return isList
                                ? SearchItem_LIST(context, anime, tag)
                                : isBox
                                    ? SearchItem_BOX(context, anime, tag)
                                    : SearchItem_COVER(context, anime, tag);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final Random random = Random();

Stack SearchItem_BOX(BuildContext context, anime, tag) {
  final uniqueTag = tag + random.nextInt(1000).toString();
  return Stack(
    children: [
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MangaDetailsPage(
                          id: anime['id'],
                          posterUrl: proxyUrl + anime['image'],
                          tag: uniqueTag,
                        )));
          },
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Hero(
              tag: uniqueTag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: proxyUrl + anime['image'],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
      // Positioned items remain unchanged
    ],
  );
}

GestureDetector SearchItem_LIST(BuildContext context, anime, tag) {
  final uniqueTag = tag + random.nextInt(1000).toString();
  return GestureDetector(
    onTap: () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MangaDetailsPage(
                    id: anime['id'],
                    posterUrl: proxyUrl + anime['image'],
                    tag: uniqueTag,
                  )));
    },
    child: Container(
      height: 110,
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Theme.of(context).colorScheme.surfaceContainer,
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          SizedBox(
            height: 90,
            width: 50,
            child: Hero(
              tag: uniqueTag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: CachedNetworkImage(
                  imageUrl: proxyUrl + anime['image'],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                anime['title'].length > 28
                    ? '${anime['title'].substring(0, 28)}...'
                    : anime['title'],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

GestureDetector SearchItem_COVER(
    BuildContext context, Map<String, dynamic> anime, String tag) {
  final uniqueTag = tag + random.nextInt(1000).toString();
  return GestureDetector(
    onTap: () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MangaDetailsPage(
                    id: anime['id'],
                    posterUrl: proxyUrl + anime['image'],
                    tag: uniqueTag,
                  )));
    },
    child: Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: proxyUrl + anime['image'],
                  fit: BoxFit.cover,
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 70,
                  child: Hero(
                    tag: uniqueTag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: CachedNetworkImage(
                        imageUrl: proxyUrl + anime['image'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anime['title'].length > 28
                            ? '${anime['title'].substring(0, 28)}...'
                            : anime['title'],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inverseSurface ==
                                  Theme.of(context)
                                      .colorScheme
                                      .onPrimaryFixedVariant
                              ? Colors.black
                              : Theme.of(context)
                                          .colorScheme
                                          .onPrimaryFixedVariant ==
                                      const Color(0xffe2e2e2)
                                  ? Colors.black
                                  : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
