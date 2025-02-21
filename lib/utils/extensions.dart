import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/core/Extensions/fetch_anime_sources.dart';
import 'package:anymex/core/Extensions/fetch_manga_sources.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class Extensions {
  final ProviderContainer _provider = ProviderContainer();
  final settings = Get.put(SourceController());

  Future<void> addRepo(bool isManga, String repo) async {
    if (isManga) {
      settings.activeMangaRepo = repo;
      await _provider
          .read(fetchMangaSourcesListProvider(id: null, reFresh: true).future);
    } else {
      settings.activeAnimeRepo = repo;
      await _provider
          .read(fetchAnimeSourcesListProvider(id: null, reFresh: true).future);
    }
  }
}
