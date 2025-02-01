import 'package:anymex/controllers/source/source_controller.dart';
import 'package:get/get.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'GetSourceList.dart';

part 'fetch_manga_sources.g.dart';

@riverpod
Future fetchMangaSourcesList(FetchMangaSourcesListRef ref,
    {int? id, required reFresh}) async {
  if ((true ?? true) || reFresh) {
    await fetchSourcesList(
        sourcesIndexUrl: Get.find<SourceController>().activeMangaRepo,
        refresh: reFresh,
        id: id,
        ref: ref,
        isManga: true);
  }
}
