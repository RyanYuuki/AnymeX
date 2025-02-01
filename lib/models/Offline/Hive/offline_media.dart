import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:hive/hive.dart';
part 'offline_media.g.dart';

@HiveType(typeId: 7)
class OfflineMedia extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? jname;

  @HiveField(2)
  String? name;

  @HiveField(3)
  String? english;

  @HiveField(4)
  String? japanese;

  @HiveField(5)
  String? description;

  @HiveField(6)
  String? poster;

  @HiveField(7)
  String? cover;

  @HiveField(8)
  String? totalEpisodes;

  @HiveField(9)
  String? type;

  @HiveField(10)
  String? season;

  @HiveField(11)
  String? premiered;

  @HiveField(12)
  String? duration;

  @HiveField(13)
  String? status;

  @HiveField(14)
  String? rating;

  @HiveField(15)
  String? popularity;

  @HiveField(16)
  String? format;

  @HiveField(17)
  String? aired;

  @HiveField(18)
  String? totalChapters;

  @HiveField(19)
  List<String>? genres;

  @HiveField(20)
  List<String>? studios;

  @HiveField(21)
  List<Chapter>? chapters;

  @HiveField(22)
  List<Episode>? episodes;

  @HiveField(23)
  Episode? currentEpisode;

  @HiveField(24)
  Chapter? currentChapter;

  @HiveField(25)
  List<Episode>? watchedEpisodes;

  @HiveField(26)
  List<Chapter>? readChapters;

  @HiveField(27)
  int? serviceIndex;

  OfflineMedia(
      {this.id,
      this.jname,
      this.name,
      this.english,
      this.japanese,
      this.description,
      this.poster,
      this.cover,
      this.totalEpisodes,
      this.type,
      this.season,
      this.premiered,
      this.duration,
      this.status,
      this.rating,
      this.popularity,
      this.format,
      this.aired,
      this.totalChapters,
      this.genres,
      this.studios,
      this.chapters,
      this.episodes,
      this.currentEpisode,
      this.currentChapter,
      this.watchedEpisodes,
      this.readChapters,
      this.serviceIndex = 0});
}
