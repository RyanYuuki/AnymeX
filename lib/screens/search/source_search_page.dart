import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/future_reusable_carousel.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SourceSearchPage extends StatefulWidget {
  final String? initialTerm;
  final ItemType type;
  const SourceSearchPage({
    super.key,
    this.initialTerm = "Attack on Titan",
    this.type = ItemType.anime,
  });

  @override
  State<SourceSearchPage> createState() => _SourceSearchPageState();
}

class _SourceSearchPageState extends State<SourceSearchPage> {
  final sourceController = Get.find<SourceController>();
  final serviceHandler = Get.find<ServiceHandler>();
  late TextEditingController textController;
  RxString currentSearchTerm = ''.obs;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.initialTerm ?? '');
    if (widget.initialTerm?.isNotEmpty == true) {
      _search();
    }
  }

  Future<void> _search() async {
    if (textController.text.trim().isEmpty) return;

    final searchTerm = textController.text.trim();
    currentSearchTerm.value = searchTerm;
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back_ios_new),
                    ),
                    Expanded(
                      child: CustomSearchBar(
                        onSubmitted: (v) => _search(),
                        controller: textController,
                        disableIcons: true,
                        hintText:
                            "Search ${widget.type.name.capitalizeFirst}...",
                      ),
                    ),
                  ],
                ),
                ...widget.type.extensions
                    .map((extension) => FutureReusableCarousel(
                          title: extension.name ?? '',
                          future: extension.methods.search(
                              textController.text, 1, []).then((e) => e.list),
                          type: widget.type,
                          variant: DataVariant.extension,
                          source: extension,
                        )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
