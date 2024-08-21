import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class MangaSearchPage extends StatefulWidget {
  final String searchTerm;
  const MangaSearchPage({super.key, required this.searchTerm});

  @override
  State<MangaSearchPage> createState() => _MangaSearchPageState();
}

class _MangaSearchPageState extends State<MangaSearchPage> {
  final TextEditingController controller = TextEditingController();
  List<dynamic>? _searchData;

  @override
  void initState() {
    super.initState();
    controller.text = widget.searchTerm;
    fetchSearchedTerm();
  }

  Future<void> fetchSearchedTerm() async {
    _searchData = null;
    final String url =
        'https://anymey-proxy.vercel.app/cors?url=https://manga-ryan.vercel.app/api/search/${controller.text}';
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode == 200) {
      final tempData = jsonDecode(resp.body);
      setState(() {
        _searchData = tempData['mangaList'];
      });
    }
  }

  void _search(String searchTerm) {
    setState(() {
      controller.text = searchTerm;
    });
    fetchSearchedTerm();
  }

  @override
  Widget build(BuildContext context) {
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
                ],
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: _searchData == null
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: _searchData!.length,
                        itemBuilder: (context, index) {
                          final anime = _searchData![index];
                          final tag = _searchData![index]['id'];
                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                        context, '/manga/details', arguments: {
                                      "id": anime['id'],
                                      'posterUrl': anime['image'],
                                      "tag": tag
                                    });
                                  },
                                  child: Hero(
                                    tag: tag,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: CachedNetworkImage(
                                          imageUrl: anime['image'],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'MANGA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
