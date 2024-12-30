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

  SourceController();

  Future<void> initExtensions() async {
    try {
      final container = ProviderContainer();
      final extensions =
          await container.read(getExtensionsStreamProvider(false).future);
      installedExtensions.value =
          extensions.where((e) => e.isAdded ?? false).toList();
      if (installedExtensions.isNotEmpty) {
        activeSource.value = installedExtensions[0];
      }
      log('Extensions initialized.');
    } catch (e) {
      log('Error initializing extensions: $e');
      Get.snackbar('Error', 'Failed to initialize extensions.');
    }
  }

  Future<Source>? getExtensionByName(String name) async {
    activeSource.value = installedExtensions.value.firstWhere(
        (source) => '${source.name} (${source.lang?.toUpperCase()})' == name);
    return activeSource.value!;
  }
}
