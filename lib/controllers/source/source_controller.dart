// ignore_for_file: unnecessary_null_comparison

import 'dart:developer';
import 'package:anymex/api/Mangayomi/Model/Manga.dart';
import 'package:anymex/controllers/anilist/anilist_data.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:anymex/api/Mangayomi/Extensions/extensions_provider.dart';
import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SourceController extends GetxController {
  var installedExtensions = <Source>[].obs;
  var activeSource = Rxn<Source>();

  var installedMangaExtensions = <Source>[].obs;
  var activeMangaSource = Rxn<Source>();

  var installedNovelExtensions = <Source>[].obs;
  var activeNovelSource = Rxn<Source>();

  Future<void> initExtensions({bool refresh = true}) async {
    try {
      final container = ProviderContainer();
      final extensions = await container
          .read(getExtensionsStreamProvider(ItemType.anime).future);
      final mangaExtensions = await container
          .read(getExtensionsStreamProvider(ItemType.manga).future);
      final novelExtensions = await container
          .read(getExtensionsStreamProvider(ItemType.novel).future);
      installedExtensions.value =
          extensions.where((e) => e.isAdded ?? false).toList();
      installedMangaExtensions.value =
          mangaExtensions.where((e) => e.isAdded ?? false).toList();
      installedNovelExtensions.value =
          novelExtensions.where((e) => e.isAdded ?? false).toList();

      final box = Hive.box('themeData');
      final savedActiveSourceId = box.get('activeSourceId') as int?;
      final savedActiveMangaSourceId = box.get('activeMangaSourceId') as int?;

      activeSource.value = installedExtensions
          .firstWhereOrNull((source) => source.id == savedActiveSourceId);
      activeMangaSource.value = installedMangaExtensions
          .firstWhereOrNull((source) => source.id == savedActiveMangaSourceId);

      if (activeSource.value == null && installedExtensions.isNotEmpty) {
        activeSource.value = installedExtensions[0];
      }
      if (activeMangaSource.value == null &&
          installedMangaExtensions.isNotEmpty) {
        activeMangaSource.value = installedMangaExtensions[0];
      }
      if (!refresh) {
        await Get.find<AnilistData>().fetchDataForAllSources();
      }
      log('Extensions initialized.');
    } catch (e) {
      log('Error initializing extensions: $e');
      Get.snackbar('Error', 'Failed to initialize extensions.');
    }
  }

  Source? getExtensionByName(String name) {
    final selectedSource = installedExtensions.firstWhere(
        (source) => '${source.name} (${source.lang?.toUpperCase()})' == name);

    if (selectedSource != null) {
      activeSource.value = selectedSource;
      Hive.box('themeData').put('activeSourceId', selectedSource.id);
    }
    return activeSource.value!;
  }

  Source? getMangaExtensionByName(String name) {
    final selectedMangaSource = installedMangaExtensions.firstWhere((source) =>
        '${source.name} (${source.lang?.toUpperCase()})' == name ||
        source.name == name);

    if (selectedMangaSource != null) {
      activeMangaSource.value = selectedMangaSource;
      Hive.box('themeData').put('activeMangaSourceId', selectedMangaSource.id);
    }
    return activeMangaSource.value!;
  }
}
