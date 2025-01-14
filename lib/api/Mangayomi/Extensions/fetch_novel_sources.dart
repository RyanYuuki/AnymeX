import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Model/Manga.dart';
import 'GetSourceList.dart';
part 'fetch_novel_sources.g.dart';

@riverpod
Future fetchNovelSourcesList(Ref ref, {int? id, required reFresh}) async {
  await fetchSourcesList(
    sourcesIndexUrl:
        "https://kodjodevf.github.io/mangayomi-extensions/novel_index.json",
    refresh: reFresh,
    id: id,
    ref: ref,
    itemType: ItemType.novel,
  );
}
