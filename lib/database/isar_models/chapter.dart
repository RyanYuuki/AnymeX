import 'package:isar_community/isar.dart';

part 'chapter.g.dart';

@embedded
class Chapter {
  String? link;
  String? title;
  String? releaseDate;
  String? scanlator;
  double? number;
  int? pageNumber;
  int? totalPages;
  int? lastReadTime;
  double? currentOffset;
  double? maxOffset;
  String? sourceName;

  List<String>? headerKeys;
  List<String>? headerValues;

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
      this.sourceName,
      this.headerKeys,
      this.headerValues});

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
      'headerKeys': headerKeys,
      'headerValues': headerValues
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
      headerKeys: json['headerKeys'] as List<String>?,
      headerValues: json['headerValues'] as List<String>?,
    );
  }
}
