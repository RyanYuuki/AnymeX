import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/core/Model/Source.dart';
import 'package:anymex/screens/search/source_search_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/widgets/animation/slide_scale.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

extensionSheet(String query, List<Source> sources) {
  final context = Get.context;
  Get.find<SourceController>().initExtensions();
  return showModalBottomSheet(
      context: context!,
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          height: Get.height * 0.5,
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
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  Get.back();
                  navigate(() => SourceSearchPage(
                        source: sources,
                        initialTerm: query,
                        isManga: sources[0].isManga ?? false,
                      ));
                },
                child: Container(
                    width: double.infinity,
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        boxShadow: [glowingShadow(context)],
                        borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha(100)),
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
      navigate(() => SourceSearchPage(
            source: e,
            initialTerm: q,
            isManga: e.isManga ?? false,
          ));
    },
    child: SlideAndScaleAnimation(
      initialScale: 0.0,
      finalScale: 1.0,
      initialOffset: const Offset(1.0, 0.0),
      duration: Duration(milliseconds: getAnimationDuration()),
      child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              boxShadow: [glowingShadow(context)],
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.primary.withAlpha(100)),
          child: Row(
            children: [
              const SizedBox(width: 10),
              NetworkSizedImage(
                imageUrl: e.iconUrl ?? '',
                radius: 50,
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymexText(
                    text: e.name!,
                    variant: TextVariant.semiBold,
                  ),
                  AnymexText(
                    text: completeLanguageName(e.lang!),
                    variant: TextVariant.semiBold,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ],
          )),
    ),
  );
}
