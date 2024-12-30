import 'package:anymex/api/Mangayomi/Eval/dart/model/m_manga.dart';
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_pages.dart';
import 'package:anymex/api/Mangayomi/Search/search.dart';
import 'package:anymex/controllers/source_controller.dart';
import 'package:anymex/widgets/header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class WrongTitleModal extends StatefulWidget {
  const WrongTitleModal(
      {super.key, required this.initialText, required this.onTap});
  final String initialText;
  final Function(MManga) onTap;

  @override
  State<WrongTitleModal> createState() => _WrongTitleModalState();
}

class _WrongTitleModalState extends State<WrongTitleModal> {
  late Future<MPages?> searchFuture;
  final sourceController = Get.find<SourceController>();

  @override
  void initState() {
    super.initState();
    searchFuture = performSearch(widget.initialText);
  }

  Future<MPages?> performSearch(String query) async {
    return await search(
      source: sourceController.activeSource.value!,
      query: query,
      page: 1,
      filterList: [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.6,
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                onSubmitted: (value) {
                  setState(() {
                    searchFuture = performSearch(value);
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Search Animes...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  suffixIcon: const Padding(
                    padding: EdgeInsets.only(right: 15.0),
                    child: Icon(IconlyLight.search),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<MPages?>(
                future: searchFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else if (snapshot.hasData && snapshot.data != null) {
                    final results = snapshot.data!.list ?? [];

                    if (results.isEmpty) {
                      return const Center(
                        child: Text('No results found.'),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              mainAxisExtent: 200),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return GestureDetector(
                          onTap: () {
                            widget.onTap(item);
                            Get.back();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: NetworkSizedImage(
                                    imageUrl: item.imageUrl ?? "",
                                    height: 140,
                                    radius: 12,
                                    width: double.infinity,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  item.name ?? '??',
                                  maxLines: 2,
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: Text('No data available.'),
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

Future<void> showWrongTitleModal(
    BuildContext context, String initialText, Function(MManga) onTap) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: WrongTitleModal(initialText: initialText, onTap: onTap),
      );
    },
  );
}
