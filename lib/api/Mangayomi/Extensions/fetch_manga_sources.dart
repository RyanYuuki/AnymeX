import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../Model/Manga.dart';
import 'GetSourceList.dart';

part 'fetch_manga_sources.g.dart';

@riverpod
Future fetchMangaSourcesList(FetchMangaSourcesListRef ref,
    {int? id, required reFresh}) async {

    await fetchSourcesList(
      sourcesIndexUrl:
          "https://kodjodevf.github.io/mangayomi-extensions/index.json",
      refresh: reFresh,
      id: id,
      ref: ref,
      itemType: ItemType.manga,
    );
}
