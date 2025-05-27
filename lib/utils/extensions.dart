import 'dart:convert';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/core/Extensions/fetch_anime_sources.dart';
import 'package:anymex/core/Extensions/fetch_manga_sources.dart';
import 'package:anymex/core/Extensions/fetch_novel_sources.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class Extensions {
  final ProviderContainer _provider = ProviderContainer();
  final settings = Get.put(SourceController());

  Future<void> addRepo(MediaType type, String repo) async {
    if (type == MediaType.manga) {
      settings.activeMangaRepo = repo;
      await _provider
          .read(fetchMangaSourcesListProvider(id: null, reFresh: true).future);
    } else if (type == MediaType.anime) {
      settings.activeAnimeRepo = repo;
      await _provider
          .read(fetchAnimeSourcesListProvider(id: null, reFresh: true).future);
    } else {
      settings.activeNovelRepo = repo;
      await _provider
          .read(FetchNovelSourcesListProvider(id: null, reFresh: true).future);
    }
  }

  List<String> getRecommmendedExtensions() {
    const encodedSources = [
      'QW5pbWVQYWhl',
      'VnVtZXRv',
      'QW5pcGxheQ==',
      'R29qbw==',
      'QW5pbWVHRw==',
      'YWxsYW5pbWU='
    ];

    return encodedSources
        .map((e) => (utf8.decode(base64Decode(e)).toString().toLowerCase()))
        .toList();
  }

  List<String> getRecommmendedMangaExtensions() {
    const encodedSources = [
      'TWFuZ2FmaXJl',
      'Q29taWNr',
      'QXN1cmEgU2NhbnM=',
      'TWFuZ2FkZXg=',
      'TWFuZ2FoZXJl'
    ];

    return encodedSources
        .map((e) => (utf8.decode(base64Decode(e)).toString().toLowerCase()))
        .toList();
  }
}
