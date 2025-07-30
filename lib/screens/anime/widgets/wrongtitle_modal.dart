import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:get/get.dart';

class WrongTitleModal extends StatefulWidget {
  const WrongTitleModal(
      {super.key,
      required this.initialText,
      required this.onTap,
      required this.isManga});
  final String initialText;
  final Function(DMedia) onTap;
  final bool isManga;

  @override
  State<WrongTitleModal> createState() => _WrongTitleModalState();
}

class _WrongTitleModalState extends State<WrongTitleModal> {
  late Future<List<DMedia?>?> searchFuture;
  final sourceController = Get.find<SourceController>();
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
    searchFuture = performSearch();
  }

  Future<List<DMedia?>?> performSearch() async {
    final source = widget.isManga
        ? sourceController.activeMangaSource.value
        : sourceController.activeSource.value;
    return (await source!.methods.search(controller.text, 1, [])).list;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: CustomSearchBar(
                disableIcons: true,
                padding: const EdgeInsets.all(0),
                controller: controller,
                onSubmitted: (value) {
                  setState(() {
                    searchFuture = performSearch();
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<DMedia?>?>(
                future: searchFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: AnymexProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else if (snapshot.hasData && snapshot.data != null) {
                    final results = snapshot.data ?? [];

                    if (results.isEmpty) {
                      return const Center(
                        child: Text('No results found.'),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: getResponsiveCrossAxisCount(context,
                              maxColumns: 5, baseColumns: 3),
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          mainAxisExtent: 210),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return AnymexOnTap(
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
                                    imageUrl: item!.cover ?? "",
                                    height: 140,
                                    radius: 12,
                                    width: double.infinity,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  item.title ?? '??',
                                  maxLines: 3,
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
    BuildContext context, String initialText, Function(DMedia) onTap,
    {bool isManga = false}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
    builder: (context) {
      final isDesktop = MediaQuery.of(context).size.width > 600;
      return SizedBox(
        width: isDesktop
            ? MediaQuery.of(context).size.width * 0.8
            : MediaQuery.of(context).size.width,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: WrongTitleModal(
              initialText: initialText, onTap: onTap, isManga: isManga),
        ),
      );
    },
  );
}
