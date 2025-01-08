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
  String? readDate;

  @HiveField(8)
  double? currentOffset;

  @HiveField(9)
  double? maxOffset;

  Chapter(
      {this.link,
      this.title,
      this.releaseDate,
      this.number,
      this.scanlator,
      this.pageNumber,
      this.readDate,
      this.totalPages,
      this.currentOffset,
      this.maxOffset});
}
