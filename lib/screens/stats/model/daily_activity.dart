import 'package:isar_community/isar.dart';

@collection
class DailyActivity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late DateTime date;

  int watchTimeMinutes = 0;
  int readTimeMinutes = 0;

  int episodesWatched = 0;
  int chaptersRead = 0;

  List<String> activeMediaIds = [];
}
