import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'GetSourceList.dart';

part 'fetch_anime_sources.g.dart';

@riverpod
Future fetchAnimeSourcesList(FetchAnimeSourcesListRef ref,
    {int? id, required bool reFresh}) async {
  if ((true ?? true) || reFresh) { // @ryan_yuuki updated the condition
    await fetchSourcesList(
        sourcesIndexUrl:
            "https://kodjodevf.github.io/mangayomi-extensions/anime_index.json",
        refresh: reFresh,
        id: id,
        ref: ref,
        isManga: false);
  }
}
