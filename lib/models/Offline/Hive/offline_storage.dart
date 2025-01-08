import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:hive/hive.dart';

part 'offline_storage.g.dart';

@HiveType(typeId: 8)
class OfflineStorage extends HiveObject {
  @HiveField(0)
  List<OfflineMedia>? animeLibrary;

  @HiveField(1)
  List<OfflineMedia>? mangaLibrary;

  OfflineStorage({
    this.animeLibrary = const <OfflineMedia>[],
    this.mangaLibrary = const <OfflineMedia>[],
  });
}
