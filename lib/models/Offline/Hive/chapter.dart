import 'package:hive/hive.dart';

part 'chapter.g.dart';

@HiveType(typeId: 6)
class Chapter extends HiveObject {
  @HiveField(0)
  String? link;

  @HiveField(1)
  String? title;

  @HiveField(2)
  String? releaseDate;

  @HiveField(3)
  String? scanlator;

  @HiveField(4)
  double? number;

  @HiveField(5)
  int? pageNumber;

  @HiveField(6)
  int? totalPages;

  @HiveField(7)
  int? lastReadTime;

  @HiveField(8)
  double? currentOffset;

  @HiveField(9)
  double? maxOffset;

  @HiveField(10)
  String? sourceName;

  Chapter(
      {this.link,
      this.title,
      this.releaseDate,
      this.number,
      this.scanlator,
      this.pageNumber,
      this.lastReadTime,
      this.totalPages,
      this.currentOffset,
      this.maxOffset,
      this.sourceName});
}
