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

  Map<String, dynamic> toJson() {
    return {
      'link': link,
      'title': title,
      'releaseDate': releaseDate,
      'scanlator': scanlator,
      'number': number,
      'pageNumber': pageNumber,
      'totalPages': totalPages,
      'lastReadTime': lastReadTime,
      'currentOffset': currentOffset,
      'maxOffset': maxOffset,
      'sourceName': sourceName,
    };
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      link: json['link'] as String?,
      title: json['title'] as String?,
      releaseDate: json['releaseDate'] as String?,
      scanlator: json['scanlator'] as String?,
      number: (json['number'] as num?)?.toDouble(),
      pageNumber: json['pageNumber'] as int?,
      totalPages: json['totalPages'] as int?,
      lastReadTime: json['lastReadTime'] as int?,
      currentOffset: (json['currentOffset'] as num?)?.toDouble(),
      maxOffset: (json['maxOffset'] as num?)?.toDouble(),
      sourceName: json['sourceName'] as String?,
    );
  }
}
