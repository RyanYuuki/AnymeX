import 'package:anymex/models/Offline/Hive/custom_list.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:hive/hive.dart';

part 'offline_storage.g.dart';

@HiveType(typeId: 8)
class OfflineStorage extends HiveObject {
  @HiveField(0)
  List<OfflineMedia>? animeLibrary;

  @HiveField(1)
  List<OfflineMedia>? mangaLibrary;

  @HiveField(2)
  List<CustomList>? animeCustomList;

  @HiveField(3)
  List<CustomList>? mangaCustomList;

  @HiveField(4)
  List<OfflineMedia>? novelLibrary;

  @HiveField(5)
  List<CustomList>? novelCustomList;

  OfflineStorage(
      {this.animeLibrary = const <OfflineMedia>[],
      this.mangaLibrary = const <OfflineMedia>[],
      this.novelLibrary = const <OfflineMedia>[],
      this.animeCustomList,
      this.mangaCustomList,
      this.novelCustomList});
}
