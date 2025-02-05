import 'package:anymex/controllers/source/source_controller.dart';
import 'package:get/get.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'GetSourceList.dart';

part 'fetch_anime_sources.g.dart';

@riverpod
Future fetchAnimeSourcesList(FetchAnimeSourcesListRef ref,
    {int? id, required bool reFresh}) async {
  await fetchSourcesList(
      sourcesIndexUrl: Get.find<SourceController>().activeAnimeRepo,
      refresh: reFresh,
      id: id,
      ref: ref,
      isManga: false);
}
