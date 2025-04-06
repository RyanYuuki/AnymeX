import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'get_sources_list.dart';

part 'fetch_novel_sources.g.dart';

@riverpod
Future fetchNovelSourcesList(Ref ref, {int? id, required reFresh}) async {
  var repo = sourceController.activeNovelRepo;
  if (reFresh) {
    await fetchSourcesList(
      sourcesIndexUrl: repo,
      refresh: reFresh,
      id: id,
      ref: ref,
      itemType: MediaType.novel,
    );
  }
}
