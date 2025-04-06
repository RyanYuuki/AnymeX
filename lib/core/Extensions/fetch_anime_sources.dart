import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'get_sources_list.dart';

part 'fetch_anime_sources.g.dart';

@riverpod
Future fetchAnimeSourcesList(FetchAnimeSourcesListRef ref,
    {int? id, required bool reFresh}) async {
  var repo = sourceController.activeAnimeRepo;
  await fetchSourcesList(
    sourcesIndexUrl: repo,
    id: id,
    ref: ref,
    itemType: MediaType.anime,
  );
}
