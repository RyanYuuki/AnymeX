import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../main.dart';
import '../Model/Source.dart';

part 'extensions_provider.g.dart';

@riverpod
Stream<List<Source>> getExtensionsStream(
    GetExtensionsStreamRef ref, bool? isManga) async* {
  yield* isar.sources
      .filter()
      .idIsNotNull()
      .and()
      .isActiveEqualTo(true)
      .isMangaEqualTo(isManga)
      .watch(fireImmediately: true);
}
