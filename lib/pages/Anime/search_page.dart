import 'dart:ui';
import 'package:aurora/components/common/IconWithLabel.dart';
import 'package:aurora/utils/apiHooks/anilist/anime/search_page.dart';
import 'package:aurora/pages/Anime/details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class SearchPage extends StatefulWidget {
  final String searchTerm;
  const SearchPage({super.key, required this.searchTerm});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

const String proxyUrl = '';

class _SearchPageState extends State<SearchPage> {
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
    final tempData = await fetchAnimeBySearch(controller.text);
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

    return Scaffold(
      body: Padding(
        padding:
            const EdgeInsets.only(left: 20.0, right: 20, bottom: 16, top: 50),
        child: Column(
          children: [
            SizedBox(
              height: 50,
              width: double.infinity,
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
                      color: Theme.of(context).colorScheme.onPrimary,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Search Results',
                    style: TextStyle(
                        fontSize: 18, fontFamily: 'Poppins-SemiBold')),
                IconButton(
                  onPressed: _toggleView,
                  icon: Icon(
                    isList
                        ? Iconsax.menu
                        : (isBox ? Icons.menu : Iconsax.image),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Builder(
                builder: (context) => _searchData == null
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
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
                          final tag = anime['name'].toString();
                          return isList
                              ? searchItemList(context, anime, tag)
                              : isBox
                                  ? searchItemBox(context, anime, tag)
                                  : searchItemCover(context, anime, tag);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stack searchItemBox(BuildContext context, anime, tag) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/details', arguments: {
                "id": anime['id'],
                'posterUrl': proxyUrl + anime['poster'],
                'tag': tag
              });
            },
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Hero(
                tag: tag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: proxyUrl + anime['poster'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  topRight: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.star5,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 3),
                Text(
                  anime?['rating'] ?? 'PG-13',
                  style: TextStyle(
                    fontFamily: 'Poppins-Bold',
                    color: Theme.of(context).colorScheme.inverseSurface ==
                            Theme.of(context).colorScheme.onPrimaryFixedVariant
                        ? Colors.black
                        : Theme.of(context).colorScheme.onPrimaryFixedVariant ==
                                const Color(0xffe2e2e2)
                            ? Colors.black
                            : Colors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

GestureDetector searchItemList(BuildContext context, anime, tag) {
  return GestureDetector(
    onTap: () {
      Navigator.pushNamed(context, '/details', arguments: {
        'id': anime['id'],
        'posterUrl': proxyUrl + anime['poster'],
        'tag': tag
      });
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
            height: 90,
            width: 50,
            child: Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: CachedNetworkImage(
                  imageUrl: proxyUrl + anime['poster'],
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
                anime['name'].length > 26
                    ? '${anime['name'].toString().substring(0, 26)}...'
                    : anime['name'].toString(),
              ),
              const SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  iconWithName(
                      isVertical: false,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5)),
                      icon: Icons.closed_caption,
                      backgroundColor: const Color(0xFFb0e3af),
                      name: anime['episodes']?.toString() ?? '?'),
                  const SizedBox(width: 2),
                  iconWithName(
                      isVertical: false,
                      backgroundColor: const Color(0xFFb9e7ff),
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5)),
                      icon: Iconsax.star5,
                      name: anime['rating']?.toString() ?? '?')
                ],
              )
            ],
          )
        ],
      ),
    ),
  );
}

GestureDetector searchItemCover(
    BuildContext context, Map<String, dynamic> anime, String tag) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailsPage(
                    id: anime['id'],
                    posterUrl: proxyUrl + anime['poster'],
                    tag: tag,
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
                  imageUrl: proxyUrl + anime['poster'],
                  fit: BoxFit.cover,
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                  child: Container(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Theme.of(context).colorScheme.surface.withOpacity(0.7),
                    ],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 70,
                  child: Hero(
                    tag: tag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: CachedNetworkImage(
                        imageUrl: proxyUrl + anime['poster'],
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
                        anime['name'].length > 28
                            ? '${anime['name'].substring(0, 28)}...'
                            : anime['name'],
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
                      const SizedBox(height: 5),
                      Text(
                        '${anime['episodes'] ?? '?'} Episodes',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.inverseSurface ==
                                        Theme.of(context)
                                            .colorScheme
                                            .onPrimaryFixedVariant
                                    ? Colors.black
                                    : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryFixedVariant ==
                                            const Color(0xffe2e2e2)
                                        ? Colors.black
                                        : Colors.white),
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
