import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/core/Model/Source.dart';
import 'package:anymex/screens/search/search_anilist.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

extensionSheet(String query, List<Source> sources) {
  final context = Get.context;
  return showModalBottomSheet(
      context: context!,
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          height: Get.height * 0.6,
          child: ListView(
            children: [
              const SizedBox(height: 10),
              const Center(
                child: AnymexText(
                  text: "Choose Extensions",
                  size: 18,
                  variant: TextVariant.semiBold,
                ),
              ),
              InkWell(
                onTap: () {
                  Get.back();
                  Get.to(() => SearchPage(
                        source: sources,
                        searchTerm: query,
                        isManga: sources[0].isManga ?? false,
                      ));
                },
                child: Container(
                    width: double.infinity,
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color:
                            Theme.of(context).colorScheme.secondaryContainer),
                    child: const AnymexText(
                      text: "ALL",
                      variant: TextVariant.semiBold,
                      textAlign: TextAlign.center,
                    )),
              ),
              const SizedBox(height: 10),
              ...sources
                  .map<Widget>((e) => _buildExtensionTitle(context, e, query))
            ],
          ),
        );
      });
}

InkWell _buildExtensionTitle(BuildContext context, Source e, String q) {
  return InkWell(
    onTap: () {
      Get.back();
      if (e.isManga ?? false) {
        Get.find<SourceController>().getMangaExtensionByName(e.name ?? '');
      } else {
        Get.find<SourceController>().getExtensionByName(e.name ?? '');
      }
      Get.to(() => SearchPage(
            source: e,
            searchTerm: q,
            isManga: e.isManga ?? false,
          ));
    },
    child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.secondaryContainer),
        child: AnymexText(
          text: e.name!,
          variant: TextVariant.semiBold,
          textAlign: TextAlign.center,
        )),
  );
}
