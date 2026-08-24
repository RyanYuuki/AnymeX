import 'package:isar_community/isar.dart';

part 'media_stats.g.dart';

@collection
class MediaStats {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String mediaId;

  late String title;
  late String type;
  String? poster;
  String? cover;

  int totalTimeMinutes = 0;
  int totalUnitsConsumed = 0;

  late DateTime lastInteracted;
  int interactionCount = 0;
}
