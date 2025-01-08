import 'package:hive/hive.dart';

part 'episode.g.dart';

@HiveType(typeId: 5)
class Episode extends HiveObject {
  @HiveField(0)
  String number;

  @HiveField(1)
  String? link;

  @HiveField(2)
  String? title;

  @HiveField(3)
  String? desc;

  @HiveField(4)
  String? thumbnail;

  @HiveField(5)
  bool? filler;

  @HiveField(6)
  int? timeStampInMilliseconds;

  @HiveField(7)
  int? durationInMilliseconds;

  Episode(
      {required this.number,
      this.link,
      this.title,
      this.desc,
      this.thumbnail,
      this.filler,
      this.timeStampInMilliseconds,
      this.durationInMilliseconds});
}
