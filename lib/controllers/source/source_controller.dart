import 'dart:developer';
import 'package:get/get.dart';
import 'package:anymex/api/Mangayomi/Extensions/extensions_provider.dart';
import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SourceController extends GetxController {
  var installedExtensions = <Source>[].obs;
  var activeSource = Rxn<Source>();

  var installedMangaExtensions = <Source>[].obs;
  var activeMangaSource = Rxn<Source>();

  Future<void> initExtensions() async {
    try {
      final container = ProviderContainer();
      final extensions =
          await container.read(getExtensionsStreamProvider(false).future);
      final mangaExtensions =
          await container.read(getExtensionsStreamProvider(true).future);
      installedExtensions.value =
          extensions.where((e) => e.isAdded ?? false).toList();
      installedMangaExtensions.value =
          mangaExtensions.where((e) => e.isAdded ?? false).toList();

      if (installedExtensions.isNotEmpty) {
        activeSource.value = installedExtensions[0];
      }
      if (installedMangaExtensions.isNotEmpty) {
        activeMangaSource.value = installedMangaExtensions[0];
      }

      log('Extensions initialized.');
    } catch (e) {
      log('Error initializing extensions: $e');
      Get.snackbar('Error', 'Failed to initialize extensions.');
    }
  }

  Source? getExtensionByName(String name) {
    activeSource.value = installedExtensions.value.firstWhere(
        (source) => '${source.name} (${source.lang?.toUpperCase()})' == name);
    return activeSource.value!;
  }

  Source? getMangaExtensionByName(String name) {
    activeSource.value = installedMangaExtensions.value.firstWhere(
        (source) => '${source.name} (${source.lang?.toUpperCase()})' == name);
    return activeSource.value!;
  }
}
